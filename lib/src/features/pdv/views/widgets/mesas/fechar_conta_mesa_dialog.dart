import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

const List<String> _formasDePagamento = [
  'Dinheiro',
  'Pix',
  'Cartão de Crédito',
  'Cartão de Débito',
  'Fiado / A Prazo',
];

class ResultadoFechamentoMesa {
  final String formaPagamento;
  final List<PagamentoParcial> pagamentos;
  final double desconto;
  final double acrescimo;
  final double valorFinal;
  final bool baixarEstoque;

  const ResultadoFechamentoMesa({
    required this.formaPagamento,
    this.pagamentos = const [],
    this.desconto = 0,
    this.acrescimo = 0,
    required this.valorFinal,
    required this.baixarEstoque,
  });
}

class FecharContaMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja mesa;

  const FecharContaMesaDialog({
    super.key,
    required this.theme,
    required this.mesa,
  });

  static Future<ResultadoFechamentoMesa?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MesaLoja mesa,
  }) {
    return showDialog<ResultadoFechamentoMesa>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FecharContaMesaDialog(
              theme: theme,
              mesa: mesa,
            ),
          ),
        );
      },
    );
  }

  @override
  State<FecharContaMesaDialog> createState() => _FecharContaMesaDialogState();
}

class _FecharContaMesaDialogState extends State<FecharContaMesaDialog> {
  String _formaPagamento = 'Dinheiro';
  bool _baixarEstoque = true;
  bool _dividirPagamento = false;

  final _descontoController = TextEditingController();
  final _acrescimoController = TextEditingController();

  final _valorParcialController = TextEditingController();
  String _formaParcial = 'Dinheiro';
  final List<PagamentoParcial> _pagamentosParciais = [];

  @override
  void dispose() {
    _descontoController.dispose();
    _acrescimoController.dispose();
    _valorParcialController.dispose();
    super.dispose();
  }

  double get _totalBase => widget.mesa.totalAcumulado;

  double get _desconto {
    final t = _descontoController.text.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0;
  }

  double get _acrescimo {
    final t = _acrescimoController.text.trim().replaceAll(',', '.');
    return double.tryParse(t) ?? 0;
  }

  double get _totalFinal {
    final v = _totalBase - _desconto + _acrescimo;
    return v < 0 ? 0 : v;
  }

  double get _totalPagoDividido =>
      _pagamentosParciais.fold<double>(0, (soma, p) => soma + p.valor);

  double get _restantePagar {
    final r = _totalFinal - _totalPagoDividido;
    return r < 0.005 ? 0 : r;
  }

