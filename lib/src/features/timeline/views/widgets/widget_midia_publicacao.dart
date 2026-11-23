import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/leitor_pdf_nous_widget.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/core/widgets/reprodutor_audio_widget.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_player_musica_cifra.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_visualizar_documento.dart';

/// Renderizador unificado de mídias não-imagem (áudio/música, vídeo e documentos)
/// para os cards da timeline e janela de detalhes da publicação.
class WidgetMidiaPublicacao extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final bool autoPlayVideo;
  final bool modoLeitorPdfCompleto;
  final bool pdfFullScreen;
  final VoidCallback? onAbrirPublicacao;
  final ValueChanged<bool>? onAlternarPdfFullScreen;

  const WidgetMidiaPublicacao({
    super.key,
    required this.theme,
    required this.publicacao,
    this.autoPlayVideo = false,
    this.modoLeitorPdfCompleto = false,
    this.pdfFullScreen = false,
    this.onAbrirPublicacao,
    this.onAlternarPdfFullScreen,
  });

  bool _ehPdf(MidiaPublicacao m) {
    final ext = m.mimeTipo.toLowerCase();
    return ext == 'pdf' || m.nomeArquivo.toLowerCase().endsWith('.pdf');
  }

  bool _ehAudio(MidiaPublicacao m) {
    final ext = m.mimeTipo.toLowerCase();
    return ext == 'mp3' ||
        ext == 'm4a' ||
        ext == 'wav' ||
        ext == 'ogg' ||
        ext == 'aac' ||
        ext == 'flac' ||
        publicacao.tipo == TipoFeedSocial.musicas;
  }

  bool _ehVideo(MidiaPublicacao m) {
    final ext = m.mimeTipo.toLowerCase();
    return ext == 'mp4' ||
        ext == 'mov' ||
        ext == 'webm' ||
        ext == 'mkv' ||
        ext == 'avi' ||
        publicacao.tipo == TipoFeedSocial.videos;
  }

  String _formatarTamanho(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (publicacao.midias.isEmpty) return const SizedBox.shrink();

    Widget construirItem(MidiaPublicacao m) {
      final syncPath =
          TimelineService.resolverCaminhoMidiaSync(m.caminhoRelativo);
      if (syncPath != null) {
        return _buildItem(context, m, syncPath);
      }
      if (_ehVideo(m)) {
        final urlStream = TimelineMidiaService.obterUrlStreamingVideo(
          m.caminhoRelativo,
        );
        if (urlStream != null) {
          return _buildItem(context, m, urlStream);
        }
      }
      return FutureBuilder<String?>(
        future: TimelineService.resolverCaminhoMidia(m.caminhoRelativo),
        builder: (ctx, snap) {
          final path = snap.data;
          if (path == null) {
            if (snap.connectionState == ConnectionState.done) {
              return _buildCardIndisponivel(m);
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.nomeArquivo.isNotEmpty
                          ? m.nomeArquivo
                          : 'Carregando mídia...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildItem(ctx, m, path);
        },
      );
    }

    if (publicacao.midias.length == 1) {
      return construirItem(publicacao.midias.first);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: publicacao.midias.map(construirItem).toList(),
      ),
    );
  }

  Widget _buildCardIndisponivel(MidiaPublicacao m) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: theme.secondaryTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m.nomeArquivo.isNotEmpty
                  ? '${m.nomeArquivo} (indisponível localmente)'
                  : 'Arquivo indisponível localmente',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, MidiaPublicacao m, String path) {
    if (_ehAudio(m)) {
      final tituloFaixa =
          m.nomeArquivo.isNotEmpty ? m.nomeArquivo : 'Áudio / Música';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReprodutorAudioWidget(
              theme: theme,
              caminho: path,
              tituloPadrao: tituloFaixa,
              subtituloPadrao: publicacao.autorNome,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => DialogPlayerMusicaCifra.mostrar(
                  context,
                  theme: theme,
                  publicacao: publicacao,
                  caminhoAudio: path,
                  tituloFaixa: tituloFaixa,
                ),
                icon: Icon(
                  Icons.queue_music_rounded,
                  size: 16,
                  color: theme.textColor,
                ),
                label: Text(
                  publicacao.cifraLetra.trim().isNotEmpty
                      ? 'Abrir Player & Cifra'
                      : 'Abrir no Player',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ehVideo = _ehVideo(m);
    final tamanho = _formatarTamanho(m.tamanhoBytes);

    if (ehVideo) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: PlayerVideoNousWidget(
          theme: theme,
          caminhoVideo: path,
          caminhoCapa: publicacao.capaCaminho,
          aspectRatio: publicacao.aspectRatioEfetivo ?? (16 / 9),
          autoPlay: autoPlayVideo,
          titulo: m.nomeArquivo,
          onIniciarReproducao: () {
            String? meuCpf;
            try {
              meuCpf = context.read<AuthProvider?>()?.cpf;
            } catch (_) {}
            TimelineService.registrarVisualizacaoPublicacao(
              publicacao,
              origem: 'video',
              visualizadorCpf: meuCpf,
            );
          },
        ),
      );
    }

    if (_ehPdf(m)) {
      return LeitorPdfNousWidget(
        theme: theme,
        caminhoArquivo: path,
        nomeArquivo: m.nomeArquivo,
        tamanhoBytes: m.tamanhoBytes,
        modoFeedPreview: !modoLeitorPdfCompleto,
        modoFullScreen: pdfFullScreen,
        onAbrirPublicacao: onAbrirPublicacao,
        onAlternarFullScreen: onAlternarPdfFullScreen,
      );
    }

    final existe = File(path).existsSync();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.textColor.withValues(alpha: 0.12),
          child: Icon(
            ehVideo
                ? Icons.play_arrow_rounded
                : Icons.description_outlined,
            color: theme.textColor,
          ),
        ),
        title: Text(
          m.nomeArquivo.isNotEmpty
              ? m.nomeArquivo
              : (ehVideo ? 'Vídeo' : 'Documento'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.getTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        subtitle: Text(
          [
            if (ehVideo) 'Toque para reproduzir vídeo' else 'Toque para abrir',
            if (tamanho.isNotEmpty) tamanho,
          ].join(' • '),
          style: theme.getTextStyle(
            fontSize: 11.5,
            color: theme.secondaryTextColor,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new_rounded,
          size: 18,
          color: theme.textColor,
        ),
        onTap: existe
            ? () => DialogVisualizarDocumento.mostrar(
                  context,
                  theme: theme,
                  caminho: path,
                  nomeArquivo: m.nomeArquivo,
                  tamanhoBytes: m.tamanhoBytes,
                )
            : null,
      ),
    );
  }
}
