import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/aba_gestao_nous_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/aba_ajustes_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/aba_catalogo_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/aba_dados_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';

class SeletorConteudoAbasLojaWidget extends StatelessWidget {
  final String lojaId;
  final AbaLoja abaSelecionada;
  final AppTheme theme;
  final BoxDecoration decoracaoBloco;

  // Controladores e dados da aba Dados
  final ControllersDadosLoja controllers;
  final String logo;
  final List<MembroLoja> membros;
  final List<String> galeria;
  final List<String> arquivos;
  final List<String> musicas;
  final List<String> videos;
  final List<String> arquivosAudio;
  final Map<String, String> descricoesAnexos;

  // Callbacks de dados
  final VoidCallback onAlterarLogo;
  final VoidCallback onSalvarDados;
  final VoidCallback onConfirmarExclusao;
  final Future<UsuarioNous?> Function(String cpf) onBuscarContaPorCpf;
  final Future<void> Function(UsuarioNous conta, PapelMembro papel) onEnviarConvite;
  final Future<void> Function(String cpf) onRemoverMembro;
  final Future<void> Function(String cpf, PapelMembro papel) onAtualizarPapelMembro;
  final Future<void> Function(String cpf, String? cargoId) onVincularCargoPersonalizado;
  final Future<void> Function() onSairDaLoja;
  final void Function(String caminho, String novaDescricao) onAtualizarDescricaoAnexo;
  final void Function(TipoAnexoLoja tipo, String caminho) onAdicionarAnexo;
  final void Function(TipoAnexoLoja tipo, int index) onRemoverAnexo;
  final void Function(TipoAnexoLoja tipo, int index, String novo) onSubstituirAnexo;

  // Catálogo (Aba Loja)
  final TextEditingController pesquisaItens;
  final TextEditingController pesquisaCategorias;
  final TextEditingController pesquisaGrupos;
  final List<ItemLoja> itens;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final String? categoriaExpandidaId;
  final String? grupoExpandidoId;
  final ScrollController scrollCategorias;
  final ScrollController scrollGrupos;

  final double Function(String itemId) onObterSaldoEstoque;
  final void Function(ItemLoja item) onAbrirPopupEditarItem;
  final void Function(String id) onRemoverItem;
  final void Function(String id, String novoNome) onEditarNomeItem;
  final void Function(String id, String novoPreco) onEditarPrecoItem;
  final void Function(int oldIndex, int newIndex) onReordenarItens;
  final void Function(int oldIndex, int newIndex) onReordenarCategorias;
  final void Function(int oldIndex, int newIndex) onReordenarGrupos;
  final void Function(String id) onAlternarExpansaoCategoria;
  final void Function(CategoriaLoja cat, String itemId) onAdicionarItemNaCategoria;
  final void Function(CategoriaLoja cat, String itemId) onRemoverItemDaCategoria;
  final void Function(CategoriaLoja cat) onAbrirPopupEditarCategoria;
  final void Function(String catId) onRemoverCategoria;
  final void Function(String catId, String novoNome) onEditarNomeCategoria;
  final void Function(String id) onAlternarExpansaoGrupo;
  final void Function(GrupoComponentesLoja g, String itemId) onAdicionarItemNoGrupo;
  final void Function(GrupoComponentesLoja g, String itemId) onRemoverItemDoGrupo;
  final void Function(GrupoComponentesLoja g) onAbrirPopupEditarGrupo;
  final void Function(String grpId) onRemoverGrupo;
  final void Function(String grpId, String novoNome) onEditarNomeGrupo;

  // Gestão
  final String cpfLogado;
  final String nomeLogado;
  final String emailLogado;
  final bool lojaOnline;
  final Future<void> Function(bool valor) onAlternarLojaOnline;
  final AbaPedidos abaPedidos;
  final ValueChanged<AbaPedidos> onTrocarAbaPedidos;
  final List<PedidoLoja> pedidos;
  final List<Cliente> clientes;
  final List<MesaLoja> mesas;
  final bool ehRestaurante;
  final bool temNovasMensagensLoja;

