import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_container.dart';

class ProdutoLojaRow extends StatefulWidget {
  final AppTheme theme;
  final ItemLoja item;
  final VoidCallback onExcluir;
  final VoidCallback onEditar;
  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;
  final bool podeEditar;

  const ProdutoLojaRow({
    super.key,
    required this.theme,
    required this.item,
    required this.onExcluir,
    required this.onEditar,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
    this.podeEditar = true,
  });

  @override
  State<ProdutoLojaRow> createState() => _ProdutoLojaRowState();
}

class _ProdutoLojaRowState extends State<ProdutoLojaRow> {
  bool _ativo = true;
  bool _expandido = false;

  final List<int> _grupoIds = [];
  int _proximoIdGrupo = 0;

  final Map<int, String> _gruposTitulos = {};

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.item.nome);
  late final TextEditingController _precoController =
      TextEditingController(text: widget.item.preco);

  String _letraDoGrupo(int indice) => String.fromCharCode(65 + indice);

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

  void _adicionarGrupo() {
    if (!widget.podeEditar) {
      _avisarSemPermissao();
      return;
    }
    setState(() {
      final id = _proximoIdGrupo;
      _gruposTitulos[id] =
          'Grupo de componentes ${_letraDoGrupo(_grupoIds.length)}';
      _grupoIds.add(id);
      _proximoIdGrupo++;
    });
  }

  void _removerGrupo(int id) {
    setState(() {
      _grupoIds.remove(id);
      _gruposTitulos.remove(id);
    });
  }

  void _renomearGrupo(int id, String novoTitulo) {
    _gruposTitulos[id] = novoTitulo;
  }

  @override
  void didUpdateWidget(covariant ProdutoLojaRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.nome != oldWidget.item.nome &&
        widget.item.nome != _nomeController.text) {
      _nomeController.text = widget.item.nome;
    }
    if (widget.item.preco != oldWidget.item.preco &&
        widget.item.preco != _precoController.text) {
      _precoController.text = widget.item.preco;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _abrirMenuOpcoes(
      BuildContext context, Offset posicaoToque) async {
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
          value: 'editar',
          child: Text('Editar Item', style: theme.getTextStyle()),
        ),
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

    if (selecionado == null) return;

    if (!widget.podeEditar) {
      _avisarSemPermissao();
      return;
    }

    if (selecionado == 'editar') widget.onEditar();
    if (selecionado == 'grupo') _adicionarGrupo();
    if (selecionado == 'excluir') widget.onExcluir();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final podeEditar = widget.podeEditar;

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
                child: TextField(
                  controller: _nomeController,
                  readOnly: !podeEditar,
                  onTap: podeEditar ? null : _avisarSemPermissao,
                  maxLines: 1,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onNomeAlterado,
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _ativo,
                  activeThumbColor: theme.buttonColor,
                  onChanged: podeEditar
                      ? (valor) => setState(() => _ativo = valor)
                      : null,
                ),
              ),
              SizedBox(
                width: 66,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$',
                      style: theme.getTextStyle(fontSize: 11),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _precoController,
                        readOnly: !podeEditar,
                        onTap: podeEditar ? null : _avisarSemPermissao,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: theme.getTextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '00,00',
                        ),
                        onChanged: widget.onPrecoAlterado,
                      ),
                    ),
                  ],
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
                podeEditar: podeEditar,
                titulo: _gruposTitulos[id] ??
                    'Grupo de componentes ${_letraDoGrupo(_grupoIds.indexOf(id))}',
                onTituloAlterado: (novoTitulo) =>
                    _renomearGrupo(id, novoTitulo),
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