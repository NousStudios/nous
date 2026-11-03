import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Bloco de listagem, adição e exclusão de e-mails associados à Conta Nous.
class BlocoEmailsContaWidget extends StatelessWidget {
  final UsuarioNous? conta;
  final AppTheme theme;

  const BlocoEmailsContaWidget({
    super.key,
    required this.conta,
    required this.theme,
  });

  Future<void> _abrirAdicionarEmail(BuildContext context) async {
    await AdicionarEmailDialog.mostrar(
      context,
      theme: theme,
    );
  }

  Future<void> _removerEmail(BuildContext context, String email) async {
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
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
          if (conta == null || conta!.emails.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum e-mail associado a esta conta.',
            )
          else
            Column(
              children: conta!.emails.map((email) {
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
    );
  }
}
