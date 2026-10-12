import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class SeletorLayoutsDesktopWidget extends StatelessWidget {
  final AppTheme theme;
  final bool podeEditar;
  final bool layoutExpandido;
  final String tipoLayoutSelecionado;
  final VoidCallback onAlternarLayout;
  final ValueChanged<String> onSelecionarTipo;

  const SeletorLayoutsDesktopWidget({
    super.key,
    required this.theme,
    required this.podeEditar,
    required this.layoutExpandido,
    required this.tipoLayoutSelecionado,
    required this.onAlternarLayout,
    required this.onSelecionarTipo,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = layoutExpandido;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Modo de Visualização e Layout do PDV',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Alterne entre a versão compacta e a experiência desktop expandida com barra lateral e painéis amplos.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card Único: Layout Desktop PDV Expandido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ativo
                  ? theme.borderColor.withValues(alpha: 0.12)
                  : theme.borderColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ativo
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.6),
                width: ativo ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ativo
                            ? (theme.buttonColor != Colors.transparent
                                ? theme.buttonColor
                                : theme.borderColor.withValues(alpha: 0.35))
                            : theme.borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ativo ? theme.textColor : theme.borderColor,
                        ),
                      ),
                      child: Icon(
                        ativo
                            ? Icons.view_sidebar_rounded
                            : Icons.view_compact_outlined,
                        size: 20,
                        color:
                            ativo ? theme.textColor : theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layout Desktop PDV Expandido',
                            style: theme.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ativo
                                ? 'Layout expandido ativo na aplicação'
                                : 'Layout compacto padrão ativo na aplicação',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BotaoAlternarDesktop(
                      theme: theme,
                      ativo: ativo,
                      onPressed: onAlternarLayout,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recursos incluídos neste modo:',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                _itemRecurso(
                  theme,
                  Icons.view_sidebar_rounded,
                  'Barra lateral com logo, status de caixa e atalhos rápidos.',
                ),
                const SizedBox(height: 4),
                _itemRecurso(
                  theme,
                  Icons.dashboard_customize_rounded,
                  'Janelas operacionais (Nova Venda, Clientes, Caixa, Relatórios, Impressora) em colunas duplas amplas.',
                ),
                const SizedBox(height: 4),
                _itemRecurso(
                  theme,
                  Icons.fullscreen_rounded,
                  'Pressione a tecla F11 no teclado a qualquer momento para alternar a tela cheia do Windows.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRecurso(AppTheme theme, IconData icone, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 14, color: theme.secondaryTextColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _BotaoAlternarDesktop extends StatefulWidget {
  final AppTheme theme;
  final bool ativo;
  final VoidCallback onPressed;

  const _BotaoAlternarDesktop({
    required this.theme,
    required this.ativo,
    required this.onPressed,
  });

  @override
  State<_BotaoAlternarDesktop> createState() => _BotaoAlternarDesktopState();
}

class _BotaoAlternarDesktopState extends State<_BotaoAlternarDesktop> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ativo = widget.ativo;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: OutlinedButton.icon(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (_hover) {
              return theme.borderColor.withValues(alpha: 0.18);
            }
            return ativo
                ? theme.borderColor.withValues(alpha: 0.10)
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.all(theme.textColor),
          side: WidgetStateProperty.resolveWith((states) {
            if (_hover || ativo) {
              return BorderSide(color: theme.textColor, width: 1.4);
            }
            return BorderSide(color: theme.borderColor, width: 1.0);
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        ),
        onPressed: widget.onPressed,
        icon: Icon(
          ativo ? Icons.view_compact_outlined : Icons.view_sidebar_outlined,
          size: 18,
          color: theme.textColor,
        ),
        label: Text(
          ativo ? 'Usar Layout Compacto' : 'Usar Layout Expandido',
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
}
