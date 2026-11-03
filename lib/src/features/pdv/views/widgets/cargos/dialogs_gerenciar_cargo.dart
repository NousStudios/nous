import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';

/// Diálogos modais para criação, renomeação e exclusão de cargos personalizados.
class DialogsGerenciarCargo {
  static void abrirDialogNovoCargo({
    required BuildContext context,
    required AppTheme theme,
    required ValueChanged<CargoLoja>? onAdicionarCargo,
    required ValueChanged<String> onCargoCriado,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Novo Cargo',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dê um nome para o novo cargo (ex: Gerente, Garçom, Cozinheiro, Entregador):',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: theme.getTextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nome do cargo...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final nome = controller.text.trim();
                if (nome.isEmpty) return;
                final novoCargo = CargoLoja(
                  id: 'cargo_${DateTime.now().millisecondsSinceEpoch}',
                  nome: nome,
                  permissoes: {
                    PermissaoLojaConst.usarFinanceiro: true,
                  },
                );
                onAdicionarCargo?.call(novoCargo);
                onCargoCriado(novoCargo.id);
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Criar Cargo',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void abrirDialogRenomearCargo({
    required BuildContext context,
    required AppTheme theme,
    required CargoLoja cargo,
    required ValueChanged<CargoLoja>? onAtualizarCargo,
  }) {
    final controller = TextEditingController(text: cargo.nome);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Renomear Cargo',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: theme.getTextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Novo nome...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
              ),
              onPressed: () {
                final nome = controller.text.trim();
                if (nome.isEmpty) return;
                onAtualizarCargo?.call(cargo.copyWith(nome: nome));
                Navigator.pop(dialogContext);
              },
              child: Text('Salvar', style: theme.getTextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  static void confirmarExcluirCargo({
    required BuildContext context,
    required AppTheme theme,
    required CargoLoja cargo,
    required ValueChanged<String>? onRemoverCargo,
    required VoidCallback onCargoExcluido,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Cargo',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Deseja excluir o cargo "${cargo.nome}"? Os membros que possuem esse cargo voltarão ao papel nativo padrão.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onRemoverCargo?.call(cargo.id);
                onCargoExcluido();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: theme.dangerColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
