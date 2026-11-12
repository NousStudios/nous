import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_editar_ficha_cliente_loja.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/barra_categorias_e_pesquisa_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/cabecalho_fazer_pedido_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/itens_catalogo_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/rodape_resumo_pedido_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/visao_carrinho_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/modal_personalizar_item_autoatendimento.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Modal completo de Autoatendimento no Chat: navegação de categorias,
/// cardápio interativo, acompanhamentos, carrinho e envio direto para a aba "Novos" da loja.
/// Modularizado seguindo a arquitetura limpa do Nous (< 450 linhas).
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
  final TextEditingController _trocoController = TextEditingController();
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
    _trocoController.dispose();
    _buscaItensController.dispose();
    super.dispose();
  }

  double _parsePreco(String p) => double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
  double get _totalCarrinho => _carrinho.fold(0.0, (s, i) => s + i.subtotal);
  int get _quantidadeTotal => _carrinho.fold(0, (s, i) => s + i.quantidade);

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
      final obsTexto = _observacaoController.text.trim();
      final trocoTexto = _trocoController.text.trim();
      final obsFinal = (_formaPagamento == 'Dinheiro' && trocoTexto.isNotEmpty)
          ? (obsTexto.isEmpty
              ? 'Troco para R\$ $trocoTexto'
              : '$obsTexto | Troco para R\$ $trocoTexto')
          : obsTexto;

      final pedido = await ChatAutoatendimentoService.enviarPedidoAutoatendimento(
        context: context,
        lojaId: loja.id,
        carrinho: _carrinho,
        observacaoGeral: obsFinal,
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
            CabecalhoFazerPedidoChatWidget(
              theme: theme,
              nomeLoja: loja.nome,
              vendoCarrinho: _vendoCarrinho,
              onAbrirMinhaFicha: () => _abrirMinhaFichaCliente(loja),
              onFechar: () => Navigator.pop(context),
            ),
            Expanded(
              child: _vendoCarrinho
                  ? VisaoCarrinhoChatWidget(
                      theme: theme,
                      loja: loja,
                      carrinho: _carrinho,
                      formaPagamento: _formaPagamento,
                      observacaoController: _observacaoController,
                      trocoController: _trocoController,
                      onDecrementarOuRemover: (i) {
                        setState(() {
                          if (_carrinho[i].quantidade > 1) {
                            _carrinho[i] = _carrinho[i].copyWith(
                              quantidade: _carrinho[i].quantidade - 1,
                            );
                          } else {
                            _carrinho.removeAt(i);
                          }
                        });
                      },
                      onIncrementar: (i) {
                        setState(() {
                          _carrinho[i] = _carrinho[i].copyWith(
                            quantidade: _carrinho[i].quantidade + 1,
                          );
                        });
                      },
                      onSelecionarFormaPagamento: (fp) =>
                          setState(() => _formaPagamento = fp),
                    )
                  : Column(
                      children: [
                        BarraCategoriasEPesquisaChatWidget(
                          theme: theme,
                          categorias: categorias,
                          categoriaSelecionadaId: _categoriaSelecionadaId,
                          buscaController: _buscaItensController,
                          termoBusca: _termoBuscaItens,
                          onSelecionarCategoria: (catId) =>
                              setState(() => _categoriaSelecionadaId = catId),
                          onChangedBusca: (v) => setState(
                            () => _termoBuscaItens = v.trim().toLowerCase(),
                          ),
                          onLimparBusca: () {
                            _buscaItensController.clear();
                            setState(() => _termoBuscaItens = '');
                          },
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
                                      ItensCatalogoChatWidget.buildCardCategoriaDireta(
                                        theme: theme,
                                        cat: catBase,
                                        loja: loja,
                                        onTap: () => _abrirPersonalizacao(
                                          null,
                                          loja,
                                          catBase,
                                        ),
                                      ),
                                    for (final item in itensExibidos) ...[
                                      Builder(
                                        builder: (context) {
                                          final catResolvida = categoriaAtiva ??
                                              (_parsePreco(item.preco) > 0
                                                  ? null
                                                  : categorias
                                                      .where(
                                                        (c) => c.itemIds
                                                            .contains(item.id),
                                                      )
                                                      .firstOrNull);
                                          return ItensCatalogoChatWidget
                                              .buildCardItemInterativo(
                                            theme: theme,
                                            item: item,
                                            loja: loja,
                                            cat: catResolvida,
                                            categoriaSelecionadaId:
                                                _categoriaSelecionadaId,
                                            carrinho: _carrinho,
                                            onInteragir: () =>
                                                _interagirComItem(
                                              item,
                                              loja,
                                              catResolvida,
                                            ),
                                            onPersonalizar: () =>
                                                _abrirPersonalizacao(
                                              item,
                                              loja,
                                              catResolvida,
                                            ),
                                            onDecrementar: () {
                                              setState(() {
                                                final idx =
                                                    _carrinho.lastIndexWhere(
                                                  (c) => c.itemId == item.id,
                                                );
                                                if (idx != -1) {
                                                  if (_carrinho[idx]
                                                          .quantidade >
                                                      1) {
                                                    _carrinho[idx] =
                                                        _carrinho[idx].copyWith(
                                                      quantidade:
                                                          _carrinho[idx]
                                                                  .quantidade -
                                                              1,
                                                    );
                                                  } else {
                                                    _carrinho.removeAt(idx);
                                                  }
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
            RodapeResumoPedidoChatWidget(
              theme: theme,
              total: _totalCarrinho,
              quantidadeTotal: _quantidadeTotal,
              temItens: _carrinho.isNotEmpty,
              vendoCarrinho: _vendoCarrinho,
              enviando: _enviando,
              modoLoja: widget.controller.modoLoja,
              onAlternarVisaoCarrinho: () =>
                  setState(() => _vendoCarrinho = !_vendoCarrinho),
              onFinalizarPedido: () => _finalizarPedido(loja),
            ),
          ],
        ),
      ),
    );
  }
}
