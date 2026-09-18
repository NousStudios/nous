import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

// Popup "Novo Item" / "Editar Item". Mesma tela para os dois casos:
// se "itemParaEditar" vier preenchido, os campos começam já
// preenchidos com os dados dele, o título vira "Editar Item" e o botão
// vira "Salvar" em vez de "Criar". Continua não salvando nada por
// conta própria: ao terminar, só monta o ItemLoja (novo ou editado) e
// entrega para quem chamou via onCriar.
class NovoItemDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final ItemLoja? itemParaEditar;
  final void Function(ItemLoja item) onCriar;

  const NovoItemDialog({
    super.key,
    required this.theme,
    required this.categorias,
    required this.gruposComponentes,
    this.itemParaEditar,
    required this.onCriar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<CategoriaLoja> categorias,
    required List<GrupoComponentesLoja> gruposComponentes,
    ItemLoja? itemParaEditar,
    required void Function(ItemLoja item) onCriar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NovoItemDialog(
        theme: theme,
        categorias: categorias,
        gruposComponentes: gruposComponentes,
        itemParaEditar: itemParaEditar,
        onCriar: onCriar,
      ),
    );
  }

  @override
  State<NovoItemDialog> createState() => _NovoItemDialogState();
}

class _NovoItemDialogState extends State<NovoItemDialog> {
  final _nomeController = TextEditingController();
  // NOVO: controller do campo de preço.
  final _precoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _freteGratisAteController = TextEditingController();
  final _valorPorKmController = TextEditingController();

  TipoItemLoja? _tipo;
  String? _categoriaSelecionadaId;
  String? _grupoSelecionadoId;
  bool _possuiDelivery = false;

  final List<TextEditingController> _variantesControllers = [];

  @override
  void initState() {
    super.initState();

    final item = widget.itemParaEditar;
    if (item == null) return; // modo criação: campos começam vazios

    _nomeController.text = item.nome;
    _precoController.text = item.preco;
    _descricaoController.text = item.descricao;
    _freteGratisAteController.text = item.freteGratisAte;
    _valorPorKmController.text = item.valorPorKm;
    _tipo = item.tipo;
    _categoriaSelecionadaId = item.categoriaId;
    _grupoSelecionadoId = item.grupoComponentesId;
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

  void _abrirSeletor({
    required String titulo,
    required Map<String, String> opcoes,
    required String? selecionadoId,
    required ValueChanged<String?> aoSelecionar,
  }) {
    final theme = widget.theme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Nenhuma', style: theme.getTextStyle()),
                    trailing: selecionadoId == null
                        ? Icon(Icons.check, color: theme.buttonColor)
                        : null,
                    onTap: () {
                      aoSelecionar(null);
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  for (final entrada in opcoes.entries)
                    ListTile(
                      title: Text(entrada.value, style: theme.getTextStyle()),
                      trailing: selecionadoId == entrada.key
                          ? Icon(Icons.check, color: theme.buttonColor)
                          : null,
                      onTap: () {
                        aoSelecionar(entrada.key);
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
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
                valorExibido ?? label,
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: valorExibido != null
                      ? theme.textColor
                      : theme.secondaryTextColor,
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
    if (nome.isEmpty) return; // nome é o único campo realmente obrigatório

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
            categoriaId: _categoriaSelecionadaId,
            grupoComponentesId: _grupoSelecionadoId,
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
            categoriaId: _categoriaSelecionadaId,
            grupoComponentesId: _grupoSelecionadoId,
            variantes: variantes,
            descricao: _descricaoController.text.trim(),
            possuiDelivery: _possuiDelivery,
            freteGratisAte: _freteGratisAteController.text.trim(),
            valorPorKm: _valorPorKmController.text.trim(),
          );

    widget.onCriar(item);
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

    final nomeCategoriaSelecionada = widget.categorias
        .where((c) => c.id == _categoriaSelecionadaId)
        .map((c) => c.nome)
        .firstOrNull;
    final nomeGrupoSelecionado = widget.gruposComponentes
        .where((g) => g.id == _grupoSelecionadoId)
        .map((g) => g.nome)
        .firstOrNull;

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

              // NOVO: campo de preço, logo abaixo do nome. Teclado
              // numérico pra facilitar a digitação num celular.
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
                label: 'Categoria do item',
                valorExibido: nomeCategoriaSelecionada,
                onTap: () => _abrirSeletor(
                  titulo: 'Categoria do item',
                  opcoes: opcoesCategorias,
                  selecionadoId: _categoriaSelecionadaId,
                  aoSelecionar: (id) =>
                      setState(() => _categoriaSelecionadaId = id),
                ),
              ),
              const SizedBox(height: 12),

              _campoSelecao(
                label: 'Grupo de componentes',
                valorExibido: nomeGrupoSelecionado,
                onTap: () => _abrirSeletor(
                  titulo: 'Grupo de componentes',
                  opcoes: opcoesGrupos,
                  selecionadoId: _grupoSelecionadoId,
                  aoSelecionar: (id) =>
                      setState(() => _grupoSelecionadoId = id),
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
        // ALTERADO: era "activeColor: theme.buttonColor". No tema
        // escuro padrão, buttonColor é TRANSPARENTE (ele foi pensado
        // pra ser o fundo de botões "vazados", não uma cor visível
        // sozinha). Isso fazia o pontinho do Radio ficar invisível
        // assim que você selecionava — parecia que o botão "sumia",
        // mas ele continuava lá, só que pintado de transparente.
        // theme.borderColor sempre é uma cor sólida (branco no tema
        // escuro, preto no tema claro), então o Radio fica visível
        // nos dois temas.
        Radio<TipoItemLoja>(value: valor, activeColor: theme.borderColor),
      ],
    );
  }
}