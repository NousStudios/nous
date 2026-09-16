import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';

// Tela "Cadastrar Loja", aberta quando o usuário escolhe "Loja Padrão" no
// popup de categoria e clica em "Selecionar".
class CadastrarLojaView extends StatefulWidget {
  // Categoria que veio do popup anterior (por enquanto sempre "Loja
  // Padrão", mas deixamos como parâmetro para o dia em que outras
  // categorias também tiverem essa mesma tela de cadastro).
  final String categoriaInicial;

  const CadastrarLojaView({super.key, required this.categoriaInicial});

  @override
  State<CadastrarLojaView> createState() => _CadastrarLojaViewState();
}

class _CadastrarLojaViewState extends State<CadastrarLojaView> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = ControllersDadosLoja();

  @override
  void initState() {
    super.initState();
    // Já preenche o campo "Categorias" com a categoria escolhida no popup
    // anterior, para o usuário não ter que digitar de novo.
    _controllers.categorias.text = widget.categoriaInicial;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _handleCadastrar() {
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return;

    // pushReplacement (em vez de push): troca esta tela de Cadastro pela
    // tela de Dados do Perfil na pilha de navegação. Assim, se o usuário
    // apertar "voltar" na tela de Dados do Perfil, ele volta direto para
    // a tela de Perfis — não faz sentido voltar para o formulário de
    // cadastro depois que a loja já foi cadastrada.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DadosPerfilView(
          nomeInicial: _controllers.nome.text,
          cnpjInicial: _controllers.cnpj.text,
          telefoneInicial: _controllers.telefone.text,
          enderecoInicial: _controllers.endereco.text,
          numeroInicial: _controllers.numero.text,
          emailInicial: _controllers.email.text,
          categoriasInicial: _controllers.categorias.text,
          tagsInicial: _controllers.tags.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(title: 'Cadastrar Loja'),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                // Mesma largura máxima usada nas outras telas, para o
                // formulário ficar centralizado em telas largas.
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Dados da empresa',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FormularioDadosLoja(
                            theme: theme,
                            controllers: _controllers,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: theme.buttonColor,
                                foregroundColor: theme.buttonTextColor,
                                side: BorderSide(color: theme.borderColor),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _handleCadastrar,
                              child: Text(
                                'Cadastrar',
                                style: theme.getTextStyle(
                                  fontSize: 14,
                                  color: theme.buttonTextColor,
                                ),
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
          ),
        );
      },
    );
  }
}