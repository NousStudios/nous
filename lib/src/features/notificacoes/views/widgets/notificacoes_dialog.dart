import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/gerenciador_acoes_notificacao.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_chat.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_convite.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_estoque.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_social.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/movimento_estoque_dialog.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';

enum _AbaNotificacao { tudo, mensagens, convites, mencoes, atividade }

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

/// Diálogo central de Notificações da aplicação, agregando convites de lojas,
/// alertas de estoque baixo e mensagens de chat.
class NotificacoesDialog {
  static Future<void> mostrar(BuildContext context, {String? lojaId}) async {
    if (lojaId != null) {
      await context.read<NotificacoesProvider>().carregarDispensadasLoja(lojaId);
      if (!context.mounted) return;
    }

    final alertaEscolhido = await showDialog<
        ({ItemLoja item, double saldo, String lojaNome, String lojaId})?>(
      context: context,
      builder: (dialogContext) {
        return _NotificacoesConteudo(lojaId: lojaId);
      },
    );

    if (alertaEscolhido == null || !context.mounted) return;

    await _abrirResolucaoAlertaEstoque(context, alertaEscolhido);
  }

  static Future<void> _abrirResolucaoAlertaEstoque(
    BuildContext context,
    ({ItemLoja item, double saldo, String lojaNome, String lojaId}) alerta,
  ) async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final notificacoes = context.read<NotificacoesProvider>();
    final conta = auth.contaAtual;
    final theme = ThemeController.currentTheme.value;

