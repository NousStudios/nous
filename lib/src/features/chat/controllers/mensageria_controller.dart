import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_acoes_mensagem_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_busca_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_conversa_ativa_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_filtros_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_inicializacao_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_recursos_extras_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/mensageria_acoes_delegate.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Orquestrador de estado reativo da Mensageria Nous.
/// Modularizado seguindo a arquitetura limpa (< 600 linhas).
class MensageriaController extends ChangeNotifier {
  bool modoLoja = false;
  String? lojaId;
  String? nomeLoja;
  String? logoLoja;
  String? operadorNome;
  String? operadorCpf;
  String? usuarioNome;
  String? usuarioCpf;
  String? usuarioFoto;
  String? usuarioApelido;
  String? conversaInicialId;

  List<ConversaChat> _conversas = [];
  List<ConversaChat> _todosContatosDisponiveis = [];
  ConversaChat? _conversaSelecionada;
  String _termoBusca = '';
  bool _carregando = false;
  Map<String, String> _titulosCustomizados = {};
  final Map<String, UsuarioNous> _usuariosNousPorCpf = {};

  bool _exibindoSolicitacoes = false;
  bool get exibindoSolicitacoes => _exibindoSolicitacoes;

  AbaNavegacaoMensageria _abaAtiva = AbaNavegacaoMensageria.conversas;
  AbaNavegacaoMensageria get abaAtiva => _abaAtiva;

  TipoFiltroChat _filtroAtivo = TipoFiltroChat.tudo;
  TipoFiltroChat get filtroAtivo => _filtroAtivo;

  String? _filtroPersonalizadoId;
  String? get filtroPersonalizadoId => _filtroPersonalizadoId;

  List<FiltroChatPersonalizado> _filtrosPersonalizados = [];
  List<FiltroChatPersonalizado> get filtrosPersonalizados =>
      _filtrosPersonalizados;

  int get totalConversasNaoLidas =>
      _conversas.fold<int>(0, (acc, c) => acc + c.naoLidasCount);

  List<ConversaChat> get conversas => _conversas;
  List<ConversaChat> get todosContatosDisponiveis => _todosContatosDisponiveis;
  ConversaChat? get conversaSelecionada => _conversaSelecionada;
  String get termoBusca => _termoBusca;
  bool get carregando => _carregando;
  Map<String, String> get titulosCustomizados => _titulosCustomizados;
  Map<String, UsuarioNous> get usuariosNousPorCpf => _usuariosNousPorCpf;

  bool _disposed = false;
  bool get isDisposed => _disposed;
  Timer? _timerPollingLeve;
  int _versaoRecargaConversas = 0;

