import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Cabeçalho responsivo compartilhado pelas abas Ligações, Comunidades e Transmissão.
/// Em telas estreitas (celular), posiciona o botão de ação abaixo do subtítulo.
class CabecalhoAbaChatWidget extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final IconData iconeBotao;
  final String rotuloBotao;
  final VoidCallback onPressionarBotao;

  const CabecalhoAbaChatWidget({
    super.key,
    required this.theme,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.iconeBotao,
    required this.rotuloBotao,
    required this.onPressionarBotao,
  });

  @override
  Widget build(BuildContext context) {
    final blocoTexto = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icone, size: 22, color: theme.textColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final botao = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.textColor,
        foregroundColor: theme.backgroundColor,
      ),
      onPressed: onPressionarBotao,
      icon: Icon(iconeBotao, size: 18),
      label: Text(rotuloBotao),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ehEstreito = constraints.maxWidth < 520;
          if (ehEstreito) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                blocoTexto,
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: botao,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: blocoTexto),
              const SizedBox(width: 12),
              botao,
            ],
          );
        },
      ),
    );
  }
}