    if (conta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Você precisa estar logado.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    final loja = pdv.buscarPorId(alerta.lojaId);
    if (loja == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Loja não encontrada.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    final movimento = await MovimentoEstoqueDialog.mostrar(
      context,
      theme: theme,
      itens: loja.itensLoja,
      fornecedores: loja.fornecedoresLoja,
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
      itemInicial: alerta.item,
      tipoInicial: TipoMovimentoEstoque.entrada,
    );

    if (movimento == null || !context.mounted) return;

    pdv.adicionarMovimentoEstoque(loja.id, movimento);

    final item = loja.itensLoja.firstWhere(
      (i) => i.id == movimento.itemId,
      orElse: () => alerta.item,
    );
    final tipo = movimento.ehEntrada ? 'Entrada' : 'Saída';
    final sufixoFornecedor = movimento.fornecedorNome.isNotEmpty
        ? ' de "${movimento.fornecedorNome}"'
        : '';
    final qtdFormatada = _formatarQuantidade(movimento.quantidade);
    final unidadeTexto = _rotuloUnidadeCurto(item.unidadeBase);

    final acao = RegistroAcao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataHora: DateTime.now(),
      tipo: TipoAcao.movimentoEstoqueRegistrado,
      descricao:
          '$tipo$sufixoFornecedor de $qtdFormatada $unidadeTexto em "${item.nome}"',
      cpfAutor: conta.cpf,
      nomeAutor: conta.nome,
      emailAutor: auth.emailAtivo ?? '',
    );

    pdv.registrarAcao(loja.id, acao);

    if (alerta.lojaId.isNotEmpty) {
      notificacoes.dispensarNotificacoesLoja(
        alerta.lojaId,
        ['alerta_estoque_${alerta.lojaId}_${alerta.item.id}'],
      );
    } else {
      notificacoes.dispensarNaSessao(
        'alerta_estoque_${alerta.lojaId}_${alerta.item.id}',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Entrada de estoque de "${item.nome}" registrada com sucesso!',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}

class _NotificacoesConteudo extends StatelessWidget {
  final String? lojaId;
  const _NotificacoesConteudo({this.lojaId});

  Widget _buildDismissibleFundo() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.visibility_off_outlined,
        color: Colors.redAccent,
        size: 20,
      ),
    );
  }

  Widget _buildDismissibleFundoSecundario() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.visibility_off_outlined,
        color: Colors.redAccent,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = context.watch<NotificacoesProvider>();
    final pdv = context.watch<PdvProvider>();
    final auth = context.watch<AuthProvider>();
    final cpfUsuario = auth.contaAtual?.cpf ?? '';

    final ehLojaColetivaNous = lojaId == PdvProvider.idLojaColetivaNous;
    final convites = (lojaId != null)
        ? const []
        : notificacoes.convites
            .where((c) => !notificacoes.estaDispensadaNaSessao('convite_${c.id}'))
            .toList();
    final alertasEstoque = (lojaId == null || ehLojaColetivaNous)
        ? const <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[]
        : pdv
            .itensEstoqueBaixoPorLoja(lojaId!)
            .where((a) => !notificacoes
                .estaDispensadaNaLoja(lojaId!, 'alerta_estoque_${a.lojaId}_${a.item.id}'))
            .toList();

    return FutureBuilder<({List<MensagemChat> msgs, List<NotificacaoSocial> sociais})>(
      future: () async {
        final msgsFuture = (lojaId != null)
            ? ChatService.obterMensagensNaoLidasDaLoja(lojaId!)
            : (cpfUsuario.isNotEmpty
                ? ChatService.obterMensagensNaoLidasDoUsuario(cpfUsuario)
                : Future.value(const <MensagemChat>[]));
        final sociaisFuture = (lojaId == null && cpfUsuario.isNotEmpty)
            ? TimelineRepositorioSqlite.listarNotificacoesSociaisDoUsuario(
                cpfUsuario,
              )
            : Future.value(const <NotificacaoSocial>[]);
        final res = await Future.wait([msgsFuture, sociaisFuture]);
        return (
          msgs: res[0] as List<MensagemChat>,
          sociais: res[1] as List<NotificacaoSocial>,
        );
      }(),
      builder: (context, snapshotMsgs) {
        final todasMensagens = snapshotMsgs.data?.msgs ?? const <MensagemChat>[];
        final mensagens = todasMensagens
            .where((m) => lojaId != null
                ? !notificacoes.estaDispensadaNaLoja(lojaId!, 'msg_${m.id}')
                : !notificacoes.estaDispensadaNaSessao('msg_${m.id}'))
            .toList();
        final sociais = (snapshotMsgs.data?.sociais ?? const <NotificacaoSocial>[])
            .where((s) => !notificacoes.estaDispensadaNaSessao('nsoc_${s.id}'))
            .toList();
        final vazio = convites.isEmpty &&
            alertasEstoque.isEmpty &&
            mensagens.isEmpty &&
            sociais.isEmpty;

        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            var abaSelecionada = _AbaNotificacao.tudo;
            final convitesColab = sociais
                .where((s) =>
                    s.tipo == TipoNotificacaoSocial.conviteColaboracao)
                .toList();
            final mencoes = sociais
                .where((s) => s.tipo == TipoNotificacaoSocial.mencao)
                .toList();
            final atividades = sociais
                .where((s) =>
                    s.tipo != TipoNotificacaoSocial.conviteColaboracao &&
                    s.tipo != TipoNotificacaoSocial.mencao)
                .toList();

            return StatefulBuilder(
              builder: (context, setDialogState) {
                final mostrarMsgs = abaSelecionada == _AbaNotificacao.tudo ||
                    abaSelecionada == _AbaNotificacao.mensagens;
                final mostrarEstoque = abaSelecionada == _AbaNotificacao.tudo;
                final mostrarConvites = abaSelecionada == _AbaNotificacao.tudo ||
                    abaSelecionada == _AbaNotificacao.convites;
                final mostrarMencoes = abaSelecionada == _AbaNotificacao.tudo ||
                    abaSelecionada == _AbaNotificacao.mencoes;
                final mostrarAtividade =
                    abaSelecionada == _AbaNotificacao.tudo ||
                        abaSelecionada == _AbaNotificacao.atividade;

                final listaMsgs =
                    mostrarMsgs ? mensagens : const <MensagemChat>[];
                final listaEstoque = mostrarEstoque
                    ? alertasEstoque
                    : const <({
                        ItemLoja item,
                        double saldo,
                        String lojaNome,
                        String lojaId,
                      })>[];
                final listaConvitesLoja =
                    mostrarConvites ? convites : const [];
                final listaConvitesColab = mostrarConvites
                    ? convitesColab
                    : const <NotificacaoSocial>[];
                final listaMencoes =
                    mostrarMencoes ? mencoes : const <NotificacaoSocial>[];
                final listaAtividades =
                    mostrarAtividade ? atividades : const <NotificacaoSocial>[];

                final abaVazia = listaMsgs.isEmpty &&
                    listaEstoque.isEmpty &&
                    listaConvitesLoja.isEmpty &&
                    listaConvitesColab.isEmpty &&
                    listaMencoes.isEmpty &&
                    listaAtividades.isEmpty;

                Widget buildChipAba(
                  _AbaNotificacao aba,
                  String titulo,
                  int quantidade,
                ) {
                  final ativa = abaSelecionada == aba;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setDialogState(() => abaSelecionada = aba),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ativa
                            ? theme.textColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ativa
                              ? theme.textColor
                              : theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo,
                            style: theme.getTextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  ativa ? FontWeight.bold : FontWeight.w500,
                              color: ativa
                                  ? theme.textColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                          if (quantidade > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ativa
                                    ? theme.textColor
                                    : theme.borderColor.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$quantidade',
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ativa
                                      ? theme.cardBackgroundColor
                                      : theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                Widget buildSocialDismissible(NotificacaoSocial s) {
                  return Dismissible(
                    key: ValueKey('nsoc_${s.id}'),
                    direction: DismissDirection.horizontal,
                    background: _buildDismissibleFundo(),
                    secondaryBackground: _buildDismissibleFundoSecundario(),
                    onDismissed: (_) async {
                      await TimelineRepositorioSqlite
                          .marcarNotificacaoSocialLida(s.id);
                      notificacoes.dispensarNaSessao('nsoc_${s.id}');
                    },
                    child: CardNotificacaoSocial(
                      theme: theme,
                      notificacao: s,
                      onResponderConvite:
                          s.tipo == TipoNotificacaoSocial.conviteColaboracao
                              ? (aceitar) async {
                                  await TimelineService
                                      .responderConviteColaboracao(
                                    publicacaoId: s.publicacaoId,
                                    usuarioCpf: cpfUsuario,
                                    aceitar: aceitar,
                                    notificacaoId: s.id,
                                  );
                                  notificacoes.dispensarNaSessao(
                                    'nsoc_${s.id}',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          aceitar
                                              ? 'Participação aceita! A publicação agora aparece no seu perfil.'
                                              : 'Convite de participação recusado.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                      onTap: () async {
                        if (s.tipo !=
                            TipoNotificacaoSocial.conviteColaboracao) {
                          await TimelineRepositorioSqlite
                              .marcarNotificacaoSocialLida(s.id);
                          notificacoes.dispensarNaSessao('nsoc_${s.id}');
                        }
                        if (!context.mounted) return;
                        if (s.publicacaoId.isNotEmpty) {
                          final pub = await TimelineRepositorioSqlite
                              .buscarPublicacaoPorId(s.publicacaoId);
                          if (pub != null && context.mounted) {
                            await DialogDetalhesPublicacao.mostrar(
                              context,
                              theme: theme,
                              publicacao: pub,
                              usuarioLogado: auth.contaAtual,
                            );
                            return;
                          }
                        }
                        final alvo = await ContasNousService.buscarPorCpf(
                          s.autorCpf,
                        );
                        if (alvo != null && context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PerfilSocialView(
                                usuarioAlvo: alvo,
                                mostrarBotaoVoltar: true,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }

                return Dialog(
                  backgroundColor: theme.cardBackgroundColor,
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.borderColor),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.90,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.textColor,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      lojaId == null
                                          ? 'Notificações'
                                          : (ehLojaColetivaNous
                                              ? 'Notificações • Comunidade Nous'
                                              : 'Notificações da Loja'),
                                      textAlign: TextAlign.center,
                                      style: theme.getTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    Text(
                                      'Arraste para o lado para dispensar',
                                      textAlign: TextAlign.center,
                                      style: theme.getTextStyle(
                                        fontSize: 10,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                buildChipAba(
                                  _AbaNotificacao.tudo,
                                  'Tudo',
                                  mensagens.length +
                                      alertasEstoque.length +
                                      convites.length +
                                      sociais.length,
                                ),
                                const SizedBox(width: 6),
                                buildChipAba(
                                  _AbaNotificacao.mensagens,
                                  'Mensagens',
                                  mensagens.length,
                                ),
                                if (lojaId == null) ...[
                                  const SizedBox(width: 6),
                                  buildChipAba(
                                    _AbaNotificacao.convites,
                                    'Convites',
                                    convites.length + convitesColab.length,
                                  ),
                                  const SizedBox(width: 6),
                                  buildChipAba(
                                    _AbaNotificacao.mencoes,
                                    'Menções',
                                    mencoes.length,
                                  ),
                                  const SizedBox(width: 6),
                                  buildChipAba(
                                    _AbaNotificacao.atividade,
                                    'Atividade',
                                    atividades.length,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!vazio)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Center(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.dangerColor,
                                    side: BorderSide(
                                      color: theme.dangerColor
                                          .withValues(alpha: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.clear_all_rounded,
                                    size: 16,
                                    color: theme.dangerColor,
                                  ),
                                  label: Text(
                                    'Limpar todas as notificações',
                                    style: theme.getTextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.dangerColor,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final ids = <String>[];
                                    for (final c in convites) {
                                      ids.add('convite_${c.id}');
                                    }
                                    for (final a in alertasEstoque) {
                                      ids.add(
                                        'alerta_estoque_${a.lojaId}_${a.item.id}',
                                      );
                                    }
                                    for (final m in mensagens) {
                                      ids.add('msg_${m.id}');
                                    }
                                    for (final s in sociais) {
                                      ids.add('nsoc_${s.id}');
                                      await TimelineRepositorioSqlite
                                          .marcarNotificacaoSocialLida(s.id);
                                    }
                                    if (lojaId != null) {
                                      notificacoes.dispensarNotificacoesLoja(
                                        lojaId!,
                                        ids,
                                      );
                                      ChatService.marcarMensagensDaLojaComoLidas(
                                        lojaId!,
                                        cpfUsuario,
                                      );
                                    } else {
                                      notificacoes.dispensarTodasNaSessao(ids);
                                      ChatService
                                          .marcarMensagensDoUsuarioComoLidas(
                                        cpfUsuario,
                                        mensagens
                                            .map((m) => m.conversaId)
                                            .toList(),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          if (abaVazia)
                            EstadoVazioContainer(
                              theme: theme,
                              mensagem: vazio
                                  ? 'Nenhuma notificação no momento.'
                                  : 'Nenhuma notificação nesta aba.',
                            )
                          else
                            Flexible(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 450),
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    if (listaConvitesColab.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                          top: 4,
                                        ),
                                        child: Text(
                                          'Convites de Participação (${listaConvitesColab.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                      for (final s in listaConvitesColab)
                                        buildSocialDismissible(s),
                                      const SizedBox(height: 6),
                                    ],
                                    if (listaMencoes.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                          top: 4,
                                        ),
                                        child: Text(
                                          'Menções @ (${listaMencoes.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                      for (final s in listaMencoes)
                                        buildSocialDismissible(s),
                                      const SizedBox(height: 6),
                                    ],
                                    if (listaAtividades.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                          top: 4,
                                        ),
                                        child: Text(
                                          'Atividade Social (${listaAtividades.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                      for (final s in listaAtividades)
                                        buildSocialDismissible(s),
                                      const SizedBox(height: 6),
                                    ],
                                    if (listaMsgs.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8, top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 16,
                                          color: theme.textColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mensagens (${listaMsgs.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final msg in listaMsgs)
                                    Dismissible(
                                      key: ValueKey('msg_${msg.id}'),
                                      direction: DismissDirection.horizontal,
                                      background: _buildDismissibleFundo(),
                                      secondaryBackground:
                                          _buildDismissibleFundoSecundario(),
                                      onDismissed: (_) {
                                        if (lojaId != null) {
                                          notificacoes.dispensarNotificacoesLoja(
                                            lojaId!,
                                            ['msg_${msg.id}'],
                                          );
                                          ChatService
                                              .marcarMensagensDaLojaComoLidas(
                                            lojaId!,
                                            cpfUsuario,
                                          );
                                        } else {
                                          notificacoes
                                              .dispensarNaSessao('msg_${msg.id}');
                                          ChatService
                                              .marcarMensagensDoUsuarioComoLidas(
                                            cpfUsuario,
                                            [msg.conversaId],
                                          );
                                        }
                                      },
                                      child: CardNotificacaoChat(
                                        theme: theme,
                                        msg: msg,
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          if (lojaId != null) {
                                            ChatService
                                                .marcarMensagensDaLojaComoLidas(
                                              lojaId!,
                                              cpfUsuario,
                                            );
                                          } else {
                                            ChatService.marcarComoLidas(
                                              msg.conversaId,
                                              cpfUsuario,
                                            );
                                          }
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => MensageriaView(
                                                modoLoja: lojaId != null,
                                                lojaId: lojaId,
                                                conversaInicialId:
                                                    msg.conversaId,
                                                mostrarBotaoVoltar: true,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (listaConvitesLoja.isNotEmpty ||
                                      listaEstoque.isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (listaEstoque.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8, top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 16,
                                          color: theme.dangerColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Alertas de Estoque (${listaEstoque.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.dangerColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final alerta in listaEstoque)
                                    Dismissible(
                                      key: ValueKey(
                                        'alerta_estoque_${alerta.lojaId}_${alerta.item.id}',
                                      ),
                                      direction: DismissDirection.horizontal,
                                      background: _buildDismissibleFundo(),
                                      secondaryBackground:
                                          _buildDismissibleFundoSecundario(),
                                      onDismissed: (_) {
                                        if (lojaId != null) {
                                          notificacoes.dispensarNotificacoesLoja(
                                            lojaId!,
                                            ['alerta_estoque_${alerta.lojaId}_${alerta.item.id}'],
                                          );
                                        } else {
                                          notificacoes.dispensarNaSessao(
                                            'alerta_estoque_${alerta.lojaId}_${alerta.item.id}',
                                          );
                                        }
                                      },
                                      child: CardNotificacaoEstoque(
                                        theme: theme,
                                        alerta: alerta,
                                        onTap: () =>
                                            Navigator.of(context).pop(alerta),
                                      ),
                                    ),
                                  if (listaConvitesLoja.isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (listaConvitesLoja.isNotEmpty) ...[
                                  if (listaEstoque.isNotEmpty ||
                                      listaMsgs.isNotEmpty ||
                                      listaConvitesColab.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Convites e Solicitações (${listaConvitesLoja.length})',
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  for (final convite in listaConvitesLoja)
                                    Dismissible(
                                      key: ValueKey('convite_${convite.id}'),
                                      direction: DismissDirection.horizontal,
                                      background: _buildDismissibleFundo(),
                                      secondaryBackground:
                                          _buildDismissibleFundoSecundario(),
                                      onDismissed: (_) {
                                        notificacoes.dispensarNaSessao(
                                          'convite_${convite.id}',
                                        );
                                      },
                                      child: CardNotificacaoConvite(
                                        theme: theme,
                                        convite: convite,
                                        onAceitar: () =>
                                            GerenciadorAcoesNotificacao
                                                .aceitarConvite(
                                          context,
                                          convite,
                                        ),
                                        onRecusar: () =>
                                            GerenciadorAcoesNotificacao
                                                .recusarConvite(
                                          context,
                                          convite,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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
}