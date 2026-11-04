import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';

class SubcontainerGastosDoDiaWidget extends StatefulWidget {
  final AppTheme theme;
  final List<GastoDiario> gastos;
  final ValueChanged<GastoDiario> onAdicionarGasto;
  final ValueChanged<String> onRemoverGasto;
  final String Function(double) formatarMoeda;

  const SubcontainerGastosDoDiaWidget({
    super.key,
    required this.theme,
    required this.gastos,
    required this.onAdicionarGasto,
    required this.onRemoverGasto,
    required this.formatarMoeda,
  });

  @override
  State<SubcontainerGastosDoDiaWidget> createState() =>
      _SubcontainerGastosDoDiaWidgetState();
}

class _SubcontainerGastosDoDiaWidgetState
    extends State<SubcontainerGastosDoDiaWidget> {
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _mostrarFormulario = false;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _registrar() {
    final textoValor = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(textoValor) ?? 0.0;
    if (valor <= 0) return;

    final novo = GastoDiario.novo(
      valor: valor,
      descricao: _descricaoController.text.trim(),
    );

    widget.onAdicionarGasto(novo);
    _valorController.clear();
    _descricaoController.clear();
    setState(() => _mostrarFormulario = false);
  }

  String _dataHoraFormatada(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)} ${dois(d.hour)}:${dois(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );

    final totalGastos = widget.gastos.fold<double>(0.0, (s, g) => s + g.valor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos do dia',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compras avulsas (carnes, feira) para operar as portas.',
                      style: theme.getTextStyle(
                        fontSize: 10.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _mostrarFormulario = !_mostrarFormulario);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _mostrarFormulario
                        ? theme.borderColor.withValues(alpha: 0.2)
                        : (theme.buttonColor != Colors.transparent
                            ? theme.buttonColor
                            : theme.borderColor.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _mostrarFormulario ? Icons.close : Icons.add,
                        size: 14,
                        color: theme.textColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _mostrarFormulario ? 'Fechar' : 'Declarar',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_mostrarFormulario) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 115,
                  child: TextField(
                    controller: _valorController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                    ],
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      prefixStyle: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                      hintText: '0,00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      enabledBorder:
                          borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: borda(theme.textColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _descricaoController,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Descrição (ex: Carnes, feira)',
                      hintStyle: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      enabledBorder:
                          borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: borda(theme.textColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    side: BorderSide(color: theme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: theme.buttonColor != Colors.transparent
                        ? theme.buttonColor
                        : Colors.transparent,
                  ),
                  onPressed: _registrar,
                  child: Text(
                    'Salvar',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total declarado:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
              Text(
                widget.formatarMoeda(totalGastos),
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: totalGastos > 0 ? theme.dangerColor : theme.textColor,
                ),
              ),
            ],
          ),
          if (widget.gastos.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.gastos.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
                itemBuilder: (context, index) {
                  final g = widget.gastos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          _dataHoraFormatada(g.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            g.descricao.isNotEmpty ? g.descricao : 'Gasto operacional',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(fontSize: 11),
                          ),
                        ),
                        Text(
                          widget.formatarMoeda(g.valor),
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => widget.onRemoverGasto(g.id),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 13,
                              color: theme.dangerColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
