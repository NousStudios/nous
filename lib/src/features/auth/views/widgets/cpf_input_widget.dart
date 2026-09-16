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
  // Se quem chamou este widget não mandou um controller de fora, criamos um
  // por conta própria aqui dentro. Isso mantém o widget funcionando do mesmo
  // jeito que antes, mesmo sem essa opção sendo usada em nenhum lugar ainda.
  late final TextEditingController _internalController;
  bool _createdInternalController = false;

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
  }

  @override
  void dispose() {
    // Só "destruímos" o controller se fomos nós que o criamos. Se ele veio
    // de fora (da tela de login, por exemplo), quem criou é responsável por
    // destruí-lo — destruir aqui de novo causaria um erro.
    if (_createdInternalController) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _handleChanged(String rawInput) {
    // Aplica a máscara visual (123.456.789-09) no texto do campo.
    final masked = CpfValidator.applyMask(rawInput);

    // Atualiza o campo de texto com a versão mascarada, e reposiciona o
    // cursor no final. Sem isso, o cursor "pularia" para o começo do campo
    // toda vez que uma máscara fosse aplicada — uma armadilha clássica do
    // Flutter que trava muita gente iniciante.
    _controller.value = TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );

    // context.read (e não context.watch) porque estamos dentro de uma
    // função de callback (onChanged), não dentro do build(). Aqui só
    // queremos CHAMAR um método do AuthProvider, não "escutar" mudanças
    // nele.
    context.read<AuthProvider>().updateCpf(rawInput);
  }

  @override
  Widget build(BuildContext context) {
    // context.watch aqui, dentro do build(), para que este widget seja
    // redesenhado automaticamente sempre que a mensagem de erro mudar.
    final authProvider = context.watch<AuthProvider>();

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return TextField(
          controller: _controller,
          onChanged: _handleChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          // Limita a digitação a 14 caracteres, que é o tamanho exato de
          // "123.456.789-09" já com a máscara incluída.
          maxLength: 14,
          style: theme.getTextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Digite seu CPF',
            hintStyle: theme.getTextStyle(
              fontSize: 16,
              color: theme.secondaryTextColor,
            ),
            // Some com o contadorzinho "0/14" que o Flutter mostra por
            // padrão quando existe um maxLength.
            counterText: '',
            // Mostra a mensagem de erro guardada no AuthProvider embaixo do
            // campo, se houver alguma.
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
            // Bordas específicas para quando há erro — sem definir isso, o
            // Flutter usa um vermelho padrão que pode destoar do tema.
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