import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/views/widgets/container_simbolico.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';

// Tela "Dados do Perfil". É aberta de dois jeitos diferentes:
// 1) Depois de cadastrar uma loja nova (vem com os dados já preenchidos).
// 2) Ao clicar direto no card "Loja Padrão" na tela de Perfis (por
//    enquanto vem tudo vazio, já que ainda não existe nenhum lugar
//    guardando os dados de verdade — isso vai mudar quando criarmos um
//    PdvProvider).
class DadosPerfilView extends StatefulWidget {
  final String nomeInicial;
  final String cnpjInicial;
  final String telefoneInicial;
  final String enderecoInicial;
  final String numeroInicial;
  final String emailInicial;
  final String categoriasInicial;
  final String tagsInicial;

  const DadosPerfilView({
    super.key,
    this.nomeInicial = '',
    this.cnpjInicial = '',
    this.telefoneInicial = '',
    this.enderecoInicial = '',
    this.numeroInicial = '',
    this.emailInicial = '',
    this.categoriasInicial = 'Loja Padrão',
    this.tagsInicial = '',
  });

  @override
  State<DadosPerfilView> createState() => _DadosPerfilViewState();
}

// As quatro abas da navegação própria da loja. Usar um enum em vez de só
// um número (0, 1, 2, 3) deixa o código mais fácil de ler: em vez de "if
// (aba == 2)", a gente escreve "if (aba == AbaLoja.loja)".
enum AbaLoja { dados, interface, loja, gestao }

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();

  // Guarda qual aba da navegação própria da loja está selecionada agora.
  // Começa em "dados", que é a aba inicial pedida.
  AbaLoja _abaSelecionada = AbaLoja.dados;

  @override
  void initState() {
    super.initState();
    _controllers.nome.text = widget.nomeInicial;
    _controllers.cnpj.text = widget.cnpjInicial;
    _controllers.telefone.text = widget.telefoneInicial;
    _controllers.endereco.text = widget.enderecoInicial;
    _controllers.numero.text = widget.numeroInicial;
    _controllers.email.text = widget.emailInicial;
    _controllers.categorias.text = widget.categoriasInicial;
    _controllers.tags.text = widget.tagsInicial;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  // Decide o que aparece no meio da tela, dependendo da aba escolhida.
  // Por enquanto só a aba "Dados" está completa; as outras três ainda
  // estão esperando você definir quais containers entram em cada uma.
  Widget _conteudoDaAba(AppTheme theme) {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        return Column(
          children: [
            FormularioDadosLoja(theme: theme, controllers: _controllers),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // TODO: mostrar uma confirmação antes de excluir de
                // verdade, e conectar isso a um PdvProvider quando ele
                // existir.
              },
              child: Text(
                'Excluir Loja',
                style: theme.getTextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Dados Bancários'),
          ],
        );

      // As três abas abaixo ainda não têm seus containers definidos.
      // Assim que soubermos quais dos containers (Usuários Participantes,
      // Delivery, Galeria, Arquivos, Músicas, Vídeos, Arquivos de Áudio)
      // pertencem a cada uma, é só substituir este texto pelos
      // ContainerSimbolico() correspondentes.
      case AbaLoja.interface:
      case AbaLoja.loja:
      case AbaLoja.gestao:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Em construção',
              style: theme.getTextStyle(fontSize: 13),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(title: 'Dados do Perfil'),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _conteudoDaAba(theme),
                ),
              ),
            ),
          ),
          // bottomNavigationBar fica sempre fixo na parte de baixo da
          // tela, não rola junto com o conteúdo. É aqui que colocamos a
          // barra de navegação própria da loja — a barra de navegação
          // GERAL do app (com os 5 botões) ainda não existe, então por
          // enquanto esta é a única barra fixa na tela.
          bottomNavigationBar: _BarraDeAbasDaLoja(
            theme: theme,
            abaSelecionada: _abaSelecionada,
            aoTrocarAba: (novaAba) => setState(() => _abaSelecionada = novaAba),
          ),
        );
      },
    );
  }
}

// Barra com os 4 botões de navegação própria da loja (Dados, Interface,
// Loja, Gestão). O botão da aba atual fica com o mesmo visual de "hover"
// já usado no card de perfil (fundo buttonColor) — só que aqui é
// permanente enquanto a aba estiver selecionada, não depende do mouse.
class _BarraDeAbasDaLoja extends StatelessWidget {
  final AppTheme theme;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> aoTrocarAba;

  const _BarraDeAbasDaLoja({
    required this.theme,
    required this.abaSelecionada,
    required this.aoTrocarAba,
  });

  // Nome de exibição de cada aba, já que o enum usa nomes em minúsculo
  // sem acento (interface, gestao) por convenção do Dart.
  String _rotulo(AbaLoja aba) {
    switch (aba) {
      case AbaLoja.dados:
        return 'Dados';
      case AbaLoja.interface:
        return 'Interface';
      case AbaLoja.loja:
        return 'Loja';
      case AbaLoja.gestao:
        return 'Gestão';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: AbaLoja.values.map((aba) {
            final selecionada = aba == abaSelecionada;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    // Selecionada: fundo buttonColor (igual ao hover do
                    // card). Não selecionada: fundo transparente, só a
                    // borda aparece — o mesmo truque usado em todos os
                    // botões "vazados" do app.
                    backgroundColor:
                        selecionada ? theme.buttonColor : Colors.transparent,
                    foregroundColor: selecionada
                        ? theme.buttonTextColor
                        : theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => aoTrocarAba(aba),
                  child: Text(
                    _rotulo(aba),
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: selecionada ? theme.buttonTextColor : theme.textColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}