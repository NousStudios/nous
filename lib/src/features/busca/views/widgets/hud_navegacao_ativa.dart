import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';

/// HUD imersivo de navegação turn-by-turn estilo Google Maps:
/// exibe a próxima manobra no topo, bússola (Norte fixo vs Adaptável)
/// e resumo do trajeto com botão Encerrar na base.
class HudNavegacaoAtiva extends StatelessWidget {
  final BuscaMapaController controller;
  final AppTheme theme;

  const HudNavegacaoAtiva({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rota = controller.rotaAtual;
    if (rota == null) return const SizedBox.shrink();

    final idxPasso = rota.passos.isNotEmpty
        ? controller.indicePassoAtual.clamp(0, rota.passos.length - 1)
        : 0;
    final passoPrincipal =
        rota.passos.isNotEmpty ? rota.passos[idxPasso] : null;
    final textoInstrucao = passoPrincipal?.instrucao ?? 'Siga pela rota traçada';
    final distBruta =
        controller.distanciaProximoPassoMetros ?? passoPrincipal?.distanciaMetros;
    final distManobra = distBruta != null
        ? (distBruta >= 1000
            ? '${(distBruta / 1000).toStringAsFixed(1)} km'
            : '${distBruta.round()} m')
        : rota.distanciaFormatada;

    return Stack(
      children: [
        // 1. Card superior de manobra (foco na estrada)
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F5338),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFFFFFFFF),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        distManobra,
                        style: theme.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        textoInstrucao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE6F4EA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Bússola (Norte fixo vs Adaptável) e Recentralizar na direita
        Positioned(
          right: 14,
          bottom: 108,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: theme.cardBackgroundColor.withValues(alpha: 0.95),
                shape: CircleBorder(
                  side: BorderSide(
                    color: controller.mapaFixoAoNorte
                        ? theme.buttonColor
                        : theme.borderColor.withValues(alpha: 0.85),
                    width: 1.4,
                  ),
                ),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller.alternarMapaFixoAoNorte,
                  child: Tooltip(
                    message: controller.mapaFixoAoNorte
                        ? 'Mapa fixo ao Norte (toque para adaptar)'
                        : 'Orientação adaptável (toque para fixar ao Norte)',
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: controller.mapaFixoAoNorte
                                ? 0.0
                                : (-controller.rumoUsuarioGraus *
                                    math.pi /
                                    180.0),
                            child: Icon(
                              Icons.explore_rounded,
                              size: 22,
                              color: controller.mapaFixoAoNorte
                                  ? theme.buttonColor
                                  : theme.textColor,
                            ),
                          ),
                          Text(
                            controller.mapaFixoAoNorte ? 'N' : 'AUTO',
                            style: theme.getTextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: controller.mapaFixoAoNorte
                                  ? theme.buttonColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: theme.cardBackgroundColor.withValues(alpha: 0.95),
                shape: CircleBorder(
                  side: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                ),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    controller.retomarSeguirCamera();
                    controller.centralizarNoUsuario();
                  },
                  child: Tooltip(
                    message: 'Recentralizar no trajeto',
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 22,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Barra inferior compacta do trajeto (sem barra de navegação universal)
        Positioned(
          left: 14,
          right: 14,
          bottom: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${rota.duracaoFormatada} • ${rota.distanciaFormatada}',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chegada às ${rota.horarioChegadaFormatado} • ${rota.destinoLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.dangerColor,
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: controller.alternarNavegacaoAoVivo,
                  child: Text(
                    'Encerrar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
