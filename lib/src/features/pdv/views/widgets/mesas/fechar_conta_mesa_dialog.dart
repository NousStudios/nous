import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/cadastro_cliente_rapido_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/painel_ajustes_totais_mesa_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/painel_dividir_pagamento_mesa_widget.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

const List<String> _formasDePagamento = [
  'Dinheiro',
  'Pix',
  'Cartão de Crédito',
  'Cartão de Débito',
  'À Prazo',
];

class ResultadoFechamentoMesa {
  final String formaPagamento;
  final List<PagamentoParcial> pagamentos;
  final double desconto;
  final double acrescimo;
  final double valorFinal;
  final bool baixarEstoque;
  final String? clienteId;
  final String? clienteNome;

  const ResultadoFechamentoMesa({
    required this.formaPagamento,
    this.pagamentos = const [],
    this.desconto = 0,
    this.acrescimo = 0,
    required this.valorFinal,
    required this.baixarEstoque,
    this.clienteId,
    this.clienteNome,
  });
}

class FecharContaMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja mesa;
  final List<Cliente> clientes;
  final Future<void> Function(Cliente novoCliente)? onSalvarCliente;

  const FecharContaMesaDialog({
    super.key,
    required this.theme,
    required this.mesa,
    this.clientes = const [],
    this.onSalvarCliente,
  });

  static Future<ResultadoFechamentoMesa?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MesaLoja mesa,
    List<Cliente> clientes = const [],
    Future<void> Function(Cliente)? onSalvarCliente,
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
              clientes: clientes,
              onSalvarCliente: onSalvarCliente,
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
      _acrescimoController.text =
          dezPorCento.toStringAsFixed(2).replaceAll('.', ',');
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

  Future<void> _concluirFechamento() async {
    final temAPrazo = _dividirPagamento
        ? _pagamentosParciais.any((p) {
            final f = p.forma.trim().toLowerCase();
            return f == 'à prazo' || f == 'a prazo';
          })
        : (_formaPagamento.trim().toLowerCase() == 'à prazo' ||
            _formaPagamento.trim().toLowerCase() == 'a prazo');

    String? clienteIdFinal;
    String? clienteNomeFinal = widget.mesa.clienteNome;

    if (temAPrazo) {
      final nomeAtual = clienteNomeFinal.trim();
      Cliente? clienteCadastrado;
      if (nomeAtual.isNotEmpty) {
        clienteCadastrado = widget.clientes.where((c) {
          return c.nome.trim().toLowerCase() == nomeAtual.toLowerCase();
        }).firstOrNull;
      }

      if (clienteCadastrado == null) {
        final novoCliente = await showDialog<Cliente>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (dialogCtx) {
            return CadastroClienteRapidoMesaDialog(
              theme: widget.theme,
              nomeInicial: nomeAtual,
              numeroMesa: widget.mesa.numero,
            );
          },
        );

        if (novoCliente == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: widget.theme.cardBackgroundColor,
              content: Text(
                'Venda à prazo cancelada: é necessário cadastrar o cliente.',
                style: widget.theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          );
          return;
        }

        if (widget.onSalvarCliente != null) {
          await widget.onSalvarCliente!(novoCliente);
        }
        clienteIdFinal = novoCliente.id;
        clienteNomeFinal = novoCliente.nome;
      } else {
        clienteIdFinal = clienteCadastrado.id;
        clienteNomeFinal = clienteCadastrado.nome;
      }
    }

    if (!mounted) return;

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

      if (_totalPagoDividido > _totalFinal + 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: widget.theme.cardBackgroundColor,
            content: Text(
              'A soma dos pagamentos (${_valorFormatado(_totalPagoDividido)}) excede o total da conta (${_valorFormatado(_totalFinal)}). Ajuste os valores adicionados.',
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
          clienteId: clienteIdFinal,
          clienteNome: clienteNomeFinal,
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
          clienteId: clienteIdFinal,
          clienteNome: clienteNomeFinal,
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
          PainelAjustesTotaisMesaWidget(
            theme: theme,
            descontoController: _descontoController,
            acrescimoController: _acrescimoController,
            onAplicarDezPorCento: _aplicarDezPorCento,
            onAlterado: () => setState(() {}),
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
            PainelDividirPagamentoMesaWidget(
              theme: theme,
              formasDePagamento: _formasDePagamento,
              pagamentosParciais: _pagamentosParciais,
              totalPagoDividido: _totalPagoDividido,
              restantePagar: _restantePagar,
              formaParcial: _formaParcial,
              onFormaParcialAlterada: (nova) =>
                  setState(() => _formaParcial = nova),
              valorParcialController: _valorParcialController,
              onAdicionarPagamentoParcial: _adicionarPagamentoParcial,
              onRemoverPagamentoParcial: _removerPagamentoParcial,
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
                  ThemedSwitch(
                    theme: theme,
                    value: _baixarEstoque,
                    onChanged: (v) => setState(() => _baixarEstoque = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Botão Concluir
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
                EdgeInsets.symmetric(vertical: 14),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            onPressed: _concluirFechamento,
            child: Text(
              'Concluir Venda e Liberar Mesa',
              style: theme.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.buttonColor != Colors.transparent
                    ? theme.buttonTextColor
                    : theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
