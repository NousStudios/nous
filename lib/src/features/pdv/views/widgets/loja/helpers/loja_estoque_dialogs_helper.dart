import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/estoque_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/movimento_estoque_dialog.dart';

/// Helper coeso para diálogos e operações de estoque e movimentações da loja.
class LojaEstoqueDialogsHelper {
  const LojaEstoqueDialogsHelper._();

  static String _formatarQuantidade(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _rotuloUnidadeCurto(UnidadeItemLoja u) {
    switch (u) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  static Future<void> abrirPopupNovoMovimento({
    required BuildContext Function() obterContext,
    required bool Function() estaMontado,
    required String lojaId,
    required String Function() obterCpfLogado,
    required String Function() obterNomeLogado,
    required List<ItemLoja> Function() obterItens,
    required List<Fornecedor> Function() obterFornecedores,
    required List<MovimentoEstoque> Function() obterMovimentosEstoque,
    required void Function(ItemLoja) onEditarItemCompleto,
    required void Function(TipoAcao, String) registrarAcao,
    required void Function() persistirListasLoja,
    required void Function(VoidCallback) setState,
    required void Function() avisarSemPermissao,
    ItemLoja? itemInicial,
  }) async {
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
            obterItens()[idx] =
                obterItens()[idx].copyWith(precoCusto: custoFormatado);
          }
        }
      }
    });
    persistirListasLoja();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarMovimentoEstoque(movimento, lojaId: lojaId);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'estoque_atualizado',
        'lojaId': lojaId,
        'movimento': movimento.toJson(),
      });
    }

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

  static void removerMovimentoEstoque({
    required BuildContext Function() obterContext,
    required String lojaId,
    required MovimentoEstoque movimento,
    required List<ItemLoja> Function() obterItens,
    required List<MovimentoEstoque> Function() obterMovimentosEstoque,
    required void Function(TipoAcao, String) registrarAcao,
    required void Function() persistirListasLoja,
    required void Function(VoidCallback) setState,
    required void Function() avisarSemPermissao,
  }) {
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
    LojasService.excluirMovimentoEstoqueIndividual(lojaId, movimento.id);
    persistirListasLoja();

    registrarAcao(
      TipoAcao.movimentoEstoqueRemovido,
      'Movimento de "${item.nome}" removido',
    );
  }

  static void abrirPopupEstoque({
    required BuildContext Function() obterContext,
    required String lojaId,
    required List<ItemLoja> Function() obterItens,
    required List<MovimentoEstoque> Function() obterMovimentosEstoque,
    required Future<void> Function({ItemLoja? itemInicial}) onNovoMovimento,
    required void Function(MovimentoEstoque) onRemoverMovimento,
    required void Function() avisarSemPermissao,
    required VoidCallback onAbrirFornecedores,
  }) {
    final context = obterContext();
    EstoqueDialog.mostrar(
      context,
      itens: obterItens(),
      movimentos: obterMovimentosEstoque(),
      podeEditar: context.read<PdvProvider>().possoEditarAbaLoja(lojaId),
      onNovoMovimento: onNovoMovimento,
      onRemoverMovimento: onRemoverMovimento,
      onAvisarSemPermissao: avisarSemPermissao,
      onAbrirFornecedores: () async => onAbrirFornecedores(),
    );
  }
}
