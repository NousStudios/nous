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

  /// Lista monitores e janelas disponíveis no desktop para compartilhamento de tela.
  static Future<List<DesktopCapturerSource>> listarFontesDesktop() async {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const [];
    }
    try {
      return await desktopCapturer.getSources(
        types: <SourceType>[SourceType.Screen, SourceType.Window],
      );
    } catch (e) {
      debugPrint('[ChamadaTelaHelper] Erro ao listar fontes de tela: $e');
      return const [];
    }
  }

  /// Obtém o MediaStream da tela do dispositivo, tentando capturar áudio do sistema quando suportado.
  static Future<MediaStream?> capturarTela({String? sourceId}) async {
    await iniciarServicoAndroid();

    Map<String, dynamic> montarConstraints({required bool comAudio}) {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        return <String, dynamic>{
          'video': <String, dynamic>{
            if (sourceId != null && sourceId.isNotEmpty)
              'deviceId': <String, dynamic>{'exact': sourceId},
            'mandatory': <String, dynamic>{'frameRate': 30.0},
          },
          'audio': comAudio,
        };
      }
      return <String, dynamic>{
        'video': true,
        'audio': comAudio,
      };
    }

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
        (sourceId == null || sourceId.isEmpty)) {
      final fontes = await desktopCapturer.getSources(
        types: <SourceType>[SourceType.Screen],
      );
      if (fontes.isEmpty) {
        debugPrint('[ChamadaTelaHelper] Nenhuma tela disponível para captura.');
        return null;
      }
      sourceId = fontes.first.id;
    }

    try {
      return await navigator.mediaDevices.getDisplayMedia(
        montarConstraints(comAudio: true),
      );
    } catch (_) {
      return navigator.mediaDevices.getDisplayMedia(
        montarConstraints(comAudio: false),
      );
    }
  }
}
