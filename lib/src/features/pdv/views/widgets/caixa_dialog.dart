import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/painel_abertura_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/painel_historico_turnos.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/painel_turno_aberto.dart';
import 'package:nous/src/features/pdv/views/widgets/detalhes_turno_caixa_dialog.dart';

class CaixaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    String? lojaId,
    required String lojaNome,
    required String lojaCnpj,
    required TurnoCaixa? turnoAberto,
    List<TurnoCaixa> turnosAnteriores = const [],
    required List<PedidoLoja> pedidosLoja,
    required ConfiguracoesImpressora configuracoesImpressora,
    required Future<void> Function(double saldoInicial) aoAbrirCaixa,
    required Future<void> Function(
      TipoMovimentoCaixa tipo,
      double valor,
      String motivo,
    ) aoRegistrarMovimento,
    required Future<void> Function(
      double saldoInformado,
      String observacao,
    ) aoFecharCaixa,
    Future<void> Function(String turnoId)? aoExcluirTurno,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f11): () {
              JanelaWindowsService.alternarTelaCheia();
            },
          },
          child: Consumer<PdvProvider>(
            builder: (ctx, pdv, child) {
              final expandido = pdv.layoutDesktopAtivo(lojaId);
              final larguraTela = MediaQuery.sizeOf(ctx).width;
              final maxWidth = expandido
                  ? (larguraTela > 1150 ? 1050.0 : larguraTela * 0.92)
                  : 500.0;

              return Dialog(
                backgroundColor: theme.cardBackgroundColor,
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.borderColor),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _CaixaConteudo(
                    theme: theme,
                    expandido: expandido,
                    lojaId: lojaId,
                    lojaNome: lojaNome,
                    lojaCnpj: lojaCnpj,
                    turnoAberto: turnoAberto,
                    turnosAnteriores: turnosAnteriores,
                    pedidosLoja: pedidosLoja,
                    configuracoesImpressora: configuracoesImpressora,
                    aoAbrirCaixa: aoAbrirCaixa,
                    aoRegistrarMovimento: aoRegistrarMovimento,
                    aoFecharCaixa: aoFecharCaixa,
                    aoExcluirTurno: aoExcluirTurno,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CaixaConteudo extends StatefulWidget {
  final AppTheme theme;
  final bool expandido;
  final String? lojaId;
  final String lojaNome;
  final String lojaCnpj;
  final TurnoCaixa? turnoAberto;
  final List<TurnoCaixa> turnosAnteriores;
  final List<PedidoLoja> pedidosLoja;
  final ConfiguracoesImpressora configuracoesImpressora;
  final Future<void> Function(double saldoInicial) aoAbrirCaixa;
  final Future<void> Function(
    TipoMovimentoCaixa tipo,
    double valor,
    String motivo,
  ) aoRegistrarMovimento;
  final Future<void> Function(
    double saldoInformado,
    String observacao,
  ) aoFecharCaixa;
  final Future<void> Function(String turnoId)? aoExcluirTurno;

  const _CaixaConteudo({
    required this.theme,
    this.expandido = false,
    this.lojaId,
    required this.lojaNome,
    required this.lojaCnpj,
    required this.turnoAberto,
    this.turnosAnteriores = const [],
    required this.pedidosLoja,
    required this.configuracoesImpressora,
    required this.aoAbrirCaixa,
    required this.aoRegistrarMovimento,
    required this.aoFecharCaixa,
    this.aoExcluirTurno,
  });

  @override
  State<_CaixaConteudo> createState() => _CaixaConteudoState();
}

class _CaixaConteudoState extends State<_CaixaConteudo> {
  final _saldoInicialController = TextEditingController(text: '0,00');
  final _movimentoValorController = TextEditingController();
  final _movimentoMotivoController = TextEditingController();
  final _saldoFechamentoController = TextEditingController();
  final _observacaoFechamentoController = TextEditingController();

  TipoMovimentoCaixa? _modoMovimento;
  bool _modoFechamento = false;
  bool _salvando = false;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _saldoInicialController.dispose();
    _movimentoValorController.dispose();
    _movimentoMotivoController.dispose();
    _saldoFechamentoController.dispose();
    _observacaoFechamentoController.dispose();
    super.dispose();
  }

  double _parsearValor(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0.0;
  }

  String _formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  String _formatarDataHora(DateTime d) =>
      '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
      '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

  BoxDecoration get _decoracaoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  List<PedidoLoja> get _pedidosDoTurno {
    final t = widget.turnoAberto;
    if (t == null) return [];
    return widget.pedidosLoja.where((p) {
      if (p.status == StatusPedido.cancelado) return false;
      return p.dataHora.isAfter(t.dataAbertura) ||
          p.dataHora.isAtSameMomentAs(t.dataAbertura);
    }).toList();
  }

  double get _vendasDinheiro {
    var soma = 0.0;
    for (final p in _pedidosDoTurno) {
      if (p.pagamentosExtras.isNotEmpty) {
        for (final pag in p.todosPagamentos) {
          if (pag.forma.toLowerCase() == 'dinheiro') {
            soma += pag.valor;
          }
        }
        soma -= p.troco;
      } else {
        if (p.formaPagamento.toLowerCase() == 'dinheiro') {
          soma += p.valor;
        }
      }
    }
    return soma < 0 ? 0.0 : soma;
  }

  bool _ehFormaPrazo(String forma) {
    final f = forma.trim().toLowerCase();
    return f == 'à prazo' || f == 'a prazo';
  }

  double get _vendasEletronico {
    var soma = 0.0;
    for (final p in _pedidosDoTurno) {
      for (final pag in p.todosPagamentos) {
        final f = pag.forma.trim().toLowerCase();
        if (f != 'dinheiro' && !_ehFormaPrazo(pag.forma)) {
          soma += pag.valor;
        }
      }
    }
    return soma;
  }

  double get _vendasAPrazo {
    var soma = 0.0;
    for (final p in _pedidosDoTurno) {
      for (final pag in p.todosPagamentos) {
        if (_ehFormaPrazo(pag.forma)) {
          soma += pag.valor;
        }
      }
    }
    return soma;
  }

  double get _saldoEsperadoDinheiro {
    final t = widget.turnoAberto;
    if (t == null) return 0.0;
    return t.saldoInicial +
        _vendasDinheiro +
        t.totalSuprimentos -
        t.totalSangrias;
  }

  Future<void> _abrirCaixa() async {
    final valor = _parsearValor(_saldoInicialController.text);
    setState(() => _salvando = true);
    await widget.aoAbrirCaixa(valor);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _registrarMovimento({bool imprimir = false}) async {
    final tipo = _modoMovimento;
    if (tipo == null) return;
    final valor = _parsearValor(_movimentoValorController.text);
    final motivo = _movimentoMotivoController.text.trim();

    if (valor <= 0) {
      setState(() => _aviso = 'Informe um valor válido.');
      return;
    }

    setState(() => _salvando = true);
    await widget.aoRegistrarMovimento(tipo, valor, motivo);

    if (imprimir) {
      final t = widget.turnoAberto;
      try {
        await ImpressaoService.imprimirMovimentoCaixa(
          config: widget.configuracoesImpressora,
          lojaNome: widget.lojaNome,
          lojaCnpj: widget.lojaCnpj,
          tipo: tipo,
          valor: valor,
          motivo: motivo,
          dataHora: DateTime.now(),
          operadorNome: t?.abertoPorNome ?? '',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Movimento registrado, mas falhou ao imprimir comprovante: $e',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _salvando = false;
        _modoMovimento = null;
        _movimentoValorController.clear();
        _movimentoMotivoController.clear();
        _aviso = null;
      });
    }
  }

  Future<void> _imprimirMovimento(MovimentoCaixa mov) async {
    final t = widget.turnoAberto;
    try {
      await ImpressaoService.imprimirMovimentoCaixa(
        config: widget.configuracoesImpressora,
        lojaNome: widget.lojaNome,
        lojaCnpj: widget.lojaCnpj,
        tipo: mov.tipo,
        valor: mov.valor,
        motivo: mov.motivo,
        dataHora: mov.dataHora,
        operadorNome:
            mov.autorNome.isNotEmpty ? mov.autorNome : (t?.abertoPorNome ?? ''),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Comprovante enviado para a impressora.',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Falha ao imprimir comprovante: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  Future<void> _imprimirComprovante({required bool imprimirComoFechado}) async {
    final t = widget.turnoAberto;
    if (t == null) return;
    final informado = _parsearValor(_saldoFechamentoController.text);
    final obs = _observacaoFechamentoController.text.trim();

    await ImpressaoService.imprimirFechamentoCaixa(
      config: widget.configuracoesImpressora,
      lojaNome: widget.lojaNome,
      lojaCnpj: widget.lojaCnpj,
      turno: t,
      vendasDinheiro: _vendasDinheiro,
      vendasOutros: _vendasEletronico,
      vendasAPrazo: _vendasAPrazo,
      saldoEsperado: _saldoEsperadoDinheiro,
      saldoInformado: imprimirComoFechado ? informado : _saldoEsperadoDinheiro,
      observacao: obs,
    );
  }

  Future<void> _fecharCaixa({bool imprimir = false}) async {
    final valorInformado = _parsearValor(_saldoFechamentoController.text);
    final obs = _observacaoFechamentoController.text.trim();

    if (imprimir) {
      await _imprimirComprovante(imprimirComoFechado: true);
    }

    setState(() => _salvando = true);
    await widget.aoFecharCaixa(valorInformado, obs);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reimprimirFechamento(TurnoCaixa t) async {
    final pedidosDoTurno = widget.pedidosLoja.where((p) {
      if (p.status == StatusPedido.cancelado) return false;
      final aposAbertura = p.dataHora.isAfter(t.dataAbertura) ||
          p.dataHora.isAtSameMomentAs(t.dataAbertura);
      final antesFechamento = t.dataFechamento == null ||
          p.dataHora.isBefore(t.dataFechamento!) ||
          p.dataHora.isAtSameMomentAs(t.dataFechamento!);
      return aposAbertura && antesFechamento;
    }).toList();

    double vDinheiro = 0.0;
    double vEletronico = 0.0;
    double vPrazo = 0.0;
    for (final p in pedidosDoTurno) {
      if (p.pagamentosExtras.isNotEmpty) {
        for (final pag in p.todosPagamentos) {
          final f = pag.forma.trim().toLowerCase();
          if (f == 'dinheiro') {
            vDinheiro += pag.valor;
          } else if (_ehFormaPrazo(pag.forma)) {
            vPrazo += pag.valor;
          } else {
            vEletronico += pag.valor;
          }
        }
        vDinheiro -= p.troco;
      } else {
        final f = p.formaPagamento.trim().toLowerCase();
        if (f == 'dinheiro') {
          vDinheiro += p.valor;
        } else if (_ehFormaPrazo(p.formaPagamento)) {
          vPrazo += p.valor;
        } else {
          vEletronico += p.valor;
        }
      }
    }
    if (vDinheiro < 0) vDinheiro = 0.0;

    final saldoEsperado = t.saldoInicial +
        vDinheiro +
        t.totalSuprimentos -
        t.totalSangrias;

    try {
      await ImpressaoService.imprimirFechamentoCaixa(
        config: widget.configuracoesImpressora,
        lojaNome: widget.lojaNome,
        lojaCnpj: widget.lojaCnpj,
        turno: t,
        vendasDinheiro: vDinheiro,
        vendasOutros: vEletronico,
        vendasAPrazo: vPrazo,
        saldoEsperado: saldoEsperado,
        saldoInformado: t.saldoFinalInformado ?? saldoEsperado,
        observacao: t.observacao,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Comprovante do turno enviado para a impressora.',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Falha ao imprimir comprovante: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  List<TurnoCaixa> get _turnosFechados {
    final pdv = context.watch<PdvProvider>();
    final lojaAtual =
        widget.lojaId != null ? pdv.buscarPorId(widget.lojaId!) : null;
    final listaBase = lojaAtual != null
        ? lojaAtual.turnosCaixa.where((t) => !t.aberto).toList()
        : widget.turnosAnteriores.where((t) => !t.aberto).toList();

    return listaBase
      ..sort((a, b) => (b.dataFechamento ?? b.dataAbertura)
          .compareTo(a.dataFechamento ?? a.dataAbertura));
  }

  void _abrirDetalhesTurno(TurnoCaixa turno) {
    DetalhesTurnoCaixaDialog.mostrar(
      context,
      theme: theme,
      lojaId: widget.lojaId,
      lojaNome: widget.lojaNome,
      lojaCnpj: widget.lojaCnpj,
      turno: turno,
      pedidosLoja: widget.pedidosLoja,
      configuracoesImpressora: widget.configuracoesImpressora,
      aoExcluirTurno: widget.aoExcluirTurno,
    );
  }

  Widget _blocoHistoricoTurnosFechados() {
    return PainelHistoricoTurnos(
      theme: theme,
      decoracao: _decoracaoBloco,
      turnosFechados: _turnosFechados,
      formatarDataHora: _formatarDataHora,
      formatarMoeda: _formatarMoeda,
      aoClicarDetalhes: _abrirDetalhesTurno,
      aoReimprimir: _reimprimirFechamento,
    );
  }

  Widget _blocoAbertura() {
    return PainelAberturaTurno(
      theme: theme,
      decoracao: _decoracaoBloco,
      saldoInicialController: _saldoInicialController,
      salvando: _salvando,
      aoAbrirCaixa: _abrirCaixa,
    );
  }

  Widget _linhaResumo(String label, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.getTextStyle(
              fontSize: 12,
              color: destaque ? theme.textColor : theme.secondaryTextColor,
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: theme.getTextStyle(
              fontSize: 12,
              color: destaque ? theme.textColor : theme.secondaryTextColor,
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoTurnoAberto(TurnoCaixa turno) {
    return PainelTurnoAberto(
      theme: theme,
      decoracao: _decoracaoBloco,
      turno: turno,
      vendasDinheiro: _vendasDinheiro,
      vendasEletronico: _vendasEletronico,
      vendasAPrazo: _vendasAPrazo,
      saldoEsperadoDinheiro: _saldoEsperadoDinheiro,
      formatarDataHora: _formatarDataHora,
      formatarMoeda: _formatarMoeda,
      parsearValor: _parsearValor,
      linhaResumo: _linhaResumo,
      modoMovimento: _modoMovimento,
      modoFechamento: _modoFechamento,
      salvando: _salvando,
      movimentoValorController: _movimentoValorController,
      movimentoMotivoController: _movimentoMotivoController,
      saldoFechamentoController: _saldoFechamentoController,
      observacaoFechamentoController: _observacaoFechamentoController,
      aoImprimirMovimento: _imprimirMovimento,
      aoIniciarSuprimento: () =>
          setState(() => _modoMovimento = TipoMovimentoCaixa.suprimento),
      aoIniciarSangria: () =>
          setState(() => _modoMovimento = TipoMovimentoCaixa.sangria),
      aoCancelarMovimento: () => setState(() => _modoMovimento = null),
      aoConfirmarMovimento: () => _registrarMovimento(imprimir: false),
      aoConfirmarEImprimirMovimento: () =>
          _registrarMovimento(imprimir: true),
      aoIniciarFechamento: () => setState(() => _modoFechamento = true),
      aoCancelarFechamento: () => setState(() => _modoFechamento = false),
      aoFecharCaixa: () => _fecharCaixa(imprimir: false),
      aoFecharCaixaEImprimir: () => _fecharCaixa(imprimir: true),
      aoImprimirResumoTurno: () =>
          _imprimirComprovante(imprimirComoFechado: false),
      aoAlterarTextoFechamento: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turno = widget.lojaId != null
        ? context.watch<PdvProvider>().buscarPorId(widget.lojaId!)?.turnoCaixaAberto
        : widget.turnoAberto;
    final temTurnosFechados = _turnosFechados.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Caixa do Balcão',
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
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.expandido
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            if (turno == null)
                              _blocoAbertura()
                            else
                              _blocoTurnoAberto(turno),
                            if (_aviso != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _aviso!,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (temTurnosFechados) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _blocoHistoricoTurnosFechados(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      if (turno == null) ...[
                        _blocoAbertura(),
                        if (temTurnosFechados)
                          _blocoHistoricoTurnosFechados(),
                      ] else ...[
                        _blocoTurnoAberto(turno),
                        if (temTurnosFechados)
                          _blocoHistoricoTurnosFechados(),
                      ],
                      if (_aviso != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _aviso!,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
