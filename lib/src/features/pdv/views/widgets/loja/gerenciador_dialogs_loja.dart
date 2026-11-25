import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/status_loja_view.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/loja_acoes_criticas_dialogs_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/loja_estoque_dialogs_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/loja_vendas_caixa_dialogs_helper.dart';

/// Centraliza a abertura e coordenação de diálogos e popups da loja PDV.
class GerenciadorDialogsLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;

  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final String Function() obterEmailLogado;

  final List<Cliente> Function() obterClientes;
  final List<Fornecedor> Function() obterFornecedores;
  final List<PedidoLoja> Function() obterPedidos;
  final List<ItemLoja> Function() obterItens;
  final List<CategoriaLoja> Function() obterCategorias;
  final List<GrupoComponentesLoja> Function() obterGruposComponentes;
  final List<MovimentoEstoque> Function() obterMovimentosEstoque;
  final List<MesaLoja> Function() obterMesas;
  final List<MembroLoja> Function() obterMembros;
  final bool Function() obterLojaOnline;
  final Map<String, String> Function() obterAtalhosTeclado;

  final void Function(Cliente) salvarCliente;
  final void Function(String clienteId, double valor, String formaPagamento) pagarCliente;
  final void Function(String clienteId) excluirCliente;
  final void Function(Fornecedor) salvarFornecedor;
  final void Function(String fornecedorId) excluirFornecedor;
  final void Function(PedidoLoja, List<MovimentoEstoque>) processarConclusaoVenda;
  final void Function(ItemLoja) onEditarItemCompleto;
  final Future<void> Function(ItemLoja item, List<String> catIds, List<String> grupIds, [double? estoqueInicial]) onCriarItem;
  final Future<void> Function(String pedidoId) onExcluirPedido;
  final void Function(String pedidoId, DadosComentario dados) onSalvarComentarioPedido;

  final void Function(TipoAcao, String) registrarAcao;
  final void Function() persistirListasLoja;
  final void Function(VoidCallback) setState;
  final void Function() avisarSemPermissao;
  final void Function(String) avisar;
  final void Function(bool) alternarModoBalcao;
  final Future<void> Function(bool) alternarStatusLojaOnline;
  final Future<void> Function() sairDaLoja;

  const GerenciadorDialogsLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.obterEmailLogado,
    required this.obterClientes,
    required this.obterFornecedores,
    required this.obterPedidos,
    required this.obterItens,
    required this.obterCategorias,
    required this.obterGruposComponentes,
    required this.obterMovimentosEstoque,
    required this.obterMesas,
    required this.obterMembros,
    required this.obterLojaOnline,
    required this.obterAtalhosTeclado,
    required this.salvarCliente,
    required this.pagarCliente,
    required this.excluirCliente,
    required this.salvarFornecedor,
    required this.excluirFornecedor,
    required this.processarConclusaoVenda,
    required this.onEditarItemCompleto,
    required this.onCriarItem,
    required this.onExcluirPedido,
    required this.onSalvarComentarioPedido,
    required this.registrarAcao,
    required this.persistirListasLoja,
    required this.setState,
    required this.avisarSemPermissao,
    required this.avisar,
    required this.alternarModoBalcao,
    required this.alternarStatusLojaOnline,
    required this.sairDaLoja,
  });

  Future<void> abrirPopupClientes() {
    final context = obterContext();
    return ClientesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      clientes: obterClientes(),
      pedidos: obterPedidos(),
      onSalvar: salvarCliente,
      onPagar: pagarCliente,
      onExcluir: excluirCliente,
    );
  }

  Future<void> abrirPopupClienteEspecifico(String clienteId) {
    final context = obterContext();
    return ClientesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      clientes: obterClientes(),
      pedidos: obterPedidos(),
      onSalvar: salvarCliente,
      onPagar: pagarCliente,
      onExcluir: excluirCliente,
      clienteInicialId: clienteId,
    );
  }

  Future<void> abrirPopupFornecedores() {
    final context = obterContext();
    return FornecedoresDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      clientes: obterClientes(),
      fornecedores: obterFornecedores(),
      onSalvar: salvarFornecedor,
      onExcluir: excluirFornecedor,
    );
  }

  Future<void> abrirPopupRelatorios() =>
      LojaVendasCaixaDialogsHelper.abrirPopupRelatorios(
        obterContext: obterContext,
        lojaId: lojaId,
        obterPedidos: obterPedidos,
        obterCpfLogado: obterCpfLogado,
        obterNomeLogado: obterNomeLogado,
        obterEmailLogado: obterEmailLogado,
        onExcluirPedido: onExcluirPedido,
        onSalvarComentarioPedido: onSalvarComentarioPedido,
        aoAbrirClientes: abrirPopupClienteEspecifico,
      );

  void abrirPopupImpressora() =>
      LojaVendasCaixaDialogsHelper.abrirPopupImpressora(
        obterContext: obterContext,
        lojaId: lojaId,
        avisarSemPermissao: avisarSemPermissao,
      );

  void abrirFinanceiro() => LojaVendasCaixaDialogsHelper.abrirFinanceiro(
        obterContext: obterContext,
        lojaId: lojaId,
        obterPedidos: obterPedidos,
        avisarSemPermissao: avisarSemPermissao,
      );

  void abrirPopupCaixa() => LojaVendasCaixaDialogsHelper.abrirPopupCaixa(
        obterContext: obterContext,
        lojaId: lojaId,
        obterPedidos: obterPedidos,
        obterCpfLogado: obterCpfLogado,
        obterNomeLogado: obterNomeLogado,
        registrarAcao: registrarAcao,
        setState: setState,
      );

  void abrirCriarMesa() => LojaVendasCaixaDialogsHelper.abrirCriarMesa(
        obterContext: obterContext,
        lojaId: lojaId,
        obterMesas: obterMesas,
        setState: setState,
        persistirListasLoja: persistirListasLoja,
        registrarAcao: registrarAcao,
      );

  void abrirStatusLoja() {
    final context = obterContext();
    final cpfLogado = context.read<AuthProvider>().contaAtual?.cpf ?? '';
    final meuPapel = context.read<PdvProvider>().meuPapel(lojaId);
    final ehLojaColetiva = lojaId == PdvProvider.idLojaColetivaNous;
    final podeSair = !ehLojaColetiva && meuPapel != null;

    final lojaAtual = context.read<PdvProvider>().buscarPorId(lojaId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusLojaView(
          lojaId: lojaId,
          lojaOnlineInicial: lojaAtual?.aberta ?? obterLojaOnline(),
          aoAlterarOnline: alternarStatusLojaOnline,
          membros: List.of(obterMembros()),
          cpfLogado: cpfLogado,
          podeSair: podeSair,
          onSair: sairDaLoja,
        ),
      ),
    );
  }

  void abrirPopupNovaVenda() =>
      LojaVendasCaixaDialogsHelper.abrirPopupNovaVenda(
        obterContext: obterContext,
        lojaId: lojaId,
        obterItens: obterItens,
        obterCategorias: obterCategorias,
        obterGruposComponentes: obterGruposComponentes,
        obterClientes: obterClientes,
        obterPedidos: obterPedidos,
        aoAbrirClientes: abrirPopupClientes,
        obterCpfLogado: obterCpfLogado,
        obterNomeLogado: obterNomeLogado,
        obterMovimentosEstoque: obterMovimentosEstoque,
        processarConclusaoVenda: processarConclusaoVenda,
        onCriarItem: onCriarItem,
      );

  Future<void> abrirPopupNovoMovimento({ItemLoja? itemInicial}) =>
      LojaEstoqueDialogsHelper.abrirPopupNovoMovimento(
        obterContext: obterContext,
        estaMontado: estaMontado,
        lojaId: lojaId,
        obterCpfLogado: obterCpfLogado,
        obterNomeLogado: obterNomeLogado,
        obterItens: obterItens,
        obterFornecedores: obterFornecedores,
        obterMovimentosEstoque: obterMovimentosEstoque,
        onEditarItemCompleto: onEditarItemCompleto,
        registrarAcao: registrarAcao,
        persistirListasLoja: persistirListasLoja,
        setState: setState,
        avisarSemPermissao: avisarSemPermissao,
        itemInicial: itemInicial,
      );

  void removerMovimentoEstoque(MovimentoEstoque movimento) =>
      LojaEstoqueDialogsHelper.removerMovimentoEstoque(
        obterContext: obterContext,
        lojaId: lojaId,
        movimento: movimento,
        obterItens: obterItens,
        obterMovimentosEstoque: obterMovimentosEstoque,
        registrarAcao: registrarAcao,
        persistirListasLoja: persistirListasLoja,
        setState: setState,
        avisarSemPermissao: avisarSemPermissao,
      );

  void abrirPopupEstoque() => LojaEstoqueDialogsHelper.abrirPopupEstoque(
        obterContext: obterContext,
        lojaId: lojaId,
        obterItens: obterItens,
        obterMovimentosEstoque: obterMovimentosEstoque,
        onNovoMovimento: abrirPopupNovoMovimento,
        onRemoverMovimento: removerMovimentoEstoque,
        avisarSemPermissao: avisarSemPermissao,
        onAbrirFornecedores: abrirPopupFornecedores,
      );

  void abrirMensagensLoja() {
    final context = obterContext();
    final pdv = context.read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(lojaId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: true,
          lojaId: lojaId,
          nomeLoja: lojaAtual?.nome ?? '',
          logoLoja: lojaAtual?.logo ?? '',
          operadorNome: obterNomeLogado(),
          operadorCpf: obterCpfLogado(),
        ),
      ),
    );
  }

  void abrirPerfilPublicoLoja() {
    final context = obterContext();
    final pdv = context.read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(lojaId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VitrineLojaView(
          lojaId: lojaId,
          lojaFallback: lojaAtual,
        ),
      ),
    );
  }

  void executarAcaoPorNome(String acao) {
    switch (acao) {
      case 'Nova Venda':
        abrirPopupNovaVenda();
        break;
      case 'Clientes':
        abrirPopupClientes();
        break;
      case 'Mensagens':
        abrirMensagensLoja();
        break;
      case 'Caixa':
        abrirPopupCaixa();
        break;
      case 'Relatórios':
        abrirPopupRelatorios();
        break;
      case 'Impressora':
        abrirPopupImpressora();
        break;
      case 'Financeiro':
        abrirFinanceiro();
        break;
      case 'Status da Loja':
        abrirStatusLoja();
        break;
      case 'Perfil Público':
        abrirPerfilPublicoLoja();
        break;
      case 'Modo Balcão':
        alternarModoBalcao(true);
        break;
      case 'Tela Cheia':
        JanelaWindowsService.alternarTelaCheia();
        break;
    }
  }

  String obterAcaoPorTecla(String tecla) {
    if (tecla == 'F11') {
      return 'Tela Cheia';
    }
    final atalhos = obterAtalhosTeclado();
    if (atalhos.containsKey(tecla)) {
      return atalhos[tecla]!;
    }
    final context = obterContext();
    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    if (loja != null && loja.atalhosTeclado.containsKey(tecla)) {
      return loja.atalhosTeclado[tecla]!;
    }
    return 'Desativado';
  }

  void executarAcaoAtalho(String tecla) {
    if (tecla == 'F11') {
      JanelaWindowsService.alternarTelaCheia();
      return;
    }
    final acao = obterAcaoPorTecla(tecla);
    if (acao != 'Desativado') {
      executarAcaoPorNome(acao);
    }
  }

  void confirmarExclusao(BuildContext context) =>
      LojaAcoesCriticasDialogsHelper.confirmarExclusao(
        context: context,
        lojaId: lojaId,
        avisarSemPermissao: avisarSemPermissao,
      );

  Future<void> confirmarResetTransacoes(
    BuildContext context,
    AppTheme theme, {
    required VoidCallback onResetConcluido,
  }) =>
      LojaAcoesCriticasDialogsHelper.confirmarResetTransacoes(
        context: context,
        theme: theme,
        lojaId: lojaId,
        onResetConcluido: onResetConcluido,
      );
}
