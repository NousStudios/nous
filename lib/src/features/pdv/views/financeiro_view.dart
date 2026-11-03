import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/registrar_pagamento_dialog.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_demonstrativo_dre.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/seletor_periodo_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_compras_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_funcionarios_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_vendas_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_resumo_operacional_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/barra_acoes_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_entradas_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/bloco_balanco_financeiro_widget.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

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

  DateTime? _parseData(String texto) {
    final limpo = texto.trim();
    if (limpo.length != 10) return null;
    final partes = limpo.split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    if (ano < 1900 || ano > 2100 || mes < 1 || mes > 12 || dia < 1 || dia > 31) {
      return null;
    }
    try {
      final data = DateTime(ano, mes, dia);
      if (data.day != dia || data.month != mes || data.year != ano) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  String _formatarDataBR(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  DateTime? get _inicioDoPeriodo {
    if (_periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = _parseData(_dataInicioController.text);
      final dFim = _parseData(_dataFimController.text);
      if (dInicio != null && dFim != null) {
        final inicioReal = dInicio.isBefore(dFim) ? dInicio : dFim;
        return DateTime(inicioReal.year, inicioReal.month, inicioReal.day, 0, 0, 0);
      } else if (dInicio != null) {
        return DateTime(dInicio.year, dInicio.month, dInicio.day, 0, 0, 0);
      } else if (dFim != null) {
        return DateTime(dFim.year, dFim.month, dFim.day, 0, 0, 0);
      }
      return null;
    }
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
      case PeriodoFinanceiro.personalizado:
        return null;
    }
  }

  DateTime? get _fimDoPeriodo {
    if (_periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = _parseData(_dataInicioController.text);
      final dFim = _parseData(_dataFimController.text);
      if (dInicio != null && dFim != null) {
        final fimReal = dFim.isAfter(dInicio) ? dFim : dInicio;
        return DateTime(fimReal.year, fimReal.month, fimReal.day, 23, 59, 59, 999);
      } else if (dInicio != null) {
        return DateTime(dInicio.year, dInicio.month, dInicio.day, 23, 59, 59, 999);
      } else if (dFim != null) {
        return DateTime(dFim.year, dFim.month, dFim.day, 23, 59, 59, 999);
      }
      return null;
    }
    return null;
  }

  String get _rotuloPeriodoAtual {
    if (_periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = _parseData(_dataInicioController.text);
      final dFim = _parseData(_dataFimController.text);
      if (dInicio != null && dFim != null) {
        final d1 = dInicio.isBefore(dFim) ? dInicio : dFim;
        final d2 = dFim.isAfter(dInicio) ? dFim : dInicio;
        if (d1.year == d2.year && d1.month == d2.month && d1.day == d2.day) {
          return _formatarDataBR(d1);
        }
        return '${_formatarDataBR(d1)} a ${_formatarDataBR(d2)}';
      } else if (dInicio != null) {
        return _formatarDataBR(dInicio);
      } else if (dFim != null) {
        return _formatarDataBR(dFim);
      }
      return 'Personalizado';
    }
    switch (_periodo) {
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

  bool get _ehDiaUnico {
    if (_periodo == PeriodoFinanceiro.hoje) return true;
    if (_periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = _parseData(_dataInicioController.text);
      final dFim = _parseData(_dataFimController.text);
      if (dInicio != null && dFim != null) {
        return dInicio.year == dFim.year &&
            dInicio.month == dFim.month &&
            dInicio.day == dFim.day;
      }
      return dInicio != null || dFim != null;
    }
    return false;
  }

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

  List<PagamentoFuncionario> _pagamentosDoPeriodo(Loja? loja) {
    if (loja == null) return [];
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    final lista = loja.pagamentosFuncionarios.where((p) {
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  List<MovimentoEstoque> _movimentosDoPeriodo(Loja? loja) {
    if (loja == null) return [];
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    final lista = loja.movimentosEstoque.where((m) {
      if (desde != null && m.dataHora.isBefore(desde)) return false;
      if (ate != null && m.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  double _saidaEstoqueDoPeriodo(Loja? loja) {
    var soma = 0.0;
    for (final m in _movimentosDoPeriodo(loja)) {
      if (!m.ehEntrada) continue;
      soma += m.custoTotal;
    }
    return soma;
  }

  Map<String, double> _comprasPorFornecedor(Loja? loja) {
    final mapa = <String, double>{};
    for (final m in _movimentosDoPeriodo(loja)) {
      if (!m.ehEntrada) continue;
      if (m.custoTotal <= 0) continue;
      final nome =
          m.fornecedorNome.trim().isEmpty ? 'Sem fornecedor' : m.fornecedorNome;
      mapa[nome] = (mapa[nome] ?? 0) + m.custoTotal;
    }
    return mapa;
  }

  List<MovimentoEstoque> _comprasDoPeriodo(Loja? loja) {
    if (loja == null) return [];
    return _movimentosDoPeriodo(loja).where((m) => m.ehEntrada).toList();
  }

  ItemLoja? _buscarItem(Loja? loja, String itemId) {
    if (loja == null) return null;
    for (final item in loja.itensLoja) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  String _nomeDoItem(Loja? loja, MovimentoEstoque m) {
    final item = _buscarItem(loja, m.itemId);
    if (item != null && item.nome.trim().isNotEmpty) {
      return item.nome.trim();
    }
    if (m.motivo.trim().isNotEmpty) {
      return m.motivo.trim();
    }
    return 'Item';
  }

  String _unidadeDoItem(Loja? loja, String itemId) {
    final item = _buscarItem(loja, itemId);
    return item?.unidadeBase.name ?? 'un';
  }

  double get _totalEntradas =>
      _formasDePagamento.fold(0.0, (soma, f) => soma + _entradasPorForma(f));

  double get _totalAReceber {
    final aReceberPedidosAceitos =
        _pedidosAceitos.fold(0.0, (soma, p) => soma + p.valor);
    final aReceberPrazoConcluidas = _vendasConcluidas
        .where((p) => p.aPrazoEmAberto)
        .fold(0.0, (soma, p) => soma + p.valorRestante);
    return aReceberPedidosAceitos + aReceberPrazoConcluidas;
  }

  double _entradasPorForma(String forma) {
    var soma = 0.0;
    final ehPrazo = forma.trim().toLowerCase() == 'à prazo' ||
        forma.trim().toLowerCase() == 'a prazo';
    for (final venda in _vendasConcluidas) {
      for (final p in venda.todosPagamentos) {
        final pEhPrazo = p.forma.trim().toLowerCase() == 'à prazo' ||
            p.forma.trim().toLowerCase() == 'a prazo' ||
            p.forma.toLowerCase().contains('prazo');
        if (ehPrazo && pEhPrazo) {
          soma += p.valor;
        } else if (!ehPrazo &&
            !pEhPrazo &&
            p.forma.trim().toLowerCase() == forma.trim().toLowerCase()) {
          soma += p.valor;
        }
      }
    }
    return soma;
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

  double _totalPagamentosPeriodo(Loja? loja) {
    if (loja == null) return 0.0;
    return _pagamentosDoPeriodo(loja).fold(0.0, (soma, p) => soma + p.valor);
  }

  double _saldoPeriodo(Loja? loja) {
    final entradas = _totalEntradas;
    final saidaEstoque = _saidaEstoqueDoPeriodo(loja);
    final totalPagamentos = _totalPagamentosPeriodo(loja);
    final saidas = totalPagamentos + (_contarEstoque ? saidaEstoque : 0);
    return entradas - saidas;
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

  Future<void> _exportarDRE(Loja loja) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final receita = _totalEntradas;
      final cmv = _saidaEstoqueDoPeriodo(loja);
      final lucroBruto = receita - cmv;
      final margemBruta = receita > 0 ? (lucroBruto / receita * 100) : 0.0;
      final pagamentos = _pagamentosDoPeriodo(loja);
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

  void _abrirDRE(Loja loja) {
    final theme = ThemeController.currentTheme.value;
    final receita = _totalEntradas;
    final cmv = _saidaEstoqueDoPeriodo(loja);
    final pagamentos = _pagamentosDoPeriodo(loja);
    final despesasPessoal = pagamentos.fold(0.0, (s, p) => s + p.valor);

    DialogDemonstrativoDRE.mostrar(
      context,
      theme: theme,
      rotuloPeriodo: _rotuloPeriodoAtual,
      receita: receita,
      cmv: cmv,
      despesasPessoal: despesasPessoal,
      formatarValor: _valorFormatado,
      formatarValorComSinal: _valorComSinal,
      onExportarPdf: () => _exportarDRE(loja),
    );
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
    final baseRateio = entradas - (_contarEstoque ? saidaEstoque : 0);
    final disponivel = baseRateio - totalPagamentos;
    final numeroMembros = loja.membros.isEmpty ? 0 : loja.membros.length;
    final sugestao = numeroMembros == 0
        ? 0.0
        : (baseRateio <= 0 ? 0.0 : baseRateio / numeroMembros);

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

    final delta = sugestao > 0 ? (resultado.valor - sugestao) : 0.0;
    final detalheDelta = delta.abs() < 0.01
        ? 'valor igual à sugestão de divisão'
        : (delta > 0
            ? '+R\$ ${delta.toStringAsFixed(2).replaceAll('.', ',')} acima da sugestão'
            : '-R\$ ${(-delta).toStringAsFixed(2).replaceAll('.', ',')} abaixo da sugestão');

    final acao = RegistroAcao(
      id: gerarIdUnico(),
      dataHora: DateTime.now(),
      tipo: TipoAcao.pagamentoFuncionarioRegistrado,
      descricao:
          'Pagamento de ${_valorFormatado(resultado.valor)} para "${resultado.nome}" ($detalheDelta)',
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
      emailAutor: auth.emailAtivo ?? '',
    );
    context.read<PdvProvider>().registrarAcao(widget.lojaId, acao);
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
                style: theme.getTextStyle(color: theme.dangerColor),
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

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta != null) {
      final acao = RegistroAcao(
        id: gerarIdUnico(),
        dataHora: DateTime.now(),
        tipo: TipoAcao.pagamentoFuncionarioRemovido,
        descricao:
            'Pagamento de ${_valorFormatado(p.valor)} para "${p.nome}" excluído',
        cpfAutor: conta.cpf,
        nomeAutor: conta.nome,
        emailAutor: auth.emailAtivo ?? '',
      );
      context.read<PdvProvider>().registrarAcao(widget.lojaId, acao);
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

            final conteudoColuna1 = [
              BarraAcoesFinanceiroWidget(
                theme: theme,
                loja: loja,
                imprimindo: _imprimindo,
                exportando: _exportando,
                onAbrirDRE: loja == null ? null : () => _abrirDRE(loja),
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
                parseData: _parseData,
                formatarDataBR: _formatarDataBR,
              ),
              const SizedBox(height: 16),
              BlocoResumoOperacionalWidget(
                theme: theme,
                loja: loja,
                periodo: _periodo,
                desde: _inicioDoPeriodo,
                ate: _fimDoPeriodo,
                ehDiaUnico: _ehDiaUnico,
                rotuloPeriodoAtual: _rotuloPeriodoAtual,
                decoracaoBloco: _decoracaoDoBloco(theme),
                valorFormatado: _valorFormatado,
                entradasPorForma: _entradasPorForma,
              ),
              const SizedBox(height: 16),
              BlocoEntradasFinanceiroWidget(
                theme: theme,
                formasDePagamento: _formasDePagamento,
                entradasPorForma: _entradasPorForma,
                totalEntradas: _totalEntradas,
                valorFormatado: _valorFormatado,
                decoracaoBloco: _decoracaoDoBloco,
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
              ),
              const SizedBox(height: 16),
              BlocoBalancoFinanceiroWidget(
                theme: theme,
                entradas: _totalEntradas,
                totalPagamentos: _totalPagamentosPeriodo(loja),
                saidaEstoque: _saidaEstoqueDoPeriodo(loja),
                contarEstoque: _contarEstoque,
                onToggleContarEstoque: (valor) =>
                    setState(() => _contarEstoque = valor),
                saldo: _saldoPeriodo(loja),
                aReceber: _totalAReceber,
                valorFormatado: _valorFormatado,
                valorComSinal: _valorComSinal,
                decoracaoBloco: _decoracaoDoBloco,
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
              ),
            ];

            final conteudoColuna2 = [
              BlocoComprasFinanceiroWidget(
                theme: theme,
                loja: loja,
                porFornecedor: _comprasPorFornecedor(loja),
                compras: _comprasDoPeriodo(loja),
                pesquisaComprasController: _pesquisaComprasController,
                scrollComprasController: _scrollComprasController,
                decoracaoBloco: _decoracaoDoBloco(theme),
                tituloDoBloco: _tituloDoBloco,
                linha: _linha,
                valorFormatado: _valorFormatado,
                nomeDoItem: _nomeDoItem,
                unidadeDoItem: _unidadeDoItem,
                onChangedPesquisa: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              BlocoVendasFinanceiroWidget(
                theme: theme,
                lojaId: widget.lojaId,
                vendas: _obterVendasFiltradas(loja),
                pesquisaVendasController: _pesquisaVendasController,
                formaFiltroVendas: _formaFiltroVendas,
                formasDePagamento: _formasDePagamento,
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
                pagamentos: _pagamentosDoPeriodo(loja),
                podeRegistrar: context.read<PdvProvider>().possoRegistrarPagamento(widget.lojaId),
                decoracaoBloco: _decoracaoDoBloco(theme),
                tituloDoBloco: _tituloDoBloco,
                onExcluirPagamento: _excluirPagamento,
                onRegistrarPagamento: _registrarPagamento,
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
