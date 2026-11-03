import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/botoes_hover_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/estoque_custo_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/fotos_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/seletor_multiplo_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/variantes_item_widget.dart';

class NovoItemDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final ItemLoja? itemParaEditar;
  final List<String> categoriaIdsIniciais;
  final List<String> grupoIdsIniciais;
  final double? saldoEstoqueAtual;
  final double? ultimaQuantidadeCompra;
  final double? ultimoCustoTotalCompra;
  final void Function(double novoSaldo)? onEstoqueAjustado;
  final void Function(ItemLoja item)? onAbrirMovimentoDetalhado;
  final void Function(CategoriaLoja)? onCategoriaCriada;
  final void Function(GrupoComponentesLoja)? onGrupoCriado;
  final bool layoutExpandido;
  final void Function(
    ItemLoja item,
    List<String> categoriaIds,
    List<String> grupoIds,
  ) onCriar;

  const NovoItemDialog({
    super.key,
    required this.theme,
    required this.categorias,
    required this.gruposComponentes,
    this.itemParaEditar,
    this.categoriaIdsIniciais = const [],
    this.grupoIdsIniciais = const [],
    this.saldoEstoqueAtual,
    this.ultimaQuantidadeCompra,
    this.ultimoCustoTotalCompra,
    this.layoutExpandido = false,
    this.onEstoqueAjustado,
    this.onAbrirMovimentoDetalhado,
    this.onCategoriaCriada,
    this.onGrupoCriado,
    required this.onCriar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<CategoriaLoja> categorias,
    required List<GrupoComponentesLoja> gruposComponentes,
    ItemLoja? itemParaEditar,
    List<String> categoriaIdsIniciais = const [],
    List<String> grupoIdsIniciais = const [],
    double? saldoEstoqueAtual,
    double? ultimaQuantidadeCompra,
    double? ultimoCustoTotalCompra,
    bool layoutExpandido = false,
    void Function(double novoSaldo)? onEstoqueAjustado,
    void Function(ItemLoja item)? onAbrirMovimentoDetalhado,
    void Function(CategoriaLoja)? onCategoriaCriada,
    void Function(GrupoComponentesLoja)? onGrupoCriado,
    required void Function(
      ItemLoja item,
      List<String> categoriaIds,
      List<String> grupoIds,
    ) onCriar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NovoItemDialog(
        theme: theme,
        categorias: categorias,
        gruposComponentes: gruposComponentes,
        itemParaEditar: itemParaEditar,
        categoriaIdsIniciais: categoriaIdsIniciais,
        grupoIdsIniciais: grupoIdsIniciais,
        saldoEstoqueAtual: saldoEstoqueAtual,
        ultimaQuantidadeCompra: ultimaQuantidadeCompra,
        ultimoCustoTotalCompra: ultimoCustoTotalCompra,
        layoutExpandido: layoutExpandido,
        onEstoqueAjustado: onEstoqueAjustado,
        onAbrirMovimentoDetalhado: onAbrirMovimentoDetalhado,
        onCategoriaCriada: onCategoriaCriada,
        onGrupoCriado: onGrupoCriado,
        onCriar: onCriar,
      ),
    );
  }

  @override
  State<NovoItemDialog> createState() => _NovoItemDialogState();
}

class _NovoItemDialogState extends State<NovoItemDialog> {
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _precoCustoController = TextEditingController();
  final _custoTotalCompraController = TextEditingController();
  final _quantidadeCompraController = TextEditingController();
  final _codigoBarrasController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _freteGratisAteController = TextEditingController();
  final _valorPorKmController = TextEditingController();
  final _estoqueMinimoController = TextEditingController();
  final _estoqueAtualController = TextEditingController();
  final _consumoController = TextEditingController();

  bool _calculandoCusto = false;
  TipoItemLoja? _tipo;
  bool _possuiDelivery = false;
  UnidadeItemLoja _unidadeBase = UnidadeItemLoja.un;
  bool _descricaoExpandida = false;

