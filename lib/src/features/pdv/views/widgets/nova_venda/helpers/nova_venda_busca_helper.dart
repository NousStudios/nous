import 'package:flutter/material.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Operações de busca, filtragem e exibição de campos de cliente na nova venda.
class NovaVendaBuscaHelper {
  const NovaVendaBuscaHelper._();

  static String _normalizarAlfanumerico(String valor) =>
      valor.trim().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

  /// Filtra categorias cujo nome corresponde ao termo digitado.
  static List<CategoriaLoja> filtrarCategorias({
    required String termo,
    required List<CategoriaLoja> categoriasDisponiveis,
  }) {
    final limpo = termo.trim();
    if (limpo.isEmpty) return [];
    return categoriasDisponiveis
        .where((c) => TextoUtils.contemIgnorandoAcentos(c.nome, limpo))
        .toList();
  }

  /// Filtra itens por nome ou código de barras, excluindo os já listados via categorias encontradas.
  static List<ItemLoja> filtrarItens({
    required String termo,
    required List<ItemLoja> itensDisponiveis,
    required List<CategoriaLoja> categoriasEncontradas,
  }) {
    final limpo = termo.trim();
    if (limpo.isEmpty) return [];
    final idsDeItensEmCategoriasEncontradas = <String>{};
    for (final categoria in categoriasEncontradas) {
      idsDeItensEmCategoriasEncontradas.addAll(categoria.itemIds);
    }
    final termoLimpo = _normalizarAlfanumerico(limpo);
    return itensDisponiveis
        .where((item) {
          final nomeMatch = TextoUtils.contemIgnorandoAcentos(item.nome, limpo);
          final codigoLimpo = _normalizarAlfanumerico(item.codigoBarras);
          final codigoMatch = codigoLimpo.isNotEmpty &&
              (codigoLimpo == termoLimpo || codigoLimpo.contains(termoLimpo));
          return nomeMatch || codigoMatch;
        })
        .where((item) => !idsDeItensEmCategoriasEncontradas.contains(item.id))
        .toList();
  }

  /// Trata a submissão do campo de busca por código de barras exato ou resultado único.
  static void aoSubmeterBusca({
    required String valor,
    required List<ItemLoja> itensDisponiveis,
    required List<ItemLoja> itensEncontrados,
    required void Function(String itemId) onAdicionarItem,
    required VoidCallback onLimparBusca,
  }) {
    final termo = valor.trim();
    if (termo.isEmpty) return;
    final termoLimpo = _normalizarAlfanumerico(termo);

    final itemPorCodigo = itensDisponiveis.where((i) {
      final codigo = _normalizarAlfanumerico(i.codigoBarras);
      return codigo.isNotEmpty && codigo == termoLimpo;
    }).firstOrNull;

    if (itemPorCodigo != null) {
      onAdicionarItem(itemPorCodigo.id);
      onLimparBusca();
      return;
    }

    if (itensEncontrados.length == 1) {
      onAdicionarItem(itensEncontrados.first.id);
      onLimparBusca();
    }
  }

  /// Filtra sugestões de clientes pelo termo digitado.
  static List<Cliente> filtrarClientes({
    required String termo,
    required List<Cliente> clientes,
  }) {
    final limpo = termo.trim();
    if (limpo.isEmpty) return clientes;
    return clientes.where((cliente) => cliente.correspondeABusca(limpo)).toList();
  }

  /// Verifica se determinado campo do cliente deve aparecer na comanda.
  static bool deveMostrarCampoCliente({
    required ConfiguracoesImpressora config,
    required String chave,
  }) {
    final configCampos = config.camposClienteComanda;
    final ehPadraoAntigoCompleto = !config.camposClientePersonalizados &&
        configCampos.length == kCamposClienteComanda.length &&
        kCamposClienteComanda.every((ch) => configCampos.contains(ch));

    final camposAtivos =
        ehPadraoAntigoCompleto ? kCamposClienteComandaPadrao : configCampos;

    return camposAtivos.contains(chave);
  }

  /// Atualiza o estado do cliente ao digitar no campo de cliente.
  static Cliente? aoDigitarCliente({
    required String texto,
    required Cliente? clienteSelecionado,
    required bool temAPrazo,
    required void Function(String forma) onRemoverForma,
    required String formaAPrazo,
  }) {
    if (clienteSelecionado != null && clienteSelecionado.nome != texto) {
      if (temAPrazo) onRemoverForma(formaAPrazo);
      return null;
    }
    return clienteSelecionado;
  }

  /// Aplica o cliente selecionado aos controllers de nome e frete padrão.
  static void aplicarClienteSelecionado({
    required Cliente cliente,
    required TextEditingController clienteController,
    required TextEditingController freteController,
  }) {
    clienteController.text = cliente.nome;
    if (cliente.fretePadrao > 0) {
      freteController.text =
          cliente.fretePadrao.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  /// Sincroniza o cliente selecionado após retornar da tela de clientes.
  static Future<Cliente?> sincronizarClienteAposAbrir({
    required Cliente? clienteSelecionado,
    required Future<void> Function() aoAbrirClientes,
    required Cliente? Function(String id) buscarCliente,
    required TextEditingController clienteController,
    required bool temAPrazo,
    required void Function(String forma) onRemoverForma,
    required String formaAPrazo,
  }) async {
    await aoAbrirClientes();
    final id = clienteSelecionado?.id;
    if (id == null) return clienteSelecionado;
    final atualizado = buscarCliente(id);
    if (atualizado != null) {
      clienteController.text = atualizado.nome;
    } else if (temAPrazo) {
      onRemoverForma(formaAPrazo);
    }
    return atualizado;
  }
}
