import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_anexos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_catalogo_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_clientes_fornecedores_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_dialogs_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_membros_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/dados_perfil_loja_acoes_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/dados_perfil_loja_gerenciadores_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/dados_perfil_loja_sync_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/persistencia_loja_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/gerenciador_mesas_loja.dart';

class DadosPerfilLojaController {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final void Function(void Function()) setState;

  final controllers = ControllersDadosLoja();
  final pesquisaItens = TextEditingController();
  final pesquisaCategorias = TextEditingController();
  final pesquisaGrupos = TextEditingController();
  final scrollCategorias = ScrollController();
  final scrollGrupos = ScrollController();

  String logo = '';
  final List<String> galeria = [];
  final List<String> arquivos = [];
  final List<String> musicas = [];
  final List<String> videos = [];
  final List<String> arquivosAudio = [];
  final Map<String, String> descricoesAnexos = {};

  final List<CategoriaLoja> categorias = [];
  final List<ItemLoja> itens = [];
  final List<GrupoComponentesLoja> gruposComponentes = [];
  final List<Cliente> clientes = [];
  final List<Fornecedor> fornecedores = [];
  final List<PedidoLoja> pedidos = [];
  final List<MovimentoEstoque> movimentosEstoque = [];
  final List<MesaLoja> mesas = [];
  List<MembroLoja> membros = [];

  bool lojaOnline = false;
  AbaPedidos abaPedidos = AbaPedidos.novos;
  int tempoConclusaoMinutos = 0;
  final Map<String, String> sonsAlertas = {};
  final Map<String, String> atalhosTeclado = {};

  bool modoBalcaoAtivo = false;
  bool temNovasMensagensLoja = false;
  String? categoriaExpandidaId;
  String? grupoExpandidoId;
  bool tentouGarantirDono = false;
  bool tecladoFisicoDetectado = false;

  late final GerenciadorMesasLoja gerenciadorMesas;
  late final GerenciadorCatalogoLoja gerenciadorCatalogo;
  late final GerenciadorPedidosLoja gerenciadorPedidos;
  late final GerenciadorMembrosLoja gerenciadorMembros;
  late final GerenciadorAnexosLoja gerenciadorAnexos;
  late final GerenciadorClientesFornecedoresLoja gerenciadorClientesFornecedores;
  late final GerenciadorDialogsLoja gerenciadorDialogs;

  DadosPerfilLojaController({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.setState,
  }) {
    DadosPerfilLojaGerenciadoresHelper.inicializar(this);
  }

  String get cpfLogado =>
      obterContext().read<AuthProvider>().contaAtual?.cpf ?? '';

