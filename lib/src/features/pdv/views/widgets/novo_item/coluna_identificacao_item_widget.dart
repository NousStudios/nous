import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/botoes_hover_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/fotos_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/variantes_item_widget.dart';

/// Coluna de identificação visual, nome, categorias, grupos e variantes do item.
class ColunaIdentificacaoItemWidget extends StatefulWidget {
  final AppTheme theme;
  final List<String> imagens;
  final VoidCallback onImagensAlteradas;
  final TextEditingController nomeController;
  final TextEditingController descricaoController;
  final TipoItemLoja? tipo;
  final ValueChanged<TipoItemLoja> onTipoAlterado;
  final TextEditingController precoController;
  final String nomesCategoriasSelecionadas;
  final VoidCallback onAbrirSeletorCategorias;
  final String nomesGruposSelecionados;
  final VoidCallback onAbrirSeletorGrupos;
  final List<VarianteFormControllers> variantesControllers;
  final VoidCallback onAdicionarVariante;
  final void Function(int) onRemoverVariante;

  const ColunaIdentificacaoItemWidget({
    super.key,
    required this.theme,
    required this.imagens,
    required this.onImagensAlteradas,
    required this.nomeController,
    required this.descricaoController,
    required this.tipo,
    required this.onTipoAlterado,
    required this.precoController,
    required this.nomesCategoriasSelecionadas,
    required this.onAbrirSeletorCategorias,
    required this.nomesGruposSelecionados,
    required this.onAbrirSeletorGrupos,
    required this.variantesControllers,
    required this.onAdicionarVariante,
    required this.onRemoverVariante,
  });

  @override
  State<ColunaIdentificacaoItemWidget> createState() =>
      _ColunaIdentificacaoItemWidgetState();
}

class _ColunaIdentificacaoItemWidgetState
    extends State<ColunaIdentificacaoItemWidget> {
  bool _descricaoExpandida = false;

  @override
  void initState() {
    super.initState();
    if (widget.descricaoController.text.trim().isNotEmpty) {
      _descricaoExpandida = true;
    }
  }

  Widget _campoSelecao({
    required String label,
    required String? valorExibido,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextoRolante(
                texto: (valorExibido == null || valorExibido.isEmpty)
                    ? label
                    : valorExibido,
                textAlign: TextAlign.start,
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: (valorExibido == null || valorExibido.isEmpty)
                      ? theme.secondaryTextColor
                      : theme.textColor,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: theme.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBlocoDescricao(AppTheme theme) {
    final temDescricao = widget.descricaoController.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _descricaoExpandida = !_descricaoExpandida),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextoRolante(
                      texto: temDescricao
                          ? (_descricaoExpandida
                              ? 'Descrição do item'
                              : 'Descrição: ${widget.descricaoController.text.trim().split('\n').first}')
                          : 'Descrição do item (opcional)',
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: temDescricao ? theme.textColor : theme.secondaryTextColor,
                        fontWeight: temDescricao ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    _descricaoExpandida
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.secondaryTextColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_descricaoExpandida) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ThemedTextField(
                theme: theme,
                controller: widget.descricaoController,
                label: 'Escreva a descrição do item',
                linhas: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeletorTipo(AppTheme theme) {
    final tipoAtual = widget.tipo ?? TipoItemLoja.produto;
    return Row(
      children: [
        Expanded(
          child: BotaoHoverTipoItem(
            theme: theme,
            rotulo: 'Produto',
            icone: Icons.inventory_2_outlined,
            selecionado: tipoAtual == TipoItemLoja.produto,
            aoClicar: () => widget.onTipoAlterado(TipoItemLoja.produto),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BotaoHoverTipoItem(
            theme: theme,
            rotulo: 'Serviço',
            icone: Icons.handyman_outlined,
            selecionado: tipoAtual == TipoItemLoja.servico,
            aoClicar: () => widget.onTipoAlterado(TipoItemLoja.servico),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FotosItemWidget(
          theme: theme,
          imagens: widget.imagens,
          onImagensAlteradas: widget.onImagensAlteradas,
        ),
        const SizedBox(height: 16),
        ThemedTextField(
          theme: theme,
          controller: widget.nomeController,
          label: 'Nome do novo item',
        ),
        const SizedBox(height: 14),
        _buildBlocoDescricao(theme),
        const SizedBox(height: 14),
        _buildSeletorTipo(theme),
        const SizedBox(height: 14),
        ThemedTextField(
          theme: theme,
          controller: widget.precoController,
          label: 'Preço de venda (ex: 12,50)',
          tipoDeTeclado: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _campoSelecao(
          label: 'Categorias do item',
          valorExibido: widget.nomesCategoriasSelecionadas,
          onTap: widget.onAbrirSeletorCategorias,
        ),
        const SizedBox(height: 12),
        _campoSelecao(
          label: 'Grupos de componentes',
          valorExibido: widget.nomesGruposSelecionados,
          onTap: widget.onAbrirSeletorGrupos,
        ),
        const SizedBox(height: 14),
        VariantesItemWidget(
          theme: theme,
          variantesControllers: widget.variantesControllers,
          onAdicionarVariante: widget.onAdicionarVariante,
          onRemoverVariante: widget.onRemoverVariante,
        ),
      ],
    );
  }
}
