import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Card que exibe a versão atualmente instalada e a plataforma do dispositivo.
class CardVersaoAtual extends StatelessWidget {
  final AppTheme theme;

  const CardVersaoAtual({
    super.key,
    required this.theme,
  });

  String _rotuloPlataforma() {
    if (Platform.isAndroid) return 'Android (Móvel)';
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isIOS) return 'iOS (Móvel)';
    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versão Instalada',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'v${AtualizacaoService.versaoAtual} (Build ${AtualizacaoService.buildAtual})',
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _rotuloPlataforma(),
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