  String get nomeLogado {
    final auth = obterContext().read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta == null) return '';
    return conta.nomeExibicaoPara(
      cpfVisualizador: conta.cpf,
      reveladoParaDono: auth.dadoEstaReveladoParaDono('nome'),
    );
  }

  String get emailLogado =>
      obterContext().read<AuthProvider>().emailAtivo ?? '';

  static String valorFormatado(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static String numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

  static String formatarQuantidade(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String rotuloUnidadeCurto(UnidadeItemLoja u) {
    switch (u) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  bool podeEditarAbaLoja() =>
      obterContext().read<PdvProvider>().possoEditarAbaLoja(lojaId);

  void avisarSemPermissao() => DadosPerfilLojaAcoesHelper.avisar(
        obterContext(),
        'Você não tem permissão para fazer isso.',
      );

  void avisar(String mensagem) =>
      DadosPerfilLojaAcoesHelper.avisar(obterContext(), mensagem);

  void registrarAcao(TipoAcao tipo, String descricao) =>
      DadosPerfilLojaAcoesHelper.registrarAcao(this, tipo, descricao);

  void persistirListasLoja() {
    PersistenciaLojaHelper.persistirListasLoja(
      pdv: obterContext().read<PdvProvider>(),
      lojaId: lojaId,
      categorias: categorias,
      itens: itens,
      gruposComponentes: gruposComponentes,
      clientes: clientes,
      fornecedores: fornecedores,
      pedidos: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
    );
  }

  Future<bool> dialogoConfirmarExclusao({
    required String titulo,
    required String mensagem,
  }) =>
      DadosPerfilLojaAcoesHelper.dialogoConfirmarExclusao(
        context: obterContext(),
        titulo: titulo,
        mensagem: mensagem,
      );

  Future<void> criarItemNaVenda(
    ItemLoja item,
    List<String> categoriaIds,
    List<String> grupoIds, [
    double? estoqueInicial,
  ]) =>
      DadosPerfilLojaAcoesHelper.criarItemNaVenda(
        this,
        item,
        categoriaIds,
        grupoIds,
        estoqueInicial,
      );

  void salvarCliente(Cliente c) =>
      gerenciadorClientesFornecedores.salvarCliente(c);

  void pagarCliente(String cId, double v, String fp) =>
      gerenciadorClientesFornecedores.pagarCliente(cId, v, fp);

  void excluirCliente(String cId) =>
      gerenciadorClientesFornecedores.excluirCliente(cId);

  void salvarFornecedor(Fornecedor f) =>
      gerenciadorClientesFornecedores.salvarFornecedor(f);

  void excluirFornecedor(String fId) =>
      gerenciadorClientesFornecedores.excluirFornecedor(fId);

  Future<void> abrirPopupNovoMovimento({ItemLoja? itemInicial}) =>
      gerenciadorDialogs.abrirPopupNovoMovimento(itemInicial: itemInicial);

  void alternarExpansaoCategoria(String id) {
    final vaiExpandir = categoriaExpandidaId != id;
    setState(() => categoriaExpandidaId = vaiExpandir ? id : null);
    if (vaiExpandir && scrollCategorias.hasClients) {
      scrollCategorias.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void alternarExpansaoGrupo(String id) {
    final vaiExpandir = grupoExpandidoId != id;
    setState(() => grupoExpandidoId = vaiExpandir ? id : null);
    if (vaiExpandir && scrollGrupos.hasClients) {
      scrollGrupos.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void salvarDadosLoja() => DadosPerfilLojaAcoesHelper.salvarDadosLoja(this);

  Future<void> alterarLogoLoja() =>
      DadosPerfilLojaAcoesHelper.alterarLogoLoja(this);

  Future<void> alternarStatusLojaOnline(bool valor) =>
      DadosPerfilLojaAcoesHelper.alternarStatusLojaOnline(this, valor);

  Future<void> verificarMensagensNaoLidasLoja() async {
    final tem = await ChatService.temMensagensNaoLidasNaLoja(lojaId);
    if (estaMontado() && tem != temNovasMensagensLoja) {
      setState(() => temNovasMensagensLoja = tem);
    }
  }

  bool tratarTecladoGlobal(KeyEvent event) {
    if (!tecladoFisicoDetectado) {
      tecladoFisicoDetectado = true;
      if (estaMontado()) setState(() {});
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      JanelaWindowsService.alternarTelaCheia();
      return true;
    }
    return false;
  }

  void carregarDadosIniciais(Loja? loja) =>
      DadosPerfilLojaSyncHelper.carregarDadosIniciais(this, loja);

  void sincronizarComLoja(Loja lojaAtual) =>
      DadosPerfilLojaSyncHelper.sincronizarComLoja(this, lojaAtual);

  void dispose() {
    HardwareKeyboard.instance.removeHandler(tratarTecladoGlobal);
    ChatService.alteracoesChatNotifier
        .removeListener(verificarMensagensNaoLidasLoja);
    gerenciadorPedidos.cancelarTimer();
    controllers.dispose();
    pesquisaItens.dispose();
    pesquisaCategorias.dispose();
    pesquisaGrupos.dispose();
    scrollCategorias.dispose();
    scrollGrupos.dispose();
  }
}