  late final List<CategoriaLoja> _categorias = List.from(widget.categorias);
  late final List<GrupoComponentesLoja> _grupos =
      List.from(widget.gruposComponentes);

  late final Set<String> _categoriasSelecionadas =
      widget.categoriaIdsIniciais.toSet();
  late final Set<String> _gruposSelecionados =
      widget.grupoIdsIniciais.toSet();

  late final List<String> _imagens = (widget.itemParaEditar?.imagens ?? [])
      .map((img) => ImagemService.resolverCaminhoExistente(img) ?? img)
      .toList();

  final List<VarianteFormControllers> _variantesControllers = [];

  @override
  void initState() {
    super.initState();

    final item = widget.itemParaEditar;
    if (item == null) {
      _consumoController.text = '1';
      _tipo = TipoItemLoja.produto;
      if (widget.saldoEstoqueAtual != null && widget.saldoEstoqueAtual! > 0) {
        _estoqueAtualController.text =
            _formatarNumero(widget.saldoEstoqueAtual!);
      }
    } else {
      _nomeController.text = item.nome;
      _precoController.text = item.preco;
      _precoCustoController.text = item.precoCusto;
      _codigoBarrasController.text = item.codigoBarras;
      _descricaoController.text = item.descricao;
      if (item.descricao.isNotEmpty) {
        _descricaoExpandida = true;
      }
      _freteGratisAteController.text = item.freteGratisAte;
      _valorPorKmController.text = item.valorPorKm;
      _estoqueMinimoController.text = item.estoqueMinimo;
      if (widget.saldoEstoqueAtual != null) {
        _estoqueAtualController.text =
            _formatarNumero(widget.saldoEstoqueAtual!);
      }
      _tipo = item.tipo ?? TipoItemLoja.produto;
      _possuiDelivery = item.possuiDelivery;
      _unidadeBase = item.unidadeBase;
      _consumoController.text = _formatarNumero(item.consumoPorVenda);

      for (final variante in item.variantes) {
        _variantesControllers.add(
          VarianteFormControllers(
            nome: variante.nome,
            preco: variante.preco,
          ),
        );
      }
    }

    if (widget.ultimoCustoTotalCompra != null &&
        widget.ultimoCustoTotalCompra! > 0 &&
        widget.ultimaQuantidadeCompra != null &&
        widget.ultimaQuantidadeCompra! > 0) {
      _custoTotalCompraController.text =
          widget.ultimoCustoTotalCompra!.toStringAsFixed(2).replaceAll('.', ',');
      _quantidadeCompraController.text =
          _formatarNumero(widget.ultimaQuantidadeCompra!);
    } else if (item != null && item.precoCusto.isNotEmpty) {
      final custoVal = double.tryParse(
        item.precoCusto.replaceAll('.', '').replaceAll(',', '.'),
      );
      if (custoVal != null &&
          custoVal > 0 &&
          widget.saldoEstoqueAtual != null &&
          widget.saldoEstoqueAtual! > 0) {
        final totalEst = custoVal * widget.saldoEstoqueAtual!;
        _quantidadeCompraController.text =
            _formatarNumero(widget.saldoEstoqueAtual!);
        _custoTotalCompraController.text =
            totalEst.toStringAsFixed(2).replaceAll('.', ',');
      }
    }

    _custoTotalCompraController.addListener(_onCustoTotalCompraMudou);
    _quantidadeCompraController.addListener(_onQuantidadeCompraMudou);
    _precoCustoController.addListener(_onPrecoCustoMudou);
    _precoController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onCustoTotalCompraMudou() {
    if (_calculandoCusto) return;
    _calculandoCusto = true;
    try {
      final qtdTexto =
          _quantidadeCompraController.text.trim().replaceAll(',', '.');
      final qtd = double.tryParse(qtdTexto);
      final totalTexto = _custoTotalCompraController.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final total = double.tryParse(totalTexto);
      if (qtd != null && qtd > 0 && total != null && total >= 0) {
        final unitario = total / qtd;
        _precoCustoController.text =
            unitario.toStringAsFixed(2).replaceAll('.', ',');
      }
    } finally {
      _calculandoCusto = false;
      if (mounted) setState(() {});
    }
  }

  void _onQuantidadeCompraMudou() {
    if (_calculandoCusto) return;
    final totalTexto = _custoTotalCompraController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final total = double.tryParse(totalTexto);
    if (total != null && total > 0) {
      _onCustoTotalCompraMudou();
    } else {
      _onPrecoCustoMudou();
    }

    if (widget.itemParaEditar == null &&
        _estoqueAtualController.text.trim().isEmpty) {
      _estoqueAtualController.text = _quantidadeCompraController.text.trim();
    }
    if (mounted) setState(() {});
  }

  void _onPrecoCustoMudou() {
    if (_calculandoCusto) return;
    _calculandoCusto = true;
    try {
      final qtdTexto =
          _quantidadeCompraController.text.trim().replaceAll(',', '.');
      final qtd = double.tryParse(qtdTexto);
      final custoTexto = _precoCustoController.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final custo = double.tryParse(custoTexto);
      if (qtd != null && qtd > 0 && custo != null && custo >= 0) {
        final total = qtd * custo;
        _custoTotalCompraController.text =
            total.toStringAsFixed(2).replaceAll('.', ',');
      }
    } finally {
      _calculandoCusto = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _precoCustoController.dispose();
    _custoTotalCompraController.dispose();
    _quantidadeCompraController.dispose();
    _codigoBarrasController.dispose();
    _descricaoController.dispose();
    _freteGratisAteController.dispose();
    _valorPorKmController.dispose();
    _estoqueMinimoController.dispose();
    _estoqueAtualController.dispose();
    _consumoController.dispose();
    for (final controller in _variantesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatarNumero(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toString().replaceAll('.', ',');
  }

  double _consumoParseado() {
    final texto = _consumoController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0) return 1.0;
    return valor;
  }

  void _adicionarCampoVariante() {
    setState(() => _variantesControllers.add(VarianteFormControllers()));
  }

  void _removerCampoVariante(int index) {
    setState(() {
      _variantesControllers[index].dispose();
      _variantesControllers.removeAt(index);
    });
  }

  void _abrirCriarNovaCategoria() {
    NovaCategoriaDialog.mostrar(
      context,
      theme: widget.theme,
      gruposComponentes: _grupos,
      onCriar: (novaCategoria) {
        setState(() {
          _categorias.add(novaCategoria);
          _categoriasSelecionadas.add(novaCategoria.id);
        });
        widget.onCategoriaCriada?.call(novaCategoria);
      },
    );
  }

  void _abrirCriarNovoGrupo() {
    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: widget.theme,
      itensDisponiveis: const [],
      onCriar: (novoGrupo) {
        setState(() {
          _grupos.add(novoGrupo);
          _gruposSelecionados.add(novoGrupo.id);
        });
        widget.onGrupoCriado?.call(novoGrupo);
      },
    );
  }

  Widget _campoSelecao({
    required String label,
    required String? valorExibido,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextoRolante(
                texto: (valorExibido == null || valorExibido.isEmpty)
                    ? label
                    : valorExibido,
                textAlign: TextAlign.start,
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: (valorExibido == null || valorExibido.isEmpty)
                      ? theme.secondaryTextColor
                      : theme.textColor,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: theme.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _botaoUnidade(
    AppTheme theme,
    String rotulo,
    UnidadeItemLoja valor,
  ) {
    final selecionado = _unidadeBase == valor;
    return Expanded(
      child: BotaoHoverUnidade(
        theme: theme,
        rotulo: rotulo,
        selecionado: selecionado,
        aoClicar: () => setState(() => _unidadeBase = valor),
      ),
    );
  }

  String _rotuloUnidade() {
    switch (_unidadeBase) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  String _formatarMoeda(double v) {
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _buildBlocoDescricao(AppTheme theme) {
    final temDescricao = _descricaoController.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _descricaoExpandida = !_descricaoExpandida),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextoRolante(
                      texto: temDescricao
                          ? (_descricaoExpandida
                              ? 'Descrição do item'
                              : 'Descrição: ${_descricaoController.text.trim().split('\n').first}')
                          : 'Descrição do item (opcional)',
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: temDescricao ? theme.textColor : theme.secondaryTextColor,
                        fontWeight: temDescricao ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    _descricaoExpandida
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.secondaryTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_descricaoExpandida) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ThemedTextField(
                theme: theme,
                controller: _descricaoController,
                label: 'Escreva a descrição do item',
                linhas: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeletorTipo(AppTheme theme) {
    final tipoAtual = _tipo ?? TipoItemLoja.produto;
    return Row(
      children: [
        Expanded(
          child: BotaoHoverTipoItem(
            theme: theme,
            rotulo: 'Produto',
            icone: Icons.inventory_2_outlined,
            selecionado: tipoAtual == TipoItemLoja.produto,
            aoClicar: () => setState(() => _tipo = TipoItemLoja.produto),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BotaoHoverTipoItem(
            theme: theme,
            rotulo: 'Serviço',
            icone: Icons.handyman_outlined,
            selecionado: tipoAtual == TipoItemLoja.servico,
            aoClicar: () => setState(() => _tipo = TipoItemLoja.servico),
          ),
        ),
      ],
    );
  }

  void _criar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final variantes = _variantesControllers
        .map((c) => VarianteItem(
              nome: c.nomeController.text.trim(),
              preco: c.precoController.text.trim(),
            ))
        .where((v) => v.nome.isNotEmpty)
        .toList();

    final itemExistente = widget.itemParaEditar;
    final consumo = _consumoParseado();

    final item = itemExistente != null
        ? itemExistente.copyWith(
            nome: nome,
            tipo: _tipo,
            preco: _precoController.text.trim(),
            precoCusto: _precoCustoController.text.trim(),
            codigoBarras: _codigoBarrasController.text.trim(),
            variantes: variantes,
            imagens: _imagens,
            descricao: _descricaoController.text.trim(),
            possuiDelivery: _possuiDelivery,
            freteGratisAte: _freteGratisAteController.text.trim(),
            valorPorKm: _valorPorKmController.text.trim(),
            estoqueMinimo: _estoqueMinimoController.text.trim(),
            unidadeBase: _unidadeBase,
            consumoPorVenda: consumo,
          )
        : ItemLoja.novo(
            nome: nome,
            tipo: _tipo,
            preco: _precoController.text.trim(),
            precoCusto: _precoCustoController.text.trim(),
            codigoBarras: _codigoBarrasController.text.trim(),
            variantes: variantes,
            imagens: _imagens,
            descricao: _descricaoController.text.trim(),
            possuiDelivery: _possuiDelivery,
            freteGratisAte: _freteGratisAteController.text.trim(),
            valorPorKm: _valorPorKmController.text.trim(),
            estoqueMinimo: _estoqueMinimoController.text.trim(),
            unidadeBase: _unidadeBase,
            consumoPorVenda: consumo,
          );

    final textoEstoque =
        _estoqueAtualController.text.trim().replaceAll(',', '.');
    final novoEstoque = double.tryParse(textoEstoque);
    if (novoEstoque != null) {
      widget.onEstoqueAjustado?.call(novoEstoque);
    }

    widget.onCriar(
      item,
      _categoriasSelecionadas.toList(),
      _gruposSelecionados.toList(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final editando = widget.itemParaEditar != null;

    final larguraTela = MediaQuery.sizeOf(context).width;
    final modoExpandido = widget.layoutExpandido && larguraTela >= 680;

    final double larguraPopup;
    if (modoExpandido) {
      larguraPopup = (larguraTela * 0.90).clamp(680.0, 780.0);
    } else {
      larguraPopup = larguraTela < 440 ? larguraTela * 0.94 : 380.0;
    }

    final opcoesCategorias = {
      for (final categoria in _categorias) categoria.id: categoria.nome,
    };
    final fotosCategorias = {
      for (final categoria in _categorias) categoria.id: categoria.foto,
    };
    final opcoesGrupos = {
      for (final grupo in _grupos) grupo.id: grupo.nome,
    };
    final fotosGrupos = {
      for (final grupo in _grupos) grupo.id: grupo.foto,
    };

    final nomesCategoriasSelecionadas = _categorias
        .where((c) => _categoriasSelecionadas.contains(c.id))
        .map((c) => c.nome)
        .join(', ');
    final nomesGruposSelecionados = _grupos
        .where((g) => _gruposSelecionados.contains(g.id))
        .map((g) => g.nome)
        .join(', ');

    final custoUnitarioTexto = _precoCustoController.text.trim();
    final custoTotalTexto = _custoTotalCompraController.text.trim();
    final qtdTexto = _quantidadeCompraController.text.trim();

    final custoUnitarioVal = double.tryParse(
      custoUnitarioTexto.replaceAll('.', '').replaceAll(',', '.'),
    );
    final precoVendaVal = double.tryParse(
      _precoController.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );

    String? calculoTexto;
    if (custoTotalTexto.isNotEmpty &&
        qtdTexto.isNotEmpty &&
        custoUnitarioVal != null &&
        custoUnitarioVal > 0) {
      calculoTexto =
          'Cálculo: R\$ $custoTotalTexto ÷ $qtdTexto ${_rotuloUnidade()} = R\$ ${_formatarMoeda(custoUnitarioVal)} por ${_rotuloUnidade()}';
    } else if (custoUnitarioVal != null && custoUnitarioVal > 0) {
      calculoTexto =
          'Custo unitário: R\$ ${_formatarMoeda(custoUnitarioVal)} por ${_rotuloUnidade()}';
    }

    String? margemTexto;
    if (precoVendaVal != null &&
        precoVendaVal > 0 &&
        custoUnitarioVal != null &&
        custoUnitarioVal > 0) {
      final lucro = precoVendaVal - custoUnitarioVal;
      final margem = (lucro / precoVendaVal) * 100;
      final lucroFormatado = _formatarMoeda(lucro);
      final sinal = lucro >= 0 ? '+' : '';
      margemTexto =
          'Margem bruta estimada: $sinal R\$ $lucroFormatado ($sinal${margem.toStringAsFixed(1)}%)';
    }

    Widget buildColunaIdentificacao() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FotosItemWidget(
            theme: theme,
            imagens: _imagens,
            onImagensAlteradas: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          ThemedTextField(
            theme: theme,
            controller: _nomeController,
            label: 'Nome do novo item',
          ),
          const SizedBox(height: 14),
          _buildBlocoDescricao(theme),
          const SizedBox(height: 14),
          _buildSeletorTipo(theme),
          const SizedBox(height: 14),
          ThemedTextField(
            theme: theme,
            controller: _precoController,
            label: 'Preço de venda (ex: 12,50)',
            tipoDeTeclado: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _campoSelecao(
            label: 'Categorias do item',
            valorExibido: nomesCategoriasSelecionadas,
            onTap: () => SeletorMultiploDialog.mostrar(
              context: context,
              theme: theme,
              titulo: 'Categorias do item',
              opcoes: opcoesCategorias,
              fotos: fotosCategorias,
              selecionados: _categoriasSelecionadas,
              onCriarNovo: _abrirCriarNovaCategoria,
              textoCriarNovo: 'Nova Categoria',
              onAlterado: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          _campoSelecao(
            label: 'Grupos de componentes',
            valorExibido: nomesGruposSelecionados,
            onTap: () => SeletorMultiploDialog.mostrar(
              context: context,
              theme: theme,
              titulo: 'Grupos de componentes',
              opcoes: opcoesGrupos,
              fotos: fotosGrupos,
              selecionados: _gruposSelecionados,
              onCriarNovo: _abrirCriarNovoGrupo,
              textoCriarNovo: 'Novo Grupo de Componentes',
              onAlterado: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 14),
          VariantesItemWidget(
            theme: theme,
            variantesControllers: _variantesControllers,
            onAdicionarVariante: _adicionarCampoVariante,
            onRemoverVariante: _removerCampoVariante,
          ),
        ],
      );
    }

    Widget buildColunaOperacaoEEstoque() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ThemedTextField(
            theme: theme,
            controller: _codigoBarrasController,
            label: 'Código de barras / EAN (opcional)',
          ),
          const SizedBox(height: 14),
          Text(
            'Unidade de medida',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _botaoUnidade(theme, 'Unidade', UnidadeItemLoja.un),
              const SizedBox(width: 8),
              _botaoUnidade(theme, 'Grama', UnidadeItemLoja.g),
              const SizedBox(width: 8),
              _botaoUnidade(theme, 'Mililitro', UnidadeItemLoja.ml),
            ],
          ),
          const SizedBox(height: 14),
          ThemedTextField(
            theme: theme,
            controller: _consumoController,
            label: 'Consumo por venda (${_rotuloUnidade()})',
            tipoDeTeclado: TextInputType.number,
          ),
          const SizedBox(height: 14),
          EstoqueCustoItemWidget(
            theme: theme,
            editando: editando,
            saldoEstoqueAtual: widget.saldoEstoqueAtual,
            rotuloUnidade: _rotuloUnidade(),
            estoqueAtualController: _estoqueAtualController,
            estoqueMinimoController: _estoqueMinimoController,
            custoTotalCompraController: _custoTotalCompraController,
            quantidadeCompraController: _quantidadeCompraController,
            precoCustoController: _precoCustoController,
            calculoTexto: calculoTexto,
            margemTexto: margemTexto,
            onAbrirMovimentoDetalhado: widget.onAbrirMovimentoDetalhado != null
                ? () {
                    Navigator.of(context).pop();
                    widget.onAbrirMovimentoDetalhado!(widget.itemParaEditar!);
                  }
                : null,
            formatarNumero: _formatarNumero,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'O Produto possui delivery',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
              ThemedSwitch(
                theme: theme,
                value: _possuiDelivery,
                onChanged: (valor) =>
                    setState(() => _possuiDelivery = valor),
              ),
            ],
          ),
          if (_possuiDelivery) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ThemedTextField(
                    theme: theme,
                    controller: _freteGratisAteController,
                    label: 'Frete Grátis até',
                    tipoDeTeclado: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ThemedTextField(
                    theme: theme,
                    controller: _valorPorKmController,
                    label: 'R\$ por Km',
                    tipoDeTeclado: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: theme.borderColor, width: 1.5),
      ),
      title: Text(
        editando ? 'Editar Item' : 'Novo Item',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: larguraPopup,
        child: SingleChildScrollView(
          child: modoExpandido
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildColunaIdentificacao()),
                    const SizedBox(width: 18),
                    Expanded(child: buildColunaOperacaoEEstoque()),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildColunaIdentificacao(),
                    const SizedBox(height: 14),
                    buildColunaOperacaoEEstoque(),
                  ],
                ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        SizedBox(
          width: 140,
          child: OutlinedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return theme.borderColor.withValues(alpha: 0.18);
                }
                return theme.buttonColor != Colors.transparent
                    ? theme.buttonColor
                    : Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return theme.buttonColor != Colors.transparent
                    ? theme.buttonTextColor
                    : theme.textColor;
              }),
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return BorderSide(color: theme.textColor, width: 1.4);
                }
                return BorderSide(color: theme.borderColor, width: 1.0);
              }),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            onPressed: _criar,
            child: Text(
              editando ? 'Salvar' : 'Criar',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.buttonColor != Colors.transparent
                    ? theme.buttonTextColor
                    : theme.textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}