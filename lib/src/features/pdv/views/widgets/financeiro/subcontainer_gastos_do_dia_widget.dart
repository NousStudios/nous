import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/dialog_novo_gasto_fixo.dart';

class SubcontainerGastosDoDiaWidget extends StatefulWidget {
  final AppTheme theme;
  final List<GastoDiario> gastos;
  final List<GastoFixo> gastosFixos;
  final List<MembroLoja> membros;
  final ValueChanged<GastoDiario> onAdicionarGasto;
  final ValueChanged<String> onRemoverGasto;
  final ValueChanged<GastoFixo> onAdicionarGastoFixo;
  final ValueChanged<String> onRemoverGastoFixo;
  final ValueChanged<String> onAlternarAtivoGastoFixo;
  final String Function(double) formatarMoeda;

  const SubcontainerGastosDoDiaWidget({
    super.key,
    required this.theme,
    required this.gastos,
    this.gastosFixos = const [],
    this.membros = const [],
    required this.onAdicionarGasto,
    required this.onRemoverGasto,
    required this.onAdicionarGastoFixo,
    required this.onRemoverGastoFixo,
    required this.onAlternarAtivoGastoFixo,
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
  int _abaAtiva = 0; // 0 = Gastos do Dia, 1 = Gastos Fixos
  String _formaPagamento = 'Dinheiro';

  static const List<String> _formas = [
    'Dinheiro',
    'Pix',
    'Débito',
    'Crédito',
    'Voucher',
    'À Prazo',
  ];

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
      formaPagamento: _formaPagamento,
      pago: _formaPagamento != 'À Prazo',
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

  String _resumoRecorrencia(GastoFixo g) {
    const nomes = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
    switch (g.recorrencia) {
      case TipoRecorrenciaGasto.diario:
        return 'Diário';
      case TipoRecorrenciaGasto.semanal:
        final dia = g.diasDaSemana.isNotEmpty ? nomes[g.diasDaSemana.first] ?? '' : '';
        return dia.isNotEmpty ? 'Toda $dia' : 'Semanal';
      case TipoRecorrenciaGasto.mensal:
        return 'Todo dia ${g.diaDoMes ?? 1}';
      case TipoRecorrenciaGasto.diasAlternados:
        return 'Dias alternados';
      case TipoRecorrenciaGasto.diasDaSemana:
        return g.diasDaSemana.map((d) => nomes[d] ?? '$d').join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );

    final totalGastos = widget.gastos.fold<double>(0.0, (s, g) => s + g.valor);
    final totalFixosAtivos = widget.gastosFixos
        .where((g) => g.ativo)
        .fold<double>(0.0, (s, g) => s + g.valor);

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
                      'Gastos e Despesas',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compras avulsas e compromissos fixos recorrentes.',
                      style: theme.getTextStyle(
                        fontSize: 10.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (_abaAtiva == 1) {
                        DialogNovoGastoFixo.mostrar(
                          context: context,
                          theme: theme,
                          membros: widget.membros,
                          onSalvar: widget.onAdicionarGastoFixo,
                        );
                      } else {
                        setState(() => _mostrarFormulario = !_mostrarFormulario);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: (_abaAtiva == 0 && _mostrarFormulario)
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
                            (_abaAtiva == 0 && _mostrarFormulario) ? Icons.close : Icons.add,
                            size: 14,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _abaAtiva == 1
                                ? 'Novo Fixo'
                                : (_mostrarFormulario ? 'Fechar' : 'Declarar'),
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
            ],
          ),
          const SizedBox(height: 8),
          // Abas: Gastos do Dia | Gastos Fixos
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _abaAtiva = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: _abaAtiva == 0
                          ? theme.borderColor.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _abaAtiva == 0
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Gastos do Dia (${widget.gastos.length})',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: _abaAtiva == 0 ? FontWeight.bold : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _abaAtiva = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: _abaAtiva == 1
                          ? theme.borderColor.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _abaAtiva == 1
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Gastos Fixos (${widget.gastosFixos.length})',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: _abaAtiva == 1 ? FontWeight.bold : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_abaAtiva == 0) ...[
            if (_mostrarFormulario) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 105,
                    child: TextField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        enabledBorder: borda(theme.borderColor.withValues(alpha: 0.5)),
                        focusedBorder: borda(theme.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        enabledBorder: borda(theme.borderColor.withValues(alpha: 0.5)),
                        focusedBorder: borda(theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _formaPagamento,
                          dropdownColor: theme.cardBackgroundColor,
                          isExpanded: true,
                          style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
                          items: _formas.map((f) => DropdownMenuItem(value: f, child: Text('Pagto: $f'))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _formaPagamento = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  'Total declarado hoje:',
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
                constraints: const BoxConstraints(maxHeight: 130),
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
                              '${g.descricao.isNotEmpty ? g.descricao : "Gasto"} (${g.formaPagamento}${!g.pago ? " • Pendente" : ""})',
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
                              color: !g.pago ? theme.dangerColor : theme.textColor,
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
          ] else ...[
            // Aba 1: Gastos Fixos
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compromissos fixos ativos:',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  widget.formatarMoeda(totalFixosAtivos),
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (widget.gastosFixos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhum gasto fixo cadastrado.\nClique em "Novo Fixo" para cadastrar aluguel, diárias ou compras recorrentes.',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.gastosFixos.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
                  itemBuilder: (context, index) {
                    final gf = widget.gastosFixos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => widget.onAlternarAtivoGastoFixo(gf.id),
                            child: Icon(
                              gf.ativo ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 15,
                              color: gf.ativo ? Colors.greenAccent : theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gf.descricao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: gf.ativo ? theme.textColor : theme.secondaryTextColor,
                                  ),
                                ),
                                Text(
                                  '${_resumoRecorrencia(gf)} • ${gf.formaPagamentoPadrao}${gf.nomeFuncionario.isNotEmpty ? " • ${gf.nomeFuncionario}" : ""}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 9.5,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.formatarMoeda(gf.valor),
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: gf.ativo ? theme.textColor : theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => widget.onRemoverGastoFixo(gf.id),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.delete_outline,
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