  final void Function(String id) onAceitarPedido;
  final void Function(String id) onRecusarPedido;
  final void Function(String id) onConcluirPedido;
  final Future<void> Function(String id) onCancelarPedidoComDialog;
  final void Function(String id, DadosComentario dados) onSalvarComentarioPedido;
  final Future<void> Function(String id) onExcluirPedido;

  final VoidCallback onNovaVenda;
  final VoidCallback onClientes;
  final VoidCallback onMensagens;
  final VoidCallback onRelatorios;
  final VoidCallback onImpressora;
  final VoidCallback onFinanceiro;
  final VoidCallback onCaixa;
  final VoidCallback onStatus;
  final VoidCallback onCriarMesa;
  final void Function(MesaLoja mesa) onClicarMesa;

  // Interface / Ajustes
  final bool tecladoFisicoDetectado;
  final Map<String, String> atalhosTeclado;
  final int tempoConclusaoMinutos;
  final Map<String, String> sonsAlertas;
  final List<String> acoesAtalhosDisponiveis;
  final List<String> teclasFuncao;
  final String Function(String tecla) onObterAcaoPorTecla;
  final VoidCallback onAlternarLayout;
  final void Function(String tecla, String? novoValor) onSalvarAtalho;
  final void Function(int minutos) onSalvarTempoConclusao;
  final void Function(String chave, String valor) onSalvarSomAlerta;
  final Future<void> Function(BuildContext context, AppTheme theme) onConfirmarResetTransacoes;

  const SeletorConteudoAbasLojaWidget({
    super.key,
    required this.lojaId,
    required this.abaSelecionada,
    required this.theme,
    required this.decoracaoBloco,
    required this.controllers,
    required this.logo,
    required this.membros,
    required this.galeria,
    required this.arquivos,
    required this.musicas,
    required this.videos,
    required this.arquivosAudio,
    required this.descricoesAnexos,
    required this.onAlterarLogo,
    required this.onSalvarDados,
    required this.onConfirmarExclusao,
    required this.onBuscarContaPorCpf,
    required this.onEnviarConvite,
    required this.onRemoverMembro,
    required this.onAtualizarPapelMembro,
    required this.onVincularCargoPersonalizado,
    required this.onSairDaLoja,
    required this.onAtualizarDescricaoAnexo,
    required this.onAdicionarAnexo,
    required this.onRemoverAnexo,
    required this.onSubstituirAnexo,
    required this.pesquisaItens,
    required this.pesquisaCategorias,
    required this.pesquisaGrupos,
    required this.itens,
    required this.categorias,
    required this.gruposComponentes,
    required this.categoriaExpandidaId,
    required this.grupoExpandidoId,
    required this.scrollCategorias,
    required this.scrollGrupos,
    required this.onObterSaldoEstoque,
    required this.onAbrirPopupEditarItem,
    required this.onRemoverItem,
    required this.onEditarNomeItem,
    required this.onEditarPrecoItem,
    required this.onReordenarItens,
    required this.onReordenarCategorias,
    required this.onReordenarGrupos,
    required this.onAlternarExpansaoCategoria,
    required this.onAdicionarItemNaCategoria,
    required this.onRemoverItemDaCategoria,
    required this.onAbrirPopupEditarCategoria,
    required this.onRemoverCategoria,
    required this.onEditarNomeCategoria,
    required this.onAlternarExpansaoGrupo,
    required this.onAdicionarItemNoGrupo,
    required this.onRemoverItemDoGrupo,
    required this.onAbrirPopupEditarGrupo,
    required this.onRemoverGrupo,
    required this.onEditarNomeGrupo,
    required this.cpfLogado,
    required this.nomeLogado,
    required this.emailLogado,
    required this.lojaOnline,
    required this.onAlternarLojaOnline,
    required this.abaPedidos,
    required this.onTrocarAbaPedidos,
    required this.pedidos,
    required this.clientes,
    required this.mesas,
    required this.ehRestaurante,
    required this.temNovasMensagensLoja,
    required this.onAceitarPedido,
    required this.onRecusarPedido,
    required this.onConcluirPedido,
    required this.onCancelarPedidoComDialog,
    required this.onSalvarComentarioPedido,
    required this.onExcluirPedido,
    required this.onNovaVenda,
    required this.onClientes,
    required this.onMensagens,
    required this.onRelatorios,
    required this.onImpressora,
    required this.onFinanceiro,
    required this.onCaixa,
    required this.onStatus,
    required this.onCriarMesa,
    required this.onClicarMesa,
    required this.tecladoFisicoDetectado,
    required this.atalhosTeclado,
    required this.tempoConclusaoMinutos,
    required this.sonsAlertas,
    required this.acoesAtalhosDisponiveis,
    required this.teclasFuncao,
    required this.onObterAcaoPorTecla,
    required this.onAlternarLayout,
    required this.onSalvarAtalho,
    required this.onSalvarTempoConclusao,
    required this.onSalvarSomAlerta,
    required this.onConfirmarResetTransacoes,
  });

