import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/services/mapa_tile_cache_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Filtro visual de modo escuro compartilhado para tiles do OpenStreetMap.
TileBuilder? criarTileBuilderModoEscuroLoja(AppTheme theme) {
  if (theme.backgroundColor.computeLuminance() >= 0.5) return null;
  return (context, tileWidget, tile) => RepaintBoundary(
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            -0.25, -0.55, -0.10, 0, 245,
            -0.25, -0.55, -0.10, 0, 245,
            -0.25, -0.55, -0.10, 0, 245,
            0, 0, 0, 1, 0,
          ]),
          child: tileWidget,
        ),
      );
}

class MiniaturaLojaArrastavel extends StatelessWidget {
  final AppTheme theme;
  final String logoLoja;
  final String nomeLoja;
  final bool arrastando;
  final bool podeEditar;

  const MiniaturaLojaArrastavel({
    super.key,
    required this.theme,
    required this.logoLoja,
    required this.nomeLoja,
    required this.arrastando,
    required this.podeEditar,
  });

  @override
  Widget build(BuildContext context) {
    final caminhoLogo = ImagemService.resolverCaminhoExistente(logoLoja);
    return MouseRegion(
      cursor: podeEditar
          ? (arrastando ? SystemMouseCursors.grabbing : SystemMouseCursors.grab)
          : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: arrastando ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: arrastando ? theme.buttonColor : theme.textColor,
                  width: arrastando ? 2.5 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: arrastando ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: caminhoLogo != null
                  ? ClipOval(
                      child: Image.file(
                        File(caminhoLogo),
                        fit: BoxFit.cover,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        filterQuality: FilterQuality.low,
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      size: 20,
                      color: theme.textColor,
                    ),
            ),
            if (nomeLoja.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  nomeLoja.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BotaoPequenoMapaLoja extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final String tooltip;
  final VoidCallback onTap;

  const BotaoPequenoMapaLoja({
    super.key,
    required this.theme,
    required this.icone,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardBackgroundColor.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.8)),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icone, size: 17, color: theme.textColor),
          ),
        ),
      ),
    );
  }
}

class DialogMapaTelaCheiaLoja extends StatefulWidget {
  final AppTheme theme;
  final LatLng pontoInicial;
  final String logoLoja;
  final String nomeLoja;
  final bool podeEditar;

  const DialogMapaTelaCheiaLoja({
    super.key,
    required this.theme,
    required this.pontoInicial,
    required this.logoLoja,
    required this.nomeLoja,
    required this.podeEditar,
  });

  @override
  State<DialogMapaTelaCheiaLoja> createState() =>
      _DialogMapaTelaCheiaLojaState();
}

class _DialogMapaTelaCheiaLojaState extends State<DialogMapaTelaCheiaLoja> {
  final MapController _mapController = MapController();
  final NousCachedTileProvider _tileProvider = NousCachedTileProvider();
  final GlobalKey _mapaKey = GlobalKey();
  late LatLng _pontoAtual;
  bool _mapaPronto = false;
  bool _arrastandoMarcador = false;

  @override
  void initState() {
    super.initState();
    _pontoAtual = widget.pontoInicial;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _atualizarPontoPorPosicaoGlobal(Offset globalPosition) {
    if (!widget.podeEditar || !_mapaPronto) return;
    final box = _mapaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final ponto = _mapController.camera.offsetToCrs(local);
    setState(() => _pontoAtual = ponto);
  }

  Future<void> _centralizarMeuGps() async {
    final pos = await MapaGeoService.obterPosicaoAtual();
    if (!mounted || pos == null) return;
    setState(() => _pontoAtual = pos);
    if (_mapaPronto) {
      _mapController.move(pos, 17.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.96,
          maxHeight: size.height * 0.90,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.pin_drop_rounded, size: 20, color: theme.textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.podeEditar
                          ? 'Segure e arraste a loja para posicionar no mapa'
                          : 'Posição da loja no mapa',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.textColor),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                key: _mapaKey,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pontoAtual,
                      initialZoom: 16.8,
                      minZoom: 3.0,
                      maxZoom: 19.0,
                      interactionOptions: InteractionOptions(
                        flags: _arrastandoMarcador
                            ? InteractiveFlag.none
                            : InteractiveFlag.all,
                      ),
                      onMapReady: () => _mapaPronto = true,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.nous.app',
                        tileProvider: _tileProvider,
                        tileBuilder: criarTileBuilderModoEscuroLoja(theme),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pontoAtual,
                            width: 60,
                            height: 64,
                            alignment: Alignment.center,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: widget.podeEditar
                                  ? (_) => setState(
                                        () => _arrastandoMarcador = true,
                                      )
                                  : null,
                              onPanUpdate: widget.podeEditar
                                  ? (d) => _atualizarPontoPorPosicaoGlobal(
                                        d.globalPosition,
                                      )
                                  : null,
                              onPanEnd: widget.podeEditar
                                  ? (_) => setState(
                                        () => _arrastandoMarcador = false,
                                      )
                                  : null,
                              onPanCancel: widget.podeEditar
                                  ? () => setState(
                                        () => _arrastandoMarcador = false,
                                      )
                                  : null,
                              child: MiniaturaLojaArrastavel(
                                theme: theme,
                                logoLoja: widget.logoLoja,
                                nomeLoja: widget.nomeLoja,
                                arrastando: _arrastandoMarcador,
                                podeEditar: widget.podeEditar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BotaoPequenoMapaLoja(
                          theme: theme,
                          icone: Icons.remove_rounded,
                          tooltip: 'Afastar zoom',
                          onTap: () {
                            if (!_mapaPronto) return;
                            _mapController.move(
                              _mapController.camera.center,
                              (_mapController.camera.zoom - 1.0)
                                  .clamp(3.0, 19.0),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        BotaoPequenoMapaLoja(
                          theme: theme,
                          icone: Icons.add_rounded,
                          tooltip: 'Aproximar zoom',
                          onTap: () {
                            if (!_mapaPronto) return;
                            _mapController.move(
                              _mapController.camera.center,
                              (_mapController.camera.zoom + 1.0)
                                  .clamp(3.0, 19.0),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.podeEditar)
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: BotaoPequenoMapaLoja(
                        theme: theme,
                        icone: Icons.my_location_rounded,
                        tooltip: 'Usar minha localização atual',
                        onTap: _centralizarMeuGps,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.podeEditar)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(_pontoAtual),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirmar Posição'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
