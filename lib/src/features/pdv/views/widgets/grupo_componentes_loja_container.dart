import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

// Um "card" de Grupo de Componentes dentro da aba Loja. É basicamente
// uma cópia do CategoriaLojaContainer — mesmo layout, mesma lógica de
// mostrar os Itens já vinculados a ele — mas com "Editar Grupo" e
// "Excluir Grupo" no menu "⋮".
//
// ALTERADO: assim como a Categoria, este widget deixou de guardar
// sozinho se está "expandido" (bool interno). Agora recebe isso de
// fora, pela propriedade "expandida" e pelo callback
// "aoAlternarExpansao" — a tela DadosPerfilView é quem decide,
// justamente para poder tirar o limite de altura da lista e rolar até
// aqui quando o grupo expande.
//
// ALTERADO (edição inline do nome): o nome do grupo, que antes era só
// um Text estático (só editável pelo popup "Editar Grupo"), agora é
// um TextField sem borda — igual ao nome/preço dos produtos em
// ProdutoLojaRow e igual ao que já foi feito em CategoriaLojaContainer.
// Dá pra editar tocando direto nele, sem abrir nada. O popup "Editar
// Grupo" continua existindo (widget.onEditar). onNomeAlterado é
// opcional de propósito, pelo mesmo motivo da categoria: a tela que
// usa este widget pode ainda não ter a persistência pronta pra esse
// callback.
//
// ALTERADO (ícone de imagem): adicionado um quadrado de 36x36 no
// início da barra, hoje só com um ícone de placeholder
// (Icons.image_outlined) — mesmo padrão usado em
// CategoriaLojaContainer e ProdutoLojaRow — preparado para, numa
// atualização futura, o usuário poder colocar uma imagem de verdade
// ali.
class GrupoComponentesLojaContainer extends StatefulWidget {
  final AppTheme theme;
  final String nome;

  final List<String> itemIds;
  final List<ItemLoja> itensDisponiveis;

  // NOVO: estado de expansão e o callback pra alternar, controlados
  // por fora.
  final bool expandida;
  final VoidCallback aoAlternarExpansao;

  final ValueChanged<String> onAdicionarItem;
  final ValueChanged<String> onRemoverItem;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  // NOVO: chamado a cada mudança no nome deste grupo, editado direto
  // no campo da barra. Opcional para não quebrar telas que ainda não
  // passam esse callback.
  final ValueChanged<String>? onNomeAlterado;

  final void Function(String itemId, String novoNome) onEditarNomeItem;
  final void Function(String itemId, String novoPreco) onEditarPrecoItem;

  // NOVO: chamado quando o usuário escolhe "Editar Item" no "⋮" de um
  // produto dentro deste grupo.
  final void Function(ItemLoja item) onEditarItem;

  const GrupoComponentesLojaContainer({
    super.key,
    required this.theme,
    required this.nome,
    required this.itemIds,
    required this.itensDisponiveis,
    required this.expandida,
    required this.aoAlternarExpansao,
    required this.onAdicionarItem,
    required this.onRemoverItem,
    required this.onEditar,
    required this.onExcluir,
    required this.onEditarNomeItem,
    required this.onEditarPrecoItem,
    required this.onEditarItem,
    this.onNomeAlterado,
  });

  @override
  State<GrupoComponentesLojaContainer> createState() =>
      _GrupoComponentesLojaContainerState();
}

class _GrupoComponentesLojaContainerState
    extends State<GrupoComponentesLojaContainer> {
  bool _ativa = true;

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);

  @override
  void didUpdateWidget(covariant GrupoComponentesLojaContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o nome mudou por FORA deste campo (ex: editado pelo popup
    // "Editar Grupo" em outra tela), atualiza o texto mostrado aqui
    // também — mesmo padrão usado em CategoriaLojaContainer e
    // ProdutoLojaRow.
    if (widget.nome != oldWidget.nome && widget.nome != _nomeController.text) {
      _nomeController.text = widget.nome;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _abrirSeletorDeItem() {
    final theme = widget.theme;
    final disponiveis = widget.itensDisponiveis
        .where((item) => !widget.itemIds.contains(item.id))
        .toList();

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
            'Adicionar item',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: disponiveis.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nenhum item disponível. Crie um item primeiro pelo '
                      'botão "Novo Item".',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                          fontSize: 13, color: theme.secondaryTextColor),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in disponiveis)
                          ListTile(
                            title: Text(item.nome, style: theme.getTextStyle()),
                            onTap: () {
                              widget.onAdicionarItem(item.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // NOVO: placeholder de imagem, mesmo padrão visual do
              // ícone usado em CategoriaLojaContainer e
              // ProdutoLojaRow. Sem função ainda — só reserva o espaço
              // para a foto do grupo no futuro.
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.image_outlined,
                    size: 18, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 8),
              // ALTERADO: era um Text estático; agora é um TextField
              // sem borda, editável direto na barra (mesmo padrão do
              // nome da categoria e do nome do produto).
              Expanded(
                child: TextField(
                  controller: _nomeController,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: theme.getTextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (valor) => widget.onNomeAlterado?.call(valor),
                ),
              ),
              Switch(
                value: _ativa,
                activeThumbColor: theme.buttonColor,
                onChanged: (valor) => setState(() => _ativa = valor),
              ),
              GestureDetector(
                onTap: _abrirSeletorDeItem,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Adicionar item',
                        style: theme.getTextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Icon(Icons.add_circle_outline,
                        size: 14, color: theme.secondaryTextColor),
                  ],
                ),
              ),
              // ALTERADO: era "setState(() => _expandida = !_expandida)".
              IconButton(
                icon: Icon(
                  widget.expandida
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.secondaryTextColor,
                ),
                onPressed: widget.aoAlternarExpansao,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'editar') widget.onEditar();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar Grupo', style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Grupo', style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),
          // ALTERADO: era "if (_expandida)".
          if (widget.expandida) ...[
            const SizedBox(height: 8),
            if (widget.itemIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Text('Produtos',
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Ativo',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Preços',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              for (final id in widget.itemIds) ...[
                Builder(builder: (context) {
                  final item = widget.itensDisponiveis
                      .where((i) => i.id == id)
                      .firstOrNull;
                  if (item == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      ProdutoLojaRow(
                        key: ValueKey('produto_$id'),
                        theme: theme,
                        item: item,
                        onExcluir: () => widget.onRemoverItem(id),
                        onEditar: () => widget.onEditarItem(item),
                        onNomeAlterado: (novoNome) =>
                            widget.onEditarNomeItem(id, novoNome),
                        onPrecoAlterado: (novoPreco) =>
                            widget.onEditarPrecoItem(id, novoPreco),
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                }),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Nenhum item neste grupo ainda.',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
          ],
        ],
      ),
    );
  }
}