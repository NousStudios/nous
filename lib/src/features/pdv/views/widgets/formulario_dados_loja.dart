import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';

// Agrupa todos os controllers usados pelo formulário da loja num único
// lugar. Assim, tanto a tela de Cadastrar Loja quanto a de Dados do
// Perfil podem criar um conjunto desses controllers, passar para este
// widget, e depois ler os valores digitados (ex: para navegar levando os
// dados adiante, ou futuramente para salvar de verdade).
class ControllersDadosLoja {
  final nome = TextEditingController();
  final cnpj = TextEditingController();
  final telefone = TextEditingController();
  final endereco = TextEditingController();
  final numero = TextEditingController();
  final email = TextEditingController();
  final categorias = TextEditingController();
  final tags = TextEditingController();

  // Libera a memória de todos os controllers de uma vez. Deve ser chamado
  // dentro do dispose() da tela que criou esse grupo de controllers.
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

// Conjunto visual completo de campos do formulário da loja: foto/logo,
// nome, CNPJ, telefone, endereço, número, email, categorias e tags.
// Não inclui o botão de ação (Cadastrar / Excluir Loja) nem o Form/
// SingleChildScrollView em volta — isso fica a cargo de cada tela que usa
// este widget, para manter esta peça só com os campos em si.
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
        // Foto/logo da loja. Por enquanto é só um círculo com um ícone de
        // placeholder — selecionar uma imagem de verdade da galeria do
        // celular vai exigir adicionar o pacote "image_picker" ao
        // pubspec.yaml, o que ainda não foi feito. Por isso o toque aqui
        // ainda não abre nada.
        InkWell(
          onTap: () {
            // todo: quando o pacote image_picker for adicionado ao
            // projeto, abrir aqui a galeria/câmera para escolher a logo.
          },
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

        // CNPJ e Telefone lado a lado, como no design.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ThemedTextField(
                theme: theme,
                controller: controllers.cnpj,
                label: 'CNPJ',
                tipoDeTeclado: TextInputType.number,
                // Aqui está a formatação pedida: aplica a máscara
                // 00.000.000/0000-00 automaticamente enquanto digita.
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Endereço (mais largo) e Número (mais estreito) lado a lado.
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
          label: 'Escreva as #tags em ordem de importância para melhor '
              'descrever sua loja',
          linhas: 4,
        ),
      ],
    );
  }
}