import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

/// Bloco que exibe os e-mails associados ao CPF do usuário.
class BlocoEmailsUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final String? emailAtivo;
  final bool ocultarDados;
  final BoxDecoration decoracao;

  const BlocoEmailsUsuario({
    super.key,
    required this.theme,
    required this.usuario,
    required this.emailAtivo,
    required this.ocultarDados,
    required this.decoracao,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'E-mails Associados ao CPF',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          if (usuario.emails.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Nenhum e-mail cadastrado.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          else
            for (final email in usuario.emails)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 3,
                ),
                child: Row(
                  children: [
                    Icon(
                      emailAtivo == email
                          ? Icons.check_circle_outline
                          : Icons.mail_outline,
                      size: 16,
                      color: emailAtivo == email
                          ? theme.buttonColor
                          : theme.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: emailAtivo == email
                              ? theme.textColor
                              : theme.secondaryTextColor,
                          fontWeight: emailAtivo == email
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (emailAtivo == email)
                      Text(
                        'Ativo',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.buttonColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );

    if (!ocultarDados) return conteudo;

    return IgnorePointer(
      ignoring: true,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
        child: conteudo,
      ),
    );
  }
}
