import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Ponto de entrada nativo em background para respostas e ações no Android
@pragma('vm:entry-point')
void notificacaoBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();
  await BancoDadosService.inicializar();
  try {
    final ultimo = await GerenciadorDispositivoLocal.obterUltimoBalcao();
    if (ultimo.ip != null && ultimo.ip!.isNotEmpty) {
      ClienteRedeLocal().configurarServidorManual(
        ultimo.ip!,
        ultimo.porta ?? ServidorRedeLocal.portaPadraoHttp,
      );
    }
  } catch (_) {}
  await NotificacaoAndroidService.tratarRespostaNotificacao(response);
}

class NotificacaoAndroidService {
  NotificacaoAndroidService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const String canalId = 'nous_chat_mensagens_v9';
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
        'ic_notification',
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

        final cpfLogado = await ChatService.obterCpfLogadoLocal();
        final remOriginalEhLoja = remetenteOriginalId.startsWith('loja_');

        bool ehRespostaDeLoja = false;
        String idLojaConv = '';
        if (conversaId.startsWith('loja_') && conversaId.contains('_usuario_')) {
          final antesUsuario =
              conversaId.substring(0, conversaId.indexOf('_usuario_'));
          idLojaConv = PdvProvider.normalizarIdLoja(antesUsuario);
          ehRespostaDeLoja = !remOriginalEhLoja &&
              (destinatarioId.startsWith('loja_') ||
                  (cpfLogado.isEmpty && !remetenteOriginalId.startsWith('loja_')));
        } else {
          ehRespostaDeLoja = destinatarioId.startsWith('loja_');
          if (ehRespostaDeLoja) {
            idLojaConv = PdvProvider.normalizarIdLoja(destinatarioId);
          }
        }

        String remetenteIdFinal =
            cpfLogado.isNotEmpty ? cpfLogado : destinatarioId;
        String destinatarioFinal = remetenteOriginalId;
        String remetenteNome = 'Usuário';
        String remetenteFoto = '';

        if (ehRespostaDeLoja) {
          final idLimpo = idLojaConv.isNotEmpty
              ? idLojaConv
              : PdvProvider.normalizarIdLoja(destinatarioId);
          remetenteIdFinal = 'loja_$idLimpo';
          final loja = await LojasService.carregarLojaPorId(idLimpo);
          if (loja != null) {
            remetenteNome = loja.nome;
            remetenteFoto = loja.logo;
          } else {
            remetenteNome = 'Loja';
          }
        } else {
          final cpfBusca = ChatService.normalizarCpf(remetenteIdFinal);
          if (cpfBusca.length == 11) {
            remetenteIdFinal = cpfBusca;
            final conta = await ContasNousService.buscarPorCpf(cpfBusca);
            remetenteNome = conta?.nomeExibicao.isNotEmpty == true
                ? conta!.nomeExibicao
                : (conta?.nome.isNotEmpty == true ? conta!.nome : 'Usuário');
            remetenteFoto = conta?.fotoExibicao ?? (conta?.foto ?? '');
          }
          if (destinatarioFinal.isEmpty &&
              conversaId.startsWith('loja_') &&
              idLojaConv.isNotEmpty) {
            destinatarioFinal = 'loja_$idLojaConv';
          } else if (destinatarioFinal.isEmpty && cpfBusca.isNotEmpty) {
            destinatarioFinal =
                ChatService.extrairOutroCpf(conversaId, cpfBusca);
          }
        }

        final novaMensagem = MensagemChat(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversaId: conversaId,
          remetenteId: remetenteIdFinal,
          remetenteNome: remetenteNome,
          remetenteFoto: remetenteFoto,
          destinatarioId: destinatarioFinal,
          texto: textoDigitado.trim(),
          dataHora: DateTime.now(),
          enviadaPorMim: true,
          lida: false,
          statusEnvio: 'enviada',
        );

