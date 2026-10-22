import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/backup_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

/// Tela dedicada para gerenciamento da Conta Nous Soberana do Cidadão.
/// Reúne Identidade, E-mails associados, Backup dos dados e Exclusão de Conta.
class ContaNousView extends StatelessWidget {
  const ContaNousView({super.key});

  Future<void> _abrirAdicionarEmail(BuildContext context) async {
    await AdicionarEmailDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
    );
  }

  Future<void> _removerEmail(BuildContext context, String email) async {
    final theme = ThemeController.currentTheme.value;

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
            'Excluir E-mail',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja remover o e-mail "$email" desta conta?',
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
                'Excluir',
                style: theme.getTextStyle(color: theme.dangerColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      await context.read<AuthProvider>().removerEmail(email);
    }
  }

  Future<void> _excluirConta(BuildContext context) async {
    final theme = ThemeController.currentTheme.value;

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
            'Excluir Conta Nous',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.dangerColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir esta Conta Nous? Isso também '
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
      await context.read<AuthProvider>().excluirConta();

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
    final auth = context.watch<AuthProvider>();
    final conta = auth.contaAtual;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final fotoResolvida =
            conta != null ? ImagemService.resolverCaminhoExistente(conta.foto) : null;
        final temFoto = fotoResolvida != null;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Conta Nous',
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloco 1: Identidade do Usuário
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
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.borderColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: temFoto
                                        ? Image.file(
                                            File(fotoResolvida),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Icon(
                                              Icons.person,
                                              size: 32,
                                              color: theme.textColor,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 32,
                                            color: theme.textColor,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conta?.nome.isNotEmpty == true
                                            ? conta!.nome
                                            : 'Usuário Nous',
                                        style: theme.getTextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      if (conta?.apelido.isNotEmpty == true) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${conta!.apelido}',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            color: theme.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatarCpf(conta?.cpf ?? auth.cpf),
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
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
                                  if (conta != null) {
                                    FichaUsuarioDialog.mostrar(
                                      context,
                                      theme: theme,
                                      usuario: conta,
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.badge_outlined,
                                  size: 16,
                                  color: theme.textColor,
                                ),
                                label: Text(
                                  'Ver / Editar Identidade Completa',
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

                      // Bloco 2: E-mails Associados
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alternate_email_rounded,
                                      size: 18,
                                      color: theme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'E-mails Associados',
                                      style: theme.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _abrirAdicionarEmail(context),
                                  icon: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: theme.textColor,
                                  ),
                                  label: Text(
                                    'Adicionar',
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (conta == null || conta.emails.isEmpty)
                              EstadoVazioContainer(
                                theme: theme,
                                mensagem: 'Nenhum e-mail associado a esta conta.',
                              )
                            else
                              Column(
                                children: conta.emails.map((email) {
                                  final ehAtivo = auth.emailAtivo == email;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ehAtivo
                                          ? theme.borderColor.withValues(alpha: 0.2)
                                          : theme.backgroundColor.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: ehAtivo
                                            ? theme.textColor
                                            : theme.borderColor.withValues(alpha: 0.5),
                                        width: ehAtivo ? 1.3 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ehAtivo
                                              ? Icons.check_circle_rounded
                                              : Icons.mail_outline_rounded,
                                          size: 16,
                                          color: ehAtivo
                                              ? theme.textColor
                                              : theme.secondaryTextColor,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                email,
                                                style: theme.getTextStyle(
                                                  fontSize: 13,
                                                  fontWeight: ehAtivo
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              if (ehAtivo)
                                                Text(
                                                  'E-mail ativo da sessão',
                                                  style: theme.getTextStyle(
                                                    fontSize: 10,
                                                    color: theme.secondaryTextColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (!ehAtivo)
                                          TextButton(
                                            onPressed: () => auth.definirEmailAtivo(email),
                                            child: Text(
                                              'Usar',
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: theme.dangerColor,
                                          ),
                                          onPressed: () => _removerEmail(context, email),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco 3: Backup Soberano dos Dados
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

                      // Bloco 4: Zona de Perigo (Excluir Conta Nous)
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
