import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';

/// Card inferior exibido quando uma rota foi traçada (antes de iniciar a corrida),
/// contendo duração, distância, previsão de chegada, passo a passo e botão Iniciar.
class CardResumoRotaMapa extends StatefulWidget {
  final BuscaMapaController controller;
  final AppTheme theme;

  const CardResumoRotaMapa({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  State<CardResumoRotaMapa> createState() => _CardResumoRotaMapaState();
}

class _CardResumoRotaMapaState extends State<CardResumoRotaMapa> {
  bool _passosExpandidos = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ctrl = widget.controller;
    final rota = ctrl.rotaAtual;
    if (rota == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 20,
                color: theme.textColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rota.duracaoFormatada} (${rota.distanciaFormatada})',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Chegada prevista às ${rota.horarioChegadaFormatado}${rota.ehRotaRealOnline ? '' : ' • Offline'}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (rota.passos.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _passosExpandidos
                        ? Icons.expand_more_rounded
                        : Icons.list_alt_rounded,
                    size: 20,
                    color: theme.textColor,
                  ),
                  tooltip: 'Ver passo a passo',
                  onPressed: () =>
                      setState(() => _passosExpandidos = !_passosExpandidos),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: ctrl.alternarNavegacaoAoVivo,
                icon: Icon(
                  Icons.navigation_rounded,
                  size: 16,
                  color: theme.buttonTextColor,
                ),
                label: Text(
                  'Iniciar',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (_passosExpandidos && rota.passos.isNotEmpty) ...[
            const Divider(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rota.passos.length,
                itemBuilder: (_, idx) {
                  final passo = rota.passos[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.turn_right_rounded,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            passo.instrucao,
                            style: theme.getTextStyle(
                              fontSize: 11.5,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          passo.distanciaFormatada,
                          style: theme.getTextStyle(
                            fontSize: 10.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
