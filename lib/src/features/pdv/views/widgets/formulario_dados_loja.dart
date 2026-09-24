import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';
import 'package:nous/src/features/pdv/services/telefone_input_formatter.dart';

class ControllersDadosLoja {
  final nome = TextEditingController();
  final cnpj = TextEditingController();
  final telefone = TextEditingController();
  final endereco = TextEditingController();
  final numero = TextEditingController();
  final email = TextEditingController();
  final categorias = TextEditingController();
  final tags = TextEditingController();

  void dispose() {
    nome.dispose();
    cnpj.dispose();
    telefone.dispose();
    endereco.dispose();
    numero.dispose();
    email.dispose();
    categorias.dispose();
    tags.dispose();
  }
}

class FormularioDadosLoja extends StatelessWidget {
  final AppTheme theme;
  final ControllersDadosLoja controllers;

  const FormularioDadosLoja({
    super.key,
    required this.theme,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: theme.cardBackgroundColor,
            child: Icon(
              Icons.person,
              size: 44,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 20),

        ThemedTextField(
          theme: theme,
          controller: controllers.nome,
          label: 'Nome da Loja',
          obrigatorio: true,
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ThemedTextField(
                theme: theme,
                controller: controllers.cnpj,
                label: 'CNPJ',
                tipoDeTeclado: TextInputType.number,
                formatadores: [CnpjInputFormatter()],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ThemedTextField(
                theme: theme,
                controller: controllers.telefone,
                label: 'Telefone',
                tipoDeTeclado: TextInputType.phone,
                formatadores: [TelefoneInputFormatter()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ThemedTextField(
                theme: theme,
                controller: controllers.endereco,
                label: 'Endereço',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ThemedTextField(
                theme: theme,
                controller: controllers.numero,
                label: 'Nº',
                tipoDeTeclado: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ThemedTextField(
          theme: theme,
          controller: controllers.email,
          label: 'Email',
          tipoDeTeclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        ThemedTextField(
          theme: theme,
          controller: controllers.categorias,
          label: 'Categorias',
        ),
        const SizedBox(height: 12),

        ThemedTextField(
          theme: theme,
          controller: controllers.tags,
          label: 'Descrição',
          linhas: 4,
        ),
      ],
    );
  }
}