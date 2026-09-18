import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_container.dart';

// Uma linha de "Produto" dentro de uma Categoria expandida (ex: um item
// do cardápio). Guarda sua própria lista de Grupos de Componentes,
// criada pela opção "Adicionar Grupo de Componentes" no menu "⋮". Ao
// expandir (seta), mostra esses grupos, cada um com seus componentes.
class ProdutoLojaRow extends StatefulWidget {
  final AppTheme theme;

  // Chamado quando o usuário escolhe "Excluir Produto" no "⋮". Quem
  // decide tirar este produto da lista é a CategoriaLojaContainer (pai).
  final VoidCallback onExcluir;

  const ProdutoLojaRow({
    super.key,
    required this.theme,
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

  // Transforma a posição do grupo na lista (0, 1, 2...) na letra
  // correspondente (A, B, C...) usada no título, igual ao protótipo
  // ("Grupo de componentes A"). 65 é o código da letra 'A'.
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

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
              // Quadrado de imagem — só um ícone de placeholder por
              // enquanto, até existir upload de imagem de verdade.
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
                  'Nome do Produto',
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(fontSize: 12),
                ),
              ),
              Switch(
                value: _ativo,
                activeThumbColor: theme.buttonColor,
                onChanged: (valor) => setState(() => _ativo = valor),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'R\$ 00,00',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(fontSize: 11),
                ),
              ),
              IconButton(
                icon: Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.secondaryTextColor,
                ),
                onPressed: () => setState(() => _expandido = !_expandido),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'grupo') _adicionarGrupo();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'grupo',
                    child: Text('Adicionar Grupo de Componentes',
                        style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child:
                        Text('Excluir Produto', style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),

          // Grupos de componentes deste produto, só aparecem quando o
          // produto está expandido.
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