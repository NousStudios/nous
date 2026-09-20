import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

// Um "card" de categoria dentro da aba Loja (ex: "Bebidas", "Lanches").
// Mostra os Itens de verdade que já foram associados a ela (a lista
// vem de fora, em itemIds) e, ao expandir, cada um pode virar
// ProdutoLojaRow com seus grupos de componentes.
//
// ALTERADO: este widget deixou de decidir sozinho se está "expandido"
// ou não. Antes, isso era um bool guardado aqui dentro (_expandida).
// Agora, quem manda nisso é a tela DadosPerfilView, através da
// propriedade "expandida" (o estado atual) e do callback
// "aoAlternarExpansao" (avisa a tela que o usuário quer abrir/fechar).
// Isso é chamado de "widget controlado": a tela de fora enxerga e
// decide o estado, em vez de ele ficar escondido aqui dentro. Foi
// necessário porque, quando uma categoria expande, a TELA precisa
// saber disso pra tirar o limite de altura da lista e rolar até ela —
// coisa que o container, sozinho, não tem como fazer.
//
// ALTERADO (edição inline do nome): o nome da categoria, que antes era
// só um Text estático (só editável pelo popup "Editar Categoria"),
// agora é um TextField sem borda — igual ao nome/preço dos produtos em
// ProdutoLojaRow. Dá pra editar tocando direto nele, sem abrir nada. O
// popup "Editar Categoria" continua existindo (widget.onEditar), caso
// a tela queira abrir algo mais completo no futuro. onNomeAlterado é
// opcional de propósito: se a tela que usa este widget ainda não
// tiver essa persistência pronta, o campo continua editável na tela
// (localmente) sem quebrar a compilação — mas o ideal é a tela passar
// esse callback para salvar a mudança de verdade.
//
// ALTERADO (ícone de imagem): adicionado um quadrado de 36x36 no
// início da barra, hoje só com um ícone de placeholder
// (Icons.image_outlined) — igual ao que já existe em ProdutoLojaRow —
// preparado para, numa atualização futura, o usuário poder colocar
// uma imagem de verdade ali.
class CategoriaLojaContainer extends StatefulWidget {
  final AppTheme theme;
  final String nome;

  final List<String> itemIds;
  final List<ItemLoja> itensDisponiveis;

  // NOVO: estado de expansão e o callback pra alternar (abrir/fechar),
  // controlados por fora.
  final bool expandida;
  final VoidCallback aoAlternarExpansao;

  final ValueChanged<String> onAdicionarItem;
  final ValueChanged<String> onRemoverItem;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  // NOVO: chamado a cada mudança no nome desta categoria, editado
  // direto no campo da barra. Opcional para não quebrar telas que
  // ainda não passam esse callback.
  final ValueChanged<String>? onNomeAlterado;

  // Repassados até o ProdutoLojaRow de cada item, para permitir editar
  // nome/preço direto na lista, sem abrir nenhum popup.
  final void Function(String itemId, String novoNome) onEditarNomeItem;
  final void Function(String itemId, String novoPreco) onEditarPrecoItem;

  // NOVO: chamado quando o usuário escolhe "Editar Item" no "⋮" de um
  // produto dentro desta categoria. Recebe o ItemLoja inteiro, porque
  // é isso que o popup completo de edição precisa.
  final void Function(ItemLoja item) onEditarItem;

  const CategoriaLojaContainer({
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
  State<CategoriaLojaContainer> createState() =>
      _CategoriaLojaContainerState();
}

class _CategoriaLojaContainerState extends State<CategoriaLojaContainer> {
  // _ativa continua sendo um estado só "de tela" (visual, não
  // persistido ainda) — diferente da expansão, ninguém mais precisa
  // saber se o switch está ligado, então ele pode continuar guardado
  // aqui dentro, sem problema.
  bool _ativa = true;

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);

  @override
  void didUpdateWidget(covariant CategoriaLojaContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o nome mudou por FORA deste campo (ex: editado pelo popup
    // "Editar Categoria" em outra tela), atualiza o texto mostrado
    // aqui também — mesmo padrão usado em ProdutoLojaRow.
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
              // ícone usado em ProdutoLojaRow. Sem função ainda — só
              // reserva o espaço para a foto da categoria no futuro.
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
              // nome do produto em ProdutoLojaRow).
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
              // Agora só avisa a tela de fora, que decide o novo
              // estado e também cuida de rolar até aqui.
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
                    child: Text('Editar Categoria', style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Categoria',
                        style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),
          // ALTERADO: era "if (_expandida)"; agora usa a propriedade
          // vinda de fora.
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
                  'Nenhum item nesta categoria ainda.',
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