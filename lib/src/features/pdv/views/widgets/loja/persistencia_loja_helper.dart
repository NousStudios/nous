import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class PersistenciaLojaHelper {
  static void persistirListasLoja({
    required PdvProvider pdv,
    required String lojaId,
    required List<CategoriaLoja> categorias,
    required List<ItemLoja> itens,
    required List<GrupoComponentesLoja> gruposComponentes,
    required List<Cliente> clientes,
    required List<Fornecedor> fornecedores,
    required List<PedidoLoja> pedidos,
    required List<MesaLoja> mesas,
    required List<MovimentoEstoque> movimentosEstoque,
  }) {
    pdv.atualizarListasLoja(
      lojaId,
      categorias: categorias,
      itens: itens,
      gruposComponentes: gruposComponentes,
      clientes: clientes,
      fornecedores: fornecedores,
      pedidos: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
    );

    final lojaAtual = pdv.buscarPorId(lojaId);
    if (lojaAtual != null) {
      notificarLojaAtualizada(lojaAtual);
    }
  }

  static void notificarLojaAtualizada(Loja loja) {
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': loja.toJson(),
      });
    }

    if (ClienteRedeLocal().conectado &&
        !ClienteRedeLocal().aplicandoAtualizacaoRemota) {
      ClienteRedeLocal().enviarLojaAtualizada(loja, imediato: true);
    }
  }
}
