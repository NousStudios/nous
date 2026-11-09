import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/gerenciador_acoes_notificacao.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_chat.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_convite.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_estoque.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/movimento_estoque_dialog.dart';

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

    final convites = notificacoes.convites
        .where((c) => !notificacoes.estaDispensadaNaSessao('convite_${c.id}'))
        .toList();
    final alertasEstoque = (lojaId == null)
        ? const <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[]
        : pdv
            .itensEstoqueBaixoPorLoja(lojaId!)
            .where((a) => !notificacoes
                .estaDispensadaNaLoja(lojaId!, 'alerta_estoque_${a.lojaId}_${a.item.id}'))
            .toList();

    return FutureBuilder<List<MensagemChat>>(
      future: (lojaId != null)
          ? ChatService.obterMensagensNaoLidasDaLoja(lojaId!)
          : (cpfUsuario.isNotEmpty
              ? ChatService.obterMensagensNaoLidasDoUsuario(cpfUsuario)
              : Future.value(const <MensagemChat>[])),
      builder: (context, snapshotMsgs) {
        final todasMensagens = snapshotMsgs.data ?? const <MensagemChat>[];
        final mensagens = todasMensagens
            .where((m) => lojaId != null
                ? !notificacoes.estaDispensadaNaLoja(lojaId!, 'msg_${m.id}')
                : !notificacoes.estaDispensadaNaSessao('msg_${m.id}'))
            .toList();
        final vazio =
            convites.isEmpty && alertasEstoque.isEmpty && mensagens.isEmpty;

        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            return Dialog(
              backgroundColor: theme.cardBackgroundColor,
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.textColor),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Notificações',
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
                          if (!vazio)
                            IconButton(
                              tooltip: 'Limpar todas as notificações',
                              icon: Icon(
                                Icons.clear_all_rounded,
                                color: theme.buttonColor,
                              ),
                              onPressed: () {
                                final ids = <String>[];
                                for (final c in convites) {
                                  ids.add('convite_${c.id}');
                                }
                                for (final a in alertasEstoque) {
                                  ids.add(
                                      'alerta_estoque_${a.lojaId}_${a.item.id}');
                                }
                                for (final m in mensagens) {
                                  ids.add('msg_${m.id}');
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
                                }
                              },
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!vazio)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Center(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.dangerColor,
                                side: BorderSide(
                                  color: theme.dangerColor.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                Icons.clear_all_rounded,
                                size: 18,
                                color: theme.dangerColor,
                              ),
                              label: Text(
                                'Limpar todas as notificações',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.dangerColor,
                                ),
                              ),
                              onPressed: () {
                                final ids = <String>[];
                                for (final c in convites) {
                                  ids.add('convite_${c.id}');
                                }
                                for (final a in alertasEstoque) {
                                  ids.add(
                                      'alerta_estoque_${a.lojaId}_${a.item.id}');
                                }
                                for (final m in mensagens) {
                                  ids.add('msg_${m.id}');
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
                                }
                              },
                            ),
                          ),
                        ),
                      if (vazio)
                        EstadoVazioContainer(
                          theme: theme,
                          mensagem: 'Nenhuma notificação no momento.',
                        )
                      else
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 450),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                if (mensagens.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8, top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 16,
                                          color: theme.buttonColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mensagens (${mensagens.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final msg in mensagens)
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
                                  if (convites.isNotEmpty ||
                                      alertasEstoque.isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (alertasEstoque.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8, top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Alertas de Estoque (${alertasEstoque.length})',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final alerta in alertasEstoque)
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
                                  if (convites.isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (convites.isNotEmpty) ...[
                                  if (alertasEstoque.isNotEmpty ||
                                      mensagens.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Convites e Solicitações (${convites.length})',
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  for (final convite in convites)
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
  }
}