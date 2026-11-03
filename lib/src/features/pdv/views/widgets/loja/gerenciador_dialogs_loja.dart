import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/estoque_dialog.dart';
import 'package:nous/src/features/pdv/views/financeiro_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/status_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/criar_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/movimento_estoque_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios_dialog.dart';

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

  String _valorFormatado(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarQuantidade(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _rotuloUnidadeCurto(UnidadeItemLoja u) {
    switch (u) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

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

  Future<void> abrirPopupRelatorios() {
    final context = obterContext();
    return RelatoriosDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      pedidos: List.of(obterPedidos()),
      autorCpf: obterCpfLogado(),
      autorNome: obterNomeLogado(),
      autorEmail: obterEmailLogado(),
      onExcluirPedido: onExcluirPedido,
      onSalvarComentario: onSalvarComentarioPedido,
      aoAbrirClientes: abrirPopupClienteEspecifico,
    );
  }

  void abrirPopupImpressora() {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoUsarImpressora(lojaId)) {
      avisarSemPermissao();
      return;
    }

    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    final atuais =
        loja?.configuracoesImpressora ?? const ConfiguracoesImpressora();

    ImpressoraDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      configuracoes: atuais,
      onSalvar: (configuracoes) {
        context
            .read<PdvProvider>()
            .atualizarConfiguracoesImpressora(lojaId, configuracoes);
      },
    );
  }

  void abrirFinanceiro() {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoUsarFinanceiro(lojaId)) {
      avisarSemPermissao();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinanceiroView(
          lojaId: lojaId,
          pedidos: List.of(obterPedidos()),
        ),
      ),
    );
  }

  void abrirPopupCaixa() {
    final context = obterContext();
    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    if (loja == null) return;

    CaixaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      lojaNome: loja.nome,
      lojaCnpj: loja.cnpj,
      turnoAberto: loja.turnoCaixaAberto,
      turnosAnteriores: loja.turnosCaixa.where((t) => !t.aberto).toList(),
      pedidosLoja: obterPedidos(),
      configuracoesImpressora: loja.configuracoesImpressora,
      aoAbrirCaixa: (saldoInicial) async {
        await context.read<PdvProvider>().abrirCaixa(
              lojaId,
              saldoInicial,
              cpf: obterCpfLogado(),
              nome: obterNomeLogado(),
            );
        registrarAcao(
          TipoAcao.caixaAberto,
          'Caixa aberto com fundo de ${_valorFormatado(saldoInicial)}',
        );
        setState(() {});
      },
      aoRegistrarMovimento: (tipo, valor, motivo) async {
        await context.read<PdvProvider>().registrarMovimentoCaixa(
              lojaId,
              tipo: tipo,
              valor: valor,
              motivo: motivo,
              cpf: obterCpfLogado(),
              nome: obterNomeLogado(),
            );
        final rotulo =
            tipo == TipoMovimentoCaixa.sangria ? 'Sangria' : 'Suprimento';
        registrarAcao(
          tipo == TipoMovimentoCaixa.sangria
              ? TipoAcao.sangriaRegistrada
              : TipoAcao.suprimentoRegistrado,
          '$rotulo de ${_valorFormatado(valor)} registrado ($motivo)',
        );
        setState(() {});
      },
      aoFecharCaixa: (saldoInformado, observacao) async {
        await context.read<PdvProvider>().fecharCaixa(
              lojaId,
              saldoInformado,
              cpf: obterCpfLogado(),
              nome: obterNomeLogado(),
              observacao: observacao,
            );
        registrarAcao(
          TipoAcao.caixaFechado,
          'Caixa fechado. Saldo informado: ${_valorFormatado(saldoInformado)}',
        );
        setState(() {});
      },
      aoExcluirTurno: (turnoId) async {
        await context.read<PdvProvider>().excluirTurnoCaixa(
              lojaId,
              turnoId,
            );
        registrarAcao(
          TipoAcao.turnoCaixaExcluido,
          'Registro de turno de caixa excluído',
        );
        setState(() {});
      },
    );
  }

  void abrirCriarMesa() {
    final context = obterContext();
    CriarMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      aoSalvar: (novaMesa) {
        setState(() => obterMesas().add(novaMesa));
        persistirListasLoja();
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarMesa(novaMesa);
        }
        registrarAcao(
          TipoAcao.mesaCriada,
          'Mesa "${novaMesa.numero}" cadastrada no salão',
        );
      },
    );
  }

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

  void abrirPopupNovaVenda() {
    final context = obterContext();
    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    final proximoNumero = obterPedidos().fold<int>(
          0,
          (maior, pedido) => pedido.numero > maior ? pedido.numero : maior,
        ) +
        1;

    NovaVendaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: lojaId,
      itensDisponiveis: obterItens(),
      categoriasDisponiveis: obterCategorias(),
      gruposDisponiveis: obterGruposComponentes(),
      obterClientes: obterClientes,
      aoAbrirClientes: abrirPopupClientes,
      nomeVendedor: loja?.nome ?? '',
      cnpjVendedor: loja?.cnpj ?? '',
      proximoNumero: proximoNumero,
      cpfAutor: obterCpfLogado(),
      nomeAutor: obterNomeLogado(),
      configuracoesImpressora:
          loja?.configuracoesImpressora ?? const ConfiguracoesImpressora(),
      movimentosEstoque: obterMovimentosEstoque(),
      onConcluir: processarConclusaoVenda,
      aoCriarItem: onCriarItem,
    );
  }

  Future<void> abrirPopupNovoMovimento({ItemLoja? itemInicial}) async {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarAbaLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    final movimento = await MovimentoEstoqueDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itens: obterItens(),
      fornecedores: obterFornecedores(),
      cpfAutor: obterCpfLogado(),
      nomeAutor: obterNomeLogado(),
      itemInicial: itemInicial,
      onItemAtualizado: (itemAtualizado) {
        setState(() {
          final idx = obterItens().indexWhere((i) => i.id == itemAtualizado.id);
          if (idx != -1) {
            obterItens()[idx] = itemAtualizado;
          }
        });
        persistirListasLoja();
        registrarAcao(
          TipoAcao.itemAtualizado,
          'Dados do item "${itemAtualizado.nome}" atualizados via Movimento de Estoque',
        );
      },
      onEditarItemCompleto: onEditarItemCompleto,
    );

    if (movimento == null) return;
    if (!estaMontado()) return;

    setState(() {
      obterMovimentosEstoque().add(movimento);
      if (movimento.ehEntrada && movimento.custoUnitario > 0) {
        final idx = obterItens().indexWhere((i) => i.id == movimento.itemId);
        if (idx != -1) {
          final custoFormatado =
              movimento.custoUnitario.toStringAsFixed(2).replaceAll('.', ',');
          if (obterItens()[idx].precoCusto != custoFormatado) {
            obterItens()[idx] = obterItens()[idx].copyWith(precoCusto: custoFormatado);
          }
        }
      }
    });
    persistirListasLoja();

    final item = obterItens().firstWhere(
      (i) => i.id == movimento.itemId,
      orElse: () => const ItemLoja(id: '', nome: ''),
    );
    final tipo = movimento.ehEntrada ? 'Entrada' : 'Saída';
    final sufixoFornecedor = movimento.fornecedorNome.isNotEmpty
        ? ' de "${movimento.fornecedorNome}"'
        : '';

    registrarAcao(
      TipoAcao.movimentoEstoqueRegistrado,
      '$tipo$sufixoFornecedor de ${_formatarQuantidade(movimento.quantidade)} '
          '${_rotuloUnidadeCurto(item.unidadeBase)} em "${item.nome}"',
    );
  }

  void removerMovimentoEstoque(MovimentoEstoque movimento) {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarAbaLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    final item = obterItens().firstWhere(
      (i) => i.id == movimento.itemId,
      orElse: () => const ItemLoja(id: '', nome: ''),
    );

    setState(() {
      obterMovimentosEstoque().removeWhere((m) => m.id == movimento.id);
    });
    persistirListasLoja();

    registrarAcao(
      TipoAcao.movimentoEstoqueRemovido,
      'Movimento de "${item.nome}" removido',
    );
  }

  void abrirPopupEstoque() {
    final context = obterContext();
    EstoqueDialog.mostrar(
      context,
      itens: obterItens(),
      movimentos: obterMovimentosEstoque(),
      podeEditar: context.read<PdvProvider>().possoEditarAbaLoja(lojaId),
      onNovoMovimento: abrirPopupNovoMovimento,
      onRemoverMovimento: removerMovimentoEstoque,
      onAvisarSemPermissao: avisarSemPermissao,
      onAbrirFornecedores: abrirPopupFornecedores,
    );
  }

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

  void confirmarExclusao(BuildContext context) {
    if (!context.read<PdvProvider>().possoExcluirLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

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
                    style: theme.getTextStyle(color: theme.dangerColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executarExclusao(BuildContext dialogContext) async {
    final navigator = Navigator.of(dialogContext);

    await dialogContext.read<PdvProvider>().excluirLoja(lojaId);
    if (!dialogContext.mounted) return;

    navigator.pop();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  Future<void> confirmarResetTransacoes(
    BuildContext context,
    AppTheme theme, {
    required VoidCallback onResetConcluido,
  }) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resetar Transações',
                  style: theme.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Esta ação apagará permanentemente todos os registros de vendas, turnos de caixa e pagamentos a trabalhadores desta loja.\n\n'
              'Produtos, categorias, clientes, fornecedores e membros da equipe NÃO serão afetados.\n\n'
              'Tem certeza que deseja continuar?',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.textColor,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Resetar Transações'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;
    if (!context.mounted) return;

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final pdv = context.read<PdvProvider>();

    await pdv.resetarTransacoesLoja(
      lojaId,
      autorCpf: conta?.cpf ?? '',
      autorNome: conta?.nome ?? '',
      autorEmail: auth.emailAtivo ?? '',
    );

    if (!context.mounted) return;
    onResetConcluido();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Registros de transações resetados com sucesso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}
