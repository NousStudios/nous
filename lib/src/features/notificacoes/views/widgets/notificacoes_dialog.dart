import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
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

    final lojasDoConvidante =
        await LojasService.carregar(convite.cpfConvidante);
    if (!context.mounted) return;

    Loja? lojaOriginal;
    for (final loja in lojasDoConvidante) {
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

    final novaLoja = lojaOriginal.copyWith(
      membros: [
        ...lojaOriginal.membros,
        MembroLoja(
          cpf: conta.cpf,
          nome: conta.nome,
          papel: convite.papel,
          desde: DateTime.now(),
        ),
      ],
    );

    final cpfConvidado = conta.cpf;
    final lojasDoConvidado = await LojasService.carregar(cpfConvidado);
    if (!context.mounted) return;

    final jaTem = lojasDoConvidado.any((l) => l.id == novaLoja.id);
    final listaFinal = jaTem
        ? lojasDoConvidado
            .map((l) => l.id == novaLoja.id ? novaLoja : l)
            .toList()
        : [...lojasDoConvidado, novaLoja];
    await LojasService.salvar(cpfConvidado, listaFinal);
    if (!context.mounted) return;

    await pdv.entrarComCpf(cpfConvidado);
    if (!context.mounted) return;

    await notificacoes.aceitar(convite.id);
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
            'Convite de ${c.nomeConvidante}',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Para entrar em "${c.nomeLoja}" como ${_rotuloPapel(c.papel)}',
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = context.watch<NotificacoesProvider>();

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
                  if (notificacoes.convites.isEmpty)
                    EstadoVazioContainer(
                      theme: theme,
                      mensagem: 'Nenhum convite pendente.',
                    )
                  else
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: notificacoes.convites.length,
                          itemBuilder: (context, index) => _linhaConvite(
                            context,
                            theme,
                            notificacoes.convites[index],
                          ),
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