import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';

class FreteClienteWidget extends StatefulWidget {
  final AppTheme theme;
  final Cliente cliente;
  final ValueChanged<double> onSalvarFrete;

  const FreteClienteWidget({
    super.key,
    required this.theme,
    required this.cliente,
    required this.onSalvarFrete,
  });

  @override
  State<FreteClienteWidget> createState() => _FreteClienteWidgetState();
}

class _FreteClienteWidgetState extends State<FreteClienteWidget> {
  late final TextEditingController _freteController;
  bool _salvo = false;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _freteController = TextEditingController(
      text: widget.cliente.fretePadrao > 0
          ? widget.cliente.fretePadrao.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant FreteClienteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cliente.id != widget.cliente.id ||
        oldWidget.cliente.fretePadrao != widget.cliente.fretePadrao) {
      _freteController.text = widget.cliente.fretePadrao > 0
          ? widget.cliente.fretePadrao.toStringAsFixed(2).replaceAll('.', ',')
          : '';
      _salvo = false;
    }
  }

  @override
  void dispose() {
    _freteController.dispose();
    super.dispose();
  }

  void _aplicar() {
    final texto = _freteController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto) ?? 0.0;
    widget.onSalvarFrete(valor < 0 ? 0.0 : valor);
    setState(() => _salvo = true);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );

    final valorAtual = widget.cliente.fretePadrao;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Frete',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Text(
            'Taxa de entrega acrescentada automaticamente na comanda ao selecionar este cliente.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _freteController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 13),
                  onSubmitted: (_) => _aplicar(),
                  onChanged: (_) {
                    if (_salvo) setState(() => _salvo = false);
                  },
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    prefixStyle: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                    hintText: '0,00',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    enabledBorder: borda(theme.borderColor),
                    focusedBorder: borda(theme.textColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return theme.borderColor.withValues(alpha: 0.18);
                    }
                    return theme.buttonColor != Colors.transparent
                        ? theme.buttonColor
                        : Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return theme.buttonColor != Colors.transparent
                        ? theme.buttonTextColor
                        : theme.textColor;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return BorderSide(color: theme.textColor, width: 1.4);
                    }
                    return BorderSide(color: theme.borderColor, width: 1.0);
                  }),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                onPressed: _aplicar,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _salvo ? Icons.check : Icons.save_outlined,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _salvo ? 'Salvo' : 'Salvar',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (valorAtual > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Frete atual configurado: R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
