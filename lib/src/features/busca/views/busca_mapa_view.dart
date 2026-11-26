import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/services/mapa_tile_cache_service.dart';
import 'package:nous/src/features/busca/views/detalhes_produto_mercado_view.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_adicionar_carrinho_variantes.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_criar_projeto_mapa.dart';
import 'package:nous/src/features/busca/views/widgets/barra_busca_universal_mapa.dart';
import 'package:nous/src/features/busca/views/widgets/catalogo_produtos/grade_produtos_mercado_widget.dart';
import 'package:nous/src/features/busca/views/widgets/card_resumo_entidade_mapa.dart';
import 'package:nous/src/features/busca/views/widgets/card_resumo_rota_mapa.dart';
import 'package:nous/src/features/busca/views/widgets/hud_navegacao_ativa.dart';
import 'package:nous/src/features/busca/views/widgets/lista_resultados_busca_mapa.dart';
import 'package:nous/src/features/busca/views/widgets/marcadores_mapa_widget.dart';
import 'package:nous/src/features/busca/views/widgets/painel_rotas_mapa.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Tela de Busca Universal & Mapa Interativo do Nous.
class BuscaMapaView extends StatefulWidget {
  static bool telaAberta = false;
  final Loja? lojaDestinoInicial;

  const BuscaMapaView({super.key, this.lojaDestinoInicial});

  @override
  State<BuscaMapaView> createState() => _BuscaMapaViewState();
}

