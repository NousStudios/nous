import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/services/mapa_tile_cache_service.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/dialog_mapa_tela_cheia_loja.dart';

/// Seletor retangular de mapa que exibe a miniatura real da loja e permite
/// segurar e arrastar a miniatura para posicionar a loja no mapa.
class SeletorLocalizacaoMapaLojaWidget extends StatefulWidget {
  final AppTheme theme;
  final double? latitude;
  final double? longitude;
  final String logoLoja;
  final String nomeLoja;
  final String enderecoConsulta;
  final String? cidadeFallback;
  final bool podeEditar;
  final void Function(double latitude, double longitude) onCoordenadaAlterada;

  const SeletorLocalizacaoMapaLojaWidget({
    super.key,
    required this.theme,
    required this.latitude,
    required this.longitude,
    this.logoLoja = '',
    this.nomeLoja = '',
    this.enderecoConsulta = '',
    this.cidadeFallback,
    this.podeEditar = true,
    required this.onCoordenadaAlterada,
  });

  @override
  State<SeletorLocalizacaoMapaLojaWidget> createState() =>
      _SeletorLocalizacaoMapaLojaWidgetState();
}

class _SeletorLocalizacaoMapaLojaWidgetState
    extends State<SeletorLocalizacaoMapaLojaWidget> {
  final MapController _mapController = MapController();
  final NousCachedTileProvider _tileProvider = NousCachedTileProvider();
  final GlobalKey _mapaKey = GlobalKey();
  LatLng? _pontoSelecionado;
  LatLng _centroInicial = MapaGeoService.coordenadaPadraoBrasil;
  bool _carregandoCentro = false;
  bool _mapaPronto = false;
  bool _arrastandoMarcador = false;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _pontoSelecionado = LatLng(widget.latitude!, widget.longitude!);
      _centroInicial = _pontoSelecionado!;
    } else {
      unawaited(_resolverPosicaoAtualLoja());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SeletorLocalizacaoMapaLojaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      if (widget.latitude != null && widget.longitude != null) {
        final novo = LatLng(widget.latitude!, widget.longitude!);
        _pontoSelecionado = novo;
        _centroInicial = novo;
        if (_mapaPronto && !_arrastandoMarcador) {
          _mapController.move(novo, _mapController.camera.zoom);
        }
      }
    }
  }

  Future<void> _resolverPosicaoAtualLoja() async {
    if (_carregandoCentro) return;
    setState(() => _carregandoCentro = true);
    LatLng? encontrado;
    if (widget.enderecoConsulta.trim().isNotEmpty) {
      encontrado = await MapaGeoService.geocodificarEndereco(
        widget.enderecoConsulta,
        cidadeFallback: widget.cidadeFallback,
      );
    }
    encontrado ??= await MapaGeoService.obterPosicaoAtual();
    if (!mounted) return;
    setState(() {
      _carregandoCentro = false;
      if (encontrado != null && _pontoSelecionado == null) {
        _pontoSelecionado = encontrado;
        _centroInicial = encontrado;
        if (_mapaPronto) {
          _mapController.move(encontrado, 16.5);
        }
      }
    });
  }

  void _atualizarPontoPorPosicaoGlobal(Offset globalPosition) {
    if (!widget.podeEditar || !_mapaPronto) return;
    final box = _mapaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final ponto = _mapController.camera.offsetToCrs(local);
    setState(() {
      _pontoSelecionado = ponto;
      _centroInicial = ponto;
    });
  }

  void _finalizarArraste() {
    if (!widget.podeEditar) return;
    setState(() => _arrastandoMarcador = false);
    final ponto = _pontoSelecionado;
    if (ponto != null) {
      widget.onCoordenadaAlterada(ponto.latitude, ponto.longitude);
    }
  }

  void _alterarZoom(double delta) {
    if (!_mapaPronto) return;
    final novoZoom = (_mapController.camera.zoom + delta).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, novoZoom);
  }

  Future<void> _abrirTelaCheia() async {
    final resultado = await showDialog<LatLng>(
      context: context,
      builder: (_) => DialogMapaTelaCheiaLoja(
        theme: widget.theme,
        pontoInicial: _pontoSelecionado ?? _centroInicial,
        logoLoja: widget.logoLoja,
        nomeLoja: widget.nomeLoja,
        podeEditar: widget.podeEditar,
      ),
    );
    if (resultado != null && widget.podeEditar && mounted) {
      setState(() {
        _pontoSelecionado = resultado;
        _centroInicial = resultado;
      });
      widget.onCoordenadaAlterada(resultado.latitude, resultado.longitude);
      if (_mapaPronto) {
        _mapController.move(resultado, 17.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pontoExibido = _pontoSelecionado ?? _centroInicial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.pin_drop_outlined,
              size: 15,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Localização da loja no mapa',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            if (_pontoSelecionado != null)
              Text(
                '${_pontoSelecionado!.latitude.toStringAsFixed(5)}, '
                '${_pontoSelecionado!.longitude.toStringAsFixed(5)}',
                style: theme.getTextStyle(
                  fontSize: 10.5,
                  color: theme.secondaryTextColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          key: _mapaKey,
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.85),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: pontoExibido,
                  initialZoom: _pontoSelecionado != null ? 16.5 : 15.0,
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
                        point: pontoExibido,
                        width: 58,
                        height: 62,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: widget.podeEditar
                              ? (_) =>
                                  setState(() => _arrastandoMarcador = true)
                              : null,
                          onPanUpdate: widget.podeEditar
                              ? (d) =>
                                  _atualizarPontoPorPosicaoGlobal(d.globalPosition)
                              : null,
                          onPanEnd:
                              widget.podeEditar ? (_) => _finalizarArraste() : null,
                          onPanCancel:
                              widget.podeEditar ? _finalizarArraste : null,
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
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    widget.podeEditar
                        ? (_carregandoCentro
                            ? 'Buscando posição atual...'
                            : 'Segure e arraste a loja para posicionar')
                        : 'Sem permissão para editar posição',
                    style: theme.getTextStyle(
                      fontSize: 10.5,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: BotaoPequenoMapaLoja(
                  theme: theme,
                  icone: Icons.fullscreen_rounded,
                  tooltip: 'Abrir mapa em tela cheia',
                  onTap: _abrirTelaCheia,
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotaoPequenoMapaLoja(
                      theme: theme,
                      icone: Icons.remove_rounded,
                      tooltip: 'Afastar zoom',
                      onTap: () => _alterarZoom(-1.0),
                    ),
                    const SizedBox(width: 6),
                    BotaoPequenoMapaLoja(
                      theme: theme,
                      icone: Icons.add_rounded,
                      tooltip: 'Aproximar zoom',
                      onTap: () => _alterarZoom(1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