  @override
  void dispose() {
    _timerPollingLeve?.cancel();
    _timerPollingLeve = null;
    ChatService.idConversaAtiva = null;
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  String get idVisualizador {
    if (modoLoja) {
      final lid = lojaId ?? '';
      if (lid.isEmpty) return 'loja';
      return lid.startsWith('loja_') ? lid : 'loja_$lid';
    }
    return usuarioCpf ?? 'usuario';
  }

  MensagemChat? _mensagemRespondendo;
  MensagemChat? get mensagemRespondendo => _mensagemRespondendo;

  void definirMensagemRespondendo(MensagemChat? msg) {
    _mensagemRespondendo = msg;
    notifyListeners();
  }

  void configurar({
    required bool modoLoja,
    String? lojaId,
    String? nomeLoja,
    String? logoLoja,
    String? operadorNome,
    String? operadorCpf,
    String? usuarioNome,
    String? usuarioCpf,
    String? usuarioFoto,
    String? usuarioApelido,
    String? conversaInicialId,
  }) {
    this.modoLoja = modoLoja;
    this.lojaId = lojaId;
    this.nomeLoja = nomeLoja;
    this.logoLoja = logoLoja;
    this.operadorNome = operadorNome;
    this.operadorCpf = operadorCpf;
    this.usuarioNome = usuarioNome;
    this.usuarioCpf = usuarioCpf;
    this.usuarioFoto = usuarioFoto;
    this.usuarioApelido = usuarioApelido;
    this.conversaInicialId = conversaInicialId;
    if (this.usuarioCpf != null) {
      MensageriaSolicitacoesHelper.carregarAceitas(this.usuarioCpf!);
    }
  }

  bool ehSolicitacao(ConversaChat c, {UsuarioNous? contaLogada}) {
    return MensageriaSolicitacoesHelper.ehSolicitacao(
      conversa: c,
      modoLoja: modoLoja,
      meuCpf: usuarioCpf ?? '',
      contaLogada: contaLogada,
    );
  }

  int totalSolicitacoes({UsuarioNous? contaLogada}) => _conversas
      .where((c) => ehSolicitacao(c, contaLogada: contaLogada))
      .length;

  void alternarExibindoSolicitacoes(bool valor) {
    _exibindoSolicitacoes = valor;
    notifyListeners();
  }

  Future<void> aceitarSolicitacao(ConversaChat c) async {
    await MensageriaSolicitacoesHelper.aceitarSolicitacao(
      conversaId: c.id,
      meuCpf: usuarioCpf ?? '',
    );
    notifyListeners();
  }

  Future<void> recusarSolicitacao(
    ConversaChat c, {
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    await MensageriaSolicitacoesHelper.recusarSolicitacao(c.id);
    if (_conversaSelecionada?.id == c.id) {
      _conversaSelecionada = null;
    }
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: false);
  }

  void atualizarTermoBusca(String termo) {
    _termoBusca = termo.trim().toLowerCase();
    notifyListeners();
  }

  String resumoMensagem(MensagemChat msg) =>
      MontadorConversasChat.resumoMensagem(msg);

  bool combinaBusca(ConversaChat c, String termo) =>
      MensageriaBuscaHelper.combinaBusca(
        c: c,
        termo: termo,
        modoLoja: modoLoja,
        operadorCpf: operadorCpf,
        usuarioCpf: usuarioCpf,
        usuariosNousPorCpf: _usuariosNousPorCpf,
      );

  void selecionarAba(AbaNavegacaoMensageria aba) {
    if (_abaAtiva == aba) return;
    _abaAtiva = aba;
    notifyListeners();
  }

  void selecionarFiltro(TipoFiltroChat tipo, {String? personalizadoId}) {
    _filtroAtivo = tipo;
    _filtroPersonalizadoId =
        tipo == TipoFiltroChat.personalizado ? personalizadoId : null;
    notifyListeners();
  }

  Future<void> carregarFiltrosPersonalizados() async {
    _filtrosPersonalizados = await ChatRecursosExtrasService.listarFiltros();
    notifyListeners();
  }

  Future<FiltroChatPersonalizado> criarFiltroPersonalizado(String nome) async {
    final novo = FiltroChatPersonalizado(
      id: 'filtro_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim(),
      ordem: _filtrosPersonalizados.length,
      criadoEm: DateTime.now(),
    );
    await ChatRecursosExtrasService.salvarFiltro(novo);
    _filtrosPersonalizados = [..._filtrosPersonalizados, novo];
    notifyListeners();
    return novo;
  }

  Future<void> renomearFiltroPersonalizado(
    FiltroChatPersonalizado filtro,
    String novoNome,
  ) async {
    final atualizado = filtro.copyWith(nome: novoNome.trim());
    await ChatRecursosExtrasService.salvarFiltro(atualizado);
    _filtrosPersonalizados = _filtrosPersonalizados
        .map((f) => f.id == filtro.id ? atualizado : f)
        .toList();
    notifyListeners();
  }

  Future<void> excluirFiltroPersonalizado(String filtroId) async {
    await ChatRecursosExtrasService.excluirFiltro(filtroId);
    _filtrosPersonalizados =
        _filtrosPersonalizados.where((f) => f.id != filtroId).toList();
    if (_filtroAtivo == TipoFiltroChat.personalizado &&
        _filtroPersonalizadoId == filtroId) {
      _filtroAtivo = TipoFiltroChat.tudo;
      _filtroPersonalizadoId = null;
    }
    notifyListeners();
  }

  Future<void> alternarConversaNoFiltro({
    required String filtroId,
    required String conversaId,
  }) async {
    final atualizado = await ChatRecursosExtrasService.alternarConversaNoFiltro(
      filtroId: filtroId,
      conversaId: conversaId,
    );
    if (atualizado != null) {
      _filtrosPersonalizados = _filtrosPersonalizados
          .map((f) => f.id == filtroId ? atualizado : f)
          .toList();
      notifyListeners();
    }
  }

  Future<void> alternarFavoritaConversa(ConversaChat c) async {
    final novo = await ChatRecursosExtrasService.alternarFavoritaConversa(c.id);
    _conversas = _conversas
        .map((item) => item.id == c.id ? item.copyWith(favorita: novo) : item)
        .toList();
    if (_conversaSelecionada?.id == c.id) {
      _conversaSelecionada = _conversaSelecionada!.copyWith(favorita: novo);
    }
    notifyListeners();
  }

  List<ConversaChat> obterConversasFiltradas({UsuarioNous? contaLogada}) {
    final todas = MensageriaBuscaHelper.filtrarConversas(
      conversas: _conversas,
      todosContatosDisponiveis: _todosContatosDisponiveis,
      termoBusca: _termoBusca,
      modoLoja: modoLoja,
      operadorCpf: operadorCpf,
      usuarioCpf: usuarioCpf,
      usuariosNousPorCpf: _usuariosNousPorCpf,
    );

    final base = modoLoja
        ? todas
        : todas
            .where((c) =>
                ehSolicitacao(c, contaLogada: contaLogada) ==
                _exibindoSolicitacoes)
            .toList();

    if (_exibindoSolicitacoes) return base;
    return MensageriaFiltrosHelper.aplicarFiltro(
      conversas: base,
      tipoFiltro: _filtroAtivo,
      filtroPersonalizadoId: _filtroPersonalizadoId,
      filtrosPersonalizados: _filtrosPersonalizados,
    );
  }

  bool _conversaInicialConsumida = false;
  static bool _manutencaoChatExecutadaNaSessao = false;

  Future<void> inicializar({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    if (_disposed) return;
    try {
      final identidade =
          await MensageriaInicializacaoHelper.resolverIdentidadeUsuario(
        auth: auth,
        pdv: pdv,
        usuarioCpf: usuarioCpf,
        usuarioNome: usuarioNome,
        usuarioFoto: usuarioFoto,
        usuarioApelido: usuarioApelido,
        isDisposed: () => _disposed,
      );
      if (_disposed) return;
      usuarioCpf = identidade.usuarioCpf;
      usuarioNome = identidade.usuarioNome;
      usuarioFoto = identidade.usuarioFoto;
      usuarioApelido = identidade.usuarioApelido;

      _carregando = true;
      notifyListeners();

      if (usuarioCpf != null && usuarioCpf!.isNotEmpty) {
        await MensageriaSolicitacoesHelper.carregarAceitas(usuarioCpf!);
      }
      await carregarFiltrosPersonalizados();
      if (_disposed) return;
      await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: false);
      if (_disposed) return;

      if (conversaInicialId != null &&
          conversaInicialId!.isNotEmpty &&
          !_conversaInicialConsumida) {
        _conversaInicialConsumida = true;
        await MensageriaInicializacaoHelper.abrirConversaInicialSeHouver(
          conversaInicialId: conversaInicialId,
          conversas: _conversas,
          todosContatosDisponiveis: _todosContatosDisponiveis,
          auth: auth,
          pdv: pdv,
          usuarioCpf: usuarioCpf,
          onAbrir: selecionarOuIniciarConversa,
        );
      }

      sincronizarComRedeLocal(auth: auth, pdv: pdv);
      _iniciarPollingLeve(auth: auth);

      if (!_manutencaoChatExecutadaNaSessao) {
        _manutencaoChatExecutadaNaSessao = true;
        MensageriaInicializacaoHelper.executarManutencaoSessao();
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void _iniciarPollingLeve({required AuthProvider auth}) {
    _timerPollingLeve?.cancel();
    _timerPollingLeve = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_disposed) return;
      MensageriaInicializacaoHelper.executarTickPolling(
        auth: auth,
        modoLoja: modoLoja,
        lojaId: lojaId,
        usuarioCpf: usuarioCpf,
      );
    });
  }

  void sincronizarComRedeLocal({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) {
    MensageriaInicializacaoHelper.sincronizarComRedeLocal(
      auth: auth,
      pdv: pdv,
      modoLoja: modoLoja,
      lojaId: lojaId,
      usuarioCpf: usuarioCpf,
      isDisposed: () => _disposed,
      onSincronizado: () =>
          recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true),
    );
  }

  Future<void> recarregarConversas({
    required AuthProvider auth,
    required PdvProvider pdv,
    bool manterSelecionada = true,
  }) async {
    if (_disposed) return;
    final minhaVersao = ++_versaoRecargaConversas;
    try {
      usuarioCpf = await MensageriaInicializacaoHelper.resolverCpfUsuario(
        auth: auth,
        pdv: pdv,
        usuarioCpf: usuarioCpf,
        deveCancelar: () => _disposed || minhaVersao != _versaoRecargaConversas,
      );
      if (_disposed || minhaVersao != _versaoRecargaConversas) return;

      final resultado = await MontadorConversasChat.montarConversas(
        auth: auth,
        pdv: pdv,
        modoLoja: modoLoja,
        lojaId: lojaId,
        operadorCpf: operadorCpf,
        usuarioCpf: usuarioCpf,
        conversaSelecionada: _conversaSelecionada,
      );
      if (_disposed || minhaVersao != _versaoRecargaConversas) return;

      _conversas = resultado.conversas;
      _todosContatosDisponiveis = resultado.todosDisponiveis;
      _usuariosNousPorCpf.clear();
      _usuariosNousPorCpf.addAll(resultado.usuariosNousPorCpf);
      _titulosCustomizados = resultado.titulosCustomizados;

      if (manterSelecionada && _conversaSelecionada != null) {
        _conversaSelecionada =
            MensageriaConversaAtivaHelper.reconciliarSelecionadaAposRecarga(
          conversas: _conversas,
          selecionadaAtual: _conversaSelecionada,
          idVisualizador: idVisualizador,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[MensageriaController] Erro ao recarregar conversas: $e');
    }
  }

  void _aplicarConversaAtualizada(ConversaChat c) {
    _conversaSelecionada = c;
    notifyListeners();
  }

  Future<void> selecionarOuIniciarConversa({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
  }) async {
    if (_disposed) return;
    if (MensageriaConversaAtivaHelper.deveIgnorarConversaColetiva(
      ehLoja: ehLoja,
      identificador: identificador,
      convId: convId,
      titulo: titulo,
      idLojaColetiva: PdvProvider.idLojaColetivaNous,
    )) {
      return;
    }

    final index = _conversas.indexWhere((c) => c.id == convId);
    if (index != -1) {
      selecionarConversa(_conversas[index]);
      return;
    }

    final ehConvLojaUsuario =
        convId.startsWith('loja_') && convId.contains('_usuario_');
    final lojaIdResolvido = MensageriaConversaAtivaHelper.resolverLojaIdConversa(
      convId: convId,
      modoLoja: modoLoja,
      lojaId: lojaId,
      ehLoja: ehLoja,
      identificador: identificador,
    );

    final novaConversaOtimista =
        MensageriaConversaAtivaHelper.montarConversaOtimista(
      convId: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja,
      ehConvLojaUsuario: ehConvLojaUsuario,
      lojaIdResolvido: lojaIdResolvido,
    );

    _conversaSelecionada = novaConversaOtimista;
    ChatService.idConversaAtiva = convId;
    _conversas.insert(0, novaConversaOtimista);
    notifyListeners();

    MensageriaConversaAtivaHelper.iniciarPersistenciaConversaNova(
      convId: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja,
      ehConvLojaUsuario: ehConvLojaUsuario,
      modoLoja: modoLoja,
      lojaId: lojaId,
      lojaIdResolvido: lojaIdResolvido,
      usuarioCpf: usuarioCpf,
      idVisualizador: idVisualizador,
      resumoMensagem: resumoMensagem,
      isDisposed: () => _disposed,
      onConversaHidratada: (conversa) {
        final i = _conversas.indexWhere((c) => c.id == convId);
        if (i != -1) _conversas[i] = conversa;
        if (_conversaSelecionada?.id == convId) {
          _conversaSelecionada = conversa;
        }
        notifyListeners();
      },
      onMarcarComoLida: marcarComoLida,
    );
  }

  void selecionarConversa(ConversaChat? c) {
    if (_conversaSelecionada?.id != c?.id) {
      _mensagemRespondendo = null;
    }
    if (c == null) {
      _conversaSelecionada = null;
      ChatService.idConversaAtiva = null;
      MensageriaConversaAtivaHelper.salvarUltimaConversaAberta(
        convId: '',
        modoLoja: modoLoja,
        lojaId: lojaId,
        usuarioCpf: usuarioCpf,
      );
      notifyListeners();
      return;
    }

    final conversaAtualizada =
        MensageriaConversaAtivaHelper.prepararConversaSelecionada(
      nova: c,
      selecionadaAtual: _conversaSelecionada,
    );
    _conversaSelecionada = conversaAtualizada;
    ChatService.idConversaAtiva = c.id;

    final idx = _conversas.indexWhere((item) => item.id == c.id);
    if (idx != -1) {
      _conversas[idx] = conversaAtualizada;
    } else {
      _conversas.insert(0, conversaAtualizada);
    }
    notifyListeners();

    MensageriaConversaAtivaHelper.sincronizarAberturaConversa(
      conversa: conversaAtualizada,
      estavaNaLista: idx != -1,
      modoLoja: modoLoja,
      lojaId: lojaId,
      usuarioCpf: usuarioCpf,
      idVisualizador: idVisualizador,
      resumoMensagem: resumoMensagem,
      deveAplicar: () => !_disposed && _conversaSelecionada?.id == c.id,
      onMensagensCarregadas: (comMsgs) {
        _conversaSelecionada = comMsgs;
        final i = _conversas.indexWhere((item) => item.id == c.id);
        if (i != -1) _conversas[i] = comMsgs;
        notifyListeners();
      },
    );
  }

  Future<void> recarregarMensagensConversaAtiva() async {
    if (_disposed || _conversaSelecionada == null) return;
    final convId = _conversaSelecionada!.id;
    try {
      final msgs = await ChatService.carregarMensagens(
        convId,
        idVisualizador: idVisualizador,
      );
      if (_disposed || _conversaSelecionada?.id != convId) return;

      final comMsgs = MensageriaConversaAtivaHelper.mesclarMensagensRecarregadas(
        conversaAtual: _conversaSelecionada!,
        msgsBanco: msgs,
        resumoMensagem: resumoMensagem,
      );
      if (comMsgs == null) return;

      _conversaSelecionada = comMsgs;
      final i = _conversas.indexWhere((item) => item.id == convId);
      if (i != -1) {
        _conversas[i] = comMsgs;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marcarComoLida(ConversaChat conversa) async {
    final res = await MensageriaConversaAtivaHelper.marcarConversaComoLida(
      conversa: conversa,
      conversas: _conversas,
      selecionadaAtual: _conversaSelecionada,
      idVisualizador: idVisualizador,
      isDisposed: () => _disposed,
    );
    if (_disposed || !res.alterou) return;
    _conversaSelecionada = res.selecionada;
    notifyListeners();
  }

  Future<void> enviarMensagem({
    required String texto,
    String tipo = 'texto',
    String caminhoAnexo = '',
    String nomeAnexo = '',
    int tamanhoAnexo = 0,
    String pedidoId = '',
    String dadosPedidoJson = '',
    required AuthProvider auth,
  }) async {
    if (texto.trim().isEmpty && tipo == 'texto') return;
    if (_conversaSelecionada == null) return;
    final resp = _mensagemRespondendo;
    _mensagemRespondendo = null;
    MensageriaConversaAtivaHelper.enviarMensagemComConfirmacao(
      conversaSelecionada: _conversaSelecionada!,
      conversas: _conversas,
      mensagemRespondendo: resp,
      texto: texto,
      tipo: tipo,
      caminhoAnexo: caminhoAnexo,
      nomeAnexo: nomeAnexo,
      tamanhoAnexo: tamanhoAnexo,
      pedidoId: pedidoId,
      dadosPedidoJson: dadosPedidoJson,
      modoLoja: modoLoja,
      lojaId: lojaId,
      nomeLoja: nomeLoja,
      logoLoja: logoLoja,
      operadorNome: operadorNome,
      operadorCpf: operadorCpf,
      usuarioNome: usuarioNome,
      usuarioCpf: usuarioCpf,
      usuarioFoto: usuarioFoto,
      auth: auth,
      resumoMensagem: resumoMensagem,
      isDisposed: () => _disposed,
      getConversaSelecionada: () => _conversaSelecionada,
      onConversaAtualizada: _aplicarConversaAtualizada,
    );
  }

  Future<void> encaminharMensagem({
    required MensagemChat msgOriginal,
    required ConversaChat destino,
    required AuthProvider auth,
  }) =>
      MensageriaAcoesDelegate.encaminharMensagem(
        msgOriginal: msgOriginal,
        destino: destino,
        auth: auth,
        modoLoja: modoLoja,
        lojaId: lojaId,
        nomeLoja: nomeLoja,
        logoLoja: logoLoja,
        usuarioCpf: usuarioCpf,
        usuarioNome: usuarioNome,
      );

  Future<void> editarMensagem(MensagemChat msg, String novoTexto) =>
      MensageriaAcoesMensagemHelper.editar(
        msg: msg,
        novoTexto: novoTexto,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: _aplicarConversaAtualizada,
      );

  Future<void> excluirMensagemLocal(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.excluir(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: _aplicarConversaAtualizada,
      );

  Future<void> alternarFavoritarMensagem(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.alternarFavoritar(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: _aplicarConversaAtualizada,
      );

  Future<void> alternarFixarMensagem(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.alternarFixar(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: _aplicarConversaAtualizada,
      );

  Future<void> reagirMensagem(MensagemChat msg, String emoji) =>
      MensageriaAcoesMensagemHelper.reagir(
        msg: msg,
        emoji: emoji,
        modoLoja: modoLoja,
        lojaId: lojaId,
        usuarioCpf: usuarioCpf,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: _aplicarConversaAtualizada,
      );

  Future<void> _executarERecarregar(
    Future<void> Function() acao,
    AuthProvider auth,
    PdvProvider pdv,
  ) async {
    await acao();
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  Future<void> alternarSilenciar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) =>
      _executarERecarregar(() => ChatService.alternarSilenciarConversa(c.id), auth, pdv);

  Future<void> alternarFixar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) =>
      _executarERecarregar(() => ChatService.alternarFixarConversa(c.id), auth, pdv);

  Future<void> alternarArquivar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) =>
      _executarERecarregar(() => ChatService.alternarArquivarConversa(c.id), auth, pdv);

  Future<void> renomearConversa(ConversaChat c, String novoTitulo, {required AuthProvider auth, required PdvProvider pdv}) async {
    final tLimpo = novoTitulo.trim();
    await ChatService.renomearConversa(c.id, tLimpo);
    if (_conversaSelecionada?.id == c.id) {
      _conversaSelecionada = c.copyWith(tituloConversa: tLimpo);
    }
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  void limpar() {
    ChatService.idConversaAtiva = null;
    _conversas.clear();
    _todosContatosDisponiveis.clear();
    _conversaSelecionada = null;
    _usuariosNousPorCpf.clear();
    _titulosCustomizados.clear();
    ResolvedorFotoChat.instancia.limpar();
  }
}
