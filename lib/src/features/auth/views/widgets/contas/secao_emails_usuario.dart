import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/views/widgets/contas/barra_email_usuario.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class SecaoEmailsUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous? conta;
  final bool autenticandoGoogle;
  final VoidCallback aoConectarGoogle;
  final VoidCallback aoAdicionarEmail;
  final ValueChanged<String> aoEntrarComEmail;
  final ValueChanged<String> aoExcluirEmail;

  const SecaoEmailsUsuario({
    super.key,
    required this.theme,
    required this.conta,
    required this.autenticandoGoogle,
    required this.aoConectarGoogle,
    required this.aoAdicionarEmail,
    required this.aoEntrarComEmail,
    required this.aoExcluirEmail,
  });

  @override
  Widget build(BuildContext context) {
    final c = conta;
    if (c == null || c.emails.isEmpty) {
      return Column(
        children: [
          EstadoVazioContainer(
            theme: theme,
            mensagem:
                'Nenhum e-mail associado ainda.\nÉ obrigatório vincular um e-mail para acessar a Conta Nous.',
          ),
          const SizedBox(height: 16),
          _BotaoConectarGoogle(
            theme: theme,
            autenticando: autenticandoGoogle,
            fontSize: 14,
            aoPressionar: aoConectarGoogle,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.mail_outline, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: autenticandoGoogle ? null : aoAdicionarEmail,
            label: Text(
              'Cadastrar e-mail manualmente',
              style: theme.getTextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Toque em um e-mail para iniciar sua sessão:',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            for (final email in c.emails)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BarraEmailUsuario(
                  theme: theme,
                  email: email,
                  verificadoGoogle: c.emailEstaVerificado(email),
                  aoClicar: () => aoEntrarComEmail(email),
                  aoExcluir: () => aoExcluirEmail(email),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _BotaoConectarGoogle(
          theme: theme,
          autenticando: autenticandoGoogle,
          fontSize: 13,
          aoPressionar: aoConectarGoogle,
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textColor,
            side: BorderSide(color: theme.borderColor),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: autenticandoGoogle ? null : aoAdicionarEmail,
          child: Text(
            'Adicionar outro e-mail',
            style: theme.getTextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _BotaoConectarGoogle extends StatelessWidget {
  final AppTheme theme;
  final bool autenticando;
  final double fontSize;
  final VoidCallback aoPressionar;

  const _BotaoConectarGoogle({
    required this.theme,
    required this.autenticando,
    required this.fontSize,
    required this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: autenticando
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.buttonTextColor,
              ),
            )
          : const Icon(Icons.login_rounded, size: 18),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.buttonColor,
        foregroundColor: theme.buttonTextColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: autenticando ? null : aoPressionar,
      label: Text(
        'Conectar com Google',
        style: theme.getTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: theme.buttonTextColor,
        ),
      ),
    );
  }
}
