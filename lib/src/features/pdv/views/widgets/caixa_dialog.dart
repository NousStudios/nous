import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';

class CaixaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String lojaNome,
    required String lojaCnpj,
    required TurnoCaixa? turnoAberto,
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
  }) {
    return showDialog<void>(
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _CaixaConteudo(
              theme: theme,
              lojaNome: lojaNome,
              lojaCnpj: lojaCnpj,
              turnoAberto: turnoAberto,
              pedidosLoja: pedidosLoja,
              configuracoesImpressora: configuracoesImpressora,
              aoAbrirCaixa: aoAbrirCaixa,
              aoRegistrarMovimento: aoRegistrarMovimento,
              aoFecharCaixa: aoFecharCaixa,
            ),
          ),
        );
      },
    );
  }
}

class _CaixaConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaNome;
  final String lojaCnpj;
  final TurnoCaixa? turnoAberto;
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

  const _CaixaConteudo({
    required this.theme,
    required this.lojaNome,
    required this.lojaCnpj,
    required this.turnoAberto,
    required this.pedidosLoja,
    required this.configuracoesImpressora,
    required this.aoAbrirCaixa,
    required this.aoRegistrarMovimento,
    required this.aoFecharCaixa,
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
      for (final pag in p.todosPagamentos) {
        if (pag.forma.toLowerCase() == 'dinheiro') {
          soma += pag.valor;
        }
      }
      soma -= p.troco;
    }
    return soma < 0 ? 0.0 : soma;
  }

  double get _vendasOutros {
    var soma = 0.0;
    for (final p in _pedidosDoTurno) {
      for (final pag in p.todosPagamentos) {
        if (pag.forma.toLowerCase() != 'dinheiro') {
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
      vendasOutros: _vendasOutros,
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

  Widget _blocoAbertura() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _decoracaoBloco,
          child: Column(
            children: [
              Icon(Icons.lock_clock, size: 36, color: theme.textColor),
              const SizedBox(height: 8),
              Text(
                'O caixa está fechado',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Informe o valor de fundo de troco para iniciar as vendas deste turno.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ThemedTextField(
                theme: theme,
                controller: _saldoInicialController,
                label: 'Fundo de troco inicial (ex: 50,00)',
                tipoDeTeclado: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _salvando ? null : _abrirCaixa,
            child: Text(
              _salvando ? 'Abrindo...' : 'Abrir Caixa',
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.buttonTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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

  Widget _blocoMovimentacoes(TurnoCaixa turno) {
    if (turno.movimentacoes.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: theme.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Lançamentos do Turno (${turno.movimentacoes.length})',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: turno.movimentacoes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final m = turno.movimentacoes.reversed.toList()[index];
                final ehSangria = m.tipo == TipoMovimentoCaixa.sangria;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ehSangria
                          ? Colors.redAccent.withValues(alpha: 0.4)
                          : theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ehSangria
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 16,
                        color: ehSangria ? Colors.redAccent : theme.buttonColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ehSangria ? "Sangria" : "Suprimento"}: ${_formatarMoeda(m.valor)}',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ehSangria
                                    ? Colors.redAccent
                                    : theme.textColor,
                              ),
                            ),
                            if (m.motivo.isNotEmpty)
                              Text(
                                m.motivo,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Imprimir comprovante',
                        icon: Icon(Icons.print_outlined,
                            size: 16, color: theme.textColor),
                        onPressed: () => _imprimirMovimento(m),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoTurnoAberto(TurnoCaixa turno) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: _decoracaoBloco,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Turno Ativo',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatarDataHora(turno.dataAbertura),
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              if (turno.abertoPorNome.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Operador: ${turno.abertoPorNome}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Divider(color: theme.borderColor.withValues(alpha: 0.6)),
              _linhaResumo('Fundo de troco inicial', _formatarMoeda(turno.saldoInicial)),
              _linhaResumo('Vendas em dinheiro (+)', _formatarMoeda(_vendasDinheiro)),
              _linhaResumo('Vendas outras formas (Pix/Cartão)', _formatarMoeda(_vendasOutros)),
              if (turno.totalSuprimentos > 0)
                _linhaResumo('Suprimentos (+ troco adicionado)', _formatarMoeda(turno.totalSuprimentos)),
              if (turno.totalSangrias > 0)
                _linhaResumo('Sangrias (- retiradas p/ cofre)', '-${_formatarMoeda(turno.totalSangrias)}'),
              Divider(color: theme.borderColor.withValues(alpha: 0.6)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Atual em Dinheiro:',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      _formatarMoeda(_saldoEsperadoDinheiro),
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _blocoMovimentacoes(turno),
        const SizedBox(height: 12),
        if (_modoMovimento != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _decoracaoBloco,
            child: Column(
              children: [
                Text(
                  _modoMovimento == TipoMovimentoCaixa.sangria
                      ? 'Lançar Sangria (Retirada de Dinheiro)'
                      : 'Lançar Suprimento (Adicionar Moedas/Troco)',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                ThemedTextField(
                  theme: theme,
                  controller: _movimentoValorController,
                  label: 'Valor (ex: 20,00)',
                  tipoDeTeclado: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ThemedTextField(
                  theme: theme,
                  controller: _movimentoMotivoController,
                  label: 'Motivo (ex: Troco de moedas, Pagamento de água)',
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _modoMovimento = null),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(color: theme.secondaryTextColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        side: BorderSide(color: theme.borderColor),
                      ),
                      onPressed:
                          _salvando ? null : () => _registrarMovimento(imprimir: false),
                      child: Text(
                        'Confirmar',
                        style: theme.getTextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                      ),
                      onPressed:
                          _salvando ? null : () => _registrarMovimento(imprimir: true),
                      icon: Icon(Icons.print_outlined,
                          size: 14, color: theme.buttonTextColor),
                      label: Text(
                        'Confirmar e Imprimir',
                        style: theme.getTextStyle(
                          color: theme.buttonTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (_modoFechamento) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _decoracaoBloco,
            child: Column(
              children: [
                Text(
                  'Conferência e Fechamento de Caixa',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Conte todo o dinheiro físico presente na gaveta e informe abaixo:',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                ThemedTextField(
                  theme: theme,
                  controller: _saldoFechamentoController,
                  label: 'Valor contado na gaveta (ex: 125,50)',
                  tipoDeTeclado: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                ThemedTextField(
                  theme: theme,
                  controller: _observacaoFechamentoController,
                  label: 'Observação do fechamento (opcional)',
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final contado = _parsearValor(_saldoFechamentoController.text);
                  final diferenca = contado - _saldoEsperadoDinheiro;
                  final bateu = diferenca.abs() < 0.01;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _linhaResumo('Saldo Esperado:', _formatarMoeda(_saldoEsperadoDinheiro)),
                        _linhaResumo('Valor Informado:', _formatarMoeda(contado)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bateu
                                  ? 'Conferência exata'
                                  : (diferenca > 0 ? 'Sobra de caixa:' : 'Quebra / Falta:'),
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: bateu
                                    ? theme.textColor
                                    : (diferenca < 0 ? Colors.redAccent : theme.textColor),
                              ),
                            ),
                            Text(
                              bateu ? 'R\$ 0,00' : _formatarMoeda(diferenca.abs()),
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: bateu
                                    ? theme.textColor
                                    : (diferenca < 0 ? Colors.redAccent : theme.textColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _modoFechamento = false),
                      child: Text(
                        'Voltar',
                        style: theme.getTextStyle(color: theme.secondaryTextColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        side: BorderSide(color: theme.borderColor),
                      ),
                      onPressed: _salvando ? null : () => _fecharCaixa(imprimir: true),
                      icon: Icon(Icons.print_outlined, size: 16, color: theme.textColor),
                      label: Text(
                        'Fechar e Imprimir',
                        style: theme.getTextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                      ),
                      onPressed: _salvando ? null : () => _fecharCaixa(imprimir: false),
                      child: Text(
                        _salvando ? 'Fechando...' : 'Fechar',
                        style: theme.getTextStyle(
                          color: theme.buttonTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => setState(() => _modoMovimento = TipoMovimentoCaixa.suprimento),
                  icon: Icon(Icons.add_circle_outline, size: 16, color: theme.textColor),
                  label: Text('Suprimento', style: theme.getTextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => setState(() => _modoMovimento = TipoMovimentoCaixa.sangria),
                  icon: Icon(Icons.remove_circle_outline, size: 16, color: theme.textColor),
                  label: Text('Sangria', style: theme.getTextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => setState(() => _modoFechamento = true),
              icon: Icon(Icons.check_circle_outline, size: 18, color: theme.buttonTextColor),
              label: Text(
                'Fechar Caixa do Turno',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _imprimirComprovante(imprimirComoFechado: false),
              icon: Icon(Icons.print_outlined, size: 16, color: theme.textColor),
              label: Text(
                'Imprimir Resumo do Turno',
                style: theme.getTextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
        if (turno.movimentacoes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Movimentações deste Turno',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final m in turno.movimentacoes.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                m.tipo == TipoMovimentoCaixa.suprimento
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: theme.textColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${m.tipo == TipoMovimentoCaixa.suprimento ? "Suprimento" : "Sangria"}: ${m.motivo.isEmpty ? "Sem motivo" : m.motivo}',
                                style: theme.getTextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            _formatarMoeda(m.valor),
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final turno = widget.turnoAberto;

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
            child: Column(
              children: [
                if (turno == null) _blocoAbertura() else _blocoTurnoAberto(turno),
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
