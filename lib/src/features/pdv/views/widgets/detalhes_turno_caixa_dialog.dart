import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_movimento_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_operacional_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_resumo_financeiro_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_venda_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class DetalhesTurnoCaixaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String? lojaId,
    required String lojaNome,
    required String lojaCnpj,
    required TurnoCaixa turno,
    required List<PedidoLoja> pedidosLoja,
    required ConfiguracoesImpressora configuracoesImpressora,
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
          child: Dialog(
            backgroundColor: theme.cardBackgroundColor,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.borderColor),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 680,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
              ),
              child: _DetalhesTurnoConteudo(
                theme: theme,
                lojaId: lojaId,
                lojaNome: lojaNome,
                lojaCnpj: lojaCnpj,
                turno: turno,
                pedidosLoja: pedidosLoja,
                configuracoesImpressora: configuracoesImpressora,
                aoExcluirTurno: aoExcluirTurno,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetalhesTurnoConteudo extends StatefulWidget {
  final AppTheme theme;
  final String? lojaId;
  final String lojaNome;
  final String lojaCnpj;
  final TurnoCaixa turno;
  final List<PedidoLoja> pedidosLoja;
  final ConfiguracoesImpressora configuracoesImpressora;
  final Future<void> Function(String turnoId)? aoExcluirTurno;

  const _DetalhesTurnoConteudo({
    required this.theme,
    required this.lojaId,
    required this.lojaNome,
    required this.lojaCnpj,
    required this.turno,
    required this.pedidosLoja,
    required this.configuracoesImpressora,
    required this.aoExcluirTurno,
  });

  @override
  State<_DetalhesTurnoConteudo> createState() => _DetalhesTurnoConteudoState();
}

class _DetalhesTurnoConteudoState extends State<_DetalhesTurnoConteudo> {
  int _abaSelecionada = 0; // 0 = Movimentações (Retiradas/Entradas), 1 = Vendas
  bool _excluindo = false;
  bool _imprimindo = false;

  AppTheme get theme => widget.theme;

  BoxDecoration get _decoracaoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  String _formatarMoeda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteira = partes[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $inteira,${partes[1]}';
  }

  String _formatarDataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $h:$min';
  }

  String _formatarCpf(String doc) {
    final d = doc.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) {
      return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
    }
    return doc.isEmpty ? 'Não informado' : doc;
  }

  String _duracaoTurno(DateTime inicio, DateTime? fim) {
    if (fim == null) return 'Em andamento';
    final diferenca = fim.difference(inicio);
    if (diferenca.inHours > 0) {
      final minutos = diferenca.inMinutes % 60;
      return '${diferenca.inHours}h ${minutos}min';
    }
    return '${diferenca.inMinutes} minutos';
  }

  bool _ehFormaPrazo(String forma) {
    final f = forma.trim().toLowerCase();
    return f == 'à prazo' || f == 'a prazo';
  }

  List<PedidoLoja> get _pedidosDoTurno {
    final t = widget.turno;
    return widget.pedidosLoja.where((p) {
      if (p.status == StatusPedido.cancelado) return false;
      final aposAbertura = p.dataHora.isAfter(t.dataAbertura) ||
          p.dataHora.isAtSameMomentAs(t.dataAbertura);
      final antesFechamento = t.dataFechamento == null ||
          p.dataHora.isBefore(t.dataFechamento!) ||
          p.dataHora.isAtSameMomentAs(t.dataFechamento!);
      return aposAbertura && antesFechamento;
    }).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
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

  double get _totalVendas =>
      _vendasDinheiro + _vendasEletronico + _vendasAPrazo;

  double get _saldoEsperado {
    final t = widget.turno;
    return t.saldoInicial +
        _vendasDinheiro +
        t.totalSuprimentos -
        t.totalSangrias;
  }

  double get _saldoInformado =>
      widget.turno.saldoFinalInformado ?? _saldoEsperado;

  double get _diferencaQuebra => _saldoInformado - _saldoEsperado;

  Widget _buildAvatarUsuario(String cpf, String nome, {double raio = 16}) {
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    var foto = auth.buscarFotoPorCpf(cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(cpf) ?? '';
    }

    final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);

    if (fotoResolvida != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.2),
        backgroundImage: FileImage(File(fotoResolvida)),
      );
    }

    final inicial =
        nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: raio,
      backgroundColor: theme.borderColor.withValues(alpha: 0.25),
      child: Text(
        inicial,
        style: theme.getTextStyle(
          fontSize: raio * 0.85,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
    );
  }

  Future<void> _reimprimirFechamento() async {
    if (_imprimindo) return;
    setState(() => _imprimindo = true);

    try {
      await ImpressaoService.imprimirFechamentoCaixa(
        config: widget.configuracoesImpressora,
        lojaNome: widget.lojaNome,
        lojaCnpj: widget.lojaCnpj,
        turno: widget.turno,
        vendasDinheiro: _vendasDinheiro,
        vendasOutros: _vendasEletronico,
        vendasAPrazo: _vendasAPrazo,
        saldoEsperado: _saldoEsperado,
        saldoInformado: _saldoInformado,
        observacao: widget.turno.observacao,
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
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  void _confirmarExclusao() {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Apagar Registro do Turno?',
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja apagar o registro deste turno fechado? '
            'Todo o histórico de movimentações e fechamento vinculado a este turno será removido. '
            'Esta ação não pode ser desfeita.',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.textColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sim, Apagar'),
            ),
          ],
        );
      },
    ).then((confirmado) async {
      if (confirmado == true) {
        await _executarExclusao();
      }
    });
  }

  Future<void> _executarExclusao() async {
    setState(() => _excluindo = true);

    try {
      if (widget.aoExcluirTurno != null) {
        await widget.aoExcluirTurno!(widget.turno.id);
      } else if (widget.lojaId != null) {
        await context
            .read<PdvProvider>()
            .excluirTurnoCaixa(widget.lojaId!, widget.turno.id);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Registro do turno apagado com sucesso.',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _excluindo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Erro ao apagar turno: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  Widget _buildCardOperacional() {
    return CardOperacionalTurno(
      theme: theme,
      decoracao: _decoracaoBloco,
      turno: widget.turno,
      duracaoTurno: _duracaoTurno,
      formatarDataHora: _formatarDataHora,
      formatarCpf: _formatarCpf,
      buildAvatarUsuario: _buildAvatarUsuario,
    );
  }

  Widget _buildCardResumoFinanceiro() {
    return CardResumoFinanceiroTurno(
      theme: theme,
      decoracao: _decoracaoBloco,
      turno: widget.turno,
      vendasDinheiro: _vendasDinheiro,
      totalVendas: _totalVendas,
      saldoEsperado: _saldoEsperado,
      saldoInformado: _saldoInformado,
      diferencaQuebra: _diferencaQuebra,
      formatarMoeda: _formatarMoeda,
    );
  }

  Widget _buildSeletorAbas() {
    final movCount = widget.turno.movimentacoes.length;
    final vendCount = _pedidosDoTurno.length;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          _buildBotaoAba(
            indice: 0,
            titulo: 'Retiradas e Entradas',
            contador: movCount,
            icone: Icons.sync_alt,
          ),
          const SizedBox(width: 8),
          _buildBotaoAba(
            indice: 1,
            titulo: 'Vendas do Turno',
            contador: vendCount,
            icone: Icons.receipt_long_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAba({
    required int indice,
    required String titulo,
    required int contador,
    required IconData icone,
  }) {
    final selecionada = _abaSelecionada == indice;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _abaSelecionada = indice),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: selecionada
                  ? theme.borderColor.withValues(alpha: 0.22)
                  : theme.backgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selecionada
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.4),
                width: selecionada ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 14,
                  color: selecionada ? theme.textColor : theme.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight:
                        selecionada ? FontWeight.bold : FontWeight.normal,
                    color: selecionada
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selecionada
                        ? theme.borderColor.withValues(alpha: 0.3)
                        : theme.borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$contador',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selecionada
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaMovimentacoes() {
    final movs = widget.turno.movimentacoes.reversed.toList();

    if (movs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma retirada ou suprimento registrado neste turno.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final m = movs[index];
        final ehSangria = m.tipo == TipoMovimentoCaixa.sangria;

        return CardMovimentoTurno(
          theme: theme,
          movimento: m,
          ehSangria: ehSangria,
          formatarMoeda: _formatarMoeda,
          formatarDataHora: _formatarDataHora,
          formatarCpf: _formatarCpf,
          buildAvatar: _buildAvatarUsuario,
        );
      },
    );
  }

  Widget _buildListaVendas() {
    final vendas = _pedidosDoTurno;

    if (vendas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma venda registrada durante o período deste turno.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final p = vendas[index];

        return CardVendaTurno(
          theme: theme,
          pedido: p,
          formatarMoeda: _formatarMoeda,
          formatarDataHora: _formatarDataHora,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico do Turno de Caixa',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      '${widget.lojaNome} • Fechado',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 13, color: theme.secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      'Turno Fechado',
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
        const Divider(height: 1),
        // Conteúdo rolável
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardOperacional(),
                _buildCardResumoFinanceiro(),
                _buildSeletorAbas(),
                if (_abaSelecionada == 0)
                  _buildListaMovimentacoes()
                else
                  _buildListaVendas(),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Rodapé de ações
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Botão Apagar Registro (Destrutivo)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _excluindo
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(Icons.delete_outline,
                        size: 16, color: Colors.redAccent),
                label: Text(
                  'Apagar Registro',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: _excluindo ? null : _confirmarExclusao,
              ),
              const Spacer(),
              // Botão Reimprimir Comprovante
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _imprimindo
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.buttonTextColor,
                        ),
                      )
                    : const Icon(Icons.print_outlined, size: 16),
                label: Text(
                  'Reimprimir Comprovante',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
                onPressed: _imprimindo ? null : _reimprimirFechamento,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
