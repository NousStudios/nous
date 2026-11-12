import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Utilitários de cálculo financeiro e matemático para a tela de Nova Venda.
class CalculadoraNovaVenda {
  static double precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  static String valorComVirgula(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  static String doisDigitos(int n) => n.toString().padLeft(2, '0');

  static String dataHoraCompleta(DateTime d) =>
      '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year} '
      '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

  static double calcularValorOuPorcentagem(String texto, double base) {
    final t = texto.trim();
    if (t.isEmpty) return 0.0;
    if (t.contains('%')) {
      final limpo = t.replaceAll('%', '').trim();
      final percentual = precoComoNumero(limpo);
      if (percentual <= 0) return 0.0;
      return base * (percentual / 100.0);
    }
    return precoComoNumero(t);
  }

  static double precoDosAcompanhamentosPorUnidade({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
  }) {
    var soma = 0.0;
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = buscarItem(itemId);
      if (item == null) return;
      soma += precoComoNumero(item.preco) * quantidade;
    });
    return soma;
  }

  static double precoBaseUnitarioDaLinha({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
    required CategoriaLoja? Function(String id) buscarCategoria,
  }) {
    final item = buscarItem(linha.itemId);
    if (item == null) return 0;
    final precoItem = linha.precoVariante.trim().isNotEmpty
        ? precoComoNumero(linha.precoVariante)
        : precoComoNumero(item.preco);
    var soma = precoItem;
    if (linha.categoriaId != null) {
      final categoria = buscarCategoria(linha.categoriaId!);
      if (categoria != null) soma += precoComoNumero(categoria.preco);
    }
    return soma;
  }

  static double precoUnitarioDaLinha({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
    required CategoriaLoja? Function(String id) buscarCategoria,
  }) {
    return precoBaseUnitarioDaLinha(
          linha: linha,
          buscarItem: buscarItem,
          buscarCategoria: buscarCategoria,
        ) +
        precoDosAcompanhamentosPorUnidade(
          linha: linha,
          buscarItem: buscarItem,
        );
  }

  static double subtotalBaseDaLinha({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
    required CategoriaLoja? Function(String id) buscarCategoria,
  }) =>
      precoBaseUnitarioDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      ) *
      linha.quantidade;

  static double subtotalDaLinha({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
    required CategoriaLoja? Function(String id) buscarCategoria,
  }) =>
      precoUnitarioDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      ) *
      linha.quantidade;

  static String resumoAcompanhamentos({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
  }) {
    final partes = <String>[];
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = buscarItem(itemId);
      if (item == null || quantidade <= 0) return;
      final valor = precoComoNumero(item.preco) * quantidade * linha.quantidade;
      partes.add('${quantidade}x ${item.nome} R\$ ${valorComVirgula(valor)}');
    });
    return partes.join(', ');
  }

  static double dividaDoCliente({
    required Cliente cliente,
    required List<PedidoLoja> pedidos,
  }) {
    if (pedidos.isEmpty) return 0.0;
    var soma = 0.0;
    final nomeAlvo = cliente.nome.trim().toLowerCase();
    for (final p in pedidos) {
      final ehDesteCliente = p.clienteId == cliente.id ||
          (nomeAlvo.isNotEmpty &&
              p.clienteNome.trim().toLowerCase() == nomeAlvo);
      if (ehDesteCliente && p.aPrazoEmAberto) {
        soma += p.valorRestante;
      }
    }
    return soma;
  }

  static String obterDadoPrioritarioCliente(Cliente cliente) {
    final end = cliente.endereco.trim();
    final num = cliente.numero.trim();
    final tel = cliente.telefone.trim();

    final enderecoCompleto = end.isNotEmpty
        ? (num.isNotEmpty ? '$end, $num' : end)
        : (num.isNotEmpty ? 'nº $num' : '');

    final partes = <String>[
      if (enderecoCompleto.isNotEmpty) enderecoCompleto,
      if (tel.isNotEmpty) tel,
    ];
    if (partes.isNotEmpty) {
      return partes.join(' • ');
    }

    if (cliente.descricao.trim().isNotEmpty) {
      return cliente.descricao.trim();
    }
    if (cliente.email.trim().isNotEmpty) {
      return cliente.email.trim();
    }
    if (cliente.redesSociais.trim().isNotEmpty) {
      return cliente.redesSociais.trim();
    }
    if (cliente.cnpj.trim().isNotEmpty) {
      return cliente.cnpj.trim();
    }
    return '';
  }
}
