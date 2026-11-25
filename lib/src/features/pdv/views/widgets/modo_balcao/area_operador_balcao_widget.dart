import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/campo_bipador_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/catalogo_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/cliente_ajustes_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/visor_ultimo_produto_widget.dart';

/// Coluna esquerda do Modo Balcão: bipador, visor do último produto, catálogo e cliente/ajustes.
class AreaOperadorBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController bipadorController;
  final FocusNode bipadorFocusNode;
  final ItemLoja? ultimoItemBipado;
  final ItemVendido? ultimoItemVendido;
  final int quantidadeUltimoBipado;
  final List<CategoriaLoja> categorias;
  final String? categoriaFiltroId;
  final List<ItemLoja> itensFiltrados;
  final List<Cliente> clientes;
  final List<Cliente> sugestoesClientes;
  final Cliente? clienteSelecionado;
  final bool mostrarSugestoesCliente;
  final TextEditingController clienteController;
  final FocusNode clienteFocusNode;
  final TextEditingController descontoController;
  final TextEditingController freteController;
  final TextEditingController acrescimoController;
  final ValueChanged<String> onChangedBipador;
  final VoidCallback onSubmittedBipador;
  final VoidCallback onLimparBipador;
  final String Function(double valor) formatarValor;
  final double Function(String itemId) obterSaldoEstoque;
  final ValueChanged<String?> onSelecionarCategoria;
  final ValueChanged<ItemLoja> onSelecionarItem;
  final double Function(Cliente cliente) obterDividaCliente;
  final ValueChanged<Cliente> onSelecionarCliente;
  final VoidCallback onRemoverCliente;
  final ValueChanged<bool> onAlterarVisibilidadeSugestoes;
  final VoidCallback onGarantirFocoBipador;
  final VoidCallback onAjusteAlterado;

  const AreaOperadorBalcaoWidget({
    super.key,
    required this.theme,
    required this.bipadorController,
    required this.bipadorFocusNode,
    required this.ultimoItemBipado,
    required this.ultimoItemVendido,
    required this.quantidadeUltimoBipado,
    required this.categorias,
    required this.categoriaFiltroId,
    required this.itensFiltrados,
    required this.clientes,
    required this.sugestoesClientes,
    required this.clienteSelecionado,
    required this.mostrarSugestoesCliente,
    required this.clienteController,
    required this.clienteFocusNode,
    required this.descontoController,
    required this.freteController,
    required this.acrescimoController,
    required this.onChangedBipador,
    required this.onSubmittedBipador,
    required this.onLimparBipador,
    required this.formatarValor,
    required this.obterSaldoEstoque,
    required this.onSelecionarCategoria,
    required this.onSelecionarItem,
    required this.obterDividaCliente,
    required this.onSelecionarCliente,
    required this.onRemoverCliente,
    required this.onAlterarVisibilidadeSugestoes,
    required this.onGarantirFocoBipador,
    required this.onAjusteAlterado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoBipadorBalcaoWidget(
            theme: theme,
            controller: bipadorController,
            focusNode: bipadorFocusNode,
            onChanged: onChangedBipador,
            onSubmitted: onSubmittedBipador,
            onLimpar: onLimparBipador,
          ),
          const SizedBox(height: 12),
          VisorUltimoProdutoWidget(
            theme: theme,
            item: ultimoItemBipado,
            itemVendido: ultimoItemVendido,
            quantidade: quantidadeUltimoBipado,
            formatarValor: formatarValor,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CatalogoBalcaoWidget(
              theme: theme,
              categorias: categorias,
              categoriaFiltroId: categoriaFiltroId,
              itens: itensFiltrados,
              obterSaldoEstoque: obterSaldoEstoque,
              onSelecionarCategoria: onSelecionarCategoria,
              onSelecionarItem: onSelecionarItem,
            ),
          ),
          const SizedBox(height: 10),
          ClienteAjustesBalcaoWidget(
            theme: theme,
            clientes: clientes,
            sugestoesClientes: sugestoesClientes,
            clienteSelecionado: clienteSelecionado,
            mostrarSugestoesCliente: mostrarSugestoesCliente,
            clienteController: clienteController,
            clienteFocusNode: clienteFocusNode,
            descontoController: descontoController,
            freteController: freteController,
            acrescimoController: acrescimoController,
            obterDividaCliente: obterDividaCliente,
            onSelecionarCliente: onSelecionarCliente,
            onRemoverCliente: onRemoverCliente,
            onAlterarVisibilidadeSugestoes: onAlterarVisibilidadeSugestoes,
            onGarantirFocoBipador: onGarantirFocoBipador,
            onAjusteAlterado: onAjusteAlterado,
          ),
        ],
      ),
    );
  }
}
