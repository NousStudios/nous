import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/financeiro_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/status_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/categoria_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/container_simbolico.dart';
import 'package:nous/src/features/pdv/views/widgets/dados_bancarios_container.dart';
import 'package:nous/src/features/pdv/views/widgets/delivery_container.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios_participantes_container.dart';

class DadosPerfilView extends StatefulWidget {
  final String lojaId;

  const DadosPerfilView({super.key, required this.lojaId});

  @override
  State<DadosPerfilView> createState() => _DadosPerfilViewState();
}

enum AbaLoja { dados, interface, loja, gestao }

const double _larguraMaximaConteudo = 500;

const double _alturaMaximaListaSecundaria = 136;

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();
  final _controllersBancarios = ControllersDadosBancarios();
  final _controllersUsuarios = ControllersUsuariosParticipantes();
  final _controllersDelivery = ControllersDelivery();

  final _pesquisaItens = TextEditingController();
  final _pesquisaCategorias = TextEditingController();
  final _pesquisaGrupos = TextEditingController();

  AbaLoja _abaSelecionada = AbaLoja.dados;

  final List<CategoriaLoja> _categorias = [];
  final List<ItemLoja> _itens = [];
  final List<GrupoComponentesLoja> _gruposComponentes = [];
  final List<Cliente> _clientes = [];

  final List<PedidoLoja> _pedidos = [];
  bool _lojaOnline = true;
  AbaPedidos _abaPedidos = AbaPedidos.novos;

  String? _categoriaExpandidaId;
  String? _grupoExpandidoId;

  final Map<String, GlobalKey> _chavesCategorias = {};
  final Map<String, GlobalKey> _chavesGrupos = {};

  GlobalKey _chaveCategoria(String id) =>
      _chavesCategorias.putIfAbsent(id, () => GlobalKey());

  GlobalKey _chaveGrupo(String id) =>
      _chavesGrupos.putIfAbsent(id, () => GlobalKey());

  void _rolarAteOTopo(GlobalKey chave) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextoDoWidget = chave.currentContext;
      if (contextoDoWidget == null) return;
      Scrollable.ensureVisible(
        contextoDoWidget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    });
  }

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
          clientes: _clientes,
          pedidos: _pedidos,
        );
  }

  void _salvarDadosLoja() {
    context.read<PdvProvider>().atualizarDadosLoja(
          widget.lojaId,
          nome: _controllers.nome.text,
          cnpj: _controllers.cnpj.text,
          telefone: _controllers.telefone.text,
          endereco: _controllers.endereco.text,
          numero: _controllers.numero.text,
          email: _controllers.email.text,
          categorias: _controllers.categorias.text,
          tags: _controllers.tags.text,
        );

    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Dados salvos.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  void _alterarStatusPedido(String id, StatusPedido novoStatus) {
    setState(() {
      final indice = _pedidos.indexWhere((p) => p.id == id);
      if (indice == -1) return;
      _pedidos[indice] = _pedidos[indice].copyWith(status: novoStatus);
    });
    _persistirListasLoja();
  }

  void _salvarComentarioPedido(String id, String comentario) {
    setState(() {
      final indice = _pedidos.indexWhere((p) => p.id == id);
      if (indice == -1) return;
      _pedidos[indice] = _pedidos[indice].copyWith(comentario: comentario);
    });
    _persistirListasLoja();
  }

  void _recusarPedido(String id) {
    setState(() => _pedidos.removeWhere((p) => p.id == id));
    _persistirListasLoja();
  }

  void _salvarCliente(Cliente cliente) {
    setState(() {
      final indice = _clientes.indexWhere((c) => c.id == cliente.id);
      if (indice == -1) {
        _clientes.add(cliente);
      } else {
        _clientes[indice] = cliente;
      }
    });
    _persistirListasLoja();
  }

  void _pagarCliente(String clienteId, double valor) {
    final atualizados = aplicarPagamentoAPrazo(_pedidos, clienteId, valor);
    setState(() {
      _pedidos
        ..clear()
        ..addAll(atualizados);
    });
    _persistirListasLoja();
  }

  void _excluirCliente(String clienteId) {
    setState(() => _clientes.removeWhere((c) => c.id == clienteId));
    _persistirListasLoja();
  }

  Future<void> _abrirPopupClientes() {
    return ClientesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      clientes: _clientes,
      pedidos: _pedidos,
      onSalvar: _salvarCliente,
      onPagar: _pagarCliente,
      onExcluir: _excluirCliente,
    );
  }

  Future<void> _abrirPopupRelatorios() {
    return RelatoriosDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      pedidos: List.of(_pedidos),
    );
  }

  void _abrirPopupImpressora() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final atuais =
        loja?.configuracoesImpressora ?? const ConfiguracoesImpressora();

    ImpressoraDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      configuracoes: atuais,
      onSalvar: (configuracoes) {
        context
            .read<PdvProvider>()
            .atualizarConfiguracoesImpressora(widget.lojaId, configuracoes);
      },
    );
  }

  void _abrirFinanceiro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinanceiroView(
          lojaId: widget.lojaId,
          pedidos: List.of(_pedidos),
        ),
      ),
    );
  }

  void _abrirStatusLoja() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusLojaView(
          lojaId: widget.lojaId,
          lojaOnlineInicial: _lojaOnline,
          aoAlterarOnline: (valor) => setState(() => _lojaOnline = valor),
        ),
      ),
    );
  }

  void _abrirPopupNovaVenda() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final proximoNumero = _pedidos.fold<int>(
          0,
          (maior, pedido) => pedido.numero > maior ? pedido.numero : maior,
        ) +
        1;

    NovaVendaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      categoriasDisponiveis: _categorias,
      gruposDisponiveis: _gruposComponentes,
      obterClientes: () => _clientes,
      aoAbrirClientes: _abrirPopupClientes,
      nomeVendedor: loja?.nome ?? '',
      cnpjVendedor: loja?.cnpj ?? '',
      proximoNumero: proximoNumero,
      onConcluir: (pedido) {
        setState(() {
          _pedidos.add(pedido);
          _abaPedidos = AbaPedidos.aceitos;
        });
        _persistirListasLoja();
      },
      aoCriarItem: (item, categoriaIds, grupoIds) async {
        setState(() => _itens.add(item));
        _sincronizarVinculosItem(item.id, categoriaIds, grupoIds);
        _persistirListasLoja();
      },
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

  void _sincronizarVinculosItem(
    String itemId,
    List<String> categoriaIds,
    List<String> grupoIds,
  ) {
    setState(() {
      for (var i = 0; i < _categorias.length; i++) {
        final categoria = _categorias[i];
        final deveConter = categoriaIds.contains(categoria.id);
        final contem = categoria.itemIds.contains(itemId);
        if (deveConter && !contem) {
          _categorias[i] =
              categoria.copyWith(itemIds: [...categoria.itemIds, itemId]);
        } else if (!deveConter && contem) {
          _categorias[i] = categoria.copyWith(
            itemIds:
                categoria.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }

      for (var i = 0; i < _gruposComponentes.length; i++) {
        final grupo = _gruposComponentes[i];
        final deveConter = grupoIds.contains(grupo.id);
        final contem = grupo.itemIds.contains(itemId);
        if (deveConter && !contem) {
          _gruposComponentes[i] =
              grupo.copyWith(itemIds: [...grupo.itemIds, itemId]);
        } else if (!deveConter && contem) {
          _gruposComponentes[i] = grupo.copyWith(
            itemIds: grupo.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }
    });
  }

  void _abrirPopupNovoItem() {
    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      onCriar: (item, categoriaIds, grupoIds) {
        setState(() => _itens.add(item));
        _sincronizarVinculosItem(item.id, categoriaIds, grupoIds);
        _persistirListasLoja();
      },
    );
  }

  void _abrirPopupEditarItem(ItemLoja item) {
    final categoriaIdsIniciais = _categorias
        .where((c) => c.itemIds.contains(item.id))
        .map((c) => c.id)
        .toList();
    final grupoIdsIniciais = _gruposComponentes
        .where((g) => g.itemIds.contains(item.id))
        .map((g) => g.id)
        .toList();

    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      itemParaEditar: item,
      categoriaIdsIniciais: categoriaIdsIniciais,
      grupoIdsIniciais: grupoIdsIniciais,
      onCriar: (itemEditado, categoriaIds, grupoIds) {
        setState(() {
          final indice = _itens.indexWhere((i) => i.id == itemEditado.id);
          if (indice != -1) _itens[indice] = itemEditado;
        });
        _sincronizarVinculosItem(itemEditado.id, categoriaIds, grupoIds);
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

  void _editarNomeCategoria(String id, String novoNome) {
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == id);
      if (indice == -1) return;
      _categorias[indice] = _categorias[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();
  }

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
      if (_categoriaExpandidaId == id) _categoriaExpandidaId = null;
    });
    _persistirListasLoja();
  }

  void _removerItem(String id) {
    setState(() {
      _itens.removeWhere((item) => item.id == id);

      for (var i = 0; i < _categorias.length; i++) {
        if (_categorias[i].itemIds.contains(id)) {
          _categorias[i] = _categorias[i].copyWith(
            itemIds:
                _categorias[i].itemIds.where((itemId) => itemId != id).toList(),
          );
        }
      }

      for (var i = 0; i < _gruposComponentes.length; i++) {
        if (_gruposComponentes[i].itemIds.contains(id)) {
          _gruposComponentes[i] = _gruposComponentes[i].copyWith(
            itemIds: _gruposComponentes[i]
                .itemIds
                .where((itemId) => itemId != id)
                .toList(),
          );
        }
      }
    });
    _persistirListasLoja();
  }

  void _removerGrupoComponentes(String id) {
    setState(() {
      _gruposComponentes.removeWhere((grupo) => grupo.id == id);
      if (_grupoExpandidoId == id) _grupoExpandidoId = null;

      for (var i = 0; i < _categorias.length; i++) {
        if (_categorias[i].grupoIds.contains(id)) {
          _categorias[i] = _categorias[i].copyWith(
            grupoIds:
                _categorias[i].grupoIds.where((gId) => gId != id).toList(),
          );
        }
      }
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
    _clientes.addAll(loja?.clientesLoja ?? []);
    _pedidos.addAll(loja?.pedidosLoja ?? []);
  }

  @override
  void dispose() {
    _controllers.dispose();
    _controllersBancarios.dispose();
    _controllersUsuarios.dispose();
    _controllersDelivery.dispose();
    _pesquisaItens.dispose();
    _pesquisaCategorias.dispose();
    _pesquisaGrupos.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthProvider>().sair();
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

  Widget _campoDePesquisa(
    AppTheme theme,
    TextEditingController controller,
    String dica,
  ) {
    return TextField(
      controller: controller,
      style: theme.getTextStyle(fontSize: 13),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: dica,
        hintStyle: theme.getTextStyle(
          fontSize: 13,
          color: theme.secondaryTextColor,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: theme.secondaryTextColor,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
    );
  }

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

  Widget _construirCategoria(AppTheme theme, CategoriaLoja categoria) {
    return CategoriaLojaContainer(
      key: _chaveCategoria(categoria.id),
      theme: theme,
      nome: categoria.nome,
      preco: categoria.preco,
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

  Widget _listaCategorias(AppTheme theme, List<CategoriaLoja> categorias) {
    if (categorias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: _categorias.isEmpty
              ? 'Nenhuma categoria criada ainda.'
              : 'Nenhuma categoria encontrada.',
        ),
      );
    }

    if (_categoriaExpandidaId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 8),
            itemCount: categorias.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _construirCategoria(theme, categorias[index]),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final categoria in categorias) ...[
          _construirCategoria(theme, categoria),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

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

  Widget _listaGrupos(AppTheme theme, List<GrupoComponentesLoja> grupos) {
    if (grupos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: _gruposComponentes.isEmpty
              ? 'Nenhum grupo de componentes criado ainda.'
              : 'Nenhum grupo de componentes encontrado.',
        ),
      );
    }

    if (_grupoExpandidoId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 8),
            itemCount: grupos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _construirGrupo(theme, grupos[index]),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final grupo in grupos) ...[
          _construirGrupo(theme, grupo),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _abaLoja(AppTheme theme) {
    final termoItens = _pesquisaItens.text.trim().toLowerCase();
    final termoCategorias = _pesquisaCategorias.text.trim().toLowerCase();
    final termoGrupos = _pesquisaGrupos.text.trim().toLowerCase();

    final itensFiltrados = termoItens.isEmpty
        ? _itens
        : _itens
            .where((i) => i.nome.toLowerCase().contains(termoItens))
            .toList();

    final categoriasFiltradas = termoCategorias.isEmpty
        ? _categorias
        : _categorias
            .where((c) => c.nome.toLowerCase().contains(termoCategorias))
            .toList();

    final gruposFiltrados = termoGrupos.isEmpty
        ? _gruposComponentes
        : _gruposComponentes
            .where((g) => g.nome.toLowerCase().contains(termoGrupos))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDeSecao(theme, 'Itens'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaItens,
            'Pesquisar itens...',
          ),
          const SizedBox(height: 12),
          if (itensFiltrados.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itensFiltrados.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = itensFiltrados[index];
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
          else if (_itens.isEmpty)
            _textoListaVazia(theme, 'Nenhum item criado ainda.')
          else
            _textoListaVazia(theme, 'Nenhum item encontrado.'),

          const SizedBox(height: 24),
          _tituloDeSecao(theme, 'Categorias'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaCategorias,
            'Pesquisar categorias...',
          ),
          const SizedBox(height: 12),
          _listaCategorias(theme, categoriasFiltradas),

          const SizedBox(height: 24),
          _tituloDeSecao(theme, 'Grupos de Componentes'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaGrupos,
            'Pesquisar grupos...',
          ),
          const SizedBox(height: 12),
          _listaGrupos(theme, gruposFiltrados),
        ],
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvarDadosLoja,
                      child: Text(
                        'Salvar Dados',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
        return _abaLoja(theme);

      case AbaLoja.gestao:
        return GestaoLojaContainer(
          theme: theme,
          lojaOnline: _lojaOnline,
          aoAlterarOnline: (valor) => setState(() => _lojaOnline = valor),
          abaPedidos: _abaPedidos,
          aoTrocarAbaPedidos: (aba) => setState(() => _abaPedidos = aba),
          pedidos: _pedidos,
          aoAceitar: (id) => _alterarStatusPedido(id, StatusPedido.aceito),
          aoRecusar: _recusarPedido,
          aoConcluir: (id) => _alterarStatusPedido(id, StatusPedido.concluido),
          aoSalvarComentario: _salvarComentarioPedido,
          aoNovaVenda: _abrirPopupNovaVenda,
          aoClientes: _abrirPopupClientes,
          aoRelatorios: _abrirPopupRelatorios,
          aoImpressora: _abrirPopupImpressora,
          aoFinanceiro: _abrirFinanceiro,
          aoStatus: _abrirStatusLoja,
        );

      case AbaLoja.interface:
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