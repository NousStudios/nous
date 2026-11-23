import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/leitor_pdf_nous_widget.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Renderiza a capa minimalista de uma publicação de mídia (Música, Vídeo ou PDF)
/// respeitando o `AppTheme` ativo, reutilizando caches de thumbnail e importando
/// automaticamente a miniatura embutida (ID3/APIC) de arquivos de áudio.
class CapaMidiaUniversalWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final double? largura;
  final double? altura;
  final double borderRadius;
  final IconData? iconeFallback;
  final double tamanhoIcone;

  const CapaMidiaUniversalWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    this.largura,
    this.altura,
    this.borderRadius = 10,
    this.iconeFallback,
    this.tamanhoIcone = 32,
  });

  /// Extrai a miniatura em bytes de um áudio (seja do `PlayerAudioService`
  /// ativo ou lendo os metadados ID3/pasta do arquivo local).
  static Uint8List? obterCapaAudioBytes(PublicacaoSocial publicacao) {
    final caminhoOriginal = PlayerUniversalController.obterCaminhoMidiaPrincipal(
      publicacao,
    );
    if (caminhoOriginal.isEmpty) return null;

    final audioService = PlayerAudioService.instancia;
    final estadoAtual = audioService.estadoAtual;
    if ((audioService.ehMesmoAudio(caminhoOriginal, estadoAtual.caminho) ||
            audioService.ehMesmoAudio(
              caminhoOriginal,
              estadoAtual.caminhoOriginal,
            )) &&
        (estadoAtual.metadados?.temCapa ?? false)) {
      return estadoAtual.metadados!.capaBytes;
    }

    final resolvido =
        ImagemService.resolverCaminhoExistente(caminhoOriginal) ??
            caminhoOriginal;
    if (File(resolvido).existsSync()) {
      final meta = MetadadosAudioService.extrair(resolvido);
      if (meta.temCapa) return meta.capaBytes;
    }
    return null;
  }

  /// Retorna um `ImageProvider` síncrono (arquivo ou memória) quando houver
  /// capa explícita ou miniatura embutida no arquivo de áudio — ideal para o
  /// fundo desfocado do player.
  static ImageProvider? obterImageProvider(PublicacaoSocial publicacao) {
    if (publicacao.capaCaminho.isNotEmpty) {
      final capaResolvida =
          ImagemService.resolverCaminhoExistente(publicacao.capaCaminho);
      if (capaResolvida != null && File(capaResolvida).existsSync()) {
        return FileImage(File(capaResolvida));
      }
    }
    if (PlayerUniversalController.possuiAudio(publicacao)) {
      final bytes = obterCapaAudioBytes(publicacao);
      if (bytes != null && bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final capaResolvida = publicacao.capaCaminho.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(publicacao.capaCaminho)
        : null;

    Widget conteudo;
    if (capaResolvida != null && File(capaResolvida).existsSync()) {
      conteudo = Image.file(
        File(capaResolvida),
        fit: BoxFit.cover,
        width: largura,
        height: altura,
        errorBuilder: (_, _, _) => _buildFallbackOuAudio(),
      );
    } else if (publicacao.tipo == TipoFeedSocial.documentos ||
        publicacao.tipo == TipoFeedSocial.livros) {
      final caminhoPdf =
          PlayerUniversalController.obterCaminhoMidiaPrincipal(publicacao);
      if (caminhoPdf.isNotEmpty) {
        conteudo = AbsorbPointer(
          child: LeitorPdfNousWidget(
            theme: theme,
            caminhoArquivo: caminhoPdf,
            nomeArquivo: publicacao.midias.isNotEmpty
                ? publicacao.midias.first.nomeArquivo
                : '',
            modoFeedPreview: true,
          ),
        );
      } else {
        conteudo = _buildFallbackPorTipo();
      }
    } else if (PlayerUniversalController.possuiVideo(publicacao)) {
      final caminhoVideo =
          PlayerUniversalController.obterCaminhoMidiaPrincipal(
        publicacao,
        preferirVideo: true,
      );
      if (caminhoVideo.isNotEmpty) {
        conteudo = FutureBuilder<Uint8List?>(
          future: PlayerVideoNousWidget.obterOuGerarCapaVideo(caminhoVideo),
          builder: (_, snap) {
            final bytes = snap.data;
            if (bytes != null && bytes.isNotEmpty) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: largura,
                height: altura,
              );
            }
            return _buildFallbackOuAudio();
          },
        );
      } else {
        conteudo = _buildFallbackOuAudio();
      }
    } else {
      conteudo = _buildFallbackOuAudio();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: largura,
        height: altura,
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.45),
          ),
        ),
        child: conteudo,
      ),
    );
  }

  Widget _buildFallbackOuAudio() {
    if (PlayerUniversalController.possuiAudio(publicacao)) {
      final bytes = obterCapaAudioBytes(publicacao);
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: largura,
          height: altura,
          errorBuilder: (_, _, _) => _buildFallbackPorTipo(),
        );
      }
    }
    return _buildFallbackPorTipo();
  }

  Widget _buildFallbackPorTipo() {
    final icone = iconeFallback ??
        switch (publicacao.tipo) {
          TipoFeedSocial.musicas => Icons.music_note_rounded,
          TipoFeedSocial.videos => Icons.play_arrow_rounded,
          TipoFeedSocial.documentos => Icons.picture_as_pdf_outlined,
          TipoFeedSocial.livros => Icons.menu_book_rounded,
          _ => Icons.audiotrack_rounded,
        };

    return Container(
      width: largura,
      height: altura,
      color: theme.cardBackgroundColor,
      alignment: Alignment.center,
      child: Icon(
        icone,
        size: tamanhoIcone,
        color: theme.textColor.withValues(alpha: 0.85),
      ),
    );
  }
}
