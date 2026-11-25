import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_estoque_financeiro_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_sessao_rede_helper.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Helper que centraliza operações de pedidos, pedidos programados e quitação de vendas.
class PdvOperacoesPedidosHelper {
  static Future<List<PedidoLoja>> obterHistoricoPedidosPaginado({
    required String lojaId,
    int limite = 100,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      LojasService.carregarPedidosPaginados(
        lojaId: lojaId,
        limite: limite,
        offset: offset,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );

  static Future<int> obterTotalPedidos({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      LojasService.contarTotalPedidos(
        lojaId: lojaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );

  static void executarQuitarPedido({
    required Loja? loja,
    required String pedidoId,
    required String formaRecebimento,
    required String autorCpf,
    required String autorNome,
    required String autorEmail,
    required Future<void> Function(Loja) salvarEAtualizar,
    required Future<void> Function(
      String lojaId, {
      required TipoMovimentoCaixa tipo,
      required double valor,
      required String motivo,
      required String cpf,
      required String nome,
    }) registrarMovimentoCaixa,
    required void Function(String lojaId, RegistroAcao acao) registrarAcao,
  }) {
    if (loja == null) return;
    PdvEstoqueFinanceiroHelper.executarQuitarPedido(
      loja: loja,
      pedidoId: pedidoId,
      formaRecebimento: formaRecebimento,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorEmail: autorEmail,
      salvarEAtualizar: salvarEAtualizar,
      registrarSuprimentoCaixa: (valor, motivo) => registrarMovimentoCaixa(
        loja.id,
        tipo: TipoMovimentoCaixa.suprimento,
        valor: valor,
        motivo: motivo,
        cpf: autorCpf,
        nome: autorNome,
      ),
      registrarAcao: (acao) => registrarAcao(loja.id, acao),
    );
  }

  static Future<void> adicionarPedidoProgramado({
    required String lojaId,
    required PedidoProgramado pedido,
    required Future<void> Function(String, Loja? Function(Loja)) mutarLojaAsync,
    required Future<bool> Function(String) verificarEGerar,
  }) async {
    await mutarLojaAsync(
      lojaId,
      (l) => PdvPedidosProgramadosHelper.adicionarPedidoProgramado(l, pedido),
    );
    if (!PdvSessaoRedeHelper.clienteRedeConectado) {
      await verificarEGerar(lojaId);
    }
  }

  static Future<void> atualizarPedidoProgramado({
    required Loja? loja,
    required PedidoProgramado pedido,
    required Future<void> Function(Loja) salvarEAtualizar,
    required Future<bool> Function(String) verificarEGerar,
  }) async {
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.atualizarPedidoProgramado(loja, pedido);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, loja.id);
    await salvarEAtualizar(res.loja);
    if (!PdvSessaoRedeHelper.clienteRedeConectado) {
      await verificarEGerar(loja.id);
    }
  }

  static Future<void> removerPedidoProgramado({
    required Loja? loja,
    required String pedidoId,
    required Future<void> Function(Loja) salvarEAtualizar,
  }) async {
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.removerPedidoProgramado(loja, pedidoId);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, loja.id);
    await salvarEAtualizar(res.loja);
  }

  static Future<void> alternarAtivoPedidoProgramado({
    required Loja? loja,
    required String pedidoId,
    required Future<void> Function(Loja) salvarEAtualizar,
    required Future<bool> Function(String) verificarEGerar,
  }) async {
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.alternarAtivoPedidoProgramado(loja, pedidoId);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, loja.id);
    await salvarEAtualizar(res.loja);
    if (!PdvSessaoRedeHelper.clienteRedeConectado) {
      await verificarEGerar(loja.id);
    }
  }

  static Future<bool> verificarEGerarPedidosProgramados({
    required Loja? loja,
    required Future<void> Function(Loja) salvarEAtualizar,
  }) async {
    if (loja == null) return false;
    final res = PdvPedidosProgramadosHelper.verificarEGerar(loja);
    if (res.alterou) {
      await salvarEAtualizar(res.loja);
      PdvPedidosProgramadosHelper.despacharPedidosGeradosNaRede(res.pedidosGerados, loja.id);
      return res.pedidosGerados.isNotEmpty;
    }
    return false;
  }
}
