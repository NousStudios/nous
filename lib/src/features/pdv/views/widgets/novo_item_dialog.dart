import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class NovoItemDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final ItemLoja? itemParaEditar;
  final List<String> categoriaIdsIniciais;
  final List<String> grupoIdsIniciais;
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

  TipoItemLoja? _tipo;
  bool _possuiDelivery = false;

  late final Set<String> _categoriasSelecionadas =
      widget.categoriaIdsIniciais.toSet();
  late final Set<String> _gruposSelecionados =
      widget.grupoIdsIniciais.toSet();

  final List<TextEditingController> _variantesControllers = [];

  @override
  void initState() {
    super.initState();

    final item = widget.itemParaEditar;
    if (item == null) return;

    _nomeController.text = item.nome;
    _precoController.text = item.preco;
    _descricaoController.text = item.descricao;
    _freteGratisAteController.text = item.freteGratisAte;
    _valorPorKmController.text = item.valorPorKm;
    _tipo = item.tipo;
    _possuiDelivery = item.possuiDelivery;

    for (final variante in item.variantes) {
      _variantesControllers.add(TextEditingController(text: variante));
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _descricaoController.dispose();
    _freteGratisAteController.dispose();
    _valorPorKmController.dispose();
    for (final controller in _variantesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _adicionarCampoVariante() {
    setState(() => _variantesControllers.add(TextEditingController()));
  }

  void _removerCampoVariante(int index) {
    setState(() {
      _variantesControllers[index].dispose();
      _variantesControllers.removeAt(index);
    });
  }

  void _abrirSeletorMultiplo({
    required String titulo,
    required Map<String, String> opcoes,
    required Set<String> selecionados,
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
                width: 280,
                child: opcoes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhuma opção disponível ainda.',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final entrada in opcoes.entries)
                              CheckboxListTile(
                                value: selecionados.contains(entrada.key),
                                title:
                                    Text(entrada.value, style: theme.getTextStyle()),
                                activeColor: theme.buttonColor,
                                checkColor: theme.buttonTextColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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

  void _criar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final variantes = _variantesControllers
        .map((controller) => controller.text.trim())
        .where((texto) => texto.isNotEmpty)
        .toList();

    final itemExistente = widget.itemParaEditar;

    final item = itemExistente != null
        ? itemExistente.copyWith(
            nome: nome,
            tipo: _tipo,
            preco: _precoController.text.trim(),
            variantes: variantes,
            descricao: _descricaoController.text.trim(),
            possuiDelivery: _possuiDelivery,
            freteGratisAte: _freteGratisAteController.text.trim(),
            valorPorKm: _valorPorKmController.text.trim(),
          )
        : ItemLoja.novo(
            nome: nome,
            tipo: _tipo,
            preco: _precoController.text.trim(),
            variantes: variantes,
            descricao: _descricaoController.text.trim(),
            possuiDelivery: _possuiDelivery,
            freteGratisAte: _freteGratisAteController.text.trim(),
            valorPorKm: _valorPorKmController.text.trim(),
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
      for (final categoria in widget.categorias) categoria.id: categoria.nome,
    };
    final opcoesGrupos = {
      for (final grupo in widget.gruposComponentes) grupo.id: grupo.nome,
    };

    final nomesCategoriasSelecionadas = widget.categorias
        .where((c) => _categoriasSelecionadas.contains(c.id))
        .map((c) => c.nome)
        .join(', ');
    final nomesGruposSelecionados = widget.gruposComponentes
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: theme.secondaryTextColor,
                  size: 32,
                ),
              ),
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
                ),
              ),
              const SizedBox(height: 16),

              for (var i = 0; i < _variantesControllers.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: ThemedTextField(
                        theme: theme,
                        controller: _variantesControllers[i],
                        label: 'Variante ${i + 1}',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => _removerCampoVariante(i),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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