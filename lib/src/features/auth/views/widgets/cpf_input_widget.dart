import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

class CpfInputWidget extends StatefulWidget {
  final TextEditingController? controller;

  const CpfInputWidget({super.key, this.controller});

  @override
  State<CpfInputWidget> createState() => _CpfInputWidgetState();
}

class _CpfInputWidgetState extends State<CpfInputWidget> {
  late final TextEditingController _internalController;
  bool _createdInternalController = false;

  // FocusNode: um objeto que "sabe" se este campo específico está com o
  // foco (ou seja, se é nele que o teclado está escrevendo agora) ou não.
  late final FocusNode _focusNode;
  bool _isFocused = false;

  TextEditingController get _controller {
    return widget.controller ?? _internalController;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
      _createdInternalController = true;
    }

    _focusNode = FocusNode();
    // addListener registra uma função que vai ser chamada toda vez que o
    // estado de foco mudar (ganhou foco ou perdeu foco). setState() avisa
    // o Flutter para redesenhar o widget com o novo valor de _isFocused.
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (_createdInternalController) {
      _internalController.dispose();
    }
    // FocusNode também precisa ser "destruído" quando o widget sai de tela,
    // assim como o TextEditingController.
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String maskedText) {
    // A máscara já foi aplicada pelo CpfInputFormatter antes de chegarmos
    // aqui — então só precisamos avisar o AuthProvider do valor atual.
    context.read<AuthProvider>().updateCpf(maskedText);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _handleChanged,
          // inputFormatters: lista de "filtros" aplicados ao texto sempre
          // que ele muda. O CpfInputFormatter cuida de aplicar a máscara
          // (123.456.789-09) e corrigir o comportamento do backspace.
          inputFormatters: [CpfInputFormatter()],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 14,
          style: theme.getTextStyle(fontSize: 16),
          decoration: InputDecoration(
            // Se o campo está focado, a dica não aparece — nem vazia, nem
            // com texto — mesmo antes de o usuário digitar qualquer coisa.
            // Se perder o foco e o campo continuar vazio, a dica volta.
            hintText: _isFocused ? null : 'Digite seu CPF',
            hintStyle: theme.getTextStyle(
              fontSize: 16,
              color: theme.secondaryTextColor,
            ),
            counterText: '',
            errorText: authProvider.errorMessage,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.textColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}