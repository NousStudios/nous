import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class NotificacaoAndroidService {
  NotificacaoAndroidService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const String canalId = 'nous_chat_mensagens';
  static const String canalNome = 'Mensagens do Chat';
  static const String canalDescricao =
      'Recebimento e resposta rápida de mensagens do chat Nous';
  static const String acaoResponderId = 'responder_mensagem';

  /// Inicializa o plugin no Android
  static Future<void> inicializar() async {
    if (_inicializado) return;
    if (!kIsWeb && !Platform.isAndroid) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _aoReceberRespostaNotificacao,
      );

      // Solicita permissão no Android 13+
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidImpl?.requestNotificationsPermission();
      }

      _inicializado = true;
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao inicializar: $e');
    }
  }

  /// Trata clique na notificação ou envio de resposta direta (Direct Reply estilo WhatsApp)
  @pragma('vm:entry-point')
  static Future<void> _aoReceberRespostaNotificacao(
    NotificationResponse response,
  ) async {
    try {
      final payloadStr = response.payload;
      if (payloadStr == null || payloadStr.isEmpty) return;

      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final conversaId = payload['conversaId'] as String? ?? '';
      final destinatarioId = payload['destinatarioId'] as String? ?? '';
      final remetenteOriginalId = payload['remetenteId'] as String? ?? '';

      // Se for a ação de resposta rápida
      if (response.actionId == acaoResponderId) {
        final textoDigitado = response.input;
        if (textoDigitado == null || textoDigitado.trim().isEmpty) return;

        // Quem responde é o usuário local (destinatário da mensagem anterior)
        final conta = await ContasNousService.buscarPorCpf(destinatarioId);
        final remetenteNome = conta?.nomeExibicao.isNotEmpty == true
            ? conta!.nomeExibicao
            : (conta?.nome.isNotEmpty == true ? conta!.nome : 'Usuário');

        final novaMensagem = MensagemChat(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversaId: conversaId,
          remetenteId: destinatarioId,
          remetenteNome: remetenteNome,
          remetenteFoto: conta?.fotoExibicao ?? (conta?.foto ?? ''),
          destinatarioId: remetenteOriginalId,
          texto: textoDigitado.trim(),
          dataHora: DateTime.now(),
          enviadaPorMim: true,
          lida: true,
          statusEnvio: 'enviada',
        );

        // Salva localmente e despacha para a rede local
        await ChatService.enviarMensagemInstantanea(novaMensagem);
      }
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao processar resposta: $e');
    }
  }

  static final Set<String> _mensagensNotificadas = <String>{};

  /// Cancela notificações pendentes de uma conversa específica (ex.: quando aberta pelo usuário)
  static Future<void> cancelarNotificacaoConversa(String conversaId) async {
    if (!kIsWeb && !Platform.isAndroid) return;
    try {
      final notificacaoId = conversaId.hashCode.abs() % 100000;
      await _notificationsPlugin.cancel(id: notificacaoId);
    } catch (_) {}
  }

  /// Exibe notificação nativa no Android com a Logo do Nous, foto real do remetente, na cor da aplicação e resposta rápida (estilo WhatsApp)
  static Future<void> exibirNotificacaoMensagem(MensagemChat mensagem) async {
    if (!kIsWeb && !Platform.isAndroid) return;
    if (!_inicializado) {
      await inicializar();
    }

    // Blindagem rigorosa contra loops contínuos de notificação para a mesma mensagem
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
      final temaAtual = ThemeController.currentTheme.value;
      final corApp = temaAtual.buttonColor;

      // Resolução soberana da foto do remetente para avatar grande na notificação
      AndroidBitmap<Object>? avatarBitmap;
      AndroidIcon<Object>? avatarIcon;
      String fotoCaminho = mensagem.remetenteFoto.trim();
      if (fotoCaminho.isEmpty) {
        final cpfRemNorm = ChatService.normalizarCpf(mensagem.remetenteId);
        if (cpfRemNorm.length == 11) {
          final conta = await ContasNousService.buscarPorCpf(cpfRemNorm);
          if (conta != null && conta.fotoExibicao.isNotEmpty) {
            fotoCaminho = conta.fotoExibicao.trim();
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

      final androidDetails = AndroidNotificationDetails(
        canalId,
        canalNome,
        channelDescription: canalDescricao,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: avatarBitmap,
        color: corApp,
        colorized: false,
        category: AndroidNotificationCategory.message,
        styleInformation: MessagingStyleInformation(
          Person(
            name: 'Eu',
            key: mensagem.destinatarioId,
          ),
          conversationTitle: tituloConversa,
          groupConversation: ehGrupo,
          messages: [
            Message(
              textoCorpo,
              mensagem.dataHora,
              personRemetente,
            ),
          ],
        ),
        actions: const [
          AndroidNotificationAction(
            acaoResponderId,
            'Responder',
            inputs: [
              AndroidNotificationActionInput(
                label: 'Digite sua resposta...',
              ),
            ],
            allowGeneratedReplies: true,
            showsUserInterface: false,
          ),
        ],
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      final payloadMap = {
        'conversaId': mensagem.conversaId,
        'remetenteId': mensagem.remetenteId,
        'destinatarioId': mensagem.destinatarioId,
        'mensagemId': mensagem.id,
      };

      final notificacaoId = mensagem.conversaId.hashCode.abs() % 100000;

      await _notificationsPlugin.show(
        id: notificacaoId,
        title: mensagem.remetenteNome.isNotEmpty
            ? mensagem.remetenteNome
            : 'Nova Mensagem',
        body: textoCorpo,
        notificationDetails: notificationDetails,
        payload: jsonEncode(payloadMap),
      );
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao exibir notificação: $e');
    }
  }
}
