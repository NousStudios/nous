import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

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
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _aoReceberRespostaNotificacao,
      );

      // Solicita permissão no Android 13+
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _inicializado = true;
    } catch (e) {
      debugPrint('[NotificacaoAndroidService] Erro ao inicializar: $e');
    }
  }

  /// Trata clique na notificação ou envio de resposta direta (Direct Reply)
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
        final remetenteNome = conta?.nome.isNotEmpty == true
            ? conta!.nome
            : 'Usuário';

        final novaMensagem = MensagemChat(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversaId: conversaId,
          remetenteId: destinatarioId,
          remetenteNome: remetenteNome,
          remetenteFoto: conta?.foto ?? '',
          destinatarioId: remetenteOriginalId,
          texto: textoDigitado.trim(),
          dataHora: DateTime.now(),
          enviadaPorMim: true,
          lida: true,
        );

        await ChatService.salvarMensagem(novaMensagem);
      }
    } catch (e) {
      debugPrint(
        '[NotificacaoAndroidService] Erro ao processar resposta: $e',
      );
    }
  }

  /// Exibe notificação nativa no Android com estilo de mensagem e ação de resposta
  static Future<void> exibirNotificacaoMensagem(MensagemChat mensagem) async {
    if (!kIsWeb && !Platform.isAndroid) return;
    if (!_inicializado) {
      await inicializar();
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        canalId,
        canalNome,
        channelDescription: canalDescricao,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        category: AndroidNotificationCategory.message,
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
          ),
        ],
      );

      final notificationDetails =
          NotificationDetails(android: androidDetails);

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
        body: mensagem.texto,
        notificationDetails: notificationDetails,
        payload: jsonEncode(payloadMap),
      );
    } catch (e) {
      debugPrint(
        '[NotificacaoAndroidService] Erro ao exibir notificação: $e',
      );
    }
  }
}
