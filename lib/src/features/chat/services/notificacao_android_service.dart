import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Ponto de entrada nativo em background para respostas e ações no Android
@pragma('vm:entry-point')
void notificacaoBackgroundHandler(NotificationResponse response) {
  NotificacaoAndroidService.tratarRespostaNotificacao(response);
}

class NotificacaoAndroidService {
  NotificacaoAndroidService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const String canalId = 'nous_chat_mensagens_v4';
  static const String canalNome = 'Mensagens do Chat';
  static const String canalDescricao =
      'Recebimento, agrupamento e resposta rápida de mensagens do chat Nous';
  static const String grupoNotificacoesChat = 'com.nous.app.CHAT_NOTIF';
  static const int idNotificacaoResumo = 0;

  static const String acaoResponderId = 'responder_mensagem';
  static const String acaoMarcarLidaId = 'marcar_como_lida';
  static const String acaoSilenciarId = 'silenciar_conversa';

  // Histórico em memória de mensagens por conversa para agrupamento expansível estilo WhatsApp
  static final Map<String, List<Message>> _mensagensPorConversa = {};
  static final Set<String> _mensagensNotificadas = <String>{};

  /// Inicializa o plugin no Android
  static Future<void> inicializar() async {
    if (_inicializado) return;
    if (!kIsWeb && !Platform.isAndroid) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: tratarRespostaNotificacao,
        onDidReceiveBackgroundNotificationResponse: notificacaoBackgroundHandler,
      );

      // Solicita permissão no Android 13+
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImpl?.requestNotificationsPermission();

        // Cria antecipadamente o canal com alta prioridade para banner suspenso (heads-up)
        final channel = const AndroidNotificationChannel(
          canalId,
          canalNome,
          description: canalDescricao,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        await androidImpl?.createNotificationChannel(channel);
      }

