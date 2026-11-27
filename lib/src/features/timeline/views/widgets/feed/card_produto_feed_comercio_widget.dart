import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/views/detalhes_produto_mercado_view.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_adicionar_carrinho_variantes.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_comentarios_produto.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';

/// Card de produto próximo para a aba "Comércio" do Feed de Descoberta,
/// seguindo o padrão visual de publicação da rede social do Nous.
class CardProdutoFeedComercioWidget extends StatefulWidget {
  final AppTheme theme;
  final ProdutoMapaItem produto;

  const CardProdutoFeedComercioWidget({
    super.key,
    required this.theme,
    required this.produto,
  });

  @override
  State<CardProdutoFeedComercioWidget> createState() =>
      _CardProdutoFeedComercioWidgetState();
}

class _CardProdutoFeedComercioWidgetState
    extends State<CardProdutoFeedComercioWidget> {
  int _fotoAtual = 0;

  void _abrirDetalhes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesProdutoMercadoView(produto: widget.produto),
      ),
    );
  }

  void _abrirPerfilLoja() {
    final loja = widget.produto.loja;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VitrineLojaView(
          lojaId: loja.id,
          lojaFallback: loja,
        ),
      ),
    );
  }

  void _abrirCarrinho() {
    final pdv = context.read<PdvProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => DialogAdicionarCarrinhoVariantes(
        produto: widget.produto,
        theme: widget.theme,
        pdv: pdv,
      ),
    );
  }

  void _abrirAvaliacoes() {
    showDialog<void>(
      context: context,
      builder: (_) => DialogComentariosProduto(
        produto: widget.produto,
        theme: widget.theme,
      ),
    );
  }

  Future<void> _compartilhar() async {
    final loja = widget.produto.loja;
    final texto =
        '${widget.produto.nomeExibicao} — ${loja.nome} (${widget.produto.precoTexto})';
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Produto copiado para compartilhar!',
          style: widget.theme.getTextStyle(color: widget.theme.buttonTextColor),
        ),
        backgroundColor: widget.theme.buttonColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final loja = widget.produto.loja;
    final item = widget.produto.item;
    final fotos = widget.produto.todasFotos;
    final logoProvider = ImagemService.obterImageProvider(loja.logo);
    final largura = MediaQuery.sizeOf(context).width;
    final alturaMidia = largura < 600 ? 300.0 : 380.0;

    return Card(
      color: theme.cardBackgroundColor,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho da Loja (padrão CabecalhoAutorColaboradoresWidget)
          InkWell(
            onTap: _abrirPerfilLoja,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                    backgroundImage: logoProvider,
                    child: logoProvider == null
                        ? Icon(
                            Icons.storefront_outlined,
                            size: 18,
                            color: theme.textColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loja.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          loja.cidade.trim().isNotEmpty
                              ? '${widget.produto.distanciaFormatada} • ${loja.cidade}'
                              : widget.produto.distanciaFormatada,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      loja.aberta ? 'Aberta' : 'Fechada',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Mídia do Produto (clicável para abrir Detalhes do Produto)
          if (fotos.isNotEmpty)
            GestureDetector(
              onTap: _abrirDetalhes,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: alturaMidia),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: fotos.length,
                        onPageChanged: (i) => setState(() => _fotoAtual = i),
                        itemBuilder: (_, index) => ImagemService.construirImagem(
                          fotos[index],
                          fit: BoxFit.cover,
                          cacheWidth: 680,
                        ),
                      ),
                      if (fotos.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_fotoAtual + 1}/${fotos.length}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Barra de ações + preço (padrão barra horizontal da rede social)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _BotaoAcaoProduto(
                          theme: theme,
                          icone: Icons.shopping_bag_outlined,
                          rotulo: 'Ver produto',
                          onTap: _abrirDetalhes,
                        ),
                        const SizedBox(width: 6),
                        _BotaoAcaoProduto(
                          theme: theme,
                          icone: Icons.add_shopping_cart_rounded,
                          rotulo: 'Carrinho',
                          onTap: _abrirCarrinho,
                        ),
                        const SizedBox(width: 6),
                        _BotaoAcaoProduto(
                          theme: theme,
                          icone: Icons.star_outline_rounded,
                          rotulo: 'Avaliar',
                          onTap: _abrirAvaliacoes,
                        ),
                        const SizedBox(width: 6),
                        _BotaoAcaoProduto(
                          theme: theme,
                          icone: Icons.send_rounded,
                          rotulo: '',
                          onTap: _compartilhar,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.produto.precoTexto,
                  style: theme.getTextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),

          // 4. Legenda com nome e descrição do produto
          InkWell(
            onTap: _abrirDetalhes,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.produto.nomeExibicao,
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  if (item.descricao.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.descricao,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoAcaoProduto extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoAcaoProduto({
    required this.theme,
    required this.icone,
    required this.rotulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 15, color: theme.textColor),
            if (rotulo.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
