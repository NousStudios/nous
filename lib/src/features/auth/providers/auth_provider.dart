import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class AuthProvider extends ChangeNotifier {
  static const String _chaveUltimoCpf = 'ultimo_cpf_login';
  static const String _chaveSessaoCpf = 'nous_sessao_cpf';
  static const String _chaveSessaoEmail = 'nous_sessao_email';

  static Future<void> salvarSessao(String cpf, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveSessaoCpf, cpf.replaceAll(RegExp(r'\D'), ''));
      await prefs.setString(_chaveSessaoEmail, email.trim());
    } catch (_) {}
  }

  static Future<void> limparSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveSessaoCpf);
      await prefs.remove(_chaveSessaoEmail);
    } catch (_) {}
  }

  Future<bool> tentarRestaurarSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cpf = prefs.getString(_chaveSessaoCpf);
      final email = prefs.getString(_chaveSessaoEmail);
      if (cpf == null || cpf.length != 11 || email == null || email.isEmpty) {
        return false;
      }
      final conta = await ContasNousService.buscarPorCpf(cpf);
      if (conta == null) return false;

      _cpf = cpf;
      _contaAtual = conta;
      _emailAtivo = email;
      if (conta.foto.isNotEmpty) {
        _fotosPorCpf[conta.cpf] = conta.foto;
      }
      await carregarDadosReveladosDono(conta.cpf);
      ClienteRedeLocal().atualizarIdentidadeUsuario(
        cpf: conta.cpf,
        nome: conta.nomeExibicao,
        apelido: conta.apelido,
        foto: conta.fotoExibicao,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  AuthProvider() {
    carregarCacheContas();
    ClienteRedeLocal().vincularAuthProvider(this);
    ServidorRedeLocal().vincularAuthProvider(this);
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
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (_contaAtual != null) {
      final meuCpfLimpo = _contaAtual!.cpf.replaceAll(RegExp(r'\D'), '');
      if ((_contaAtual!.cpf == cpf || (cpfLimpo.isNotEmpty && meuCpfLimpo == cpfLimpo)) &&
          _contaAtual!.fotoExibicao.trim().isNotEmpty) {
        return _contaAtual!.fotoExibicao.trim();
      }
    }
    if (_fotosPorCpf.containsKey(cpf) && _fotosPorCpf[cpf]!.isNotEmpty) {
      return _fotosPorCpf[cpf]!;
    }
    if (cpfLimpo.isNotEmpty) {
      for (final entry in _fotosPorCpf.entries) {
        if (entry.key.replaceAll(RegExp(r'\D'), '') == cpfLimpo &&
            entry.value.isNotEmpty) {
          return entry.value;
        }
      }
    }
    return '';
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

    // Se a conta já existe localmente, define imediatamente para a UI responder com fluidez total (sem gargalo)
    if (conta != null) {
      var contaSegura = conta;
      if (contaSegura.foto.isNotEmpty) {
        try {
          final lojasDoUsuario = await LojasService.carregar(_cpf);
          final logos = lojasDoUsuario
              .map((l) => l.logo.trim())
              .where((logo) => logo.isNotEmpty)
              .toSet();
          if (logos.contains(contaSegura.foto.trim())) {
            contaSegura = contaSegura.copyWith(foto: '');
            await ContasNousService.salvar(contaSegura);
          }
        } catch (_) {}
      }

      _contaAtual = contaSegura;
      _emailAtivo = contaSegura.emails.isNotEmpty ? contaSegura.emails.first : null;
      await ThemeController.carregarTemaDoUsuario(contaSegura.cpf);
      await carregarDadosReveladosDono(contaSegura.cpf);
      ClienteRedeLocal().atualizarIdentidadeUsuario(
        cpf: contaSegura.cpf,
        nome: contaSegura.nome,
        apelido: contaSegura.apelido,
        foto: contaSegura.foto,
      );
      ServidorRedeLocal().atualizarOperadorBalcao(contaSegura);
      _carregando = false;
      notifyListeners();

      // Enriquecimento e sincronização em background com o balcão via rede Wi-Fi local
      unawaited(() async {
        try {
          final remoto = await ClienteRedeLocal().buscarUsuarioRemoto(_cpf);
          if (remoto != null && _contaAtual != null && _contaAtual!.cpf == _cpf) {
            final contaAtualizada = _contaAtual!.copyWith(
              nome: (_contaAtual!.nome.isEmpty || _contaAtual!.nome.toLowerCase() == 'blackview')
                  ? remoto.nome
                  : _contaAtual!.nome,
              apelido: _contaAtual!.apelido.isNotEmpty ? _contaAtual!.apelido : remoto.apelido,
              nomeDeUsuario: _contaAtual!.nomeDeUsuario.isNotEmpty
                  ? _contaAtual!.nomeDeUsuario
                  : remoto.nomeDeUsuario,
              foto: (_contaAtual!.foto.isNotEmpty && ImagemService.existe(_contaAtual!.foto))
                  ? _contaAtual!.foto
                  : remoto.foto,
              emails: {..._contaAtual!.emails, ...remoto.emails}.toList(),
              biografia: _contaAtual!.biografia.isNotEmpty ? _contaAtual!.biografia : remoto.biografia,
              nomePublico: _contaAtual!.nomePublico.isNotEmpty ? _contaAtual!.nomePublico : remoto.nomePublico,
              apelidoPublico: _contaAtual!.apelidoPublico.isNotEmpty ? _contaAtual!.apelidoPublico : remoto.apelidoPublico,
              fotoPublica: _contaAtual!.fotoPublica.isNotEmpty ? _contaAtual!.fotoPublica : remoto.fotoPublica,
              dadosPrivados: _contaAtual!.dadosPrivados.isNotEmpty ? _contaAtual!.dadosPrivados : remoto.dadosPrivados,
              dadosAutorizadosPorCpf: {..._contaAtual!.dadosAutorizadosPorCpf, ...remoto.dadosAutorizadosPorCpf}.toList(),
              seguindo: {..._contaAtual!.seguindo, ...remoto.seguindo}.toList(),
              seguidores: {..._contaAtual!.seguidores, ...remoto.seguidores}.toList(),
            );
            await ContasNousService.salvar(contaAtualizada);
            _contaAtual = contaAtualizada;
            ClienteRedeLocal().atualizarIdentidadeUsuario(
              cpf: contaAtualizada.cpf,
              nome: contaAtualizada.nome,
              apelido: contaAtualizada.apelido,
              foto: contaAtualizada.foto,
            );
            notifyListeners();
          }
        } catch (_) {}
      }());

      return true;
    }

    // Se a conta não existe localmente, consulta o balcão via rede Wi-Fi local para enriquecer
    try {
      final remoto = await ClienteRedeLocal().buscarUsuarioRemoto(_cpf);
      if (remoto != null) {
        conta = remoto;
        await ContasNousService.salvar(conta);
        debugPrint(
          '[AuthProvider] Conta recuperada do balcão Wi-Fi para CPF $_cpf (${conta.nome})',
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
      ClienteRedeLocal().atualizarIdentidadeUsuario(
        cpf: conta.cpf,
        nome: conta.nome,
        apelido: conta.apelido,
        foto: conta.foto,
      );
      ServidorRedeLocal().atualizarOperadorBalcao(conta);
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
    ClienteRedeLocal().atualizarIdentidadeUsuario(
      cpf: conta.cpf,
      nome: conta.nome,
      apelido: conta.apelido,
      foto: conta.foto,
    );
    ServidorRedeLocal().atualizarOperadorBalcao(conta);
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
    if (email != null && email.isNotEmpty && _cpf.isNotEmpty) {
      salvarSessao(_cpf, email);
    }
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
    limparSessao();
    _cpf = '';
    _errorMessage = null;
    _contaAtual = null;
    _emailAtivo = null;
    _dadosReveladosDono = {};
    ThemeController.desvincularUsuario();
    ClienteRedeLocal().notificarLogout();
    unawaited(ClienteRedeLocal().desconectar(manual: true));
    ClienteRedeLocal().pararDescoberta();
    ServidorRedeLocal().atualizarOperadorBalcao(null);
    notifyListeners();
  }
}