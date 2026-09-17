import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/container_simbolico.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';

// Tela "Dados do Perfil". Antes, ela recebia os dados da loja soltos, um
// parâmetro para cada campo (nome, cnpj, telefone...). Agora que o
// PdvProvider guarda uma LISTA de lojas, essa tela passa a receber só o
// "lojaId" — o identificador de QUAL loja da lista ela deve mostrar — e
// busca os dados de verdade no PdvProvider.
class DadosPerfilView extends StatefulWidget {
  final String lojaId;

  const DadosPerfilView({super.key, required this.lojaId});

  @override
  State<DadosPerfilView> createState() => _DadosPerfilViewState();
}

// As quatro abas da navegação própria da loja. Usar um enum em vez de só
// um número (0, 1, 2, 3) deixa o código mais fácil de ler: em vez de "if
// (aba == 2)", a gente escreve "if (aba == AbaLoja.loja)".
enum AbaLoja { dados, interface, loja, gestao }

// Largura máxima do conteúdo da tela. O formulário (no body) e a barra de
// abas (embaixo) usam esse mesmo número, então os dois ficam com a mesma
// largura.
const double _larguraMaximaConteudo = 500;

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();

  // Guarda qual aba da navegação própria da loja está selecionada agora.
  // Começa em "dados", que é a aba inicial pedida.
  AbaLoja _abaSelecionada = AbaLoja.dados;

  @override
  void initState() {
    super.initState();

    // context.read (não watch): aqui só precisamos LER os dados da loja
    // uma vez, para preencher os campos de texto quando a tela abre. Não
    // queremos que initState rode de novo toda vez que algo mudar no
    // provider — isso nem seria permitido pelo Flutter dentro de
    // initState.
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);

    // Se por algum motivo a loja não for encontrada (por exemplo, ela já
    // foi excluída em outra aba do navegador), os campos ficam vazios em
    // vez de quebrar o app.
    _controllers.nome.text = loja?.nome ?? '';
    _controllers.cnpj.text = loja?.cnpj ?? '';
    _controllers.telefone.text = loja?.telefone ?? '';
    _controllers.endereco.text = loja?.endereco ?? '';
    _controllers.numero.text = loja?.numero ?? '';
    _controllers.email.text = loja?.email ?? '';
    _controllers.categorias.text = loja?.categorias ?? '';
    _controllers.tags.text = loja?.tags ?? '';
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  // Função chamada quando o usuário clica em "Sair" dentro do popup de
  // Configurações. Idêntica à que já existe em perfis_pdv_view.dart:
  // pushAndRemoveUntil troca de tela E apaga toda a pilha de navegação
  // anterior, então depois disso não existe mais "voltar" para nenhuma
  // tela do PDV por engano — a única forma de voltar é fazendo
  // login/entrando como visitante de novo.
  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // false para TODAS as rotas = apaga tudo
    );
  }

  // Abre o popup "Tem certeza?" antes de excluir a loja de verdade. Só um
  // AlertDialog simples, seguindo o mesmo visual (cores, borda
  // arredondada) dos outros popups do app, como o de Configurações.
  void _confirmarExclusao(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (dialogContext, theme, child) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Excluir Loja',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: Text(
                'Tem certeza que deseja excluir esta loja? Essa ação não '
                'pode ser desfeita.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(fontSize: 14),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _executarExclusao(dialogContext),
                  child: Text(
                    'Excluir',
                    style: theme.getTextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Executa a exclusão de verdade, depois que o usuário já confirmou no
  // popup. Remove APENAS a loja com este lojaId (as outras lojas
  // continuam intactas na lista) e leva o usuário de volta para "Meus
  // Perfis" — já que a loja que estava sendo vista nesta tela não existe
  // mais, não faz sentido deixar ele "voltar" para cá.
  void _executarExclusao(BuildContext dialogContext) {
    // Pegamos a referência do Navigator ANTES de fechar o popup e a tela,
    // pelo mesmo motivo já usado no popup de categoria: depois do pop(),
    // o context pode não ser mais confiável.
    final navigator = Navigator.of(dialogContext);

    dialogContext.read<PdvProvider>().excluirLoja(widget.lojaId);

    navigator.pop(); // fecha o popup de confirmação

    // pushAndRemoveUntil troca esta tela pela de "Meus Perfis" e apaga
    // toda a pilha de navegação anterior (incluindo esta própria tela de
    // Dados do Perfil) — assim o botão "voltar" não consegue mais chegar
    // numa tela mostrando dados de uma loja que já foi excluída.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  // Decide o que aparece no meio da tela, dependendo da aba escolhida.
  // Por enquanto só a aba "Dados" está completa; as outras três ainda
  // estão esperando você definir quais containers entram em cada uma.
  Widget _conteudoDaAba(AppTheme theme) {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        // Decoração compartilhada por TODOS os blocos desta aba (o
        // formulário e cada ContainerSimbolico): fundo semi-transparente
        // + borda arredondada. Isso é a mesma decoração que já existia
        // dentro do ContainerSimbolico — deixamos ela guardada aqui numa
        // variável para não repetir o mesmo código várias vezes, e para
        // os dois lugares ficarem sempre idênticos visualmente.
        final decoracaoDoBloco = BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        );

        return Column(
          children: [
            // O formulário e o botão "Excluir Loja" ficam dentro de um
            // Container com a mesma borda usada nos containers seguintes
            // (Dados Bancários, Galeria, etc.), como no protótipo do
            // Figma.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: decoracaoDoBloco,
              child: Column(
                children: [
                  FormularioDadosLoja(
                    theme: theme,
                    controllers: _controllers,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _confirmarExclusao(context),
                    child: Text(
                      'Excluir Loja',
                      style: theme.getTextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Todos os containers abaixo seguem o mesmo padrão visual do
            // formulário acima: mesmo ContainerSimbolico, com 16 de
            // espaçamento entre um e outro. Como estão dentro do
            // SingleChildScrollView do body (lá embaixo, no build), a
            // tela toda rola normalmente quando o conteúdo não cabe.
            ContainerSimbolico(theme: theme, titulo: 'Dados Bancários'),
            const SizedBox(height: 16),
            ContainerSimbolico(
              theme: theme,
              titulo: 'Usuários Participantes',
            ),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Delivery'),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Galeria'),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Arquivos'),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Músicas'),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Vídeos'),
            const SizedBox(height: 16),
            ContainerSimbolico(theme: theme, titulo: 'Arquivos de Áudio'),
          ],
        );

      // As três abas abaixo ainda não têm seus containers definidos.
      // Assim que soubermos quais dos containers pertencem a cada uma
      // (já que os sete de cima ficaram todos na aba "Dados" por
      // enquanto), é só mover os ContainerSimbolico() correspondentes
      // para cá.
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
          appBar: CustomAppBar(
            title: 'Dados do Perfil',
            onLogout: () => _handleLogout(context),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _larguraMaximaConteudo),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _conteudoDaAba(theme),
                ),
              ),
            ),
          ),
          // bottomNavigationBar fica sempre fixo na parte de baixo da
          // tela, não rola junto com o conteúdo. Nada é embrulhado em
          // volta dele aqui — a limitação de largura acontece dentro do
          // próprio _BarraDeAbasDaLoja, pelo cálculo de margem.
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
    // ---------------------------------------------------------------
    // NOVA ABORDAGEM PARA A LARGURA
    //
    // As tentativas anteriores usavam Center + ConstrainedBox, que é o
    // jeito "normal" de limitar largura no Flutter — mas dentro do slot
    // bottomNavigationBar do Scaffold isso não pegou.
    //
    // Então aqui a conta é feita na mão, com o mesmo recurso que já
    // resolveu o bug do popup "Personalizar Aparência" neste projeto:
    // MediaQuery.sizeOf(context) + .clamp().
    //
    // Como funciona, em português:
    // 1. Pega a largura total da tela.
    // 2. Descobre quanto "sobra" além dos 500px do conteúdo.
    // 3. Divide essa sobra por 2 — esse é o espaço de cada lado.
    // 4. O .clamp(0, ...) garante que o número nunca fique negativo
    //    (se a tela for menor que 500px, a sobra daria negativo, e
    //    margem negativa quebra o app).
    // ---------------------------------------------------------------
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - _larguraMaximaConteudo;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return Container(
      // A cor de fundo e a borda de cima continuam ocupando a tela
      // inteira; só o conteúdo de dentro é que fica estreito.
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: EdgeInsets.only(
        // 12 é o espaçamento que já existia antes nas laterais; a
        // margemLateral calculada acima é somada a ele.
        left: margemLateral + 12,
        right: margemLateral + 12,
        top: 10,
        bottom: 10,
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
                    foregroundColor:
                        selecionada ? theme.buttonTextColor : theme.textColor,
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
                      color:
                          selecionada ? theme.buttonTextColor : theme.textColor,
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