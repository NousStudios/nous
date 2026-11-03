import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

/// Bloco encapsulado de configuração dos atalhos de teclado (F1 a F12).
class BlocoAtalhosTecladoWidget extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracaoBloco;
  final List<String> teclasFuncao;
  final List<String> acoesAtalhosDisponiveis;
  final bool podeEditar;
  final String Function(String tecla)? onObterAcaoPorTecla;
  final void Function(String tecla, String? acao) onSalvarAtalho;

  const BlocoAtalhosTecladoWidget({
    super.key,
    required this.theme,
    required this.decoracaoBloco,
    required this.teclasFuncao,
    required this.acoesAtalhosDisponiveis,
    required this.podeEditar,
    this.onObterAcaoPorTecla,
    required this.onSalvarAtalho,
  });

  Widget _buildItemTeclaAtalho(
    BuildContext context,
    AppTheme theme,
    String tecla,
    bool podeEditar,
  ) {
    if (tecla == 'F11') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                'F11',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextoRolante(
                    texto: 'Tela Cheia (Padrão do Sistema)',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    'Atalho fixo do sistema',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Fixo',
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final acaoAtual = onObterAcaoPorTecla != null
        ? onObterAcaoPorTecla!(tecla)
        : 'Desativado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.buttonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.buttonColor.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              tecla,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.buttonColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: acoesAtalhosDisponiveis.contains(acaoAtual)
                    ? acaoAtual
                    : 'Desativado',
                isExpanded: true,
                dropdownColor: theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: podeEditar
                      ? theme.textColor
                      : theme.secondaryTextColor.withValues(alpha: 0.5),
                ),
                items: acoesAtalhosDisponiveis.map((acao) {
                  final ehDesativado = acao == 'Desativado';
                  return DropdownMenuItem<String>(
                    value: acao,
                    child: Text(
                      acao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: ehDesativado
                            ? theme.secondaryTextColor
                            : theme.textColor,
                        fontWeight: acao == acaoAtual
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: podeEditar
                    ? (novo) => onSalvarAtalho(tecla, novo)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_outlined,
                  color: theme.buttonColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comandos (Atalhos do Teclado)',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Personalize as teclas de atalho do teclado para agilizar a operação diária no PDV. Defina qual ação cada tecla de função deve executar.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final emDuasColunas = constraints.maxWidth > 520;
              final metade = (teclasFuncao.length / 2).ceil();
              final col1 = teclasFuncao.sublist(0, metade);
              final col2 = teclasFuncao.sublist(metade);

              if (emDuasColunas) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: col1
                            .map((t) => _buildItemTeclaAtalho(
                                context, theme, t, podeEditar))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: col2
                            .map((t) => _buildItemTeclaAtalho(
                                context, theme, t, podeEditar))
                            .toList(),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: teclasFuncao
                    .map((t) =>
                        _buildItemTeclaAtalho(context, theme, t, podeEditar))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
