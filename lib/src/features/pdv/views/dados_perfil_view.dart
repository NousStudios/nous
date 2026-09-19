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

// NOVO: altura máxima (em pixels) que as listas de "Categorias" e de
// "Grupos de Componentes" podem ocupar na tela. Calculada para caber
// EXATAMENTE 2 itens fechados (não expandidos) de cada vez: cada linha
// fechada tem uns 64px de altura (por causa dos botões redondos de
// "expandir" e do menu "⋮", que têm uma área mínima de toque de 48px),
// mais 8px do espaço entre as duas. Do 3º item em diante, quem rola é
// só essa caixinha (por dentro), não a tela inteira. Se no seu
// aparelho a fonte ou os ícones ficarem um pouco maiores/menores e
// "vazar" um pouco além do 2º item, é só ajustar esse número.
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

  // Abre o mesmo popup de "Novo Grupo de Componentes", mas em modo de
  // edição (passando grupoParaEditar). O onCriar, nesse caso,
  // substitui o grupo antigo pelo editado na lista, em vez de
  // adicionar um novo.
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

  // NOVO: abre o mesmo popup de "Nova Categoria", mas em modo de
  // edição (passando categoriaParaEditar). O onCriar, nesse caso,
  // substitui a categoria antiga pela editada na lista, em vez de
  // adicionar uma nova.
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

  // NOVO: chamado a cada letra digitada no campo de nome, direto na
  // lista (seja no card horizontal de "Itens", seja na linha dentro de
  // uma categoria/grupo expandido). Acha o item pelo id, cria uma
  // cópia com o nome novo (copyWith) e substitui na lista.
  void _editarNomeItem(String id, String novoNome) {
    setState(() {
      final indice = _itens.indexWhere((i) => i.id == id);
      if (indice == -1) return;
      _itens[indice] = _itens[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();
  }

  // NOVO: mesma ideia de _editarNomeItem, mas para o campo de preço.
  void _editarPrecoItem(String id, String novoPreco) {
    setState(() {
      final indice = _itens.indexWhere((i) => i.id == id);
      if (indice == -1) return;
      _itens[indice] = _itens[indice].copyWith(preco: novoPreco);
    });
    _persistirListasLoja();
  }

  void _removerCategoria(String id) {
    setState(() => _categorias.removeWhere((categoria) => categoria.id == id));
    _persistirListasLoja();
  }

  void _removerItem(String id) {
    setState(() => _itens.removeWhere((item) => item.id == id));
    _persistirListasLoja();
  }

  void _removerGrupoComponentes(String id) {
    setState(
        () => _gruposComponentes.removeWhere((grupo) => grupo.id == id));
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

  // NOVO: barra fixa com os botões "Novo Item", "Nova Categoria" e
  // "Novo Grupo de Componentes". Antes, esses botões ficavam DENTRO da
  // área que rola (junto com as listas) — agora ficam numa faixa FIXA
  // da tela, logo acima da barra "Dados/Interface/Loja/Gestão", então
  // nunca somem de vista, não importa quantos itens/categorias/grupos
  // existam. Só aparece quando a aba "Loja" está selecionada.
  Widget _barraDeAcoesLoja(AppTheme theme) {
    return Container(
      width: double.infinity,
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _botaoAcaoLoja(theme, 'Novo Item', _abrirPopupNovoItem),
                _botaoAcaoLoja(
                  theme,
                  'Nova Categoria',
                  _abrirPopupNovaCategoria,
                ),
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

              // 2) CATEGORIAS — altura máxima de 2 itens
              // (_alturaMaximaListaSecundaria), com rolagem interna a
              // partir do 3º.
              const SizedBox(height: 24),
              _tituloDeSecao(theme, 'Categorias'),
              const SizedBox(height: 12),
              if (_categorias.isNotEmpty)
                SizedBox(
                  height: _alturaMaximaListaSecundaria,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(right: 8),
                      itemCount: _categorias.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final categoria = _categorias[index];
                        return CategoriaLojaContainer(
                          key: ValueKey('categoria_${categoria.id}'),
                          theme: theme,
                          nome: categoria.nome,
                          itemIds: categoria.itemIds,
                          itensDisponiveis: _itens,
                          onAdicionarItem: (itemId) =>
                              _adicionarItemNaCategoria(categoria, itemId),
                          onRemoverItem: (itemId) =>
                              _removerItemDaCategoria(categoria, itemId),
                          onEditar: () => _abrirPopupEditarCategoria(categoria),
                          onExcluir: () => _removerCategoria(categoria.id),
                          onEditarNomeItem: _editarNomeItem,
                          onEditarPrecoItem: _editarPrecoItem,
                        );
                      },
                    ),
                  ),
                )
              else
                _textoListaVazia(theme, 'Nenhuma categoria criada ainda.'),

              // 3) GRUPOS DE COMPONENTES — mesma ideia da lista de
              // Categorias logo acima: altura máxima + rolagem interna.
              const SizedBox(height: 24),
              _tituloDeSecao(theme, 'Grupos de Componentes'),
              const SizedBox(height: 12),
              if (_gruposComponentes.isNotEmpty)
                SizedBox(
                  height: _alturaMaximaListaSecundaria,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(right: 8),
                      itemCount: _gruposComponentes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final grupo = _gruposComponentes[index];
                        return GrupoComponentesLojaContainer(
                          key: ValueKey('grupo_${grupo.id}'),
                          theme: theme,
                          nome: grupo.nome,
                          itemIds: grupo.itemIds,
                          itensDisponiveis: _itens,
                          onAdicionarItem: (itemId) =>
                              _adicionarItemNoGrupoComponentes(grupo, itemId),
                          onRemoverItem: (itemId) =>
                              _removerItemDoGrupoComponentes(grupo, itemId),
                          onEditar: () =>
                              _abrirPopupEditarGrupoComponentes(grupo),
                          onExcluir: () =>
                              _removerGrupoComponentes(grupo.id),
                          onEditarNomeItem: _editarNomeItem,
                          onEditarPrecoItem: _editarPrecoItem,
                        );
                      },
                    ),
                  ),
                )
              else
                _textoListaVazia(
                    theme, 'Nenhum grupo de componentes criado ainda.'),
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
              // NOVO: os botões de criar só aparecem na aba "Loja",
              // fixos acima da barra de abas.
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