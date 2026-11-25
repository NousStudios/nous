import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/financeiro_view.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/criar_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios_dialog.dart';

/// Helper coeso para diálogos de vendas, caixa, mesas, relatórios, impressora e financeiro.
class LojaVendasCaixaDialogsHelper {
  const LojaVendasCaixaDialogsHelper._();

  static String _valorFormatado(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static Future<void> abrirPopupRelatorios({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<PedidoLoja> Function() obterPedidos,
    required String Function() obterCpfLogado,
    required String Function() obterNomeLogado,
    required String Function() obterEmailLogado,
    required Future<void> Function(String pedidoId) onExcluirPedido,
    required void Function(String pedidoId, DadosComentario dados)
        onSalvarComentarioPedido,
    required Future<void> Function(String clienteId) aoAbrirClientes,
  }) {
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
      aoAbrirClientes: aoAbrirClientes,
    );
  }

  static void abrirPopupImpressora({
    required BuildContext Function() obterContext,
    required String lojaId,
    required void Function() avisarSemPermissao,
  }) {
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

  static void abrirFinanceiro({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<PedidoLoja> Function() obterPedidos,
    required void Function() avisarSemPermissao,
  }) {
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

  static void abrirPopupCaixa({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<PedidoLoja> Function() obterPedidos,
    required String Function() obterCpfLogado,
    required String Function() obterNomeLogado,
    required void Function(TipoAcao, String) registrarAcao,
    required void Function(VoidCallback) setState,
  }) {
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

  static void abrirCriarMesa({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<MesaLoja> Function() obterMesas,
    required void Function(VoidCallback) setState,
    required void Function() persistirListasLoja,
    required void Function(TipoAcao, String) registrarAcao,
  }) {
    final context = obterContext();
    CriarMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      aoSalvar: (novaMesa) {
        setState(() => obterMesas().add(novaMesa));
        persistirListasLoja();
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarMesa(novaMesa, lojaId: lojaId);
        }
        if (ServidorRedeLocal().ativo) {
          ServidorRedeLocal().notificarTodos({
            'tipo': 'mesa_atualizada',
            'lojaId': lojaId,
            'mesa': novaMesa.toJson(),
          });
        }
        registrarAcao(
          TipoAcao.mesaCriada,
          'Mesa "${novaMesa.numero}" cadastrada no salão',
        );
      },
    );
  }

  static void abrirPopupNovaVenda({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<ItemLoja> Function() obterItens,
    required List<CategoriaLoja> Function() obterCategorias,
    required List<GrupoComponentesLoja> Function() obterGruposComponentes,
    required List<Cliente> Function() obterClientes,
    required List<PedidoLoja> Function() obterPedidos,
    required Future<void> Function() aoAbrirClientes,
    required String Function() obterCpfLogado,
    required String Function() obterNomeLogado,
    required List<MovimentoEstoque> Function() obterMovimentosEstoque,
    required void Function(PedidoLoja, List<MovimentoEstoque>)
        processarConclusaoVenda,
    required Future<void> Function(
      ItemLoja item,
      List<String> catIds,
      List<String> grupIds, [
      double? estoqueInicial,
    ]) onCriarItem,
  }) {
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
      obterPedidos: obterPedidos,
      aoAbrirClientes: aoAbrirClientes,
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
}
