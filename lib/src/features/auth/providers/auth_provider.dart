import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/helpers/auth_social_operacoes_helper.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
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

  static Future<void> limparSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveSessaoCpf);
      await prefs.remove(_chaveSessaoEmail);
    } catch (_) {}
  }

  AuthProvider() {
    limparSessao();
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
  bool _modoVisitante = false;

  String get cpf => _cpf;
  String? get errorMessage => _errorMessage;
  bool get carregando => _carregando;
  UsuarioNous? get contaAtual => _contaAtual;
  String? get emailAtivo => _emailAtivo;
  Set<String> get dadosReveladosDono => _dadosReveladosDono;
  List<UsuarioNous> get contasCache => _contasPorCpf.values.toList();
  bool get modoVisitante => _modoVisitante;
  bool get usuarioAtualVerificado => _contaAtual?.possuiValidacao ?? false;
  bool get perfilIsolado =>
      !_modoVisitante && _contaAtual != null && !usuarioAtualVerificado;

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
    final lista = await PreferenciasSoberanasService.obterLista(
      'dados_revelados_$digitos',
    );
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
    await PreferenciasSoberanasService.salvarLista(
      'dados_revelados_$digitos',
      _dadosReveladosDono.toList(),
    );
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
    await ContasNousService.varrerECorrigirBanco();
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

    _modoVisitante = false;
    _carregando = true;
    notifyListeners();

    var conta = await ContasNousService.buscarPorCpf(_cpf);

    // 1. Se não encontrou no banco de contas local, tenta enriquecer e consolidar a partir de dados locais (clientes e membros)
    // desde que a conta não tenha sido explicitamente excluída pelo usuário.
    if (conta == null && !await ContasExcluidasService.estaExcluido(_cpf)) {
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

      // Garante chave pública Ed25519 e chave de troca X25519 no perfil soberano do usuário
      try {
        final chavePub = await CriptografiaService.obterOuGerarChavePublica(contaSegura.cpf);
        final chaveTroca = await CriptografiaService.obterOuGerarChaveTroca(contaSegura.cpf);
        var precisaSalvar = false;
        if (chavePub.isNotEmpty && contaSegura.chavePublica != chavePub) {
          contaSegura = contaSegura.copyWith(chavePublica: chavePub);
          precisaSalvar = true;
        }
        if (chaveTroca.isNotEmpty && contaSegura.chaveTrocaPublica != chaveTroca) {
          contaSegura = contaSegura.copyWith(chaveTrocaPublica: chaveTroca);
          precisaSalvar = true;
        }
        if (precisaSalvar) {
          await ContasNousService.salvar(contaSegura);
        }
      } catch (e) {
        debugPrint('[AuthProvider] Erro ao sincronizar chaves de criptografia: $e');
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

    final chavePub = await CriptografiaService.obterOuGerarChavePublica(_cpf);
    final chaveTroca = await CriptografiaService.obterOuGerarChaveTroca(_cpf);
    final contaComChave = conta.copyWith(
      chavePublica: chavePub,
      chaveTrocaPublica: chaveTroca,
    );

    await ContasNousService.salvar(contaComChave, permitirReativacao: true);

    _contaAtual = contaComChave;
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

    final chavePub = await CriptografiaService.obterOuGerarChavePublica(_cpf);
    final chaveTroca = await CriptografiaService.obterOuGerarChaveTroca(_cpf);
    final contaComChave = conta.copyWith(
      chavePublica: chavePub,
      chaveTrocaPublica: chaveTroca,
    );

    await ContasNousService.salvar(contaComChave, permitirReativacao: true);

    _contaAtual = contaComChave;
    _emailAtivo = null;
    await ThemeController.carregarTemaDoUsuario(_cpf);
    await carregarDadosReveladosDono(_cpf);
    ClienteRedeLocal().atualizarIdentidadeUsuario(
      cpf: contaComChave.cpf,
      nome: contaComChave.nome,
      apelido: contaComChave.apelido,
      foto: contaComChave.foto,
    );
    ServidorRedeLocal().atualizarOperadorBalcao(contaComChave);
    _propagarUsuarioAtualizado(contaComChave);
    notifyListeners();
  }

  Future<void> registrarNovaContaCompleta({
    required String nome,
    required String apelido,
    required String nomeDeUsuario,
    required String foto,
    required String biografia,
    required List<String> dadosPrivados,
    String termosAceitosVersao = '',
    String termosAceitosEm = '',
  }) async {
    _modoVisitante = false;
    final apelidoLimpo = apelido.trim().isNotEmpty ? apelido.trim() : nome.trim();
    final usernameLimpo = nomeDeUsuario
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('@', '');
    final hojeIso = DateTime.now().toIso8601String();

    final conta = UsuarioNous(
      cpf: _cpf,
      nome: nome.trim(),
      apelido: apelidoLimpo,
      nomeDeUsuario: usernameLimpo,
      dataNascimento: '',
      foto: foto.trim(),
      fotoPublica: foto.trim(),
      biografia: biografia.trim(),
      dadosPrivados: dadosPrivados,
      criadoEm: hojeIso,
      validadoPorNome: 'Rede Soberana Nous',
      validadoEm: hojeIso,
      verificado: true,
      termosAceitosVersao: termosAceitosVersao,
      termosAceitosEm: termosAceitosEm,
    );

    final chavePub = await CriptografiaService.obterOuGerarChavePublica(_cpf);
    final chaveTroca = await CriptografiaService.obterOuGerarChaveTroca(_cpf);
    final contaComChave = conta.copyWith(
      chavePublica: chavePub,
      chaveTrocaPublica: chaveTroca,
    );

    await ContasNousService.salvar(contaComChave, permitirReativacao: true);

    _contaAtual = contaComChave;
    _emailAtivo = null;
    await ThemeController.carregarTemaDoUsuario(_cpf);
    await carregarDadosReveladosDono(_cpf);
    ClienteRedeLocal().atualizarIdentidadeUsuario(
      cpf: contaComChave.cpf,
      nome: contaComChave.nome,
      apelido: contaComChave.apelido,
      foto: contaComChave.foto,
    );
    ServidorRedeLocal().atualizarOperadorBalcao(contaComChave);
    _propagarUsuarioAtualizado(contaComChave);
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
    List<String>? links,
    Map<String, String>? coresPerfil,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(
      nomePublico: nome.trim(),
      apelidoPublico: apelido.trim(),
      biografia: biografia.trim(),
      fotoPublica: foto != null ? foto.trim() : conta.fotoPublica,
      links: links ?? conta.links,
      coresPerfil: coresPerfil ?? conta.coresPerfil,
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
    final cpfLimpo = CpfValidator.onlyDigits(usuario.cpf);
    _contasPorCpf[cpfLimpo] = usuario;
    _contasPorCpf[usuario.cpf] = usuario;
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

  Future<String?> adicionarEmail(
    String email, {
    bool verificadoGoogle = false,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return 'Nenhuma conta carregada.';

    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return 'Informe um e-mail válido.';
    }

    final jaExisteNaConta = conta.emails.any(
      (e) => e.trim().toLowerCase() == emailLimpo,
    );
    if (jaExisteNaConta && !verificadoGoogle) {
      return 'Este e-mail já está nesta conta.';
    }

    final donoAtual = await ContasNousService.buscarCpfDoEmail(emailLimpo);
    if (donoAtual != null && donoAtual != conta.cpf) {
      return 'Este e-mail já está associado a outro CPF.';
    }

    final novosEmails = jaExisteNaConta
        ? conta.emails
        : [...conta.emails, emailLimpo];
    final novosVerificados = verificadoGoogle && !conta.emailEstaVerificado(emailLimpo)
        ? [...conta.emailsVerificados, emailLimpo]
        : conta.emailsVerificados;

    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: novosVerificados,
    );
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _emailAtivo ??= emailLimpo;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
    return null;
  }

  Future<void> marcarEmailComoVerificadoGoogle(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || conta.emailEstaVerificado(emailLimpo)) return;

    final novosEmails = conta.emails.any((e) => e.trim().toLowerCase() == emailLimpo)
        ? conta.emails
        : [...conta.emails, emailLimpo];
    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: [...conta.emailsVerificados, emailLimpo],
    );
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _propagarUsuarioAtualizado(atualizado);
    notifyListeners();
  }

  Future<void> removerEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final emailLimpo = email.trim().toLowerCase();
    final novosEmails =
        conta.emails.where((e) => e.trim().toLowerCase() != emailLimpo).toList();
    final novosVerificados = conta.emailsVerificados
        .where((e) => e.trim().toLowerCase() != emailLimpo)
        .toList();
    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: novosVerificados,
    );
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;

    if (_emailAtivo?.trim().toLowerCase() == emailLimpo) {
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

    final contaExistente =
        buscarContaPorCpf(cpfLimpo) ?? await ContasNousService.buscarPorCpf(cpfLimpo);
    final regExcluida = contaExistente != null
        ? await ContasExcluidasService.registrarExclusao(contaExistente)
        : null;

    await ContasNousService.excluir(cpfLimpo);

    try {
      final coletiva = await LojasService.carregarLojaPorId('loja_nous_coletiva');
      if (coletiva != null) {
        final membrosAtualizados = coletiva.membros
            .where((m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpfLimpo)
            .toList();
        if (membrosAtualizados.length != coletiva.membros.length) {
          await LojasService.salvarLojaIndividual(
            coletiva.copyWith(membros: membrosAtualizados),
          );
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getString(_chaveUltimoCpf);
    if (ultimo != null &&
        ultimo.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
      await prefs.remove(_chaveUltimoCpf);
    }

    _fotosPorCpf.remove(cpfLimpo);
    _fotosPorCpf.remove(cpfReal);
    _contasPorCpf.remove(cpfLimpo);
    _contasPorCpf.remove(cpfReal);

    final evento = <String, dynamic>{
      'tipo': 'usuario_nous_excluido',
      'cpf': cpfLimpo,
      if (regExcluida != null) 'registro': regExcluida.toJson(),
    };
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarEventoWs(evento);
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos(evento);
    }

    await carregarCacheContas();
    final eraContaAtual = c != null &&
        CpfValidator.onlyDigits(c.cpf) == cpfLimpo;
    if (eraContaAtual) {
      sair();
    } else {
      notifyListeners();
    }
  }

  /// Valida a identidade de outro usuário Nous com assinatura digital Ed25519
  /// e registra na lista cronológica de validações do alvo.
  Future<UsuarioNous?> validarIdentidadeUsuario(UsuarioNous alvo) async {
    final validador = _contaAtual;
    if (validador == null) return null;
    final resultado = await AuthSocialOperacoesHelper.validarIdentidadeUsuario(
      validador: validador,
      alvo: alvo,
      buscarContaPorCpf: buscarContaPorCpf,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    if (resultado != null) notifyListeners();
    return resultado;
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

  Future<void> atualizarQuemPodeEnviarMensagens(String opcao) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final atualizado = conta.copyWith(quemPodeEnviarMensagens: opcao);
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
    _contaAtual = await AuthSocialOperacoesHelper.alternarSeguir(
      conta: conta,
      cpfAlvo: cpfAlvo,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
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

  /// Atualiza exclusivamente a foto do Perfil Público (`fotoPublica`),
  /// preservando intacta a foto da Identidade do Usuário (`foto`).
  Future<void> atualizarFotoPublica(String novaFoto) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final atualizado = conta.copyWith(fotoPublica: novaFoto.trim());
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    _fotosPorCpf[conta.cpf] = atualizado.fotoExibicao;
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

  void entrarComoVisitante() {
    limparSessao();
    _cpf = '';
    _errorMessage = null;
    _contaAtual = null;
    _emailAtivo = null;
    _dadosReveladosDono = {};
    _modoVisitante = true;
    ThemeController.desvincularUsuario();
    notifyListeners();
  }

  void sair() {
    limparSessao();
    _cpf = '';
    _errorMessage = null;
    _contaAtual = null;
    _emailAtivo = null;
    _dadosReveladosDono = {};
    _modoVisitante = false;
    ThemeController.desvincularUsuario();
    ClienteRedeLocal().notificarLogout();
    unawaited(ClienteRedeLocal().desconectar(manual: true));
    ClienteRedeLocal().pararDescoberta();
    ServidorRedeLocal().atualizarOperadorBalcao(null);
    notifyListeners();
  }
}