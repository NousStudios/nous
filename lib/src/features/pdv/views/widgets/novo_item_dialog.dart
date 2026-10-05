import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';

class _VarianteFormControllers {
  final TextEditingController nomeController;
  final TextEditingController precoController;

  _VarianteFormControllers({String nome = '', String preco = ''})
      : nomeController = TextEditingController(text: nome),
        precoController = TextEditingController(text: preco);

  void dispose() {
    nomeController.dispose();
    precoController.dispose();
  }
}

class NovoItemDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final ItemLoja? itemParaEditar;
  final List<String> categoriaIdsIniciais;
  final List<String> grupoIdsIniciais;
  final void Function(CategoriaLoja)? onCategoriaCriada;
  final void Function(GrupoComponentesLoja)? onGrupoCriado;
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
  final _descricaoController = TextEditingController();
  final _freteGratisAteController = TextEditingController();
  final _valorPorKmController = TextEditingController();
  final _estoqueMinimoController = TextEditingController();
  final _consumoController = TextEditingController();

  TipoItemLoja? _tipo;
  bool _possuiDelivery = false;
  UnidadeItemLoja _unidadeBase = UnidadeItemLoja.un;

  late final List<CategoriaLoja> _categorias = List.from(widget.categorias);
  late final List<GrupoComponentesLoja> _grupos =
      List.from(widget.gruposComponentes);

  late final Set<String> _categoriasSelecionadas =
      widget.categoriaIdsIniciais.toSet();
  late final Set<String> _gruposSelecionados =
      widget.grupoIdsIniciais.toSet();

  late final List<String> _imagens =
      List.from(widget.itemParaEditar?.imagens ?? []);

  final List<_VarianteFormControllers> _variantesControllers = [];

  @override
  void initState() {
    super.initState();

    final item = widget.itemParaEditar;
    if (item == null) {
      _consumoController.text = '1';
      return;
    }

    _nomeController.text = item.nome;
    _precoController.text = item.preco;
    _descricaoController.text = item.descricao;
    _freteGratisAteController.text = item.freteGratisAte;
    _valorPorKmController.text = item.valorPorKm;
    _estoqueMinimoController.text = item.estoqueMinimo;
    _tipo = item.tipo;
    _possuiDelivery = item.possuiDelivery;
    _unidadeBase = item.unidadeBase;
    _consumoController.text = _formatarNumero(item.consumoPorVenda);

    for (final variante in item.variantes) {
      _variantesControllers.add(
        _VarianteFormControllers(
          nome: variante.nome,
          preco: variante.preco,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _descricaoController.dispose();
    _freteGratisAteController.dispose();
    _valorPorKmController.dispose();
    _estoqueMinimoController.dispose();
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
    setState(() => _variantesControllers.add(_VarianteFormControllers()));
  }

  void _removerCampoVariante(int index) {
    setState(() {
      _variantesControllers[index].dispose();
      _variantesControllers.removeAt(index);
    });
  }

  Future<void> _selecionarFotos() async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final arquivos = await openFiles(acceptedTypeGroups: const [grupo]);
    if (arquivos.isEmpty) return;

    var ignorados = 0;

    for (final arquivo in arquivos) {
      final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
      if (salvo != null) {
        if (!_imagens.contains(salvo)) {
          _imagens.add(salvo);
        }
      } else {
        ignorados++;
      }
    }

    if (mounted) {
      setState(() {});
      if (ignorados > 0) {
        final theme = widget.theme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              '$ignorados imagem(ns) foram ignoradas por tamanho superior a 5MB ou formato inválido.',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  void _removerFoto(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
  }

  void _abrirSeletorMultiplo({
    required String titulo,
    required Map<String, String> opcoes,
    required Set<String> selecionados,
    VoidCallback? onCriarNovo,
    String? textoCriarNovo,
  }) {
    final theme = widget.theme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                titulo,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onCriarNovo != null) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.8),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            onCriarNovo();
                            setDialogState(() {});
                          },
                          icon: Icon(Icons.add, size: 16, color: theme.textColor),
                          label: Text(
                            textoCriarNovo ?? 'Criar novo',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (opcoes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma opção cadastrada ainda.\nClique acima para criar.',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        )
                      else
                        for (final entrada in opcoes.entries)
                          CheckboxListTile(
                            value: selecionados.contains(entrada.key),
                            title: Text(
                              entrada.value,
                              style: theme.getTextStyle(fontSize: 14),
                            ),
                            activeColor: theme.buttonColor,
                            checkColor: theme.buttonTextColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (marcado) {
                              setDialogState(() {
                                if (marcado == true) {
                                  selecionados.add(entrada.key);
                                } else {
                                  selecionados.remove(entrada.key);
                                }
                              });
                              setState(() {});
                            },
                          ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Concluir',
                    style: theme.getTextStyle(color: theme.textColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
              child: Text(
                (valorExibido == null || valorExibido.isEmpty)
                    ? label
                    : valorExibido,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selecionado ? theme.buttonColor : Colors.transparent,
          foregroundColor:
              selecionado ? theme.buttonTextColor : theme.textColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => setState(() => _unidadeBase = valor),
        child: Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 12,
            color: selecionado ? theme.buttonTextColor : theme.textColor,
          ),
        ),
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

  Widget _buildEspacoFotos(AppTheme theme) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: _imagens.isEmpty
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selecionarFotos,
                child: Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.secondaryTextColor,
                    size: 42,
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagens.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _imagens.length) {
                    return Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _selecionarFotos,
                        child: Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: theme.textColor,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }

                  final caminho = _imagens[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 110,
                          height: double.infinity,
                          color: theme.cardBackgroundColor,
                          child: Image.file(
                            File(caminho),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: theme.secondaryTextColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removerFoto(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
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
    final larguraPopup = larguraTela < 380 ? larguraTela * 0.9 : 340.0;

    final opcoesCategorias = {
      for (final categoria in _categorias) categoria.id: categoria.nome,
    };
    final opcoesGrupos = {
      for (final grupo in _grupos) grupo.id: grupo.nome,
    };

    final nomesCategoriasSelecionadas = _categorias
        .where((c) => _categoriasSelecionadas.contains(c.id))
        .map((c) => c.nome)
        .join(', ');
    final nomesGruposSelecionados = _grupos
        .where((g) => _gruposSelecionados.contains(g.id))
        .map((g) => g.nome)
        .join(', ');

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEspacoFotos(theme),
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _nomeController,
                label: 'Nome do novo item',
              ),
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _precoController,
                label: 'Preço (ex: 12,50)',
                tipoDeTeclado: TextInputType.number,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _consumoController,
                label: 'Consumo por venda (${_rotuloUnidade()})',
                tipoDeTeclado: TextInputType.number,
              ),
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _estoqueMinimoController,
                label: 'Estoque mínimo em ${_rotuloUnidade()} (opcional)',
                tipoDeTeclado: TextInputType.number,
              ),
              const SizedBox(height: 16),

              RadioGroup<TipoItemLoja>(
                groupValue: _tipo,
                onChanged: (valor) => setState(() => _tipo = valor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _opcaoTipo(theme, 'Produto', TipoItemLoja.produto),
                    const SizedBox(width: 32),
                    _opcaoTipo(theme, 'Serviço', TipoItemLoja.servico),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _campoSelecao(
                label: 'Categorias do item',
                valorExibido: nomesCategoriasSelecionadas,
                onTap: () => _abrirSeletorMultiplo(
                  titulo: 'Categorias do item',
                  opcoes: opcoesCategorias,
                  selecionados: _categoriasSelecionadas,
                  onCriarNovo: _abrirCriarNovaCategoria,
                  textoCriarNovo: '+ Nova Categoria',
                ),
              ),
              const SizedBox(height: 12),

              _campoSelecao(
                label: 'Grupos de componentes',
                valorExibido: nomesGruposSelecionados,
                onTap: () => _abrirSeletorMultiplo(
                  titulo: 'Grupos de componentes',
                  opcoes: opcoesGrupos,
                  selecionados: _gruposSelecionados,
                  onCriarNovo: _abrirCriarNovoGrupo,
                  textoCriarNovo: '+ Novo Grupo de Componentes',
                ),
              ),
              const SizedBox(height: 16),

              for (var i = 0; i < _variantesControllers.length; i++) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ThemedTextField(
                          theme: theme,
                          controller: _variantesControllers[i].nomeController,
                          label: 'Variante ${i + 1} (ex: G, 500ml)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ThemedTextField(
                          theme: theme,
                          controller: _variantesControllers[i].precoController,
                          label: 'Preço (R\$)',
                          tipoDeTeclado: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        tooltip: 'Remover variante',
                        onPressed: () => _removerCampoVariante(i),
                      ),
                    ],
                  ),
                ),
              ],

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _adicionarCampoVariante,
                icon: Icon(Icons.add, color: theme.textColor, size: 18),
                label: Text(
                  'Adicionar variante',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _descricaoController,
                label: 'Descrição do item',
                linhas: 3,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'O Produto possui delivery',
                      style: theme.getTextStyle(fontSize: 13),
                    ),
                  ),
                  Switch(
                    value: _possuiDelivery,
                    activeThumbColor: theme.buttonColor,
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: _criar,
            child: Text(
              editando ? 'Salvar' : 'Criar',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _opcaoTipo(AppTheme theme, String rotulo, TipoItemLoja valor) {
    return Column(
      children: [
        Text(rotulo, style: theme.getTextStyle(fontSize: 13)),
        Radio<TipoItemLoja>(value: valor, activeColor: theme.borderColor),
      ],
    );
  }
}