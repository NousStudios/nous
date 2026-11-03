import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

class VarianteFormControllers {
  final TextEditingController nomeController;
  final TextEditingController precoController;

  VarianteFormControllers({String nome = '', String preco = ''})
      : nomeController = TextEditingController(text: nome),
        precoController = TextEditingController(text: preco);

  void dispose() {
    nomeController.dispose();
    precoController.dispose();
  }
}

class VariantesItemWidget extends StatelessWidget {
  final AppTheme theme;
  final List<VarianteFormControllers> variantesControllers;
  final VoidCallback onAdicionarVariante;
  final ValueChanged<int> onRemoverVariante;

  const VariantesItemWidget({
    super.key,
    required this.theme,
    required this.variantesControllers,
    required this.onAdicionarVariante,
    required this.onRemoverVariante,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < variantesControllers.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ThemedTextField(
                    theme: theme,
                    controller: variantesControllers[i].nomeController,
                    label: 'Variante ${i + 1} (ex: G, 500ml)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ThemedTextField(
                    theme: theme,
                    controller: variantesControllers[i].precoController,
                    label: 'Preço (R\$)',
                    tipoDeTeclado: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'Remover variante',
                  onPressed: () => onRemoverVariante(i),
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textColor,
            side: BorderSide(color: theme.borderColor),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onAdicionarVariante,
          icon: Icon(Icons.add, color: theme.textColor, size: 18),
          label: Text(
            'Adicionar variante',
            style: theme.getTextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
