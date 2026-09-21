import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _AdicionarEmailConteudo(theme: theme),
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
  final _emailController = TextEditingController();
  String? _aviso;
  bool _salvando = false;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() {
      _salvando = true;
      _aviso = null;
    });

    final erro = await context
        .read<AuthProvider>()
        .adicionarEmail(_emailController.text);

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

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Adicionar Email',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Simulação do login com Google. Na próxima etapa, isso será '
            'substituído pela autenticação real.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 13),
            decoration: _decoracaoCampo('seuemail@gmail.com'),
          ),
          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_aviso!, style: theme.getTextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    Text('Cancelar', style: theme.getTextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
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
                onPressed: _salvando ? null : _confirmar,
                child: _salvando
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
                          fontSize: 12,
                          color: theme.buttonTextColor,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}