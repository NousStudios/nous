import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

class SomNativoItem {
  final String id;
  final String nome;
  final String assetPath;

  const SomNativoItem({
    required this.id,
    required this.nome,
    required this.assetPath,
  });
}

class SomService {
  static const String eventoNovoPedido = 'novo_pedido';
  static const String eventoConclusaoPedido = 'conclusao_pedido';
  static const String eventoBipVenda = 'bip_venda';

  static const String opcaoPadrao = 'padrao';
  static const String opcaoSilencioso = 'silencioso';

  static const List<SomNativoItem> sonsNativos = [
    SomNativoItem(
      id: 'asset:cash',
      nome: 'Caixa Registradora (Cash)',
      assetPath: 'assets/sounds/cash.mp3',
    ),
    SomNativoItem(
      id: 'asset:beep_digital',
      nome: 'Beep Digital Curto',
      assetPath: 'assets/sounds/universfield-notification-beep-229154.mp3',
    ),
    SomNativoItem(
      id: 'asset:ping_suave',
      nome: 'Ping Suave (Notificação)',
      assetPath: 'assets/sounds/dragon-studio-notification-ping-372479.mp3',
    ),
    SomNativoItem(
      id: 'asset:alerta_aviso',
      nome: 'Alerta / Aviso (Warning)',
      assetPath: 'assets/sounds/universfield-warning-notification.mp3',
    ),
    SomNativoItem(
      id: 'asset:sino_harmonico',
      nome: 'Sino Harmônico',
      assetPath: 'assets/sounds/universfield-new-notification-07-210334.mp3',
    ),
    SomNativoItem(
      id: 'asset:notif_dupla',
      nome: 'Notificação Dupla',
      assetPath: 'assets/sounds/quiandrea96-notification-457196.mp3',
    ),
    SomNativoItem(
      id: 'asset:alerta_discreto',
      nome: 'Alerta Discreto',
      assetPath: 'assets/sounds/universfield-new-notification-08-352461.mp3',
    ),
    SomNativoItem(
      id: 'asset:notif_melodica',
      nome: 'Melodia Suave',
      assetPath: 'assets/sounds/universfield-new-notification-050-494248.mp3',
    ),
    SomNativoItem(
      id: 'asset:notif_viva',
      nome: 'Notificação Viva',
      assetPath: 'assets/sounds/universfield-new-notification-062-494544.mp3',
    ),
  ];

  static final Map<String, String> _cacheAssetTemp = {};

  static Future<String> _obterCaminhoTemporarioDoAsset(String assetPath) async {
    if (_cacheAssetTemp.containsKey(assetPath)) {
      final file = File(_cacheAssetTemp[assetPath]!);
      if (file.existsSync()) return file.path;
    }
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final nomeArquivo = assetPath.split('/').last;
    final file = File('${tempDir.path}/nous_sound_$nomeArquivo');
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      flush: true,
    );
    _cacheAssetTemp[assetPath] = file.path;
    return file.path;
  }

  /// Toca o bip padrão do sistema operacional com zero latência.
  static Future<void> tocarBipPadrao() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Toca um asset de áudio nativo do aplicativo.
  static Future<void> tocarAsset(String assetPath) async {
    try {
      final caminho = await _obterCaminhoTemporarioDoAsset(assetPath);
      await tocarArquivo(caminho);
    } catch (_) {
      await tocarBipPadrao();
    }
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
        final ext = caminho.toLowerCase();
        if (ext.endsWith('.wav')) {
          final caminhoFormatado = caminho.replaceAll("'", "''");
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
          final uriFormatada = file.uri.toString().replaceAll("'", "''");
          Process.run(
            'powershell',
            [
              '-NoProfile',
              '-NonInteractive',
              '-Command',
              "Add-Type -AssemblyName presentationCore; "
                  "\$player = New-Object System.Windows.Media.MediaPlayer; "
                  "\$player.Open([System.Uri]::new('$uriFormatada')); "
                  "\$player.Play(); "
                  "Start-Sleep -Milliseconds 1400;",
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

  /// Toca uma configuração qualquer (silencioso, bip padrão, asset nativo ou arquivo externo).
  static Future<void> tocarConfiguracao(String config) async {
    if (config == opcaoSilencioso) {
      return;
    }
    if (config.isEmpty || config == opcaoPadrao) {
      await tocarBipPadrao();
      return;
    }
    final nativo = sonsNativos.where((s) => s.id == config).firstOrNull;
    if (nativo != null) {
      await tocarAsset(nativo.assetPath);
      return;
    }
    if (config.startsWith('assets/')) {
      await tocarAsset(config);
      return;
    }
    await tocarArquivo(config);
  }

  /// Toca o som configurado para o evento informado segundo as preferências da loja.
  static Future<void> tocarEvento(String evento, {Loja? loja}) async {
    final config = loja?.sonsAlertas[evento]?.trim() ?? opcaoPadrao;
    await tocarConfiguracao(config);
  }
}
