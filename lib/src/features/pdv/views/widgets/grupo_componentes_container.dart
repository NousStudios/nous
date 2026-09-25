import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/componente_loja_row.dart';

class GrupoComponentesContainer extends StatefulWidget {
  final AppTheme theme;
  final String titulo;
  final ValueChanged<String> onTituloAlterado;
  final VoidCallback onExcluir;
  final bool podeEditar;

  const GrupoComponentesContainer({
    super.key,
    required this.theme,
    required this.titulo,
    required this.onTituloAlterado,
    required this.onExcluir,
    this.podeEditar = true,
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

  void _avisarSemPermissao() {
    final theme = widget.theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Você não tem permissão para fazer isso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GrupoComponentesContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final podeEditar = widget.podeEditar;

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
              Expanded(
                child: TextField(
                  controller: _tituloController,
                  readOnly: !podeEditar,
                  onTap: podeEditar ? null : _avisarSemPermissao,
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
                  if (!podeEditar) {
                    _avisarSemPermissao();
                    return;
                  }
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
                podeEditar: podeEditar,
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