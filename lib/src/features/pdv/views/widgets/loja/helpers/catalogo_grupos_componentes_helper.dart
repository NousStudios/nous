import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';

/// Helper responsável pela gestão de grupos de componentes do catálogo da loja.
class CatalogoGruposComponentesHelper {
  final BuildContext Function() obterContext;
  final List<ItemLoja> Function() obterItens;
  final List<CategoriaLoja> Function() obterCategorias;
  final List<GrupoComponentesLoja> Function() obterGrupos;
  final bool Function() podeEditarAbaLoja;
  final VoidCallback avisarSemPermissao;
  final void Function(void Function()) setState;
  final VoidCallback aoPersistir;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final Future<bool> Function({
    required String titulo,
    required String mensagem,
  })
  confirmarExclusao;
  final String? Function() obterGrupoExpandidoId;
  final void Function(String?) definirGrupoExpandidoId;

  const CatalogoGruposComponentesHelper({
    required this.obterContext,
    required this.obterItens,
    required this.obterCategorias,
    required this.obterGrupos,
    required this.podeEditarAbaLoja,
    required this.avisarSemPermissao,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.confirmarExclusao,
    required this.obterGrupoExpandidoId,
    required this.definirGrupoExpandidoId,
  });

  void abrirPopupNovoGrupoComponentes() {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final itens = obterItens();

    NovoGrupoComponentesDialog.mostrar(
      obterContext(),
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: itens,
      onCriar: (grupo) {
        setState(() => grupos.add(grupo));
        aoPersistir();

        registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${grupo.nome}" criado',
        );
      },
    );
  }

  void abrirPopupEditarGrupoComponentes(GrupoComponentesLoja grupo) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final itens = obterItens();

    NovoGrupoComponentesDialog.mostrar(
      obterContext(),
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: itens,
      grupoParaEditar: grupo,
      onCriar: (grupoEditado) {
        setState(() {
          final indice = grupos.indexWhere((g) => g.id == grupoEditado.id);
          if (indice != -1) grupos[indice] = grupoEditado;
        });
        aoPersistir();

        registrarAcao(
          TipoAcao.grupoAtualizado,
          'Grupo de componentes "${grupoEditado.nome}" atualizado',
        );
      },
    );
  }

  void editarNomeGrupoComponentes(String id, String novoNome) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final indice = grupos.indexWhere((g) => g.id == id);
    if (indice == -1) return;
    final anterior = grupos[indice];
    if (anterior.nome == novoNome) return;

    setState(() {
      grupos[indice] = anterior.copyWith(nome: novoNome);
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.grupoAtualizado,
      'Grupo de componentes "${anterior.nome}" renomeado para "$novoNome"',
    );
  }

  Future<void> removerGrupoComponentes(String id) async {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final categorias = obterCategorias();
    final indice = grupos.indexWhere((g) => g.id == id);
    final nome = indice == -1 ? '' : grupos[indice].nome;

    final confirmou = await confirmarExclusao(
      titulo: 'Excluir Grupo',
      mensagem:
          'Tem certeza que deseja excluir o grupo de componentes "$nome"? Essa ação não pode ser desfeita.',
    );
    if (!confirmou) return;

    setState(() {
      grupos.removeWhere((grupo) => grupo.id == id);
      if (obterGrupoExpandidoId() == id) {
        definirGrupoExpandidoId(null);
      }

      for (var i = 0; i < categorias.length; i++) {
        if (categorias[i].grupoIds.contains(id)) {
          categorias[i] = categorias[i].copyWith(
            grupoIds: categorias[i].grupoIds.where((gId) => gId != id).toList(),
          );
        }
      }
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.grupoExcluido,
      'Grupo de componentes "$nome" excluído',
    );
  }

  void adicionarItemNoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final itens = obterItens();

    setState(() {
      final indice = grupos.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = [...grupo.itemIds, itemId];
      grupos[indice] = grupo.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemVinculadoGrupo,
      'Item "$nomeItem" vinculado ao grupo "${grupo.nome}"',
    );
  }

  void removerItemDoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final itens = obterItens();

    setState(() {
      final indice = grupos.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = grupo.itemIds.where((id) => id != itemId).toList();
      grupos[indice] = grupo.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemDesvinculadoGrupo,
      'Item "$nomeItem" desvinculado do grupo "${grupo.nome}"',
    );
  }
}
