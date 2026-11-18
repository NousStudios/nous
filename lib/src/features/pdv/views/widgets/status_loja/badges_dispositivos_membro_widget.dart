import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';

/// Exibe os badges de dispositivos conectados na rede local para um trabalhador.
class BadgesDispositivosMembroWidget extends StatelessWidget {
  final bool estaOnline;
  final List<TerminalConectadoInfo> dispositivos;
  final AppTheme theme;

  const BadgesDispositivosMembroWidget({
    super.key,
    required this.estaOnline,
    required this.dispositivos,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (!estaOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 11,
            color: theme.secondaryTextColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Nenhum dispositivo conectado na rede local',
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: dispositivos.map((disp) {
        final ehBalcao = disp.nome.toLowerCase().contains('balcão') ||
            disp.id.contains('balcao');
        final icone =
            ehBalcao ? Icons.computer_rounded : Icons.smartphone_rounded;

        return Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 12, color: theme.textColor),
              const SizedBox(width: 4),
              Flexible(
                child: TextoRolante(
                  texto:
                      '${disp.nome}${disp.ip.isNotEmpty && disp.ip != "Local" ? " (${disp.ip})" : ""}',
                  textAlign: TextAlign.start,
                  style: theme.getTextStyle(
                    fontSize: 10,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
