import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/google_oauth_service.dart';

class AdicionarEmailDialog {
  static Future<bool?> mostrar(
    BuildContext context, {
    required AppTheme theme,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.90,
            ),
            child: SingleChildScrollView(
              child: _AdicionarEmailConteudo(theme: theme),
            ),
          ),
        );
      },
    );
  }
}

class _AdicionarEmailConteudo extends StatefulWidget {
  final AppTheme theme;

  const _AdicionarEmailConteudo({required this.theme});

  @override
  State<_AdicionarEmailConteudo> createState() =>
      _AdicionarEmailConteudoState();
}

class _AdicionarEmailConteudoState extends State<_AdicionarEmailConteudo> {
  String? _aviso;
  bool _salvando = false;

  AppTheme get theme => widget.theme;

  Future<void> _autenticarComGoogle() async {
    setState(() {
      _salvando = true;
      _aviso = null;
    });

    final resultado = await GoogleOAuthService.autenticarComGoogle();

    if (!mounted) return;

    if (!resultado.sucesso || (resultado.email?.isEmpty ?? true)) {
      setState(() {
        _salvando = false;
        _aviso = resultado.erro ?? 'Falha ao autenticar com o Google.';
      });
      return;
    }

    final erro = await context.read<AuthProvider>().adicionarEmail(
          resultado.email!,
          verificadoGoogle: true,
        );

    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _salvando = false;
        _aviso = erro;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vincular E-mail Google',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Para segurança da rede, todos os e-mails precisam ser autenticados pela sua conta Google.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.login_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _salvando ? null : _autenticarComGoogle,
              label: _salvando
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.buttonTextColor,
                      ),
                    )
                  : Text(
                      'Continuar com Google',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.buttonTextColor,
                      ),
                    ),
            ),
          ),
          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _aviso!,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.dangerColor,
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: theme.getTextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}