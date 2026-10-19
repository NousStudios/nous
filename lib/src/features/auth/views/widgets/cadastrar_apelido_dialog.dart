import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

class CadastrarApelidoDialog extends StatefulWidget {
  final String cpf;
  final AppTheme theme;

  const CadastrarApelidoDialog({
    super.key,
    required this.cpf,
    required this.theme,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required String cpf,
    required AppTheme theme,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CadastrarApelidoDialog(cpf: cpf, theme: theme),
    );
  }

  @override
  State<CadastrarApelidoDialog> createState() => _CadastrarApelidoDialogState();
}

class _CadastrarApelidoDialogState extends State<CadastrarApelidoDialog> {
  late final TextEditingController _apelidoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _apelidoController = TextEditingController();
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final apelido = _apelidoController.text.trim();
    if (apelido.isEmpty) return;
    Navigator.of(context).pop(apelido);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cpfFormatado = CpfValidator.applyMask(widget.cpf);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      size: 26,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Identificação do Usuário',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Este CPF não possui registro na rede local. Digite seu apelido para se identificar na loja:',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'CPF: $cpfFormatado',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ThemedTextField(
                  theme: theme,
                  controller: _apelidoController,
                  label: 'Apelido',
                  obrigatorio: true,
                  onSubmitted: (_) => _confirmar(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: theme.borderColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _confirmar,
                      child: Text(
                        'Confirmar',
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
