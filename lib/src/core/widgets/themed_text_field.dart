import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Campo de texto com o visual padrão do app (fundo, borda e fonte
// seguindo o tema atual). Criado para não repetir esse mesmo estilo em
// cada formulário novo (Cadastrar Loja, Dados do Perfil, etc.) — se um
// dia quisermos mudar a aparência de todos os campos de uma vez, só
// precisamos mexer aqui.
class ThemedTextField extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final String label;
  final bool obrigatorio;
  final int linhas;
  final TextInputType? tipoDeTeclado;
  final List<TextInputFormatter>? formatadores;

  const ThemedTextField({
    super.key,
    required this.theme,
    required this.controller,
    required this.label,
    this.obrigatorio = false,
    this.linhas = 1,
    this.tipoDeTeclado,
    this.formatadores,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: linhas,
      keyboardType: tipoDeTeclado,
      inputFormatters: formatadores,
      style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.getTextStyle(fontSize: 13),
        filled: true,
        fillColor: theme.cardBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.textColor),
        ),
      ),
      // Só valida (exige preenchimento) quando o campo for marcado como
      // obrigatório. Caso contrário, nunca mostra erro.
      validator: obrigatorio
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            }
          : null,
    );
  }
}