import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

class SolicitarAcessoDadoDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous usuarioAlvo,
    required String rotulo,
    required String chave,
  }) async {
    final auth = context.read<AuthProvider>();
    final notificacoes = context.read<NotificacoesProvider>();
    final usuarioLogado = auth.contaAtual;
    if (usuarioLogado == null) return;

    final nomeAlvo =
        usuarioAlvo.nome.isNotEmpty ? usuarioAlvo.nome : 'o usuário';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Solicitar Acesso',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja enviar uma notificação para $nomeAlvo solicitando autorização para visualizar: "$rotulo"?',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Enviar Solicitação',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final solicitacao = ConviteLoja(
        id: 'solic_${DateTime.now().millisecondsSinceEpoch}_${CpfValidator.onlyDigits(usuarioLogado.cpf)}',
        cpfConvidante: CpfValidator.onlyDigits(usuarioLogado.cpf),
        nomeConvidante: usuarioLogado.nome.isNotEmpty
            ? usuarioLogado.nome
            : usuarioLogado.usernameExibicao,
        cpfConvidado: CpfValidator.onlyDigits(usuarioAlvo.cpf),
        lojaId: '',
        nomeLoja: 'Conta Pessoal',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoDadoUsuario,
        dadoSolicitado: chave,
      );
      await notificacoes.adicionarNotificacao(solicitacao);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Solicitação enviada para $nomeAlvo!',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    }
  }
}