        final msgPersistida =
            await ChatService.enviarMensagemInstantanea(novaMensagem);
        await _despacharMensagemEmBackground(msgPersistida);
        await ChatService.marcarComoLidas(conversaId, remetenteIdFinal);
        await cancelarNotificacaoConversa(conversaId);
        return;
      }

      // 2. Ação: Marcar como Lida
      if (response.actionId == acaoMarcarLidaId) {
        if (conversaId.isNotEmpty) {
          final idLeitor = destinatarioId.isNotEmpty
              ? destinatarioId
              : await ChatService.obterCpfLogadoLocal();
          if (idLeitor.isNotEmpty) {
            await ChatService.marcarComoLidas(conversaId, idLeitor);
          }
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
            final bytesRedondos = await _gerarAvatarCircularBytes(fotoFisica);
            if (bytesRedondos != null) {
              avatarBitmap = ByteArrayAndroidBitmap(bytesRedondos);
              avatarIcon = ByteArrayAndroidIcon(bytesRedondos);
            } else {
              avatarBitmap = FilePathAndroidBitmap(fotoFisica);
              avatarIcon = BitmapFilePathAndroidIcon(fotoFisica);
            }
          } catch (_) {}
        }
      }
      avatarBitmap ??= const DrawableResourceAndroidBitmap('@drawable/ic_nous_badge');
      avatarIcon ??= const DrawableResourceAndroidIcon('@drawable/ic_nous_badge');

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
        icon: 'ic_notification',
        largeIcon: avatarBitmap,
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
        icon: 'ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_nous_badge'),
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

  /// Recorta uma imagem local em círculo (128x128 PNG) para exibição redonda nas notificações.
  static Future<Uint8List?> _gerarAvatarCircularBytes(String caminho) async {
    try {
      final rawBytes = await File(caminho).readAsBytes();
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      const double tamanho = 128.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final path = Path()
        ..addOval(const Rect.fromLTWH(0, 0, tamanho, tamanho));
      canvas.clipPath(path);

      final srcW = srcImage.width.toDouble();
      final srcH = srcImage.height.toDouble();
      final minDim = srcW < srcH ? srcW : srcH;
      final srcRect = Rect.fromCenter(
        center: Offset(srcW / 2, srcH / 2),
        width: minDim,
        height: minDim,
      );
      const dstRect = Rect.fromLTWH(0, 0, tamanho, tamanho);
      canvas.drawImageRect(srcImage, srcRect, dstRect, Paint()..isAntiAlias = true);

      final picture = recorder.endRecording();
      final imgCircular = await picture.toImage(128, 128);
      final byteData = await imgCircular.toByteData(format: ui.ImageByteFormat.png);
      srcImage.dispose();
      imgCircular.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Despacha a mensagem respondida via Direct Reply mesmo quando executado
  /// no isolate isolado em background do Android.
  static Future<void> _despacharMensagemEmBackground(MensagemChat msg) async {
    final dadosEnvio = {
      'tipo': 'mensagem_chat',
      'mensagem': msg.toJson(),
    };
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);

    try {
      // 1. Tenta POST no loopback local 127.0.0.1:8080 (caso este aparelho seja o servidor balcão)
      try {
        final uriLocal = Uri.parse('http://127.0.0.1:8080/api/chat/mensagem');
        final req = await client
            .postUrl(uriLocal)
            .timeout(const Duration(milliseconds: 1200));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(dadosEnvio));
        final resp = await req.close().timeout(const Duration(seconds: 2));
        await resp.drain<void>();
        if (resp.statusCode == HttpStatus.ok) {
          return;
        }
      } catch (_) {}

      // 2. Tenta POST no IP do balcão configurado (caso este aparelho seja cliente terminal)
      try {
        final ultimo = await GerenciadorDispositivoLocal.obterUltimoBalcao();
        final ip = (ultimo.ip != null && ultimo.ip!.isNotEmpty)
            ? ultimo.ip
            : ClienteRedeLocal().ipServidor;
        final porta = ultimo.porta ??
            ClienteRedeLocal().portaServidor ??
            ServidorRedeLocal.portaPadraoHttp;
        if (ip != null && ip.isNotEmpty) {
          final uriRemota = ResolvedorUrlRede.montarUriHttp(
            hostOuIp: ip,
            porta: porta,
            caminho: '/api/chat/mensagem',
          );
          final req = await client
              .postUrl(uriRemota)
              .timeout(const Duration(seconds: 3));
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode(dadosEnvio));
          final resp = await req.close().timeout(const Duration(seconds: 3));
          await resp.drain<void>();
        }
      } catch (_) {}
    } finally {
      client.close(force: true);
    }
  }
}