  @override
  Widget build(BuildContext context) {
    final pdv = context.read<PdvProvider>();
    final possoEditarDados = pdv.possoEditarDadosLoja(lojaId);
    final possoGerenciarMembros = pdv.possoGerenciarMembros(lojaId);
    final lojaAtual = pdv.buscarPorId(lojaId);
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final expandido = pdv.layoutDesktopAtivo(lojaId, larguraDaTela);

    switch (abaSelecionada) {
      case AbaLoja.dados:
        return AbaDadosLojaWidget(
          theme: theme,
          lojaId: lojaId,
          possoEditarDados: possoEditarDados,
          possoGerenciarMembros: possoGerenciarMembros,
          lojaAtual: lojaAtual,
          cpfLogado: cpfLogado,
          expandido: expandido,
          larguraDaTela: larguraDaTela,
          controllers: controllers,
          logo: logo,
          membros: membros,
          galeria: galeria,
          arquivos: arquivos,
          musicas: musicas,
          videos: videos,
          arquivosAudio: arquivosAudio,
          descricoesAnexos: descricoesAnexos,
          decoracaoBloco: decoracaoBloco,
          onAlterarLogo: onAlterarLogo,
          onSalvarDados: onSalvarDados,
          onConfirmarExclusao: onConfirmarExclusao,
          onBuscarContaPorCpf: onBuscarContaPorCpf,
          onEnviarConvite: onEnviarConvite,
          onRemoverMembro: onRemoverMembro,
          onAtualizarPapelMembro: onAtualizarPapelMembro,
          onVincularCargoPersonalizado: (cpf, cargoId) =>
              onVincularCargoPersonalizado(cpf, cargoId),
          onSairDaLoja: onSairDaLoja,
          onAtualizarDescricaoAnexo: onAtualizarDescricaoAnexo,
          onAdicionarAnexo: onAdicionarAnexo,
          onRemoverAnexo: onRemoverAnexo,
          onSubstituirAnexo: onSubstituirAnexo,
        );

      case AbaLoja.loja:
        final podeEditarLoja = pdv.possoEditarAbaLoja(lojaId);
        return AbaCatalogoLojaWidget(
          theme: theme,
          lojaId: lojaId,
          podeEditarLoja: podeEditarLoja,
          expandido: expandido,
          pesquisaItens: pesquisaItens,
          pesquisaCategorias: pesquisaCategorias,
          pesquisaGrupos: pesquisaGrupos,
          itens: itens,
          categorias: categorias,
          gruposComponentes: gruposComponentes,
          categoriaExpandidaId: categoriaExpandidaId,
          grupoExpandidoId: grupoExpandidoId,
          scrollCategorias: scrollCategorias,
          scrollGrupos: scrollGrupos,
          decoracaoBloco: decoracaoBloco,
          onObterSaldoEstoque: onObterSaldoEstoque,
          onAbrirPopupEditarItem: onAbrirPopupEditarItem,
          onRemoverItem: onRemoverItem,
          onEditarNomeItem: onEditarNomeItem,
          onEditarPrecoItem: onEditarPrecoItem,
          onReordenarItens: onReordenarItens,
          onReordenarCategorias: onReordenarCategorias,
          onReordenarGrupos: onReordenarGrupos,
          onAlternarExpansaoCategoria: onAlternarExpansaoCategoria,
          onAdicionarItemNaCategoria: onAdicionarItemNaCategoria,
          onRemoverItemDaCategoria: onRemoverItemDaCategoria,
          onAbrirPopupEditarCategoria: onAbrirPopupEditarCategoria,
          onRemoverCategoria: onRemoverCategoria,
          onEditarNomeCategoria: onEditarNomeCategoria,
          onAlternarExpansaoGrupo: onAlternarExpansaoGrupo,
          onAdicionarItemNoGrupo: onAdicionarItemNoGrupo,
          onRemoverItemDoGrupo: onRemoverItemDoGrupo,
          onAbrirPopupEditarGrupo: onAbrirPopupEditarGrupo,
          onRemoverGrupo: onRemoverGrupo,
          onEditarNomeGrupo: onEditarNomeGrupo,
        );

      case AbaLoja.gestao:
        final bool ehLojaNous = lojaId == PdvProvider.idLojaColetivaNous;
        if (ehLojaNous) {
          final auth = context.watch<AuthProvider>();
          return AbaGestaoNousWidget(
            theme: theme,
            lojaId: lojaId,
            cpfLogado: cpfLogado,
            nomeLogado: nomeLogado,
            fotoLogada: auth.contaAtual?.foto ?? '',
            membros: membros,
            onAbrirStatusLoja: onStatus,
          );
        }
        final loja = context.watch<PdvProvider>().buscarPorId(lojaId);
        final onlineEfetivo = loja?.aberta ?? lojaOnline;
        return GestaoLojaContainer(
          theme: theme,
          lojaId: lojaId,
          autorCpf: cpfLogado,
          autorNome: nomeLogado,
          autorEmail: emailLogado,
          lojaOnline: onlineEfetivo,
          aoAlterarOnline: onAlternarLojaOnline,
          abaPedidos: abaPedidos,
          aoTrocarAbaPedidos: onTrocarAbaPedidos,
          pedidos: pedidos,
          clientes: clientes,
          itensDisponiveis: itens,
          aoAceitar: onAceitarPedido,
          aoRecusar: onRecusarPedido,
          aoConcluir: onConcluirPedido,
          aoCancelarPedido: onCancelarPedidoComDialog,
          aoSalvarComentario: onSalvarComentarioPedido,
          aoExcluirPedido: onExcluirPedido,
          aoNovaVenda: onNovaVenda,
          aoClientes: onClientes,
          aoMensagens: onMensagens,
          temNovasMensagens: temNovasMensagensLoja,
          aoRelatorios: onRelatorios,
          aoImpressora: onImpressora,
          aoFinanceiro: onFinanceiro,
          aoCaixa: onCaixa,
          caixaAberto: loja?.turnoCaixaAberto != null,
          aoStatus: onStatus,
          ehRestaurante: ehRestaurante,
          mesas: mesas,
          aoCriarMesa: onCriarMesa,
          aoClicarMesa: onClicarMesa,
          ocultarBotoesTopo: expandido,
        );

      case AbaLoja.interface:
        return AbaAjustesLojaWidget(
          theme: theme,
          lojaId: lojaId,
          possoEditarDados: possoEditarDados,
          expandido: expandido,
          larguraDaTela: larguraDaTela,
          tecladoFisicoDetectado: tecladoFisicoDetectado,
          atalhosTeclado: atalhosTeclado,
          tempoConclusaoMinutos: tempoConclusaoMinutos,
          sonsAlertas: sonsAlertas,
          arquivosAudio: arquivosAudio,
          descricoesAnexos: descricoesAnexos,
          decoracaoBloco: decoracaoBloco,
          acoesAtalhosDisponiveis: acoesAtalhosDisponiveis,
          teclasFuncao: teclasFuncao,
          onObterAcaoPorTecla: onObterAcaoPorTecla,
          onAlternarLayout: onAlternarLayout,
          onSalvarAtalho: onSalvarAtalho,
          onSalvarTempoConclusao: onSalvarTempoConclusao,
          onSalvarSomAlerta: onSalvarSomAlerta,
          onConfirmarResetTransacoes: onConfirmarResetTransacoes,
        );
    }
  }
}
