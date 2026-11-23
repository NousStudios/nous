import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Editor visual de prévia para publicações com múltiplas fotos em carrossel:
/// permite inspecionar cada foto pela tira de miniaturas, arrastar em todas
/// as direções e ajustar o zoom (`1.0x` a `3.0x`).
class EditorFotosCarrosselWidget extends StatelessWidget {
  final AppTheme theme;
  final List<XFile> arquivos;
  final int indiceAtivo;
  final double? aspectRatio;
  final double alinhamentoX;
  final double alinhamentoY;
  final double escalaZoom;
  final ValueChanged<int> onSelecionarIndice;
  final ValueChanged<int> onRemoverIndice;
  final void Function(double x, double y, double zoom) onAtualizarAjuste;
  final VoidCallback onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  final ValueChanged<bool>? onInteracaoAtivaMudou;
  final VoidCallback onAdicionarMais;
  final VoidCallback onLimparTudo;

  const EditorFotosCarrosselWidget({
    super.key,
    required this.theme,
    required this.arquivos,
    required this.indiceAtivo,
    required this.aspectRatio,
    required this.alinhamentoX,
    required this.alinhamentoY,
    required this.escalaZoom,
    required this.onSelecionarIndice,
    required this.onRemoverIndice,
    required this.onAtualizarAjuste,
    required this.onScaleStart,
    required this.onScaleUpdate,
    this.onInteracaoAtivaMudou,
    required this.onAdicionarMais,
    required this.onLimparTudo,
  });

  @override
  Widget build(BuildContext context) {
    final totalFotos = arquivos.length;
    final idx = indiceAtivo.clamp(0, totalFotos - 1);
    final arquivoAtivo = arquivos[idx];

    final imgWidget = ClipRect(
      child: Transform.scale(
        scale: escalaZoom,
        alignment: Alignment.center,
        child: Image.file(
          File(arquivoAtivo.path),
          fit: aspectRatio != null ? BoxFit.cover : BoxFit.contain,
          alignment: Alignment(alinhamentoX, alinhamentoY),
          cacheWidth: 1080,
        ),
      ),
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 290),
            color: theme.backgroundColor.withValues(alpha: 0.5),
            child: Listener(
              onPointerDown: (_) => onInteracaoAtivaMudou?.call(true),
              onPointerUp: (_) => onInteracaoAtivaMudou?.call(false),
              onPointerCancel: (_) => onInteracaoAtivaMudou?.call(false),
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  GestureBinding.instance.pointerSignalResolver.register(
                    event,
                    (resolved) {
                      final scroll = resolved as PointerScrollEvent;
                      final delta = -scroll.scrollDelta.dy * 0.002;
                      final novoZoom = (escalaZoom + delta).clamp(1.0, 3.0);
                      if (novoZoom != escalaZoom) {
                        onAtualizarAjuste(alinhamentoX, alinhamentoY, novoZoom);
                      }
                    },
                  );
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) {
                  onInteracaoAtivaMudou?.call(true);
                  onScaleStart();
                },
                onScaleUpdate: onScaleUpdate,
                onScaleEnd: (_) => onInteracaoAtivaMudou?.call(false),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    aspectRatio != null
                        ? AspectRatio(aspectRatio: aspectRatio!, child: imgWidget)
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: imgWidget,
                          ),
                    if (escalaZoom > 1.05 ||
                        alinhamentoX.abs() > 0.05 ||
                        alinhamentoY.abs() > 0.05)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: InkWell(
                          onTap: () => onAtualizarAjuste(0.0, 0.0, 1.0),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.60),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Resetar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (totalFotos > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Foto ${idx + 1}/$totalFotos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (escalaZoom > 1.05 ||
            alinhamentoX.abs() > 0.02 ||
            alinhamentoY.abs() > 0.02)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onAtualizarAjuste(0.0, 0.0, 1.0),
              child: Text(
                'Centralizar enquadramento',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.buttonColor,
                ),
              ),
            ),
          ),
        if (totalFotos > 1) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalFotos,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selecionada = i == idx;
                return GestureDetector(
                  onTap: () => onSelecionarIndice(i),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selecionada
                                ? theme.buttonColor
                                : theme.borderColor.withValues(alpha: 0.5),
                            width: selecionada ? 2.2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          File(arquivos[i].path),
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => onRemoverIndice(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$totalFotos imagem(ns) no carrossel',
              style: theme.getTextStyle(
                fontSize: 11.5,
                color: theme.secondaryTextColor,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAdicionarMais,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                ),
                TextButton(
                  onPressed: onLimparTudo,
                  child: Text(
                    'Limpar',
                    style: theme.getTextStyle(color: theme.dangerColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
