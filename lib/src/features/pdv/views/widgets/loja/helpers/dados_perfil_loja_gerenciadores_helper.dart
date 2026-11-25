import 'package:nous/src/features/pdv/views/widgets/loja/dados_perfil_loja_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_anexos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_catalogo_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_clientes_fornecedores_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_dialogs_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_membros_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/gerenciador_mesas_loja.dart';

class DadosPerfilLojaGerenciadoresHelper {
  static void inicializar(DadosPerfilLojaController c) {
    c.gerenciadorMesas = GerenciadorMesasLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterMesas: () => c.mesas,
      obterCategorias: () => c.categorias,
      obterItens: () => c.itens,
      obterGrupos: () => c.gruposComponentes,
      obterClientes: () => c.clientes,
      obterPedidos: () => c.pedidos,
      obterMovimentos: () => c.movimentosEstoque,
      obterCpfLogado: () => c.cpfLogado,
      obterNomeLogado: () => c.nomeLogado,
      setState: (fn) => c.setState(fn),
      aoPersistir: c.persistirListasLoja,
      registrarAcao: c.registrarAcao,
      salvarCliente: c.salvarCliente,
      confirmarExclusao: c.dialogoConfirmarExclusao,
      formatarNumeroPedido: DadosPerfilLojaController.numeroPedido,
      formatarValor: DadosPerfilLojaController.valorFormatado,
      formatarQuantidade: DadosPerfilLojaController.formatarQuantidade,
    );

    c.gerenciadorCatalogo = GerenciadorCatalogoLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterItens: () => c.itens,
      obterCategorias: () => c.categorias,
      obterGrupos: () => c.gruposComponentes,
      obterMovimentos: () => c.movimentosEstoque,
      obterCpfLogado: () => c.cpfLogado,
      obterNomeLogado: () => c.nomeLogado,
      podeEditarAbaLoja: c.podeEditarAbaLoja,
      avisarSemPermissao: c.avisarSemPermissao,
      setState: (fn) => c.setState(fn),
      aoPersistir: c.persistirListasLoja,
      registrarAcao: c.registrarAcao,
      confirmarExclusao: c.dialogoConfirmarExclusao,
      rotuloUnidadeCurto: DadosPerfilLojaController.rotuloUnidadeCurto,
      formatarQuantidade: DadosPerfilLojaController.formatarQuantidade,
      obterCategoriaExpandidaId: () => c.categoriaExpandidaId,
      definirCategoriaExpandidaId: (id) =>
          c.setState(() => c.categoriaExpandidaId = id),
      obterGrupoExpandidoId: () => c.grupoExpandidoId,
      definirGrupoExpandidoId: (id) =>
          c.setState(() => c.grupoExpandidoId = id),
      abrirPopupNovoMovimento: c.abrirPopupNovoMovimento,
    );

    c.gerenciadorPedidos = GerenciadorPedidosLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterPedidos: () => c.pedidos,
      obterItens: () => c.itens,
      obterMovimentos: () => c.movimentosEstoque,
      obterCpfLogado: () => c.cpfLogado,
      obterNomeLogado: () => c.nomeLogado,
      obterTempoConclusaoMinutos: () => c.tempoConclusaoMinutos,
      setState: (fn) => c.setState(fn),
      aoPersistir: c.persistirListasLoja,
      registrarAcao: c.registrarAcao,
      formatarNumeroPedido: DadosPerfilLojaController.numeroPedido,
      formatarValor: DadosPerfilLojaController.valorFormatado,
      formatarQuantidade: DadosPerfilLojaController.formatarQuantidade,
      rotuloUnidadeCurto: DadosPerfilLojaController.rotuloUnidadeCurto,
      definirAbaPedidos: (aba) => c.setState(() => c.abaPedidos = aba),
    );

    c.gerenciadorMembros = GerenciadorMembrosLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterMembros: () => c.membros,
      definirMembros: (m) => c.setState(() => c.membros = m),
      registrarAcao: c.registrarAcao,
      avisar: c.avisar,
    );

    c.gerenciadorAnexos = GerenciadorAnexosLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterGaleria: () => c.galeria,
      obterArquivos: () => c.arquivos,
      obterMusicas: () => c.musicas,
      obterVideos: () => c.videos,
      obterArquivosAudio: () => c.arquivosAudio,
      obterDescricoesAnexos: () => c.descricoesAnexos,
      definirLogo: (l) => c.logo = l,
      setState: (fn) => c.setState(fn),
      salvarDadosLoja: c.salvarDadosLoja,
      avisarSemPermissao: c.avisarSemPermissao,
    );

    c.gerenciadorClientesFornecedores = GerenciadorClientesFornecedoresLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterClientes: () => c.clientes,
      obterFornecedores: () => c.fornecedores,
      obterPedidos: () => c.pedidos,
      obterCpfLogado: () => c.cpfLogado,
      obterNomeLogado: () => c.nomeLogado,
      podeEditarAbaLoja: c.podeEditarAbaLoja,
      avisarSemPermissao: c.avisarSemPermissao,
      setState: (fn) => c.setState(fn),
      persistirListasLoja: c.persistirListasLoja,
      registrarAcao: c.registrarAcao,
      formatarValor: DadosPerfilLojaController.valorFormatado,
    );

    c.gerenciadorDialogs = GerenciadorDialogsLoja(
      obterContext: c.obterContext,
      estaMontado: c.estaMontado,
      lojaId: c.lojaId,
      obterCpfLogado: () => c.cpfLogado,
      obterNomeLogado: () => c.nomeLogado,
      obterEmailLogado: () => c.emailLogado,
      obterClientes: () => c.clientes,
      obterFornecedores: () => c.fornecedores,
      obterPedidos: () => c.pedidos,
      obterItens: () => c.itens,
      obterCategorias: () => c.categorias,
      obterGruposComponentes: () => c.gruposComponentes,
      obterMovimentosEstoque: () => c.movimentosEstoque,
      obterMesas: () => c.mesas,
      obterMembros: () => c.membros,
      obterLojaOnline: () => c.lojaOnline,
      obterAtalhosTeclado: () => c.atalhosTeclado,
      salvarCliente: c.salvarCliente,
      pagarCliente: c.pagarCliente,
      excluirCliente: c.excluirCliente,
      salvarFornecedor: c.salvarFornecedor,
      excluirFornecedor: c.excluirFornecedor,
      processarConclusaoVenda: c.gerenciadorPedidos.processarConclusaoVenda,
      onEditarItemCompleto: c.gerenciadorCatalogo.abrirPopupEditarItem,
      onCriarItem: c.criarItemNaVenda,
      onExcluirPedido: c.gerenciadorPedidos.excluirPedido,
      onSalvarComentarioPedido: c.gerenciadorPedidos.salvarComentarioPedido,
      registrarAcao: c.registrarAcao,
      persistirListasLoja: c.persistirListasLoja,
      setState: (fn) => c.setState(fn),
      avisarSemPermissao: c.avisarSemPermissao,
      avisar: c.avisar,
      alternarModoBalcao: (ativo) =>
          c.setState(() => c.modoBalcaoAtivo = ativo),
      alternarStatusLojaOnline: c.alternarStatusLojaOnline,
      sairDaLoja: c.gerenciadorMembros.sairDaLoja,
    );
  }
}
