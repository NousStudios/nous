import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/barra_acoes_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/dados_perfil_loja_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/layout_principal_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/seletor_conteudo_abas_loja_widget.dart';

class DadosPerfilView extends StatefulWidget {
  final String lojaId;
  final AbaLoja abaInicial;

  const DadosPerfilView({
    super.key,
    required this.lojaId,
    this.abaInicial = AbaLoja.dados,
  });

  @override
  State<DadosPerfilView> createState() => _DadosPerfilViewState();
}

enum AbaLoja { dados, interface, loja, gestao }

const double _larguraMaximaConteudo = 500;

class _DadosPerfilViewState extends State<DadosPerfilView> {
  late final DadosPerfilLojaController _c;
  late AbaLoja _abaSelecionada;
  late final PdvProvider _pdvProvider;

  static const List<String> _acoesAtalhosDisponiveis = [
    'Nova Venda',
    'Clientes',
    'Mensagens',
    'Caixa',
    'Relatórios',
    'Impressora',
    'Financeiro',
    'Status da Loja',
    'Modo Balcão',
    'Desativado',
  ];

  static const List<String> _teclasFuncao = [
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
  ];

  @override
  void initState() {
    super.initState();
    _abaSelecionada = widget.abaInicial;

    _c = DadosPerfilLojaController(
      obterContext: () => context,
      estaMontado: () => mounted,
      lojaId: widget.lojaId,
      setState: (fn) => setState(fn),
    );

    HardwareKeyboard.instance.addHandler(_c.tratarTecladoGlobal);
    ChatService.alteracoesChatNotifier.addListener(_c.verificarMensagensNaoLidasLoja);
    _c.verificarMensagensNaoLidasLoja();

    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    _c.carregarDadosIniciais(loja);

    _pdvProvider = context.read<PdvProvider>();
    _pdvProvider.addListener(_aoAtualizarPdv);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_c.tentouGarantirDono) {
        _c.tentouGarantirDono = true;
        final conta = context.read<AuthProvider>().contaAtual;
        if (conta != null) {
          final atual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
          if (atual != null && atual.membros.isEmpty) {
            context.read<PdvProvider>().garantirDono(
                  widget.lojaId,
                  cpf: conta.cpf,
                  nome: conta.nome,
                );
            if (mounted) {
              final depois =
                  context.read<PdvProvider>().buscarPorId(widget.lojaId);
              setState(() => _c.membros = List.of(depois?.membros ?? []));
            }
          }
        }
      }

