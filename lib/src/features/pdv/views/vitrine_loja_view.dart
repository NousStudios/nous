import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/barra_categorias_e_pesquisa_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/itens_catalogo_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/rodape_resumo_pedido_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/fazer_pedido/visao_carrinho_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/modal_personalizar_item_autoatendimento.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Vitrine pública de uma loja comercial para clientes, visitantes e não-membros.
/// Exibe apenas dados públicos e catálogo configurado, enviando pedidos ao Chat com a Loja.
class VitrineLojaView extends StatefulWidget {
  final String lojaId;
  final Loja? lojaFallback;

  const VitrineLojaView({
    super.key,
    required this.lojaId,
    this.lojaFallback,
  });

  @override
  State<VitrineLojaView> createState() => _VitrineLojaViewState();
}

class _VitrineLojaViewState extends State<VitrineLojaView> {
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
    _lojaResolvida = widget.lojaFallback;
    _carregarCatalogo();
  }

  Future<void> _carregarCatalogo() async {
    final pdv = context.read<PdvProvider>();
    final loja = await ChatAutoatendimentoService.obterLojaCatalogo(
      lojaIdBruto: widget.lojaId,
      pdv: pdv,
    );
    List<ItemVendido> carrinhoRestaurado = [];
    try {
      final raw = await PreferenciasSoberanasService.obterTexto(
        'vitrine_carrinho_pendente_${widget.lojaId}',
      );
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          carrinhoRestaurado = decoded
              .whereType<Map>()
              .map((m) => ItemVendido.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _lojaResolvida = loja ?? _lojaResolvida;
        if (_carrinho.isEmpty && carrinhoRestaurado.isNotEmpty) {
          _carrinho.addAll(carrinhoRestaurado);
        }
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

  double _parsePreco(String p) =>
      double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
  double get _totalCarrinho => _carrinho.fold(0.0, (s, i) => s + i.subtotal);
  int get _quantidadeTotal => _carrinho.fold(0, (s, i) => s + i.quantidade);

  void _adicionarItemDireto(ItemLoja item, {CategoriaLoja? cat}) {
    setState(() {
      final precoItem = _parsePreco(item.preco);
      final precoCat = cat != null ? _parsePreco(cat.preco) : 0.0;
      final idx = _carrinho.indexWhere(
        (c) =>
            c.itemId == item.id &&
            c.categoriaId == cat?.id &&
            c.acompanhamentos.isEmpty &&
            c.observacao.isEmpty &&
            c.varianteNome.isEmpty,
      );
      if (idx != -1) {
        _carrinho[idx] = _carrinho[idx].copyWith(
          quantidade: _carrinho[idx].quantidade + 1,
        );
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
    unawaited(ComprasUsuarioService.salvarCarrinhoPendente(widget.lojaId, _carrinho));
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

  void _abrirPersonalizacao(
    ItemLoja? item,
    Loja loja,
    CategoriaLoja? categoria,
  ) {
    ModalPersonalizarItemAutoatendimento.mostrar(
      context: context,
      theme: ThemeController.currentTheme.value,
      item: item,
      categoria: categoria,
      gruposDisponiveis: loja.gruposComponentesLoja,
      todosItens: loja.itensLoja,
      onConfirmar: (itemPersonalizado) {
        setState(() => _carrinho.add(itemPersonalizado));
        unawaited(
          ComprasUsuarioService.salvarCarrinhoPendente(widget.lojaId, _carrinho),
        );
      },
    );
  }

  Future<void> _mostrarDialogCriarContaVisitante(
    AppTheme theme,
    Loja loja,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Crie sua Conta Nous para pedir',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Você selecionou $_quantidadeTotal ${_quantidadeTotal == 1 ? "item" : "itens"} em ${loja.nome}.\n\n'
          'Para enviar seu pedido para o chat da loja, crie sua Conta Nous com seus dados e aguarde a aprovação de um usuário Nous verificado.',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Continuar vendo',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await PreferenciasSoberanasService.salvarTexto(
                  'vitrine_carrinho_pendente_${loja.id}',
                  jsonEncode(_carrinho.map((e) => e.toJson()).toList()),
                );
              } catch (_) {}
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              context.read<AuthProvider>().sair();
              context.read<PdvProvider>().limparSessao();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            child: Text(
              'Criar Conta Nous',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogAguardandoAprovacao(AppTheme theme) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Conta aguardando aprovação',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Sua Conta Nous já foi criada, mas ainda aguarda a aprovação de um usuário Nous verificado para enviar pedidos às lojas da rede.',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendi',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarPedido(Loja loja, AppTheme theme) async {
    if (_carrinho.isEmpty || _enviando) return;
    final auth = context.read<AuthProvider>();

    if (auth.modoVisitante || auth.contaAtual == null) {
      await _mostrarDialogCriarContaVisitante(theme, loja);
      return;
    }

    if (auth.perfilIsolado || !auth.usuarioAtualVerificado) {
      await _mostrarDialogAguardandoAprovacao(theme);
      return;
    }

    setState(() => _enviando = true);
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
      );

      if (!mounted) return;
      final cpfNorm = ChatService.normalizarCpf(auth.contaAtual!.cpf);
      final convId = ChatService.conversaIdLojaUsuario(loja.id, cpfNorm);

      setState(() {
        _carrinho.clear();
        _vendoCarrinho = false;
        _observacaoController.clear();
        _trocoController.clear();
      });
      await PreferenciasSoberanasService.salvarTexto(
        'vitrine_carrinho_pendente_${loja.id}',
        '',
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Pedido enviado ao chat!',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Sua comanda #${pedido.numero.toString().padLeft(4, '0')} foi enviada para ${loja.nome} e aguarda aceite no balcão.',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Continuar aqui',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MensageriaView(
                      modoLoja: false,
                      conversaInicialId: convId,
                    ),
                  ),
                );
              },
              child: Text(
                'Abrir Chat com a Loja',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.dangerColor,
            content: Text(
              'Erro ao enviar pedido: $e',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _buildCabecalhoPublico(AppTheme theme, Loja loja) {
    final temLogo = ImagemService.existe(loja.logo);
    final infoSecundaria = [
      if (loja.categorias.trim().isNotEmpty) loja.categorias.trim(),
      if (loja.endereco.trim().isNotEmpty) loja.endereco.trim(),
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (temLogo)
            ImagemService.construirImagem(
              loja.logo,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
              fallback: Icon(
                Icons.storefront_rounded,
                size: 32,
                color: theme.secondaryTextColor,
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 28,
                color: theme.secondaryTextColor,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loja.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                if (infoSecundaria.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    infoSecundaria,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final loja = _lojaResolvida;

        if (_carregandoLoja && loja == null) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: const CustomAppBar(title: 'Vitrine da Loja'),
            body: Center(
              child: CircularProgressIndicator(color: theme.textColor),
            ),
          );
        }

        if (loja == null) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: const CustomAppBar(title: 'Vitrine da Loja'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EstadoVazioContainer(
                  theme: theme,
                  mensagem: 'Vitrine desta loja não está disponível no momento.',
                ),
              ),
            ),
          );
        }

        final categorias = loja.categoriasLoja;
        final todosItens = loja.itensLoja;
        final grupos = loja.gruposComponentesLoja;

        final idsEmCategorias = categorias.expand((c) => c.itemIds).toSet();
        final idsEmGrupos = grupos.expand((g) => g.itemIds).toSet();
        final idsApenasAcompanhamento =
            idsEmGrupos.difference(idsEmCategorias);

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
          itensFiltrados = categoriaAtiva != null
              ? todosItens
                  .where((i) => categoriaAtiva!.itemIds.contains(i.id))
                  .toList()
              : todosItens;
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
                        categoriaAtiva.grupoIds.isNotEmpty))
                ? [categoriaAtiva]
                : <CategoriaLoja>[];

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(title: loja.nome),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    _buildCabecalhoPublico(theme, loja),
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
                                unawaited(
                                  ComprasUsuarioService.salvarCarrinhoPendente(
                                    widget.lojaId,
                                    _carrinho,
                                  ),
                                );
                              },
                              onIncrementar: (i) {
                                setState(() {
                                  _carrinho[i] = _carrinho[i].copyWith(
                                    quantidade: _carrinho[i].quantidade + 1,
                                  );
                                });
                                unawaited(
                                  ComprasUsuarioService.salvarCarrinhoPendente(
                                    widget.lojaId,
                                    _carrinho,
                                  ),
                                );
                              },
                              onSelecionarFormaPagamento: (fp) =>
                                  setState(() => _formaPagamento = fp),
                            )
                          : Column(
                              children: [
                                BarraCategoriasEPesquisaChatWidget(
                                  theme: theme,
                                  categorias: categorias,
                                  categoriaSelecionadaId:
                                      _categoriaSelecionadaId,
                                  buscaController: _buscaItensController,
                                  termoBusca: _termoBuscaItens,
                                  onSelecionarCategoria: (catId) => setState(
                                    () => _categoriaSelecionadaId = catId,
                                  ),
                                  onChangedBusca: (v) => setState(
                                    () => _termoBuscaItens =
                                        v.trim().toLowerCase(),
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
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: EstadoVazioContainer(
                                              theme: theme,
                                              mensagem: _termoBuscaItens
                                                      .isNotEmpty
                                                  ? 'Nenhum item encontrado para "$_termoBuscaItens".'
                                                  : 'Esta loja ainda não publicou itens no catálogo.',
                                            ),
                                          ),
                                        )
                                      : ListView(
                                          padding: const EdgeInsets.all(10),
                                          children: [
                                            for (final catBase
                                                in categoriasBaseDiretas)
                                              ItensCatalogoChatWidget
                                                  .buildCardCategoriaDireta(
                                                theme: theme,
                                                cat: catBase,
                                                loja: loja,
                                                onTap: () =>
                                                    _abrirPersonalizacao(
                                                  null,
                                                  loja,
                                                  catBase,
                                                ),
                                              ),
                                            for (final item in itensExibidos)
                                              Builder(
                                                builder: (context) {
                                                  final catResolvida =
                                                      categoriaAtiva ??
                                                          (_parsePreco(
                                                                    item.preco,
                                                                  ) >
                                                                  0
                                                              ? null
                                                              : categorias
                                                                  .where(
                                                                    (c) => c
                                                                        .itemIds
                                                                        .contains(
                                                                      item.id,
                                                                    ),
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
                                                        final idx = _carrinho
                                                            .lastIndexWhere(
                                                          (c) =>
                                                              c.itemId ==
                                                              item.id,
                                                        );
                                                        if (idx != -1) {
                                                          if (_carrinho[idx]
                                                                  .quantidade >
                                                              1) {
                                                            _carrinho[idx] =
                                                                _carrinho[idx]
                                                                    .copyWith(
                                                              quantidade:
                                                                  _carrinho[idx]
                                                                          .quantidade -
                                                                      1,
                                                            );
                                                          } else {
                                                            _carrinho
                                                                .removeAt(idx);
                                                          }
                                                        }
                                                      });
                                                      unawaited(
                                                        ComprasUsuarioService
                                                            .salvarCarrinhoPendente(
                                                          widget.lojaId,
                                                          _carrinho,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
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
                      modoLoja: false,
                      onAlternarVisaoCarrinho: () =>
                          setState(() => _vendoCarrinho = !_vendoCarrinho),
                      onFinalizarPedido: () => _finalizarPedido(loja, theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
