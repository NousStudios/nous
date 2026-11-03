import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Orquestrador de regras de negócio para aceitar e recusar convites e solicitações de notificação.
class GerenciadorAcoesNotificacao {
  static String rotuloPapel(PapelMembro papel) {
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

  static Future<void> recusarConvite(
    BuildContext context,
    ConviteLoja convite,
  ) async {
    final notificacoes = context.read<NotificacoesProvider>();
    await notificacoes.recusar(convite.id);
  }

  static Future<void> aceitarConvite(
    BuildContext context,
    ConviteLoja convite,
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
            'Você precisa estar logado para responder ao convite.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    if (convite.tipo == TipoNotificacao.solicitacaoDadoUsuario) {
      await auth.autorizarAcessoDado(
        convite.cpfConvidante,
        convite.dadoSolicitado.isNotEmpty ? convite.dadoSolicitado : 'cpf',
      );
      await notificacoes.aceitar(convite.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Você autorizou ${convite.nomeConvidante} a visualizar seu dado "${convite.dadoSolicitado}".',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      return;
    }

    if (convite.tipo == TipoNotificacao.solicitacaoExclusaoConversa) {
      await ChatService.excluirConversaLocal(convite.lojaId);
      await notificacoes.aceitar(convite.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Você concordou com a exclusão da conversa "${convite.nomeLoja}".',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
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

    final donoCofre = convite.cpfDonoOriginal.isNotEmpty
        ? convite.cpfDonoOriginal
        : convite.cpfConvidante;
    var cofreDoDono = await LojasService.carregar(donoCofre);
    if (!context.mounted) return;

    Loja? lojaOriginal;
    for (final loja in cofreDoDono) {
      if (loja.id == convite.lojaId) {
        lojaOriginal = loja;
        break;
      }
    }

    if (lojaOriginal == null && convite.cpfConvidante != donoCofre) {
      final cofreAlternativo =
          await LojasService.carregar(convite.cpfConvidante);
      if (!context.mounted) return;
      for (final loja in cofreAlternativo) {
        if (loja.id == convite.lojaId) {
          lojaOriginal = loja;
          cofreDoDono = cofreAlternativo;
          break;
        }
      }
    }

    if (lojaOriginal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'A loja deste convite não está mais disponível.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
      await notificacoes.aceitar(convite.id);
      return;
    }

    final cpfDonoOriginal = lojaOriginal.cpfDonoOriginal.isEmpty
        ? donoCofre
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
            'Seu papel na loja "${convite.nomeLoja}" foi alterado para ${rotuloPapel(convite.papel)}.',
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
          'Você agora é ${rotuloPapel(convite.papel)} em "${convite.nomeLoja}".',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}
