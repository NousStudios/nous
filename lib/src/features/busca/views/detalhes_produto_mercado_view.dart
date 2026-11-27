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
import 'package:nous/src/features/busca/views/widgets/detalhes_produto/cabecalho_loja_e_avaliacoes_produto_widget.dart';
import 'package:nous/src/features/busca/views/widgets/detalhes_produto/galeria_fotos_produto_widget.dart';
import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/visualizador_galeria_dialog.dart';

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
  VarianteItem? _varianteSelecionada;
  int _fotoAtual = 0;

  @override
  void initState() {
    super.initState();
    if (widget.produto.item.variantes.isNotEmpty) {
      _varianteSelecionada = widget.produto.item.variantes.first;
    }
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
    if (!widget.produto.item.ativo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Este item está temporariamente indisponível na loja.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
          backgroundColor: theme.cardBackgroundColor,
        ),
      );
      return;
    }
    final pdv = context.read<PdvProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => DialogAdicionarCarrinhoVariantes(
        produto: widget.produto,
        theme: theme,
        pdv: pdv,
        varianteInicial: _varianteSelecionada,
      ),
    );
  }

  void _abrirPerfilPublicoLoja() {
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

  void _abrirImagemTelaCheia(AppTheme theme, List<String> fotos) {
    if (fotos.isEmpty) return;
    VisualizadorGaleriaDialog.mostrar(
      context,
      theme: theme,
      imagens: fotos,
      indiceInicial: _fotoAtual.clamp(0, fotos.length - 1),
    );
  }

  String _precoExibicaoAtual() {
    if (_varianteSelecionada != null) {
      final pVar = CarrinhoComprasService.parsePreco(_varianteSelecionada!.preco);
      final pCat = widget.produto.categoria != null
          ? CarrinhoComprasService.parsePreco(widget.produto.categoria!.preco)
          : 0.0;
      if (pVar > 0) {
        final total = pVar + pCat;
        return 'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
      }
    }
    return widget.produto.precoTexto;
  }

  String _textoEntrega() {
    final item = widget.produto.item;
    if (!item.possuiDelivery) {
      return 'Retirada no balcão / combinar com a loja';
    }
    final partes = <String>['Delivery'];
    if (item.freteGratisAte.trim().isNotEmpty) {
      partes.add('Frete grátis até ${item.freteGratisAte} km');
    }
    if (item.valorPorKm.trim().isNotEmpty) {
      partes.add('Taxa: R\$ ${item.valorPorKm}/km');
    }
    if (partes.length == 1) {
      return 'Entrega disponível e retirada na loja';
    }
    return partes.join(' • ');
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
        final fotos = widget.produto.todasFotos;
        final mediaEstrelas = _resumoAvaliacoes?.mediaEstrelas ?? 0.0;
        final totalAvaliacoes = _resumoAvaliacoes?.totalAvaliacoes ?? 0;
        final precoTexto = _precoExibicaoAtual();

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Cabeçalho com seta para voltar à esquerda e título logo ao lado
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Voltar',
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: theme.textColor,
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.tipo?.name == 'servico'
                                  ? 'Detalhes do Serviço'
                                  : 'Detalhes do Produto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
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
                                // 1. Foto(s) principal(is) com clique para tela cheia
                                GaleriaFotosProdutoWidget(
                                  theme: theme,
                                  fotos: fotos,
                                  fotoAtual: _fotoAtual,
                                  onTrocarFoto: (i) {
                                    setState(() => _fotoAtual = i);
                                  },
                                  onAbrirTelaCheia: () =>
                                      _abrirImagemTelaCheia(theme, fotos),
                                ),
                                const SizedBox(height: 14),

                                // Badges de status visual (Ativo/Inativo e Loja Aberta/Fechada)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.ativo
                                            ? theme.cardBackgroundColor
                                            : theme.dangerColor
                                                .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: item.ativo
                                              ? theme.borderColor
                                                  .withValues(alpha: 0.7)
                                              : theme.dangerColor,
                                        ),
                                      ),
                                      child: Text(
                                        item.ativo ? 'Ativo' : 'Indisponível',
                                        style: theme.getTextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: item.ativo
                                              ? theme.textColor
                                              : theme.dangerColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: theme.borderColor
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      child: Text(
                                        loja.aberta
                                            ? 'Loja aberta'
                                            : 'Loja fechada',
                                        style: theme.getTextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // 2. Nome
                                Text(
                                  widget.produto.nomeExibicao,
                                  style: theme.getTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 3. Linha Loja (clicável para Perfil Público) + Estrelas/Comentários (direita)
                                CabecalhoLojaEAvaliacoesProdutoWidget(
                                  theme: theme,
                                  loja: loja,
                                  distanciaFormatada:
                                      widget.produto.distanciaFormatada,
                                  mediaEstrelas: mediaEstrelas,
                                  totalAvaliacoes: totalAvaliacoes,
                                  onAbrirLoja: _abrirPerfilPublicoLoja,
                                  onAbrirComentarios: () =>
                                      _abrirComentarios(theme),
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
                                            _textoEntrega(),
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
                                          color: item.ativo
                                              ? theme.buttonColor
                                              : theme.borderColor
                                                  .withValues(alpha: 0.4),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.add_shopping_cart_rounded,
                                          color: item.ativo
                                              ? theme.buttonTextColor
                                              : theme.secondaryTextColor,
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

                                if (item.variantes.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    'Opções / Variantes',
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: item.variantes.map((v) {
                                      final selecionada =
                                          _varianteSelecionada?.nome == v.nome;
                                      final pv =
                                          CarrinhoComprasService.parsePreco(
                                        v.preco,
                                      );
                                      final pCat = widget.produto.categoria !=
                                              null
                                          ? CarrinhoComprasService.parsePreco(
                                              widget.produto.categoria!.preco,
                                            )
                                          : 0.0;
                                      final precoVar = pv > 0 ? pv + pCat : 0.0;
                                      final label = precoVar > 0
                                          ? '${v.nome} • R\$ ${precoVar.toStringAsFixed(2).replaceAll('.', ',')}'
                                          : v.nome;
                                      return ChoiceChip(
                                        label: Text(
                                          label,
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: selecionada
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: selecionada
                                                ? theme.buttonTextColor
                                                : theme.textColor,
                                          ),
                                        ),
                                        selected: selecionada,
                                        selectedColor: theme.buttonColor,
                                        backgroundColor:
                                            theme.cardBackgroundColor,
                                        side: BorderSide(
                                          color: selecionada
                                              ? theme.buttonColor
                                              : theme.borderColor
                                                  .withValues(alpha: 0.65),
                                        ),
                                        onSelected: (_) {
                                          setState(
                                            () => _varianteSelecionada = v,
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 14),

                                // Botão largo "Adicionar ao Carrinho" para facilitar o toque
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: item.ativo
                                          ? theme.buttonColor
                                          : theme.borderColor
                                              .withValues(alpha: 0.4),
                                      foregroundColor: item.ativo
                                          ? theme.buttonTextColor
                                          : theme.secondaryTextColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _abrirDialogAdicionarCarrinho(theme),
                                    icon: Icon(
                                      item.ativo
                                          ? Icons.add_shopping_cart_rounded
                                          : Icons.block_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      item.ativo
                                          ? 'Adicionar ao Carrinho'
                                          : 'Produto Indisponível',
                                      style: theme.getTextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: item.ativo
                                            ? theme.buttonTextColor
                                            : theme.secondaryTextColor,
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
}
