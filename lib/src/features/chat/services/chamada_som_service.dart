import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Gerencia os toques sonoros contínuos durante o disparo e o recebimento de chamadas.
class ChamadaSomService {
  ChamadaSomService._();
  static final ChamadaSomService instancia = ChamadaSomService._();

  AudioPlayer? _player;
  Timer? _timerLoop;
  bool _tocando = false;

  /// Inicia o toque discreto de espera enquanto o usuário aguarda o outro lado atender.
  Future<void> iniciarToqueChamando() async {
    await _iniciarLoop(
      assetPath: 'sounds/universfield-notification-beep-229154.mp3',
      intervalo: const Duration(milliseconds: 2800),
      volume: 0.45,
    );
  }

  /// Inicia o toque de chamada recebida até o usuário atender, rejeitar ou expirar.
  Future<void> iniciarToqueRecebida() async {
    await _iniciarLoop(
      assetPath: 'sounds/universfield-new-notification-062.mp3',
      intervalo: const Duration(milliseconds: 2200),
      volume: 0.85,
    );
  }

  /// Interrompe imediatamente qualquer toque ativo.
  Future<void> pararToque() async {
    _tocando = false;
    _timerLoop?.cancel();
    _timerLoop = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> _iniciarLoop({
    required String assetPath,
    required Duration intervalo,
    required double volume,
  }) async {
    await pararToque();
    _tocando = true;

    await _tocarUmaVez(assetPath, volume);
    _timerLoop = Timer.periodic(intervalo, (_) {
      if (!_tocando) return;
      unawaited(_tocarUmaVez(assetPath, volume));
    });
  }

  Future<void> _tocarUmaVez(String assetPath, double volume) async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.setVolume(volume);
      await _player!.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[ChamadaSomService] Aviso ao reproduzir toque: $e');
    }
  }
}
