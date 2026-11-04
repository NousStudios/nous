import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_demonstrativo_dre.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/seletor_periodo_financeiro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/registrar_pagamento_dialog.dart';
import 'package:provider/provider.dart';

class FinanceiroOperacoesHelper {
  static const List<String> formasDePagamento = [
    'Pix',
    'Dinheiro',
    'Débito',
    'Crédito',
    'Voucher',
    'À Prazo',
  ];

  static DateTime? parseData(String texto) {
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

  static String formatarDataBR(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  static DateTime? obterInicioDoPeriodo({
    required PeriodoFinanceiro periodo,
    required String dataInicioTexto,
    required String dataFimTexto,
  }) {
    if (periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = parseData(dataInicioTexto);
      final dFim = parseData(dataFimTexto);
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
    switch (periodo) {
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

  static DateTime? obterFimDoPeriodo({
    required PeriodoFinanceiro periodo,
    required String dataInicioTexto,
    required String dataFimTexto,
  }) {
    if (periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = parseData(dataInicioTexto);
      final dFim = parseData(dataFimTexto);
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

  static String obterRotuloPeriodoAtual({
    required PeriodoFinanceiro periodo,
    required String dataInicioTexto,
    required String dataFimTexto,
  }) {
    if (periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = parseData(dataInicioTexto);
      final dFim = parseData(dataFimTexto);
      if (dInicio != null && dFim != null) {
        final d1 = dInicio.isBefore(dFim) ? dInicio : dFim;
        final d2 = dFim.isAfter(dInicio) ? dFim : dInicio;
        if (d1.year == d2.year && d1.month == d2.month && d1.day == d2.day) {
          return formatarDataBR(d1);
        }
        return '${formatarDataBR(d1)} a ${formatarDataBR(d2)}';
      } else if (dInicio != null) {
        return formatarDataBR(dInicio);
      } else if (dFim != null) {
        return formatarDataBR(dFim);
      }
      return 'Personalizado';
    }
    switch (periodo) {
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

  static bool verificarEhDiaUnico({
    required PeriodoFinanceiro periodo,
    required String dataInicioTexto,
    required String dataFimTexto,
  }) {
    if (periodo == PeriodoFinanceiro.hoje) return true;
    if (periodo == PeriodoFinanceiro.personalizado) {
      final dInicio = parseData(dataInicioTexto);
      final dFim = parseData(dataFimTexto);
      if (dInicio != null && dFim != null) {
        return dInicio.year == dFim.year &&
            dInicio.month == dFim.month &&
            dInicio.day == dFim.day;
      }
      return dInicio != null || dFim != null;
    }
    return false;
  }

  static String valorFormatado(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  static String valorComSinal(double valor) {
    if (valor < 0) return '-${valorFormatado(-valor)}';
    return valorFormatado(valor);
  }

  static double calcularEntradasPorForma(List<PedidoLoja> vendasConcluidas, String forma) {
    var soma = 0.0;
    final ehPrazo = forma.trim().toLowerCase() == 'à prazo' ||
        forma.trim().toLowerCase() == 'a prazo';
    for (final venda in vendasConcluidas) {
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

  static double calcularTotalEntradas(List<PedidoLoja> vendasConcluidas) {
    return formasDePagamento.fold(
      0.0,
      (soma, f) => soma + calcularEntradasPorForma(vendasConcluidas, f),
    );
  }

  static double calcularTotalAReceber({
    required List<PedidoLoja> pedidosAceitos,
    required List<PedidoLoja> vendasConcluidas,
  }) {
    final aReceberPedidosAceitos =
        pedidosAceitos.fold(0.0, (soma, p) => soma + p.valor);
    final aReceberPrazoConcluidas = vendasConcluidas
        .where((p) => p.aPrazoEmAberto)
        .fold(0.0, (soma, p) => soma + p.valorRestante);
    return aReceberPedidosAceitos + aReceberPrazoConcluidas;
  }

  static List<PagamentoFuncionario> obterPagamentosDoPeriodo({
    required Loja? loja,
    required DateTime? desde,
    required DateTime? ate,
  }) {
    if (loja == null) return [];
    final lista = loja.pagamentosFuncionarios.where((p) {
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  static List<MovimentoEstoque> obterMovimentosDoPeriodo({
    required Loja? loja,
    required DateTime? desde,
    required DateTime? ate,
  }) {
    if (loja == null) return [];
    final lista = loja.movimentosEstoque.where((m) {
      if (desde != null && m.dataHora.isBefore(desde)) return false;
      if (ate != null && m.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  static double obterSaidaEstoqueDoPeriodo({
    required Loja? loja,
    required DateTime? desde,
    required DateTime? ate,
  }) {
    var soma = 0.0;
    for (final m in obterMovimentosDoPeriodo(loja: loja, desde: desde, ate: ate)) {
      if (!m.ehEntrada) continue;
      soma += m.custoTotal;
    }
    return soma;
  }

  static Map<String, double> obterComprasPorFornecedor({
    required Loja? loja,
    required DateTime? desde,
    required DateTime? ate,
  }) {
    final mapa = <String, double>{};
    for (final m in obterMovimentosDoPeriodo(loja: loja, desde: desde, ate: ate)) {
      if (!m.ehEntrada) continue;
      if (m.custoTotal <= 0) continue;
      final nome =
          m.fornecedorNome.trim().isEmpty ? 'Sem fornecedor' : m.fornecedorNome;
      mapa[nome] = (mapa[nome] ?? 0) + m.custoTotal;
    }
    return mapa;
  }

  static ItemLoja? buscarItem(Loja? loja, String itemId) {
    if (loja == null) return null;
    for (final item in loja.itensLoja) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  static String nomeDoItem(Loja? loja, MovimentoEstoque m) {
    final item = buscarItem(loja, m.itemId);
    if (item != null && item.nome.trim().isNotEmpty) {
      return item.nome.trim();
    }
    if (m.motivo.trim().isNotEmpty) {
      return m.motivo.trim();
    }
    return 'Item';
  }

  static String unidadeDoItem(Loja? loja, String itemId) {
    final item = buscarItem(loja, itemId);
    return item?.unidadeBase.name ?? 'un';
  }

  static void abrirDRE({
    required BuildContext context,
    required Loja loja,
    required String rotuloPeriodo,
    required double receita,
    required double cmv,
    required List<PagamentoFuncionario> pagamentos,
    required VoidCallback onExportarPdf,
  }) {
    final theme = ThemeController.currentTheme.value;
    final despesasPessoal = pagamentos.fold(0.0, (s, p) => s + p.valor);

    DialogDemonstrativoDRE.mostrar(
      context,
      theme: theme,
      rotuloPeriodo: rotuloPeriodo,
      receita: receita,
      cmv: cmv,
      despesasPessoal: despesasPessoal,
      formatarValor: valorFormatado,
      formatarValorComSinal: valorComSinal,
      onExportarPdf: onExportarPdf,
    );
  }

  static Future<void> registrarPagamento({
    required BuildContext context,
    required Loja loja,
    required double totalEntradas,
    required double saidaEstoque,
    required bool contarEstoque,
    required List<PagamentoFuncionario> pagamentos,
  }) async {
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta == null) return;

    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final baseRateio = totalEntradas - (contarEstoque ? saidaEstoque : 0);
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

    if (!context.mounted) return;
    context
        .read<PdvProvider>()
        .adicionarPagamentoFuncionario(loja.id, pagamento);

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
          'Pagamento de ${valorFormatado(resultado.valor)} para "${resultado.nome}" ($detalheDelta)',
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
      emailAutor: auth.emailAtivo ?? '',
    );
    context.read<PdvProvider>().registrarAcao(loja.id, acao);
  }

  static Future<void> excluirPagamento({
    required BuildContext context,
    required String lojaId,
    required PagamentoFuncionario p,
  }) async {
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
            'Excluir o pagamento de ${p.nome} (${valorFormatado(p.valor)})? '
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
    if (!context.mounted) return;
    context
        .read<PdvProvider>()
        .removerPagamentoFuncionario(lojaId, p.id);

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta != null) {
      final acao = RegistroAcao(
        id: gerarIdUnico(),
        dataHora: DateTime.now(),
        tipo: TipoAcao.pagamentoFuncionarioRemovido,
        descricao:
            'Pagamento de ${valorFormatado(p.valor)} para "${p.nome}" excluído',
        cpfAutor: conta.cpf,
        nomeAutor: conta.nome,
        emailAutor: auth.emailAtivo ?? '',
      );
      context.read<PdvProvider>().registrarAcao(lojaId, acao);
    }
  }
}
