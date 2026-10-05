import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class CadastrarLojaView extends StatefulWidget {
  final String categoriaInicial;

  const CadastrarLojaView({super.key, required this.categoriaInicial});

  @override
  State<CadastrarLojaView> createState() => _CadastrarLojaViewState();
}

class _CadastrarLojaViewState extends State<CadastrarLojaView> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = ControllersDadosLoja();
  String _logo = '';

  @override
  void initState() {
    super.initState();
    _controllers.categorias.text = widget.categoriaInicial;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _alterarLogo(AppTheme theme) async {
    if (_logo.isNotEmpty) {
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Logo da Loja',
        onEscolherNova: () => _selecionarNovaLogo(theme),
        onRemover: () => setState(() => _logo = ''),
      );
    } else {
      await _selecionarNovaLogo(theme);
    }
  }

  Future<void> _selecionarNovaLogo(AppTheme theme) async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return;

    final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
    if (salvo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'A logo deve ser uma imagem válida de até meio giga (500MB).',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _logo = salvo);
  }

  void _handleCadastrar() {
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return;

    final pdvProvider = context.read<PdvProvider>();

    pdvProvider.salvarLoja(
      nome: _controllers.nome.text,
      cnpj: _controllers.cnpj.text,
      telefone: _controllers.telefone.text,
      endereco: _controllers.endereco.text,
      numero: _controllers.numero.text,
      email: _controllers.email.text,
      categorias: _controllers.categorias.text,
      tags: _controllers.tags.text,
      logo: _logo,
    );

    final lojaRecemCriada = pdvProvider.lojas.last;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DadosPerfilView(lojaId: lojaRecemCriada.id),
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
                            logo: _logo,
                            onAlterarLogo: () => _alterarLogo(theme),
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