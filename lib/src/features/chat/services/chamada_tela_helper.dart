import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Encapsula os detalhes de captura de tela por plataforma:
/// - Android: inicia/para o Foreground Service de MediaProjection via MethodChannel.
/// - Desktop (Windows/Linux/macOS): obtém a tela principal via desktopCapturer.
class ChamadaTelaHelper {
  ChamadaTelaHelper._();

  static const MethodChannel _capturaTelaChannel =
      MethodChannel('com.nous.app/captura_tela');

  static Future<void> iniciarServicoAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _capturaTelaChannel.invokeMethod<bool>('iniciarServicoTela');
    } catch (e) {
      debugPrint('[ChamadaTelaHelper] Aviso ao iniciar serviço de tela Android: $e');
    }
  }

  static Future<void> pararServicoAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _capturaTelaChannel.invokeMethod<bool>('pararServicoTela');
    } catch (_) {}
  }

  static Future<void> iniciarServicoChamadaAndroid({
    required String nomeContato,
    required bool ehVideo,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _capturaTelaChannel.invokeMethod<bool>(
        'iniciarServicoChamada',
        <String, dynamic>{
          'nomeContato': nomeContato,
          'ehVideo': ehVideo,
        },
      );
    } catch (e) {
      debugPrint('[ChamadaTelaHelper] Aviso ao iniciar serviço de chamada Android: $e');
    }
  }

  static Future<void> pararServicoChamadaAndroid() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _capturaTelaChannel.invokeMethod<bool>('pararServicoChamada');
    } catch (_) {}
  }

  /// Obtém o MediaStream da tela do dispositivo sem exibir diálogos extras no desktop.
  static Future<MediaStream?> capturarTela() async {
    await iniciarServicoAndroid();

    final Map<String, dynamic> constraints;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final fontes = await desktopCapturer.getSources(
        types: <SourceType>[SourceType.Screen],
      );
      if (fontes.isEmpty) {
        debugPrint('[ChamadaTelaHelper] Nenhuma tela disponível para captura.');
        return null;
      }
      constraints = <String, dynamic>{
        'video': <String, dynamic>{
          'deviceId': <String, dynamic>{'exact': fontes.first.id},
          'mandatory': <String, dynamic>{'frameRate': 30.0},
        },
        'audio': false,
      };
    } else {
      constraints = <String, dynamic>{
        'video': true,
        'audio': false,
      };
    }

    return navigator.mediaDevices.getDisplayMedia(constraints);
  }
}
