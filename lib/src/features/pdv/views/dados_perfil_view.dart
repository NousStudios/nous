import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/categoria_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/container_simbolico.dart';
import 'package:nous/src/features/pdv/views/widgets/dados_bancarios_container.dart';
import 'package:nous/src/features/pdv/views/widgets/delivery_container.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios_participantes_container.dart';

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

// Largura máxima do conteúdo da tela. O formulário (no body) e as barras
// de baixo usam esse mesmo número, então tudo fica com a mesma largura.
const double _larguraMaximaConteudo = 500;

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();

  // Controllers dos formulários novos. Cada um segue o mesmo padrão do
  // ControllersDadosLoja: um "agrupador" que guarda os TextEditingController
  // daquele formulário específico, e que precisa ser liberado da memória
  // no dispose() desta tela.
  final _controllersBancarios = ControllersDadosBancarios();
  final _controllersUsuarios = ControllersUsuariosParticipantes();
  final _controllersDelivery = ControllersDelivery();

  // Guarda qual aba da navegação própria da loja está selecionada agora.
  // Começa em "dados", que é a aba inicial pedida.
  AbaLoja _abaSelecionada = AbaLoja.dados;

  // ---------------------------------------------------------------
  // Aba "Loja" — ainda sem provider (guardamos em memória, perdido se
  // a tela fechar), mas agora com os MODELOS DE VERDADE (ItemLoja,
  // CategoriaLoja, GrupoComponentesLoja), em vez de simples números.
  // Cada botão ("Nova Categoria", "Novo Item", "Novo Grupo de
  // Componentes") abre o popup correspondente ANTES de adicionar
  // qualquer coisa a estas listas — só depois que o usuário preenche o
  // popup e aperta "Criar" é que o item de verdade entra na lista.
  // ---------------------------------------------------------------
  final List<CategoriaLoja> _categorias = [];
  final List<ItemLoja> _itens = [];
  final List<GrupoComponentesLoja> _gruposComponentes = [];

  // Abre o popup "Novo Grupo de Componentes". Ao criar, o grupo entra
  // na lista _gruposComponentes — ele não aparece em nenhum card na
  // tela (a árvore visual da aba Loja não pede isso), mas passa a
  // ficar disponível nos seletores dos popups de Categoria e Item.
  void _abrirPopupNovoGrupoComponentes() {
    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      onCriar: (grupo) {
        setState(() => _gruposComponentes.add(grupo));
      },
    );
  }

  // Abre o popup "Nova Categoria". Ao criar, a categoria vira um novo
  // CategoriaLojaContainer na lista visível da tela.
  void _abrirPopupNovaCategoria() {
    NovaCategoriaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      gruposComponentes: _gruposComponentes,
      onCriar: (categoria) {
        setState(() => _categorias.add(categoria));
      },
    );
  }

  // Abre o popup "Novo Item". Ao criar, o item vira um novo
  // ItemLojaCard na lista visível da tela, e também passa a estar
  // disponível para ser escolhido dentro de um Grupo de Componentes.
  void _abrirPopupNovoItem() {
    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      onCriar: (item) {
        setState(() => _itens.add(item));
      },
    );
  }

  void _removerCategoria(String id) {
    setState(() => _categorias.removeWhere((categoria) => categoria.id == id));
  }

  void _removerItem(String id) {
    setState(() => _itens.removeWhere((item) => item.id == id));
  }

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
    _controllersBancarios.dispose();
    _controllersUsuarios.dispose();
    _controllersDelivery.dispose();
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

  // Título mostrado no topo da tela (ao lado da seta de voltar e do ícone
  // de Configurações), de acordo com a aba selecionada agora. É chamada
  // dentro do build(), então toda vez que _abaSelecionada muda (e o
  // setState() da barra de abas dispara um novo build), esse texto é
  // recalculado e o CustomAppBar exibe o valor novo automaticamente —
  // sem precisar navegar para nenhuma tela nova.
  String _tituloDaAba() {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        return 'Dados do Perfil';
      case AbaLoja.interface:
        return 'Interface do Perfil';
      case AbaLoja.loja:
        return 'Loja do Perfil';
      case AbaLoja.gestao:
        return 'Gestão do Perfil';
    }
  }

  // Decoração compartilhada por todos os "blocos grandes" da tela (o
  // formulário principal, e agora também o bloco da aba Loja): fundo
  // semi-transparente + borda arredondada, o padrão visual de
  // bloco/container do app inteiro.
  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.backgroundColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
    );
  }

  // Botão de ação "vazado" (só borda), usado nos três botões da aba Loja
  // (Novo Grupo de Componentes / Nova Categoria / Novo Item) — mesmo
  // visual dos botões "não selecionados" da barra de abas Dados/
  // Interface/Loja/Gestão, pra manter a identidade visual do app.
  Widget _botaoAcaoLoja(AppTheme theme, String rotulo, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }

  // Título centralizado usado no topo de cada seção do bloco (ex:
  // "Categorias", "Itens") — mesmo estilo de título já usado em todos os
  // outros containers do app (fontSize 15, w600, textColor).
  Widget _tituloDeSecao(AppTheme theme, String texto) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: theme.getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  // Decide o que aparece no meio da tela, dependendo da aba escolhida.
  Widget _conteudoDaAba(AppTheme theme) {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        final decoracaoDoBloco = _decoracaoDoBloco(theme);

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

            // Os 7 containers pedidos, cada um no seu widget dedicado.
            // Todos seguem o mesmo espaçamento de 16 entre um e outro,
            // dentro do SingleChildScrollView do body (lá embaixo, no
            // build), então a tela toda continua rolando normalmente.
            DadosBancariosContainer(
              theme: theme,
              controllers: _controllersBancarios,
            ),
            const SizedBox(height: 16),
            UsuariosParticipantesContainer(
              theme: theme,
              controllers: _controllersUsuarios,
            ),
            const SizedBox(height: 16),
            DeliveryContainer(
              theme: theme,
              controllers: _controllersDelivery,
            ),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(theme: theme, titulo: 'Galeria'),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(theme: theme, titulo: 'Arquivos'),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(theme: theme, titulo: 'Músicas'),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(theme: theme, titulo: 'Vídeos'),
            const SizedBox(height: 16),

            // Este ainda não tinha print no protótipo, então continua
            // como container simbólico por enquanto.
            ContainerSimbolico(theme: theme, titulo: 'Arquivos de Áudio'),
          ],
        );

      case AbaLoja.loja:
        // Bloco "Categorias" + bloco "Itens" + botões de ação, seguindo
        // o print que você mandou. Agora com os modelos de verdade
        // (CategoriaLoja, ItemLoja): cada botão abre seu popup, e só
        // depois de "Criar" é que o card aparece na tela.
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _decoracaoDoBloco(theme),
          child: Column(
            children: [
              _tituloDeSecao(theme, 'Categorias'),
              const SizedBox(height: 12),
              for (final categoria in _categorias) ...[
                CategoriaLojaContainer(
                  key: ValueKey('categoria_${categoria.id}'),
                  theme: theme,
                  nome: categoria.nome,
                  onExcluir: () => _removerCategoria(categoria.id),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              _tituloDeSecao(theme, 'Itens'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final item in _itens)
                    ItemLojaCard(
                      key: ValueKey('item_${item.id}'),
                      theme: theme,
                      nome: item.nome,
                      onExcluir: () => _removerItem(item.id),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Ordem: Novo Grupo de Componentes primeiro, Nova
              // Categoria no meio, Novo Item por último. Cada botão
              // agora abre seu popup em vez de adicionar o card direto.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _botaoAcaoLoja(
                    theme,
                    'Novo Grupo de Componentes',
                    _abrirPopupNovoGrupoComponentes,
                  ),
                  _botaoAcaoLoja(
                    theme,
                    'Nova Categoria',
                    _abrirPopupNovaCategoria,
                  ),
                  _botaoAcaoLoja(
                    theme,
                    'Novo Item',
                    _abrirPopupNovoItem,
                  ),
                ],
              ),
            ],
          ),
        );

      // As duas abas abaixo ainda não têm seus containers definidos.
      case AbaLoja.interface:
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
            title: _tituloDaAba(),
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
          // Column com as duas barras de baixo: primeiro a de abas da
          // loja (Dados/Interface/Loja/Gestão), depois a flutuante do
          // app inteiro — igual ao protótipo. mainAxisSize.min faz a
          // Column ocupar só a altura que as duas juntas precisam, sem
          // esticar o resto da tela.
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BarraDeAbasDaLoja(
                theme: theme,
                abaSelecionada: _abaSelecionada,
                aoTrocarAba: (novaAba) =>
                    setState(() => _abaSelecionada = novaAba),
              ),
              FloatingBottomNavBar(maxWidth: _larguraMaximaConteudo),
            ],
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
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - _larguraMaximaConteudo;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: EdgeInsets.only(
        left: margemLateral + 12,
        right: margemLateral + 12,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        children: AbaLoja.values.map((aba) {
          final selecionada = aba == abaSelecionada;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
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
    );
  }
}