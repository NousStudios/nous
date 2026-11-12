import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_acoes_mensagem_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_busca_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_mensagem_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/mensageria_acoes_delegate.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

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

  int totalSolicitacoes({UsuarioNous? contaLogada}) {
    return _conversas
        .where((c) => ehSolicitacao(c, contaLogada: contaLogada))
        .length;
  }

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

    if (modoLoja) return todas;

    if (_exibindoSolicitacoes) {
      return todas
          .where((c) => ehSolicitacao(c, contaLogada: contaLogada))
          .toList();
    } else {
      return todas
          .where((c) => !ehSolicitacao(c, contaLogada: contaLogada))
          .toList();
    }
  }

  bool _conversaInicialConsumida = false;

  Future<void> inicializar({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    if (_disposed) return;
    final conta = auth.contaAtual;
    if (usuarioCpf == null || usuarioCpf!.trim().isEmpty) {
      final cpfCandidato = conta?.cpf ??
          (auth.cpf.trim().isNotEmpty
              ? auth.cpf.trim()
              : (pdv.cpfAtual?.trim() ?? ''));
      if (cpfCandidato.isNotEmpty) {
        usuarioCpf = cpfCandidato;
      } else {
        final cpfLocal = await ChatService.obterCpfLogadoLocal();
        if (_disposed) return;
        if (cpfLocal.isNotEmpty) usuarioCpf = cpfLocal;
      }
    }
    if (usuarioNome == null || usuarioNome!.isEmpty) {
      usuarioNome = conta?.nomeExibicao ?? conta?.nome;
      if ((usuarioNome == null || usuarioNome!.isEmpty) &&
          usuarioCpf != null &&
          usuarioCpf!.isNotEmpty) {
        final u = auth.buscarContaPorCpf(usuarioCpf!);
        if (u != null) {
          usuarioNome = u.nomeExibicao.isNotEmpty ? u.nomeExibicao : u.nome;
          usuarioFoto ??= u.fotoExibicao.isNotEmpty ? u.fotoExibicao : u.foto;
          usuarioApelido ??=
              u.apelidoExibicao.isNotEmpty ? u.apelidoExibicao : u.apelido;
        }
      }
    }
    if (usuarioFoto == null || usuarioFoto!.isEmpty) {
      usuarioFoto = conta?.fotoExibicao ?? conta?.foto;
    }
    if (usuarioApelido == null || usuarioApelido!.isEmpty) {
      usuarioApelido = conta?.apelidoExibicao ?? conta?.apelido;
    }

    _carregando = true;
    notifyListeners();

    await ChatService.curarTimestampsAnomalosDoPassado();
    await ChatService.consolidarConversasDuplicadas();
    if (usuarioCpf != null && usuarioCpf!.isNotEmpty) {
      await MensageriaSolicitacoesHelper.carregarAceitas(usuarioCpf!);
    }
    if (_disposed) return;
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: false);
    if (_disposed) return;

    if (conversaInicialId != null &&
        conversaInicialId!.isNotEmpty &&
        !_conversaInicialConsumida) {
      _conversaInicialConsumida = true;
      final idAlvo = conversaInicialId!;
      final encontrada = _conversas.cast<ConversaChat?>().firstWhere(
        (c) => c?.id == idAlvo || c?.identificador == idAlvo,
        orElse: () =>
            _todosContatosDisponiveis.cast<ConversaChat?>().firstWhere(
              (c) => c?.id == idAlvo || c?.identificador == idAlvo,
              orElse: () => null,
            ),
      );
      if (encontrada != null) {
        await selecionarOuIniciarConversa(
          convId: encontrada.id,
          titulo: encontrada.titulo,
          subtitulo: encontrada.subtitulo,
          identificador: encontrada.identificador,
          foto: encontrada.foto,
          ehLoja: encontrada.ehLoja,
        );
      } else if (idAlvo.startsWith('user_')) {
        final meuCpfLimpo = ChatService.normalizarCpf(usuarioCpf ?? auth.contaAtual?.cpf ?? '');
        final outroCpfLimpo = ChatService.extrairOutroCpf(idAlvo, meuCpfLimpo);
        final contaAlvo = auth.buscarContaPorCpf(outroCpfLimpo);
        final tituloAlvo = contaAlvo?.nomeExibicao.isNotEmpty == true
            ? contaAlvo!.nomeExibicao
            : (contaAlvo?.nome.isNotEmpty == true ? contaAlvo!.nome : 'Usuário Nous');
        await selecionarOuIniciarConversa(
          convId: idAlvo,
          titulo: tituloAlvo,
          subtitulo: contaAlvo?.usernameExibicao ?? '',
          identificador: outroCpfLimpo,
          foto: contaAlvo?.fotoExibicao ?? (contaAlvo?.foto ?? ''),
          ehLoja: false,
        );
      }
    }

    sincronizarComRedeLocal(auth: auth, pdv: pdv);
    _iniciarPollingLeve(auth: auth, pdv: pdv);

    _carregando = false;
    notifyListeners();
  }

  void _iniciarPollingLeve({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) {
    _timerPollingLeve?.cancel();
    _timerPollingLeve = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_disposed) return;
      ChatService.drenarFilaDeSaida();
      final cliente = ClienteRedeLocal();
      if (cliente.conectado &&
          cliente.ipServidor != null &&
          cliente.portaServidor != null) {
        final meuCpf = modoLoja ? null : (usuarioCpf ?? auth.contaAtual?.cpf);
        ChatService.sincronizarMensagensComBalcao(
          ipServidor: cliente.ipServidor!,
          portaServidor: cliente.portaServidor!,
          cpfUsuario: meuCpf,
          lojaId: modoLoja ? lojaId : null,
        );
      }
    });
  }

  void sincronizarComRedeLocal({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) {
    if (_disposed) return;
    if (ServidorRedeLocal().ativo) return;
    final cliente = ClienteRedeLocal();
    final contaLogada = auth.contaAtual;
    final meuCpf = modoLoja ? null : (usuarioCpf ?? contaLogada?.cpf);

    cliente.tentarAutoConectarSeDisponivel(pdv, auth).then((_) {
      if (_disposed) return;
      if (cliente.ipServidor != null && cliente.portaServidor != null) {
        cliente.reconciliarContasComServidor();
        ChatService.drenarFilaDeSaida();
        ChatService.sincronizarMensagensComBalcao(
          ipServidor: cliente.ipServidor!,
          portaServidor: cliente.portaServidor!,
          cpfUsuario: meuCpf,
          lojaId: modoLoja ? lojaId : null,
        ).then((_) {
          if (_disposed) return;
          recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
        });
      }
    });
  }

  Future<void> recarregarConversas({
    required AuthProvider auth,
    required PdvProvider pdv,
    bool manterSelecionada = true,
  }) async {
    if (_disposed) return;
    final contaLogada = auth.contaAtual;
    if (usuarioCpf == null || usuarioCpf!.trim().isEmpty) {
      final cpfCandidato = contaLogada?.cpf ??
          (auth.cpf.trim().isNotEmpty
              ? auth.cpf.trim()
              : (pdv.cpfAtual?.trim() ?? ''));
      if (cpfCandidato.isNotEmpty) {
        usuarioCpf = cpfCandidato;
      } else {
        final cpfLocal = await ChatService.obterCpfLogadoLocal();
        if (_disposed) return;
        if (cpfLocal.isNotEmpty) usuarioCpf = cpfLocal;
      }
    }

    final resultado = await MontadorConversasChat.montarConversas(
      auth: auth,
      pdv: pdv,
      modoLoja: modoLoja,
      lojaId: lojaId,
      operadorCpf: operadorCpf,
      usuarioCpf: usuarioCpf,
      conversaSelecionada: _conversaSelecionada,
    );
    if (_disposed) return;

    _conversas = resultado.conversas;
    _todosContatosDisponiveis = resultado.todosDisponiveis;
    _usuariosNousPorCpf.clear();
    _usuariosNousPorCpf.addAll(resultado.usuariosNousPorCpf);
    _titulosCustomizados = resultado.titulosCustomizados;

    if (manterSelecionada && _conversaSelecionada != null) {
      final index = _conversas.indexWhere(
        (c) => c.id == _conversaSelecionada!.id,
      );
      if (index != -1) {
        final msgsAtuais = _conversaSelecionada!.mensagens;
        final novasMsgs = _conversas[index].mensagens;
        final msgsFinais = novasMsgs.isNotEmpty ? novasMsgs : msgsAtuais;
        _conversaSelecionada = _conversas[index].copyWith(
          naoLidasCount: 0,
          mensagens: msgsFinais,
        );
        _conversas[index] = _conversaSelecionada!;
      }
      ChatService.idConversaAtiva = _conversaSelecionada!.id;
      unawaited(ChatService.marcarComoLidas(
        _conversaSelecionada!.id,
        idVisualizador,
        notificar: false,
      ));
    }

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
    if (ehLoja &&
        (identificador == PdvProvider.idLojaColetivaNous ||
            convId.contains(PdvProvider.idLojaColetivaNous) ||
            titulo.trim().toLowerCase() == 'nous')) {
      return;
    }

    final index = _conversas.indexWhere((c) => c.id == convId);
    if (index != -1) {
      selecionarConversa(_conversas[index]);
      return;
    }

    final ehConvLojaUsuario =
        convId.startsWith('loja_') && convId.contains('_usuario_');
    final lojaIdResolvido = modoLoja
        ? lojaId
        : (ehConvLojaUsuario
            ? convId.substring(5, convId.indexOf('_usuario_'))
            : (ehLoja ? identificador.replaceFirst('loja_', '') : null));

    final novaConversaOtimista = ConversaChat(
      id: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja || ehConvLojaUsuario,
      lojaId: lojaIdResolvido,
      naoLidasCount: 0,
      mensagens: const [],
      dataHoraUltimaMensagem: DateTime.now(),
      ultimaMensagem: '',
    );

    _conversaSelecionada = novaConversaOtimista;
    ChatService.idConversaAtiva = convId;
    _conversas.insert(0, novaConversaOtimista);
    _salvarUltimaConversaAberta(convId);
    notifyListeners();

    unawaited(_carregarOuPersistirConversaNovaEmBackground(
      convId: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja || ehConvLojaUsuario,
      lojaIdOverride: lojaIdResolvido,
    ));
  }

  Future<void> _carregarOuPersistirConversaNovaEmBackground({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
    String? lojaIdOverride,
  }) async {
    try {
      await ChatService.desmarcarConversaExcluida(convId);
      final conversaBase = await ChatService.obterOuCriarConversa(
        id: convId,
        titulo: titulo,
        subtitulo: subtitulo,
        identificador: identificador,
        foto: foto,
        ehLoja: ehLoja,
        lojaId: lojaIdOverride ?? (modoLoja ? lojaId : null),
        cpfUsuario: modoLoja ? null : usuarioCpf,
      );
      if (_disposed) return;

      final msgs = await ChatService.carregarMensagens(
        convId,
        idVisualizador: idVisualizador,
      );
      if (_disposed) return;

      final conversa = conversaBase.copyWith(
        mensagens: msgs,
        ultimaMensagem: msgs.isNotEmpty
            ? resumoMensagem(msgs.last)
            : conversaBase.ultimaMensagem,
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : conversaBase.dataHoraUltimaMensagem,
        naoLidasCount: 0,
      );

      final index = _conversas.indexWhere((c) => c.id == convId);
      if (index != -1) {
        _conversas[index] = conversa;
      }
      if (_conversaSelecionada?.id == convId) {
        _conversaSelecionada = conversa;
      }
      ChatService.despacharConversaAtualizada(conversa);
      await marcarComoLida(conversa);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (_) {}
  }

  void selecionarConversa(ConversaChat? c) {
    if (c == null) {
      _conversaSelecionada = null;
      ChatService.idConversaAtiva = null;
      _salvarUltimaConversaAberta('');
      notifyListeners();
      return;
    }

    final msgsEmMemoria = (_conversaSelecionada?.id == c.id &&
            _conversaSelecionada!.mensagens.isNotEmpty)
        ? _conversaSelecionada!.mensagens
        : c.mensagens;

    final conversaAtualizada = c.copyWith(
      naoLidasCount: 0,
      mensagens: msgsEmMemoria,
    );
    _conversaSelecionada = conversaAtualizada;
    ChatService.idConversaAtiva = c.id;

    final idx = _conversas.indexWhere((item) => item.id == c.id);
    if (idx != -1) {
      _conversas[idx] = conversaAtualizada;
    } else {
      _conversas.insert(0, conversaAtualizada);
      unawaited(
        ChatService.obterOuCriarConversa(
          id: conversaAtualizada.id,
          titulo: conversaAtualizada.titulo,
          subtitulo: conversaAtualizada.subtitulo,
          identificador: conversaAtualizada.identificador,
          foto: conversaAtualizada.foto,
          ehLoja: conversaAtualizada.ehLoja ||
              conversaAtualizada.id.startsWith('loja_'),
          ehGrupo: conversaAtualizada.ehGrupo,
          lojaId: conversaAtualizada.lojaId ?? (modoLoja ? lojaId : null),
          cpfUsuario: modoLoja ? null : usuarioCpf,
        ),
      );
    }
    notifyListeners();

    _salvarUltimaConversaAberta(c.id);
    unawaited(ChatService.desmarcarConversaExcluida(c.id));
    unawaited(ChatService.marcarComoLidas(
      c.id,
      idVisualizador,
      notificar: false,
    ));

    ChatService.carregarMensagens(c.id, idVisualizador: idVisualizador)
        .then((msgs) {
      if (_disposed || _conversaSelecionada?.id != c.id) return;
      final comMsgs = _conversaSelecionada!.copyWith(
        mensagens: msgs,
        ultimaMensagem: msgs.isNotEmpty
            ? resumoMensagem(msgs.last)
            : _conversaSelecionada!.ultimaMensagem,
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : _conversaSelecionada!.dataHoraUltimaMensagem,
      );
      _conversaSelecionada = comMsgs;
      final i = _conversas.indexWhere((item) => item.id == c.id);
      if (i != -1) _conversas[i] = comMsgs;
      notifyListeners();
    });
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

      final msgsAtuais = _conversaSelecionada!.mensagens;
      final idsNoBanco = msgs.map((m) => m.id).toSet();
      final pendentesLocais = msgsAtuais
          .where((m) =>
              m.statusEnvio == 'pendente' && !idsNoBanco.contains(m.id))
          .toList();

      final List<MensagemChat> msgsFinais;
      if (pendentesLocais.isNotEmpty) {
        msgsFinais = [...msgs, ...pendentesLocais]..sort((a, b) {
            final cmp = a.dataHora.compareTo(b.dataHora);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });
      } else {
        msgsFinais = msgs;
      }

      bool saoIguais = msgsAtuais.length == msgsFinais.length;
      if (saoIguais) {
        for (int k = 0; k < msgsFinais.length; k++) {
          final m1 = msgsAtuais[k];
          final m2 = msgsFinais[k];
          if (m1.id != m2.id ||
              m1.statusEnvio != m2.statusEnvio ||
              m1.lida != m2.lida ||
              m1.entregue != m2.entregue ||
              m1.texto != m2.texto ||
              m1.editada != m2.editada ||
              m1.favorita != m2.favorita ||
              m1.fixada != m2.fixada ||
              m1.caminhoAnexo != m2.caminhoAnexo ||
              m1.dadosPedidoJson != m2.dadosPedidoJson ||
              !mapEquals(m1.reacoes, m2.reacoes)) {
            saoIguais = false;
            break;
          }
        }
      }
      if (saoIguais) return;

      final comMsgs = _conversaSelecionada!.copyWith(
        mensagens: msgsFinais,
        ultimaMensagem: msgsFinais.isNotEmpty
            ? resumoMensagem(msgsFinais.last)
            : _conversaSelecionada!.ultimaMensagem,
        dataHoraUltimaMensagem: msgsFinais.isNotEmpty
            ? msgsFinais.last.dataHora
            : _conversaSelecionada!.dataHoraUltimaMensagem,
      );
      _conversaSelecionada = comMsgs;

      final i = _conversas.indexWhere((item) => item.id == convId);
      if (i != -1) {
        _conversas[i] = comMsgs;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _salvarUltimaConversaAberta(String convId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chave = 'chat_ultima_conversa_${modoLoja ? (lojaId ?? "loja") : (usuarioCpf ?? "usr")}';
      if (convId.isEmpty) {
        await prefs.remove(chave);
      } else {
        await prefs.setString(chave, convId);
      }
    } catch (_) {}
  }

  Future<void> marcarComoLida(ConversaChat conversa) async {
    await ChatService.marcarComoLidas(
      conversa.id,
      idVisualizador,
      notificar: false,
    );
    if (_disposed) return;
    final idx = _conversas.indexWhere((c) => c.id == conversa.id);
    if (idx != -1 && _conversas[idx].naoLidasCount > 0) {
      _conversas[idx] = _conversas[idx].copyWith(naoLidasCount: 0);
      if (_conversaSelecionada?.id == conversa.id) {
        _conversaSelecionada = _conversaSelecionada?.copyWith(naoLidasCount: 0);
      }
      notifyListeners();
    }
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

    final novaMensagem = MensageriaMensagemHelper.criarNovaMensagem(
      conversa: _conversaSelecionada!,
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
    );

    final resumo = resumoMensagem(novaMensagem);
    _conversaSelecionada = MensageriaMensagemHelper.integrarNovaMensagemNaConversa(
      conversa: _conversaSelecionada!,
      novaMensagem: novaMensagem,
      resumo: resumo,
    );
    MensageriaMensagemHelper.atualizarListaConversasComNova(_conversas, _conversaSelecionada!);
    notifyListeners();

    ChatService.enviarMensagemInstantanea(novaMensagem).then((msgSalva) {
      if (_disposed) return;
      if (_conversaSelecionada?.id == novaMensagem.conversaId) {
        final msgs = List<MensagemChat>.from(_conversaSelecionada!.mensagens);
        final i = msgs.indexWhere((m) => m.id == novaMensagem.id);
        if (i != -1) {
          msgs[i] = msgSalva;
          msgs.sort((a, b) {
            final cmp = a.dataHora.compareTo(b.dataHora);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });
          _conversaSelecionada = _conversaSelecionada!.copyWith(
            mensagens: msgs,
          );
          notifyListeners();
        }
      }
    });
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
        onAtualizarConversa: (c) {
          _conversaSelecionada = c;
          notifyListeners();
        },
      );

  Future<void> excluirMensagemLocal(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.excluir(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: (c) {
          _conversaSelecionada = c;
          notifyListeners();
        },
      );

  Future<void> alternarFavoritarMensagem(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.alternarFavoritar(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: (c) {
          _conversaSelecionada = c;
          notifyListeners();
        },
      );

  Future<void> alternarFixarMensagem(MensagemChat msg) =>
      MensageriaAcoesMensagemHelper.alternarFixar(
        msg: msg,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: (c) {
          _conversaSelecionada = c;
          notifyListeners();
        },
      );

  Future<void> reagirMensagem(MensagemChat msg, String emoji) =>
      MensageriaAcoesMensagemHelper.reagir(
        msg: msg,
        emoji: emoji,
        modoLoja: modoLoja,
        lojaId: lojaId,
        usuarioCpf: usuarioCpf,
        conversaSelecionada: _conversaSelecionada,
        onAtualizarConversa: (c) {
          _conversaSelecionada = c;
          notifyListeners();
        },
      );

  Future<void> alternarSilenciar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) async {
    await ChatService.alternarSilenciarConversa(c.id);
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  Future<void> alternarFixar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) async {
    await ChatService.alternarFixarConversa(c.id);
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  Future<void> alternarArquivar(ConversaChat c, {required AuthProvider auth, required PdvProvider pdv}) async {
    await ChatService.alternarArquivarConversa(c.id);
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

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
