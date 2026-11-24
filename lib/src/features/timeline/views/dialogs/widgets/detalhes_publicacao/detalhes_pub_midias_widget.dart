import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/carrossel_fotos_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/widget_midia_publicacao.dart';

class DetalhesPubMidiasWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final bool ajustarTelaCheia;
  final bool autoPlayVideo;
  final Key? midiaKey;
  final VoidCallback onDoubleTapLike;
  final bool pdfFullScreen;
  final ValueChanged<bool> onAlternarPdfFullScreen;

  const DetalhesPubMidiasWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    this.ajustarTelaCheia = false,
    this.autoPlayVideo = true,
    this.midiaKey,
    required this.onDoubleTapLike,
    required this.pdfFullScreen,
    required this.onAlternarPdfFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final todasFotos = publicacao.midias.every((m) {
      final ext = m.mimeTipo.toLowerCase();
      return ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'png' ||
          ext == 'webp' ||
          (ext.isEmpty && publicacao.tipo == TipoFeedSocial.fotos);
    });

    if (todasFotos) {
      return CarrosselFotosPublicacao(
        key: midiaKey ?? ValueKey('carrossel_${publicacao.id}'),
        theme: theme,
        midias: publicacao.midias,
        aspectRatio: publicacao.aspectRatioEfetivo,
        alignment: Alignment(publicacao.alinhamentoX, publicacao.alinhamentoY),
        escalaZoomPadrao: publicacao.escalaZoom,
        ajustarTelaCheia: ajustarTelaCheia,
        onDoubleTapLike: onDoubleTapLike,
      );
    }

    return WidgetMidiaPublicacao(
      key: midiaKey ?? ValueKey('midia_${publicacao.id}'),
      theme: theme,
      publicacao: publicacao,
      autoPlayVideo: autoPlayVideo,
      modoLeitorPdfCompleto: true,
      pdfFullScreen: pdfFullScreen,
      onAlternarPdfFullScreen: onAlternarPdfFullScreen,
    );
  }
}

class DetalhesPubPainelMidiaDesktopWidget extends StatelessWidget {
  final AppTheme theme;
  final List<PublicacaoSocial> lista;
  final PublicacaoSocial pubAtiva;
  final int indiceAtivo;
  final PageController pageController;
  final GlobalKey midiasKey;
  final bool pdfFullScreen;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onDoubleTapLike;
  final ValueChanged<bool> onAlternarPdfFullScreen;

  const DetalhesPubPainelMidiaDesktopWidget({
    super.key,
    required this.theme,
    required this.lista,
    required this.pubAtiva,
    required this.indiceAtivo,
    required this.pageController,
    required this.midiasKey,
    required this.pdfFullScreen,
    required this.onPageChanged,
    required this.onDoubleTapLike,
    required this.onAlternarPdfFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.cardBackgroundColor.withValues(alpha: 0.3),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: lista.length > 1
          ? PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              itemCount: lista.length,
              onPageChanged: onPageChanged,
              itemBuilder: (ctx, idx) {
                final item = lista[idx];
                final ehAtiva = idx == indiceAtivo;
                return Center(
                  child: DetalhesPubMidiasWidget(
                    theme: theme,
                    publicacao: item,
                    ajustarTelaCheia: true,
                    autoPlayVideo: ehAtiva,
                    midiaKey: ehAtiva ? midiasKey : null,
                    onDoubleTapLike: onDoubleTapLike,
                    pdfFullScreen: pdfFullScreen,
                    onAlternarPdfFullScreen: onAlternarPdfFullScreen,
                  ),
                );
              },
            )
          : DetalhesPubMidiasWidget(
              theme: theme,
              publicacao: pubAtiva,
              ajustarTelaCheia: true,
              midiaKey: midiasKey,
              onDoubleTapLike: onDoubleTapLike,
              pdfFullScreen: pdfFullScreen,
              onAlternarPdfFullScreen: onAlternarPdfFullScreen,
            ),
    );
  }
}
