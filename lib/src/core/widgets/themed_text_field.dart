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

  // NOVO: quando true, o campo usa uma linha simples embaixo do texto
  // (sem caixa/borda ao redor), no lugar da caixa com borda arredondada
  // de sempre. É o estilo usado, por exemplo, em "Nome do Titular da
  // Conta" e em "Agência/Conta/Dígito" no formulário de Dados Bancários.
  // false continua sendo o padrão, para não mudar nenhum campo já
  // existente no app.
  final bool sublinhado;

  const ThemedTextField({
    super.key,
    required this.theme,
    required this.controller,
    required this.label,
    this.obrigatorio = false,
    this.linhas = 1,
    this.tipoDeTeclado,
    this.formatadores,
    this.sublinhado = false,
  });

  @override
  Widget build(BuildContext context) {
    // Escolhe qual decoração usar, dependendo do parâmetro "sublinhado".
    // Feito assim (uma variável antes do TextFormField) para não deixar o
    // "return" lá embaixo poluído com um "if" gigante dentro dele.
    final InputDecoration decoracao = sublinhado
        ? InputDecoration(
            labelText: label,
            labelStyle: theme.getTextStyle(fontSize: 13),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.borderColor),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.textColor),
            ),
          )
        : InputDecoration(
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
          );

    return TextFormField(
      controller: controller,
      maxLines: linhas,
      keyboardType: tipoDeTeclado,
      inputFormatters: formatadores,
      style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
      decoration: decoracao,
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