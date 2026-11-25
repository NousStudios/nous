import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra de abas do painel lateral/inferior do player universal
/// ("A SEGUIR", "LETRA" e "CIFRA").
class PlayerUniversalAbasPainel extends StatelessWidget {
  final AppTheme theme;
  final int? abaSelecionada;
  final ValueChanged<int> onSelecionarAba;
  final bool bordaSuperior;

  const PlayerUniversalAbasPainel({
    super.key,
    required this.theme,
    required this.abaSelecionada,
    required this.onSelecionarAba,
    this.bordaSuperior = false,
  });

  @override
  Widget build(BuildContext context) {
    final borda = BorderSide(color: theme.borderColor.withValues(alpha: 0.35));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: bordaSuperior ? Border(top: borda) : Border(bottom: borda),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BotaoAbaPainel(
            theme: theme,
            label: 'A SEGUIR',
            ativo: abaSelecionada == 0,
            onTap: () => onSelecionarAba(0),
          ),
          _BotaoAbaPainel(
            theme: theme,
            label: 'LETRA',
            ativo: abaSelecionada == 1,
            onTap: () => onSelecionarAba(1),
          ),
          _BotaoAbaPainel(
            theme: theme,
            label: 'CIFRA',
            ativo: abaSelecionada == 2,
            onTap: () => onSelecionarAba(2),
          ),
        ],
      ),
    );
  }
}

class _BotaoAbaPainel extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _BotaoAbaPainel({
    required this.theme,
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? theme.textColor : theme.secondaryTextColor,
            fontSize: 12,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
