import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/helpers/auth_conta_sincronizacao_helper.dart';
import 'package:nous/src/features/auth/providers/helpers/auth_emails_helper.dart';
import 'package:nous/src/features/auth/providers/helpers/auth_perfil_operacoes_helper.dart';
import 'package:nous/src/features/auth/providers/helpers/auth_social_operacoes_helper.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
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
  bool _disposed = false;

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
  bool get isValid => CpfValidator.isValid(_cpf);

  bool dadoEstaReveladoParaDono(String chave) =>
      _dadosReveladosDono.contains(chave);

  UsuarioNous? buscarContaPorCpf(String cpf) {
    final digitos = CpfValidator.onlyDigits(cpf);
    if (_contaAtual != null &&
        CpfValidator.onlyDigits(_contaAtual!.cpf) == digitos) {
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
    if (_contaAtual != null &&
        CpfValidator.onlyDigits(_contaAtual!.cpf) == digitos) {
      _contaAtual = conta;
    }
    notifyListeners();
  }

  Future<void> carregarDadosReveladosDono(String cpf) async {
    _dadosReveladosDono =
        await AuthPerfilOperacoesHelper.carregarDadosReveladosDono(cpf);
    notifyListeners();
  }

  Future<void> alternarRevelacaoParaDono(String chave) async {
    if (_contaAtual == null) return;
    _dadosReveladosDono =
        await AuthPerfilOperacoesHelper.alternarRevelacaoParaDono(
      cpf: _contaAtual!.cpf,
      atuais: _dadosReveladosDono,
      chave: chave,
    );
    notifyListeners();
  }

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

  String buscarFotoPorCpf(String cpf) =>
      AuthContaSincronizacaoHelper.resolverFotoPorCpf(
        cpf: cpf,
        contaAtual: _contaAtual,
        fotosPorCpf: _fotosPorCpf,
      );

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

    final contaSegura =
        await AuthContaSincronizacaoHelper.prepararContaLocal(_cpf);

    if (contaSegura != null) {
      _contaAtual = contaSegura;
      _emailAtivo =
          contaSegura.emails.isNotEmpty ? contaSegura.emails.first : null;
      await AuthContaSincronizacaoHelper.ativarSessaoLocal(contaSegura);
      await carregarDadosReveladosDono(contaSegura.cpf);
      _carregando = false;
      notifyListeners();

      unawaited(
        AuthContaSincronizacaoHelper.mesclarComRemotoEmBackground(
          cpf: _cpf,
          obterContaAtual: () => _contaAtual,
          aoAtualizar: (contaAtualizada) {
            _contaAtual = contaAtualizada;
            atualizarContaNoCache(contaAtualizada);
          },
        ),
      );
      return true;
    }

    final conta =
        await AuthContaSincronizacaoHelper.buscarUsuarioRemotoESalvar(_cpf);
    _contaAtual = conta;
    _emailAtivo = (conta != null && conta.emails.isNotEmpty)
        ? conta.emails.first
        : null;

    if (conta != null) {
      await AuthContaSincronizacaoHelper.ativarSessaoLocal(conta);
      await carregarDadosReveladosDono(conta.cpf);
    }

    _carregando = false;
    notifyListeners();
    return conta != null;
  }

  Future<void> _finalizarAssociacaoConta(
    UsuarioNous contaBase, {
    bool atualizarCache = false,
  }) async {
    final contaComChave =
        await AuthContaSincronizacaoHelper.garantirChavesCriptografia(
      contaBase,
    );
    await ContasNousService.salvar(contaComChave, permitirReativacao: true);

    _contaAtual = contaComChave;
    _emailAtivo = null;
    if (atualizarCache) {
      atualizarContaNoCache(contaComChave);
    }
    await AuthContaSincronizacaoHelper.ativarSessaoLocal(contaComChave);
    await carregarDadosReveladosDono(_cpf);
    _propagarUsuarioAtualizado(contaComChave);
    notifyListeners();
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
    await _finalizarAssociacaoConta(conta, atualizarCache: true);
  }

  Future<void> associarContaComApelido(
    String apelido, [
    String? nomeDeUsuario,
  ]) async {
    final apelidoLimpo = apelido.trim();
    final usernameLimpo =
        (nomeDeUsuario != null && nomeDeUsuario.trim().isNotEmpty)
            ? nomeDeUsuario.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '')
            : '';
    final conta = UsuarioNous(
      cpf: _cpf,
      nome: apelidoLimpo,
      apelido: apelidoLimpo,
      nomeDeUsuario: usernameLimpo,
      dataNascimento: '',
    );
    await _finalizarAssociacaoConta(conta);
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
    final conta = AuthContaSincronizacaoHelper.montarNovaContaCompleta(
      cpf: _cpf,
      nome: nome,
      apelido: apelido,
      nomeDeUsuario: nomeDeUsuario,
      foto: foto,
      biografia: biografia,
      dadosPrivados: dadosPrivados,
      termosAceitosVersao: termosAceitosVersao,
      termosAceitosEm: termosAceitosEm,
    );
    await _finalizarAssociacaoConta(conta);
  }

  Future<void> _salvarAtualizacao(UsuarioNous atualizado) async {
    _contaAtual = await AuthPerfilOperacoesHelper.salvarEPropagar(
      atualizado,
      _propagarUsuarioAtualizado,
    );
    notifyListeners();
  }

  Future<void> atualizarNome(String novoNome) async {
    final conta = _contaAtual;
    if (conta == null) return;
    await _salvarAtualizacao(conta.copyWith(nome: novoNome.trim()));
  }

  Future<void> atualizarApelido(String novoApelido) async {
    final conta = _contaAtual;
    if (conta == null) return;
    await _salvarAtualizacao(conta.copyWith(apelido: novoApelido.trim()));
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
    _contaAtual = await AuthPerfilOperacoesHelper.atualizarPerfilSocial(
      conta: conta,
      nome: nome,
      apelido: apelido,
      biografia: biografia,
      foto: foto,
      links: links,
      coresPerfil: coresPerfil,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    if (foto != null && foto.trim().isNotEmpty) {
      _fotosPorCpf[conta.cpf] = foto.trim();
    }
    notifyListeners();
  }

  void _propagarUsuarioAtualizado(UsuarioNous usuario) {
    final cpfLimpo = CpfValidator.onlyDigits(usuario.cpf);
    _contasPorCpf[cpfLimpo] = usuario;
    _contasPorCpf[usuario.cpf] = usuario;
    AuthContaSincronizacaoHelper.propagarUsuarioNaRede(usuario);
  }

  /// Atualiza e propaga na rede a organização das timelines e modo galeria do perfil.
  Future<void> atualizarOrganizacaoTimelines({
    List<String>? timelinesVisiveis,
    bool? modoFotosGaleria,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;
    await _salvarAtualizacao(
      conta.copyWith(
        timelinesVisiveis: timelinesVisiveis ?? conta.timelinesVisiveis,
        modoFotosGaleria: modoFotosGaleria ?? conta.modoFotosGaleria,
      ),
    );
  }

  Future<void> _alternarListaCpf(String cpfAlvo, {required bool bloquear}) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final atualizado = await AuthPerfilOperacoesHelper.alternarListaCpf(
      conta: conta,
      cpfAlvo: cpfAlvo,
      bloquear: bloquear,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    if (atualizado == null) return;
    _contaAtual = atualizado;
    notifyListeners();
  }

  Future<void> alternarBloquearUsuario(String cpfAlvo) =>
      _alternarListaCpf(cpfAlvo, bloquear: true);

  Future<void> alternarSilenciarUsuario(String cpfAlvo) =>
      _alternarListaCpf(cpfAlvo, bloquear: false);

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

    final resultado = await AuthEmailsHelper.adicionarEmail(
      conta: conta,
      email: email,
      verificadoGoogle: verificadoGoogle,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    if (resultado.erro != null) return resultado.erro;

    _contaAtual = resultado.contaAtualizada;
    _emailAtivo ??= email.trim().toLowerCase();
    notifyListeners();
    return null;
  }

  Future<void> marcarEmailComoVerificadoGoogle(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final atualizado = await AuthEmailsHelper.marcarEmailComoVerificadoGoogle(
      conta: conta,
      email: email,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    if (atualizado == null) return;
    _contaAtual = atualizado;
    notifyListeners();
  }

  Future<void> removerEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final resultado = await AuthEmailsHelper.removerEmail(
      conta: conta,
      email: email,
      emailAtivoAtual: _emailAtivo,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    _contaAtual = resultado.contaAtualizada;
    _emailAtivo = resultado.novoEmailAtivo;
    notifyListeners();
  }

  Future<void> excluirConta([String? cpfAlvo]) async {
    final c = _contaAtual;
    final cpfReal = cpfAlvo ?? c?.cpf ?? _cpf;
    final cpfLimpo = cpfReal.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return;

    final contaExistente =
        buscarContaPorCpf(cpfLimpo) ??
        await ContasNousService.buscarPorCpf(cpfLimpo);

    await AuthContaSincronizacaoHelper.excluirContaLocalERede(
      cpfLimpo: cpfLimpo,
      contaExistente: contaExistente,
      chaveUltimoCpf: _chaveUltimoCpf,
    );

    _fotosPorCpf.remove(cpfLimpo);
    _fotosPorCpf.remove(cpfReal);
    _contasPorCpf.remove(cpfLimpo);
    _contasPorCpf.remove(cpfReal);

    await carregarCacheContas();
    final eraContaAtual =
        c != null && CpfValidator.onlyDigits(c.cpf) == cpfLimpo;
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
    await _salvarAtualizacao(conta.copyWith(nomeDeUsuario: limpo));
  }

  Future<void> alternarPrivacidadeDado(String chave, [bool? privado]) async {
    final conta = _contaAtual;
    if (conta == null) return;
    _contaAtual = await AuthPerfilOperacoesHelper.alternarPrivacidadeDado(
      conta: conta,
      chave: chave,
      privado: privado,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    notifyListeners();
  }

  Future<void> atualizarQuemPodeEnviarMensagens(String opcao) async {
    final conta = _contaAtual;
    if (conta == null) return;
    await _salvarAtualizacao(conta.copyWith(quemPodeEnviarMensagens: opcao));
  }

  Future<void> autorizarAcessoDado(String cpfSolicitante, String chave) async {
    final conta = _contaAtual;
    if (conta == null) return;
    _contaAtual = await AuthPerfilOperacoesHelper.autorizarAcessoDado(
      conta: conta,
      cpfSolicitante: cpfSolicitante,
      chave: chave,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
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
    _contaAtual = await AuthPerfilOperacoesHelper.atualizarFoto(
      conta: conta,
      novaFoto: novaFoto,
      ehFotoPublica: false,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    _fotosPorCpf[conta.cpf] = novaFoto;
    notifyListeners();
  }

  /// Atualiza exclusivamente a foto do Perfil Público (`fotoPublica`),
  /// preservando intacta a foto da Identidade do Usuário (`foto`).
  Future<void> atualizarFotoPublica(String novaFoto) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final atualizado = await AuthPerfilOperacoesHelper.atualizarFoto(
      conta: conta,
      novaFoto: novaFoto,
      ehFotoPublica: true,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    _contaAtual = atualizado;
    _fotosPorCpf[conta.cpf] = atualizado.fotoExibicao;
    notifyListeners();
  }

  /// Atualiza a nota de pensamento (24h) exibida na nuvem da tela Mensagens.
  Future<void> atualizarNotaPensamento(
    String texto, {
    String musica = '',
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;
    final atualizado = await AuthPerfilOperacoesHelper.atualizarNotaPensamento(
      conta: conta,
      texto: texto,
      musica: musica,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    atualizarContaNoCache(atualizado);
    _contaAtual = atualizado;
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
    String? cepResidencial,
    String? enderecoResidencial,
    String? numeroResidencial,
  }) async {
    final conta = _contaAtual;
    if (conta == null) return;
    _contaAtual = await AuthPerfilOperacoesHelper.atualizarDadosPessoais(
      conta: conta,
      dataNascimento: dataNascimento,
      nomePai: nomePai,
      nomeMae: nomeMae,
      localNascimento: localNascimento,
      tipoSanguineo: tipoSanguineo,
      estadoCivil: estadoCivil,
      cepResidencial: cepResidencial,
      enderecoResidencial: enderecoResidencial,
      numeroResidencial: numeroResidencial,
      propagarUsuarioAtualizado: _propagarUsuarioAtualizado,
    );
    notifyListeners();
  }

  Future<void> revogarAcessoDado(String chave, String cpfAlvo) async {
    final conta = _contaAtual;
    if (conta == null) return;
    await _salvarAtualizacao(conta.revogarAutorizacao(chave, cpfAlvo));
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
