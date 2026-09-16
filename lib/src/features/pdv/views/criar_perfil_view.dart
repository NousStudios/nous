import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';

// Tela de formulário aberta ao clicar em "Criar Perfil" na tela de Perfis.
//
// IMPORTANTE (ponto de partida, não versão final): como ainda não
// definimos todos os campos que um perfil de loja precisa ter, comecei
// com só três (Nome, Categoria e Descrição) — é fácil adicionar, remover
// ou renomear campos depois. Além disso, o botão "Salvar" por enquanto só
// fecha a tela; ele ainda não guarda o perfil em lugar nenhum. Isso vai
// exigir criar um "PdvProvider" (parecido com o AuthProvider que já existe
// na feature de login), que guarde a lista de perfis do usuário — esse é
// um próximo passo natural depois desta tela.
class CriarPerfilView extends StatefulWidget {
  const CriarPerfilView({super.key});

  @override
  State<CriarPerfilView> createState() => _CriarPerfilViewState();
}

class _CriarPerfilViewState extends State<CriarPerfilView> {
  // GlobalKey<FormState> é como a gente "controla" o Form por fora dele.
  // Com essa chave, dá pra mandar o Form validar todos os campos de uma
  // vez só, quando o botão Salvar for clicado.
  final _formKey = GlobalKey<FormState>();

  // Um TextEditingController para cada campo de texto: eles guardam o que
  // foi digitado e permitem ler esse valor depois (por exemplo, na hora
  // de salvar).
  final _nomeController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void dispose() {
    // dispose() é chamado automaticamente pelo Flutter quando essa tela é
    // fechada. Aqui a gente aproveita para liberar a memória usada pelos
    // controllers — é uma boa prática sempre fazer isso, senão eles
    // continuam ocupando memória mesmo depois da tela sumir.
    _nomeController.dispose();
    _categoriaController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _handleSalvar() {
    // validate() roda a regra de validação (o "validator") de cada campo
    // do formulário. Se algum campo obrigatório estiver vazio, o próprio
    // campo mostra a mensagem de erro embaixo dele, e validate() retorna
    // false — nesse caso a gente nem tenta continuar.
    final formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) return;

    // todo (próximo passo): em vez de só fechar a tela, aqui é onde vamos
    // enviar _nomeController.text, _categoriaController.text e
    // _descricaoController.text para um PdvProvider, que vai guardar esse
    // novo perfil numa lista (e, futuramente, salvar isso de verdade em
    // algum backend).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          // Sem passar showBackButton aqui: o padrão do CustomAppBar já
          // deve mostrar a seta de voltar, que é exatamente o que
          // queremos nesta tela (voltar para os Perfis).
          appBar: CustomAppBar(title: 'Criar Perfil'),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                // Mesma ideia de largura máxima usada na tela de Perfis,
                // para o formulário não ficar esticado de ponta a ponta
                // em telas largas (tablet, desktop, navegador).
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  // SingleChildScrollView permite rolar a tela para baixo
                  // caso o teclado do celular abra e "empurre" o
                  // formulário, ou se no futuro adicionarmos mais campos
                  // do que cabe na tela de uma vez.
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CampoTexto(
                          theme: theme,
                          controller: _nomeController,
                          label: 'Nome da loja',
                          obrigatorio: true,
                        ),
                        const SizedBox(height: 16),
                        _CampoTexto(
                          theme: theme,
                          controller: _categoriaController,
                          label: 'Categoria (ex: Mercado, Padaria...)',
                        ),
                        const SizedBox(height: 16),
                        _CampoTexto(
                          theme: theme,
                          controller: _descricaoController,
                          label: 'Descrição',
                          linhas: 4,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          // Mesmo padrão de cores usado nos outros botões
                          // sólidos do app: fundo buttonColor, texto
                          // buttonTextColor, borda borderColor.
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _handleSalvar,
                          child: Text(
                            'Salvar',
                            style: theme.getTextStyle(
                              fontSize: 15,
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
            ),
          ),
        );
      },
    );
  }
}

// Campo de texto padronizado do formulário, para não repetir o mesmo
// estilo (cores, bordas, fonte) em cada campo separadamente.
class _CampoTexto extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final String label;
  final bool obrigatorio;
  final int linhas;

  const _CampoTexto({
    required this.theme,
    required this.controller,
    required this.label,
    this.obrigatorio = false,
    this.linhas = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: linhas,
      style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.getTextStyle(fontSize: 14),
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
      // O validator só é usado se o campo for obrigatório. Se não for,
      // ele sempre retorna null, que em Flutter significa "sem erro".
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