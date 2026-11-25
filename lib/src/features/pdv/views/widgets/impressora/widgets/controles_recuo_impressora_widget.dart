import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class ControlesRecuoImpressoraWidget extends StatelessWidget {
  final AppTheme theme;
  final double margemEsquerdaMm;
  final double margemDireitaMm;
  final ValueChanged<double> onMargemEsquerdaAlterada;
  final ValueChanged<double> onMargemDireitaAlterada;

  const ControlesRecuoImpressoraWidget({
    super.key,
    required this.theme,
    required this.margemEsquerdaMm,
    required this.margemDireitaMm,
    required this.onMargemEsquerdaAlterada,
    required this.onMargemDireitaAlterada,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estreito = constraints.maxWidth < 360;
        if (estreito) {
          return Column(
            children: [
              _ColunaRecuoWidget(
                theme: theme,
                titulo: 'Recuo Esquerdo',
                subtitulo: 'Início do texto',
                valor: margemEsquerdaMm,
                aoMudar: onMargemEsquerdaAlterada,
                atalhos: const [3.0, 5.0, 6.5, 8.0],
                padrao: 5.0,
              ),
              const SizedBox(height: 10),
              _ColunaRecuoWidget(
                theme: theme,
                titulo: 'Recuo Direito',
                subtitulo: 'Fim dos preços',
                valor: margemDireitaMm,
                aoMudar: onMargemDireitaAlterada,
                atalhos: const [1.5, 3.0, 4.5, 6.0],
                padrao: 3.0,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ColunaRecuoWidget(
                theme: theme,
                titulo: 'Recuo Esquerdo',
                subtitulo: 'Início do texto',
                valor: margemEsquerdaMm,
                aoMudar: onMargemEsquerdaAlterada,
                atalhos: const [3.0, 5.0, 6.5, 8.0],
                padrao: 5.0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ColunaRecuoWidget(
                theme: theme,
                titulo: 'Recuo Direito',
                subtitulo: 'Fim dos preços',
                valor: margemDireitaMm,
                aoMudar: onMargemDireitaAlterada,
                atalhos: const [1.5, 3.0, 4.5, 6.0],
                padrao: 3.0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColunaRecuoWidget extends StatelessWidget {
  final AppTheme theme;
  final String titulo;
  final String subtitulo;
  final double valor;
  final ValueChanged<double> aoMudar;
  final List<double> atalhos;
  final double padrao;

  const _ColunaRecuoWidget({
    required this.theme,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.aoMudar,
    required this.atalhos,
    required this.padrao,
  });

  Widget _botaoPasso({
    required IconData icone,
    required bool habilitado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icone,
          size: 16,
          color: habilitado ? theme.textColor : theme.secondaryTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          Text(
            subtitulo,
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _botaoPasso(
                icone: Icons.remove,
                habilitado: valor > 0.5,
                onTap: () => aoMudar((valor - 0.5).clamp(0.5, 15.0)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.textColor, width: 1.4),
                ),
                child: Text(
                  '${valor.toStringAsFixed(1)} mm',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _botaoPasso(
                icone: Icons.add,
                habilitado: valor < 15.0,
                onTap: () => aoMudar((valor + 0.5).clamp(0.5, 15.0)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final a in atalhos)
                InkWell(
                  onTap: () => aoMudar(a),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: (valor - a).abs() < 0.1
                          ? fundoAtivo
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (valor - a).abs() < 0.1
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.45),
                        width: (valor - a).abs() < 0.1 ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      '${a.toStringAsFixed(1)}${a == padrao ? '*' : ''}',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: (valor - a).abs() < 0.1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (valor - a).abs() < 0.1
                            ? textoAtivo
                            : theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