  void _aplicarDezPorCento() {
    final dezPorCento = _totalBase * 0.10;
    setState(() {
      _acrescimoController.text = dezPorCento.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  void _adicionarPagamentoParcial() {
    final texto = _valorParcialController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0) return;

    if (valor > _restantePagar + 0.005) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.cardBackgroundColor,
          content: Text(
            'O valor excede o saldo restante a pagar.',
            style: widget.theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    setState(() {
      _pagamentosParciais.add(
        PagamentoParcial(forma: _formaParcial, valor: valor),
      );
      _valorParcialController.clear();
      if (_restantePagar > 0) {
        _valorParcialController.text =
            _restantePagar.toStringAsFixed(2).replaceAll('.', ',');
      }
    });
  }

  void _removerPagamentoParcial(int index) {
    setState(() {
      _pagamentosParciais.removeAt(index);
    });
  }

  void _concluirFechamento() {
    if (_dividirPagamento) {
      if (_restantePagar > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: widget.theme.cardBackgroundColor,
            content: Text(
              'Ainda restam ${_valorFormatado(_restantePagar)} a serem quitados.',
              style: widget.theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pop(
        ResultadoFechamentoMesa(
          formaPagamento: _pagamentosParciais.isNotEmpty
              ? _pagamentosParciais.first.forma
              : 'Dinheiro',
          pagamentos: _pagamentosParciais,
          desconto: _desconto,
          acrescimo: _acrescimo,
          valorFinal: _totalFinal,
          baixarEstoque: _baixarEstoque,
        ),
      );
    } else {
      Navigator.of(context).pop(
        ResultadoFechamentoMesa(
          formaPagamento: _formaPagamento,
          pagamentos: [
            PagamentoParcial(forma: _formaPagamento, valor: _totalFinal),
          ],
          desconto: _desconto,
          acrescimo: _acrescimo,
          valorFinal: _totalFinal,
          baixarEstoque: _baixarEstoque,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Fechar Mesa ${widget.mesa.numero}',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),

          // Totalizador Principal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                if (widget.mesa.clienteNome.isNotEmpty) ...[
                  Text(
                    'Cliente: ${widget.mesa.clienteNome}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Consumo Base: ${_valorFormatado(_totalBase)}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _valorFormatado(_totalFinal),
                  style: theme.getTextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  '${widget.mesa.quantidadeItensTotal} ${widget.mesa.quantidadeItensTotal == 1 ? "item consumido" : "itens consumidos"}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ajustes: Desconto e Taxa / Acréscimo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ajustes no Total (Opcional):',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _aplicarDezPorCento,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '+10% Garçom',
                          style: theme.getTextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descontoController,
                        onChanged: (_) => setState(() {}),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                        ],
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Desconto (R\$)',
                          labelStyle: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _acrescimoController,
                        onChanged: (_) => setState(() {}),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                        ],
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'Taxa / Acréscimo (R\$)',
                          labelStyle: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.borderColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Alternância: Pagamento Único vs Dividir Conta
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _dividirPagamento = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_dividirPagamento
                          ? theme.borderColor.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_dividirPagamento
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Pagamento Único',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: !_dividirPagamento
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _dividirPagamento = true;
                      if (_pagamentosParciais.isEmpty && _restantePagar > 0) {
                        _valorParcialController.text =
                            _restantePagar.toStringAsFixed(2).replaceAll('.', ',');
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _dividirPagamento
                          ? theme.borderColor.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dividirPagamento
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Dividir Conta (Múltiplos)',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: _dividirPagamento
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Se Pagamento Único
          if (!_dividirPagamento) ...[
            Text(
              'Forma de Pagamento:',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _formaPagamento,
                  dropdownColor: theme.cardBackgroundColor,
                  isExpanded: true,
                  items: _formasDePagamento.map((forma) {
                    return DropdownMenuItem<String>(
                      value: forma,
                      child: Text(
                        forma,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (nova) {
                    if (nova != null) setState(() => _formaPagamento = nova);
                  },
                ),
              ),
            ),
          ] else ...[
            // Se Dividir Conta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pago: ${_valorFormatado(_totalPagoDividido)}',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        _restantePagar > 0.005
                            ? 'Falta: ${_valorFormatado(_restantePagar)}'
                            : 'Conta Quitada!',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _restantePagar > 0.005
                              ? Colors.redAccent
                              : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  if (_pagamentosParciais.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (int i = 0; i < _pagamentosParciais.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: theme.textColor),
                            const SizedBox(width: 6),
                            Text(
                              _pagamentosParciais[i].forma,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.textColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _valorFormatado(_pagamentosParciais[i].valor),
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removerPagamentoParcial(i),
                              child: Icon(Icons.close,
                                  size: 14, color: theme.secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (_restantePagar > 0.005) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _formaParcial,
                                dropdownColor: theme.cardBackgroundColor,
                                isExpanded: true,
                                items: _formasDePagamento.map((forma) {
                                  return DropdownMenuItem<String>(
                                    value: forma,
                                    child: Text(
                                      forma,
                                      style: theme.getTextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (nova) {
                                  if (nova != null) {
                                    setState(() => _formaParcial = nova);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _valorParcialController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,]')),
                            ],
                            style: theme.getTextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Valor',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: theme.borderColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.add,
                              size: 20, color: theme.textColor),
                          onPressed: _adicionarPagamentoParcial,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Switch Baixa de Estoque
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _baixarEstoque = !_baixarEstoque),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baixar produtos do estoque',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          'Registra saída automática no controle de estoque',
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _baixarEstoque,
                    onChanged: (v) => setState(() => _baixarEstoque = v),
                    activeThumbColor: theme.textColor,
                    activeTrackColor:
                        theme.borderColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Botão Concluir
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _concluirFechamento,
            child: Text(
              'Concluir Venda e Liberar Mesa',
              style: theme.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
