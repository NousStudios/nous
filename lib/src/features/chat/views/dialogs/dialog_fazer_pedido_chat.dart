import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_editar_ficha_cliente_loja.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/modal_personalizar_item_autoatendimento.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Modal completo de Autoatendimento no Chat: navegação de categorias,
/// cardápio interativo, acompanhamentos, carrinho e envio direto para a aba "Novos" da loja.
class DialogFazerPedidoChat extends StatefulWidget {
  final AppTheme theme;
  final ConversaChat conversa;
  final MensageriaController controller;

  const DialogFazerPedidoChat({
    super.key,
    required this.theme,
    required this.conversa,
    required this.controller,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ConversaChat conversa,
    required MensageriaController controller,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DialogFazerPedidoChat(
        theme: theme,
        conversa: conversa,
        controller: controller,
      ),
    );
  }

  @override
  State<DialogFazerPedidoChat> createState() => _DialogFazerPedidoChatState();
}

class _DialogFazerPedidoChatState extends State<DialogFazerPedidoChat> {
  String? _categoriaSelecionadaId;
  final List<ItemVendido> _carrinho = [];
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _buscaItensController = TextEditingController();
  String _termoBuscaItens = '';
  String _formaPagamento = 'PIX';
  bool _enviando = false;
  bool _vendoCarrinho = false;
  bool _carregandoLoja = true;
  Loja? _lojaResolvida;

  @override
  void initState() {
    super.initState();
    _carregarCatalogoLoja();
  }

  Future<void> _carregarCatalogoLoja() async {
    final pdv = context.read<PdvProvider>();
    final idBruto =
        (widget.conversa.lojaId != null && widget.conversa.lojaId!.isNotEmpty)
        ? widget.conversa.lojaId!
        : (widget.conversa.identificador.isNotEmpty
              ? widget.conversa.identificador
              : widget.conversa.id);
    final loja = await ChatAutoatendimentoService.obterLojaCatalogo(
      lojaIdBruto: idBruto,
      pdv: pdv,
    );
    if (mounted) {
      setState(() {
        _lojaResolvida = loja;
        _carregandoLoja = false;
      });
    }
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    _buscaItensController.dispose();
    super.dispose();
  }

  double _parsePreco(String p) =>
      double.tryParse(p.replaceAll(',', '.')) ?? 0.0;

  double get _totalCarrinho => _carrinho.fold(0.0, (s, i) => s + i.subtotal);
  int get _quantidadeTotal => _carrinho.fold(0, (s, i) => s + i.quantidade);

  String _formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  void _adicionarItemDireto(ItemLoja item, {CategoriaLoja? cat}) {
    setState(() {
      final precoItem = _parsePreco(item.preco);
      final precoCat = cat != null ? _parsePreco(cat.preco) : 0.0;
      final idx = _carrinho.indexWhere(
        (i) =>
            i.itemId == item.id &&
            i.categoriaId == cat?.id &&
            i.acompanhamentos.isEmpty &&
            i.observacao.isEmpty &&
            i.varianteNome.isEmpty,
      );
      if (idx != -1) {
        final atual = _carrinho[idx];
        _carrinho[idx] = atual.copyWith(quantidade: atual.quantidade + 1);
      } else {
        _carrinho.add(
          ItemVendido(
            itemId: item.id,
            nomeItem: item.nome,
            foto: item.imagens.isNotEmpty ? item.imagens.first : '',
            categoriaId: cat?.id,
            nomeCategoria: cat?.nome,
            precoCategoria: precoCat,
            precoItem: precoItem,
            quantidade: 1,
            acompanhamentos: const [],
          ),
        );
      }
    });
  }

  void _interagirComItem(ItemLoja item, Loja loja, CategoriaLoja? cat) {
    final temGrupos = cat != null && cat.grupoIds.isNotEmpty;
    final temVariantes = item.variantes.isNotEmpty;
    if (temGrupos || temVariantes) {
      _abrirPersonalizacao(item, loja, cat);
    } else {
      _adicionarItemDireto(item, cat: cat);
    }
  }

