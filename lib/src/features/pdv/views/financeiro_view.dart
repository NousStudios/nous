import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/seletor_periodo_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_compras_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_funcionarios_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_vendas_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_resumo_operacional_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/barra_acoes_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_entradas_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_balanco_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/financeiro_operacoes_helper.dart';

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
  final _pesquisaComprasController = TextEditingController();
  final _scrollComprasController = ScrollController();
  final _pesquisaVendasController = TextEditingController();
  String? _formaFiltroVendas;
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  @override
  void dispose() {
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _pesquisaComprasController.dispose();
    _scrollComprasController.dispose();
    _pesquisaVendasController.dispose();
    super.dispose();
  }

  DateTime? get _inicioDoPeriodo =>
      FinanceiroOperacoesHelper.obterInicioDoPeriodo(
        periodo: _periodo,
        dataInicioTexto: _dataInicioController.text,
        dataFimTexto: _dataFimController.text,
      );

  DateTime? get _fimDoPeriodo =>
      FinanceiroOperacoesHelper.obterFimDoPeriodo(
        periodo: _periodo,
        dataInicioTexto: _dataInicioController.text,
        dataFimTexto: _dataFimController.text,
      );

  String get _rotuloPeriodoAtual =>
      FinanceiroOperacoesHelper.obterRotuloPeriodoAtual(
        periodo: _periodo,
        dataInicioTexto: _dataInicioController.text,
        dataFimTexto: _dataFimController.text,
      );

  bool get _ehDiaUnico =>
      FinanceiroOperacoesHelper.verificarEhDiaUnico(
        periodo: _periodo,
        dataInicioTexto: _dataInicioController.text,
        dataFimTexto: _dataFimController.text,
      );

  List<PedidoLoja> get _vendasConcluidas {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final todos = loja?.pedidosLoja ?? widget.pedidos;
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    return todos.where((p) {
      if (p.status != StatusPedido.concluido) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
  }

  List<PedidoLoja> get _pedidosAceitos {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final todos = loja?.pedidosLoja ?? widget.pedidos;
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    return todos.where((p) {
      if (p.status != StatusPedido.aceito) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
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

  Future<void> _imprimir(Loja loja) async {
    if (_imprimindo) return;
    setState(() => _imprimindo = true);
    try {
      final desde = _inicioDoPeriodo;
      final ate = _fimDoPeriodo;
      await ImpressaoService.imprimirFinanceiro(
        config: loja.configuracoesImpressora,
        loja: loja,
        periodo: _rotuloPeriodoAtual,
        vendas: _vendasConcluidas,
        pedidosAceitos: _pedidosAceitos,
        pagamentos: FinanceiroOperacoesHelper.obterPagamentosDoPeriodo(loja: loja, desde: desde, ate: ate),
        movimentos: FinanceiroOperacoesHelper.obterMovimentosDoPeriodo(loja: loja, desde: desde, ate: ate),
        saidaEstoque: FinanceiroOperacoesHelper.obterSaidaEstoqueDoPeriodo(loja: loja, desde: desde, ate: ate),
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
      final desde = _inicioDoPeriodo;
      final ate = _fimDoPeriodo;
      final caminho = await ImpressaoService.exportarFinanceiroPDF(
        loja: loja,
        periodo: _rotuloPeriodoAtual,
        rodape: loja.configuracoesImpressora.rodape,
        vendas: _vendasConcluidas,
        pedidosAceitos: _pedidosAceitos,
        pagamentos: FinanceiroOperacoesHelper.obterPagamentosDoPeriodo(loja: loja, desde: desde, ate: ate),
        movimentos: FinanceiroOperacoesHelper.obterMovimentosDoPeriodo(loja: loja, desde: desde, ate: ate),
        saidaEstoque: FinanceiroOperacoesHelper.obterSaidaEstoqueDoPeriodo(loja: loja, desde: desde, ate: ate),
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

  Future<void> _exportarDRE(Loja loja) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final desde = _inicioDoPeriodo;
      final ate = _fimDoPeriodo;
      final receita = FinanceiroOperacoesHelper.calcularTotalEntradas(_vendasConcluidas);
      final cmv = FinanceiroOperacoesHelper.obterSaidaEstoqueDoPeriodo(loja: loja, desde: desde, ate: ate);
      final lucroBruto = receita - cmv;
      final margemBruta = receita > 0 ? (lucroBruto / receita * 100) : 0.0;
      final pagamentos = FinanceiroOperacoesHelper.obterPagamentosDoPeriodo(loja: loja, desde: desde, ate: ate);
      final despesasPessoal = pagamentos.fold(0.0, (s, p) => s + p.valor);
      final resultadoLiquido = lucroBruto - despesasPessoal;
      final margemLiquida =
          receita > 0 ? (resultadoLiquido / receita * 100) : 0.0;

      final caminho = await ImpressaoService.exportarDREPDF(
        loja: loja,
        periodo: _rotuloPeriodoAtual,
        receita: receita,
        cmv: cmv,
        lucroBruto: lucroBruto,
        margemBruta: margemBruta,
        despesasPessoal: despesasPessoal,
        resultadoLiquido: resultadoLiquido,
        margemLiquida: margemLiquida,
        rodape: loja.configuracoesImpressora.rodape,
      );
      if (!mounted) return;
      if (caminho == null) {
        _snack('Exportação da DRE cancelada.');
      } else {
        _snack('PDF da DRE salvo em: $caminho');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao exportar DRE: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  List<PedidoLoja> _obterVendasFiltradas(Loja? loja) {
    final todosPedidos = loja?.pedidosLoja ?? widget.pedidos;
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    final termo = _pesquisaVendasController.text.trim().toLowerCase().replaceAll('#', '');

    return todosPedidos.where((p) {
      if (p.status == StatusPedido.cancelado) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      if (_formaFiltroVendas != null &&
          !p.todosPagamentos.any((pag) => pag.forma == _formaFiltroVendas)) {
        return false;
      }
      if (termo.isEmpty) return true;
      final numero = p.numero.toString().padLeft(4, '0');
      final formas = p.todosPagamentos
          .map((pag) => pag.forma.toLowerCase())
          .join(' ');
      return p.clienteNome.toLowerCase().contains(termo) ||
          p.produtoNome.toLowerCase().contains(termo) ||
          formas.contains(termo) ||
          p.comanda.toLowerCase().contains(termo) ||
          numero.contains(termo);
    }).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f11): () {
          JanelaWindowsService.alternarTelaCheia();
        },
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            final loja =
                context.watch<PdvProvider>().buscarPorId(widget.lojaId);
            final larguraDaTela = MediaQuery.sizeOf(context).width;
            final expandido =
                (loja?.layoutExpandido ?? false) && larguraDaTela > 850;

            final desde = _inicioDoPeriodo;
            final ate = _fimDoPeriodo;
            final vendasConcluidas = _vendasConcluidas;
            final totalEntradas =
                FinanceiroOperacoesHelper.calcularTotalEntradas(vendasConcluidas);

            final gastosDoPeriodo = (loja?.gastosDiarios ?? []).where((g) {
              if (desde != null && g.dataHora.isBefore(desde)) return false;
              if (ate != null && g.dataHora.isAfter(ate)) return false;
              return true;
            }).toList();
            final saidaEstoque =
                FinanceiroOperacoesHelper.obterSaidaEstoqueDoPeriodo(
                    loja: loja, desde: desde, ate: ate);
            final pagamentos =
                FinanceiroOperacoesHelper.obterPagamentosDoPeriodo(
                    loja: loja, desde: desde, ate: ate);
            final totalPagamentos =
                pagamentos.fold(0.0, (soma, p) => soma + p.valor);
            final saldo = totalEntradas -
                (totalPagamentos + (_contarEstoque ? saidaEstoque : 0));
            final totalAReceber =
                FinanceiroOperacoesHelper.calcularTotalAReceber(
              pedidosAceitos: _pedidosAceitos,
              vendasConcluidas: vendasConcluidas,
            );

            final conteudoColuna1 = [
              BarraAcoesFinanceiroWidget(
                theme: theme,
                loja: loja,
                imprimindo: _imprimindo,
                exportando: _exportando,
                onAbrirDRE: loja == null
                    ? null
                    : () => FinanceiroOperacoesHelper.abrirDRE(
                          context: context,
                          loja: loja,
                          rotuloPeriodo: _rotuloPeriodoAtual,
                          receita: totalEntradas,
                          cmv: saidaEstoque,
                          pagamentos: pagamentos,
                          onExportarPdf: () => _exportarDRE(loja),
                        ),
                onImprimir: loja == null ? null : () => _imprimir(loja),
                onExportar: loja == null ? null : () => _exportar(loja),
              ),
              const SizedBox(height: 12),
              SeletorPeriodoFinanceiroWidget(
                theme: theme,
                periodo: _periodo,
                dataInicioController: _dataInicioController,
                dataFimController: _dataFimController,
                onPeriodoAlterado: (novo) => setState(() => _periodo = novo),
                parseData: FinanceiroOperacoesHelper.parseData,
                formatarDataBR: FinanceiroOperacoesHelper.formatarDataBR,
              ),
              const SizedBox(height: 16),
              BlocoResumoOperacionalWidget(
                theme: theme,
                loja: loja,
                periodo: _periodo,
                desde: desde,
                ate: ate,
                ehDiaUnico: _ehDiaUnico,
                rotuloPeriodoAtual: _rotuloPeriodoAtual,
                decoracaoBloco: _decoracaoDoBloco(theme),
                valorFormatado: FinanceiroOperacoesHelper.valorFormatado,
                entradasPorForma: (f) =>
                    FinanceiroOperacoesHelper.calcularEntradasPorForma(
                        vendasConcluidas, f),
                gastosDiarios: gastosDoPeriodo,
              ),
              const SizedBox(height: 16),
              BlocoEntradasFinanceiroWidget(
                theme: theme,
                formasDePagamento: FinanceiroOperacoesHelper.formasDePagamento,
                entradasPorForma: (f) =>
                    FinanceiroOperacoesHelper.calcularEntradasPorForma(
                        vendasConcluidas, f),
                totalEntradas: totalEntradas,
                valorFormatado: FinanceiroOperacoesHelper.valorFormatado,
                decoracaoBloco: _decoracaoDoBloco,
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
              ),
              const SizedBox(height: 16),
              BlocoBalancoFinanceiroWidget(
                theme: theme,
                entradas: totalEntradas,
                totalPagamentos: totalPagamentos,
                saidaEstoque: saidaEstoque,
                contarEstoque: _contarEstoque,
                onToggleContarEstoque: (valor) =>
                    setState(() => _contarEstoque = valor),
                saldo: saldo,
                aReceber: totalAReceber,
                valorFormatado: FinanceiroOperacoesHelper.valorFormatado,
                valorComSinal: FinanceiroOperacoesHelper.valorComSinal,
                decoracaoBloco: _decoracaoDoBloco,
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
              ),
            ];

            final conteudoColuna2 = [
              BlocoComprasFinanceiroWidget(
                theme: theme,
                loja: loja,
                porFornecedor:
                    FinanceiroOperacoesHelper.obterComprasPorFornecedor(
                        loja: loja, desde: desde, ate: ate),
                compras: FinanceiroOperacoesHelper.obterMovimentosDoPeriodo(
                        loja: loja, desde: desde, ate: ate)
                    .where((m) => m.ehEntrada)
                    .toList(),
                pesquisaComprasController: _pesquisaComprasController,
                scrollComprasController: _scrollComprasController,
                decoracaoBloco: _decoracaoDoBloco(theme),
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
                valorFormatado: FinanceiroOperacoesHelper.valorFormatado,
                nomeDoItem: (lj, m) =>
                    FinanceiroOperacoesHelper.nomeDoItem(lj, m),
                unidadeDoItem: (lj, id) =>
                    FinanceiroOperacoesHelper.unidadeDoItem(lj, id),
                onChangedPesquisa: () => setState(() {}),
                gastosDiarios: gastosDoPeriodo,
                gastosFixos: loja?.gastosFixos ?? const [],
                membros: loja?.membros ?? const [],
                onAdicionarGasto: (novo) {
                  context
                      .read<PdvProvider>()
                      .adicionarGastoDiario(widget.lojaId, novo);
                },
                onRemoverGasto: (idGasto) {
                  context
                      .read<PdvProvider>()
                      .removerGastoDiario(widget.lojaId, idGasto);
                },
                onAdicionarGastoFixo: (gf) {
                  context
                      .read<PdvProvider>()
                      .adicionarGastoFixo(widget.lojaId, gf);
                },
                onRemoverGastoFixo: (idGf) {
                  context
                      .read<PdvProvider>()
                      .removerGastoFixo(widget.lojaId, idGf);
                },
                onAlternarAtivoGastoFixo: (idGf) {
                  context
                      .read<PdvProvider>()
                      .alternarAtivoGastoFixo(widget.lojaId, idGf);
                },
              ),
              const SizedBox(height: 16),
              BlocoVendasFinanceiroWidget(
                theme: theme,
                lojaId: widget.lojaId,
                vendas: _obterVendasFiltradas(loja),
                pesquisaVendasController: _pesquisaVendasController,
                formaFiltroVendas: _formaFiltroVendas,
                formasDePagamento: FinanceiroOperacoesHelper.formasDePagamento,
                decoracaoBloco: _decoracaoDoBloco(theme),
                tituloDoBloco: _tituloDoBloco,
                onAlternarFormaPagamento: (forma) => setState(() {
                  _formaFiltroVendas =
                      _formaFiltroVendas == forma ? null : forma;
                }),
                onChangedPesquisa: () => setState(() {}),
                contaAtual: context.read<AuthProvider>().contaAtual,
                emailAtivo: context.read<AuthProvider>().emailAtivo ?? '',
              ),
              const SizedBox(height: 16),
              BlocoFuncionariosFinanceiroWidget(
                theme: theme,
                loja: loja,
                pagamentos: pagamentos,
                cpfLogado: context.read<AuthProvider>().contaAtual?.cpf ?? '',
                podeRegistrar: context
                    .read<PdvProvider>()
                    .possoRegistrarPagamento(widget.lojaId),
                decoracaoBloco: _decoracaoDoBloco(theme),
                tituloDoBloco: _tituloDoBloco,
                onExcluirPagamento: (p) =>
                    FinanceiroOperacoesHelper.excluirPagamento(
                  context: context,
                  lojaId: widget.lojaId,
                  p: p,
                ),
                onRegistrarPagamento: (lj) =>
                    FinanceiroOperacoesHelper.registrarPagamento(
                  context: context,
                  loja: lj,
                  totalEntradas: totalEntradas,
                  saidaEstoque: saidaEstoque,
                  contarEstoque: _contarEstoque,
                  pagamentos: pagamentos,
                ),
              ),
            ];

            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: CustomAppBar(
                title: 'Financeiro',
                lojaId: widget.lojaId,
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: expandido ? 1300 : 500,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: expandido
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: conteudoColuna1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: conteudoColuna2,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...conteudoColuna1,
                                const SizedBox(height: 16),
                                ...conteudoColuna2,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
