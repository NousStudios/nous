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
import 'package:nous/src/features/pdv/views/widgets/caixa/abas_detalhes_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/cabecalho_detalhes_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_operacional_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_resumo_financeiro_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/rodape_detalhes_turno.dart';

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
              style: theme.getTextStyle(color: theme.dangerColor),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  void _confirmarExclusao() {
    RodapeDetalhesTurno.mostrarConfirmacaoExclusao(
      context,
      theme: theme,
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
              style: theme.getTextStyle(color: theme.dangerColor),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CabecalhoDetalhesTurno(
          theme: theme,
          lojaNome: widget.lojaNome,
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardOperacional(),
                _buildCardResumoFinanceiro(),
                AbasDetalhesTurno(
                  theme: theme,
                  abaSelecionada: _abaSelecionada,
                  aoSelecionarAba: (indice) {
                    setState(() => _abaSelecionada = indice);
                  },
                  movimentacoes: widget.turno.movimentacoes,
                  pedidosDoTurno: _pedidosDoTurno,
                  formatarMoeda: _formatarMoeda,
                  formatarDataHora: _formatarDataHora,
                  formatarCpf: _formatarCpf,
                  buildAvatarUsuario: _buildAvatarUsuario,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        RodapeDetalhesTurno(
          theme: theme,
          excluindo: _excluindo,
          imprimindo: _imprimindo,
          aoConfirmarExclusao: _confirmarExclusao,
          aoReimprimir: _reimprimirFechamento,
        ),
      ],
    );
  }
}
