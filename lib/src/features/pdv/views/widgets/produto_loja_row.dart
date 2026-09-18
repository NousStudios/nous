import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_container.dart';

// Uma linha de "Produto" dentro de uma Categoria expandida. Mostra o
// ItemLoja de verdade (escolhido no seletor da categoria). Continua
// guardando sua própria lista de Grupos de Componentes, criada pela
// opção "Adicionar Grupo de Componentes" no menu "⋮" — essa parte
// ainda não persiste (fica só na memória da tela), é um próximo passo
// separado.
class ProdutoLojaRow extends StatefulWidget {
  final AppTheme theme;
  final ItemLoja item;

  // Chamado quando o usuário escolhe "Excluir Produto" no "⋮". Quem
  // decide tirar este produto da categoria é a CategoriaLojaContainer
  // (pai) — na prática, remove o id deste item da lista itemIds da
  // categoria.
  final VoidCallback onExcluir;

  const ProdutoLojaRow({
    super.key,
    required this.theme,
    required this.item,
    required this.onExcluir,
  });

  @override
  State<ProdutoLojaRow> createState() => _ProdutoLojaRowState();
}

class _ProdutoLojaRowState extends State<ProdutoLojaRow> {
  bool _ativo = true;
  bool _expandido = false;

  final List<int> _grupoIds = [];
  int _proximoIdGrupo = 0;

  String _letraDoGrupo(int indice) => String.fromCharCode(65 + indice);

  void _adicionarGrupo() {
    setState(() {
      _grupoIds.add(_proximoIdGrupo);
      _proximoIdGrupo++;
    });
  }

  void _removerGrupo(int id) {
    setState(() => _grupoIds.remove(id));
  }

  Future<void> _abrirMenuOpcoes(BuildContext context, Offset posicaoToque) async {
    final theme = widget.theme;

    final selecionado = await showMenu<String>(
      context: context,
      color: theme.cardBackgroundColor,
      position: RelativeRect.fromLTRB(
        posicaoToque.dx,
        posicaoToque.dy,
        posicaoToque.dx,
        posicaoToque.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'grupo',
          child: Text('Adicionar Grupo de Componentes',
              style: theme.getTextStyle()),
        ),
        PopupMenuItem(
          value: 'excluir',
          child: Text('Excluir Produto', style: theme.getTextStyle()),
        ),
      ],
    );

    if (selecionado == 'grupo') _adicionarGrupo();
    if (selecionado == 'excluir') widget.onExcluir();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // NOVO: monta o texto do preço. Se o item não tiver preço definido
    // (campo vazio, caso comum em itens criados antes desta mudança),
    // mostra "R$ 00,00" como valor de reserva, em vez de deixar em
    // branco.
    final textoPreco =
        widget.item.preco.isEmpty ? 'R\$ 00,00' : 'R\$ ${widget.item.preco}';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
              Expanded(
                child: Text(
                  widget.item.nome,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(fontSize: 12),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _ativo,
                  activeThumbColor: theme.buttonColor,
                  onChanged: (valor) => setState(() => _ativo = valor),
                ),
              ),
              SizedBox(
                width: 52,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    textoPreco,
                    style: theme.getTextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _expandido = !_expandido),
                child: Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTapDown: (details) =>
                    _abrirMenuOpcoes(context, details.globalPosition),
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (_expandido && _grupoIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final id in _grupoIds) ...[
              GrupoComponentesContainer(
                key: ValueKey('grupo_$id'),
                theme: theme,
                titulo:
                    'Grupo de componentes ${_letraDoGrupo(_grupoIds.indexOf(id))}',
                onExcluir: () => _removerGrupo(id),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}