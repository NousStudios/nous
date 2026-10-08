import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

String _rotuloPapel(PapelMembro papel) {
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

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

class NotificacoesDialog {
  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return const _NotificacoesConteudo();
      },
    );
  }
}

class _NotificacoesConteudo extends StatelessWidget {
  const _NotificacoesConteudo();

  void _avisar(BuildContext context, String mensagem) {
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

  Future<void> _aceitar(BuildContext context, ConviteLoja convite) async {
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final notificacoes = context.read<NotificacoesProvider>();
    final theme = ThemeController.currentTheme.value;
    final conta = auth.contaAtual;

    if (conta == null) {
      _avisar(context, 'Você precisa estar logado.');
      return;
    }

    if (convite.tipo == TipoNotificacao.remocaoLoja) {
      await notificacoes.aceitar(convite.id);
      if (!context.mounted) return;
      await pdv.entrarComCpf(conta.cpf);
      return;
    }

    if (convite.tipo == TipoNotificacao.solicitacaoExclusaoDono) {
      await pdv.sairDaLoja(convite.lojaId);
      if (!context.mounted) return;
      await notificacoes.aceitar(convite.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Você concordou com a saída e não faz mais parte da loja "${convite.nomeLoja}".',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    final cofreDoDono =
        await LojasService.carregar(convite.cpfConvidante);
    if (!context.mounted) return;

    Loja? lojaOriginal;
    for (final loja in cofreDoDono) {
      if (loja.id == convite.lojaId) {
        lojaOriginal = loja;
        break;
      }
    }

    if (lojaOriginal == null) {
      _avisar(context, 'A loja deste convite não está mais disponível.');
      await notificacoes.aceitar(convite.id);
      return;
    }

    final cpfDonoOriginal = lojaOriginal.cpfDonoOriginal.isEmpty
        ? convite.cpfConvidante
        : lojaOriginal.cpfDonoOriginal;

    if (convite.tipo == TipoNotificacao.alteracaoPapel) {
      final novosMembros = lojaOriginal.membros.map((m) {
        return m.cpf == conta.cpf ? m.copyWith(papel: convite.papel) : m;
      }).toList();

      final lojaAtualizada = lojaOriginal.copyWith(
        cpfDonoOriginal: cpfDonoOriginal,
        membros: novosMembros,
      );

      final cofreAtualizado = cofreDoDono
          .map((l) => l.id == lojaAtualizada.id ? lojaAtualizada : l)
          .toList();
      await LojasService.salvar(cpfDonoOriginal, cofreAtualizado);
      if (!context.mounted) return;

      await notificacoes.aceitar(convite.id);
      if (!context.mounted) return;

      await pdv.entrarComCpf(conta.cpf);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Seu papel na loja "${convite.nomeLoja}" foi alterado para ${_rotuloPapel(convite.papel)}.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    final jaMembro =
        lojaOriginal.membros.any((m) => m.cpf == conta.cpf);
    final novosMembros = jaMembro
        ? lojaOriginal.membros
        : [
            ...lojaOriginal.membros,
            MembroLoja(
              cpf: conta.cpf,
              nome: conta.nome,
              papel: convite.papel,
              desde: DateTime.now(),
            ),
          ];

    final lojaAtualizada = lojaOriginal.copyWith(
      cpfDonoOriginal: cpfDonoOriginal,
      membros: novosMembros,
    );

    final cofreAtualizado = cofreDoDono
        .map((l) => l.id == lojaAtualizada.id ? lojaAtualizada : l)
        .toList();
    await LojasService.salvar(cpfDonoOriginal, cofreAtualizado);
    if (!context.mounted) return;

    await LojasService.adicionarReferencia(
      conta.cpf,
      ReferenciaLoja(
        lojaId: lojaAtualizada.id,
        cpfDonoOriginal: cpfDonoOriginal,
      ),
    );
    if (!context.mounted) return;

    await notificacoes.aceitar(convite.id);
    if (!context.mounted) return;

    await pdv.entrarComCpf(conta.cpf);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Você agora é ${_rotuloPapel(convite.papel)} em "${convite.nomeLoja}".',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _recusar(BuildContext context, ConviteLoja convite) async {
    final notificacoes = context.read<NotificacoesProvider>();
    await notificacoes.recusar(convite.id);
  }

  Widget _linhaConvite(BuildContext context, AppTheme theme, ConviteLoja c) {
    final String titulo;
    final String descricao;
    final bool ehAvisoInformativo;

    switch (c.tipo) {
      case TipoNotificacao.alteracaoPapel:
        titulo = 'Solicitação de ${c.nomeConvidante}';
        descricao =
            'Alteração do seu papel em "${c.nomeLoja}" para ${_rotuloPapel(c.papel)}';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.solicitacaoExclusaoDono:
        titulo = 'Solicitação de saída por ${c.nomeConvidante}';
        descricao =
            '${c.nomeConvidante} solicitou a sua saída da loja "${c.nomeLoja}". Como você é Dono(a), sua saída depende do seu consentimento.';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.remocaoLoja:
        titulo = 'Aviso de remoção';
        descricao =
            'Você foi removido(a) da loja "${c.nomeLoja}" por ${c.nomeConvidante}.';
        ehAvisoInformativo = true;
        break;
      case TipoNotificacao.conviteEntrada:
        titulo = 'Convite de ${c.nomeConvidante}';
        descricao =
            'Para entrar em "${c.nomeLoja}" como ${_rotuloPapel(c.papel)}';
        ehAvisoInformativo = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: theme.getTextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatarCpf(c.cpfConvidante)} • ${_dataHoraCurta(c.dataHora)}',
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (ehAvisoInformativo)
                TextButton(
                  onPressed: () => _aceitar(context, c),
                  child: Text(
                    'Entendido',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () => _recusar(context, c),
                  child: Text(
                    'Recusar',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _aceitar(context, c),
                  child: Text(
                    'Aceitar',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaAlertaEstoque(
    BuildContext context,
    AppTheme theme,
    ({ItemLoja item, double saldo, String lojaNome, String lojaId}) alerta,
  ) {
    final saldoFormatado = alerta.saldo.truncateToDouble() == alerta.saldo
        ? alerta.saldo.toInt().toString()
        : alerta.saldo.toStringAsFixed(1);
    final unidadeTexto = alerta.item.unidadeBase.name;
    final esgotado = alerta.saldo <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              esgotado
                  ? Icons.remove_shopping_cart_outlined
                  : Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        esgotado
                            ? 'Estoque Esgotado: ${alerta.item.nome}'
                            : 'Estoque Baixo: ${alerta.item.nome}',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$saldoFormatado $unidadeTexto',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Loja: ${alerta.lojaNome}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esgotado
                      ? 'O item está sem saldo disponível. Registre uma nova entrada no módulo de estoque.'
                      : 'O saldo está abaixo de 10 unidades. Reabasteça para evitar rupturas de vendas.',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = context.watch<NotificacoesProvider>();
    final pdv = context.watch<PdvProvider>();
    final convites = notificacoes.convites;
    final alertasEstoque = pdv.todosItensEstoqueBaixo;
    final vazio = convites.isEmpty && alertasEstoque.isEmpty;

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
                        child: Text(
                          'Notificações',
                          textAlign: TextAlign.center,
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
                  const SizedBox(height: 12),
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
                            if (alertasEstoque.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8, top: 4),
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
                                _linhaAlertaEstoque(context, theme, alerta),
                              if (convites.isNotEmpty)
                                const SizedBox(height: 8),
                            ],
                            if (convites.isNotEmpty) ...[
                              if (alertasEstoque.isNotEmpty)
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
                                _linhaConvite(context, theme, convite),
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
  }
}