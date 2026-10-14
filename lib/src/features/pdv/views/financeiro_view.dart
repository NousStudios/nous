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
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/registrar_pagamento_dialog.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

enum PeriodoFinanceiro { hoje, semana, mes, tudo, personalizado }

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
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  @override
  void dispose() {
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _pesquisaComprasController.dispose();
    _scrollComprasController.dispose();
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

  List<PedidoLoja> get _vendasConcluidas {
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    return widget.pedidos.where((p) {
      if (p.status != StatusPedido.concluido) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (ate != null && p.dataHora.isAfter(ate)) return false;
      return true;
    }).toList();
  }

  List<PedidoLoja> get _pedidosAceitos {
    final desde = _inicioDoPeriodo;
    final ate = _fimDoPeriodo;
    return widget.pedidos.where((p) {
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

  Widget _botaoPeriodo(AppTheme theme, PeriodoFinanceiro p) {
    final selecionado = p == _periodo;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return _LinhaComHover(
      aoClicar: () {
        setState(() {
          _periodo = p;
          _dataInicioController.clear();
          _dataFimController.clear();
        });
      },
      builder: (hover) => Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado
              ? (hover
                  ? (theme.buttonColor != Colors.transparent
                      ? theme.buttonColor.withValues(alpha: 0.85)
                      : theme.borderColor.withValues(alpha: 0.35))
                  : fundoAtivo)
              : (hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado || hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          _rotuloPeriodoDe(p),
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado
                ? textoAtivo
                : (hover ? theme.textColor : theme.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  Widget _filtroPeriodo(AppTheme theme) {
    const double larguraBotao = 80;
    const double espaco = 8;

    const opcoes = [
      PeriodoFinanceiro.hoje,
      PeriodoFinanceiro.semana,
      PeriodoFinanceiro.mes,
      PeriodoFinanceiro.tudo,
    ];

    final botoes = opcoes.map((p) => _botaoPeriodo(theme, p)).toList();

    final larguraTotal =
        larguraBotao * botoes.length + espaco * (botoes.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
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
        ),
        const SizedBox(height: 10),
        _inputsDataPersonalizada(theme),
      ],
    );
  }

  InputDecoration _decoracaoCampoData(AppTheme theme, String dica) {
    return InputDecoration(
      hintText: dica,
      hintStyle: theme.getTextStyle(
        fontSize: 11,
        color: theme.secondaryTextColor,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: theme.cardBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: theme.textColor,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _inputsDataPersonalizada(AppTheme theme) {
    final temFiltroData = _dataInicioController.text.trim().isNotEmpty ||
        _dataFimController.text.trim().isNotEmpty;
    final dataInicioInvalida = _dataInicioController.text.length == 10 &&
        _parseData(_dataInicioController.text) == null;
    final dataFimInvalida = _dataFimController.text.length == 10 &&
        _parseData(_dataFimController.text) == null;

    void atualizarFiltro() {
      setState(() {
        if (_dataInicioController.text.isNotEmpty ||
            _dataFimController.text.isNotEmpty) {
          _periodo = PeriodoFinanceiro.personalizado;
        } else {
          _periodo = PeriodoFinanceiro.hoje;
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _dataInicioController,
                keyboardType: TextInputType.number,
                inputFormatters: [_DataInputFormatter()],
                cursorColor: theme.textColor,
                style: theme.getTextStyle(fontSize: 12),
                decoration: _decoracaoCampoData(theme, 'De: dd/mm/aaaa'),
                onChanged: (_) => atualizarFiltro(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _dataFimController,
                keyboardType: TextInputType.number,
                inputFormatters: [_DataInputFormatter()],
                cursorColor: theme.textColor,
                style: theme.getTextStyle(fontSize: 12),
                decoration: _decoracaoCampoData(theme, 'Até: dd/mm/aaaa'),
                onChanged: (_) => atualizarFiltro(),
              ),
            ),
            if (temFiltroData) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Limpar filtro de data',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _dataInicioController.clear();
                      _dataFimController.clear();
                      _periodo = PeriodoFinanceiro.hoje;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (dataInicioInvalida || dataFimInvalida) ...[
          const SizedBox(height: 4),
          Text(
            'Data inválida (use o formato dd/mm/aaaa)',
            style: theme.getTextStyle(
              fontSize: 11,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
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
      case PeriodoFinanceiro.personalizado:
        return 'Personalizado';
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
          'DRE Simples',
          carregando: false,
          aoPressionar: loja == null ? null : () => _abrirDRE(loja),
        ),
        const SizedBox(width: 8),
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
    final lucroBruto = receita - cmv;
    final margemBruta = receita > 0 ? (lucroBruto / receita * 100) : 0.0;
    final pagamentos = _pagamentosDoPeriodo(loja);
    final despesasPessoal = pagamentos.fold(0.0, (s, p) => s + p.valor);
    final resultadoLiquido = lucroBruto - despesasPessoal;
    final margemLiquida =
        receita > 0 ? (resultadoLiquido / receita * 100) : 0.0;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.textColor),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Demonstrativo de Resultado (DRE)',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              'Período: $_rotuloPeriodoAtual',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                        _linha(theme, '1. Receita Operacional Bruta',
                            _valorFormatado(receita),
                            destaque: true),
                        const SizedBox(height: 4),
                        _linha(
                          theme,
                          '2. (-) Custo dos Produtos / Insumos',
                          _valorFormatado(cmv),
                        ),
                        const Divider(height: 16),
                        _linha(
                          theme,
                          '3. (=) Lucro Operacional Bruto',
                          _valorComSinal(lucroBruto),
                          destaque: true,
                          negativo: lucroBruto < 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Margem Bruta: ${margemBruta.toStringAsFixed(1)}%',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        _linha(
                          theme,
                          '4. (-) Pagamentos a Trabalhadores',
                          _valorFormatado(despesasPessoal),
                        ),
                        const Divider(height: 16),
                        _linha(
                          theme,
                          '5. (=) Resultado Líquido do Período',
                          _valorComSinal(resultadoLiquido),
                          destaque: true,
                          negativo: resultadoLiquido < 0,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Margem Líquida: ${margemLiquida.toStringAsFixed(1)}%',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: resultadoLiquido < 0
                                  ? Colors.redAccent
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Fechar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _exportarDRE(loja);
                        },
                        icon: Icon(Icons.picture_as_pdf_outlined,
                            size: 14, color: theme.textColor),
                        label: Text(
                          'Exportar DRE em PDF',
                          style: theme.getTextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          if (aReceber > 0) ...[
            const SizedBox(height: 8),
            Text(
              'A receber (pedidos e saldo a prazo): ${_valorFormatado(aReceber)}',
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

  Widget _blocoCompras(AppTheme theme, Loja? loja) {
    final porFornecedor = _comprasPorFornecedor(loja);
    final compras = _comprasDoPeriodo(loja);
    if (porFornecedor.isEmpty && compras.isEmpty) {
      return Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: _decoracaoDoBloco(theme),
        child: Column(
          children: [
            _tituloDoBloco(theme, 'Compras do período'),
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra com custo registrado no período.',
            ),
          ],
        ),
      );
    }

    final entradas = porFornecedor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var total = 0.0;
    for (final e in entradas) {
      total += e.value;
    }

    final termo = _pesquisaComprasController.text.trim().toLowerCase();
    final comprasFiltradas = compras.where((m) {
      if (termo.isEmpty) return true;
      final nome = _nomeDoItem(loja, m).toLowerCase();
      final fornecedor = m.fornecedorNome.toLowerCase();
      final motivo = m.motivo.toLowerCase();
      return nome.contains(termo) ||
          fornecedor.contains(termo) ||
          motivo.contains(termo);
    }).toList();

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Compras do período'),
          for (final e in entradas)
            _linha(theme, e.key, _valorFormatado(e.value)),
          const Divider(height: 20),
          _linha(
            theme,
            'Total',
            _valorFormatado(total),
            destaque: true,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _pesquisaComprasController,
              onChanged: (_) => setState(() {}),
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar item ou fornecedor...',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                suffixIcon: _pesquisaComprasController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          _pesquisaComprasController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.backgroundColor.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.buttonColor),
                ),
              ),
            ),
          ),
          if (comprasFiltradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum item encontrado.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 290),
              child: Scrollbar(
                controller: _scrollComprasController,
                thumbVisibility: comprasFiltradas.length > 6,
                child: ListView.builder(
                  controller: _scrollComprasController,
                  shrinkWrap: true,
                  physics: comprasFiltradas.length > 6
                      ? const AlwaysScrollableScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: comprasFiltradas.length,
                  itemBuilder: (context, index) {
                    final compra = comprasFiltradas[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == comprasFiltradas.length - 1 ? 0 : 6,
                      ),
                      child: _LinhaCompraEstoque(
                        theme: theme,
                        movimento: compra,
                        nomeItem: _nomeDoItem(loja, compra),
                        unidade: _unidadeDoItem(loja, compra.itemId),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
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
              _barraAcoes(theme, loja),
              const SizedBox(height: 12),
              _filtroPeriodo(theme),
              const SizedBox(height: 16),
              _blocoEntradas(theme),
              const SizedBox(height: 16),
              _blocoBalanco(theme, loja),
            ];

            final conteudoColuna2 = [
              _blocoCompras(theme, loja),
              const SizedBox(height: 16),
              _blocoFuncionarios(theme, loja),
            ];

            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: const CustomAppBar(title: 'Financeiro'),
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

class _LinhaCompraEstoque extends StatefulWidget {
  final AppTheme theme;
  final MovimentoEstoque movimento;
  final String nomeItem;
  final String unidade;

  const _LinhaCompraEstoque({
    required this.theme,
    required this.movimento,
    required this.nomeItem,
    required this.unidade,
  });

  @override
  State<_LinhaCompraEstoque> createState() => _LinhaCompraEstoqueState();
}

class _LinhaCompraEstoqueState extends State<_LinhaCompraEstoque> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarQuantidade(double qtd, String unidade) {
    final qtdFormatada = qtd == qtd.roundToDouble()
        ? qtd.toInt().toString()
        : qtd.toStringAsFixed(2).replaceAll('.', ',');
    return '$qtdFormatada $unidade';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimento;
    final qtdFormatada = _formatarQuantidade(m.quantidade, widget.unidade);
    final custoUnit = _valor(m.custoUnitario);
    final detalhes = <String>[
      '$qtdFormatada x $custoUnit',
      if (m.fornecedorNome.trim().isNotEmpty) m.fornecedorNome.trim(),
      _dataHora(m.dataHora),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.nomeItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalhes.join(' • '),
                    maxLines: 1,
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
              _valor(m.custoTotal),
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaComHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaComHover> createState() => _LinhaComHoverState();
}

class _LinhaComHoverState extends State<_LinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}