  void _abrirPersonalizacao(ItemLoja? item, Loja loja, CategoriaLoja? cat) {
    ModalPersonalizarItemAutoatendimento.mostrar(
      context: context,
      theme: widget.theme,
      item: item,
      categoria: cat,
      gruposDisponiveis: loja.gruposComponentesLoja,
      todosItens: loja.itensLoja,
      onConfirmar: (itemPersonalizado) {
        setState(() {
          _carrinho.add(itemPersonalizado);
        });
      },
    );
  }

  Future<void> _abrirMinhaFichaCliente(Loja loja) async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final usuario =
        auth.contaAtual ??
        UsuarioNous(
          cpf: auth.cpf,
          nome: auth.contaAtual?.nome ?? 'Cliente',
          dataNascimento: '',
        );
    final cliente = await ChatAutoatendimentoService.resolverOuCriarFichaCliente(
      loja: loja,
      usuario: usuario,
      pdv: pdv,
    );
    if (!mounted) return;
    await DialogEditarFichaClienteLoja.mostrar(
      context: context,
      theme: widget.theme,
      lojaId: loja.id,
      cliente: cliente,
    );
  }

  Future<void> _finalizarPedido(Loja loja) async {
    if (_carrinho.isEmpty || _enviando) return;
    final ctxPai = Navigator.of(context).context;
    setState(() => _enviando = true);

    final geradoPelaLoja = widget.controller.modoLoja;

    try {
      final pedido =
          await ChatAutoatendimentoService.enviarPedidoAutoatendimento(
            context: context,
            lojaId: loja.id,
            carrinho: _carrinho,
            observacaoGeral: _observacaoController.text.trim(),
            formaPagamento: _formaPagamento,
            controller: widget.controller,
            geradoPelaLoja: geradoPelaLoja,
            identificadorClienteConversa: widget.conversa.identificador,
            nomeClienteConversa: widget.conversa.titulo,
            fotoClienteConversa: widget.conversa.foto,
          );

      if (mounted) {
        Navigator.pop(context);
        if (ctxPai.mounted) {
          if (geradoPelaLoja) {
            ScaffoldMessenger.of(ctxPai).showSnackBar(
              SnackBar(
                backgroundColor: widget.theme.cardBackgroundColor,
                content: Text(
                  'Proposta de comanda enviada para o cliente no chat! O pedido entrará em "Novos" assim que for aprovado.',
                  style: widget.theme.getTextStyle(
                    color: widget.theme.textColor,
                    fontSize: 12.5,
                  ),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            _mostrarConfirmacaoComFicha(ctxPai, loja, pedido);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: widget.theme.dangerColor,
            content: Text(
              'Erro ao enviar pedido: $e',
              style: widget.theme.getTextStyle(
                color: widget.theme.buttonTextColor,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarConfirmacaoComFicha(
    BuildContext hostContext,
    Loja loja,
    PedidoLoja pedido,
  ) {
    final pdv = hostContext.read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(loja.id) ?? loja;
    final cliente =
        lojaAtual.clientesLoja
            .where((c) => c.id == pedido.clienteId)
            .firstOrNull ??
        Cliente(id: pedido.clienteId ?? '', nome: pedido.clienteNome);

    showDialog(
      context: hostContext,
      builder: (ctx) {
        final theme = widget.theme;
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: theme.buttonColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedido Enviado para a Loja!',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu pedido #${pedido.numero.toString().padLeft(4, '0')} foi despachado no chat e já está na aba "Novos" do balcão de ${lojaAtual.nome}.',
                style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meus dados cadastrados na loja:',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cliente.nome} • ${cliente.telefone.isNotEmpty ? cliente.telefone : 'Sem telefone'}',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    if (cliente.endereco.isNotEmpty)
                      Text(
                        '${cliente.endereco}${cliente.numero.isNotEmpty ? ', Nº ${cliente.numero}' : ''}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                DialogEditarFichaClienteLoja.mostrar(
                  context: hostContext,
                  theme: theme,
                  lojaId: lojaAtual.id,
                  cliente: cliente,
                );
              },
              child: Text(
                'Editar meus dados na Loja',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.buttonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Concluir',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pdv = context.watch<PdvProvider>();
    final idBruto =
        (widget.conversa.lojaId != null && widget.conversa.lojaId!.isNotEmpty)
        ? widget.conversa.lojaId!
        : (widget.conversa.identificador.isNotEmpty
              ? widget.conversa.identificador
              : widget.conversa.id);
    final loja = pdv.buscarPorId(idBruto) ?? _lojaResolvida;

    if (_carregandoLoja && loja == null) {
      return Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.buttonColor),
              const SizedBox(height: 14),
              Text(
                'Carregando catálogo da loja...',
                style: theme.getTextStyle(color: theme.textColor),
              ),
            ],
          ),
        ),
      );
    }

    if (loja == null) {
      return Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 48,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Cardápio não disponível no momento.',
                style: theme.getTextStyle(color: theme.textColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final categorias = loja.categoriasLoja;
    final todosItens = loja.itensLoja;
    final grupos = loja.gruposComponentesLoja;

    // Identifica itens que pertencem APENAS a grupos de acompanhamentos (para não poluir a aba Todos)
    final idsEmCategorias = categorias.expand((c) => c.itemIds).toSet();
    final idsEmGrupos = grupos.expand((g) => g.itemIds).toSet();
    final idsApenasAcompanhamento = idsEmGrupos.difference(idsEmCategorias);

    CategoriaLoja? categoriaAtiva;
    final List<ItemLoja> itensFiltrados;
    if (_categoriaSelecionadaId == null) {
      itensFiltrados = todosItens
          .where((i) => !idsApenasAcompanhamento.contains(i.id))
          .toList();
    } else {
      categoriaAtiva = categorias
          .where((c) => c.id == _categoriaSelecionadaId)
          .firstOrNull;
      if (categoriaAtiva != null) {
        itensFiltrados = todosItens
            .where((i) => categoriaAtiva!.itemIds.contains(i.id))
            .toList();
      } else {
        itensFiltrados = todosItens;
      }
    }

    final itensExibidos = _termoBuscaItens.isEmpty
        ? itensFiltrados
        : itensFiltrados
            .where(
              (i) =>
                  i.nome.toLowerCase().contains(_termoBuscaItens) ||
                  i.descricao.toLowerCase().contains(_termoBuscaItens),
            )
            .toList();

    // Categorias que funcionam como produto direto (possuem preço próprio ou grupos de componentes sem itens filhos)
    final categoriasBaseDiretas = _categoriaSelecionadaId == null
        ? categorias
              .where(
                (c) =>
                    c.itemIds.isEmpty &&
                    (_parsePreco(c.preco) > 0 || c.grupoIds.isNotEmpty),
              )
              .toList()
        : (categoriaAtiva != null &&
                  categoriaAtiva.itemIds.isEmpty &&
                  (_parsePreco(categoriaAtiva.preco) > 0 ||
                      categoriaAtiva.grupoIds.isNotEmpty)
              ? [categoriaAtiva]
              : const <CategoriaLoja>[]);

    final tamanho = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: tamanho.height * 0.90,
        ),
        child: Column(
          children: [
            // Cabeçalho - Linha superior de utilitários: Minha Ficha e Botão Fechar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    icon: Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: theme.textColor,
                    ),
                    label: Text(
                      'Minha Ficha',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    onPressed: () => _abrirMinhaFichaCliente(loja),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.secondaryTextColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Título e Subtítulo Centralizados no topo (Padrão Nous)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: [
                  Text(
                    'Pedido • ${loja.nome}',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _vendoCarrinho
                        ? 'Confira sua comanda e forma de pagamento'
                        : 'Toque nos itens para adicionar ou personalizar',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.3)),

            // Conteúdo Principal
            Expanded(
              child: _vendoCarrinho
                  ? _buildVisaoCarrinho(loja)
                  : Column(
                      children: [
                        if (categorias.isNotEmpty)
                          SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    selected: _categoriaSelecionadaId == null,
                                    label: const Text('Todos'),
                                    labelStyle: theme.getTextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _categoriaSelecionadaId == null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _categoriaSelecionadaId == null
                                          ? theme.buttonTextColor
                                          : theme.textColor,
                                    ),
                                    backgroundColor: theme.backgroundColor,
                                    selectedColor: theme.buttonColor,
                                    onSelected: (_) => setState(
                                      () => _categoriaSelecionadaId = null,
                                    ),
                                  ),
                                ),
                                for (final cat in categorias)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      selected:
                                          _categoriaSelecionadaId == cat.id,
                                      label: Text(
                                        _parsePreco(cat.preco) > 0
                                            ? '${cat.nome} (${_formatarPreco(_parsePreco(cat.preco))})'
                                            : cat.nome,
                                      ),
                                      labelStyle: theme.getTextStyle(
                                        fontSize: 11.5,
                                        fontWeight:
                                            _categoriaSelecionadaId == cat.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _categoriaSelecionadaId == cat.id
                                            ? theme.buttonTextColor
                                            : theme.textColor,
                                      ),
                                      backgroundColor: theme.backgroundColor,
                                      selectedColor: theme.buttonColor,
                                      onSelected: (_) => setState(
                                        () => _categoriaSelecionadaId = cat.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        // Barra de Pesquisa de Itens do Catálogo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: TextField(
                            controller: _buscaItensController,
                            style: theme.getTextStyle(
                              fontSize: 12.5,
                              color: theme.textColor,
                            ),
                            onChanged: (v) => setState(
                              () => _termoBuscaItens = v.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Pesquisar itens no cardápio...',
                              hintStyle: theme.getTextStyle(
                                fontSize: 11.5,
                                color: theme.secondaryTextColor,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: theme.secondaryTextColor,
                              ),
                              suffixIcon: _termoBuscaItens.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        size: 16,
                                        color: theme.secondaryTextColor,
                                      ),
                                      onPressed: () {
                                        _buscaItensController.clear();
                                        setState(() => _termoBuscaItens = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              filled: true,
                              fillColor: theme.backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.buttonColor),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: (itensExibidos.isEmpty &&
                                  categoriasBaseDiretas.isEmpty)
                              ? Center(
                                  child: Text(
                                    _termoBuscaItens.isNotEmpty
                                        ? 'Nenhum item encontrado para "$_termoBuscaItens".'
                                        : 'Nenhum item disponível nesta categoria.',
                                    style: theme.getTextStyle(
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(10),
                                  children: [
                                    for (final catBase in categoriasBaseDiretas)
                                      _buildCardCategoriaDireta(catBase, loja),
                                    for (final item in itensExibidos)
                                      _buildCardItemInterativo(
                                        item,
                                        loja,
                                        categoriaAtiva ??
                                            categorias
                                                .where(
                                                  (c) =>
                                                      c.itemIds.contains(item.id),
                                                )
                                                .firstOrNull,
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),

            // Rodapé com Resumo da Comanda: Linha 1 = Valor/Itens, Linha 2 = Botões Revisar e Despachar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Linha 1: Valor total e quantidade de itens selecionados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_formatarPreco(_totalCarrinho)}',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        '$_quantidadeTotal item${_quantidadeTotal == 1 ? '' : 's'} selecionado${_quantidadeTotal == 1 ? '' : 's'}',
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Linha 2: Botões de ação em largura completa
                  Row(
                    children: [
                      if (_carrinho.isNotEmpty) ...[
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              side: BorderSide(color: theme.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: Icon(
                              _vendoCarrinho
                                  ? Icons.menu_book_rounded
                                  : Icons.receipt_long_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _vendoCarrinho
                                  ? 'Cardápio'
                                  : 'Revisar ($_quantidadeTotal)',
                              style: theme.getTextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            onPressed: () => setState(
                              () => _vendoCarrinho = !_vendoCarrinho,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: _enviando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 17),
                          label: Text(
                            _enviando
                                ? 'Enviando...'
                                : (widget.controller.modoLoja
                                    ? 'Enviar Proposta'
                                    : 'Despachar Pedido'),
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonTextColor,
                            ),
                          ),
                          onPressed: _enviando || _carrinho.isEmpty
                              ? null
                              : () => _finalizarPedido(loja),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCategoriaDireta(CategoriaLoja cat, Loja loja) {
    final theme = widget.theme;
    final precoCat = _parsePreco(cat.preco);
    return Card(
      color: theme.backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirPersonalizacao(null, loja, cat),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ImagemService.construirImagem(
                    cat.foto,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: theme.cardBackgroundColor,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: theme.secondaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.nome,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Toque para montar e escolher acompanhamentos',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatarPreco(precoCat),
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_rounded, color: theme.buttonColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItemInterativo(
    ItemLoja item,
    Loja loja,
    CategoriaLoja? cat,
  ) {
    final theme = widget.theme;
    final temComponentesOuVariantes =
        (cat != null && cat.grupoIds.isNotEmpty) || item.variantes.isNotEmpty;
    final precoBase =
        _parsePreco(item.preco) + (cat != null ? _parsePreco(cat.preco) : 0.0);
    final fotoItem = item.imagens.isNotEmpty
        ? item.imagens.first
        : (cat?.foto ?? '');

    final qtdNoCarrinho = _carrinho
        .where((c) => c.itemId == item.id)
        .fold(0, (s, c) => s + c.quantidade);

    return Card(
      color: theme.backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: qtdNoCarrinho > 0
              ? theme.buttonColor
              : theme.borderColor.withValues(alpha: 0.4),
          width: qtdNoCarrinho > 0 ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _interagirComItem(item, loja, cat),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ImagemService.construirImagem(
                    fotoItem,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: theme.cardBackgroundColor,
                      child: Icon(
                        Icons.fastfood_outlined,
                        color: theme.secondaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (cat != null && _categoriaSelecionadaId == null)
                      Text(
                        cat.nome,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: theme.buttonColor,
                        ),
                      ),
                    if (item.descricao.isNotEmpty)
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatarPreco(precoBase),
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _abrirPersonalizacao(item, loja, cat),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              temComponentesOuVariantes
                                  ? 'Escolher opções'
                                  : '+ Observação',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.buttonColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (qtdNoCarrinho > 0 && !temComponentesOuVariantes)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: theme.dangerColor,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          final idx = _carrinho.lastIndexWhere(
                            (c) => c.itemId == item.id,
                          );
                          if (idx != -1) {
                            if (_carrinho[idx].quantidade > 1) {
                              _carrinho[idx] = _carrinho[idx].copyWith(
                                quantidade: _carrinho[idx].quantidade - 1,
                              );
                            } else {
                              _carrinho.removeAt(idx);
                            }
                          }
                        });
                      },
                    ),
                    Text(
                      '$qtdNoCarrinho',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, size: 24),
                      color: theme.buttonColor,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _interagirComItem(item, loja, cat),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _interagirComItem(item, loja, cat),
                  child: Text(
                    qtdNoCarrinho > 0 ? '+ Mais ($qtdNoCarrinho)' : 'Pedir',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisaoCarrinho(Loja loja) {
    final theme = widget.theme;
    const formas = ['PIX', 'Dinheiro', 'Cartão', 'A combinar no chat'];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (int i = 0; i < _carrinho.length; i++)
          Builder(
            builder: (_) {
              final item = _carrinho[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nomeExibicao,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          for (final a in item.acompanhamentos)
                            Text(
                              ' + ${a.quantidadePorUnidade}x ${a.nomeItem}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          if (item.observacao.isNotEmpty)
                            Text(
                              ' Obs: ${item.observacao}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatarPreco(item.subtotal),
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.quantidade > 1
                                ? Icons.remove
                                : Icons.delete_outline,
                            size: 18,
                          ),
                          color: item.quantidade > 1
                              ? theme.textColor
                              : theme.dangerColor,
                          onPressed: () {
                            setState(() {
                              if (item.quantidade > 1) {
                                _carrinho[i] = item.copyWith(
                                  quantidade: item.quantidade - 1,
                                );
                              } else {
                                _carrinho.removeAt(i);
                              }
                            });
                          },
                        ),
                        Text(
                          '${item.quantidade}',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: theme.textColor,
                          onPressed: () {
                            setState(() {
                              _carrinho[i] = item.copyWith(
                                quantidade: item.quantidade + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Text(
          'Forma de pagamento preferida:',
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final fp in formas)
              ChoiceChip(
                selected: _formaPagamento == fp,
                label: Text(fp),
                labelStyle: theme.getTextStyle(
                  fontSize: 11.5,
                  fontWeight: _formaPagamento == fp
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _formaPagamento == fp
                      ? theme.buttonTextColor
                      : theme.textColor,
                ),
                backgroundColor: theme.backgroundColor,
                selectedColor: theme.buttonColor,
                onSelected: (_) => setState(() => _formaPagamento = fp),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _observacaoController,
          maxLines: 2,
          style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          decoration: InputDecoration(
            labelText: 'Observações de Entrega / Pedido',
            labelStyle: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
            hintText: 'Ex: Entregar no portão preto, troco para R\$ 50...',
            hintStyle: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}
