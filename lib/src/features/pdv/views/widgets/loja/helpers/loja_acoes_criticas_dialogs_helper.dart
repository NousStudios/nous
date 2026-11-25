import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

/// Helper coeso para diálogos de ações críticas (exclusão de loja e reset de transações).
class LojaAcoesCriticasDialogsHelper {
  const LojaAcoesCriticasDialogsHelper._();

  static void confirmarExclusao({
    required BuildContext context,
    required String lojaId,
    required void Function() avisarSemPermissao,
  }) {
    if (!context.read<PdvProvider>().possoExcluirLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (dialogContext, theme, child) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Excluir Loja',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: Text(
                'Tem certeza que deseja excluir esta loja? Essa ação não '
                'pode ser desfeita.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(fontSize: 14),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _executarExclusao(dialogContext, lojaId),
                  child: Text(
                    'Excluir',
                    style: theme.getTextStyle(color: theme.dangerColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _executarExclusao(
    BuildContext dialogContext,
    String lojaId,
  ) async {
    final navigator = Navigator.of(dialogContext);

    await dialogContext.read<PdvProvider>().excluirLoja(lojaId);
    if (!dialogContext.mounted) return;

    navigator.pop();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  static Future<void> confirmarResetTransacoes({
    required BuildContext context,
    required AppTheme theme,
    required String lojaId,
    required VoidCallback onResetConcluido,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.dangerColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resetar Transações',
                  style: theme.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Esta ação apagará permanentemente todos os registros de vendas, turnos de caixa e pagamentos a trabalhadores desta loja.\n\n'
              'Produtos, categorias, clientes, fornecedores e membros da equipe NÃO serão afetados.\n\n'
              'Tem certeza que deseja continuar?',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.textColor,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.dangerColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Resetar Transações'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;
    if (!context.mounted) return;

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final pdv = context.read<PdvProvider>();

    await pdv.resetarTransacoesLoja(
      lojaId,
      autorCpf: conta?.cpf ?? '',
      autorNome: conta?.nome ?? '',
      autorEmail: auth.emailAtivo ?? '',
    );

    if (!context.mounted) return;
    onResetConcluido();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Registros de transações resetados com sucesso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}
