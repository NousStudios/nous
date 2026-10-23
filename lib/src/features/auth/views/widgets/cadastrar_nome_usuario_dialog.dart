import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

/// Formata o texto inserido para letras minúsculas e remove quaisquer espaços em branco.
class MinuscSemEspacosFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final textoFormatado =
        newValue.text.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

/// Diálogo obrigatório para que todo cidadão Nous registre seu nome de usuário soberano (@username).
class CadastrarNomeUsuarioDialog extends StatefulWidget {
  final String cpf;
  final String? nomeOuApelidoAtual;
  final AppTheme theme;

  const CadastrarNomeUsuarioDialog({
    super.key,
    required this.cpf,
    this.nomeOuApelidoAtual,
    required this.theme,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required String cpf,
    String? nomeOuApelidoAtual,
    required AppTheme theme,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CadastrarNomeUsuarioDialog(
        cpf: cpf,
        nomeOuApelidoAtual: nomeOuApelidoAtual,
        theme: theme,
      ),
    );
  }

  @override
  State<CadastrarNomeUsuarioDialog> createState() =>
      _CadastrarNomeUsuarioDialogState();
}

class _CadastrarNomeUsuarioDialogState
    extends State<CadastrarNomeUsuarioDialog> {
  late final TextEditingController _controller;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Sugestão inicial baseada no nome/apelido existente
    String sugestao = '';
    if (widget.nomeOuApelidoAtual != null &&
        widget.nomeOuApelidoAtual!.trim().isNotEmpty) {
      sugestao = widget.nomeOuApelidoAtual!
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '.')
          .replaceAll(RegExp(r'[^a-z0-9._]'), '');
    }
    _controller = TextEditingController(text: sugestao);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _controller.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');

    if (texto.isEmpty) {
      setState(() => _erro = 'Informe um nome de usuário.');
      return;
    }

    if (texto.length < 3) {
      setState(() => _erro = 'O nome de usuário deve ter no mínimo 3 caracteres.');
      return;
    }

    // Apenas letras minúsculas, números, ponto e sublinhado
    final regex = RegExp(r'^[a-z0-9._]+$');
    if (!regex.hasMatch(texto)) {
      setState(() => _erro =
          'Use apenas letras minúsculas, números, ponto (.) ou sublinhado (_).');
      return;
    }

    Navigator.of(context).pop(texto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cpfFormatado = CpfValidator.applyMask(widget.cpf);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: theme.cardBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.alternate_email_rounded,
                      size: 28,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nome de Usuário Nous',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cadastre sua identificação única na rede Nous. O nome de usuário deve ser todo junto e em letras minúsculas:',
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
                  controller: _controller,
                  label: 'Nome de usuário (@usuario)',
                  obrigatorio: true,
                  formatadores: [MinuscSemEspacosFormatter()],
                  onChanged: (_) {
                    if (_erro != null) setState(() => _erro = null);
                  },
                  onSubmitted: (_) => _confirmar(),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                      vertical: 14,
                    ),
                  ),
                  onPressed: _confirmar,
                  child: Text(
                    'Salvar Nome de Usuário',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
