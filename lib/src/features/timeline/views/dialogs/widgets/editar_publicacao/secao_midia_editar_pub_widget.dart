import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Seção de pré-visualização, ajuste de zoom/enquadramento e seleção de formato
/// visual das mídias de imagem no diálogo de edição de publicação.
class SecaoMidiaEditarPubWidget extends StatefulWidget {
  final AppTheme theme;
  final List<MidiaPublicacao> midias;
  final List<int> fotosIdx;
  final int indiceFotoAtiva;
  final PadraoExibicaoMidia padrao;
  final double? proporcaoCustom;
  final ValueChanged<int> onSelecionarFoto;
  final ValueChanged<PadraoExibicaoMidia> onAlterarPadrao;
  final void Function({
    required double x,
    required double y,
    required double zoom,
  }) onAtualizarMidiaAtiva;
  final ValueChanged<bool> onInteracaoFotoChanged;

  const SecaoMidiaEditarPubWidget({
    super.key,
    required this.theme,
    required this.midias,
    required this.fotosIdx,
    required this.indiceFotoAtiva,
    required this.padrao,
    required this.proporcaoCustom,
    required this.onSelecionarFoto,
    required this.onAlterarPadrao,
    required this.onAtualizarMidiaAtiva,
    required this.onInteracaoFotoChanged,
  });

  @override
  State<SecaoMidiaEditarPubWidget> createState() =>
      _SecaoMidiaEditarPubWidgetState();
}

class _SecaoMidiaEditarPubWidgetState extends State<SecaoMidiaEditarPubWidget> {
  double _zoomInicioGesto = 1.0;

  double? _aspectRatioParaPadrao(PadraoExibicaoMidia padrao) {
    switch (padrao) {
      case PadraoExibicaoMidia.original:
        return widget.proporcaoCustom;
      case PadraoExibicaoMidia.quadrado1x1:
        return 1.0;
      case PadraoExibicaoMidia.retrato4x5:
        return 4 / 5;
      case PadraoExibicaoMidia.paisagem16x9:
        return 16 / 9;
      case PadraoExibicaoMidia.vertical9x16:
        return 9 / 16;
      case PadraoExibicaoMidia.mosaico:
      case PadraoExibicaoMidia.personalizado:
        return widget.proporcaoCustom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final fotosIdx = widget.fotosIdx;
    final midiaAtiva = widget.midias[widget.indiceFotoAtiva];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fotosIdx.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (int k = 0; k < fotosIdx.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => widget.onSelecionarFoto(fotosIdx[k]),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.indiceFotoAtiva == fotosIdx[k]
                              ? theme.buttonColor
                              : theme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${k + 1}',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: widget.indiceFotoAtiva == fotosIdx[k]
                                ? theme.buttonTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        _buildEditorFotoAtiva(theme, midiaAtiva),
        const SizedBox(height: 12),
        _buildSeletorFormatoVisual(theme),
      ],
    );
  }

  Widget _buildSeletorFormatoVisual(AppTheme theme) {
    final opcoes = <(PadraoExibicaoMidia, IconData, String)>[
      (PadraoExibicaoMidia.original, Icons.crop_free_rounded, 'Original'),
      (PadraoExibicaoMidia.quadrado1x1, Icons.crop_square_rounded, '1:1'),
      (PadraoExibicaoMidia.retrato4x5, Icons.crop_portrait_rounded, '4:5'),
      (PadraoExibicaoMidia.paisagem16x9, Icons.crop_16_9_rounded, '16:9'),
      (PadraoExibicaoMidia.vertical9x16, Icons.smartphone_rounded, '9:16'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enquadramento',
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opcoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (padrao, icone, rotulo) = opcoes[i];
              final ativo = widget.padrao == padrao;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onAlterarPadrao(padrao),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: ativo
                        ? theme.buttonColor
                        : theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ativo
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.5),
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icone,
                        size: 18,
                        color: ativo ? theme.buttonTextColor : theme.textColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rotulo,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              ativo ? FontWeight.bold : FontWeight.normal,
                          color:
                              ativo ? theme.buttonTextColor : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditorFotoAtiva(AppTheme theme, MidiaPublicacao midia) {
    final caminhoResolvido =
        ImagemService.resolverCaminhoExistente(midia.caminhoRelativo);
    if (caminhoResolvido == null || !File(caminhoResolvido).existsSync()) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    final align = Alignment(midia.alinhamentoX, midia.alinhamentoY);
    final zoom = midia.escalaZoom.clamp(1.0, 3.0);
    final aspectRatio = _aspectRatioParaPadrao(widget.padrao);

    final imgWidget = ClipRect(
      child: Transform.scale(
        scale: zoom,
        alignment: Alignment.center,
        child: Image.file(
          File(caminhoResolvido),
          fit: aspectRatio != null ? BoxFit.cover : BoxFit.contain,
          alignment: align,
          cacheWidth: 900,
        ),
      ),
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            width: double.infinity,
            color: theme.backgroundColor.withValues(alpha: 0.5),
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final delta = -event.scrollDelta.dy * 0.002;
                  widget.onAtualizarMidiaAtiva(
                    x: midia.alinhamentoX,
                    y: midia.alinhamentoY,
                    zoom: zoom + delta,
                  );
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) {
                  widget.onInteracaoFotoChanged(true);
                  _zoomInicioGesto = zoom;
                },
                onScaleUpdate: (details) {
                  final novoZoom =
                      (_zoomInicioGesto * details.scale).clamp(1.0, 3.0);
                  final divisor = 130.0 * novoZoom;
                  final dx = details.focalPointDelta.dx / divisor;
                  final dy = details.focalPointDelta.dy / divisor;
                  widget.onAtualizarMidiaAtiva(
                    x: midia.alinhamentoX - dx,
                    y: midia.alinhamentoY - dy,
                    zoom: novoZoom,
                  );
                },
                onScaleEnd: (_) => widget.onInteracaoFotoChanged(false),
                child: Center(
                  child: aspectRatio != null
                      ? AspectRatio(aspectRatio: aspectRatio, child: imgWidget)
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 270),
                          child: imgWidget,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (zoom > 1.05 ||
            midia.alinhamentoX.abs() > 0.02 ||
            midia.alinhamentoY.abs() > 0.02)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  widget.onAtualizarMidiaAtiva(x: 0.0, y: 0.0, zoom: 1.0),
              child: Text(
                'Centralizar',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.buttonColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