class _BuscaMapaViewState extends State<BuscaMapaView>
    with TickerProviderStateMixin {
  final BuscaMapaController _controller = BuscaMapaController();
  final TextEditingController _buscaTextController = TextEditingController();
  final ValueNotifier<bool> _navegandoAoVivoNotifier = ValueNotifier<bool>(false);
  final NousCachedTileProvider _tileProvider = NousCachedTileProvider();
  Timer? _debounceRede;
  StreamSubscription<Position>? _subGps;
  AnimationController? _cameraAnimController;
  late final AnimationController _rotaAnimController;
  PdvProvider? _pdvProviderRef;

  @override
  void initState() {
    super.initState();
    BuscaMapaView.telaAberta = true;
    _rotaAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _controller.onAnimarCamera = _animarCameraPara;
    _controller.onRotaCalculada = () {
      if (mounted) {
        _rotaAnimController.forward(from: 0.0);
      }
    };
    _controller.addListener(_aoMudarController);
    MapaEspelhamentoService.instancia.addListener(_aoMudarEspelhamento);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pdvProviderRef = context.read<PdvProvider>();
      _pdvProviderRef?.addListener(_aoMudarRede);
      _controller.inicializar(
        _pdvProviderRef!,
        lojaDestinoInicial: widget.lojaDestinoInicial,
        cpfUsuario: context.read<AuthProvider>().cpf,
      );
    });
    ClienteRedeLocal().presencasAtivas.addListener(_aoMudarRede);
    ClienteRedeLocal().estaConectado.addListener(_aoMudarRede);
    TimelineService.alteracoesTimelineNotifier.addListener(_aoMudarRede);
  }

  void _aoMudarEspelhamento() {
    if (!mounted) return;
    final esp = MapaEspelhamentoService.instancia;
    final estado = esp.estadoRemoto;
    if (estado != null) {
      _controller.aplicarEstadoEspelhado(estado);
      if (estado.ativo) return;
      esp.limparEstadoRemoto();
    }
    final posGpsRede = esp.ultimaPosicaoGpsRede;
    if (posGpsRede != null) {
      final mudou = _controller.posicaoUsuario == null ||
          MapaGeoService.distanciaMetros(_controller.posicaoUsuario!, posGpsRede) > 20;
      if (mudou) {
        _controller.posicaoUsuario = posGpsRede;
        _controller.origemRota = posGpsRede;
        _controller.origemRotaLabel = 'Seu local';
        if (esp.resumoGpsRede.isNotEmpty) {
          _controller.enderecoUsuarioResumo = esp.resumoGpsRede;
        }
        if (_controller.modoRota &&
            _controller.destinoRota != null &&
            _controller.rotaAtual == null) {
          _controller.tracarRotaPara(
            destino: _controller.destinoRota!,
            destinoLabel: _controller.destinoRotaLabel,
          );
        } else {
          _controller.atualizarPosicaoTempoReal(posGpsRede);
        }
      }
    }
  }

  void _aoMudarController() {
    if (!mounted) return;
    if (_navegandoAoVivoNotifier.value != _controller.navegandoAoVivo) {
      _navegandoAoVivoNotifier.value = _controller.navegandoAoVivo;
    }
    if (_controller.navegandoAoVivo && _subGps == null) {
      try {
        _subGps = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        ).listen((pos) {
          if (mounted) {
            _controller.atualizarPosicaoTempoReal(
              LatLng(pos.latitude, pos.longitude),
              headingGraus: pos.heading >= 0 ? pos.heading : null,
            );
          }
        });
      } catch (_) {}
    } else if (!_controller.navegandoAoVivo && _subGps != null) {
      _subGps?.cancel();
      _subGps = null;
    }
  }

  void _animarCameraPara(
    LatLng destino,
    double zoomAlvo, {
    double? rotacaoGraus,
  }) {
    if (!mounted) return;
    _cameraAnimController?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _cameraAnimController = ctrl;

    late final LatLng inicio;
    late final double zoomInicio;
    late final double rotInicio;
    try {
      inicio = _controller.mapController.camera.center;
      zoomInicio = _controller.mapController.camera.zoom;
      rotInicio = _controller.mapController.camera.rotation;
    } catch (_) {
      return;
    }

    final rotAlvo = rotacaoGraus ?? rotInicio;
    final diffRot = ((rotAlvo - rotInicio + 540) % 360) - 180;

    final latTween = Tween<double>(
      begin: inicio.latitude,
      end: destino.latitude,
    );
    final lngTween = Tween<double>(
      begin: inicio.longitude,
      end: destino.longitude,
    );
    final zoomTween = Tween<double>(begin: zoomInicio, end: zoomAlvo);
    final rotTween = Tween<double>(begin: rotInicio, end: rotInicio + diffRot);
    final curva = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);

    ctrl.addListener(() {
      if (!mounted) return;
      try {
        _controller.mapController.moveAndRotate(
          LatLng(latTween.evaluate(curva), lngTween.evaluate(curva)),
          zoomTween.evaluate(curva),
          rotTween.evaluate(curva),
        );
      } catch (_) {}
    });
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_cameraAnimController == ctrl) {
          _cameraAnimController = null;
        }
        ctrl.dispose();
      }
    });
    ctrl.forward();
  }

  void _aoMudarRede() {
    if (!mounted) return;
    _debounceRede?.cancel();
    _debounceRede = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.recarregarDados(context.read<PdvProvider>());
      }
    });
  }

  @override
  void dispose() {
    BuscaMapaView.telaAberta = false;
    _debounceRede?.cancel();
    _subGps?.cancel();
    _cameraAnimController?.dispose();
    _rotaAnimController.dispose();
    _navegandoAoVivoNotifier.dispose();
    _controller.removeListener(_aoMudarController);
    MapaEspelhamentoService.instancia.removeListener(_aoMudarEspelhamento);
    _pdvProviderRef?.removeListener(_aoMudarRede);
    ClienteRedeLocal().presencasAtivas.removeListener(_aoMudarRede);
    ClienteRedeLocal().estaConectado.removeListener(_aoMudarRede);
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoMudarRede);
    _buscaTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _abrirCriarProjetoNoPonto(
    LatLng ponto,
    AppTheme theme,
  ) async {
    final auth = context.read<AuthProvider>();
    final cpf = auth.cpf;
    final nome = auth.contaAtual?.nomeExibicao.isNotEmpty == true
        ? auth.contaAtual!.nomeExibicao
        : (auth.contaAtual?.nome ?? 'Cidadão Nous');
    final resumo = await MapaGeoService.obterEnderecoResumo(ponto);
    if (!mounted) return;
    final criado = await DialogCriarProjetoMapa.mostrar(
      context,
      theme: theme,
      coordenada: ponto,
      enderecoResumo: resumo,
      criadorCpf: cpf,
      criadorNome: nome,
    );
    if (criado != null && mounted) {
      await _controller.criarProjeto(criado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final modoEscuro =
            theme.backgroundColor.computeLuminance() < 0.35;

        final mapaWidget = RepaintBoundary(
          child: FlutterMap(
            mapController: _controller.mapController,
            options: MapOptions(
              backgroundColor: modoEscuro
                  ? const Color(0xFF1F1F1F)
                  : const Color(0xFFEAE6DF),
              initialCenter: _controller.centroReferencia,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 20.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _controller.navegandoAoVivo) {
                  _controller.pausarSeguirCamera();
                }
              },
              onTap: (_, ponto) async {
                if (_controller.painelBuscaExpandido) {
                  _controller.definirPainelBusca(false);
                  FocusManager.instance.primaryFocus?.unfocus();
                  return;
                }
                if (_controller.modoRota) {
                  final nomePonto =
                      await MapaGeoService.obterEnderecoResumo(ponto);
                  if (mounted) {
                    await _controller.tracarRotaPara(
                      destino: ponto,
                      destinoLabel: nomePonto,
                    );
                  }
                  return;
                }
                await _controller.selecionarPontoMapa(ponto);
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.nous.app',
                tileProvider: _tileProvider,
                maxZoom: 20,
                maxNativeZoom: 18,
                keepBuffer: 2,
                panBuffer: 1,
                tileDisplay: const TileDisplay.instantaneous(),
                evictErrorTileStrategy:
                    EvictErrorTileStrategy.notVisibleRespectMargin,
                tileBuilder: modoEscuro
                    ? (context, tileWidget, tile) => RepaintBoundary(
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              -0.25, -0.55, -0.10, 0, 245,
                              -0.25, -0.55, -0.10, 0, 245,
                              -0.25, -0.55, -0.10, 0, 245,
                              0, 0, 0, 1, 0,
                            ]),
                            child: tileWidget,
                          ),
                        )
                    : null,
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      if (_controller.rotaAtual != null)
                        AnimatedBuilder(
                          animation: _rotaAnimController,
                          builder: (context, _) {
                            final pontos = _controller.rotaAtual!.pontos;
                            final t = Curves.easeOutCubic
                                .transform(_rotaAnimController.value);
                            final qtd = (pontos.length * t)
                                .ceil()
                                .clamp(2, pontos.length);
                            final subPontos = pontos.take(qtd).toList();
                            return PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: subPontos,
                                  color: const Color(0xFF1A56DB),
                                  strokeWidth: 8.0,
                                ),
                                Polyline(
                                  points: subPontos,
                                  color: const Color(0xFF4285F4),
                                  strokeWidth: 5.0,
                                ),
                              ],
                            );
                          },
                        ),
                      MarkerLayer(
                        markers: MarcadoresMapaWidget.construir(
                          controller: _controller,
                          theme: theme,
                          usuarioLogado:
                              context.read<AuthProvider>().contaAtual,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Busca e Mapa',
            showBackButton: false,
          ),
          body: Stack(
            children: [
              // 1. Mapa Interativo isolado de rebuilds de texto/cards (fluidez)
              Positioned.fill(
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _navegandoAoVivoNotifier,
                        builder: (context, aoVivo, child) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: aoVivo ? 1.0 : 0.0,
                            ),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, innerChild) {
                              if (t <= 0.001) return innerChild!;
                              final largura =
                                  constraints.maxWidth * (1.0 + 0.35 * t);
                              final altura =
                                  constraints.maxHeight * (1.0 + 0.48 * t);
                              final matriz = Matrix4.identity()
                                ..setEntry(3, 2, 0.0018)
                                ..rotateX(-0.52 * t);
                              return OverflowBox(
                                minWidth: largura,
                                maxWidth: largura,
                                minHeight: altura,
                                maxHeight: altura,
                                alignment: Alignment.center,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: matriz,
                                  child: SizedBox(
                                    width: largura,
                                    height: altura,
                                    child: innerChild,
                                  ),
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        child: mapaWidget,
                      );
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final temCardEntidade = _controller.lojaSelecionada != null ||
                        _controller.perfilSelecionado != null ||
                        _controller.projetoSelecionado != null ||
                        _controller.pontoMapaSelecionado != null;
                    final temCardRotaInferior = _controller.modoRota &&
                        _controller.rotaAtual != null &&
                        !_controller.navegandoAoVivo;

                    return Stack(
                      children: [

                  // 2. Topo: HUD de Navegação Ativa OU Catálogo Comercial (Produtos/Serviços) OU Painel de Rotas / Barra Universal
                  if (_controller.navegandoAoVivo)
                    Positioned.fill(
                      child: HudNavegacaoAtiva(
                        controller: _controller,
                        theme: theme,
                      ),
                    )
                  else if (_controller.exibirCatalogoComercial)
                    Positioned.fill(
                      child: Container(
                        color: theme.backgroundColor,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                              child: BarraBuscaUniversalMapa(
                                controller: _controller,
                                textController: _buscaTextController,
                                theme: theme,
                              ),
                            ),
                            Expanded(
                              child: GradeProdutosMercadoWidget(
                                controller: _controller,
                                theme: theme,
                                onAbrirDetalhes: (produto) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetalhesProdutoMercadoView(
                                        produto: produto,
                                      ),
                                    ),
                                  );
                                },
                                onAdicionarAoCarrinho: (produto, _) {
                                  final pdv = context.read<PdvProvider>();
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) =>
                                        DialogAdicionarCarrinhoVariantes(
                                      produto: produto,
                                      theme: theme,
                                      pdv: pdv,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_controller.modoRota)
                            PainelRotasMapa(
                              controller: _controller,
                              theme: theme,
                            )
                          else
                            BarraBuscaUniversalMapa(
                              controller: _controller,
                              textController: _buscaTextController,
                              theme: theme,
                            ),
                          if (_controller.painelBuscaExpandido &&
                              !_controller.modoRota) ...[
                            const SizedBox(height: 8),
                            ListaResultadosBuscaMapa(
                              controller: _controller,
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ),

                  // 3. Botões de Zoom Horizontais à Esquerda
                  if (!_controller.painelBuscaExpandido &&
                      !_controller.exibirCatalogoComercial &&
                      !_controller.navegandoAoVivo)
                    Positioned(
                      left: 14,
                      bottom: temCardRotaInferior
                          ? 186
                          : (temCardEntidade ? 190 : 94),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _botaoFlutuanteMapa(
                            theme: theme,
                            icone: Icons.remove_rounded,
                            tooltip: 'Afastar zoom',
                            tamanho: 36,
                            tamanhoIcone: 18,
                            onTap: () => _controller.alterarZoom(-1.2),
                          ),
                          const SizedBox(width: 8),
                          _botaoFlutuanteMapa(
                            theme: theme,
                            icone: Icons.add_rounded,
                            tooltip: 'Aproximar zoom',
                            tamanho: 36,
                            tamanhoIcone: 18,
                            onTap: () => _controller.alterarZoom(1.2),
                          ),
                        ],
                      ),
                    ),

                  // 4. Botões Flutuantes Direitos: Rota (cima) e Centralizar (baixo)
                  if (!_controller.painelBuscaExpandido &&
                      !_controller.exibirCatalogoComercial &&
                      !_controller.navegandoAoVivo)
                    Positioned(
                      right: 14,
                      bottom: temCardRotaInferior
                          ? 186
                          : (temCardEntidade ? 190 : 94),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _botaoFlutuanteMapa(
                            theme: theme,
                            icone: Icons.alt_route_rounded,
                            tooltip: 'Rotas e Motoristas',
                            ativo: _controller.modoRota,
                            onTap: () {
                              if (_controller.modoRota) {
                                _controller.fecharModoRota();
                              } else {
                                _controller.abrirModoRota();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _botaoFlutuanteMapa(
                            theme: theme,
                            icone: Icons.my_location_rounded,
                            tooltip: 'Centralizar na minha localização',
                            onTap: _controller.centralizarNoUsuario,
                          ),
                        ],
                      ),
                    ),

                  // 4. Card Flutuante Inferior: Resumo da Rota (Iniciar) OU Entidade Selecionada
                  if (temCardRotaInferior && !_controller.painelBuscaExpandido)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 84,
                      child: CardResumoRotaMapa(
                        controller: _controller,
                        theme: theme,
                      ),
                    )
                  else if (temCardEntidade &&
                      !_controller.painelBuscaExpandido &&
                      !_controller.navegandoAoVivo)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 84,
                      child: CardResumoEntidadeMapa(
                        controller: _controller,
                        theme: theme,
                        onCriarProjetoNoPonto: () {
                          final ponto = _controller.pontoMapaSelecionado;
                          if (ponto != null) {
                            _abrirCriarProjetoNoPonto(ponto, theme);
                          }
                        },
                      ),
                    ),

                  // 5. Barra de Navegação Inferior Flutuante (oculta durante navegação ativa)
                  if (!_controller.navegandoAoVivo)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: FloatingBottomNavBar(
                          maxWidth: MediaQuery.sizeOf(context).width,
                          slotSelecionado: 2,
                          subIndiceSelecionado: 0,
                        ),
                      ),
                    ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botaoFlutuanteMapa({
    required AppTheme theme,
    required IconData icone,
    required String tooltip,
    required VoidCallback onTap,
    bool ativo = false,
    double tamanho = 46,
    double tamanhoIcone = 22,
  }) {
    return Material(
      color: ativo
          ? theme.buttonColor
          : theme.cardBackgroundColor.withValues(alpha: 0.94),
      shape: CircleBorder(
        side: BorderSide(
          color: ativo
              ? theme.buttonColor
              : theme.borderColor.withValues(alpha: 0.85),
          width: 1.2,
        ),
      ),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: tamanho,
            height: tamanho,
            child: Icon(
              icone,
              size: tamanhoIcone,
              color: ativo ? theme.buttonTextColor : theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
