import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/componente_loja_row.dart';

// Um "Grupo de Componentes" dentro de um Produto (ex: "Grupo de
// componentes A" = adicionais do lanche). Guarda sua própria lista de
// Componentes, criada pela opção "Adicionar Componente" no menu "⋮".
//
// ALTERADO (edição inline do título): o título deste grupo, que antes
// era um Text estático (calculado pelo ProdutoLojaRow a partir da
// posição na lista, tipo "Grupo de componentes A"), agora é um
// TextField sem borda — mesmo padrão do nome do produto em
// ProdutoLojaRow. Quem "dona" o valor de verdade do título continua
// sendo o ProdutoLojaRow (pai): ele guarda o título atual de cada
// grupo e passa pra cá em "titulo"; este widget só mostra esse valor
// num campo editável e avisa o pai a cada mudança via
// "onTituloAlterado", pra ele persistir. Isso evita que o nome
// digitado pelo usuário seja sobrescrito pela letra automática (A, B,
// C...) sempre que a lista de grupos mudar.
//
// ALTERADO (ícone de imagem): adicionado um quadrado no início da
// barra, hoje só com um ícone de placeholder (Icons.image_outlined) —
// preparado para, numa atualização futura, o usuário poder colocar
// uma imagem de verdade ali.
class GrupoComponentesContainer extends StatefulWidget {
  final AppTheme theme;

  // Título atual deste grupo (ex: "Grupo de componentes A", ou um
  // nome customizado se o usuário já editou). Controlado por fora,
  // pelo ProdutoLojaRow.
  final String titulo;

  // NOVO: chamado a cada mudança no título, editado direto no campo
  // da barra.
  final ValueChanged<String> onTituloAlterado;

  // Chamado quando o usuário escolhe "Excluir Grupo" no "⋮". Quem decide
  // tirar este grupo inteiro da lista é o ProdutoLojaRow (pai).
  final VoidCallback onExcluir;

  const GrupoComponentesContainer({
    super.key,
    required this.theme,
    required this.titulo,
    required this.onTituloAlterado,
    required this.onExcluir,
  });

  @override
  State<GrupoComponentesContainer> createState() =>
      _GrupoComponentesContainerState();
}

class _GrupoComponentesContainerState
    extends State<GrupoComponentesContainer> {
  final List<int> _componenteIds = [];
  int _proximoIdComponente = 0;

  late final TextEditingController _tituloController =
      TextEditingController(text: widget.titulo);

  @override
  void didUpdateWidget(covariant GrupoComponentesContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o título mudou por FORA deste campo (ex: outro grupo foi
    // excluído e a letra automática deste mudou), atualiza o texto
    // mostrado aqui também — mesmo padrão usado em ProdutoLojaRow.
    if (widget.titulo != oldWidget.titulo &&
        widget.titulo != _tituloController.text) {
      _tituloController.text = widget.titulo;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  void _adicionarComponente() {
    setState(() {
      _componenteIds.add(_proximoIdComponente);
      _proximoIdComponente++;
    });
  }

  void _removerComponente(int id) {
    setState(() => _componenteIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // NOVO: placeholder de imagem, mesmo padrão visual do
              // ícone usado em ProdutoLojaRow (só um pouco menor, pra
              // caber no tamanho deste container aninhado).
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.image_outlined,
                    size: 14, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 6),
              // ALTERADO: era um Text estático; agora é um TextField
              // sem borda, editável direto na barra.
              Expanded(
                child: TextField(
                  controller: _tituloController,
                  maxLines: 1,
                  style: theme.getTextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onTituloAlterado,
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert,
                    size: 16, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'componente') _adicionarComponente();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'componente',
                    child: Text('Adicionar Componente',
                        style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Grupo', style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),
          if (_componenteIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final id in _componenteIds) ...[
              ComponenteLojaRow(
                key: ValueKey('componente_$id'),
                theme: theme,
                onExcluir: () => _removerComponente(id),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}