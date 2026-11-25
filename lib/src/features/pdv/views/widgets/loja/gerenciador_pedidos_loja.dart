import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/pedidos_acoes_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/pedidos_programados_fila_helper.dart';

/// Controlador desacoplado responsável pela gestão de pedidos, confirmações,
/// cancelamentos, estornos de estoque, timers e notificações de novos pedidos no PDV.
class GerenciadorPedidosLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<PedidoLoja> Function() obterPedidos;
  final List<ItemLoja> Function() obterItens;
  final List<MovimentoEstoque> Function() obterMovimentos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final int Function() obterTempoConclusaoMinutos;
  final void Function(void Function()) setState;
  final VoidCallback aoPersistir;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final String Function(int numero) formatarNumeroPedido;
  final String Function(double valor) formatarValor;
  final String Function(double qtd) formatarQuantidade;
  final String Function(UnidadeItemLoja u) rotuloUnidadeCurto;
  final void Function(AbaPedidos) definirAbaPedidos;

  Timer? _timerVerificacaoPedidos;
  final Set<String> _pedidosPerguntados = {};
  static final Set<String> _avisosMostradosNaSessao = {};

  late final PedidosAcoesHelper _acoesHelper = PedidosAcoesHelper(
    obterContext: obterContext,
    estaMontado: estaMontado,
    lojaId: lojaId,
    obterPedidos: obterPedidos,
    obterItens: obterItens,
    obterMovimentos: obterMovimentos,
    obterCpfLogado: obterCpfLogado,
    obterNomeLogado: obterNomeLogado,
    setState: setState,
    aoPersistir: aoPersistir,
    aoSincronizarComPdv: _sincronizarPedidosLocaisComPdv,
    registrarAcao: registrarAcao,
    formatarNumeroPedido: formatarNumeroPedido,
    formatarValor: formatarValor,
    formatarQuantidade: formatarQuantidade,
    rotuloUnidadeCurto: rotuloUnidadeCurto,
    definirAbaPedidos: definirAbaPedidos,
  );

  late final PedidosProgramadosFilaHelper _filaHelper =
      PedidosProgramadosFilaHelper(
    obterContext: obterContext,
    estaMontado: estaMontado,
    lojaId: lojaId,
    obterPedidos: obterPedidos,
    obterTempoConclusaoMinutos: obterTempoConclusaoMinutos,
    aoSincronizarComPdv: _sincronizarPedidosLocaisComPdv,
    aoAlterarStatusPedido: alterarStatusPedido,
    aoCancelarPedidoSilencioso: cancelarPedidoSilencioso,
    aoRecusarPedido: recusarPedido,
    formatarNumeroPedido: formatarNumeroPedido,
    pedidosPerguntados: _pedidosPerguntados,
    avisosMostradosNaSessao: _avisosMostradosNaSessao,
  );

  GerenciadorPedidosLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterPedidos,
    required this.obterItens,
    required this.obterMovimentos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.obterTempoConclusaoMinutos,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.formatarNumeroPedido,
    required this.formatarValor,
    required this.formatarQuantidade,
    required this.rotuloUnidadeCurto,
    required this.definirAbaPedidos,
  });

  BuildContext get context => obterContext();

  void _sincronizarPedidosLocaisComPdv() {
    if (!estaMontado()) return;
    final lojaAtual = context.read<PdvProvider>().buscarPorId(lojaId);
    if (lojaAtual == null) return;
    final pedidosLocais = obterPedidos();
    final idsLocais = pedidosLocais.map((p) => p.id).toSet();
    final faltantes = lojaAtual.pedidosLoja
        .where((p) => !idsLocais.contains(p.id))
        .toList();
    if (faltantes.isNotEmpty) {
      setState(() {
        pedidosLocais.insertAll(0, faltantes);
      });
    }
  }

  void iniciarTimerVerificacaoPedidos() {
    _timerVerificacaoPedidos?.cancel();
    _timerVerificacaoPedidos =
        Timer.periodic(const Duration(seconds: 15), (_) async {
      verificarPedidosTempoConclusao();
      if (estaMontado()) {
        if (!ClienteRedeLocal().estaConectado.value) {
          final gerou = await context
              .read<PdvProvider>()
              .verificarEGerarPedidosProgramados(lojaId);
          if (gerou && estaMontado()) {
            _sincronizarPedidosLocaisComPdv();
            await processarFilaNovosPedidos();
          }
        }
      }
    });
  }

  void cancelarTimer() {
    _timerVerificacaoPedidos?.cancel();
    _timerVerificacaoPedidos = null;
  }

  void verificarPedidosTempoConclusao() =>
      _filaHelper.verificarPedidosTempoConclusao();

  Future<void> perguntarConclusaoPedido(PedidoLoja pedido) =>
      _filaHelper.perguntarConclusaoPedido(pedido);

  void alterarStatusPedido(String id, StatusPedido novoStatus) =>
      _acoesHelper.alterarStatusPedido(id, novoStatus);

  void salvarComentarioPedido(String id, DadosComentario dados) =>
      _acoesHelper.salvarComentarioPedido(id, dados);

  void cancelarPedidoSilencioso(
    String id, {
    String motivo = 'Cancelado automaticamente',
  }) =>
      _acoesHelper.cancelarPedidoSilencioso(id, motivo: motivo);

  Future<void> cancelarPedidoComDialog(String id) =>
      _acoesHelper.cancelarPedidoComDialog(id);

  void recusarPedido(String id) => _acoesHelper.recusarPedido(id);

  Future<void> excluirPedido(String id) => _acoesHelper.excluirPedido(id);

  void processarConclusaoVenda(
    PedidoLoja pedido,
    List<MovimentoEstoque> movimentosEstoque,
  ) =>
      _acoesHelper.processarConclusaoVenda(pedido, movimentosEstoque);

  Future<void> verificarAvisosIniciais() =>
      _filaHelper.verificarAvisosIniciais();

  Future<void> processarFilaNovosPedidos() =>
      _filaHelper.processarFilaNovosPedidos();
}
