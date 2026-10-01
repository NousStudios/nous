import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/registrar_pagamento_dialog.dart';

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
  bool _contarEstoque = true;
  bool _imprimindo = false;
  bool _exportando = false;

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

  String get _rotuloPeriodoAtual {
    switch (_periodo) {
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

  List<PagamentoFuncionario> _pagamentosDoPeriodo(Loja? loja) {
    if (loja == null) return [];
    final desde = _inicioDoPeriodo;
    final lista = loja.pagamentosFuncionarios.where((p) {
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  List<MovimentoEstoque> _movimentosDoPeriodo(Loja? loja) {
    if (loja == null) return [];
    final desde = _inicioDoPeriodo;
    final lista = loja.movimentosEstoque.where((m) {
      if (desde != null && m.dataHora.isBefore(desde)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  double _saidaEstoqueDoPeriodo(Loja? loja) {
    final desde = _inicioDoPeriodo;
    var soma = 0.0;
    for (final m in _movimentosDoPeriodo(loja)) {
      if (!m.ehEntrada) continue;
      if (desde != null && m.dataHora.isBefore(desde)) continue;
      soma += m.custoTotal;
    }
    return soma;
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

  String _valorComSinal(double valor) {
    if (valor < 0) return '-${_valorFormatado(-valor)}';
    return _valorFormatado(valor);
  }

  void _snack(String texto) {
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          texto,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
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
    bool negativo = false,
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
              color: negativo ? Colors.redAccent : theme.textColor,
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
            _rotuloPeriodoDe(p),
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

  String _rotuloPeriodoDe(PeriodoFinanceiro p) {
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

  Widget _botaoAcao(
    AppTheme theme,
    String rotulo, {
    required bool carregando,
    required VoidCallback? aoPressionar,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: carregando ? null : aoPressionar,
      child: carregando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }

  Widget _barraAcoes(AppTheme theme, Loja? loja) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _botaoAcao(
          theme,
          'Imprimir',
          carregando: _imprimindo,
          aoPressionar: loja == null ? null : () => _imprimir(loja),
        ),
        const SizedBox(width: 8),
        _botaoAcao(
          theme,
          'Exportar PDF',
          carregando: _exportando,
          aoPressionar: loja == null ? null : () => _exportar(loja),
        ),
      ],
    );
  }

  Future<void> _imprimir(Loja loja) async {
    if (_imprimindo) return;
    setState(() => _imprimindo = true);
    try {
      await ImpressaoService.imprimirFinanceiro(
        config: loja.configuracoesImpressora,
        loja: loja,
        periodo: _rotuloPeriodoAtual,
        vendas: _vendasConcluidas,
        pedidosAceitos: _pedidosAceitos,
        pagamentos: _pagamentosDoPeriodo(loja),
        movimentos: _movimentosDoPeriodo(loja),
        saidaEstoque: _saidaEstoqueDoPeriodo(loja),
        contarEstoque: _contarEstoque,
      );
      if (!mounted) return;
      _snack('Relatório enviado para a impressora.');
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao imprimir: $e');
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _exportar(Loja loja) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final caminho = await ImpressaoService.exportarFinanceiroPDF(
        loja: loja,
        periodo: _rotuloPeriodoAtual,
        rodape: loja.configuracoesImpressora.rodape,
        vendas: _vendasConcluidas,
        pedidosAceitos: _pedidosAceitos,
        pagamentos: _pagamentosDoPeriodo(loja),
        movimentos: _movimentosDoPeriodo(loja),
        saidaEstoque: _saidaEstoqueDoPeriodo(loja),
        contarEstoque: _contarEstoque,
      );
      if (!mounted) return;
      if (caminho == null) {
        _snack('Exportação cancelada.');
      } else {
        _snack('PDF salvo em: $caminho');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _registrarPagamento(Loja loja) async {
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta == null) return;

    final entradas = _totalEntradas;
    final pagamentos = _pagamentosDoPeriodo(loja);
    final saidaEstoque = _saidaEstoqueDoPeriodo(loja);
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final saidas = totalPagamentos + (_contarEstoque ? saidaEstoque : 0);
    final disponivel = entradas - saidas;
    final numeroMembros = loja.membros.isEmpty ? 0 : loja.membros.length;
    final sugestao = numeroMembros == 0
        ? 0.0
        : (disponivel <= 0 ? 0.0 : disponivel / numeroMembros);

    final resultado = await RegistrarPagamentoDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      membros: loja.membros,
      sugestaoPorMembro: sugestao,
      disponivelNoPeriodo: disponivel,
      numeroMembros: numeroMembros,
    );

    if (resultado == null) return;

    final pagamento = PagamentoFuncionario.novo(
      cpf: resultado.cpf,
      nome: resultado.nome,
      valor: resultado.valor,
      descricao: resultado.descricao,
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
    );

    if (!mounted) return;
    context
        .read<PdvProvider>()
        .adicionarPagamentoFuncionario(widget.lojaId, pagamento);
  }

  Future<void> _excluirPagamento(PagamentoFuncionario p) async {
    final theme = ThemeController.currentTheme.value;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir pagamento',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Excluir o pagamento de ${p.nome} (${_valorFormatado(p.valor)})? '
            'Essa ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;
    if (!mounted) return;
    context
        .read<PdvProvider>()
        .removerPagamentoFuncionario(widget.lojaId, p.id);
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

  Widget _blocoBalanco(AppTheme theme, Loja? loja) {
    final entradas = _totalEntradas;
    final saidaEstoque = _saidaEstoqueDoPeriodo(loja);
    final pagamentos = _pagamentosDoPeriodo(loja);
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final saidas =
        totalPagamentos + (_contarEstoque ? saidaEstoque : 0);
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
          _linha(
            theme,
            'Saídas (funcionários)',
            _valorFormatado(totalPagamentos),
          ),
          _linha(
            theme,
            'Saídas (estoque)',
            _contarEstoque
                ? _valorFormatado(saidaEstoque)
                : '${_valorFormatado(saidaEstoque)} (fora do cálculo)',
          ),
          const SizedBox(height: 4),
          _linhaToggleEstoque(theme),
          const Divider(height: 20),
          _linha(
            theme,
            'Saldo',
            _valorComSinal(saldo),
            destaque: true,
            negativo: saldo < 0,
          ),
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

  Widget _linhaToggleEstoque(AppTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _contarEstoque = !_contarEstoque),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _contarEstoque,
                onChanged: (valor) =>
                    setState(() => _contarEstoque = valor ?? false),
                activeColor: theme.buttonColor,
                checkColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contar custo de estoque no saldo',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoFuncionarios(AppTheme theme, Loja? loja) {
    final pagamentos = _pagamentosDoPeriodo(loja);
    final podeRegistrar =
        context.read<PdvProvider>().possoRegistrarPagamento(widget.lojaId);

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Pagamento de funcionários'),
          if (pagamentos.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum pagamento registrado no período.',
            )
          else
            for (final p in pagamentos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LinhaPagamento(
                  theme: theme,
                  pagamento: p,
                  podeExcluir: podeRegistrar,
                  onExcluir: () => _excluirPagamento(p),
                ),
              ),
          if (podeRegistrar) ...[
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
                onPressed: loja == null ? null : () => _registrarPagamento(loja),
                child: Text(
                  'Registrar pagamento',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final loja =
            context.watch<PdvProvider>().buscarPorId(widget.lojaId);

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
                      const SizedBox(height: 12),
                      _barraAcoes(theme, loja),
                      const SizedBox(height: 16),
                      Center(child: _blocoEntradas(theme)),
                      const SizedBox(height: 16),
                      Center(child: _blocoBalanco(theme, loja)),
                      const SizedBox(height: 16),
                      Center(child: _blocoFuncionarios(theme, loja)),
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

class _LinhaPagamento extends StatefulWidget {
  final AppTheme theme;
  final PagamentoFuncionario pagamento;
  final bool podeExcluir;
  final VoidCallback onExcluir;

  const _LinhaPagamento({
    required this.theme,
    required this.pagamento,
    required this.podeExcluir,
    required this.onExcluir,
  });

  @override
  State<_LinhaPagamento> createState() => _LinhaPagamentoState();
}

class _LinhaPagamentoState extends State<_LinhaPagamento> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final p = widget.pagamento;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    '${_dataHora(p.dataHora)}'
                    '${p.nomeAutor.isNotEmpty ? ' • por ${p.nomeAutor}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  if (p.descricao.trim().isNotEmpty)
                    Text(
                      p.descricao.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _valor(p.valor),
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            if (widget.podeExcluir)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.more_vert,
                    color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Excluir',
                            style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}