      await _c.gerenciadorPedidos.verificarAvisosIniciais();
    });
  }

  void _aoAtualizarPdv() {
    if (!mounted) return;
    final lojaAtual = _pdvProvider.buscarPorId(widget.lojaId);
    if (lojaAtual == null) return;
    _c.sincronizarComLoja(lojaAtual);
  }

  @override
  void dispose() {
    _pdvProvider.removeListener(_aoAtualizarPdv);
    _c.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthProvider>().sair();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  String _tituloDaAba() {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        return 'Dados do Perfil';
      case AbaLoja.interface:
        return 'Ajustes do Perfil';
      case AbaLoja.loja:
        return 'Loja do Perfil';
      case AbaLoja.gestao:
        return 'Gestão do Perfil';
    }
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.backgroundColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
    );
  }

  Widget _barraDeAcoesLoja(AppTheme theme, double maxWidth) {
    return BarraAcoesLojaWidget(
      theme: theme,
      maxWidth: maxWidth,
      onNovoItem: _c.gerenciadorCatalogo.abrirPopupNovoItem,
      onNovaCategoria: _c.gerenciadorCatalogo.abrirPopupNovaCategoria,
      onNovoGrupo: _c.gerenciadorCatalogo.abrirPopupNovoGrupoComponentes,
      onEstoque: _c.gerenciadorDialogs.abrirPopupEstoque,
    );
  }

  void _alternarLayout() {
    final pdv = context.read<PdvProvider>();
    pdv.alternarLayoutExpandido(widget.lojaId);
    final expandido = pdv.layoutDesktopAtivo(widget.lojaId);
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        duration: const Duration(seconds: 2),
        content: Text(
          expandido
              ? 'Layout Desktop PDV Expandido ativado.'
              : 'Layout Compacto ativado.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  bool get _ehRestaurante {
    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final categorias =
        (lojaAtual?.categorias ?? _c.controllers.categorias.text).toLowerCase();
    return categorias.contains('restaurante');
  }

  double _obterLarguraMaxima(Loja? loja) {
    if (loja == null || !loja.layoutExpandidoEfetivo) {
      return _larguraMaximaConteudo;
    }
    switch (loja.tipoLayoutMaior) {
      case 'grid_amplo':
        return 1440;
      case 'balcao_operacional':
        return 1380;
      case 'painel_duplo':
      default:
        return 1200;
    }
  }

  Widget _conteudoDaAba(AppTheme theme) {
    return SeletorConteudoAbasLojaWidget(
      lojaId: widget.lojaId,
      abaSelecionada: _abaSelecionada,
      theme: theme,
      decoracaoBloco: _decoracaoDoBloco(theme),
      controllers: _c.controllers,
      logo: _c.logo,
      membros: _c.membros,
      galeria: _c.galeria,
      arquivos: _c.arquivos,
      musicas: _c.musicas,
      videos: _c.videos,
      arquivosAudio: _c.arquivosAudio,
      descricoesAnexos: _c.descricoesAnexos,
      onAlterarLogo: _c.alterarLogoLoja,
      onSalvarDados: _c.salvarDadosLoja,
      onConfirmarExclusao: () => _c.gerenciadorDialogs.confirmarExclusao(context),
      onBuscarContaPorCpf: _c.gerenciadorMembros.buscarContaPorCpf,
      onEnviarConvite: _c.gerenciadorMembros.enviarConvite,
      onRemoverMembro: _c.gerenciadorMembros.removerMembro,
      onAtualizarPapelMembro: _c.gerenciadorMembros.atualizarPapelMembro,
      onVincularCargoPersonalizado: (cpf, cargoId) async {
        await context
            .read<PdvProvider>()
            .vincularCargoAoMembro(widget.lojaId, cpf, cargoId);
        if (!mounted) return;
        setState(() {
          _c.membros = _c.membros
              .map((m) => m.cpf == cpf
                  ? m.copyWith(cargoPersonalizadoId: cargoId)
                  : m)
              .toList();
        });
      },
      onSairDaLoja: _c.gerenciadorMembros.sairDaLoja,
      onAtualizarDescricaoAnexo: _c.gerenciadorAnexos.atualizarDescricaoAnexo,
      onAdicionarAnexo: _c.gerenciadorAnexos.adicionarAnexo,
      onRemoverAnexo: _c.gerenciadorAnexos.removerAnexo,
      onSubstituirAnexo: _c.gerenciadorAnexos.substituirAnexo,
      pesquisaItens: _c.pesquisaItens,
      pesquisaCategorias: _c.pesquisaCategorias,
      pesquisaGrupos: _c.pesquisaGrupos,
      itens: _c.itens,
      categorias: _c.categorias,
      gruposComponentes: _c.gruposComponentes,
      categoriaExpandidaId: _c.categoriaExpandidaId,
      grupoExpandidoId: _c.grupoExpandidoId,
      scrollCategorias: _c.scrollCategorias,
      scrollGrupos: _c.scrollGrupos,
      onObterSaldoEstoque: _c.gerenciadorCatalogo.saldoEstoqueDoItem,
      onAbrirPopupEditarItem: _c.gerenciadorCatalogo.abrirPopupEditarItem,
      onRemoverItem: _c.gerenciadorCatalogo.removerItem,
      onEditarNomeItem: _c.gerenciadorCatalogo.editarNomeItem,
      onEditarPrecoItem: _c.gerenciadorCatalogo.editarPrecoItem,
      onReordenarItens: (oldIndex, newIndex) {
        setState(() {
          final itemRemovido = _c.itens.removeAt(oldIndex);
          _c.itens.insert(newIndex, itemRemovido);
          _c.persistirListasLoja();
        });
      },
      onReordenarCategorias: (oldIndex, newIndex) {
        setState(() {
          final item = _c.categorias.removeAt(oldIndex);
          _c.categorias.insert(newIndex, item);
          _c.persistirListasLoja();
        });
      },
      onReordenarGrupos: (oldIndex, newIndex) {
        setState(() {
          final item = _c.gruposComponentes.removeAt(oldIndex);
          _c.gruposComponentes.insert(newIndex, item);
          _c.persistirListasLoja();
        });
      },
      onAlternarExpansaoCategoria: _c.alternarExpansaoCategoria,
      onAdicionarItemNaCategoria: _c.gerenciadorCatalogo.adicionarItemNaCategoria,
      onRemoverItemDaCategoria: _c.gerenciadorCatalogo.removerItemDaCategoria,
      onAbrirPopupEditarCategoria:
          _c.gerenciadorCatalogo.abrirPopupEditarCategoria,
      onRemoverCategoria: _c.gerenciadorCatalogo.removerCategoria,
      onEditarNomeCategoria: _c.gerenciadorCatalogo.editarNomeCategoria,
      onAlternarExpansaoGrupo: _c.alternarExpansaoGrupo,
      onAdicionarItemNoGrupo:
          _c.gerenciadorCatalogo.adicionarItemNoGrupoComponentes,
      onRemoverItemDoGrupo:
          _c.gerenciadorCatalogo.removerItemDoGrupoComponentes,
      onAbrirPopupEditarGrupo:
          _c.gerenciadorCatalogo.abrirPopupEditarGrupoComponentes,
      onRemoverGrupo: _c.gerenciadorCatalogo.removerGrupoComponentes,
      onEditarNomeGrupo: _c.gerenciadorCatalogo.editarNomeGrupoComponentes,
      cpfLogado: _c.cpfLogado,
      nomeLogado: _c.nomeLogado,
      emailLogado: _c.emailLogado,
      lojaOnline: _c.lojaOnline,
      onAlternarLojaOnline: _c.alternarStatusLojaOnline,
      abaPedidos: _c.abaPedidos,
      onTrocarAbaPedidos: (aba) => setState(() => _c.abaPedidos = aba),
      pedidos: _c.pedidos,
      clientes: _c.clientes,
      mesas: _c.mesas,
      ehRestaurante: _ehRestaurante,
      temNovasMensagensLoja: _c.temNovasMensagensLoja,
      onAceitarPedido: (id) =>
          _c.gerenciadorPedidos.alterarStatusPedido(id, StatusPedido.aceito),
      onRecusarPedido: _c.gerenciadorPedidos.recusarPedido,
      onConcluirPedido: (id) =>
          _c.gerenciadorPedidos.alterarStatusPedido(id, StatusPedido.concluido),
      onCancelarPedidoComDialog:
          _c.gerenciadorPedidos.cancelarPedidoComDialog,
      onSalvarComentarioPedido:
          _c.gerenciadorPedidos.salvarComentarioPedido,
      onExcluirPedido: _c.gerenciadorPedidos.excluirPedido,
      onNovaVenda: _c.gerenciadorDialogs.abrirPopupNovaVenda,
      onClientes: _c.gerenciadorDialogs.abrirPopupClientes,
      onMensagens: _c.gerenciadorDialogs.abrirMensagensLoja,
      onRelatorios: _c.gerenciadorDialogs.abrirPopupRelatorios,
      onImpressora: _c.gerenciadorDialogs.abrirPopupImpressora,
      onFinanceiro: _c.gerenciadorDialogs.abrirFinanceiro,
      onCaixa: _c.gerenciadorDialogs.abrirPopupCaixa,
      onStatus: _c.gerenciadorDialogs.abrirStatusLoja,
      onCriarMesa: _c.gerenciadorDialogs.abrirCriarMesa,
      onClicarMesa: _c.gerenciadorMesas.abrirComandaMesa,
      tecladoFisicoDetectado: _c.tecladoFisicoDetectado,
      atalhosTeclado: _c.atalhosTeclado,
      tempoConclusaoMinutos: _c.tempoConclusaoMinutos,
      sonsAlertas: _c.sonsAlertas,
      acoesAtalhosDisponiveis: _acoesAtalhosDisponiveis,
      teclasFuncao: _teclasFuncao,
      onObterAcaoPorTecla: _c.gerenciadorDialogs.obterAcaoPorTecla,
      onAlternarLayout: _alternarLayout,
      onSalvarAtalho: (tecla, novoValor) {
        if (novoValor == null) return;
        setState(() => _c.atalhosTeclado[tecla] = novoValor);
        context.read<PdvProvider>().atualizarAtalhoTeclado(
              widget.lojaId,
              tecla,
              novoValor,
            );
      },
      onSalvarTempoConclusao: (minutos) {
        setState(() => _c.tempoConclusaoMinutos = minutos);
        context.read<PdvProvider>().atualizarTempoConclusao(
              widget.lojaId,
              minutos,
            );
      },
      onSalvarSomAlerta: (chave, valor) {
        setState(() => _c.sonsAlertas[chave] = valor);
        context.read<PdvProvider>().atualizarSomAlerta(
              widget.lojaId,
              chave,
              valor,
            );
        if (valor == SomService.opcaoSilencioso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Alerta silenciado para esta notificação.',
                style: theme.getTextStyle(color: theme.textColor),
              ),
            ),
          );
        }
      },
      onConfirmarResetTransacoes: (ctx, th) =>
          _c.gerenciadorDialogs.confirmarResetTransacoes(
        ctx,
        th,
        onResetConcluido: () {
          setState(() {
            _c.pedidos.clear();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(widget.lojaId);
    final larguraDinamica = _obterLarguraMaxima(lojaAtual);

    return LayoutPrincipalLojaWidget(
      lojaId: widget.lojaId,
      abaSelecionada: _abaSelecionada,
      onTrocarAba: (novaAba) => setState(() => _abaSelecionada = novaAba),
      tituloAba: _tituloDaAba(),
      larguraDinamica: larguraDinamica,
      modoBalcaoAtivo: _c.modoBalcaoAtivo,
      onSairModoBalcao: () => setState(() => _c.modoBalcaoAtivo = false),
      onConcluirVendaBalcao: _c.gerenciadorPedidos.processarConclusaoVenda,
      pedidos: _c.pedidos,
      itens: _c.itens,
      categorias: _c.categorias,
      gruposComponentes: _c.gruposComponentes,
      clientes: _c.clientes,
      movimentosEstoque: _c.movimentosEstoque,
      cpfLogado: _c.cpfLogado,
      nomeLogado: _c.nomeLogado,
      atalhosTeclado: _c.atalhosTeclado,
      temNovasMensagensLoja: _c.temNovasMensagensLoja,
      onExecutarAtalho: _c.gerenciadorDialogs.executarAcaoAtalho,
      onExecutarAcao: _c.gerenciadorDialogs.executarAcaoPorNome,
      onAlternarLayout: _alternarLayout,
      onLogout: () => _handleLogout(context),
      construtorBarraAcoes: _barraDeAcoesLoja,
      construtorConteudoAba: _conteudoDaAba,
    );
  }
}