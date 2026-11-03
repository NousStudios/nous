import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

/// Controlador que permite ofuscar visualmente os dígitos finais do CPF
/// preservando os 3 primeiros números e os separadores da máscara.
class CpfTextEditingController extends TextEditingController {
  bool oculto;

  CpfTextEditingController({
    super.text,
    this.oculto = true,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!oculto) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final rawText = value.text;
    final buffer = StringBuffer();
    int digitCount = 0;

    for (int i = 0; i < rawText.length; i++) {
      final char = rawText[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        digitCount++;
        if (digitCount <= 3) {
          buffer.write(char);
        } else {
          buffer.write('•');
        }
      } else {
        buffer.write(char);
      }
    }

    return TextSpan(
      style: style,
      text: buffer.toString(),
    );
  }
}

class CpfInputWidget extends StatefulWidget {
  final TextEditingController? controller;

  const CpfInputWidget({super.key, this.controller});

  @override
  State<CpfInputWidget> createState() => _CpfInputWidgetState();
}

class _CpfInputWidgetState extends State<CpfInputWidget> {
  late final TextEditingController _internalController;
  bool _createdInternalController = false;

  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _oculto = true;
  bool _temTexto = false;

  TextEditingController get _controller {
    return widget.controller ?? _internalController;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = CpfTextEditingController(oculto: _oculto);
      _createdInternalController = true;
    }

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    _controller.addListener(_aoMudarTexto);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.cpf.isEmpty) {
        final ultimo = await auth.obterUltimoCpf();
        if (ultimo != null && ultimo.isNotEmpty && mounted) {
          final formatado = CpfValidator.applyMask(ultimo);
          _controller.text = formatado;
          auth.updateCpf(formatado);
        }
      } else if (_controller.text.isEmpty) {
        _controller.text = CpfValidator.applyMask(auth.cpf);
      }
      if (mounted) {
        setState(() {
          _temTexto = _controller.text.trim().isNotEmpty;
        });
      }
    });
  }

  void _aoMudarTexto() {
    final temTextoAgora = _controller.text.trim().isNotEmpty;
    if (temTextoAgora != _temTexto) {
      setState(() {
        _temTexto = temTextoAgora;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_aoMudarTexto);
    if (_createdInternalController) {
      _internalController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String maskedText) {
    context.read<AuthProvider>().updateCpf(maskedText);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final temTexto = _controller.text.trim().isNotEmpty;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _handleChanged,
          inputFormatters: [CpfInputFormatter()],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 14,
          style: theme.getTextStyle(fontSize: 16),
          decoration: InputDecoration(
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
            prefixIcon: temTexto
                ? const SizedBox(
                    width: 48,
                    height: 48,
                  )
                : null,
            suffixIcon: temTexto
                ? IconButton(
                    icon: Icon(
                      _oculto
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: theme.secondaryTextColor,
                    ),
                    tooltip: _oculto ? 'Mostrar CPF' : 'Ocultar CPF',
                    onPressed: () {
                      setState(() {
                        _oculto = !_oculto;
                        if (_controller is CpfTextEditingController) {
                          (_controller as CpfTextEditingController).oculto =
                              _oculto;
                        }
                      });
                    },
                  )
                : null,
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
              borderSide: BorderSide(color: theme.dangerColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.dangerColor, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}