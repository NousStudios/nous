import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/cadastrar_loja_view.dart';

// Função helper que abre o popup de "Criar Perfil". É ela que a tela de
// Perfis chama quando o botão "Criar Perfil" é clicado.
//
// showDialog já escurece a tela de trás sozinho (o "barrierColor" padrão
// do Flutter é um preto semitransparente) — é por isso que a tela de
// "Meus Perfis Profissionais" fica ofuscada atrás do popup. Isso é
// automático, não precisamos programar nada para isso acontecer.
Future<void> showCriarPerfilDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _CriarPerfilDialog(),
  );
}

class _CriarPerfilDialog extends StatefulWidget {
  const _CriarPerfilDialog();

  @override
  State<_CriarPerfilDialog> createState() => _CriarPerfilDialogState();
}

class _CriarPerfilDialogState extends State<_CriarPerfilDialog> {
  // Lista de categorias que aparecem na listinha de escolha. Por enquanto
  // só "Loja Padrão" tem uma tela de continuação de verdade; as outras já
  // aparecem na lista (é assim que está no design), mas ainda não levam a
  // lugar nenhum além de ficarem selecionadas aqui no popup.
  static const List<String> _categorias = [
    'Loja Padrão',
    'Motoboy',
    'Motorista',
    'Professor',
  ];

  // Guarda qual categoria o usuário já escolheu. Começa como null (nada
  // escolhido ainda) — é isso que mantém o botão "Selecionar" desabilitado
  // no início.
  String? _categoriaSelecionada;

  // Abre uma listinha simples com as opções de categoria, centralizada na
  // tela. Ao tocar numa opção, guardamos a escolha e fechamos essa
  // listinha.
  Future<void> _abrirListaDeCategorias(AppTheme theme) async {
    final categoriaEscolhida = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            // Mesma largura máxima do popup principal, para os dois
            // ficarem consistentes visualmente.
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _categorias.map((categoria) {
                return ListTile(
                  title: Text(
                    categoria,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(fontSize: 15),
                  ),
                  // pop(categoria): fecha a listinha E já devolve o valor
                  // escolhido para quem chamou showDialog.
                  onTap: () => Navigator.of(context).pop(categoria),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    // Se o usuário realmente escolheu algo (não fechou a listinha sem
    // escolher), atualizamos o estado para redesenhar o popup com a
    // categoria escolhida.
    if (categoriaEscolhida != null) {
      setState(() => _categoriaSelecionada = categoriaEscolhida);
    }
  }

  // Chamado ao clicar em "Selecionar". Fecha o popup de categoria e, se a
  // categoria for "Loja Padrão", abre a tela de cadastro dela.
  void _confirmarSelecao(BuildContext context) {
    final categoria = _categoriaSelecionada!;

    // Pegamos a referência do Navigator ANTES de fechar o popup. Isso
    // importa porque, depois do pop(), o "context" deste widget pode não
    // ser mais confiável (o widget está sendo removido da tela) — mas a
    // variável "navigator" continua válida, pois já guardamos a
    // referência que precisávamos dela.
    final navigator = Navigator.of(context);
    navigator.pop(); // fecha o popup de categoria

    if (categoria == 'Loja Padrão') {
      navigator.push(
        MaterialPageRoute(
          builder: (context) =>
              CadastrarLojaView(categoriaInicial: categoria),
        ),
      );
    }
    // todo: quando Motoboy, Motorista e Professor tiverem suas próprias
    // telas de cadastro, adicionar os casos delas aqui.
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        // Usamos Dialog (não AlertDialog) de propósito: o AlertDialog usa
        // IntrinsicWidth por baixo dos panos, o que trava o app quando
        // combinado com certos widgets de layout (é a mesma armadilha do
        // LayoutBuilder que já resolvemos no popup de Aparência). Com
        // Dialog simples, temos controle total do conteúdo sem esse
        // risco.
        return Dialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              // Largura máxima do popup, para não ficar gigante em telas
              // largas (tablet, desktop). O próprio Dialog já cuida de
              // não deixar isso estourar a tela em celulares pequenos.
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título do popup — usa textColor por ser um cabeçalho
                  // de janela, seguindo a mesma regra usada em "Termos de
                  // Uso" e "Personalizar Aparência".
                  Text(
                    'Categoria da Loja ou Função',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Este é o "container pequeno" da sua descrição: mostra
                  // um texto de instrução até que uma categoria seja
                  // escolhida, e depois passa a mostrar a categoria
                  // escolhida no lugar. Tocar nele abre a listinha.
                  InkWell(
                    onTap: () => _abrirListaDeCategorias(theme),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Text(
                        _categoriaSelecionada ??
                            'Principais Categorias para Perfis '
                                'Profissionais',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão "Selecionar": segue o mesmo padrão de cores dos
                  // outros botões sólidos do app (buttonColor +
                  // buttonTextColor + borderColor). Só fica habilitado
                  // (onPressed diferente de null) depois que uma
                  // categoria já foi escolhida.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _categoriaSelecionada == null
                          ? null
                          : () => _confirmarSelecao(context),
                      child: Text(
                        'Selecionar',
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
        );
      },
    );
  }
}