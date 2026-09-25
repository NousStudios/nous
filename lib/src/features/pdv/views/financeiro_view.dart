import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

enum PeriodoFinanceiro { hoje, semana, mes, tudo }

class FinanceiroView extends StatefulWidget {
  final String lojaId;
  final List<PedidoLoja> pedidos;

  const FinanceiroView({
    super.key,
    required this.lojaId,
    required this.pedidos,
  });

  @override
  State<FinanceiroView> createState() => _FinanceiroViewState();
}

class _FinanceiroViewState extends State<FinanceiroView> {
  PeriodoFinanceiro _periodo = PeriodoFinanceiro.hoje;

  DateTime? get _inicioDoPeriodo {
    final agora = DateTime.now();
    switch (_periodo) {
      case PeriodoFinanceiro.hoje:
        return DateTime(agora.year, agora.month, agora.day);
      case PeriodoFinanceiro.semana:
        final inicio = agora.subtract(Duration(days: agora.weekday - 1));
        return DateTime(inicio.year, inicio.month, inicio.day);
      case PeriodoFinanceiro.mes:
        return DateTime(agora.year, agora.month, 1);
      case PeriodoFinanceiro.tudo:
        return null;
    }
  }

  List<PedidoLoja> get _vendasConcluidas {
    final desde = _inicioDoPeriodo;
    return widget.pedidos.where((p) {
      if (p.status != StatusPedido.concluido) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      return true;
    }).toList();
  }

  List<PedidoLoja> get _pedidosAceitos {
    final desde = _inicioDoPeriodo;
    return widget.pedidos.where((p) {
      if (p.status != StatusPedido.aceito) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      return true;
    }).toList();
  }

  double get _totalEntradas =>
      _vendasConcluidas.fold(0.0, (soma, p) => soma + p.valor);

  double get _totalAReceber =>
      _pedidosAceitos.fold(0.0, (soma, p) => soma + p.valor);

  double _entradasPorForma(String forma) {
    return _vendasConcluidas
        .where((p) => p.formaPagamento == forma)
        .fold(0.0, (soma, p) => soma + p.valor);
  }

  String _valorFormatado(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  String _rotuloPeriodo(PeriodoFinanceiro p) {
    switch (p) {
      case PeriodoFinanceiro.hoje:
        return 'Hoje';
      case PeriodoFinanceiro.semana:
        return 'Semana';
      case PeriodoFinanceiro.mes:
        return 'Mês';
      case PeriodoFinanceiro.tudo:
        return 'Tudo';
    }
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(AppTheme theme, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _linha(
    AppTheme theme,
    String rotulo,
    String valor, {
    bool destaque = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          Text(
            valor,
            style: theme.getTextStyle(
              fontSize: destaque ? 14 : 13,
              color: theme.textColor,
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroPeriodo(AppTheme theme) {
    const double larguraBotao = 80;
    const double espaco = 8;

    final botoes = PeriodoFinanceiro.values.map((p) {
      final selecionado = p == _periodo;
      return SizedBox(
        width: larguraBotao,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor:
                selecionado ? theme.buttonColor : Colors.transparent,
            foregroundColor:
                selecionado ? theme.buttonTextColor : theme.textColor,
            side: BorderSide(color: theme.borderColor),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => setState(() => _periodo = p),
          child: Text(
            _rotuloPeriodo(p),
            style: theme.getTextStyle(
              fontSize: 12,
              color:
                  selecionado ? theme.buttonTextColor : theme.textColor,
            ),
          ),
        ),
      );
    }).toList();

    final larguraTotal =
        larguraBotao * botoes.length + espaco * (botoes.length - 1);

    return LayoutBuilder(
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
    );
  }

  Widget _blocoEntradas(AppTheme theme) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Entradas por forma de pagamento'),
          for (final forma in _formasDePagamento)
            _linha(theme, forma, _valorFormatado(_entradasPorForma(forma))),
          const Divider(height: 20),
          _linha(
            theme,
            'Total',
            _valorFormatado(_totalEntradas),
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _blocoBalanco(AppTheme theme) {
    final entradas = _totalEntradas;
    const saidas = 0.0;
    final saldo = entradas - saidas;
    final aReceber = _totalAReceber;
    final quantidadeAReceber = _pedidosAceitos.length;

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Balança orçamentária'),
          _linha(theme, 'Entradas', _valorFormatado(entradas)),
          _linha(theme, 'Saídas', _valorFormatado(saidas)),
          const Divider(height: 20),
          _linha(theme, 'Saldo', _valorFormatado(saldo), destaque: true),
          if (quantidadeAReceber > 0) ...[
            const SizedBox(height: 8),
            Text(
              'A receber ($quantidadeAReceber ${quantidadeAReceber == 1 ? 'pedido aceito' : 'pedidos aceitos'}): ${_valorFormatado(aReceber)}',
              textAlign: TextAlign.center,
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

  Widget _blocoFuncionarios(AppTheme theme) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Pagamento de funcionários'),
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum pagamento registrado ainda.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registrar pagamento: em construção'),
                  ),
                );
              },
              child: Text(
                'Registrar pagamento',
                style: theme.getTextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(title: 'Financeiro'),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _filtroPeriodo(theme),
                      const SizedBox(height: 16),
                      Center(child: _blocoEntradas(theme)),
                      const SizedBox(height: 16),
                      Center(child: _blocoBalanco(theme)),
                      const SizedBox(height: 16),
                      Center(child: _blocoFuncionarios(theme)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}