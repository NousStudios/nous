import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

// Popup "Novo Grupo de Componentes", criado direto pelo botão da aba
// Loja (diferente do grupo de componentes que já existe dentro da
// árvore Categoria > Produto > Grupo, esse aqui é "solto"). Parecido
// com o NovaCategoriaDialog, mas sem Produto/Serviço, e com uma seção
// para escolher, entre os Itens já criados pelo botão "Novo Item",
// quais fazem parte deste grupo.
class NovoGrupoComponentesDialog extends StatefulWidget {
  final AppTheme theme;

  // Itens já existentes (criados antes pelo botão "Novo Item"), para o
  // usuário escolher quais entram neste grupo.
  final List<ItemLoja> itensDisponiveis;

  final void Function(GrupoComponentesLoja grupo) onCriar;

  const NovoGrupoComponentesDialog({
    super.key,
    required this.theme,
    required this.itensDisponiveis,
    required this.onCriar,
  });

  // Função de conveniência, mesmo padrão dos outros dois popups.
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    required void Function(GrupoComponentesLoja grupo) onCriar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NovoGrupoComponentesDialog(
        theme: theme,
        itensDisponiveis: itensDisponiveis,
        onCriar: onCriar,
      ),
    );
  }

  @override
  State<NovoGrupoComponentesDialog> createState() =>
      _NovoGrupoComponentesDialogState();
}

class _NovoGrupoComponentesDialogState
    extends State<NovoGrupoComponentesDialog> {
  final _nomeController = TextEditingController();

  // Ids dos itens que o usuário já escolheu para este grupo, na ordem
  // em que foram adicionados.
  final List<String> _itemIdsSelecionados = [];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // Abre um popup de seleção com os itens que AINDA NÃO foram
  // adicionados a este grupo (para não deixar escolher o mesmo item
  // duas vezes). Ao tocar num item da lista, ele é adicionado e o
  // popup de seleção fecha — se o usuário quiser adicionar mais de um,
  // basta tocar em "Adicionar item" novamente.
  void _abrirSeletorDeItem() {
    final theme = widget.theme;
    final itensAindaNaoEscolhidos = widget.itensDisponiveis
        .where((item) => !_itemIdsSelecionados.contains(item.id))
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
            child: itensAindaNaoEscolhidos.isEmpty
                // Mensagem clara para os dois motivos possíveis de a
                // lista estar vazia: ou não existe nenhum item ainda
                // (usuário precisa criar um primeiro com o botão "Novo
                // Item"), ou todos já foram adicionados a este grupo.
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.itensDisponiveis.isEmpty
                          ? 'Nenhum item foi criado ainda. Use o botão '
                              '"Novo Item" para criar um primeiro.'
                          : 'Todos os itens já foram adicionados a este '
                              'grupo.',
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
                        for (final item in itensAindaNaoEscolhidos)
                          ListTile(
                            title: Text(item.nome, style: theme.getTextStyle()),
                            onTap: () {
                              setState(
                                  () => _itemIdsSelecionados.add(item.id));
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

  void _removerItemSelecionado(String itemId) {
    setState(() => _itemIdsSelecionados.remove(itemId));
  }

  // Busca o nome de exibição de um item selecionado, a partir do seu
  // id. Como guardamos só o id na lista (não o objeto ItemLoja inteiro,
  // pelo mesmo motivo já explicado no modelo de dados), precisamos
  // encontrar o item correspondente na lista completa recebida.
  String _nomeDoItem(String itemId) {
    return widget.itensDisponiveis
        .where((item) => item.id == itemId)
        .map((item) => item.nome)
        .firstOrNull ??
        'Item removido';
  }

  void _criar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final grupo = GrupoComponentesLoja.novo(
      nome: nome,
      itemIds: List.of(_itemIdsSelecionados),
    );

    widget.onCriar(grupo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final larguraTela = MediaQuery.sizeOf(context).width;
    final larguraPopup = larguraTela < 380 ? larguraTela * 0.9 : 340.0;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: theme.borderColor, width: 1.5),
      ),
      title: Text(
        'Novo Grupo de Componentes',
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
              // Quadrado de foto — decorativo por enquanto, mesmo
              // estágio dos outros dois popups.
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
                label: 'Nome do grupo de componentes',
              ),
              const SizedBox(height: 16),

              // Lista de itens já adicionados a este grupo, cada um com
              // um "x" para remover — mesmo padrão visual da lista de
              // variantes do NovoItemDialog.
              for (final itemId in _itemIdsSelecionados) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _nomeDoItem(itemId),
                          style: theme.getTextStyle(fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removerItemSelecionado(itemId),
                        child: Icon(Icons.close,
                            size: 18, color: theme.secondaryTextColor),
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
                onPressed: _abrirSeletorDeItem,
                icon: Icon(Icons.add, color: theme.textColor, size: 18),
                label: Text(
                  'Adicionar item',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
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
              'Criar',
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
}