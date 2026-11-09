import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/mensageria_acoes_delegate.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

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
      return lojaId ?? 'loja';
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
  }

  void atualizarTermoBusca(String termo) {
    _termoBusca = termo.trim().toLowerCase();
    notifyListeners();
  }

  String resumoMensagem(MensagemChat msg) =>
      MontadorConversasChat.resumoMensagem(msg);

  bool combinaBusca(ConversaChat c, String termo) {
    if (termo.isEmpty) return true;
    final tLimpo = termo.trim().toLowerCase();
    final termoSemArroba = tLimpo.startsWith('@')
        ? tLimpo.substring(1)
        : tLimpo;
    final termoDigitos = tLimpo.replaceAll(RegExp(r'\D'), '');

    if (TextoUtils.contemIgnorandoAcentos(c.titulo, tLimpo) ||
        TextoUtils.contemIgnorandoAcentos(c.titulo, termoSemArroba)) {
      return true;
    }
    if (c.ehGrupo &&
        (TextoUtils.contemIgnorandoAcentos(c.nomeGrupo, tLimpo) ||
            TextoUtils.contemIgnorandoAcentos(c.nomeGrupo, termoSemArroba))) {
      return true;
    }
    if (!c.ehLoja || (c.subtitulo != 'Loja' && c.subtitulo != 'Loja Nous')) {
      if (TextoUtils.contemIgnorandoAcentos(c.subtitulo, tLimpo) ||
          TextoUtils.contemIgnorandoAcentos(c.subtitulo, termoSemArroba)) {
        return true;
      }
    } else if (tLimpo == 'loja' || tLimpo == 'lojas') {
      return true;
    }

    if (c.identificador.isNotEmpty && !c.ehLoja) {
      if (TextoUtils.contemIgnorandoAcentos(c.identificador, tLimpo)) {
        return true;
      }
      if (termoDigitos.isNotEmpty) {
        final idDigitos = c.identificador.replaceAll(RegExp(r'\D'), '');
        if (idDigitos.length >= 3 && idDigitos.contains(termoDigitos)) {
          return true;
        }
      }
    }
    if (TextoUtils.contemIgnorandoAcentos(c.ultimaMensagem, tLimpo)) {
      return true;
    }

    if (!c.ehLoja) {
      final meuCpfAtual = modoLoja
          ? (operadorCpf ?? '')
          : (usuarioCpf ?? '');
      final meuNorm = ChatService.normalizarCpf(meuCpfAtual);
      var cpfNorm = ChatService.normalizarCpf(c.identificador);
      if (cpfNorm.length != 11 || (meuNorm.isNotEmpty && cpfNorm == meuNorm)) {
        cpfNorm = ChatService.extrairOutroCpf(c.id, meuNorm);
      }
      if (cpfNorm.length == 11 && _usuariosNousPorCpf.containsKey(cpfNorm)) {
        final u = _usuariosNousPorCpf[cpfNorm]!;
        final campos = [
          u.nome,
          u.nomeExibicao,
          u.nomePublico,
          u.apelido,
          u.apelidoExibicao,
          u.apelidoPublico,
        ];
        if (campos.any(
            (c) => TextoUtils.contemIgnorandoAcentos(c, tLimpo))) {
          return true;
        }
        if (TextoUtils.contemIgnorandoAcentos(u.nomeDeUsuario, termoSemArroba) ||
            TextoUtils.contemIgnorandoAcentos(
                u.usernameExibicao, termoSemArroba)) {
          return true;
        }
      }
    }
    return false;
  }

  List<ConversaChat> obterConversasFiltradas() {
    if (_termoBusca.isEmpty) {
      return _conversas;
    }
    final List<ConversaChat> filtradas = [];
    final Set<String> idsJaAdicionados = {};

    for (final c in _conversas) {
      if (combinaBusca(c, _termoBusca)) {
        filtradas.add(c);
        idsJaAdicionados.add(c.id);
      }
    }

    for (final c in _todosContatosDisponiveis) {
      if (!idsJaAdicionados.contains(c.id)) {
        if (combinaBusca(c, _termoBusca)) {
          filtradas.add(c);
          idsJaAdicionados.add(c.id);
        }
      }
    }

    return filtradas;
  }

  bool _conversaInicialConsumida = false;

  Future<void> inicializar({
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    if (_disposed) return;
    final conta = auth.contaAtual;
    if (usuarioCpf == null || usuarioCpf!.isEmpty) {
      usuarioCpf = conta?.cpf ?? auth.cpf;
    }
    if (usuarioNome == null || usuarioNome!.isEmpty) {
      usuarioNome = conta?.nomeExibicao ?? conta?.nome;
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
    if (usuarioCpf == null || usuarioCpf!.isEmpty) {
      usuarioCpf = contaLogada?.cpf;
    }
    if (usuarioCpf == null || usuarioCpf!.isEmpty) {
      final cpfLocal = await ChatService.obterCpfLogadoLocal();
      if (_disposed) return;
      if (cpfLocal.isNotEmpty) usuarioCpf = cpfLocal;
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

    // Se a conversa já existe em memória, seleciona instantaneamente a 60/120 FPS
    final index = _conversas.indexWhere((c) => c.id == convId);
    if (index != -1) {
      selecionarConversa(_conversas[index]);
      return;
    }

    // Inicialização otimista imediata na UI (0ms de atraso perceptível)
    final novaConversaOtimista = ConversaChat(
      id: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja,
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

    // Em segundo plano, garante persistência no banco SQLite e carrega mensagens
    unawaited(_carregarOuPersistirConversaNovaEmBackground(
      convId: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja,
    ));
  }

  Future<void> _carregarOuPersistirConversaNovaEmBackground({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
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
        lojaId: modoLoja ? lojaId : null,
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

    // 1. RESPOSTA VISUAL INSTANTÂNEA: zera não lidas e preserva mensagens já em memória (0ms)
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
    }
    notifyListeners();

    // 2. TAREFAS DE BANCO/DISCO EM SEGUNDO PLANO (sem bloquear a UI)
    _salvarUltimaConversaAberta(c.id);
    unawaited(ChatService.desmarcarConversaExcluida(c.id));
    unawaited(ChatService.marcarComoLidas(
      c.id,
      idVisualizador,
      notificar: false,
    ));

    // Carregamento de histórico cirúrgico no SQLite
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

  /// Recarrega instantaneamente as mensagens da conversa aberta diretamente do SQLite
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
      bool saoIguais = msgsAtuais.length == msgs.length;
      if (saoIguais) {
        for (int k = 0; k < msgs.length; k++) {
          final m1 = msgsAtuais[k];
          final m2 = msgs[k];
          if (m1.id != m2.id ||
              m1.statusEnvio != m2.statusEnvio ||
              m1.texto != m2.texto ||
              m1.editada != m2.editada ||
              m1.caminhoAnexo != m2.caminhoAnexo) {
            saoIguais = false;
            break;
          }
        }
      }
      if (saoIguais) {
        return; // Mensagens em tela já estão idênticas. Zero rebuild desnecessário e sem piscar!
      }

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

    final agora = RelogioRedeService.agora().toLocal();
    var dataHoraEfetiva = agora;
    if (_conversaSelecionada!.mensagens.isNotEmpty) {
      final ultimaData = _conversaSelecionada!.mensagens.last.dataHora.toLocal();
      if (!dataHoraEfetiva.isAfter(ultimaData)) {
        if (ultimaData.difference(agora).inSeconds > 30) {
          dataHoraEfetiva = agora;
        } else {
          dataHoraEfetiva = ultimaData.add(const Duration(milliseconds: 10));
        }
      }
    }
    final conta = auth.contaAtual;

    final remetenteId = modoLoja
        ? (lojaId ?? 'loja')
        : (usuarioCpf ?? conta?.cpf ?? 'usuario');
    final remetenteNome = modoLoja
        ? (nomeLoja ?? 'Loja')
        : (usuarioNome ?? conta?.nomeExibicao ?? 'Usuário');
    final atendenteNome = modoLoja
        ? (operadorNome ?? conta?.nomeExibicao ?? 'Atendente')
        : '';
    final remetenteFoto = modoLoja
        ? (logoLoja ?? '')
        : (usuarioFoto ??
              conta?.fotoExibicao ??
              auth.buscarFotoPorCpf(conta?.cpf ?? ''));

    var destinatarioId = _conversaSelecionada!.identificador;
    if (_conversaSelecionada!.id.startsWith('user_')) {
      final outro = ChatService.extrairOutroCpf(
        _conversaSelecionada!.id,
        remetenteId,
      );
      if (outro.length == 11) {
        destinatarioId = outro;
      }
    }

    final salt = Random().nextInt(9999);
    final novaMensagem = MensagemChat(
      id: 'msg_${dataHoraEfetiva.millisecondsSinceEpoch}_${remetenteId.hashCode.abs()}_$salt',
      conversaId: _conversaSelecionada!.id,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      remetenteFoto: remetenteFoto,
      destinatarioId: destinatarioId,
      texto: texto.trim(),
      dataHora: dataHoraEfetiva,
      enviadaPorMim: true,
      nomeAtendente: atendenteNome,
      cpfAtendente: operadorCpf ?? conta?.cpf ?? '',
      lida: false,
      entregue: false,
      statusEnvio: 'pendente',
      tipo: tipo,
      caminhoAnexo: caminhoAnexo,
      nomeAnexo: nomeAnexo,
      tamanhoAnexo: tamanhoAnexo,
      pedidoId: pedidoId,
      dadosPedidoJson: dadosPedidoJson,
    );

    // Atualização Otimista Imediata na UI
    final resumo = resumoMensagem(novaMensagem);
    final msgsAtuais = List<MensagemChat>.from(_conversaSelecionada!.mensagens)
      ..add(novaMensagem);
    msgsAtuais.sort((a, b) {
      final cmp = a.dataHora.compareTo(b.dataHora);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    _conversaSelecionada = _conversaSelecionada!.copyWith(
      mensagens: msgsAtuais,
      ultimaMensagem: resumo,
      dataHoraUltimaMensagem: dataHoraEfetiva,
    );

    final idx = _conversas.indexWhere((c) => c.id == _conversaSelecionada!.id);
    if (idx != -1) {
      final atualizada = _conversas[idx].copyWith(
        mensagens: msgsAtuais,
        ultimaMensagem: resumo,
        dataHoraUltimaMensagem: agora,
      );
      _conversas.removeAt(idx);
      _conversas.insert(0, atualizada);
    } else {
      _conversas.insert(0, _conversaSelecionada!);
    }
    notifyListeners();

    // Persistência no SQLite e despacho pela rede
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

  Future<void> editarMensagem(MensagemChat msg, String novoTexto) async {
    final agora = DateTime.now();
    final historicoAtualizado =
        List<Map<String, dynamic>>.from(msg.historicoEdicoes)..add({
          'textoAnterior': msg.texto,
          'dataHoraEdicao': agora.toIso8601String(),
        });

    final msgEditada = msg.copyWith(
      texto: novoTexto,
      editada: true,
      historicoEdicoes: historicoAtualizado,
    );

    if (_conversaSelecionada != null &&
        _conversaSelecionada!.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(_conversaSelecionada!.mensagens);
      final index = msgs.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        msgs[index] = msgEditada;
        _conversaSelecionada = _conversaSelecionada!.copyWith(mensagens: msgs);
        notifyListeners();
      }
    }

    await ChatService.salvarMensagem(msgEditada);
  }

  Future<void> excluirMensagemLocal(MensagemChat msg) async {
    if (_conversaSelecionada != null &&
        _conversaSelecionada!.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(_conversaSelecionada!.mensagens)
        ..removeWhere((m) => m.id == msg.id);
      _conversaSelecionada = _conversaSelecionada!.copyWith(mensagens: msgs);
      notifyListeners();
    }
    await ChatService.excluirMensagem(msg.id);
  }

  Future<void> alternarFixar(
    ConversaChat conversa, {
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    await ChatService.alternarFixarConversa(conversa.id);
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  Future<void> alternarArquivar(
    ConversaChat conversa, {
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    await ChatService.alternarArquivarConversa(conversa.id);
    await recarregarConversas(auth: auth, pdv: pdv, manterSelecionada: true);
  }

  Future<void> renomearConversa(
    ConversaChat conversa,
    String novoTitulo, {
    required AuthProvider auth,
    required PdvProvider pdv,
  }) async {
    final tLimpo = novoTitulo.trim();
    await ChatService.renomearConversa(conversa.id, tLimpo);
    final atualizada = conversa.copyWith(tituloConversa: tLimpo);
    if (_conversaSelecionada?.id == conversa.id) {
      _conversaSelecionada = atualizada;
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
