import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class AuthProvider extends ChangeNotifier {
  static const String _chaveUltimoCpf = 'ultimo_cpf_login';

  AuthProvider() {
    carregarCacheContas();
  }

  String _cpf = '';
  String? _errorMessage;
  bool _carregando = false;
  UsuarioNous? _contaAtual;
  String? _emailAtivo;
  Map<String, String> _fotosPorCpf = {};
  Map<String, UsuarioNous> _contasPorCpf = {};
  Set<String> _dadosReveladosDono = {};

  String get cpf => _cpf;
  String? get errorMessage => _errorMessage;
  bool get carregando => _carregando;
  UsuarioNous? get contaAtual => _contaAtual;
  String? get emailAtivo => _emailAtivo;
  Set<String> get dadosReveladosDono => _dadosReveladosDono;

  bool dadoEstaReveladoParaDono(String chave) => _dadosReveladosDono.contains(chave);

  UsuarioNous? buscarContaPorCpf(String cpf) {
    final digitos = CpfValidator.onlyDigits(cpf);
    if (_contaAtual != null && CpfValidator.onlyDigits(_contaAtual!.cpf) == digitos) {
      return _contaAtual;
    }
    return _contasPorCpf[digitos] ?? _contasPorCpf[cpf];
  }

  void atualizarContaNoCache(UsuarioNous conta) {
    final digitos = CpfValidator.onlyDigits(conta.cpf);
    _contasPorCpf[digitos] = conta;
    _contasPorCpf[conta.cpf] = conta;
    if (conta.foto.isNotEmpty) {
      _fotosPorCpf[conta.cpf] = conta.foto;
      _fotosPorCpf[digitos] = conta.foto;
    }
    if (_contaAtual != null && CpfValidator.onlyDigits(_contaAtual!.cpf) == digitos) {
      _contaAtual = conta;
    }
    notifyListeners();
  }

  Future<void> carregarDadosReveladosDono(String cpf) async {
    final digitos = CpfValidator.onlyDigits(cpf);
    if (digitos.isEmpty) {
      _dadosReveladosDono = {};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('dados_revelados_$digitos') ?? [];
    _dadosReveladosDono = lista.toSet();
    notifyListeners();
  }

  Future<void> alternarRevelacaoParaDono(String chave) async {
    if (_contaAtual == null) return;
    final digitos = CpfValidator.onlyDigits(_contaAtual!.cpf);
    if (_dadosReveladosDono.contains(chave)) {
      _dadosReveladosDono.remove(chave);
    } else {
      _dadosReveladosDono.add(chave);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dados_revelados_$digitos', _dadosReveladosDono.toList());
    notifyListeners();
  }

  bool get isValid => CpfValidator.isValid(_cpf);

  Future<void> salvarUltimoCpf(String cpf) async {
    final digitos = CpfValidator.onlyDigits(cpf);
    if (digitos.length == 11) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveUltimoCpf, digitos);
    }
  }

  Future<String?> obterUltimoCpf() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveUltimoCpf);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> carregarCacheContas() async {
    final todas = await ContasNousService.carregarTodas();
    if (_disposed) return;
    _contasPorCpf = {
      for (final c in todas) CpfValidator.onlyDigits(c.cpf): c,
    };
    _fotosPorCpf = {
      for (final c in todas)
        if (c.fotoExibicao.trim().isNotEmpty) c.cpf: c.fotoExibicao.trim(),
    };
    notifyListeners();
  }

  String buscarFotoPorCpf(String cpf) {
    if (_contaAtual != null &&
        _contaAtual!.cpf == cpf &&
        _contaAtual!.fotoExibicao.trim().isNotEmpty) {
      return _contaAtual!.fotoExibicao.trim();
    }
    return _fotosPorCpf[cpf] ?? '';
  }

  void updateCpf(String rawInput) {
    _cpf = CpfValidator.onlyDigits(rawInput);

    if (_cpf.length < 11) {
      _errorMessage = null;
    } else if (!CpfValidator.isValid(_cpf)) {
      _errorMessage = 'CPF inválido';
    } else {
      _errorMessage = null;
    }

    notifyListeners();
  }

  Future<bool> buscarConta() async {
    if (!isValid) return false;

    _carregando = true;
    notifyListeners();

    var conta = await ContasNousService.buscarPorCpf(_cpf);

    // 1. Se não encontrou no banco de contas local, tenta enriquecer e consolidar a partir de dados locais (clientes e membros)
    if (conta == null) {
      try {
        final dadosAuto = await DadosLocaisService.buscarPorDocumento(_cpf);
        if (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty) {
          conta = UsuarioNous(
            cpf: _cpf,
            nome: dadosAuto.nome.trim(),
            dataNascimento: dadosAuto.dataNascimento,
            foto: dadosAuto.foto,
          );
          await ContasNousService.salvar(conta);
          debugPrint(
            '[AuthProvider] Conta consolidada automaticamente de dados locais para CPF $_cpf (${conta.nome})',
          );
        }
      } catch (e) {
        debugPrint('[AuthProvider] Erro ao consolidar dados locais: $e');
      }
    }

    // 2. Consulta o balcão via rede Wi-Fi local para enriquecer os dados (inclusive nomeDeUsuario soberano, foto e dados cadastrais)
    try {
      final remoto = await ClienteRedeLocal().buscarUsuarioRemoto(_cpf);
      if (remoto != null) {
        if (conta == null) {
          conta = remoto;
        } else {
          conta = conta.copyWith(
            nome: (conta.nome.isEmpty || conta.nome.toLowerCase() == 'blackview')
                ? remoto.nome
                : conta.nome,
            apelido: conta.apelido.isNotEmpty ? conta.apelido : remoto.apelido,
            nomeDeUsuario: conta.nomeDeUsuario.isNotEmpty
                ? conta.nomeDeUsuario
                : remoto.nomeDeUsuario,
            foto: (conta.foto.isNotEmpty && ImagemService.existe(conta.foto))
                ? conta.foto
                : remoto.foto,
            emails: {...conta.emails, ...remoto.emails}.toList(),
            biografia: conta.biografia.isNotEmpty ? conta.biografia : remoto.biografia,
            nomePublico: conta.nomePublico.isNotEmpty ? conta.nomePublico : remoto.nomePublico,
            apelidoPublico: conta.apelidoPublico.isNotEmpty ? conta.apelidoPublico : remoto.apelidoPublico,
            fotoPublica: conta.fotoPublica.isNotEmpty ? conta.fotoPublica : remoto.fotoPublica,
            dadosPrivados: conta.dadosPrivados.isNotEmpty ? conta.dadosPrivados : remoto.dadosPrivados,
            dadosAutorizadosPorCpf: {...conta.dadosAutorizadosPorCpf, ...remoto.dadosAutorizadosPorCpf}.toList(),
            seguindo: {...conta.seguindo, ...remoto.seguindo}.toList(),
            seguidores: {...conta.seguidores, ...remoto.seguidores}.toList(),
          );
        }
        await ContasNousService.salvar(conta);
        debugPrint(
          '[AuthProvider] Conta recuperada/enriquecida do balcão Wi-Fi para CPF $_cpf (${conta.nome}, username: ${conta.nomeDeUsuario})',
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] Erro ao buscar usuário remoto: $e');
    }

    _contaAtual = conta;
    _emailAtivo = (conta != null && conta.emails.isNotEmpty)
        ? conta.emails.first
        : null;

    if (conta != null) {
      await ThemeController.carregarTemaDoUsuario(conta.cpf);
      await carregarDadosReveladosDono(conta.cpf);
    }

    _carregando = false;
    notifyListeners();

    return conta != null;
  }

  Future<void> associarConta({
    required String nome,
    required String dataNascimento,
  }) async {
    final conta = UsuarioNous(
      cpf: _cpf,
      nome: nome.trim(),
      apelido: nome.trim(),
      dataNascimento: dataNascimento.trim(),
    );

    await ContasNousService.salvar(conta);

    _contaAtual = conta;
    _emailAtivo = null;
    await ThemeController.carregarTemaDoUsuario(_cpf);
    await carregarDadosReveladosDono(_cpf);
    notifyListeners();
  }

  Future<void> associarContaComApelido(String apelido, [String? nomeDeUsuario]) async {
    final apelidoLimpo = apelido.trim();
    final usernameLimpo = (nomeDeUsuario != null && nomeDeUsuario.trim().isNotEmpty)
        ? nomeDeUsuario.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '')
        : '';
    final conta = UsuarioNous(
      cpf: _cpf,
      nome: apelidoLimpo,
      apelido: apelidoLimpo,
      nomeDeUsuario: usernameLimpo,
      dataNascimento: '',
    );

    await ContasNousService.salvar(conta);

    _contaAtual = conta;
    _emailAtivo = null;
    await ThemeController.carregarTemaDoUsuario(_cpf);
    await carregarDadosReveladosDono(_cpf);
    _propagarUsuarioAtualizado(conta);
    notifyListeners();
  }

  Future<void> atualizarNome(String novoNome) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(nome: novoNome.trim());
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> atualizarApelido(String novoApelido) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(apelido: novoApelido.trim());
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> atualizarPerfilSocial({
    required String nome,
    required String apelido,
    required String biografia,
    String? foto,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(
      nomePublico: nome.trim(),
      apelidoPublico: apelido.trim(),
      biografia: biografia.trim(),
      fotoPublica: foto != null ? foto.trim() : conta.fotoPublica,
    );
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    if (foto != null && foto.trim().isNotEmpty) {
      _fotosPorCpf[conta.cpf] = foto.trim();
    }
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  void _propagarUsuarioAtualizado(UsuarioNous usuario) {
    _contasPorCpf[CpfValidator.onlyDigits(usuario.cpf)] = usuario;
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarUsuario(usuario);
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'usuario_atualizado',
        'usuario': usuario.toJson(),
      });
    }
  }

  void definirEmailAtivo(String? email) {
    _emailAtivo = email;
    notifyListeners();
  }

  Future<String?> adicionarEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return 'Nenhuma conta carregada.';

    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return 'Informe um e-mail válido.';
    }
    if (conta.emails.contains(emailLimpo)) {
      return 'Este e-mail já está nesta conta.';
    }

    final donoAtual = await ContasNousService.buscarCpfDoEmail(emailLimpo);
    if (donoAtual != null && donoAtual != conta.cpf) {
      return 'Este e-mail já está associado a outro CPF.';
    }

    final atualizado = conta.copyWith(emails: [...conta.emails, emailLimpo]);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _emailAtivo ??= emailLimpo;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
    return null;
  }

  Future<void> removerEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final novosEmails = conta.emails.where((e) => e != email).toList();
    final atualizado = conta.copyWith(emails: novosEmails);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;

    if (_emailAtivo == email) {
      _emailAtivo = novosEmails.isEmpty ? null : novosEmails.first;
    }
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> excluirConta([String? cpfAlvo]) async {
    final c = _contaAtual;
    final cpfReal = cpfAlvo ?? c?.cpf ?? _cpf;
    final cpfLimpo = cpfReal.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return;

    await ContasNousService.excluir(cpfLimpo);

    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getString(_chaveUltimoCpf);
    if (ultimo != null &&
        ultimo.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
      await prefs.remove(_chaveUltimoCpf);
    }

    _fotosPorCpf.remove(cpfLimpo);
    _fotosPorCpf.remove(cpfReal);
    await carregarCacheContas();
    sair();
  }

  Future<void> atualizarNomeDeUsuario(String novoUsername) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final limpo = novoUsername.trim().toLowerCase().replaceAll('@', '');
    final atualizado = conta.copyWith(nomeDeUsuario: limpo);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> alternarPrivacidadeDado(String chave, [bool? privado]) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final novaLista = List<String>.from(conta.dadosPrivados);
    final deveFicarPrivado = privado ?? !novaLista.contains(chave);
    if (deveFicarPrivado) {
      if (!novaLista.contains(chave)) novaLista.add(chave);
    } else {
      novaLista.remove(chave);
    }

    final atualizado = conta.copyWith(dadosPrivados: novaLista);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> autorizarAcessoDado(String cpfSolicitante, String chave) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final solicitanteLimpo = cpfSolicitante.replaceAll(RegExp(r'\D'), '');
    final chavePermissao = '$solicitanteLimpo:$chave';
    final novaLista = List<String>.from(conta.dadosAutorizadosPorCpf);
    if (!novaLista.contains(chavePermissao)) {
      novaLista.add(chavePermissao);
    }

    final atualizado = conta.copyWith(dadosAutorizadosPorCpf: novaLista);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> alternarSeguir(String cpfAlvo) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final alvoLimpo = cpfAlvo.replaceAll(RegExp(r'\D'), '');
    final novaListaSeguindo = List<String>.from(conta.seguindo);

    final jaSegue = novaListaSeguindo.any((s) => s.replaceAll(RegExp(r'\D'), '') == alvoLimpo);
    if (jaSegue) {
      novaListaSeguindo.removeWhere((s) => s.replaceAll(RegExp(r'\D'), '') == alvoLimpo);
    } else {
      novaListaSeguindo.add(alvoLimpo);
    }

    final atualizado = conta.copyWith(seguindo: novaListaSeguindo);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;

    // Atualiza também a conta alvo se existir localmente
    final contaAlvo = await ContasNousService.buscarPorCpf(alvoLimpo);
    if (contaAlvo != null) {
      final meuCpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
      final seguidoresAlvo = List<String>.from(contaAlvo.seguidores);
      if (jaSegue) {
        seguidoresAlvo.removeWhere((s) => s.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo);
      } else {
        if (!seguidoresAlvo.contains(meuCpfLimpo)) seguidoresAlvo.add(meuCpfLimpo);
      }
      final alvoAtualizado = contaAlvo.copyWith(seguidores: seguidoresAlvo);
      await ContasNousService.salvar(alvoAtualizado);
    }

    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> atualizarFoto(String novaFoto) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(foto: novaFoto);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _fotosPorCpf[conta.cpf] = novaFoto;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> sincronizarFotoComClienteSeNecessario(String? fotoCliente) async {
    final conta = _contaAtual;
    if (conta == null) return;
    if (fotoCliente == null || fotoCliente.trim().isEmpty) return;

    if (conta.foto.trim().isEmpty) {
      await atualizarFoto(fotoCliente.trim());
    }
  }

  Future<void> atualizarDadosPessoais({
    String? dataNascimento,
    String? nomePai,
    String? nomeMae,
    String? localNascimento,
    String? tipoSanguineo,
    String? estadoCivil,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(
      dataNascimento: dataNascimento,
      nomePai: nomePai,
      nomeMae: nomeMae,
      localNascimento: localNascimento,
      tipoSanguineo: tipoSanguineo,
      estadoCivil: estadoCivil,
    );
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> revogarAcessoDado(String chave, String cpfAlvo) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.revogarAutorizacao(chave, cpfAlvo);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> recarregarConta() async {
    if (_cpf.isEmpty) return;
    final conta = await ContasNousService.buscarPorCpf(_cpf);
    _contaAtual = conta;
    if (conta != null && conta.foto.isNotEmpty) {
      _fotosPorCpf[conta.cpf] = conta.foto;
    }
    if (conta != null) {
      await carregarDadosReveladosDono(conta.cpf);
    }
    notifyListeners();
  }

  void sair() {
    _cpf = '';
    _errorMessage = null;
    _contaAtual = null;
    _emailAtivo = null;
    _dadosReveladosDono = {};
    ThemeController.desvincularUsuario();
    notifyListeners();
  }
}