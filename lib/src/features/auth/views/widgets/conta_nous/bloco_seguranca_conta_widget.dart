import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/dialogs/dialog_chaves_criptograficas.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/backup_dialog.dart';

/// Bloco de Backup Soberano dos Dados e Zona de Perigo (Exclusão definitiva de Conta).
class BlocoSegurancaContaWidget extends StatelessWidget {
  final AppTheme theme;

  const BlocoSegurancaContaWidget({
    super.key,
    required this.theme,
  });

  Future<void> _excluirConta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Conta Nous Definitivamente',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.dangerColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir esta Conta Nous definitivamente? Isso também '
            'apaga todas as lojas criadas por este CPF neste dispositivo. '
            'Esta ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir Definitivamente',
                style: theme.getTextStyle(
                  color: theme.dangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      final cpf = context.read<AuthProvider>().cpf;
      await context.read<PdvProvider>().excluirDadosDoCpf(cpf);

      if (!context.mounted) return;
      await context.read<AuthProvider>().excluirConta(cpf);

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bloco Backup Soberano
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 18,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Backup dos Dados',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gere cópias de segurança de todas as suas lojas, caixas, históricos e cadastros vinculados a este CPF em um único arquivo soberano.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    BackupDialog.mostrar(context, theme: theme);
                  },
                  icon: Icon(
                    Icons.save_alt_rounded,
                    size: 16,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Gerenciar Backup / Restaurar Dados',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bloco Cofre Criptográfico Soberano
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cofre Criptográfico & Chaves E2EE',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Suas chaves soberanas Ed25519 (assinatura de atestados e mensagens) e X25519 (criptografia de ponta a ponta) residem neste aparelho. Exporte ou restaure suas chaves com senha mestre.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final cpf = context.read<AuthProvider>().cpf;
                    DialogChavesCriptograficas.mostrar(
                      context,
                      theme: theme,
                      cpf: cpf,
                    );
                  },
                  icon: Icon(
                    Icons.lock_reset_rounded,
                    size: 16,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Exportar ou Restaurar Chaves Criptográficas',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bloco Zona de Perigo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.dangerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dangerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.dangerColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Excluir Conta Nous',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.dangerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Apaga permanentemente os dados cadastrais deste CPF e de suas lojas locais deste computador. Esta ação não poderá ser desfeita.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.dangerColor,
                    side: BorderSide(color: theme.dangerColor),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _excluirConta(context),
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    size: 16,
                    color: theme.dangerColor,
                  ),
                  label: Text(
                    'Excluir Conta Nous Definitivamente',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.dangerColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