      // Trata toque na notificação quando o app foi inicializado pelo clique nela
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          tratarRespostaNotificacao(launchDetails!.notificationResponse!);
        });
      }

      _inicializado = true;
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao inicializar: $e');
    }
  }

  /// Trata clique na notificação ou nas ações (Responder, Marcar como Lida, Silenciar)
  @pragma('vm:entry-point')
  static Future<void> tratarRespostaNotificacao(
    NotificationResponse response,
  ) async {
    try {
      final payloadStr = response.payload;
      if (payloadStr == null || payloadStr.isEmpty) return;

      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final conversaId = payload['conversaId'] as String? ?? '';
      final destinatarioId = payload['destinatarioId'] as String? ?? '';
      final remetenteOriginalId = payload['remetenteId'] as String? ?? '';

      // Clique no corpo da notificação: Abre a conversa no app
      if (response.actionId == null || response.actionId!.isEmpty) {
        if (conversaId.isNotEmpty) {
          _abrirConversaNoApp(conversaId);
        }
        return;
      }

      // 1. Ação: Responder Direto (Direct Reply inline)
      if (response.actionId == acaoResponderId) {
        final textoDigitado = response.input;
        if (textoDigitado == null || textoDigitado.trim().isEmpty) return;

        final destDigits = destinatarioId.replaceAll(RegExp(r'\D'), '');
        final ehRespostaDeLoja = destinatarioId.startsWith('loja_') ||
            (conversaId.startsWith('loja_') && destDigits.length != 11);

        String remetenteIdFinal = destinatarioId;
        String remetenteNome = 'Usuário';
        String remetenteFoto = '';

        if (ehRespostaDeLoja) {
          final idLimpo = PdvProvider.normalizarIdLoja(destinatarioId);
          remetenteIdFinal = 'loja_$idLimpo';
          final loja = await LojasService.carregarLojaPorId(idLimpo);
          if (loja != null) {
            remetenteNome = loja.nome;
            remetenteFoto = loja.logo;
          } else {
            remetenteNome = 'Loja';
          }
        } else {
          final conta = await ContasNousService.buscarPorCpf(destinatarioId);
          remetenteNome = conta?.nomeExibicao.isNotEmpty == true
              ? conta!.nomeExibicao
              : (conta?.nome.isNotEmpty == true ? conta!.nome : 'Usuário');
          remetenteFoto = conta?.fotoExibicao ?? (conta?.foto ?? '');
        }

        final novaMensagem = MensagemChat(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversaId: conversaId,
          remetenteId: remetenteIdFinal,
          remetenteNome: remetenteNome,
          remetenteFoto: remetenteFoto,
          destinatarioId: remetenteOriginalId,
          texto: textoDigitado.trim(),
          dataHora: DateTime.now(),
          enviadaPorMim: true,
          lida: false,
          statusEnvio: 'enviada',
        );

        await ChatService.enviarMensagemInstantanea(novaMensagem);
        await ChatService.marcarComoLidas(conversaId, remetenteIdFinal);
        await cancelarNotificacaoConversa(conversaId);
        return;
      }

      // 2. Ação: Marcar como Lida
      if (response.actionId == acaoMarcarLidaId) {
        if (conversaId.isNotEmpty) {
          await ChatService.marcarComoLidas(conversaId, destinatarioId);
          await cancelarNotificacaoConversa(conversaId);
        }
        return;
      }

      // 3. Ação: Silenciar Conversa
      if (response.actionId == acaoSilenciarId) {
        if (conversaId.isNotEmpty) {
          await ChatService.alternarSilenciarConversa(conversaId);
          await cancelarNotificacaoConversa(conversaId);
        }
        return;
      }
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao processar resposta: $e');
    }
  }

  /// Navega diretamente para a conversa indicada sem perder contexto
  static void _abrirConversaNoApp(String conversaId) {
    void navegar() {
      final nav = NavigatorKeyService.navigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => MensageriaView(
              conversaInicialId: conversaId,
            ),
          ),
        );
      }
    }

    if (NavigatorKeyService.navigatorKey.currentState != null) {
      navegar();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navegar();
      });
    }
  }

  /// Cancela notificações pendentes de uma conversa específica e atualiza ou cancela o resumo do grupo
  static Future<void> cancelarNotificacaoConversa(String conversaId) async {
    if (!kIsWeb && !Platform.isAndroid) return;
    try {
      _mensagensPorConversa.remove(conversaId);
      final notificacaoId = (conversaId.hashCode.abs() % 90000) + 1;
      await _notificationsPlugin.cancel(id: notificacaoId);

      if (_mensagensPorConversa.isEmpty) {
        await _notificationsPlugin.cancel(id: idNotificacaoResumo);
      } else {
        await _atualizarResumoGrupo();
      }
    } catch (_) {}
  }

  /// Exibe notificação nativa no Android estilo WhatsApp:
  /// - Logo do Nous
  /// - Avatar/Foto real do contato em LargeIcon
  /// - Agrupamento em gaveta com groupKey
  /// - Mensagens encadeadas por conversa
  /// - Ações: RESPONDER, MARCAR COMO LIDA, SILENCIAR
  static Future<void> exibirNotificacaoMensagem(MensagemChat mensagem) async {
    if (!kIsWeb && !Platform.isAndroid) return;
    if (!_inicializado) {
      await inicializar();
    }

    if (mensagem.id.isNotEmpty) {
      if (_mensagensNotificadas.contains(mensagem.id)) {
        return;
      }
      _mensagensNotificadas.add(mensagem.id);
      if (_mensagensNotificadas.length > 300) {
        _mensagensNotificadas.remove(_mensagensNotificadas.first);
      }
    }

    try {
      const corLogoNous = Color(0xFFFFFFFF);

      // Resolução da foto do remetente para avatar grande na notificação
      AndroidBitmap<Object>? avatarBitmap;
      AndroidIcon<Object>? avatarIcon;
      String fotoCaminho = mensagem.remetenteFoto.trim();
      if (fotoCaminho.isEmpty) {
        final cpfRemNorm = ChatService.normalizarCpf(mensagem.remetenteId);
        if (!mensagem.remetenteId.startsWith('loja_') &&
            cpfRemNorm.length == 11) {
          final conta = await ContasNousService.buscarPorCpf(cpfRemNorm);
          if (conta != null && conta.fotoExibicao.isNotEmpty) {
            fotoCaminho = conta.fotoExibicao.trim();
          }
        }
        if (fotoCaminho.isEmpty && mensagem.conversaId.startsWith('loja_')) {
          final idLojaLimpo = PdvProvider.normalizarIdLoja(mensagem.conversaId);
          final loja = await LojasService.carregarLojaPorId(idLojaLimpo);
          if (loja != null && loja.logo.isNotEmpty) {
            fotoCaminho = loja.logo.trim();
          }
        }
      }

      if (fotoCaminho.isNotEmpty) {
        final fotoFisica = ImagemService.resolverCaminhoExistente(fotoCaminho);
        if (fotoFisica != null && File(fotoFisica).existsSync()) {
          try {
            avatarBitmap = FilePathAndroidBitmap(fotoFisica);
            avatarIcon = BitmapFilePathAndroidIcon(fotoFisica);
          } catch (_) {}
        }
      }
      avatarBitmap ??= const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
      avatarIcon ??= const DrawableResourceAndroidIcon('@mipmap/ic_launcher');

      final personRemetente = Person(
        name: mensagem.remetenteNome.isNotEmpty
            ? mensagem.remetenteNome
            : 'Usuário',
        key: mensagem.remetenteId,
        icon: avatarIcon,
      );

      final textoCorpo = mensagem.texto.trim().isNotEmpty
          ? mensagem.texto.trim()
          : ChatMediaService.gerarResumoMensagem(mensagem);

      final ehGrupo = mensagem.conversaId.startsWith('grupo_');
      final tituloConversa = ehGrupo
          ? (mensagem.remetenteNome.isNotEmpty ? mensagem.remetenteNome : 'Grupo')
          : null;

      // Acumula histórico da conversa para exibição encadeada expansível
      final listaMsgs = _mensagensPorConversa.putIfAbsent(
        mensagem.conversaId,
        () => [],
      );
      listaMsgs.add(
        Message(
          textoCorpo,
          mensagem.dataHora,
          personRemetente,
        ),
      );
      if (listaMsgs.length > 8) {
        listaMsgs.removeAt(0);
      }

      final payloadMap = {
        'conversaId': mensagem.conversaId,
        'remetenteId': mensagem.remetenteId,
        'destinatarioId': mensagem.destinatarioId,
        'mensagemId': mensagem.id,
      };

      final payloadJson = jsonEncode(payloadMap);
      final notificacaoId = (mensagem.conversaId.hashCode.abs() % 90000) + 1;

      // Notificação da conversa (filho do grupo)
      final androidDetails = AndroidNotificationDetails(
        canalId,
        canalNome,
        channelDescription: canalDescricao,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        when: mensagem.dataHora.millisecondsSinceEpoch,
        icon: '@drawable/ic_notification',
        largeIcon: avatarBitmap,
        color: corLogoNous,
        colorized: false,
        subText: 'Nous',
        groupKey: grupoNotificacoesChat,
        setAsGroupSummary: false,
        category: AndroidNotificationCategory.message,
        styleInformation: MessagingStyleInformation(
          Person(
            name: 'Eu',
            key: mensagem.destinatarioId,
          ),
          conversationTitle: tituloConversa,
          groupConversation: ehGrupo,
          messages: List.of(listaMsgs),
        ),
        actions: const [
          AndroidNotificationAction(
            acaoResponderId,
            'RESPONDER',
            inputs: [
              AndroidNotificationActionInput(
                label: 'Digite sua resposta...',
              ),
            ],
            allowGeneratedReplies: true,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            acaoMarcarLidaId,
            'MARCAR COMO LIDA',
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            acaoSilenciarId,
            'SILENCIAR',
            showsUserInterface: false,
          ),
        ],
      );

      await _notificationsPlugin.show(
        id: notificacaoId,
        title: mensagem.remetenteNome.isNotEmpty
            ? mensagem.remetenteNome
            : 'Nova Mensagem',
        body: textoCorpo,
        notificationDetails: NotificationDetails(android: androidDetails),
        payload: payloadJson,
      );

      // Emite ou atualiza a notificação de resumo do grupo (cabeçalho expansível do WhatsApp)
      await _atualizarResumoGrupo();
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao exibir notificação: $e');
    }
  }

  /// Cria ou atualiza a notificação de resumo do grupo para agrupar todas as conversas
  static Future<void> _atualizarResumoGrupo() async {
    try {
      if (_mensagensPorConversa.isEmpty) {
        await _notificationsPlugin.cancel(id: idNotificacaoResumo);
        return;
      }

      int totalMensagens = 0;
      final linhasResumo = <String>[];
      DateTime? ultimaData;

      for (final msgs in _mensagensPorConversa.values) {
        totalMensagens += msgs.length;
        if (msgs.isNotEmpty) {
          final ult = msgs.last;
          if (ultimaData == null || ult.timestamp.isAfter(ultimaData)) {
            ultimaData = ult.timestamp;
          }
          final autor = ult.person?.name ?? 'Mensagem';
          linhasResumo.add('$autor: ${ult.text}');
        }
      }

      const corLogoNous = Color(0xFFFFFFFF);

      final resumoTexto = totalMensagens == 1
          ? '1 nova mensagem'
          : '$totalMensagens novas mensagens em ${_mensagensPorConversa.length} conversas';

      final summaryInfo = InboxStyleInformation(
        linhasResumo,
        contentTitle: 'Nous • $resumoTexto',
        summaryText: totalMensagens == 1
            ? '1 mensagem'
            : '$totalMensagens mensagens',
      );

      final resumoDetails = AndroidNotificationDetails(
        canalId,
        canalNome,
        channelDescription: canalDescricao,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: corLogoNous,
        subText: totalMensagens == 1
            ? '1 mensagem'
            : '$totalMensagens mensagens',
        number: totalMensagens,
        groupKey: grupoNotificacoesChat,
        setAsGroupSummary: true,
        showWhen: true,
        when: ultimaData?.millisecondsSinceEpoch,
        styleInformation: summaryInfo,
      );

      await _notificationsPlugin.show(
        id: idNotificacaoResumo,
        title: 'Nous',
        body: resumoTexto,
        notificationDetails: NotificationDetails(android: resumoDetails),
      );
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao atualizar resumo do grupo: $e');
    }
  }
}
