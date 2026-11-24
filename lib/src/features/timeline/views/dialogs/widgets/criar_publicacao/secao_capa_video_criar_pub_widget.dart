import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_escolher_frame_video.dart';

class SecaoCapaVideoCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final XFile? capaVideo;
  final Uint8List? capaFrameBytes;
  final List<XFile> arquivosSelecionados;
  final double aspectRatio;
  final ValueChanged<XFile> onCapaImagemSelecionada;
  final ValueChanged<Uint8List> onFrameEscolhido;
  final VoidCallback onRemoverCapa;

  const SecaoCapaVideoCriarPubWidget({
    super.key,
    required this.theme,
    required this.capaVideo,
    required this.capaFrameBytes,
    required this.arquivosSelecionados,
    required this.aspectRatio,
    required this.onCapaImagemSelecionada,
    required this.onFrameEscolhido,
    required this.onRemoverCapa,
  });

  static Future<Uint8List?> capturarPrimeiroFrameBytes(
    String caminhoVideo,
  ) async {
    Player? player;
    try {
      try {
        MediaKit.ensureInitialized();
      } catch (_) {}
      player = Player();
      VideoController(player);
      await player.setVolume(0);
      await player
          .open(Media(caminhoVideo), play: true)
          .timeout(const Duration(seconds: 5));
      await player.stream.width
          .firstWhere((w) => w != null && w > 0)
          .timeout(const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 250));
      await player.pause();
      final bytes = await player
          .screenshot(format: 'image/jpeg')
          .timeout(const Duration(seconds: 3));
      if (bytes != null && bytes.isNotEmpty) {
        return bytes;
      }
    } catch (_) {
    } finally {
      try {
        await player?.dispose();
      } catch (_) {}
    }
    return null;
  }

  static Future<String> capturarPrimeiroFrameVideo(String caminhoVideo) async {
    final bytes = await capturarPrimeiroFrameBytes(caminhoVideo);
    if (bytes != null && bytes.isNotEmpty) {
      final salvo = await ImagemService.salvarBytesImagemLocal(
        bytes,
        extensaoOriginal: 'jpg',
      );
      if (salvo != null && salvo.isNotEmpty) {
        return ImagemService.paraCaminhoRelativoCanonico(salvo);
      }
    }
    return '';
  }

  Future<void> _selecionarCapaVideo() async {
    final arq = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Capa do Vídeo',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (arq == null) return;
    onCapaImagemSelecionada(arq);
  }

  Future<void> _escolherFrameDoVideo(BuildContext context) async {
    if (arquivosSelecionados.isEmpty) return;
    final bytes = await DialogEscolherFrameVideo.mostrar(
      context,
      theme: theme,
      caminhoVideo: arquivosSelecionados.first.path,
      aspectRatio: aspectRatio,
    );
    if (bytes != null && bytes.isNotEmpty) {
      onFrameEscolhido(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temCapa = capaVideo != null || capaFrameBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Capa do vídeo',
              style: theme.getTextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            if (temCapa)
              InkWell(
                onTap: onRemoverCapa,
                child: Text(
                  'Remover',
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.dangerColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (temCapa) ...[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: capaVideo != null
                      ? Image.file(
                          File(capaVideo!.path),
                          fit: BoxFit.cover,
                          cacheWidth: 720,
                        )
                      : Image.memory(
                          capaFrameBytes!,
                          fit: BoxFit.cover,
                          cacheWidth: 720,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (arquivosSelecionados.isNotEmpty) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFrameDoVideo(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.video_settings_outlined, size: 17),
                  label: Text(
                    'Escolher frame',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selecionarCapaVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.image_outlined, size: 17),
                label: Text(
                  'Enviar imagem',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
