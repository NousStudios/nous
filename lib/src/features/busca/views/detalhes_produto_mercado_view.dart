import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/models/avaliacao_produto.dart';
import 'package:nous/src/features/busca/services/avaliacoes_produto_service.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_adicionar_carrinho_variantes.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_comentarios_produto.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class DetalhesProdutoMercadoView extends StatefulWidget {
  final ProdutoMapaItem produto;

  const DetalhesProdutoMercadoView({
    super.key,
    required this.produto,
  });

  @override
  State<DetalhesProdutoMercadoView> createState() =>
      _DetalhesProdutoMercadoViewState();
}

class _DetalhesProdutoMercadoViewState
    extends State<DetalhesProdutoMercadoView> {
  ResumoAvaliacoesProduto? _resumoAvaliacoes;

  @override
  void initState() {
    super.initState();
    AvaliacoesProdutoService.versaoAtualizacao.addListener(_carregarResumo);
    _carregarResumo();
  }

  @override
  void dispose() {
    AvaliacoesProdutoService.versaoAtualizacao.removeListener(_carregarResumo);
    super.dispose();
  }

  Future<void> _carregarResumo() async {
    final resumo = await AvaliacoesProdutoService.obterResumoEstrelas(
      widget.produto.item.id,
    );
    if (mounted) {
      setState(() {
        _resumoAvaliacoes = resumo;
      });
    }
  }

  void _abrirComentarios(AppTheme theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogComentariosProduto(
        produto: widget.produto,
        theme: theme,
        aoAtualizar: _carregarResumo,
      ),
    );
  }

  void _abrirDialogAdicionarCarrinho(AppTheme theme) {
    final pdv = context.read<PdvProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogAdicionarCarrinhoVariantes(
        produto: widget.produto,
        theme: theme,
        pdv: pdv,
      ),
    );
  }

  Future<void> _compartilharResumo(AppTheme theme) async {
    final loja = widget.produto.loja;
    final texto =
        '${widget.produto.nomeExibicao} — ${loja.nome} (${widget.produto.precoTexto})';
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Resumo copiado para a área de transferência!',
          style: theme.getTextStyle(color: theme.buttonTextColor),
        ),
        backgroundColor: theme.buttonColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final item = widget.produto.item;
        final loja = widget.produto.loja;
        final fotoUrl = widget.produto.fotoDestaque;
        final mediaEstrelas = _resumoAvaliacoes?.mediaEstrelas ?? 5.0;
        final totalAvaliacoes = _resumoAvaliacoes?.totalAvaliacoes ?? 0;
        final precoTexto = widget.produto.precoTexto;
        final logoProvider = ImagemService.obterImageProvider(loja.logo);

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Cabeçalho limpo com botão X à direita (conforme protótipo)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.tipo?.name == 'servico'
                                ? 'Detalhes do Serviço'
                                : 'Detalhes do Produto',
                            style: theme.getTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar',
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.textColor,
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Foto principal
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: AspectRatio(
                                    aspectRatio: 1.25,
                                    child: ImagemService.construirImagem(
                                      fotoUrl,
                                      fit: BoxFit.cover,
                                      fallback: _placeholderGrande(theme),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 2. Nome e curta descrição / especificações
                                Text(
                                  widget.produto.nomeExibicao,
                                  style: theme.getTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 3. Linha Loja (esquerda, SEM estrelas) + Estrelas acima de Comentários (direita)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: theme.borderColor
                                                .withValues(alpha: 0.3),
                                            backgroundImage: logoProvider,
                                            child: logoProvider == null
                                                ? Icon(
                                                    Icons.storefront_outlined,
                                                    size: 16,
                                                    color: theme.textColor,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  loja.nome,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme.getTextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                                Text(
                                                  widget.produto
                                                      .distanciaFormatada,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme.getTextStyle(
                                                    fontSize: 11,
                                                    color: theme
                                                        .secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Estrelas acima de "Comentários" (padrão Mercado Livre pedido pelo usuário)
                                    InkWell(
                                      onTap: () => _abrirComentarios(theme),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.cardBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: theme.borderColor
                                                .withValues(alpha: 0.65),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...List.generate(5, (index) {
                                                  final v = index + 1;
                                                  return Icon(
                                                    v <= mediaEstrelas.round()
                                                        ? Icons.star_rounded
                                                        : Icons
                                                            .star_outline_rounded,
                                                    size: 15,
                                                    color: theme.textColor,
                                                  );
                                                }),
                                                const SizedBox(width: 4),
                                                Text(
                                                  mediaEstrelas
                                                      .toStringAsFixed(1),
                                                  style: theme.getTextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.comment_outlined,
                                                  size: 13,
                                                  color:
                                                      theme.secondaryTextColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Comentários ($totalAvaliacoes)',
                                                  style: theme.getTextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // 4. Valor + Ações (Adicionar ao carrinho e Compartilhar)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            precoTexto,
                                            style: theme.getTextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.possuiDelivery
                                                ? (item.freteGratisAte
                                                        .trim()
                                                        .isNotEmpty
                                                    ? 'Delivery • Frete grátis até ${item.freteGratisAte} km'
                                                    : 'Entrega disponível e retirada na loja')
                                                : 'Retirada no balcão / combinar com a loja',
                                            style: theme.getTextStyle(
                                              fontSize: 12,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Adicionar ao Carrinho',
                                      onPressed: () =>
                                          _abrirDialogAdicionarCarrinho(theme),
                                      icon: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.buttonColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.add_shopping_cart_rounded,
                                          color: theme.buttonTextColor,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Compartilhar',
                                      onPressed: () =>
                                          _compartilharResumo(theme),
                                      icon: Icon(
                                        Icons.share_outlined,
                                        color: theme.textColor,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Botão largo "Adicionar ao Carrinho" para facilitar o toque
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.buttonColor,
                                      foregroundColor: theme.buttonTextColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _abrirDialogAdicionarCarrinho(theme),
                                    icon: const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Adicionar ao Carrinho',
                                      style: theme.getTextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: theme.buttonTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Divider(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),

                                // 5. Descrição
                                Center(
                                  child: Text(
                                    'Descrição',
                                    style: theme.getTextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.descricao.trim().isNotEmpty
                                      ? item.descricao
                                      : 'Produto cadastrado por ${loja.nome}. Consulte variações ao adicionar ao carrinho.',
                                  style: theme.getTextStyle(
                                    fontSize: 13.5,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Barra de navegação universal flutuante (para receber o pacote animado!)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FloatingBottomNavBar(
                    maxWidth: 600,
                    slotSelecionado: 2,
                    subIndiceSelecionado: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderGrande(AppTheme theme) {
    return Container(
      color: theme.cardBackgroundColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 58,
          color: theme.secondaryTextColor.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
