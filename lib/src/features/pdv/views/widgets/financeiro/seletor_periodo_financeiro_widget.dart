import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart';

enum PeriodoFinanceiro { hoje, semana, mes, tudo, personalizado }

extension PeriodoFinanceiroExt on PeriodoFinanceiro {
  String get rotulo {
    switch (this) {
      case PeriodoFinanceiro.hoje:
        return 'Hoje';
      case PeriodoFinanceiro.semana:
        return 'Semana';
      case PeriodoFinanceiro.mes:
        return 'Mês';
      case PeriodoFinanceiro.tudo:
        return 'Tudo';
      case PeriodoFinanceiro.personalizado:
        return 'Personalizado';
    }
  }
}

/// Seletor de período financeiro com botões rápidos (Hoje, Semana, Mês, Tudo)
/// e campos de data com navegação direta por dia e calendário pop-up.
class SeletorPeriodoFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final PeriodoFinanceiro periodo;
  final TextEditingController dataInicioController;
  final TextEditingController dataFimController;
  final void Function(PeriodoFinanceiro novoPeriodo) onPeriodoAlterado;
  final String Function(PeriodoFinanceiro p)? rotuloPeriodoDe;
  final DateTime? Function(String texto) parseData;
  final String Function(DateTime data) formatarDataBR;

  const SeletorPeriodoFinanceiroWidget({
    super.key,
    required this.theme,
    required this.periodo,
    required this.dataInicioController,
    required this.dataFimController,
    required this.onPeriodoAlterado,
    this.rotuloPeriodoDe,
    required this.parseData,
    required this.formatarDataBR,
  });

  Widget _botaoPeriodo(BuildContext context, PeriodoFinanceiro p) {
    final selecionado = p == periodo;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return LinhaComHoverWidget(
      aoClicar: () {
        dataInicioController.clear();
        dataFimController.clear();
        onPeriodoAlterado(p);
      },
      builder: (hover) => Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado
              ? (hover
                  ? (theme.buttonColor != Colors.transparent
                      ? theme.buttonColor.withValues(alpha: 0.85)
                      : theme.borderColor.withValues(alpha: 0.35))
                  : fundoAtivo)
              : (hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado || hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          rotuloPeriodoDe != null ? rotuloPeriodoDe!(p) : p.rotulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado
                ? textoAtivo
                : (hover ? theme.textColor : theme.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampoData(String dica) {
    return InputDecoration(
      hintText: dica,
      hintStyle: theme.getTextStyle(
        fontSize: 11,
        color: theme.secondaryTextColor,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: theme.cardBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.textColor,
          width: 1.4,
        ),
      ),
    );
  }

  void _ajustarDiaController(TextEditingController controller, int delta) {
    DateTime base;
    final atual = parseData(controller.text);
    if (atual != null) {
      base = atual.add(Duration(days: delta));
    } else {
      base = DateTime.now();
    }
    controller.text = formatarDataBR(base);
    onPeriodoAlterado(PeriodoFinanceiro.personalizado);
  }

  Future<void> _abrirDatePickerController(
      BuildContext context, TextEditingController controller) async {
    final atual = parseData(controller.text) ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.buttonColor != Colors.transparent
                  ? theme.buttonColor
                  : theme.textColor,
              onPrimary: theme.buttonTextColor,
              surface: theme.cardBackgroundColor,
              onSurface: theme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selecionada != null) {
      controller.text = formatarDataBR(selecionada);
      onPeriodoAlterado(PeriodoFinanceiro.personalizado);
    }
  }

  Widget _campoDataComNavegacao({
    required BuildContext context,
    required String rotulo,
    required TextEditingController controller,
    required VoidCallback aoMudar,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Dia anterior',
          child: LinhaComHoverWidget(
            aoClicar: () => _ajustarDiaController(controller, -1),
            builder: (hover) => Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: hover
                    ? theme.borderColor.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hover
                      ? theme.textColor
                      : theme.borderColor.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 15,
                color: hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 148,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [DataInputFormatter()],
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampoData(rotulo).copyWith(
              suffixIcon: Tooltip(
                message: 'Abrir calendário',
                child: IconButton(
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: theme.textColor,
                  ),
                  onPressed: () =>
                      _abrirDatePickerController(context, controller),
                ),
              ),
            ),
            onChanged: (_) => aoMudar(),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Próximo dia',
          child: LinhaComHoverWidget(
            aoClicar: () => _ajustarDiaController(controller, 1),
            builder: (hover) => Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: hover
                    ? theme.borderColor.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hover
                      ? theme.textColor
                      : theme.borderColor.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputsDataPersonalizada(BuildContext context) {
    final temFiltroData = dataInicioController.text.trim().isNotEmpty ||
        dataFimController.text.trim().isNotEmpty;
    final dataInicioInvalida = dataInicioController.text.length == 10 &&
        parseData(dataInicioController.text) == null;
    final dataFimInvalida = dataFimController.text.length == 10 &&
        parseData(dataFimController.text) == null;

    void atualizarFiltro() {
      if (dataInicioController.text.isNotEmpty ||
          dataFimController.text.isNotEmpty) {
        onPeriodoAlterado(PeriodoFinanceiro.personalizado);
      } else {
        onPeriodoAlterado(PeriodoFinanceiro.hoje);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _campoDataComNavegacao(
              context: context,
              rotulo: 'De: dd/mm/aaaa',
              controller: dataInicioController,
              aoMudar: atualizarFiltro,
            ),
            _campoDataComNavegacao(
              context: context,
              rotulo: 'Até: dd/mm/aaaa',
              controller: dataFimController,
              aoMudar: atualizarFiltro,
            ),
            if (temFiltroData) ...[
              Tooltip(
                message: 'Limpar filtro de data',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    dataInicioController.clear();
                    dataFimController.clear();
                    onPeriodoAlterado(PeriodoFinanceiro.hoje);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (dataInicioInvalida || dataFimInvalida)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Data inválida informada',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.dangerColor,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double larguraBotao = 80;
    const double espaco = 8;

    const opcoes = [
      PeriodoFinanceiro.hoje,
      PeriodoFinanceiro.semana,
      PeriodoFinanceiro.mes,
      PeriodoFinanceiro.tudo,
    ];

    final botoes = opcoes.map((p) => _botaoPeriodo(context, p)).toList();
    final larguraTotal =
        larguraBotao * botoes.length + espaco * (botoes.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (larguraTotal <= constraints.maxWidth) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < botoes.length; i++) ...[
                    if (i > 0) const SizedBox(width: espaco),
                    botoes[i],
                  ],
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < botoes.length; i++) ...[
                    if (i > 0) const SizedBox(width: espaco),
                    botoes[i],
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _inputsDataPersonalizada(context),
      ],
    );
  }
}
