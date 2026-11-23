import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Carrossel horizontal de fotos para publicações com:
/// - Suporte a enquadramento (X, Y) e zoom individual por foto;
/// - Duplo toque na imagem para curtir com animação visual central;
/// - Cache síncrono instantâneo sem piscar em rebuilds.
class CarrosselFotosPublicacao extends StatefulWidget {
  final AppTheme theme;
  final List<MidiaPublicacao> midias;
  final double? aspectRatio;
  final Alignment alignment;
  final double escalaZoomPadrao;
  final VoidCallback? onDoubleTapLike;
  final VoidCallback? onTapFoto;
  final bool ajustarTelaCheia;

  const CarrosselFotosPublicacao({
    super.key,
    required this.theme,
    required this.midias,
    this.aspectRatio,
    this.alignment = Alignment.center,
    this.escalaZoomPadrao = 1.0,
    this.onDoubleTapLike,
    this.onTapFoto,
    this.ajustarTelaCheia = false,
  });

  @override
  State<CarrosselFotosPublicacao> createState() =>
      _CarrosselFotosPublicacaoState();
}

class _CarrosselFotosPublicacaoState extends State<CarrosselFotosPublicacao>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late final AnimationController _coracaoCtrl;
  int _indiceAtual = 0;

  @override
  void initState() {
    super.initState();
    _coracaoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(covariant CarrosselFotosPublicacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.midias.length != widget.midias.length ||
        (widget.midias.isNotEmpty &&
            oldWidget.midias.isNotEmpty &&
            oldWidget.midias.first.caminhoRelativo !=
                widget.midias.first.caminhoRelativo)) {
      _indiceAtual = 0;
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _coracaoCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _dispararDoubleTapLike() {
    if (widget.onDoubleTapLike != null) {
      widget.onDoubleTapLike!();
    }
    _coracaoCtrl.forward(from: 0.0);
  }

  Widget _renderizarArquivo(String path, MidiaPublicacao midia) {
    final alignEfetivo =
        (midia.alinhamentoX != 0.0 || midia.alinhamentoY != 0.0)
            ? Alignment(midia.alinhamentoX, midia.alinhamentoY)
            : widget.alignment;
    final zoomEfetivo = midia.escalaZoom > 1.01
        ? midia.escalaZoom
        : widget.escalaZoomPadrao;

    final img = Transform.scale(
      scale: zoomEfetivo.clamp(1.0, 3.5),
      alignment: alignEfetivo,
      child: Image.file(
        File(path),
        fit: (!widget.ajustarTelaCheia && widget.aspectRatio != null)
            ? BoxFit.cover
            : BoxFit.contain,
        alignment: alignEfetivo,
        cacheWidth: 1080,
      ),
    );

    if (!widget.ajustarTelaCheia && widget.aspectRatio != null) {
      return ClipRect(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio!,
          child: img,
        ),
      );
    }
    return ClipRect(child: img);
  }

  Widget _buildFoto(MidiaPublicacao midia) {
    final syncPath =
        TimelineService.resolverCaminhoMidiaSync(midia.caminhoRelativo);
    if (syncPath != null) {
      return _renderizarArquivo(syncPath, midia);
    }

    return FutureBuilder<String?>(
      future: TimelineService.resolverCaminhoMidia(midia.caminhoRelativo),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null) {
          if (snap.connectionState == ConnectionState.done) {
            return Container(
              height: 200,
              color: widget.theme.cardBackgroundColor.withValues(alpha: 0.4),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 36,
                  color: widget.theme.secondaryTextColor,
                ),
              ),
            );
          }
          return Container(
            height: 240,
            color: widget.theme.cardBackgroundColor.withValues(alpha: 0.4),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.buttonColor,
              ),
            ),
          );
        }
        return _renderizarArquivo(path, midia);
      },
    );
  }

  Widget _envolverComDoubleTap(Widget child) {
    return GestureDetector(
      onTap: widget.onTapFoto,
      onDoubleTap: _dispararDoubleTapLike,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _coracaoCtrl,
              builder: (_, _) {
                final v = _coracaoCtrl.value;
                if (v == 0.0 || v == 1.0) return const SizedBox.shrink();
                final opacidade = v < 0.5 ? (v * 2.0) : ((1.0 - v) * 2.0);
                final escala = v < 0.35
                    ? (0.4 + (v / 0.35) * 0.85)
                    : (1.25 - ((v - 0.35) / 0.65) * 0.25);
                return Opacity(
                  opacity: opacidade.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: escala,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Icon(
                        Icons.thumb_up_alt_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.midias.isEmpty) return const SizedBox.shrink();
    if (widget.midias.length == 1) {
      return _envolverComDoubleTap(_buildFoto(widget.midias.first));
    }

    final total = widget.midias.length;
    final ratioEfetivo = widget.aspectRatio ?? 1.0;

    final pageViewStack = Stack(
      alignment: Alignment.center,
      children: [
        if (widget.ajustarTelaCheia)
          PageView.builder(
            controller: _pageCtrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _indiceAtual = i),
            itemBuilder: (_, i) => _buildFoto(widget.midias[i]),
          )
        else
          AspectRatio(
            aspectRatio: ratioEfetivo,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: total,
              onPageChanged: (i) => setState(() => _indiceAtual = i),
              itemBuilder: (_, i) => _buildFoto(widget.midias[i]),
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_indiceAtual + 1}/$total',
              style: widget.theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );

    return _envolverComDoubleTap(
      LayoutBuilder(
        builder: (context, constraints) {
          final usarFlexible =
              !widget.ajustarTelaCheia && constraints.hasBoundedHeight;
          return Column(
            mainAxisSize:
                (widget.ajustarTelaCheia || usarFlexible)
                    ? MainAxisSize.max
                    : MainAxisSize.min,
            children: [
              if (widget.ajustarTelaCheia)
                Expanded(child: pageViewStack)
              else if (usarFlexible)
                Flexible(child: pageViewStack)
              else
                pageViewStack,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final ativo = i == _indiceAtual;
                  return Container(
                    width: ativo ? 8 : 6,
                    height: ativo ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ativo
                          ? widget.theme.textColor
                          : widget.theme.secondaryTextColor
                              .withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
