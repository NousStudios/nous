import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';

/// Retorna o ícone padrão associado a cada tipo de timeline social.
IconData iconeTimelineSocial(TipoFeedSocial tipo) => switch (tipo) {
      TipoFeedSocial.fotos => Icons.grid_on_sharp,
      TipoFeedSocial.videos => Icons.play_circle_outline_rounded,
      TipoFeedSocial.documentos => Icons.description_outlined,
      TipoFeedSocial.livros => Icons.menu_book_outlined,
      TipoFeedSocial.musicas => Icons.music_note_outlined,
      TipoFeedSocial.escritos => Icons.article_outlined,
      TipoFeedSocial.republicacoes => Icons.repeat_rounded,
      TipoFeedSocial.interacoes => Icons.history_toggle_off_rounded,
      TipoFeedSocial.salvos => Icons.bookmark_border_rounded,
      TipoFeedSocial.likes => Icons.thumb_up_off_alt_rounded,
      TipoFeedSocial.deslikes => Icons.thumb_down_off_alt_rounded,
      TipoFeedSocial.denuncias => Icons.shield_outlined,
    };

/// Grade de 3 colunas para exibição em galeria de publicações do perfil.
class TimelineGaleriaGridWidget extends StatelessWidget {
  final AppTheme theme;
  final List<PublicacaoSocial> publicacoes;
  final UsuarioNous? usuarioLogado;
  final bool ehProprioUsuario;
  final bool modoGaleria3Colunas;
  final Future<void> Function() onRecarregar;

  const TimelineGaleriaGridWidget({
    super.key,
    required this.theme,
    required this.publicacoes,
    required this.usuarioLogado,
    required this.ehProprioUsuario,
    required this.modoGaleria3Colunas,
    required this.onRecarregar,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: publicacoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, index) {
        final pub = publicacoes[index];
        final tile = GestureDetector(
          onTap: () => DialogDetalhesPublicacao.mostrar(
            context,
            theme: theme,
            publicacao: pub,
            usuarioLogado: usuarioLogado,
            listaPublicacoes: publicacoes,
            indiceInicial: index,
          ),
          child: _buildTileGaleria(pub),
        );

        if (!ehProprioUsuario) {
          return KeyedSubtree(
            key: ValueKey('galeria_pub_${pub.id}'),
            child: tile,
          );
        }

        return DragTarget<int>(
          key: ValueKey('galeria_pub_${pub.id}'),
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) async {
            await TimelineService.reordenarPublicacaoNaLista(
              listaAtual: publicacoes,
              indiceAtual: details.data,
              novoIndice: index,
            );
            await onRecarregar();
          },
          builder: (ctx, candidateData, rejectedData) {
            final emAlvo = candidateData.isNotEmpty;
            return AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: emAlvo ? 0.92 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: emAlvo
                    ? BoxDecoration(
                        border: Border.all(
                          color: theme.buttonColor,
                          width: 2.5,
                        ),
                      )
                    : null,
                child: LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    elevation: 10,
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: Transform.scale(
                        scale: 1.06,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildTileGaleria(pub),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.30,
                    child: _buildTileGaleria(pub),
                  ),
                  child: tile,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTileGaleria(PublicacaoSocial pub) {
    final primeiraMidia = pub.midias.isNotEmpty ? pub.midias.first : null;
    final ext = (primeiraMidia?.mimeTipo ?? '').toLowerCase();
    final ehVideo = pub.tipo == TipoFeedSocial.videos ||
        ext == 'mp4' ||
        ext == 'mov' ||
        ext == 'webm' ||
        ext == 'mkv' ||
        ext == 'avi';
    final ehImagem = primeiraMidia != null &&
        (ext == 'jpg' ||
            ext == 'jpeg' ||
            ext == 'png' ||
            ext == 'webp' ||
            ext == 'gif' ||
            (ext.isEmpty && pub.tipo == TipoFeedSocial.fotos));

    return Container(
      color: theme.cardBackgroundColor.withValues(alpha: 0.6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ehVideo)
            _buildConteudoVideo(pub, primeiraMidia)
          else if (pub.midias.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  pub.texto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: theme.textColor,
                  ),
                ),
              ),
            )
          else if (ehImagem)
            _renderImg(
              primeiraMidia,
              BoxFit.cover,
              null,
              Alignment(pub.alinhamentoX, pub.alinhamentoY),
            )
          else if (ext == 'pdf' ||
              primeiraMidia!.nomeArquivo.toLowerCase().endsWith('.pdf'))
            _buildConteudoPdf(pub, primeiraMidia!)
          else
            _buildTilePadraoMidia(
              icone: pub.tipo == TipoFeedSocial.musicas
                  ? Icons.music_note_rounded
                  : iconeTimelineSocial(pub.tipo),
              rotulo: primeiraMidia.nomeArquivo.isNotEmpty
                  ? primeiraMidia.nomeArquivo
                  : pub.texto,
            ),
          if (pub.fixada)
            Positioned(
              top: 6,
              left: 6,
              child: Icon(
                Icons.push_pin_rounded,
                size: 16,
                color: theme.buttonTextColor,
              ),
            ),
          if (ehVideo)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: theme.buttonTextColor,
              ),
            )
          else if (pub.midias.length > 1)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.collections_outlined,
                size: 16,
                color: theme.buttonTextColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConteudoVideo(
    PublicacaoSocial pub,
    MidiaPublicacao? primeiraMidia,
  ) {
    if (pub.capaCaminho.isNotEmpty) {
      return _renderImg(
        MidiaPublicacao(caminhoRelativo: pub.capaCaminho),
        BoxFit.cover,
        null,
        Alignment.center,
      );
    }
    if (primeiraMidia != null) {
      return FutureBuilder<Uint8List?>(
        future: PlayerVideoNousWidget.obterOuGerarCapaVideo(
          primeiraMidia.caminhoRelativo,
        ),
        builder: (_, snap) {
          if (snap.data != null && snap.data!.isNotEmpty) {
            return Image.memory(snap.data!, fit: BoxFit.cover);
          }
          return _buildPlaceholderVideo();
        },
      );
    }
    return _buildPlaceholderVideo();
  }

