import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
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
import 'package:nous/src/features/pdv/views/dialogs/dialog_confirmar_abertura_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_anexos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_catalogo_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_clientes_fornecedores_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_dialogs_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_membros_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/persistencia_loja_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/sincronizador_estado_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/gerenciador_mesas_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

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
    _inicializarGerenciadores();
  }

  void _inicializarGerenciadores() {
    gerenciadorMesas = GerenciadorMesasLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterMesas: () => mesas,
      obterCategorias: () => categorias,
      obterItens: () => itens,
      obterGrupos: () => gruposComponentes,
      obterClientes: () => clientes,
      obterPedidos: () => pedidos,
      obterMovimentos: () => movimentosEstoque,
      obterCpfLogado: () => cpfLogado,
      obterNomeLogado: () => nomeLogado,
      setState: (fn) => setState(fn),
      aoPersistir: persistirListasLoja,
      registrarAcao: registrarAcao,
      salvarCliente: salvarCliente,
      confirmarExclusao: dialogoConfirmarExclusao,
      formatarNumeroPedido: numeroPedido,
      formatarValor: valorFormatado,
      formatarQuantidade: formatarQuantidade,
    );

    gerenciadorCatalogo = GerenciadorCatalogoLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterItens: () => itens,
      obterCategorias: () => categorias,
      obterGrupos: () => gruposComponentes,
      obterMovimentos: () => movimentosEstoque,
      obterCpfLogado: () => cpfLogado,
      obterNomeLogado: () => nomeLogado,
      podeEditarAbaLoja: podeEditarAbaLoja,
      avisarSemPermissao: avisarSemPermissao,
      setState: (fn) => setState(fn),
      aoPersistir: persistirListasLoja,
      registrarAcao: registrarAcao,
      confirmarExclusao: dialogoConfirmarExclusao,
      rotuloUnidadeCurto: rotuloUnidadeCurto,
      formatarQuantidade: formatarQuantidade,
      obterCategoriaExpandidaId: () => categoriaExpandidaId,
      definirCategoriaExpandidaId: (id) =>
          setState(() => categoriaExpandidaId = id),
      obterGrupoExpandidoId: () => grupoExpandidoId,
      definirGrupoExpandidoId: (id) =>
          setState(() => grupoExpandidoId = id),
      abrirPopupNovoMovimento: abrirPopupNovoMovimento,
    );

    gerenciadorPedidos = GerenciadorPedidosLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterPedidos: () => pedidos,
      obterItens: () => itens,
      obterMovimentos: () => movimentosEstoque,
      obterCpfLogado: () => cpfLogado,
      obterNomeLogado: () => nomeLogado,
      obterTempoConclusaoMinutos: () => tempoConclusaoMinutos,
      setState: (fn) => setState(fn),
      aoPersistir: persistirListasLoja,
      registrarAcao: registrarAcao,
      formatarNumeroPedido: numeroPedido,
      formatarValor: valorFormatado,
      formatarQuantidade: formatarQuantidade,
      rotuloUnidadeCurto: rotuloUnidadeCurto,
      definirAbaPedidos: (aba) => setState(() => abaPedidos = aba),
    );

    gerenciadorMembros = GerenciadorMembrosLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterMembros: () => membros,
      definirMembros: (m) => setState(() => membros = m),
      registrarAcao: registrarAcao,
      avisar: avisar,
    );

    gerenciadorAnexos = GerenciadorAnexosLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterGaleria: () => galeria,
      obterArquivos: () => arquivos,
      obterMusicas: () => musicas,
      obterVideos: () => videos,
      obterArquivosAudio: () => arquivosAudio,
      obterDescricoesAnexos: () => descricoesAnexos,
      definirLogo: (l) => logo = l,
      setState: (fn) => setState(fn),
      salvarDadosLoja: salvarDadosLoja,
      avisarSemPermissao: avisarSemPermissao,
    );

    gerenciadorClientesFornecedores = GerenciadorClientesFornecedoresLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterClientes: () => clientes,
      obterFornecedores: () => fornecedores,
      obterPedidos: () => pedidos,
      obterCpfLogado: () => cpfLogado,
      obterNomeLogado: () => nomeLogado,
      podeEditarAbaLoja: podeEditarAbaLoja,
      avisarSemPermissao: avisarSemPermissao,
      setState: (fn) => setState(fn),
      persistirListasLoja: persistirListasLoja,
      registrarAcao: registrarAcao,
      formatarValor: valorFormatado,
    );

    gerenciadorDialogs = GerenciadorDialogsLoja(
      obterContext: obterContext,
      estaMontado: estaMontado,
      lojaId: lojaId,
      obterCpfLogado: () => cpfLogado,
      obterNomeLogado: () => nomeLogado,
      obterEmailLogado: () => emailLogado,
      obterClientes: () => clientes,
      obterFornecedores: () => fornecedores,
      obterPedidos: () => pedidos,
      obterItens: () => itens,
      obterCategorias: () => categorias,
      obterGruposComponentes: () => gruposComponentes,
      obterMovimentosEstoque: () => movimentosEstoque,
      obterMesas: () => mesas,
      obterMembros: () => membros,
      obterLojaOnline: () => lojaOnline,
      obterAtalhosTeclado: () => atalhosTeclado,
      salvarCliente: salvarCliente,
      pagarCliente: pagarCliente,
      excluirCliente: excluirCliente,
      salvarFornecedor: salvarFornecedor,
      excluirFornecedor: excluirFornecedor,
      processarConclusaoVenda: gerenciadorPedidos.processarConclusaoVenda,
      onEditarItemCompleto: gerenciadorCatalogo.abrirPopupEditarItem,
      onCriarItem: criarItemNaVenda,
      onExcluirPedido: gerenciadorPedidos.excluirPedido,
      onSalvarComentarioPedido: gerenciadorPedidos.salvarComentarioPedido,
      registrarAcao: registrarAcao,
      persistirListasLoja: persistirListasLoja,
      setState: (fn) => setState(fn),
      avisarSemPermissao: avisarSemPermissao,
      avisar: avisar,
      alternarModoBalcao: (ativo) =>
          setState(() => modoBalcaoAtivo = ativo),
      alternarStatusLojaOnline: alternarStatusLojaOnline,
      sairDaLoja: gerenciadorMembros.sairDaLoja,
    );
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

  void avisarSemPermissao() {
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(obterContext()).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Você não tem permissão para fazer isso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  void avisar(String mensagem) {
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(obterContext()).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          mensagem,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  void registrarAcao(TipoAcao tipo, String descricao) {
    final auth = obterContext().read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta == null) return;

    final nomeParaExibir = conta.nomeExibicaoPara(
      cpfVisualizador: conta.cpf,
      reveladoParaDono: auth.dadoEstaReveladoParaDono('nome'),
    );

    final acao = RegistroAcao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataHora: DateTime.now(),
      tipo: tipo,
      descricao: descricao,
      cpfAutor: conta.cpf,
      nomeAutor: nomeParaExibir,
      emailAutor: auth.emailAtivo ?? '',
    );

    obterContext().read<PdvProvider>().registrarAcao(lojaId, acao);
  }

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
  }) async {
    final theme = ThemeController.currentTheme.value;
    final res = await showDialog<bool>(
      context: obterContext(),
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          titulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Excluir',
              style: theme.getTextStyle(color: theme.dangerColor),
            ),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> criarItemNaVenda(
    ItemLoja item,
    List<String> categoriaIds,
    List<String> grupoIds, [
    double? estoqueInicial,
  ]) async {
    setState(() => itens.add(item));
    gerenciadorCatalogo.sincronizarVinculosItem(item.id, categoriaIds, grupoIds);

    if (estoqueInicial != null && estoqueInicial > 0) {
      final custoTexto =
          item.precoCusto.trim().replaceAll('.', '').replaceAll(',', '.');
      final custo = double.tryParse(custoTexto) ?? 0.0;
      final mov = MovimentoEstoque.novo(
        itemId: item.id,
        tipo: TipoMovimentoEstoque.entrada,
        quantidade: estoqueInicial,
        custoUnitario: custo,
        motivo: 'Estoque inicial cadastrado na criação do item',
        cpfAutor: cpfLogado,
        nomeAutor: nomeLogado,
        categoria: CategoriaMovimentoEstoque.ajuste,
      );
      setState(() => movimentosEstoque.add(mov));
    }

    persistirListasLoja();
    registrarAcao(
      TipoAcao.itemCriado,
      'Item "${item.nome}" criado',
    );
  }

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

  void salvarDadosLoja() {
    if (!obterContext().read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    obterContext().read<PdvProvider>().atualizarDadosLoja(
          lojaId,
          nome: controllers.nome.text,
          cnpj: controllers.cnpj.text,
          telefone: controllers.telefone.text,
          endereco: controllers.endereco.text,
          numero: controllers.numero.text,
          email: controllers.email.text,
          redesSociais: controllers.redesSociais.text,
          categorias: controllers.categorias.text,
          tags: controllers.tags.text,
          logo: logo,
        );

    registrarAcao(TipoAcao.dadosLojaAtualizados, 'Dados da loja atualizados');

    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(obterContext()).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Dados salvos.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> alterarLogoLoja() async {
    if (!obterContext().read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    if (logo.isNotEmpty) {
      final theme = ThemeController.currentTheme.value;
      OpcoesImagemDialog.mostrar(
        obterContext(),
        theme: theme,
        titulo: 'Logo da Loja',
        onEscolherNova: gerenciadorAnexos.selecionarNovaLogoLoja,
        onRemover: gerenciadorAnexos.removerLogoLoja,
      );
    } else {
      await gerenciadorAnexos.selecionarNovaLogoLoja();
    }
  }

  Future<void> alternarStatusLojaOnline(bool valor) async {
    final pdv = obterContext().read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(lojaId);

    if (valor && lojaAtual != null && lojaAtual.turnoCaixaAberto == null) {
      final acao = await DialogConfirmarAberturaCaixa.mostrar(
        context: obterContext(),
        theme: ThemeController.currentTheme.value,
        lojaNome: lojaAtual.nome,
      );
      if (acao == AcaoAberturaCaixa.cancelar) {
        return;
      }
      setState(() => lojaOnline = true);
      await pdv.alternarLojaAberta(lojaId, true);
      final atualizada = pdv.buscarPorId(lojaId);
      if (atualizada != null) {
        PersistenciaLojaHelper.notificarLojaAtualizada(atualizada);
      }
      if (acao == AcaoAberturaCaixa.abrirCaixaAgora && estaMontado()) {
        gerenciadorDialogs.abrirPopupCaixa();
      }
      return;
    }

    setState(() => lojaOnline = valor);
    await pdv.alternarLojaAberta(lojaId, valor);
    final lojaNova = pdv.buscarPorId(lojaId);
    if (lojaNova != null) {
      PersistenciaLojaHelper.notificarLojaAtualizada(lojaNova);
    }
  }

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

  void carregarDadosIniciais(Loja? loja) {
    controllers.nome.text = loja?.nome ?? '';
    controllers.cnpj.text = loja?.cnpj ?? '';
    controllers.telefone.text = loja?.telefone ?? '';
    controllers.endereco.text = loja?.endereco ?? '';
    controllers.numero.text = loja?.numero ?? '';
    controllers.email.text = loja?.email ?? '';
    controllers.redesSociais.text = loja?.redesSociais ?? '';
    controllers.categorias.text = loja?.categorias ?? '';
    controllers.tags.text = loja?.tags ?? '';

    logo = loja?.logo ?? '';
    galeria.addAll(loja?.galeria ?? []);
    arquivos.addAll(loja?.arquivos ?? []);
    musicas.addAll(loja?.musicas ?? []);
    videos.addAll(loja?.videos ?? []);
    arquivosAudio.addAll(loja?.arquivosAudio ?? []);
    descricoesAnexos.addAll(loja?.descricoesAnexos ?? {});

    categorias.addAll(loja?.categoriasLoja ?? []);
    itens.addAll(loja?.itensLoja ?? []);
    gruposComponentes.addAll(loja?.gruposComponentesLoja ?? []);
    clientes.addAll(loja?.clientesLoja ?? []);
    fornecedores.addAll(loja?.fornecedoresLoja ?? []);
    pedidos.addAll(loja?.pedidosLoja ?? []);
    movimentosEstoque.addAll(loja?.movimentosEstoque ?? []);
    mesas.addAll(loja?.mesas ?? []);
    membros = List.of(loja?.membros ?? []);
    lojaOnline = loja?.aberta ?? false;
    tempoConclusaoMinutos = loja?.tempoConclusaoMinutos ?? 0;
    sonsAlertas.addAll(loja?.sonsAlertas ?? {});
    atalhosTeclado.addAll(loja?.atalhosTeclado ?? {});
    gerenciadorPedidos.iniciarTimerVerificacaoPedidos();
  }

  void sincronizarComLoja(Loja lojaAtual) {
    SincronizadorEstadoLoja.sincronizar(
      lojaAtual: lojaAtual,
      controllers: controllers,
      movimentosEstoque: movimentosEstoque,
      pedidos: pedidos,
      membros: membros,
      mesas: mesas,
      itens: itens,
      categorias: categorias,
      gruposComponentes: gruposComponentes,
      clientes: clientes,
      fornecedores: fornecedores,
      galeria: galeria,
      musicas: musicas,
      arquivosAudio: arquivosAudio,
      videos: videos,
      arquivos: arquivos,
      descricoesAnexos: descricoesAnexos,
      logoAtual: logo,
      lojaOnlineAtual: lojaOnline,
      tempoConclusaoMinutosAtual: tempoConclusaoMinutos,
      aplicarMudancas: ({
        required onlineMudou,
        required logoMudou,
        required galeriaMudou,
        required musicasMudaram,
        required arquivosAudioMudaram,
        required videosMudaram,
        required arquivosMudaram,
        required descricoesMudaram,
        required tempoConclusaoMudou,
        required movsMudaram,
        required pedidosMudaram,
        required membrosMudaram,
        required mesasMudaram,
        required itensMudaram,
        required categoriasMudaram,
        required gruposMudaram,
        required clientesMudaram,
        required fornecedoresMudaram,
      }) {
        setState(() {
          if (onlineMudou) lojaOnline = lojaAtual.aberta;
          if (logoMudou) logo = lojaAtual.logo;
          if (galeriaMudou) {
            galeria..clear()..addAll(lojaAtual.galeria);
          }
          if (musicasMudaram) {
            musicas..clear()..addAll(lojaAtual.musicas);
          }
          if (arquivosAudioMudaram) {
            arquivosAudio..clear()..addAll(lojaAtual.arquivosAudio);
          }
          if (videosMudaram) {
            videos..clear()..addAll(lojaAtual.videos);
          }
          if (arquivosMudaram) {
            arquivos..clear()..addAll(lojaAtual.arquivos);
          }
          if (descricoesMudaram) {
            descricoesAnexos..clear()..addAll(lojaAtual.descricoesAnexos);
          }
          if (tempoConclusaoMudou) {
            tempoConclusaoMinutos = lojaAtual.tempoConclusaoMinutos;
          }
          if (movsMudaram) {
            movimentosEstoque..clear()..addAll(lojaAtual.movimentosEstoque);
          }
          if (pedidosMudaram) {
            pedidos..clear()..addAll(lojaAtual.pedidosLoja);
          }
          if (membrosMudaram) {
            membros = List.of(lojaAtual.membros);
          }
          if (mesasMudaram) {
            mesas..clear()..addAll(lojaAtual.mesas);
          }
          if (itensMudaram) {
            itens..clear()..addAll(lojaAtual.itensLoja);
          }
          if (categoriasMudaram) {
            categorias..clear()..addAll(lojaAtual.categoriasLoja);
          }
          if (gruposMudaram) {
            gruposComponentes..clear()..addAll(lojaAtual.gruposComponentesLoja);
          }
          if (clientesMudaram) {
            clientes..clear()..addAll(lojaAtual.clientesLoja);
          }
          if (fornecedoresMudaram) {
            fornecedores..clear()..addAll(lojaAtual.fornecedoresLoja);
          }
        });
      },
    );
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(tratarTecladoGlobal);
    ChatService.alteracoesChatNotifier.removeListener(verificarMensagensNaoLidasLoja);
    gerenciadorPedidos.cancelarTimer();
    controllers.dispose();
    pesquisaItens.dispose();
    pesquisaCategorias.dispose();
    pesquisaGrupos.dispose();
    scrollCategorias.dispose();
    scrollGrupos.dispose();
  }
}
