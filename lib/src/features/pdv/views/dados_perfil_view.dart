import 'package:file_selector/file_selector.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/comanda_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/criar_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/fechar_conta_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/financeiro_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/status_loja_view.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/cancelar_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/categoria_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque_container.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';
import 'package:nous/src/features/pdv/views/widgets/movimento_estoque_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios_participantes_container.dart';

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

const double _alturaMaximaListaSecundaria = 136;

String _valorFormatado(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

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

class _DadosPerfilViewState extends State<DadosPerfilView> {
  final _controllers = ControllersDadosLoja();

  final _pesquisaItens = TextEditingController();
  final _pesquisaCategorias = TextEditingController();
  final _pesquisaGrupos = TextEditingController();

  final _scrollCategorias = ScrollController();
  final _scrollGrupos = ScrollController();

  late AbaLoja _abaSelecionada;

  String _logo = '';
  final List<String> _galeria = [];
  final List<String> _arquivos = [];
  final List<String> _musicas = [];
  final List<String> _videos = [];
  final List<String> _arquivosAudio = [];
  final Map<String, String> _descricoesAnexos = {};

  final List<CategoriaLoja> _categorias = [];
  final List<ItemLoja> _itens = [];
  final List<GrupoComponentesLoja> _gruposComponentes = [];
  final List<Cliente> _clientes = [];
  final List<Fornecedor> _fornecedores = [];

  final List<PedidoLoja> _pedidos = [];
  final List<MovimentoEstoque> _movimentosEstoque = [];
  final List<MesaLoja> _mesas = [];
  List<MembroLoja> _membros = [];
  bool _lojaOnline = true;
  AbaPedidos _abaPedidos = AbaPedidos.novos;
  int _tempoConclusaoMinutos = 0;
  final Map<String, String> _sonsAlertas = {};
  Timer? _timerVerificacaoPedidos;
  final Set<String> _pedidosPerguntados = {};

  String? _categoriaExpandidaId;
  String? _grupoExpandidoId;

  bool _tentouGarantirDono = false;

  final Map<String, GlobalKey> _chavesCategorias = {};
  final Map<String, GlobalKey> _chavesGrupos = {};

  GlobalKey _chaveCategoria(String id) =>
      _chavesCategorias.putIfAbsent(id, () => GlobalKey());

  GlobalKey _chaveGrupo(String id) =>
      _chavesGrupos.putIfAbsent(id, () => GlobalKey());

  void _avisarSemPermissao() {
    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Você não tem permissão para fazer isso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  bool _podeEditarAbaLoja() {
    return context.read<PdvProvider>().possoEditarAbaLoja(widget.lojaId);
  }

  String get _cpfLogado =>
      context.read<AuthProvider>().contaAtual?.cpf ?? '';

  String get _nomeLogado =>
      context.read<AuthProvider>().contaAtual?.nome ?? '';

  String get _emailLogado =>
      context.read<AuthProvider>().emailAtivo ?? '';

  void _registrarAcao(TipoAcao tipo, String descricao) {
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta == null) return;

    final acao = RegistroAcao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataHora: DateTime.now(),
      tipo: tipo,
      descricao: descricao,
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
      emailAutor: auth.emailAtivo ?? '',
    );

    context.read<PdvProvider>().registrarAcao(widget.lojaId, acao);
  }

  Future<UsuarioNous?> _buscarContaPorCpf(String cpf) {
    return ContasNousService.buscarPorCpf(cpf);
  }

  Future<void> _enviarConvite(UsuarioNous conta, PapelMembro papel) async {
    final auth = context.read<AuthProvider>();
    final autor = auth.contaAtual;
    if (autor == null) return;

    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    if (loja == null) return;

    final convite = ConviteLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfConvidante: autor.cpf,
      nomeConvidante: autor.nome,
      cpfConvidado: conta.cpf,
      lojaId: loja.id,
      nomeLoja: loja.nome,
      papel: papel,
      dataHora: DateTime.now(),
    );

    await context.read<NotificacoesProvider>().enviarConvite(convite);

    _registrarAcao(
      TipoAcao.conviteEnviado,
      'Convite enviado para "${conta.nome}" como ${_rotuloPapelCurto(papel)}',
    );
  }

  Future<void> _removerMembro(String cpf) async {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final membro = loja?.membros.firstWhere(
      (m) => m.cpf == cpf,
      orElse: () => MembroLoja(
        cpf: cpf,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );

    final auth = context.read<AuthProvider>();
    final autor = auth.contaAtual;
    if (membro == null || autor == null || loja == null) return;

    final notificacoes = context.read<NotificacoesProvider>();
    final pdv = context.read<PdvProvider>();

    // Se o membro alvo for outro Dono, não remove diretamente: envia solicitação de consentimento
    if (membro.papel == PapelMembro.dono && membro.cpf != autor.cpf) {
      final notificacao = ConviteLoja(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cpfConvidante: autor.cpf,
        nomeConvidante: autor.nome,
        cpfConvidado: membro.cpf,
        lojaId: loja.id,
        nomeLoja: loja.nome,
        papel: PapelMembro.dono,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoExclusaoDono,
      );

      await notificacoes.enviarConvite(notificacao);
      if (!mounted) return;
      _avisar(
        'Solicitação de saída enviada para ${membro.nome}. Como se trata de um dono, exige consentimento.',
      );
      _registrarAcao(
        TipoAcao.membroRemovido,
        'Solicitação de saída do dono "${membro.nome}" enviada para consentimento',
      );
      return;
    }

    // Remoção direta (Dono removendo Sócio/Admin/Funcionario OU Sócio removendo Admin/Funcionario)
    await pdv.removerMembro(widget.lojaId, cpf);
    if (!mounted) return;
    setState(() {
      _membros = _membros.where((m) => m.cpf != cpf).toList();
    });

    // Enviar notificação avisando o membro removido
    final notificacaoRemocao = ConviteLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfConvidante: autor.cpf,
      nomeConvidante: autor.nome,
      cpfConvidado: membro.cpf,
      lojaId: loja.id,
      nomeLoja: loja.nome,
      papel: membro.papel,
      dataHora: DateTime.now(),
      tipo: TipoNotificacao.remocaoLoja,
    );
    await notificacoes.enviarConvite(notificacaoRemocao);

    _registrarAcao(
      TipoAcao.membroRemovido,
      'Membro "${membro.nome}" removido da loja por "${autor.nome}"',
    );
  }

  void _avisar(String mensagem) {
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

  Future<void> _atualizarPapelMembro(String cpf, PapelMembro papel) async {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final membro = loja?.membros.firstWhere(
      (m) => m.cpf == cpf,
      orElse: () => MembroLoja(
        cpf: cpf,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );

    // Um sócio não pode ter seu papel alterado sem seu consentimento.
    if (membro != null &&
        membro.papel == PapelMembro.socio &&
        papel != PapelMembro.socio) {
      final auth = context.read<AuthProvider>();
      final conta = auth.contaAtual;
      if (conta != null) {
        final notificacao = ConviteLoja(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cpfConvidante: conta.cpf,
          nomeConvidante: conta.nome,
          cpfConvidado: membro.cpf,
          lojaId: widget.lojaId,
          nomeLoja: loja?.nome ?? '',
          papel: papel,
          dataHora: DateTime.now(),
          tipo: TipoNotificacao.alteracaoPapel,
        );

        await context.read<NotificacoesProvider>().enviarConvite(notificacao);
        if (!mounted) return;
        _avisar(
          'Solicitação enviada para ${membro.nome}. A alteração de papel exige o consentimento do sócio.',
        );
        _registrarAcao(
          TipoAcao.papelAlterado,
          'Solicitação de alteração de papel de "${membro.nome}" enviada para consentimento',
        );
        return;
      }
    }

    await context.read<PdvProvider>().atualizarPapelMembro(
          widget.lojaId,
          cpf,
          papel,
        );
    setState(() {
      _membros = _membros
          .map((m) => m.cpf == cpf ? m.copyWith(papel: papel) : m)
          .toList();
    });

    _registrarAcao(
      TipoAcao.papelAlterado,
      'Papel de "${membro?.nome ?? ''}" alterado para '
          '${_rotuloPapelCurto(papel)}',
    );
  }

  Future<void> _sairDaLoja() async {
    await context.read<PdvProvider>().sairDaLoja(widget.lojaId);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  String _rotuloPapelCurto(PapelMembro papel) {
    switch (papel) {
      case PapelMembro.dono:
        return 'Dono';
      case PapelMembro.socio:
        return 'Sócio';
      case PapelMembro.admin:
        return 'Admin';
      case PapelMembro.funcionario:
        return 'Funcionário';
    }
  }

  void _rolarAteOTopo(GlobalKey chave) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextoDoWidget = chave.currentContext;
      if (contextoDoWidget == null) return;
      Scrollable.ensureVisible(
        contextoDoWidget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    });
  }

  void _alternarExpansaoCategoria(String id) {
    final vaiExpandir = _categoriaExpandidaId != id;
    setState(() => _categoriaExpandidaId = vaiExpandir ? id : null);
    if (vaiExpandir) _rolarAteOTopo(_chaveCategoria(id));
  }

  void _alternarExpansaoGrupo(String id) {
    final vaiExpandir = _grupoExpandidoId != id;
    setState(() => _grupoExpandidoId = vaiExpandir ? id : null);
    if (vaiExpandir) _rolarAteOTopo(_chaveGrupo(id));
  }

  void _persistirListasLoja() {
    context.read<PdvProvider>().atualizarListasLoja(
          widget.lojaId,
          categorias: _categorias,
          itens: _itens,
          gruposComponentes: _gruposComponentes,
          clientes: _clientes,
          fornecedores: _fornecedores,
          pedidos: _pedidos,
          mesas: _mesas,
          movimentosEstoque: _movimentosEstoque,
        );
  }

  void _salvarDadosLoja() {
    if (!context.read<PdvProvider>().possoEditarDadosLoja(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    context.read<PdvProvider>().atualizarDadosLoja(
          widget.lojaId,
          nome: _controllers.nome.text,
          cnpj: _controllers.cnpj.text,
          telefone: _controllers.telefone.text,
          endereco: _controllers.endereco.text,
          numero: _controllers.numero.text,
          email: _controllers.email.text,
          redesSociais: _controllers.redesSociais.text,
          categorias: _controllers.categorias.text,
          tags: _controllers.tags.text,
          logo: _logo,
        );

    _registrarAcao(TipoAcao.dadosLojaAtualizados, 'Dados da loja atualizados');

    final theme = ThemeController.currentTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Dados salvos.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _alterarLogoLoja() async {
    if (!context.read<PdvProvider>().possoEditarDadosLoja(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    if (_logo.isNotEmpty) {
      final theme = ThemeController.currentTheme.value;
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Logo da Loja',
        onEscolherNova: _selecionarNovaLogoLoja,
        onRemover: _removerLogoLoja,
      );
    } else {
      await _selecionarNovaLogoLoja();
    }
  }

  void _removerLogoLoja() {
    setState(() => _logo = '');
    _salvarDadosLoja();
  }

  Future<void> _selecionarNovaLogoLoja() async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return;

    final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
    if (salvo == null) {
      if (mounted) {
        final theme = ThemeController.currentTheme.value;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'A logo deve ser uma imagem válida de até meio giga (500MB).',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _logo = salvo);
    _salvarDadosLoja();
  }

  void _adicionarAnexo(TipoAnexoLoja tipo, String caminho) {
    if (!context.read<PdvProvider>().possoEditarDadosLoja(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    setState(() {
      switch (tipo) {
        case TipoAnexoLoja.galeria:
          _galeria.add(caminho);
          break;
        case TipoAnexoLoja.arquivos:
          _arquivos.add(caminho);
          break;
        case TipoAnexoLoja.musicas:
          _musicas.add(caminho);
          break;
        case TipoAnexoLoja.videos:
          _videos.add(caminho);
          break;
        case TipoAnexoLoja.arquivosAudio:
          _arquivosAudio.add(caminho);
          break;
      }
    });
    _persistirAnexosLoja();
  }

  void _removerAnexo(TipoAnexoLoja tipo, int index) {
    if (!context.read<PdvProvider>().possoEditarDadosLoja(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    setState(() {
      switch (tipo) {
        case TipoAnexoLoja.galeria:
          _galeria.removeAt(index);
          break;
        case TipoAnexoLoja.arquivos:
          _arquivos.removeAt(index);
          break;
        case TipoAnexoLoja.musicas:
          _musicas.removeAt(index);
          break;
        case TipoAnexoLoja.videos:
          _videos.removeAt(index);
          break;
        case TipoAnexoLoja.arquivosAudio:
          _arquivosAudio.removeAt(index);
          break;
      }
    });
    _persistirAnexosLoja();
  }

  void _atualizarDescricaoAnexo(String caminho, String novaDescricao) {
    if (!context.read<PdvProvider>().possoEditarDadosLoja(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    setState(() {
      if (novaDescricao.trim().isEmpty) {
        _descricoesAnexos.remove(caminho);
      } else {
        _descricoesAnexos[caminho] = novaDescricao.trim();
      }
    });
    _persistirAnexosLoja();
  }

  void _persistirAnexosLoja() {
    context.read<PdvProvider>().atualizarAnexosLoja(
          widget.lojaId,
          galeria: _galeria,
          arquivos: _arquivos,
          musicas: _musicas,
          videos: _videos,
          arquivosAudio: _arquivosAudio,
          descricoesAnexos: _descricoesAnexos,
        );
  }

  void _alterarStatusPedido(String id, StatusPedido novoStatus) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = _pedidos[indice];

    setState(() {
      _pedidos[indice] = pedido.copyWith(status: novoStatus);
    });
    _persistirListasLoja();

    if (novoStatus == StatusPedido.aceito) {
      _registrarAcao(
        TipoAcao.pedidoAceito,
        'Pedido ${_numeroPedido(pedido.numero)} aceito '
            '(${_valorFormatado(pedido.valor)})',
      );
    } else if (novoStatus == StatusPedido.concluido) {
      _registrarAcao(
        TipoAcao.pedidoConcluido,
        'Pedido ${_numeroPedido(pedido.numero)} concluído '
            '(${_valorFormatado(pedido.valor)})',
      );
    }
  }

  void _iniciarTimerVerificacaoPedidos() {
    _timerVerificacaoPedidos?.cancel();
    _timerVerificacaoPedidos =
        Timer.periodic(const Duration(seconds: 15), (_) {
      _verificarPedidosTempoConclusao();
    });
  }

  void _verificarPedidosTempoConclusao() {
    if (!mounted || _tempoConclusaoMinutos <= 0) return;
    final agora = DateTime.now();
    for (final pedido in _pedidos) {
      if (pedido.status == StatusPedido.aceito &&
          !_pedidosPerguntados.contains(pedido.id)) {
        final minutosDecorridos =
            agora.difference(pedido.dataHora).inMinutes;
        if (minutosDecorridos >= _tempoConclusaoMinutos) {
          _pedidosPerguntados.add(pedido.id);
          _perguntarConclusaoPedido(pedido);
          break;
        }
      }
    }
  }

  Future<void> _perguntarConclusaoPedido(PedidoLoja pedido) async {
    if (!mounted) return;
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    SomService.tocarEvento(SomService.eventoConclusaoPedido, loja: loja);

    final theme = ThemeController.currentTheme.value;
    final minutosDecorridos =
        DateTime.now().difference(pedido.dataHora).inMinutes;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.buttonColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: theme.buttonColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tempo Estimado Atingido',
                                style: theme.getTextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pedido ${_numeroPedido(pedido.numero)} decorreu $minutosDecorridos min',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'O Pedido ${_numeroPedido(pedido.numero)}${pedido.clienteNome.isNotEmpty ? " (${pedido.clienteNome})" : ""} atingiu o tempo de conclusão estipulado ($_tempoConclusaoMinutos min).\n\nEste pedido já foi concluído?',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Ainda não',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _alterarStatusPedido(
                              pedido.id,
                              StatusPedido.concluido,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                content: Text(
                                  'Pedido ${_numeroPedido(pedido.numero)} marcado como concluído!',
                                  style: theme.getTextStyle(
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Sim, concluir pedido',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _salvarComentarioPedido(String id, DadosComentario dados) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = _pedidos[indice];

    setState(() {
      _pedidos[indice] = pedido.copyWith(
        comentario: dados.texto,
        comentarioAutorCpf: dados.cpfAutor,
        comentarioAutorNome: dados.nomeAutor,
        comentarioAutorEmail: dados.emailAutor,
        comentarioDataHora: dados.dataHora,
      );
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.comentarioSalvo,
      'Comentário salvo no pedido ${_numeroPedido(pedido.numero)}',
    );
  }

  Future<void> _cancelarPedidoComDialog(String id) async {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = _pedidos[indice];

    final resultado = await CancelarPedidoDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      pedido: pedido,
    );

    if (resultado == null || !mounted) return;

    setState(() {
      _pedidos[indice] = pedido.copyWith(
        status: StatusPedido.cancelado,
        motivoCancelamento: resultado.motivo,
        dataHoraCancelamento: DateTime.now(),
        canceladoPorCpf: _cpfLogado,
        canceladoPorNome: _nomeLogado,
        estoqueEstornado: resultado.devolverEstoque,
      );

      if (resultado.devolverEstoque) {
        for (final item in pedido.itens) {
          final mov = MovimentoEstoque.novo(
            itemId: item.itemId,
            tipo: TipoMovimentoEstoque.entrada,
            quantidade: item.quantidade.toDouble(),
            motivo:
                'Estorno - Pedido ${_numeroPedido(pedido.numero)} cancelado: ${resultado.motivo}',
            cpfAutor: _cpfLogado,
            nomeAutor: _nomeLogado,
            categoria: CategoriaMovimentoEstoque.ajuste,
          );
          _movimentosEstoque.add(mov);
        }
      }
    });

    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.pedidoCancelado,
      'Pedido ${_numeroPedido(pedido.numero)} cancelado '
          '(${_valorFormatado(pedido.valor)}). Motivo: ${resultado.motivo}'
          '${resultado.devolverEstoque ? " [Estoque estornado]" : ""}',
    );

    if (resultado.devolverEstoque) {
      for (final item in pedido.itens) {
        _registrarAcao(
          TipoAcao.movimentoEstoqueRegistrado,
          'Estorno de estoque: ${_formatarQuantidade(item.quantidade.toDouble())} de '
              '"${item.nomeItem}" pelo cancelamento do pedido ${_numeroPedido(pedido.numero)}',
        );
      }
    }
  }

  void _recusarPedido(String id) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = _pedidos[indice];

    setState(() => _pedidos.removeAt(indice));
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.pedidoRecusado,
      'Pedido ${_numeroPedido(pedido.numero)} recusado '
          '(${_valorFormatado(pedido.valor)})',
    );
  }

  void _excluirPedido(String id) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = _pedidos[indice];

    setState(() => _pedidos.removeAt(indice));
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.pedidoExcluido,
      'Pedido ${_numeroPedido(pedido.numero)} excluído '
          '(${_valorFormatado(pedido.valor)})',
    );
  }

  void _salvarCliente(Cliente cliente) {
    final existia = _clientes.any((c) => c.id == cliente.id);

    setState(() {
      final indice = _clientes.indexWhere((c) => c.id == cliente.id);
      if (indice == -1) {
        _clientes.add(cliente);
      } else {
        _clientes[indice] = cliente;
      }
    });
    _persistirListasLoja();

    final cpfDigitos = _cpfLogado.replaceAll(RegExp(r'[^0-9]'), '');
    final clienteDigitos = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpfDigitos.isNotEmpty &&
        cpfDigitos == clienteDigitos &&
        cliente.foto.isNotEmpty) {
      context.read<AuthProvider>().atualizarFoto(cliente.foto);
    }

    _registrarAcao(
      existia ? TipoAcao.clienteAtualizado : TipoAcao.clienteCriado,
      existia
          ? 'Cliente "${cliente.nome}" atualizado'
          : 'Cliente "${cliente.nome}" cadastrado',
    );
  }

  void _pagarCliente(String clienteId, double valor) {
    final atualizados = aplicarPagamentoAPrazo(_pedidos, clienteId, valor);
    setState(() {
      _pedidos
        ..clear()
        ..addAll(atualizados);
    });
    _persistirListasLoja();

    final indiceCliente = _clientes.indexWhere((c) => c.id == clienteId);
    final nomeCliente =
        indiceCliente == -1 ? '' : _clientes[indiceCliente].nome;

    _registrarAcao(
      TipoAcao.pagamentoPrazoRecebido,
      'Pagamento à prazo recebido de "$nomeCliente" '
          '(${_valorFormatado(valor)})',
    );
  }

  void _excluirCliente(String clienteId) {
    final indice = _clientes.indexWhere((c) => c.id == clienteId);
    final nome = indice == -1 ? '' : _clientes[indice].nome;

    setState(() => _clientes.removeWhere((c) => c.id == clienteId));
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.clienteExcluido,
      'Cliente "$nome" excluído',
    );
  }

  void _salvarFornecedor(Fornecedor fornecedor) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final existia = _fornecedores.any((f) => f.id == fornecedor.id);

    setState(() {
      final indice =
          _fornecedores.indexWhere((f) => f.id == fornecedor.id);
      if (indice == -1) {
        _fornecedores.add(fornecedor);
      } else {
        _fornecedores[indice] = fornecedor;
      }
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.dadosLojaAtualizados,
      existia
          ? 'Fornecedor "${fornecedor.nome}" atualizado'
          : 'Fornecedor "${fornecedor.nome}" cadastrado',
    );
  }

  void _excluirFornecedor(String fornecedorId) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final indice = _fornecedores.indexWhere((f) => f.id == fornecedorId);
    final nome = indice == -1 ? '' : _fornecedores[indice].nome;

    setState(
        () => _fornecedores.removeWhere((f) => f.id == fornecedorId));
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.dadosLojaAtualizados,
      'Fornecedor "$nome" excluído',
    );
  }

  Future<void> _abrirPopupClientes() {
    return ClientesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: widget.lojaId,
      clientes: _clientes,
      pedidos: _pedidos,
      onSalvar: _salvarCliente,
      onPagar: _pagarCliente,
      onExcluir: _excluirCliente,
    );
  }

  Future<void> _abrirPopupClienteEspecifico(String clienteId) {
    return ClientesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: widget.lojaId,
      clientes: _clientes,
      pedidos: _pedidos,
      onSalvar: _salvarCliente,
      onPagar: _pagarCliente,
      onExcluir: _excluirCliente,
      clienteInicialId: clienteId,
    );
  }

  Future<void> _abrirPopupFornecedores() {
    return FornecedoresDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      clientes: _clientes,
      fornecedores: _fornecedores,
      onSalvar: _salvarFornecedor,
      onExcluir: _excluirFornecedor,
    );
  }

  Future<void> _abrirPopupRelatorios() {
    return RelatoriosDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: widget.lojaId,
      pedidos: List.of(_pedidos),
      autorCpf: _cpfLogado,
      autorNome: _nomeLogado,
      autorEmail: _emailLogado,
      onExcluirPedido: _excluirPedido,
      onSalvarComentario: _salvarComentarioPedido,
      aoAbrirClientes: _abrirPopupClienteEspecifico,
    );
  }

  void _abrirPopupImpressora() {
    if (!context.read<PdvProvider>().possoUsarImpressora(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final atuais =
        loja?.configuracoesImpressora ?? const ConfiguracoesImpressora();

    ImpressoraDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      configuracoes: atuais,
      onSalvar: (configuracoes) {
        context
            .read<PdvProvider>()
            .atualizarConfiguracoesImpressora(widget.lojaId, configuracoes);
      },
    );
  }

  void _abrirFinanceiro() {
    if (!context.read<PdvProvider>().possoUsarFinanceiro(widget.lojaId)) {
      _avisarSemPermissao();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FinanceiroView(
          lojaId: widget.lojaId,
          pedidos: List.of(_pedidos),
        ),
      ),
    );
  }

  void _abrirPopupCaixa() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    if (loja == null) return;

    CaixaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaNome: loja.nome,
      lojaCnpj: loja.cnpj,
      turnoAberto: loja.turnoCaixaAberto,
      pedidosLoja: _pedidos,
      configuracoesImpressora: loja.configuracoesImpressora,
      aoAbrirCaixa: (saldoInicial) async {
        await context.read<PdvProvider>().abrirCaixa(
              widget.lojaId,
              saldoInicial,
              cpf: _cpfLogado,
              nome: _nomeLogado,
            );
        _registrarAcao(
          TipoAcao.caixaAberto,
          'Caixa aberto com fundo de ${_valorFormatado(saldoInicial)}',
        );
        setState(() {});
      },
      aoRegistrarMovimento: (tipo, valor, motivo) async {
        await context.read<PdvProvider>().registrarMovimentoCaixa(
              widget.lojaId,
              tipo: tipo,
              valor: valor,
              motivo: motivo,
              cpf: _cpfLogado,
              nome: _nomeLogado,
            );
        final rotulo =
            tipo == TipoMovimentoCaixa.sangria ? 'Sangria' : 'Suprimento';
        _registrarAcao(
          tipo == TipoMovimentoCaixa.sangria
              ? TipoAcao.sangriaRegistrada
              : TipoAcao.suprimentoRegistrado,
          '$rotulo de ${_valorFormatado(valor)} registrado ($motivo)',
        );
        setState(() {});
      },
      aoFecharCaixa: (saldoInformado, observacao) async {
        await context.read<PdvProvider>().fecharCaixa(
              widget.lojaId,
              saldoInformado,
              cpf: _cpfLogado,
              nome: _nomeLogado,
              observacao: observacao,
            );
        _registrarAcao(
          TipoAcao.caixaFechado,
          'Caixa fechado. Saldo informado: ${_valorFormatado(saldoInformado)}',
        );
        setState(() {});
      },
    );
  }

  bool get _ehRestaurante {
    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final categorias =
        (lojaAtual?.categorias ?? _controllers.categorias.text).toLowerCase();
    return categorias.contains('restaurante');
  }

  void _abrirCriarMesa() {
    CriarMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      aoSalvar: (novaMesa) {
        setState(() => _mesas.add(novaMesa));
        _persistirListasLoja();
        _registrarAcao(
          TipoAcao.mesaCriada,
          'Mesa "${novaMesa.numero}" cadastrada no salão',
        );
      },
    );
  }

  void _abrirComandaMesa(MesaLoja mesa) {
    final indice = _mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1) return;

    ComandaMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesa: _mesas[indice],
      categoriasDisponiveis: _categorias,
      itensDisponiveis: _itens,
      gruposDisponiveis: _gruposComponentes,
      todasMesas: _mesas,
      autorCpf: _cpfLogado,
      autorNome: _nomeLogado,
      aoAtualizarMesa: (mesaAtualizada) {
        final statusMudou = _mesas[indice].status != mesaAtualizada.status;
        final novosItens =
            mesaAtualizada.itens.length > _mesas[indice].itens.length;
        setState(() => _mesas[indice] = mesaAtualizada);
        _persistirListasLoja();

        if (statusMudou && mesaAtualizada.status == StatusMesa.ocupada) {
          _registrarAcao(
            TipoAcao.mesaAberta,
            'Mesa "${mesaAtualizada.numero}" aberta por $_nomeLogado'
            '${mesaAtualizada.clienteNome.isNotEmpty ? " (Cliente: ${mesaAtualizada.clienteNome})" : ""}',
          );
        } else if (novosItens) {
          final ultimoItem = mesaAtualizada.itens.last;
          _registrarAcao(
            TipoAcao.itemAdicionadoMesa,
            'Adicionado ${ultimoItem.item.quantidade}x "${ultimoItem.item.nomeItem}" na Mesa "${mesaAtualizada.numero}" por ${ultimoItem.autorNome}',
          );
        }
      },
      aoFecharConta: (mesaParaFechar) {
        _fecharContaMesa(mesaParaFechar);
      },
      aoImprimirConferencia: (mesaConferencia) {
        final lojaAtual =
            context.read<PdvProvider>().buscarPorId(widget.lojaId);
        ImpressaoService.imprimirConferenciaMesa(
          config: lojaAtual?.configuracoesImpressora ??
              const ConfiguracoesImpressora(),
          mesa: mesaConferencia,
          nomeLoja: lojaAtual?.nome ?? 'Restaurante',
        );
      },
      aoTransferirMesa: (mesaOrigem, mesaDestino) {
        _transferirMesa(mesaOrigem, mesaDestino);
      },
      aoEditarMesa: () {
        _editarMesa(mesa);
      },
    );
  }

  void _transferirMesa(MesaLoja origem, MesaLoja destino) {
    final idxOrigem = _mesas.indexWhere((m) => m.id == origem.id);
    final idxDestino = _mesas.indexWhere((m) => m.id == destino.id);
    if (idxOrigem == -1 || idxDestino == -1) return;

    final mesaOrigem = _mesas[idxOrigem];
    final mesaDestino = _mesas[idxDestino];

    if (mesaDestino.status == StatusMesa.livre) {
      final destinoAtualizada = mesaDestino.copyWith(
        status: StatusMesa.ocupada,
        clienteNome: mesaOrigem.clienteNome,
        atendenteCpf: mesaOrigem.atendenteCpf,
        atendenteNome: mesaOrigem.atendenteNome,
        dataHoraAbertura: mesaOrigem.dataHoraAbertura ?? DateTime.now(),
        itens: List.of(mesaOrigem.itens),
      );
      final origemLiberada = mesaOrigem.copyWith(
        status: StatusMesa.livre,
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
        itens: const [],
      );

      setState(() {
        _mesas[idxDestino] = destinoAtualizada;
        _mesas[idxOrigem] = origemLiberada;
      });
      _persistirListasLoja();

      _registrarAcao(
        TipoAcao.mesaTransferida,
        'Comanda da Mesa "${origem.numero}" transferida para a Mesa "${destino.numero}" por $_nomeLogado',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comanda da Mesa ${origem.numero} transferida com sucesso para a Mesa ${destino.numero}!',
            ),
          ),
        );
      }
    } else {
      final clienteFinal = mesaDestino.clienteNome.isNotEmpty
          ? mesaDestino.clienteNome
          : mesaOrigem.clienteNome;
      final destinoAtualizada = mesaDestino.copyWith(
        clienteNome: clienteFinal,
        itens: [...mesaDestino.itens, ...mesaOrigem.itens],
      );
      final origemLiberada = mesaOrigem.copyWith(
        status: StatusMesa.livre,
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
        itens: const [],
      );

      setState(() {
        _mesas[idxDestino] = destinoAtualizada;
        _mesas[idxOrigem] = origemLiberada;
      });
      _persistirListasLoja();

      _registrarAcao(
        TipoAcao.mesaTransferida,
        'Comanda da Mesa "${origem.numero}" unificada à Mesa "${destino.numero}" por $_nomeLogado',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comanda da Mesa ${origem.numero} unificada à Mesa ${destino.numero}!',
            ),
          ),
        );
      }
    }
  }

  void _editarMesa(MesaLoja mesa) {
    final indice = _mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1) return;

    CriarMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesaExistente: _mesas[indice],
      aoSalvar: (mesaEditada) {
        setState(() => _mesas[indice] = mesaEditada);
        _persistirListasLoja();
      },
      aoExcluir: _mesas[indice].status == StatusMesa.livre
          ? () {
              setState(() => _mesas.removeAt(indice));
              _persistirListasLoja();
              _registrarAcao(
                TipoAcao.mesaExcluida,
                'Mesa "${mesa.numero}" removida do restaurante',
              );
            }
          : null,
    );
  }

  Future<void> _fecharContaMesa(MesaLoja mesa) async {
    final indice = _mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1 || mesa.itens.isEmpty) return;

    final resultado = await FecharContaMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesa: mesa,
    );

    if (resultado == null || !mounted) return;

    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final proximoNumero = _pedidos.fold<int>(
          0,
          (maior, p) => p.numero > maior ? p.numero : maior,
        ) +
        1;

    final itensVendidos = mesa.itens.map((i) => i.item).toList();
    final totalValor = mesa.totalAcumulado;
    final nomesItens = itensVendidos
        .map((i) => '${i.quantidade}x ${i.nomeItem}')
        .join(', ');

    final pedido = PedidoLoja(
      id: gerarIdUnico(),
      numero: proximoNumero,
      clienteId: '',
      clienteNome: mesa.clienteNome.isNotEmpty
          ? mesa.clienteNome
          : 'Mesa ${mesa.numero}',
      produtoNome: nomesItens.isNotEmpty
          ? nomesItens
          : 'Consumo Mesa ${mesa.numero}',
      itens: itensVendidos,
      formaPagamento: resultado.formaPagamento,
      pagamentosExtras: resultado.pagamentos.length > 1
          ? resultado.pagamentos.sublist(1)
          : const [],
      desconto: resultado.desconto,
      acrescimo: resultado.acrescimo,
      valor: resultado.valorFinal,
      dataHora: DateTime.now(),
      status: StatusPedido.concluido,
      nomeVendedor: lojaAtual?.nome ?? '',
      cnpjVendedor: lojaAtual?.cnpj ?? '',
      comentario: 'Mesa ${mesa.numero} atendida por ${mesa.atendenteNome}',
    );

    final novosMovimentos = <MovimentoEstoque>[];
    if (resultado.baixarEstoque) {
      for (final item in itensVendidos) {
        novosMovimentos.add(
          MovimentoEstoque.novo(
            itemId: item.itemId,
            tipo: TipoMovimentoEstoque.saida,
            quantidade: item.quantidade.toDouble(),
            motivo:
                'Consumo Mesa ${mesa.numero} - Pedido #${_numeroPedido(proximoNumero)}',
            cpfAutor: _cpfLogado,
            nomeAutor: _nomeLogado,
            categoria: CategoriaMovimentoEstoque.venda,
          ),
        );
        for (final acomp in item.acompanhamentos) {
          novosMovimentos.add(
            MovimentoEstoque.novo(
              itemId: acomp.itemId,
              tipo: TipoMovimentoEstoque.saida,
              quantidade:
                  (acomp.quantidadePorUnidade * item.quantidade).toDouble(),
              motivo:
                  'Acompanhamento Mesa ${mesa.numero} - Pedido #${_numeroPedido(proximoNumero)}',
              cpfAutor: _cpfLogado,
              nomeAutor: _nomeLogado,
              categoria: CategoriaMovimentoEstoque.venda,
            ),
          );
        }
      }
    }

    setState(() {
      _pedidos.add(pedido);
      _movimentosEstoque.addAll(novosMovimentos);
      _mesas[indice] = mesa.copyWith(
        status: StatusMesa.livre,
        itens: const [],
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
      );
    });

    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.mesaFechada,
      'Mesa "${mesa.numero}" fechada (${_valorFormatado(totalValor)} via ${resultado.formaPagamento}) por $_nomeLogado',
    );
    _registrarAcao(
      TipoAcao.novaVenda,
      'Nova venda #${_numeroPedido(proximoNumero)} da Mesa "${mesa.numero}" (${_valorFormatado(totalValor)})',
    );
    _registrarAcao(
      TipoAcao.pedidoConcluido,
      'Pedido #${_numeroPedido(proximoNumero)} concluído (${_valorFormatado(totalValor)})',
    );

    for (final mov in novosMovimentos) {
      _registrarAcao(
        TipoAcao.movimentoEstoqueRegistrado,
        'Baixa de estoque: ${_formatarQuantidade(mov.quantidade)} pelo fechamento da Mesa "${mesa.numero}"',
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            ThemeController.currentTheme.value.cardBackgroundColor,
        content: Text(
          'Conta da Mesa ${mesa.numero} fechada com sucesso!',
          style: ThemeController.currentTheme.value.getTextStyle(
            color: ThemeController.currentTheme.value.textColor,
          ),
        ),
      ),
    );
  }

  void _abrirStatusLoja() {
    final cpfLogado = context.read<AuthProvider>().contaAtual?.cpf ?? '';
    final meuPapel = context.read<PdvProvider>().meuPapel(widget.lojaId);
    final podeSair = meuPapel != null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatusLojaView(
          lojaId: widget.lojaId,
          lojaOnlineInicial: _lojaOnline,
          aoAlterarOnline: (valor) => setState(() => _lojaOnline = valor),
          membros: List.of(_membros),
          cpfLogado: cpfLogado,
          podeSair: podeSair,
          onSair: _sairDaLoja,
        ),
      ),
    );
  }

  void _abrirPopupNovaVenda() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final proximoNumero = _pedidos.fold<int>(
          0,
          (maior, pedido) => pedido.numero > maior ? pedido.numero : maior,
        ) +
        1;

    NovaVendaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      lojaId: widget.lojaId,
      itensDisponiveis: _itens,
      categoriasDisponiveis: _categorias,
      gruposDisponiveis: _gruposComponentes,
      obterClientes: () => _clientes,
      aoAbrirClientes: _abrirPopupClientes,
      nomeVendedor: loja?.nome ?? '',
      cnpjVendedor: loja?.cnpj ?? '',
      proximoNumero: proximoNumero,
      cpfAutor: _cpfLogado,
      nomeAutor: _nomeLogado,
      configuracoesImpressora:
          loja?.configuracoesImpressora ?? const ConfiguracoesImpressora(),
      movimentosEstoque: _movimentosEstoque,
      onConcluir: (pedido, movimentosEstoque) {
        setState(() {
          _pedidos.add(pedido);
          _abaPedidos = AbaPedidos.aceitos;
          for (final m in movimentosEstoque) {
            _movimentosEstoque.add(m);
          }
        });
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.novaVenda,
          'Nova venda ${_numeroPedido(pedido.numero)} para '
              '"${pedido.clienteNome}" (${_valorFormatado(pedido.valor)})',
        );

        for (final movimento in movimentosEstoque) {
          final item = _itens.firstWhere(
            (i) => i.id == movimento.itemId,
            orElse: () => const ItemLoja(id: '', nome: ''),
          );
          final quantidade = _formatarQuantidade(movimento.quantidade);
          final unidade = _rotuloUnidadeCurto(item.unidadeBase);
          _registrarAcao(
            TipoAcao.movimentoEstoqueRegistrado,
            'Baixa automática de $quantidade $unidade de '
                '"${item.nome}" pelo pedido ${_numeroPedido(pedido.numero)}',
          );
        }
      },
      aoCriarItem: (item, categoriaIds, grupoIds) async {
        setState(() => _itens.add(item));
        _sincronizarVinculosItem(item.id, categoriaIds, grupoIds);
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.itemCriado,
          'Item "${item.nome}" criado',
        );
      },
    );
  }

  void _abrirPopupNovoGrupoComponentes() {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      onCriar: (grupo) {
        setState(() => _gruposComponentes.add(grupo));
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${grupo.nome}" criado',
        );
      },
    );
  }

  void _abrirPopupEditarGrupoComponentes(GrupoComponentesLoja grupo) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: _itens,
      grupoParaEditar: grupo,
      onCriar: (grupoEditado) {
        setState(() {
          final indice =
              _gruposComponentes.indexWhere((g) => g.id == grupoEditado.id);
          if (indice != -1) _gruposComponentes[indice] = grupoEditado;
        });
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.grupoAtualizado,
          'Grupo de componentes "${grupoEditado.nome}" atualizado',
        );
      },
    );
  }

  void _abrirPopupNovaCategoria() {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    NovaCategoriaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      gruposComponentes: _gruposComponentes,
      onCriar: (categoria) {
        setState(() => _categorias.add(categoria));
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${categoria.nome}" criada',
        );
      },
    );
  }

  void _abrirPopupEditarCategoria(CategoriaLoja categoria) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    NovaCategoriaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      gruposComponentes: _gruposComponentes,
      categoriaParaEditar: categoria,
      onCriar: (categoriaEditada) {
        setState(() {
          final indice =
              _categorias.indexWhere((c) => c.id == categoriaEditada.id);
          if (indice != -1) _categorias[indice] = categoriaEditada;
        });
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.categoriaAtualizada,
          'Categoria "${categoriaEditada.nome}" atualizada',
        );
      },
    );
  }

  void _sincronizarVinculosItem(
    String itemId,
    List<String> categoriaIds,
    List<String> grupoIds,
  ) {
    setState(() {
      for (var i = 0; i < _categorias.length; i++) {
        final categoria = _categorias[i];
        final deveConter = categoriaIds.contains(categoria.id);
        final contem = categoria.itemIds.contains(itemId);
        if (deveConter && !contem) {
          _categorias[i] =
              categoria.copyWith(itemIds: [...categoria.itemIds, itemId]);
        } else if (!deveConter && contem) {
          _categorias[i] = categoria.copyWith(
            itemIds:
                categoria.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }

      for (var i = 0; i < _gruposComponentes.length; i++) {
        final grupo = _gruposComponentes[i];
        final deveConter = grupoIds.contains(grupo.id);
        final contem = grupo.itemIds.contains(itemId);
        if (deveConter && !contem) {
          _gruposComponentes[i] =
              grupo.copyWith(itemIds: [...grupo.itemIds, itemId]);
        } else if (!deveConter && contem) {
          _gruposComponentes[i] = grupo.copyWith(
            itemIds: grupo.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }
    });
  }

  void _abrirPopupNovoItem() {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      onCategoriaCriada: (novaCategoria) {
        setState(() => _categorias.add(novaCategoria));
        _persistirListasLoja();
        _registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${novaCategoria.nome}" criada pelo cadastro de item',
        );
      },
      onGrupoCriado: (novoGrupo) {
        setState(() => _gruposComponentes.add(novoGrupo));
        _persistirListasLoja();
        _registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${novoGrupo.nome}" criado pelo cadastro de item',
        );
      },
      onCriar: (item, categoriaIds, grupoIds) {
        setState(() => _itens.add(item));
        _sincronizarVinculosItem(item.id, categoriaIds, grupoIds);
        _persistirListasLoja();

        _registrarAcao(
          TipoAcao.itemCriado,
          'Item "${item.nome}" criado',
        );
      },
    );
  }

  void _abrirPopupEditarItem(ItemLoja item) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final categoriaIdsIniciais = _categorias
        .where((c) => c.itemIds.contains(item.id))
        .map((c) => c.id)
        .toList();
    final grupoIdsIniciais = _gruposComponentes
        .where((g) => g.itemIds.contains(item.id))
        .map((g) => g.id)
        .toList();

    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: _categorias,
      gruposComponentes: _gruposComponentes,
      itemParaEditar: item,
      categoriaIdsIniciais: categoriaIdsIniciais,
      grupoIdsIniciais: grupoIdsIniciais,
      onCategoriaCriada: (novaCategoria) {
        setState(() => _categorias.add(novaCategoria));
        _persistirListasLoja();
        _registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${novaCategoria.nome}" criada pelo cadastro de item',
        );
      },
      onGrupoCriado: (novoGrupo) {
        setState(() => _gruposComponentes.add(novoGrupo));
        _persistirListasLoja();
        _registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${novoGrupo.nome}" criado pelo cadastro de item',
        );
      },
      onCriar: (itemEditado, categoriaIds, grupoIds) {
        final anterior = _itens.firstWhere(
          (i) => i.id == itemEditado.id,
          orElse: () => itemEditado,
        );

        setState(() {
          final indice = _itens.indexWhere((i) => i.id == itemEditado.id);
          if (indice != -1) _itens[indice] = itemEditado;
        });
        _sincronizarVinculosItem(itemEditado.id, categoriaIds, grupoIds);
        _persistirListasLoja();

        final mudouNome = anterior.nome != itemEditado.nome;
        final mudouPreco = anterior.preco != itemEditado.preco;

        if (mudouPreco && mudouNome) {
          _registrarAcao(
            TipoAcao.itemAtualizado,
            'Item "${anterior.nome}" renomeado para '
                '"${itemEditado.nome}" e preço alterado de '
                'R\$ ${anterior.preco} para R\$ ${itemEditado.preco}',
          );
        } else if (mudouPreco) {
          _registrarAcao(
            TipoAcao.itemAtualizado,
            'Preço de "${itemEditado.nome}" alterado de '
                'R\$ ${anterior.preco} para R\$ ${itemEditado.preco}',
          );
        } else {
          _registrarAcao(
            TipoAcao.itemAtualizado,
            'Item "${itemEditado.nome}" atualizado',
          );
        }
      },
    );
  }

  void _editarNomeItem(String id, String novoNome) {
    if (!_podeEditarAbaLoja()) return;
    final indice = _itens.indexWhere((i) => i.id == id);
    if (indice == -1) return;
    final anterior = _itens[indice];
    if (anterior.nome == novoNome) return;

    setState(() {
      _itens[indice] = anterior.copyWith(nome: novoNome);
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.itemAtualizado,
      'Item "${anterior.nome}" renomeado para "$novoNome"',
    );
  }

  void _editarPrecoItem(String id, String novoPreco) {
    if (!_podeEditarAbaLoja()) return;
    final indice = _itens.indexWhere((i) => i.id == id);
    if (indice == -1) return;
    final anterior = _itens[indice];
    if (anterior.preco == novoPreco) return;

    setState(() {
      _itens[indice] = anterior.copyWith(preco: novoPreco);
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.itemAtualizado,
      'Preço de "${anterior.nome}" alterado de '
          'R\$ ${anterior.preco} para R\$ $novoPreco',
    );
  }

  void _editarNomeCategoria(String id, String novoNome) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == id);
      if (indice == -1) return;
      _categorias[indice] = _categorias[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.categoriaAtualizada,
      'Categoria renomeada para "$novoNome"',
    );
  }

  void _editarNomeGrupoComponentes(String id, String novoNome) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == id);
      if (indice == -1) return;
      _gruposComponentes[indice] =
          _gruposComponentes[indice].copyWith(nome: novoNome);
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.grupoAtualizado,
      'Grupo de componentes renomeado para "$novoNome"',
    );
  }

  void _removerCategoria(String id) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final indice = _categorias.indexWhere((c) => c.id == id);
    final nome = indice == -1 ? '' : _categorias[indice].nome;

    setState(() {
      _categorias.removeWhere((categoria) => categoria.id == id);
      if (_categoriaExpandidaId == id) _categoriaExpandidaId = null;
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.categoriaExcluida,
      'Categoria "$nome" excluída',
    );
  }

  void _removerItem(String id) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final indice = _itens.indexWhere((i) => i.id == id);
    final nome = indice == -1 ? '' : _itens[indice].nome;

    setState(() {
      _itens.removeWhere((item) => item.id == id);

      for (var i = 0; i < _categorias.length; i++) {
        if (_categorias[i].itemIds.contains(id)) {
          _categorias[i] = _categorias[i].copyWith(
            itemIds:
                _categorias[i].itemIds.where((itemId) => itemId != id).toList(),
          );
        }
      }

      for (var i = 0; i < _gruposComponentes.length; i++) {
        if (_gruposComponentes[i].itemIds.contains(id)) {
          _gruposComponentes[i] = _gruposComponentes[i].copyWith(
            itemIds: _gruposComponentes[i]
                .itemIds
                .where((itemId) => itemId != id)
                .toList(),
          );
        }
      }
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.itemExcluido,
      'Item "$nome" excluído',
    );
  }

  void _removerGrupoComponentes(String id) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final indice = _gruposComponentes.indexWhere((g) => g.id == id);
    final nome = indice == -1 ? '' : _gruposComponentes[indice].nome;

    setState(() {
      _gruposComponentes.removeWhere((grupo) => grupo.id == id);
      if (_grupoExpandidoId == id) _grupoExpandidoId = null;

      for (var i = 0; i < _categorias.length; i++) {
        if (_categorias[i].grupoIds.contains(id)) {
          _categorias[i] = _categorias[i].copyWith(
            grupoIds:
                _categorias[i].grupoIds.where((gId) => gId != id).toList(),
          );
        }
      }
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.grupoExcluido,
      'Grupo de componentes "$nome" excluído',
    );
  }

  void _adicionarItemNaCategoria(CategoriaLoja categoria, String itemId) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds = [...categoria.itemIds, itemId];
      _categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();

    final itemIndice = _itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : _itens[itemIndice].nome;

    _registrarAcao(
      TipoAcao.itemVinculadoCategoria,
      'Item "$nomeItem" vinculado à categoria "${categoria.nome}"',
    );
  }

  void _removerItemDaCategoria(CategoriaLoja categoria, String itemId) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds =
          categoria.itemIds.where((id) => id != itemId).toList();
      _categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();

    final itemIndice = _itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : _itens[itemIndice].nome;

    _registrarAcao(
      TipoAcao.itemDesvinculadoCategoria,
      'Item "$nomeItem" desvinculado da categoria "${categoria.nome}"',
    );
  }

  void _adicionarItemNoGrupoComponentes(
      GrupoComponentesLoja grupo, String itemId) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = [...grupo.itemIds, itemId];
      _gruposComponentes[indice] = grupo.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();

    final itemIndice = _itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : _itens[itemIndice].nome;

    _registrarAcao(
      TipoAcao.itemVinculadoGrupo,
      'Item "$nomeItem" vinculado ao grupo "${grupo.nome}"',
    );
  }

  void _removerItemDoGrupoComponentes(
      GrupoComponentesLoja grupo, String itemId) {
    if (!_podeEditarAbaLoja()) return;
    setState(() {
      final indice = _gruposComponentes.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = grupo.itemIds.where((id) => id != itemId).toList();
      _gruposComponentes[indice] = grupo.copyWith(itemIds: novosIds);
    });
    _persistirListasLoja();

    final itemIndice = _itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : _itens[itemIndice].nome;

    _registrarAcao(
      TipoAcao.itemDesvinculadoGrupo,
      'Item "$nomeItem" desvinculado do grupo "${grupo.nome}"',
    );
  }

  Future<void> _abrirPopupNovoMovimento() async {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final movimento = await MovimentoEstoqueDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itens: _itens,
      fornecedores: _fornecedores,
      cpfAutor: _cpfLogado,
      nomeAutor: _nomeLogado,
    );

    if (movimento == null) return;
    if (!mounted) return;

    setState(() => _movimentosEstoque.add(movimento));
    _persistirListasLoja();

    final item = _itens.firstWhere(
      (i) => i.id == movimento.itemId,
      orElse: () => const ItemLoja(id: '', nome: ''),
    );
    final tipo = movimento.ehEntrada ? 'Entrada' : 'Saída';
    final sufixoFornecedor = movimento.fornecedorNome.isNotEmpty
        ? ' de "${movimento.fornecedorNome}"'
        : '';

    _registrarAcao(
      TipoAcao.movimentoEstoqueRegistrado,
      '$tipo$sufixoFornecedor de ${_formatarQuantidade(movimento.quantidade)} '
          '${_rotuloUnidadeCurto(item.unidadeBase)} em "${item.nome}"',
    );
  }

  void _removerMovimentoEstoque(MovimentoEstoque movimento) {
    if (!_podeEditarAbaLoja()) {
      _avisarSemPermissao();
      return;
    }

    final item = _itens.firstWhere(
      (i) => i.id == movimento.itemId,
      orElse: () => const ItemLoja(id: '', nome: ''),
    );

    setState(() {
      _movimentosEstoque.removeWhere((m) => m.id == movimento.id);
    });
    _persistirListasLoja();

    _registrarAcao(
      TipoAcao.movimentoEstoqueRemovido,
      'Movimento de "${item.nome}" removido',
    );
  }

  void _abrirPopupEstoque() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (valueContext, theme, child) {
            return StatefulBuilder(
              builder: (statefulContext, setDialogState) {
                return Dialog(
                  backgroundColor: theme.cardBackgroundColor,
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.borderColor),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 600,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.textColor,
                                ),
                                onPressed: () =>
                                    Navigator.of(statefulContext).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  'Estoque',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: EstoqueContainer(
                              theme: theme,
                              itens: _itens,
                              movimentos: _movimentosEstoque,
                              podeEditar: context
                                  .read<PdvProvider>()
                                  .possoEditarAbaLoja(widget.lojaId),
                              onNovoMovimento: () async {
                                await _abrirPopupNovoMovimento();
                                setDialogState(() {});
                              },
                              onRemoverMovimento: (movimento) {
                                _removerMovimentoEstoque(movimento);
                                setDialogState(() {});
                              },
                              onAvisarSemPermissao: _avisarSemPermissao,
                              onAbrirFornecedores: () async {
                                await _abrirPopupFornecedores();
                                setDialogState(() {});
                              },
                              emDialog: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _abaSelecionada = widget.abaInicial;

    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);

    _controllers.nome.text = loja?.nome ?? '';
    _controllers.cnpj.text = loja?.cnpj ?? '';
    _controllers.telefone.text = loja?.telefone ?? '';
    _controllers.endereco.text = loja?.endereco ?? '';
    _controllers.numero.text = loja?.numero ?? '';
    _controllers.email.text = loja?.email ?? '';
    _controllers.redesSociais.text = loja?.redesSociais ?? '';
    _controllers.categorias.text = loja?.categorias ?? '';
    _controllers.tags.text = loja?.tags ?? '';

    _logo = loja?.logo ?? '';
    _galeria.addAll(loja?.galeria ?? []);
    _arquivos.addAll(loja?.arquivos ?? []);
    _musicas.addAll(loja?.musicas ?? []);
    _videos.addAll(loja?.videos ?? []);
    _arquivosAudio.addAll(loja?.arquivosAudio ?? []);
    _descricoesAnexos.addAll(loja?.descricoesAnexos ?? {});

    _categorias.addAll(loja?.categoriasLoja ?? []);
    _itens.addAll(loja?.itensLoja ?? []);
    _gruposComponentes.addAll(loja?.gruposComponentesLoja ?? []);
    _clientes.addAll(loja?.clientesLoja ?? []);
    _fornecedores.addAll(loja?.fornecedoresLoja ?? []);
    _pedidos.addAll(loja?.pedidosLoja ?? []);
    _movimentosEstoque.addAll(loja?.movimentosEstoque ?? []);
    _mesas.addAll(loja?.mesas ?? []);
    _membros = List.of(loja?.membros ?? []);
    _tempoConclusaoMinutos = loja?.tempoConclusaoMinutos ?? 0;
    _sonsAlertas.addAll(loja?.sonsAlertas ?? {});
    _iniciarTimerVerificacaoPedidos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tentouGarantirDono) return;
      _tentouGarantirDono = true;
      final conta = context.read<AuthProvider>().contaAtual;
      if (conta == null) return;
      final atual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
      if (atual == null || atual.membros.isNotEmpty) return;
      context.read<PdvProvider>().garantirDono(
            widget.lojaId,
            cpf: conta.cpf,
            nome: conta.nome,
          );
      if (!mounted) return;
      final depois = context.read<PdvProvider>().buscarPorId(widget.lojaId);
      setState(() => _membros = List.of(depois?.membros ?? []));
    });
  }

  @override
  void dispose() {
    _timerVerificacaoPedidos?.cancel();
    _controllers.dispose();
    _pesquisaItens.dispose();
    _pesquisaCategorias.dispose();
    _pesquisaGrupos.dispose();
    _scrollCategorias.dispose();
    _scrollGrupos.dispose();
    super.dispose();
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthProvider>().sair();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  void _confirmarExclusao(BuildContext context) {
    if (!context.read<PdvProvider>().possoExcluirLoja(widget.lojaId)) {
      _avisarSemPermissao();
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
                    style: theme.getTextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _executarExclusao(BuildContext dialogContext) {
    final navigator = Navigator.of(dialogContext);

    dialogContext.read<PdvProvider>().excluirLoja(widget.lojaId);

    navigator.pop();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  String _tituloDaAba() {
    switch (_abaSelecionada) {
      case AbaLoja.dados:
        return 'Dados do Perfil';
      case AbaLoja.interface:
        return 'Interface do Perfil';
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

  Widget _botaoAcaoLoja(AppTheme theme, String rotulo, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }

  Widget _tituloDeSecao(AppTheme theme, String texto) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: theme.getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  Widget _textoListaVazia(AppTheme theme, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        texto,
        style:
            theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
      ),
    );
  }

  Widget _campoDePesquisa(
    AppTheme theme,
    TextEditingController controller,
    String dica,
  ) {
    return TextField(
      controller: controller,
      style: theme.getTextStyle(fontSize: 13),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: dica,
        hintStyle: theme.getTextStyle(
          fontSize: 13,
          color: theme.secondaryTextColor,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: theme.secondaryTextColor,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.textColor),
        ),
      ),
    );
  }

  Widget _barraDeAcoesLoja(AppTheme theme) {
    return Container(
      width: double.infinity,
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _botaoAcaoLoja(theme, 'Novo Item', _abrirPopupNovoItem),
                const SizedBox(width: 8),
                _botaoAcaoLoja(
                  theme,
                  'Nova Categoria',
                  _abrirPopupNovaCategoria,
                ),
                const SizedBox(width: 8),
                _botaoAcaoLoja(
                  theme,
                  'Novo Grupo de Componentes',
                  _abrirPopupNovoGrupoComponentes,
                ),
                const SizedBox(width: 8),
                _botaoAcaoLoja(theme, 'Estoque', _abrirPopupEstoque),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCategoria(
    AppTheme theme,
    CategoriaLoja categoria,
    bool podeEditarLoja,
  ) {
    return CategoriaLojaContainer(
      key: _chaveCategoria(categoria.id),
      theme: theme,
      nome: categoria.nome,
      preco: categoria.preco,
      foto: categoria.foto,
      itemIds: categoria.itemIds,
      itensDisponiveis: _itens,
      expandida: categoria.id == _categoriaExpandidaId,
      podeEditar: podeEditarLoja,
      aoAlternarExpansao: () => _alternarExpansaoCategoria(categoria.id),
      onAdicionarItem: (itemId) => _adicionarItemNaCategoria(categoria, itemId),
      onRemoverItem: (itemId) => _removerItemDaCategoria(categoria, itemId),
      onEditar: () => _abrirPopupEditarCategoria(categoria),
      onExcluir: () => _removerCategoria(categoria.id),
      onNomeAlterado: (novoNome) =>
          _editarNomeCategoria(categoria.id, novoNome),
      onEditarNomeItem: _editarNomeItem,
      onEditarPrecoItem: _editarPrecoItem,
      onEditarItem: _abrirPopupEditarItem,
    );
  }

  Widget _listaCategorias(
    AppTheme theme,
    List<CategoriaLoja> categorias,
    bool podeEditarLoja,
  ) {
    if (categorias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: _categorias.isEmpty
              ? 'Nenhuma categoria criada ainda.'
              : 'Nenhuma categoria encontrada.',
        ),
      );
    }

    if (_categoriaExpandidaId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: ListView.separated(
          controller: _scrollCategorias,
          padding: const EdgeInsets.only(right: 8),
          itemCount: categorias.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _construirCategoria(
            theme,
            categorias[index],
            podeEditarLoja,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final categoria in categorias) ...[
          _construirCategoria(theme, categoria, podeEditarLoja),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _construirGrupo(
    AppTheme theme,
    GrupoComponentesLoja grupo,
    bool podeEditarLoja,
  ) {
    return GrupoComponentesLojaContainer(
      key: _chaveGrupo(grupo.id),
      theme: theme,
      nome: grupo.nome,
      foto: grupo.foto,
      itemIds: grupo.itemIds,
      itensDisponiveis: _itens,
      expandida: grupo.id == _grupoExpandidoId,
      podeEditar: podeEditarLoja,
      aoAlternarExpansao: () => _alternarExpansaoGrupo(grupo.id),
      onAdicionarItem: (itemId) => _adicionarItemNoGrupoComponentes(grupo, itemId),
      onRemoverItem: (itemId) => _removerItemDoGrupoComponentes(grupo, itemId),
      onEditar: () => _abrirPopupEditarGrupoComponentes(grupo),
      onExcluir: () => _removerGrupoComponentes(grupo.id),
      onNomeAlterado: (novoNome) =>
          _editarNomeGrupoComponentes(grupo.id, novoNome),
      onEditarNomeItem: _editarNomeItem,
      onEditarPrecoItem: _editarPrecoItem,
      onEditarItem: _abrirPopupEditarItem,
    );
  }

  Widget _listaGrupos(
    AppTheme theme,
    List<GrupoComponentesLoja> grupos,
    bool podeEditarLoja,
  ) {
    if (grupos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: _gruposComponentes.isEmpty
              ? 'Nenhum grupo de componentes criado ainda.'
              : 'Nenhum grupo de componentes encontrado.',
        ),
      );
    }

    if (_grupoExpandidoId == null) {
      return SizedBox(
        height: _alturaMaximaListaSecundaria,
        child: ListView.separated(
          controller: _scrollGrupos,
          padding: const EdgeInsets.only(right: 8),
          itemCount: grupos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _construirGrupo(
            theme,
            grupos[index],
            podeEditarLoja,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final grupo in grupos) ...[
          _construirGrupo(theme, grupo, podeEditarLoja),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _abaLoja(AppTheme theme) {
    final podeEditarLoja =
        context.read<PdvProvider>().possoEditarAbaLoja(widget.lojaId);
    final termoItens = _pesquisaItens.text.trim().toLowerCase();
    final termoCategorias = _pesquisaCategorias.text.trim().toLowerCase();
    final termoGrupos = _pesquisaGrupos.text.trim().toLowerCase();

    final itensFiltrados = termoItens.isEmpty
        ? _itens
        : _itens
            .where((i) => i.nome.toLowerCase().contains(termoItens))
            .toList();

    final categoriasFiltradas = termoCategorias.isEmpty
        ? _categorias
        : _categorias
            .where((c) => c.nome.toLowerCase().contains(termoCategorias))
            .toList();

    final gruposFiltrados = termoGrupos.isEmpty
        ? _gruposComponentes
        : _gruposComponentes
            .where((g) => g.nome.toLowerCase().contains(termoGrupos))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDeSecao(theme, 'Itens'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaItens,
            'Pesquisar itens...',
          ),
          const SizedBox(height: 12),
          if (itensFiltrados.isNotEmpty)
            SizedBox(
              height: (175 * (theme.fontScale > 1.0 ? theme.fontScale : 1.0))
                  .clamp(175.0, 235.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itensFiltrados.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = itensFiltrados[index];
                  return ItemLojaCard(
                    key: ValueKey('item_${item.id}'),
                    theme: theme,
                    nome: item.nome,
                    preco: item.preco,
                    tipo: item.tipo,
                    imagemUrl:
                        item.imagens.isNotEmpty ? item.imagens.first : null,
                    podeEditar: podeEditarLoja,
                    onEditar: () => _abrirPopupEditarItem(item),
                    onExcluir: () => _removerItem(item.id),
                    onNomeAlterado: (novoNome) =>
                        _editarNomeItem(item.id, novoNome),
                    onPrecoAlterado: (novoPreco) =>
                        _editarPrecoItem(item.id, novoPreco),
                  );
                },
              ),
            )
          else if (_itens.isEmpty)
            _textoListaVazia(theme, 'Nenhum item criado ainda.')
          else
            _textoListaVazia(theme, 'Nenhum item encontrado.'),

          const SizedBox(height: 24),
          _tituloDeSecao(theme, 'Categorias'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaCategorias,
            'Pesquisar categorias...',
          ),
          const SizedBox(height: 12),
          _listaCategorias(theme, categoriasFiltradas, podeEditarLoja),

          const SizedBox(height: 24),
          _tituloDeSecao(theme, 'Grupos de Componentes'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            theme,
            _pesquisaGrupos,
            'Pesquisar grupos...',
          ),
          const SizedBox(height: 12),
          _listaGrupos(theme, gruposFiltrados, podeEditarLoja),
        ],
      ),
    );
  }

  Widget _buildContainerTempoConclusao(AppTheme theme, bool podeEditar) {
    final decoracao = _decoracaoDoBloco(theme);
    final opcoes = <int, String>{
      0: 'Manual (sem aviso automático)',
      5: '5 minutos',
      10: '10 minutos',
      15: '15 minutos',
      20: '20 minutos',
      30: '30 minutos',
      45: '45 minutos',
      60: '60 minutos (1 hora)',
      90: '90 minutos (1h 30m)',
      120: '120 minutos (2 horas)',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                color: theme.buttonColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tempo de Conclusão dos Pedidos',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estipule um tempo padrão para preparação ou entrega. Após esse tempo decorrido em pedidos aceitos, o sistema perguntará automaticamente na interface se o pedido foi concluído. Caso deixe como "Manual", nenhum aviso automático será disparado e você poderá concluí-los na aba Gestão quando desejar.',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: !podeEditar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: opcoes.containsKey(_tempoConclusaoMinutos)
                      ? _tempoConclusaoMinutos
                      : 0,
                  isExpanded: true,
                  dropdownColor: theme.cardBackgroundColor,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.secondaryTextColor,
                  ),
                  items: opcoes.entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (novo) {
                    if (novo == null) return;
                    setState(() => _tempoConclusaoMinutos = novo);
                    context
                        .read<PdvProvider>()
                        .atualizarTempoConclusao(widget.lojaId, novo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.cardBackgroundColor,
                        duration: const Duration(seconds: 2),
                        content: Text(
                          novo == 0
                              ? 'Conclusão de pedidos definida como Manual.'
                              : 'Tempo de conclusão definido para $novo minutos.',
                          style: theme.getTextStyle(color: theme.textColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerSonsAlertas(AppTheme theme, bool podeEditar) {
    final decoracao = BoxDecoration(
      color: theme.backgroundColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.borderColor.withValues(alpha: 0.6),
      ),
    );

    final eventos = [
      (
        chave: SomService.eventoNovoPedido,
        titulo: 'Novo Pedido Recebido',
        descricao: 'Tocado quando um novo pedido entra no sistema.',
      ),
      (
        chave: SomService.eventoConclusaoPedido,
        titulo: 'Tempo Limite / Alerta de Pedido',
        descricao: 'Tocado quando um pedido atinge o tempo limite estipulado.',
      ),
      (
        chave: SomService.eventoBipVenda,
        titulo: 'Bip de Leitura na Venda (Código de Barras / Item)',
        descricao:
            'Tocado ao adicionar um item ou ler com leitor de código de barras.',
      ),
    ];

    String extrairNomeArquivo(String caminho) {
      final desc = _descricoesAnexos[caminho]?.trim();
      if (desc != null && desc.isNotEmpty) return desc;
      final partes = caminho.split(RegExp(r'[\\/]'));
      return partes.isNotEmpty ? partes.last : caminho;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up_outlined,
                color: theme.buttonColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sons e Alertas do Sistema',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Personalize os efeitos sonoros para as principais operações. Você pode manter o bip padrão nativo do sistema, silenciar ou selecionar qualquer arquivo de áudio anexado no container "Arquivos de Áudio" acima.',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...eventos.map((ev) {
            final valorAtual = _sonsAlertas[ev.chave] ?? SomService.opcaoPadrao;
            final existeArquivo = valorAtual == SomService.opcaoPadrao ||
                valorAtual == SomService.opcaoSilencioso ||
                _arquivosAudio.contains(valorAtual);
            final valorSelecionado =
                existeArquivo ? valorAtual : SomService.opcaoPadrao;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev.titulo,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ev.descricao,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: !podeEditar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: valorSelecionado,
                                isExpanded: true,
                                dropdownColor: theme.cardBackgroundColor,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.secondaryTextColor,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: SomService.opcaoPadrao,
                                    child: Text(
                                      'Bip Padrão do Sistema',
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: SomService.opcaoSilencioso,
                                    child: Text(
                                      'Silencioso (Sem som)',
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                  ..._arquivosAudio.map((caminho) {
                                    return DropdownMenuItem(
                                      value: caminho,
                                      child: Text(
                                        'Áudio: ${extrairNomeArquivo(caminho)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (novo) {
                                  if (novo == null) return;
                                  setState(() => _sonsAlertas[ev.chave] = novo);
                                  context.read<PdvProvider>().atualizarSomAlerta(
                                        widget.lojaId,
                                        ev.chave,
                                        novo,
                                      );
                                  if (novo == SomService.opcaoSilencioso) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            theme.cardBackgroundColor,
                                        duration: const Duration(seconds: 1),
                                        content: Text(
                                          '${ev.titulo} silenciado.',
                                          style: theme.getTextStyle(
                                              color: theme.textColor),
                                        ),
                                      ),
                                    );
                                  } else if (novo == SomService.opcaoPadrao) {
                                    SomService.tocarBipPadrao();
                                  } else {
                                    SomService.tocarArquivo(novo);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Testar som',
                        icon: Icon(
                          Icons.play_circle_outline_rounded,
                          color: theme.buttonColor,
                          size: 26,
                        ),
                        onPressed: () {
                          if (valorSelecionado == SomService.opcaoSilencioso) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                duration: const Duration(seconds: 1),
                                content: Text(
                                  'Este evento está configurado como silencioso.',
                                  style: theme.getTextStyle(
                                      color: theme.textColor),
                                ),
                              ),
                            );
                          } else if (valorSelecionado ==
                              SomService.opcaoPadrao) {
                            SomService.tocarBipPadrao();
                          } else {
                            SomService.tocarArquivo(valorSelecionado);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _conteudoDaAba(AppTheme theme) {
    final cpfLogado = context.read<AuthProvider>().contaAtual?.cpf ?? '';
    final pdv = context.read<PdvProvider>();
    final possoEditarDados = pdv.possoEditarDadosLoja(widget.lojaId);
    final possoGerenciarMembros = pdv.possoGerenciarMembros(widget.lojaId);

    switch (_abaSelecionada) {
      case AbaLoja.dados:
        final decoracaoDoBloco = _decoracaoDoBloco(theme);

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: decoracaoDoBloco,
              child: Column(
                children: [
                  AbsorbPointer(
                    absorbing: !possoEditarDados,
                    child: FormularioDadosLoja(
                      theme: theme,
                      controllers: _controllers,
                      logo: _logo,
                      onAlterarLogo: _alterarLogoLoja,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvarDadosLoja,
                      child: Text(
                        'Salvar Dados',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _confirmarExclusao(context),
                    child: Text(
                      'Excluir Loja',
                      style: theme.getTextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            UsuariosParticipantesContainer(
              theme: theme,
              membros: _membros,
              cpfLogado: cpfLogado,
              podeGerenciar: possoGerenciarMembros,
              buscarConta: _buscarContaPorCpf,
              onEnviarConvite: _enviarConvite,
              onRemover: _removerMembro,
              onAtualizarPapel: _atualizarPapelMembro,
              onSair: _sairDaLoja,
            ),
            const SizedBox(height: 16),
            _buildContainerTempoConclusao(theme, possoEditarDados),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(
              theme: theme,
              titulo: 'Galeria',
              itens: _galeria,
              tipo: TipoAnexoLoja.galeria,
              descricoes: _descricoesAnexos,
              onAtualizarDescricao: _atualizarDescricaoAnexo,
              onAdicionar: (caminho) =>
                  _adicionarAnexo(TipoAnexoLoja.galeria, caminho),
              onRemover: (index) =>
                  _removerAnexo(TipoAnexoLoja.galeria, index),
            ),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(
              theme: theme,
              titulo: 'Arquivos',
              itens: _arquivos,
              tipo: TipoAnexoLoja.arquivos,
              descricoes: _descricoesAnexos,
              onAtualizarDescricao: _atualizarDescricaoAnexo,
              onAdicionar: (caminho) =>
                  _adicionarAnexo(TipoAnexoLoja.arquivos, caminho),
              onRemover: (index) =>
                  _removerAnexo(TipoAnexoLoja.arquivos, index),
            ),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(
              theme: theme,
              titulo: 'Músicas',
              itens: _musicas,
              tipo: TipoAnexoLoja.musicas,
              descricoes: _descricoesAnexos,
              onAtualizarDescricao: _atualizarDescricaoAnexo,
              onAdicionar: (caminho) =>
                  _adicionarAnexo(TipoAnexoLoja.musicas, caminho),
              onRemover: (index) =>
                  _removerAnexo(TipoAnexoLoja.musicas, index),
            ),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(
              theme: theme,
              titulo: 'Vídeos',
              itens: _videos,
              tipo: TipoAnexoLoja.videos,
              descricoes: _descricoesAnexos,
              onAtualizarDescricao: _atualizarDescricaoAnexo,
              onAdicionar: (caminho) =>
                  _adicionarAnexo(TipoAnexoLoja.videos, caminho),
              onRemover: (index) =>
                  _removerAnexo(TipoAnexoLoja.videos, index),
            ),
            const SizedBox(height: 16),
            GaleriaEstiloContainer(
              theme: theme,
              titulo: 'Arquivos de Áudio',
              itens: _arquivosAudio,
              tipo: TipoAnexoLoja.arquivosAudio,
              descricoes: _descricoesAnexos,
              onAtualizarDescricao: _atualizarDescricaoAnexo,
              onAdicionar: (caminho) =>
                  _adicionarAnexo(TipoAnexoLoja.arquivosAudio, caminho),
              onRemover: (index) =>
                  _removerAnexo(TipoAnexoLoja.arquivosAudio, index),
            ),
            const SizedBox(height: 16),
            _buildContainerSonsAlertas(theme, possoEditarDados),
          ],
        );

      case AbaLoja.loja:
        return _abaLoja(theme);

      case AbaLoja.gestao:
        return GestaoLojaContainer(
          theme: theme,
          lojaId: widget.lojaId,
          autorCpf: _cpfLogado,
          autorNome: _nomeLogado,
          autorEmail: _emailLogado,
          lojaOnline: _lojaOnline,
          aoAlterarOnline: (valor) => setState(() => _lojaOnline = valor),
          abaPedidos: _abaPedidos,
          aoTrocarAbaPedidos: (aba) => setState(() => _abaPedidos = aba),
          pedidos: _pedidos,
          clientes: _clientes,
          itensDisponiveis: _itens,
          aoAceitar: (id) => _alterarStatusPedido(id, StatusPedido.aceito),
          aoRecusar: _recusarPedido,
          aoConcluir: (id) => _alterarStatusPedido(id, StatusPedido.concluido),
          aoCancelarPedido: _cancelarPedidoComDialog,
          aoSalvarComentario: _salvarComentarioPedido,
          aoExcluirPedido: _excluirPedido,
          aoNovaVenda: _abrirPopupNovaVenda,
          aoClientes: _abrirPopupClientes,
          aoRelatorios: _abrirPopupRelatorios,
          aoImpressora: _abrirPopupImpressora,
          aoFinanceiro: _abrirFinanceiro,
          aoCaixa: _abrirPopupCaixa,
          caixaAberto: context.watch<PdvProvider>().buscarPorId(widget.lojaId)?.turnoCaixaAberto != null,
          aoStatus: _abrirStatusLoja,
          ehRestaurante: _ehRestaurante,
          mesas: _mesas,
          aoCriarMesa: _abrirCriarMesa,
          aoClicarMesa: _abrirComandaMesa,
        );

      case AbaLoja.interface:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Em construção',
              style: theme.getTextStyle(fontSize: 13),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f1): () {
          _abrirPopupNovaVenda();
        },
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: CustomAppBar(
                title: _tituloDaAba(),
                onLogout: () => _handleLogout(context),
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _larguraMaximaConteudo),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _conteudoDaAba(theme),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_abaSelecionada == AbaLoja.loja) _barraDeAcoesLoja(theme),
                  _BarraDeAbasDaLoja(
                    theme: theme,
                    abaSelecionada: _abaSelecionada,
                    aoTrocarAba: (novaAba) =>
                        setState(() => _abaSelecionada = novaAba),
                  ),
                  FloatingBottomNavBar(maxWidth: _larguraMaximaConteudo),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarraDeAbasDaLoja extends StatelessWidget {
  final AppTheme theme;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> aoTrocarAba;

  const _BarraDeAbasDaLoja({
    required this.theme,
    required this.abaSelecionada,
    required this.aoTrocarAba,
  });

  String _rotulo(AbaLoja aba) {
    switch (aba) {
      case AbaLoja.dados:
        return 'Dados';
      case AbaLoja.interface:
        return 'Interface';
      case AbaLoja.loja:
        return 'Loja';
      case AbaLoja.gestao:
        return 'Gestão';
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - _larguraMaximaConteudo;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: EdgeInsets.only(
        left: margemLateral + 12,
        right: margemLateral + 12,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        children: AbaLoja.values.map((aba) {
          final selecionada = aba == abaSelecionada;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selecionada ? theme.buttonColor : Colors.transparent,
                  foregroundColor:
                      selecionada ? theme.buttonTextColor : theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => aoTrocarAba(aba),
                child: Text(
                  _rotulo(aba),
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color:
                        selecionada ? theme.buttonTextColor : theme.textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}