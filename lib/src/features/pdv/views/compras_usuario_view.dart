import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_comentarios_produto.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/compras/secao_carrinho_compras_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/compras/secao_carteira_carcaca_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/compras/secao_historico_compras_widget.dart';

class ComprasUsuarioView extends StatefulWidget {
  const ComprasUsuarioView({super.key});

  @override
  State<ComprasUsuarioView> createState() => _ComprasUsuarioViewState();
}

class _ComprasUsuarioViewState extends State<ComprasUsuarioView> {
  bool _carregando = true;
  List<CarrinhoPendenteLoja> _carrinhos = [];
  List<RegistroCompraUsuario> _historico = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final cpf = auth.contaAtual?.cpf ?? auth.cpf;

    final carrinhos =
        await ComprasUsuarioService.carregarCarrinhosPendentes(pdv);
    await CarrinhoComprasService.sincronizarContagemTotal(pdv);
    final historico = auth.modoVisitante
        ? <RegistroCompraUsuario>[]
        : await ComprasUsuarioService.carregarHistoricoCompras(
            cpfUsuario: cpf,
            pdv: pdv,
          );

    if (!mounted) return;
    setState(() {
      _carrinhos = carrinhos;
      _historico = historico;
      _carregando = false;
    });
  }

  Future<void> _alterarQuantidade(
    CarrinhoPendenteLoja carrinho,
    ItemVendido item,
    int novaQuantidade,
  ) async {
    final pdv = context.read<PdvProvider>();
    await CarrinhoComprasService.atualizarQuantidadeItem(
      pdv: pdv,
      lojaId: carrinho.lojaId,
      itemId: item.itemId,
      varianteNome: item.varianteNome,
      novaQuantidade: novaQuantidade,
    );
    await _carregarDados();
  }

  Future<void> _confirmarLimparCarrinho(
    CarrinhoPendenteLoja carrinho,
    AppTheme theme,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Limpar carrinho?',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.dangerColor,
          ),
        ),
        content: Text(
          'Todos os itens de "${carrinho.loja?.nome ?? 'esta loja'}" serão removidos do seu carrinho.',
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
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.dangerColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Limpar',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final pdv = context.read<PdvProvider>();
      await CarrinhoComprasService.limparCarrinhoLoja(
        pdv: pdv,
        lojaId: carrinho.lojaId,
      );
      await _carregarDados();
    }
  }

  Future<void> _continuarCompra(CarrinhoPendenteLoja carrinho) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VitrineLojaView(
          lojaId: carrinho.lojaId,
          lojaFallback: carrinho.loja,
          abrirCarrinhoInicial: true,
        ),
      ),
    );
    if (mounted) {
      await _carregarDados();
    }
  }

  void _explorarProdutos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BuscaMapaView()),
    );
  }

  void _mostrarDetalhesCompra(RegistroCompraUsuario reg, AppTheme theme) {
    final p = reg.pedido;
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(reg.lojaId);
    final primeiroItemId = p.itens.isNotEmpty ? p.itens.first.itemId : null;
    final itemCatalogo = (loja != null && primeiroItemId != null)
        ? loja.itensLoja.where((i) => i.id == primeiroItemId).firstOrNull
        : null;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Pedido #${p.numero} • ${reg.nomeLoja}',
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.itens.isNotEmpty)
                  ...p.itens.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${it.quantidade}x ${it.nomeItem}${it.varianteNome.isNotEmpty ? ' (${it.varianteNome})' : ''} — R\$ ${it.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  )
                else if (p.produtoNome.isNotEmpty)
                  Text(
                    p.produtoNome,
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.textColor,
                    ),
                  ),
                const SizedBox(height: 10),
                Divider(color: theme.borderColor.withValues(alpha: 0.5)),
                const SizedBox(height: 6),
                Text(
                  'Total: R\$ ${p.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                if (p.formaPagamento.trim().isNotEmpty)
                  Text(
                    'Pagamento: ${p.formaPagamento}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (loja != null && itemCatalogo != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                showDialog<void>(
                  context: context,
                  builder: (_) => DialogComentariosProduto(
                    produto: ProdutoMapaItem(item: itemCatalogo, loja: loja),
                    theme: theme,
                  ),
                );
              },
              icon: Icon(Icons.star_outline_rounded,
                  size: 16, color: theme.textColor),
              label: Text(
                'Avaliar produto',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              final cpf = auth.contaAtual?.cpf ?? auth.cpf;
              final convId =
                  ChatService.conversaIdLojaUsuario(reg.lojaId, cpf);
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MensageriaView(
                    modoLoja: false,
                    conversaInicialId: convId,
                    mostrarBotaoVoltar: true,
                  ),
                ),
              );
            },
            child: Text(
              'Abrir Chat da Loja',
              style: theme.getTextStyle(
                fontSize: 12.5,
                color: theme.textColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerSecao({
    required AppTheme theme,
    required String titulo,
    required IconData icone,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: theme.textColor),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Compras e Carteira',
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                color: theme.textColor,
                onRefresh: _carregarDados,
                child: _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.textColor,
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                            children: [
                              _buildContainerSecao(
                                theme: theme,
                                titulo: 'Carteira',
                                icone: Icons.account_balance_wallet_outlined,
                                child: SecaoCarteiraCarcacaWidget(theme: theme),
                              ),
                              _buildContainerSecao(
                                theme: theme,
                                titulo: 'Carrinho',
                                icone: Icons.shopping_cart_outlined,
                                child: SecaoCarrinhoComprasWidget(
                                  theme: theme,
                                  carrinhos: _carrinhos,
                                  onExplorarProdutos: _explorarProdutos,
                                  onContinuarCompra: _continuarCompra,
                                  onLimparCarrinho: (c) =>
                                      _confirmarLimparCarrinho(c, theme),
                                  onAlterarQuantidade: _alterarQuantidade,
                                ),
                              ),
                              _buildContainerSecao(
                                theme: theme,
                                titulo: 'Histórico de Compras',
                                icone: Icons.history_rounded,
                                child: SecaoHistoricoComprasWidget(
                                  theme: theme,
                                  modoVisitante: auth.modoVisitante,
                                  historico: _historico,
                                  onAbrirDetalhes: (reg) =>
                                      _mostrarDetalhesCompra(reg, theme),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingBottomNavBar(
                  maxWidth: 600,
                  slotSelecionado: 0,
                  subIndiceSelecionado: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