  Widget _buildPlaceholderVideo() {
    return Container(
      color: theme.backgroundColor.withValues(alpha: 0.55),
      child: Center(
        child: Icon(
          Icons.videocam_outlined,
          size: 28,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildConteudoPdf(
    PublicacaoSocial pub,
    MidiaPublicacao primeiraMidia,
  ) {
    if (pub.capaCaminho.isNotEmpty) {
      return _renderImg(
        MidiaPublicacao(caminhoRelativo: pub.capaCaminho),
        BoxFit.cover,
        null,
        Alignment.topCenter,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: TimelineService.obterOuGerarMiniaturaPdf(
        primeiraMidia.caminhoRelativo,
      ),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Container(
            color: theme.cardBackgroundColor,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
            ),
          );
        }
        return _buildTilePadraoMidia(
          icone: Icons.picture_as_pdf_outlined,
          rotulo: primeiraMidia.nomeArquivo.isNotEmpty
              ? primeiraMidia.nomeArquivo
              : pub.texto,
        );
      },
    );
  }

  Widget _buildTilePadraoMidia({
    required IconData icone,
    required String rotulo,
  }) {
    return Container(
      color: theme.backgroundColor.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 26, color: theme.textColor),
          const SizedBox(height: 6),
          Text(
            rotulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 10, color: theme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _renderImg(
    MidiaPublicacao m,
    BoxFit fit,
    double? aspectRatio,
    Alignment alignment,
  ) {
    final alignFinal = (m.alinhamentoX != 0.0 || m.alinhamentoY != 0.0)
        ? Alignment(m.alinhamentoX, m.alinhamentoY)
        : alignment;

    Widget buildArquivo(String path) {
      final img = ClipRect(
        child: Transform.scale(
          scale: m.escalaZoom.clamp(1.0, 3.5),
          alignment: alignFinal,
          child: Image.file(
            File(path),
            fit: fit,
            alignment: alignFinal,
            cacheWidth: modoGaleria3Colunas ? 420 : 900,
          ),
        ),
      );
      if (aspectRatio != null) {
        return AspectRatio(aspectRatio: aspectRatio, child: img);
      }
      return img;
    }

    final syncPath = TimelineService.resolverCaminhoMidiaSync(m.caminhoRelativo);
    if (syncPath != null) {
      return buildArquivo(syncPath);
    }

    return FutureBuilder<String?>(
      future: TimelineService.resolverCaminhoMidia(m.caminhoRelativo),
      builder: (_, snap) {
        final path = snap.data;
        if (path == null) return const SizedBox(height: 120);
        return buildArquivo(path);
      },
    );
  }
}
