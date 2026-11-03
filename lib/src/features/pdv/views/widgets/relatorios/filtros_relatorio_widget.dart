import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

const List<String> kFormasDePagamentoRelatorio = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

class DataInputFormatterRelatorio extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    var offset = newValue.selection.end;
    if (offset > texto.length) offset = texto.length;
    if (texto.length > oldValue.text.length && (offset == 2 || offset == 5)) {
      offset++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class FiltrosRelatorioWidget extends StatelessWidget {
  final AppTheme theme;
  final String? formaSelecionada;
  final ValueChanged<String?> onFormaChanged;
  final TextEditingController dataController;
  final ScrollController scrollController;
  final VoidCallback onDataChanged;
  final DateTime? dataInicial;

  const FiltrosRelatorioWidget({
    super.key,
    required this.theme,
    required this.formaSelecionada,
    required this.onFormaChanged,
    required this.dataController,
    required this.scrollController,
    required this.onDataChanged,
    required this.dataInicial,
  });

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  Widget _botaoDeFiltro(String forma) {
    final selecionada = formaSelecionada == forma;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return _LinhaComHover(
      aoClicar: () => onFormaChanged(selecionada ? null : forma),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionada
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
            color: selecionada || hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionada ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          forma,
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
            color: selecionada
                ? textoAtivo
                : (hover ? theme.textColor : theme.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  void _ajustarDia(int delta) {
    DateTime base;
    final atual = dataInicial;
    if (atual != null) {
      base = atual.add(Duration(days: delta));
    } else {
      base = DateTime.now();
    }
    dataController.text =
        '${_doisDigitos(base.day)}/${_doisDigitos(base.month)}/${base.year}';
    onDataChanged();
  }

  Future<void> _abrirDatePicker(BuildContext context) async {
    final atual = dataInicial ?? DateTime.now();
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
      dataController.text =
          '${_doisDigitos(selecionada.day)}/${_doisDigitos(selecionada.month)}/${selecionada.year}';
      onDataChanged();
    }
  }

  Widget _campoDeData(BuildContext context) {
    final temData = dataController.text.trim().isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Dia anterior',
          child: _LinhaComHover(
            aoClicar: () => _ajustarDia(-1),
            builder: (hover) => Container(
              padding: const EdgeInsets.all(8),
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
                size: 16,
                color: hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 175,
          child: TextField(
            controller: dataController,
            keyboardType: TextInputType.number,
            inputFormatters: [DataInputFormatterRelatorio()],
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('dd/mm/aaaa').copyWith(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              prefixIcon: Tooltip(
                message: 'Abrir calendário',
                child: IconButton(
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: theme.textColor,
                  ),
                  onPressed: () => _abrirDatePicker(context),
                ),
              ),
              suffixIcon: temData
                  ? Tooltip(
                      message: 'Limpar data',
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        onPressed: () {
                          dataController.clear();
                          onDataChanged();
                        },
                      ),
                    )
                  : null,
            ),
            onChanged: (_) => onDataChanged(),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Próximo dia',
          child: _LinhaComHover(
            aoClicar: () => _ajustarDia(1),
            builder: (hover) => Container(
              padding: const EdgeInsets.all(8),
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
                size: 16,
                color: hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          for (final forma in kFormasDePagamentoRelatorio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _botaoDeFiltro(forma),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _campoDeData(context),
          ),
        ],
      ),
    );
  }
}

class _LinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaComHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaComHover> createState() => _LinhaComHoverState();
}

class _LinhaComHoverState extends State<_LinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}
