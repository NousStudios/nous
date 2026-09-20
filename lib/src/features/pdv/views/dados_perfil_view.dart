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
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios_participantes_container.dart';

class DadosPerfilView extends StatefulWidget {
  final String lojaId;

  const DadosPerfilView({super.key, required this.lojaId});

  @override
  State<DadosPerfilView> createState() => _DadosPerfilViewState();
}

enum AbaLoja { dados, interface, loja, gestao }

const double _larguraMaximaConteudo = 500;

// Altura máxima (em pixels) que as listas de "Categorias" e de "Grupos
// de Componentes" ocupam ENQUANTO NENHUMA delas está expandida — dá
// pra ver 2 de cada vez, com rolagem interna a partir da 3ª. Quando
// uma categoria/grupo é expandida, esse limite deixa de ser usado
// (veja _listaCategorias/_listaGrupos), pra caber todos os
// subcomponentes dela na tela.
const double _alturaMaximaListaSecundaria = 136;

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();
  final _controllersBancarios = ControllersDadosBancarios();
  final _controllersUsuarios = ControllersUsuariosParticipantes();
  final _controllersDelivery = ControllersDelivery();

  AbaLoja _abaSelecionada = AbaLoja.dados;

  final List<CategoriaLoja> _categorias = [];
  final List<ItemLoja> _itens = [];
  final List<GrupoComponentesLoja> _gruposComponentes = [];

  // NOVO: guarda o id da categoria/grupo que está expandido no
  // momento (ou null, se nenhum estiver). Antes, cada
  // CategoriaLojaContainer/GrupoComponentesLojaContainer cuidava disso
  // sozinho, por dentro. Agora é a TELA que sabe disso, porque
  // precisa reagir: tirar o limite de altura da lista e rolar até o
  // item expandido.
  String? _categoriaExpandidaId;
  String? _grupoExpandidoId;

  // NOVO: cada categoria/grupo tem uma "chave" própria (GlobalKey), um
  // jeito do Flutter de "marcar" um widget específico na árvore para
  // conseguirmos achar sua posição na tela depois (usado para rolar
  // até ele). Guardamos num mapa (id -> chave) para reutilizar a MESMA
  // chave sempre que aquela categoria/grupo for desenhado de novo —
  // se criássemos uma chave nova a cada vez, o Flutter não conseguiria
  // saber que é o "mesmo" widget de antes.
  final Map<String, GlobalKey> _chavesCategorias = {};
  final Map<String, GlobalKey> _chavesGrupos = {};

  GlobalKey _chaveCategoria(String id) =>
      _chavesCategorias.putIfAbsent(id, () => GlobalKey());

  GlobalKey _chaveGrupo(String id) =>
      _chavesGrupos.putIfAbsent(id, () => GlobalKey());

  // NOVO: rola a tela até a categoria/grupo identificado por "chave",
  // encostando-o no topo da área visível. addPostFrameCallback espera
  // o Flutter terminar de desenhar o novo layout (sem o limite de
  // altura) antes de calcular a posição certa para rolar — se
  // tentássemos rolar ANTES do redesenho, a posição calculada ainda
  // seria a antiga (com a caixinha pequena), e a rolagem sairia
  // errada.
  void _rolarAteOTopo(GlobalKey chave) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextoDoWidget = chave.currentContext;
      if (contextoDoWidget == null) return;
      Scrollable.ensureVisible(
        contextoDoWidget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // alignment 0.0 significa "encostado no topo" da área visível
        // da rolagem (1.0 seria encostado embaixo).
        alignment: 0.0,
      );
    });
  }

  // NOVO: alterna a categoria expandida. Se a categoria clicada já
  // estava expandida, fecha (volta pra null). Se era outra (ou
  // nenhuma), expande só essa — ou seja, só uma categoria fica aberta
  // "por completo" de cada vez.
  void _alternarExpansaoCategoria(String id) {
    final vaiExpandir = _categoriaExpandidaId != id;
    setState(() => _categoriaExpandidaId = vaiExpandir ? id : null);
    if (vaiExpandir) _rolarAteOTopo(_chaveCategoria(id));
  }

  void _alternarExpansaoGrupo(String id) {
    final vaiExpandir = _grupoExpandidoId != id;
    setState(() => _grupoExpandidoId = vaiExpandir ? id : null);
    if (vaiExpandir) _rolarAteOTopo(_chaveGrupo(id));
  }

  void _persistirListasLoja() {
    context.read<PdvProvider>().atualizarListasLoja(
          widget.lojaId,
          categorias: _categorias,
          itens: _itens,
          gruposComponentes: _gruposComponentes,
        );
  }

  void _abrirPopupNovoGrupoComponentes() {
    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      onCriar: (grupo) {
        setState(() => _gruposComponentes.add(grupo));
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupEditarGrupoComponentes(GrupoComponentesLoja grupo) {
    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      grupoParaEditar: grupo,
      onCriar: (grupoEditado) {
        setState(() {
          final indice =
              _gruposComponentes.indexWhere((g) => g.id == grupoEditado.id);
          if (indice != -1) _gruposComponentes[indice] = grupoEditado;
        });
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupNovaCategoria() {
    NovaCategoriaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      gruposComponentes: _gruposComponentes,
      onCriar: (categoria) {
        setState(() => _categorias.add(categoria));
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupEditarCategoria(CategoriaLoja categoria) {
    NovaCategoriaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      gruposComponentes: _gruposComponentes,
      categoriaParaEditar: categoria,
      onCriar: (categoriaEditada) {
        setState(() {
          final indice =
              _categorias.indexWhere((c) => c.id == categoriaEditada.id);
          if (indice != -1) _categorias[indice] = categoriaEditada;
        });
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupNovoItem() {
    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      onCriar: (item) {
        setState(() => _itens.add(item));
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupEditarItem(ItemLoja item) {
    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      itemParaEditar: item,
      onCriar: (itemEditado) {
        setState(() {
          final indice = _itens.indexWhere((i) => i.id == itemEditado.id);
          if (indice != -1) _itens[indice] = itemEditado;
        });
        _persistirListasLoja();
      },
    );
  }

  void _editarNomeItem(String id, String novoNome) {
    setState(() {
      final indice = _itens.indexWhere((i) => i.id == id);
      if (indice == -1) return;
      _itens[indice] = _itens[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();
  }

  void _editarPrecoItem(String id, String novoPreco) {
    setState(() {
      final indice = _itens.indexWhere((i) => i.id == id);
      if (indice == -1) return;
      _itens[indice] = _itens[indice].copyWith(preco: novoPreco);
    });
    _persistirListasLoja();
  }

  // NOVO: mesma lógica de _editarNomeItem, só que para o nome da
  // própria categoria — chamado pelo TextField inline adicionado em
  // CategoriaLojaContainer (widget.onNomeAlterado).
  void _editarNomeCategoria(String id, String novoNome) {
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == id);
      if (indice == -1) return;
      _categorias[indice] = _categorias[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();
  }

  // NOVO: mesma lógica de _editarNomeCategoria, para o nome do Grupo
  // de Componentes — chamado pelo TextField inline adicionado em
  // GrupoComponentesLojaContainer (widget.onNomeAlterado).
  void _editarNomeGrupoComponentes(String id, String novoNome) {
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == id);
      if (indice == -1) return;
      _gruposComponentes[indice] =
          _gruposComponentes[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();
  }

  void _removerCategoria(String id) {
    setState(() {
      _categorias.removeWhere((categoria) => categoria.id == id);
      // NOVO: se a categoria excluída era a que estava expandida,
      // "esquece" essa expansão — sem isso, a tela ficaria travada no
      // modo "expandido" (lista sem limite de altura) mesmo sem
      // nenhuma categoria realmente aberta.
      if (_categoriaExpandidaId == id) _categoriaExpandidaId = null;
    });
    _persistirListasLoja();
  }

  void _removerItem(String id) {
    setState(() => _itens.removeWhere((item) => item.id == id));
    _persistirListasLoja();
  }

  void _removerGrupoComponentes(String id) {
    setState(() {
      _gruposComponentes.removeWhere((grupo) => grupo.id == id);
      if (_grupoExpandidoId == id) _grupoExpandidoId = null;
    });
    _persistirListasLoja();
  }

  void _adicionarItemNaCategoria(CategoriaLoja categoria, String itemId) {
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds = [...categoria.itemIds, itemId];
      _categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();
  }

  void _removerItemDaCategoria(CategoriaLoja categoria, String itemId) {
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds =
          categoria.itemIds.where((id) => id != itemId).toList();
      _categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();
  }

  void _adicionarItemNoGrupoComponentes(
      GrupoComponentesLoja grupo, String itemId) {
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = [...grupo.itemIds, itemId];
      _gruposComponentes[indice] = grupo.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();
  }

  void _removerItemDoGrupoComponentes(
      GrupoComponentesLoja grupo, String itemId) {
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = grupo.itemIds.where((id) => id != itemId).toList();
      _gruposComponentes[indice] = grupo.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();
  }

  @override
  void initState() {
    super.initState();

    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);

    _controllers.nome.text = loja?.nome ?? '';
    _controllers.cnpj.text = loja?.cnpj ?? '';
    _controllers.telefone.text = loja?.telefone ?? '';
    _controllers.endereco.text = loja?.endereco ?? '';
    _controllers.numero.text = loja?.numero ?? '';
    _controllers.email.text = loja?.email ?? '';
    _controllers.categorias.text = loja?.categorias ?? '';
    _controllers.tags.text = loja?.tags ?? '';

    _categorias.addAll(loja?.categoriasLoja ?? []);
    _itens.addAll(loja?.itensLoja ?? []);
    _gruposComponentes.addAll(loja?.gruposComponentesLoja ?? []);
  }

  @override
  void dispose() {
    _controllers.dispose();
    _controllersBancarios.dispose();
    _controllersUsuarios.dispose();
    _controllersDelivery.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

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

  void _executarExclusao(BuildContext dialogContext) {
    final navigator = Navigator.of(dialogContext);

    dialogContext.read<PdvProvider>().excluirLoja(widget.lojaId);

    navigator.pop();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

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

  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.backgroundColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
    );
  }

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

  Widget _textoListaVazia(AppTheme theme, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        texto,
        style:
            theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
      ),
    );
  }

  // ALTERADO: era um Wrap (que quebrava para uma segunda linha quando
  // não cabia). Agora é uma Row dentro de um SingleChildScrollView
  // horizontal, então os três botões ficam SEMPRE na mesma linha — se
  // não couberem na largura da tela, aparece rolagem lateral em vez de
  // quebrar linha.
  Widget _barraDeAcoesLoja(AppTheme theme) {
    return Container(
      width: double.infinity,
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _botaoAcaoLoja(theme, 'Novo Item', _abrirPopupNovoItem),
                const SizedBox(width: 8),
                _botaoAcaoLoja(
                  theme,
                  'Nova Categoria',
                  _abrirPopupNovaCategoria,
                ),
                const SizedBox(width: 8),
                _botaoAcaoLoja(
                  theme,
                  'Novo Grupo de Componentes',
                  _abrirPopupNovoGrupoComponentes,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NOVO: monta um CategoriaLojaContainer, já ligado a todos os
  // callbacks necessários. Extraído num método próprio porque agora
  // ele é usado em DOIS lugares diferentes (lista pequena com limite
  // de altura, e coluna cheia quando uma categoria está expandida) —
  // sem isso, teríamos que repetir o mesmo bloco de código duas vezes.
  //
  // ALTERADO: adicionado onNomeAlterado, ligado a _editarNomeCategoria
  // — é isso que faz o TextField inline do nome, adicionado em
  // CategoriaLojaContainer, realmente persistir a mudança (antes, o
  // parâmetro existia no widget mas nada aqui o preenchia, então a
  // edição funcionava só visualmente).
  Widget _construirCategoria(AppTheme theme, CategoriaLoja categoria) {
    return CategoriaLojaContainer(
      key: _chaveCategoria(categoria.id),
      theme: theme,
      nome: categoria.nome,
      itemIds: categoria.itemIds,
      itensDisponiveis: _itens,
      expandida: categoria.id == _categoriaExpandidaId,
      aoAlternarExpansao: () => _alternarExpansaoCategoria(categoria.id),
      onAdicionarItem: (itemId) => _adicionarItemNaCategoria(categoria, itemId),
      onRemoverItem: (itemId) => _removerItemDaCategoria(categoria, itemId),
      onEditar: () => _abrirPopupEditarCategoria(categoria),
      onExcluir: () => _removerCategoria(categoria.id),
      onNomeAlterado: (novoNome) =>
          _editarNomeCategoria(categoria.id, novoNome),
      onEditarNomeItem: _editarNomeItem,
      onEditarPrecoItem: _editarPrecoItem,
      onEditarItem: _abrirPopupEditarItem,
    );
  }

  // NOVO: decide como mostrar a lista de Categorias. Enquanto nenhuma
  // está expandida, usa a caixinha de altura fixa (cabe 2, com
  // rolagem interna). Assim que uma expande, troca para uma coluna
  // comum — sem altura fixa, sem rolagem própria — para que TODOS os
  // subcomponentes da categoria aberta caibam por inteiro; a rolagem
  // passa a ser a da tela toda, e é isso que permite ela "subir até o
  // topo" (feito em _alternarExpansaoCategoria).
  Widget _listaCategorias(AppTheme theme) {
    if (_categorias.isEmpty) {
      return _textoListaVazia(theme, 'Nenhuma categoria criada ainda.');
    }

    if (_categoriaExpandidaId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 8),
            itemCount: _categorias.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _construirCategoria(theme, _categorias[index]),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final categoria in _categorias) ...[
          _construirCategoria(theme, categoria),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // Mesma ideia de _construirCategoria, só que para Grupos de
  // Componentes.
  //
  // ALTERADO: adicionado onNomeAlterado, ligado a
  // _editarNomeGrupoComponentes, pelo mesmo motivo do comentário em
  // _construirCategoria.
  Widget _construirGrupo(AppTheme theme, GrupoComponentesLoja grupo) {
    return GrupoComponentesLojaContainer(
      key: _chaveGrupo(grupo.id),
      theme: theme,
      nome: grupo.nome,
      itemIds: grupo.itemIds,
      itensDisponiveis: _itens,
      expandida: grupo.id == _grupoExpandidoId,
      aoAlternarExpansao: () => _alternarExpansaoGrupo(grupo.id),
      onAdicionarItem: (itemId) => _adicionarItemNoGrupoComponentes(grupo, itemId),
      onRemoverItem: (itemId) => _removerItemDoGrupoComponentes(grupo, itemId),
      onEditar: () => _abrirPopupEditarGrupoComponentes(grupo),
      onExcluir: () => _removerGrupoComponentes(grupo.id),
      onNomeAlterado: (novoNome) =>
          _editarNomeGrupoComponentes(grupo.id, novoNome),
      onEditarNomeItem: _editarNomeItem,
      onEditarPrecoItem: _editarPrecoItem,
      onEditarItem: _abrirPopupEditarItem,
    );
  }

  // Mesma ideia de _listaCategorias, só que para Grupos de
  // Componentes.
  Widget _listaGrupos(AppTheme theme) {
    if (_gruposComponentes.isEmpty) {
      return _textoListaVazia(
          theme, 'Nenhum grupo de componentes criado ainda.');
    }

    if (_grupoExpandidoId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 8),
            itemCount: _gruposComponentes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _construirGrupo(theme, _gruposComponentes[index]),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final grupo in _gruposComponentes) ...[
          _construirGrupo(theme, grupo),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _conteudoDaAba(AppTheme theme) {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        final decoracaoDoBloco = _decoracaoDoBloco(theme);

        return Column(
          children: [
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
            ContainerSimbolico(theme: theme, titulo: 'Arquivos de Áudio'),
          ],
        );

      case AbaLoja.loja:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _decoracaoDoBloco(theme),
          child: Column(
            children: [
              // 1) ITENS — lista HORIZONTAL (rolagem lateral).
              _tituloDeSecao(theme, 'Itens'),
              const SizedBox(height: 12),
              if (_itens.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _itens.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _itens[index];
                      return ItemLojaCard(
                        key: ValueKey('item_${item.id}'),
                        theme: theme,
                        nome: item.nome,
                        preco: item.preco,
                        tipo: item.tipo,
                        onEditar: () => _abrirPopupEditarItem(item),
                        onExcluir: () => _removerItem(item.id),
                        onNomeAlterado: (novoNome) =>
                            _editarNomeItem(item.id, novoNome),
                        onPrecoAlterado: (novoPreco) =>
                            _editarPrecoItem(item.id, novoPreco),
                      );
                    },
                  ),
                )
              else
                _textoListaVazia(theme, 'Nenhum item criado ainda.'),

              // 2) CATEGORIAS
              const SizedBox(height: 24),
              _tituloDeSecao(theme, 'Categorias'),
              const SizedBox(height: 12),
              _listaCategorias(theme),

              // 3) GRUPOS DE COMPONENTES
              const SizedBox(height: 24),
              _tituloDeSecao(theme, 'Grupos de Componentes'),
              const SizedBox(height: 12),
              _listaGrupos(theme),
            ],
          ),
        );

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
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_abaSelecionada == AbaLoja.loja) _barraDeAcoesLoja(theme),
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

class _BarraDeAbasDaLoja extends StatelessWidget {
  final AppTheme theme;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> aoTrocarAba;

  const _BarraDeAbasDaLoja({
    required this.theme,
    required this.abaSelecionada,
    required this.aoTrocarAba,
  });

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