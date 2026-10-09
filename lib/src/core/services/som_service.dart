import 'dart:io';
import 'package:flutter/services.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

class SomService {
  static const String eventoNovoPedido = 'novo_pedido';
  static const String eventoConclusaoPedido = 'conclusao_pedido';
  static const String eventoBipVenda = 'bip_venda';

  static const String opcaoPadrao = 'padrao';
  static const String opcaoSilencioso = 'silencioso';

  /// Toca o bip padrão do sistema operacional com zero latência.
  static Future<void> tocarBipPadrao() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Toca um arquivo de áudio específico no Windows.
  static Future<void> tocarArquivo(String caminho) async {
    try {
      final file = File(caminho);
      if (!file.existsSync()) {
        await tocarBipPadrao();
        return;
      }

      if (Platform.isWindows) {
        final caminhoFormatado = caminho.replaceAll("'", "''");
        final ext = caminho.toLowerCase();
        if (ext.endsWith('.wav')) {
          Process.run(
            'powershell',
            [
              '-NoProfile',
              '-NonInteractive',
              '-Command',
              "(New-Object System.Media.SoundPlayer '$caminhoFormatado').Play();",
            ],
            runInShell: true,
          );
        } else {
          Process.run(
            'powershell',
            [
              '-NoProfile',
              '-NonInteractive',
              '-Command',
              "Add-Type -AssemblyName presentationCore; "
                  "\$player = New-Object System.Windows.Media.MediaPlayer; "
                  "\$player.Open([System.Uri]'$caminhoFormatado'); "
                  "\$player.Play(); "
                  "Start-Sleep -Milliseconds 1200;",
            ],
            runInShell: true,
          );
        }
      } else {
        await tocarBipPadrao();
      }
    } catch (_) {
      await tocarBipPadrao();
    }
  }

  /// Toca o som configurado para o evento informado segundo as preferências da loja.
  static Future<void> tocarEvento(String evento, {Loja? loja}) async {
    final config = loja?.sonsAlertas[evento]?.trim() ?? opcaoPadrao;

    if (config == opcaoSilencioso) {
      return;
    }

    if (config.isEmpty || config == opcaoPadrao) {
      await tocarBipPadrao();
      return;
    }

    await tocarArquivo(config);
  }
}
