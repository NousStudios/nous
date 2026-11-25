import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Funções puras de cálculo, filtragem e montagem de pedido do Modo Balcão.
class BalcaoLogicaHelper {
  BalcaoLogicaHelper._();

  static double precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  static String valorFormatado(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  static double saldoEstoque(
    String itemId,
    List<MovimentoEstoque> movimentosEstoque,
  ) {
    var saldo = 0.0;
    for (final m in movimentosEstoque) {
      if (m.itemId == itemId) {
        saldo += m.quantidadeComSinal;
      }
    }
    return saldo;
  }

  static double dividaDoCliente(Cliente cliente, List<PedidoLoja> pedidos) {
    if (pedidos.isEmpty) return 0.0;
    final nomeNorm = TextoUtils.normalizarParaBusca(cliente.nome);
    var total = 0.0;
    for (final p in pedidos) {
      if (!p.aPrazoEmAberto) continue;
      final mesmoId = p.clienteId != null &&
          p.clienteId!.isNotEmpty &&
          p.clienteId == cliente.id;
      final mesmoNome = (p.clienteId == null || p.clienteId!.isEmpty) &&
          nomeNorm.isNotEmpty &&
          TextoUtils.normalizarParaBusca(p.clienteNome) == nomeNorm;
      if (mesmoId || mesmoNome) {
        total += p.valorRestante;
      }
    }
    return total;
  }

  static CategoriaLoja? obterCategoriaDoItem(
    ItemLoja item,
    List<CategoriaLoja> categorias,
    String? categoriaFiltroId,
  ) {
    if (categoriaFiltroId != null) {
      final cat =
          categorias.where((c) => c.id == categoriaFiltroId).firstOrNull;
      if (cat != null && cat.itemIds.contains(item.id)) {
        return cat;
      }
    }
    return null;
  }

  static List<GrupoComponentesLoja> obterGruposDoItemVendido(
    ItemVendido item,
    List<CategoriaLoja> categorias,
    List<GrupoComponentesLoja> gruposComponentes,
  ) {
    if (item.categoriaId != null) {
      final cat =
          categorias.where((c) => c.id == item.categoriaId).firstOrNull;
      if (cat != null && cat.grupoIds.isNotEmpty) {
        final grupos = gruposComponentes
            .where((g) => cat.grupoIds.contains(g.id))
            .toList();
        if (grupos.isNotEmpty) return grupos;
      }
    }
    return gruposComponentes;
  }

  static List<ItemLoja> filtrarItens({
    required List<ItemLoja> itens,
    required List<CategoriaLoja> categorias,
    required String? categoriaFiltroId,
    required String termo,
  }) {
    final termoLimpo = termo.trim().toLowerCase();
    return itens.where((i) {
      if (categoriaFiltroId != null) {
        final cat =
            categorias.where((c) => c.id == categoriaFiltroId).firstOrNull;
        if (cat != null && !cat.itemIds.contains(i.id)) {
          return false;
        }
      }
      if (termoLimpo.isEmpty) return true;
      final nome = i.nome.toLowerCase();
      final codigo = i.codigoBarras.trim().toLowerCase();
      return nome.contains(termoLimpo) || codigo.contains(termoLimpo);
    }).toList();
  }

  static List<Cliente> filtrarClientes(List<Cliente> clientes, String termo) {
    final limpo = termo.trim();
    if (limpo.isEmpty) return clientes;
    return clientes.where((c) => c.correspondeABusca(limpo)).toList();
  }

  static ItemLoja? buscarItemParaBipagem({
    required String codigo,
    required List<ItemLoja> itens,
    required List<ItemLoja> itensFiltrados,
  }) {
    final codigoLower = codigo.toLowerCase();

    // 1. Tenta correspondência exata por código de barras
    final itemPorCodigo = itens.where((i) {
      final cb = i.codigoBarras.trim().toLowerCase();
      return cb.isNotEmpty && cb == codigoLower;
    }).firstOrNull;
    if (itemPorCodigo != null) return itemPorCodigo;

    // 2. Tenta por nome exato
    final itemPorNome = itens.where((i) {
      return i.nome.trim().toLowerCase() == codigoLower;
    }).firstOrNull;
    if (itemPorNome != null) return itemPorNome;

    // 3. Se houver apenas um resultado filtrado na lista, adiciona ele
    if (itensFiltrados.length == 1) {
      return itensFiltrados.first;
    }

    return null;
  }

  static String montarComanda({
    required List<ItemVendido> carrinho,
    required double freteValor,
    required double acrescimoValor,
    required double descontoValor,
  }) {
    final buffer = StringBuffer();
    for (final item in carrinho) {
      buffer.writeln(
        '${item.quantidade}x ${item.nomeExibicao} - R\$ ${valorFormatado(item.subtotal)}',
      );
      for (final a in item.acompanhamentos) {
        buffer.writeln('  + ${a.quantidadePorUnidade}x ${a.nomeItem}');
      }
      if (item.observacao.isNotEmpty) {
        buffer.writeln('  Obs: ${item.observacao}');
      }
    }
    if (freteValor > 0) {
      buffer.writeln('Frete: R\$ ${valorFormatado(freteValor)}');
    }
    if (acrescimoValor > 0) {
      buffer.writeln('Acréscimo: R\$ ${valorFormatado(acrescimoValor)}');
    }
    if (descontoValor > 0) {
      buffer.writeln('Desconto: - R\$ ${valorFormatado(descontoValor)}');
    }
    return buffer.toString().trim();
  }

  static PedidoLoja montarPedidoBalcao({
    required DateTime agora,
    required int proximoNumero,
    required Cliente? clienteSelecionado,
    required String clienteNomeTexto,
    required List<ItemVendido> carrinho,
    required double total,
    required String formaPagamentoSelecionada,
    required double valorRecebido,
    required double trocoCalculado,
    required bool temPrazo,
    required double freteValor,
    required double descontoValor,
    required double acrescimoValor,
    required String nomeVendedor,
    required String cnpjVendedor,
    required String lojaId,
  }) {
    final clienteNome = clienteSelecionado?.nome ??
        (clienteNomeTexto.trim().isNotEmpty
            ? clienteNomeTexto.trim()
            : 'Consumidor Final');
    final resumoItens =
        carrinho.map((i) => '${i.quantidade}x ${i.nomeExibicao}').join(', ');

    return PedidoLoja(
      id: agora.millisecondsSinceEpoch.toString(),
      numero: proximoNumero,
      clienteId: clienteSelecionado?.id,
      clienteNome: clienteNome,
      produtoNome: resumoItens,
      dataHora: agora,
      valor: total,
      status: StatusPedido.concluido,
      comanda: montarComanda(
        carrinho: carrinho,
        freteValor: freteValor,
        acrescimoValor: acrescimoValor,
        descontoValor: descontoValor,
      ),
      formaPagamento: formaPagamentoSelecionada,
      pagamentosExtras: const [],
      valorRecebido: formaPagamentoSelecionada == 'Dinheiro' && valorRecebido > 0
          ? valorRecebido
          : total,
      troco: trocoCalculado,
      quitado: !temPrazo,
      valorPago: !temPrazo ? total : 0.0,
      itens: List.of(carrinho),
      frete: freteValor,
      desconto: descontoValor,
      acrescimo: acrescimoValor,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      lojaId: lojaId,
    );
  }

  static ({ItemVendido? ultimoItemVendido, int quantidadeUltimoBipado})
      adicionarItemAoCarrinho({
    required List<ItemVendido> carrinho,
    required ItemLoja item,
    required List<CategoriaLoja> categorias,
    required String? categoriaFiltroId,
    VarianteItem? variante,
  }) {
    final categoria =
        obterCategoriaDoItem(item, categorias, categoriaFiltroId);
    final precoCat =
        categoria != null ? precoComoNumero(categoria.preco) : 0.0;
    final precoItem = (variante != null && variante.preco.trim().isNotEmpty)
        ? precoComoNumero(variante.preco)
        : precoComoNumero(item.preco);
    final nomeVar = (variante != null && variante.nome.trim().isNotEmpty)
        ? variante.nome.trim()
        : '';

    final indice = carrinho.indexWhere(
      (it) =>
          it.itemId == item.id &&
          it.categoriaId == categoria?.id &&
          it.varianteNome == nomeVar,
    );

    if (indice != -1) {
      final atual = carrinho[indice];
      final atualizado = atual.copyWith(quantidade: atual.quantidade + 1);
      carrinho[indice] = atualizado;
      return (
        ultimoItemVendido: atualizado,
        quantidadeUltimoBipado: atualizado.quantidade,
      );
    }

    final novo = ItemVendido(
      itemId: item.id,
      nomeItem: item.nome,
      categoriaId: categoria?.id,
      nomeCategoria: categoria?.nome,
      varianteNome: nomeVar,
      precoItem: precoItem,
      precoCategoria: precoCat,
      quantidade: 1,
      foto: item.imagens.firstOrNull ?? '',
    );
    carrinho.add(novo);
    return (ultimoItemVendido: novo, quantidadeUltimoBipado: 1);
  }

  static ({ItemVendido? ultimoItemVendido, int quantidadeUltimoBipado})
      alterarQuantidadeCarrinho({
    required List<ItemVendido> carrinho,
    required int indice,
    required int delta,
    required ItemVendido? ultimoItemVendidoAtual,
    required int quantidadeUltimoBipadoAtual,
  }) {
    final atual = carrinho[indice];
    final novaQtd = atual.quantidade + delta;
    final mesmoUltimo = ultimoItemVendidoAtual?.itemId == atual.itemId &&
        ultimoItemVendidoAtual?.categoriaId == atual.categoriaId;

    if (novaQtd <= 0) {
      carrinho.removeAt(indice);
      return (
        ultimoItemVendido: mesmoUltimo ? null : ultimoItemVendidoAtual,
        quantidadeUltimoBipado: quantidadeUltimoBipadoAtual,
      );
    }

    final atualizado = atual.copyWith(quantidade: novaQtd);
    carrinho[indice] = atualizado;
    return (
      ultimoItemVendido: mesmoUltimo ? atualizado : ultimoItemVendidoAtual,
      quantidadeUltimoBipado:
          mesmoUltimo ? novaQtd : quantidadeUltimoBipadoAtual,
    );
  }

  static ItemVendido? removerItemCarrinho({
    required List<ItemVendido> carrinho,
    required int indice,
    required ItemVendido? ultimoItemVendidoAtual,
  }) {
    final removido = carrinho.removeAt(indice);
    if (ultimoItemVendidoAtual?.itemId == removido.itemId &&
        ultimoItemVendidoAtual?.categoriaId == removido.categoriaId) {
      return null;
    }
    return ultimoItemVendidoAtual;
  }
}
