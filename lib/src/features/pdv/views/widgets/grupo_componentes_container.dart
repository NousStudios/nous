import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/componente_loja_row.dart';

// Um "Grupo de Componentes" dentro de um Produto (ex: "Grupo de
// componentes A" = adicionais do lanche). Guarda sua própria lista de
// Componentes, criada pela opção "Adicionar Componente" no menu "⋮".
class GrupoComponentesContainer extends StatefulWidget {
  final AppTheme theme;

  // Título já pronto (ex: "Grupo de componentes A"), calculado por quem
  // criou este widget — o ProdutoLojaRow, que sabe a posição deste grupo
  // na lista dele e converte isso na letra certa.
  final String titulo;

  // Chamado quando o usuário escolhe "Excluir Grupo" no "⋮". Quem decide
  // tirar este grupo inteiro da lista é o ProdutoLojaRow (pai).
  final VoidCallback onExcluir;

  const GrupoComponentesContainer({
    super.key,
    required this.theme,
    required this.titulo,
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
              Expanded(
                child: Text(
                  widget.titulo,
                  style: theme.getTextStyle(fontSize: 11),
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