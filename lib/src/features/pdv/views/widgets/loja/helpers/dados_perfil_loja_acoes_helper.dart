import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_confirmar_abertura_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/dados_perfil_loja_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/persistencia_loja_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class DadosPerfilLojaAcoesHelper {
  static void avisar(BuildContext context, String mensagem) {
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          mensagem,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  static void registrarAcao(
    DadosPerfilLojaController c,
    TipoAcao tipo,
    String descricao,
  ) {
    final auth = c.obterContext().read<AuthProvider>();
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

    c.obterContext().read<PdvProvider>().registrarAcao(c.lojaId, acao);
  }

  static Future<bool> dialogoConfirmarExclusao({
    required BuildContext context,
    required String titulo,
    required String mensagem,
  }) async {
    final theme = ThemeController.currentTheme.value;
    final res = await showDialog<bool>(
      context: context,
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

  static Future<void> criarItemNaVenda(
    DadosPerfilLojaController c,
    ItemLoja item,
    List<String> categoriaIds,
    List<String> grupoIds, [
    double? estoqueInicial,
  ]) async {
    c.setState(() => c.itens.add(item));
    c.gerenciadorCatalogo.sincronizarVinculosItem(
      item.id,
      categoriaIds,
      grupoIds,
    );

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
        cpfAutor: c.cpfLogado,
        nomeAutor: c.nomeLogado,
        categoria: CategoriaMovimentoEstoque.ajuste,
      );
      c.setState(() => c.movimentosEstoque.add(mov));
    }

    c.persistirListasLoja();
    c.registrarAcao(
      TipoAcao.itemCriado,
      'Item "${item.nome}" criado',
    );
  }

  static void salvarDadosLoja(DadosPerfilLojaController c) {
    final context = c.obterContext();
    final pdv = context.read<PdvProvider>();
    final podeDados = pdv.possoEditarDadosLoja(c.lojaId);
    final podeMapa = pdv.possoEditarLocalizacaoMapa(c.lojaId);
    if (!podeDados && !podeMapa) {
      c.avisarSemPermissao();
      return;
    }

    final lojaAtual = pdv.buscarPorId(c.lojaId);
    if (podeDados) {
      pdv.atualizarDadosLoja(
        c.lojaId,
        nome: c.controllers.nome.text,
        cnpj: c.controllers.cnpj.text,
        telefone: c.controllers.telefone.text,
        endereco: c.controllers.endereco.text,
        numero: c.controllers.numero.text,
        cidade: c.controllers.cidade.text,
        cep: c.controllers.cep.text,
        email: c.controllers.email.text,
        redesSociais: c.controllers.redesSociais.text,
        categorias: c.controllers.categorias.text,
        tags: c.controllers.tags.text,
        logo: c.logo,
        latitude: podeMapa ? c.controllers.latitude : lojaAtual?.latitude,
        longitude: podeMapa ? c.controllers.longitude : lojaAtual?.longitude,
      );
    } else if (podeMapa &&
        lojaAtual != null &&
        c.controllers.latitude != null &&
        c.controllers.longitude != null) {
      pdv.atualizarDadosLoja(
        c.lojaId,
        nome: lojaAtual.nome,
        cnpj: lojaAtual.cnpj,
        telefone: lojaAtual.telefone,
        endereco: lojaAtual.endereco,
        numero: lojaAtual.numero,
        cidade: lojaAtual.cidade,
        cep: lojaAtual.cep,
        email: lojaAtual.email,
        redesSociais: lojaAtual.redesSociais,
        categorias: lojaAtual.categorias,
        tags: lojaAtual.tags,
        logo: lojaAtual.logo,
        latitude: c.controllers.latitude,
        longitude: c.controllers.longitude,
      );
    }

    c.registrarAcao(TipoAcao.dadosLojaAtualizados, 'Dados da loja atualizados');
    avisar(context, 'Dados salvos.');
  }

  static Future<void> alterarLogoLoja(DadosPerfilLojaController c) async {
    final context = c.obterContext();
    if (!context.read<PdvProvider>().possoEditarDadosLoja(c.lojaId)) {
      c.avisarSemPermissao();
      return;
    }

    if (c.logo.isNotEmpty) {
      final theme = ThemeController.currentTheme.value;
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Logo da Loja',
        onEscolherNova: c.gerenciadorAnexos.selecionarNovaLogoLoja,
        onRemover: c.gerenciadorAnexos.removerLogoLoja,
      );
    } else {
      await c.gerenciadorAnexos.selecionarNovaLogoLoja();
    }
  }

  static Future<void> alternarStatusLojaOnline(
    DadosPerfilLojaController c,
    bool valor,
  ) async {
    final pdv = c.obterContext().read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(c.lojaId);

    if (valor && lojaAtual != null && lojaAtual.turnoCaixaAberto == null) {
      final acao = await DialogConfirmarAberturaCaixa.mostrar(
        context: c.obterContext(),
        theme: ThemeController.currentTheme.value,
        lojaNome: lojaAtual.nome,
      );
      if (acao == AcaoAberturaCaixa.cancelar) {
        return;
      }
      c.setState(() => c.lojaOnline = true);
      await pdv.alternarLojaAberta(c.lojaId, true);
      final atualizada = pdv.buscarPorId(c.lojaId);
      if (atualizada != null) {
        PersistenciaLojaHelper.notificarLojaAtualizada(atualizada);
      }
      if (acao == AcaoAberturaCaixa.abrirCaixaAgora && c.estaMontado()) {
        c.gerenciadorDialogs.abrirPopupCaixa();
      }
      return;
    }

    c.setState(() => c.lojaOnline = valor);
    await pdv.alternarLojaAberta(c.lojaId, valor);
    final lojaNova = pdv.buscarPorId(c.lojaId);
    if (lojaNova != null) {
      PersistenciaLojaHelper.notificarLojaAtualizada(lojaNova);
    }
  }
}
