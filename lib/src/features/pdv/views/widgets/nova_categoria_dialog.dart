import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class NovaCategoriaDialog extends StatefulWidget {
  final AppTheme theme;

  final List<GrupoComponentesLoja> gruposComponentes;

  final CategoriaLoja? categoriaParaEditar;

  final void Function(CategoriaLoja categoria) onCriar;

  const NovaCategoriaDialog({
    super.key,
    required this.theme,
    required this.gruposComponentes,
    this.categoriaParaEditar,
    required this.onCriar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<GrupoComponentesLoja> gruposComponentes,
    CategoriaLoja? categoriaParaEditar,
    required void Function(CategoriaLoja categoria) onCriar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NovaCategoriaDialog(
        theme: theme,
        gruposComponentes: gruposComponentes,
        categoriaParaEditar: categoriaParaEditar,
        onCriar: onCriar,
      ),
    );
  }

  @override
  State<NovaCategoriaDialog> createState() => _NovaCategoriaDialogState();
}

class _NovaCategoriaDialogState extends State<NovaCategoriaDialog> {
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();

  TipoItemLoja? _tipo;
  final Set<String> _gruposSelecionados = {};

  @override
  void initState() {
    super.initState();

    final categoria = widget.categoriaParaEditar;
    if (categoria == null) return;

    _nomeController.text = categoria.nome;
    _precoController.text = categoria.preco;
    _tipo = categoria.tipo;
    _gruposSelecionados.addAll(categoria.grupoIds);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _abrirSeletorDeGrupos() {
    final theme = widget.theme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Grupos de componentes',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: SizedBox(
                width: 280,
                child: widget.gruposComponentes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum grupo de componentes criado ainda.',
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
                            for (final grupo in widget.gruposComponentes)
                              CheckboxListTile(
                                value: _gruposSelecionados.contains(grupo.id),
                                title: Text(grupo.nome,
                                    style: theme.getTextStyle()),
                                activeColor: theme.buttonColor,
                                checkColor: theme.buttonTextColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (marcado) {
                                  setDialogState(() {
                                    if (marcado == true) {
                                      _gruposSelecionados.add(grupo.id);
                                    } else {
                                      _gruposSelecionados.remove(grupo.id);
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Concluir',
                    style: theme.getTextStyle(color: theme.textColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _criar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final categoriaExistente = widget.categoriaParaEditar;
    final grupoIds = _gruposSelecionados.toList();

    final categoria = categoriaExistente != null
        ? categoriaExistente.copyWith(
            nome: nome,
            preco: _precoController.text.trim(),
            tipo: _tipo,
            grupoIds: grupoIds,
          )
        : CategoriaLoja.nova(
            nome: nome,
            preco: _precoController.text.trim(),
            tipo: _tipo,
            grupoIds: grupoIds,
          );

    widget.onCriar(categoria);
    Navigator.of(context).pop();
  }

  String get _resumoGrupos {
    if (_gruposSelecionados.isEmpty) return '';
    return widget.gruposComponentes
        .where((g) => _gruposSelecionados.contains(g.id))
        .map((g) => g.nome)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final editando = widget.categoriaParaEditar != null;

    final larguraTela = MediaQuery.sizeOf(context).width;
    final larguraPopup = larguraTela < 380 ? larguraTela * 0.9 : 340.0;

    final resumoGrupos = _resumoGrupos;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: theme.borderColor, width: 1.5),
      ),
      title: Text(
        editando ? 'Editar Categoria' : 'Nova Categoria',
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
                label: 'Nome da nova categoria',
              ),
              const SizedBox(height: 12),

              ThemedTextField(
                theme: theme,
                controller: _precoController,
                label: 'Preço base (ex: 5,00)',
                tipoDeTeclado: TextInputType.number,
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _abrirSeletorDeGrupos,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          resumoGrupos.isEmpty
                              ? 'Grupos de componentes'
                              : resumoGrupos,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 14,
                            color: resumoGrupos.isEmpty
                                ? theme.secondaryTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down,
                          color: theme.secondaryTextColor),
                    ],
                  ),
                ),
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
        Radio<TipoItemLoja>(value: valor, activeColor: theme.borderColor),
      ],
    );
  }
}