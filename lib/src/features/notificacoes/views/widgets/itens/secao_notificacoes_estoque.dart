import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_estoque.dart';
import 'package:nous/src/features/notificacoes/views/widgets/itens/fundo_descarte_notificacao.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Seção de alertas de estoque baixo no diálogo de notificações.
class SecaoNotificacoesEstoque extends StatelessWidget {
  final AppTheme theme;
  final List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      alertas;
  final NotificacoesProvider notificacoes;
  final String? lojaId;
  final bool exibirEspacamentoInferior;

  const SecaoNotificacoesEstoque({
    super.key,
    required this.theme,
    required this.alertas,
    required this.notificacoes,
    required this.lojaId,
    required this.exibirEspacamentoInferior,
  });

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: theme.dangerColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Alertas de Estoque (${alertas.length})',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.dangerColor,
                ),
              ),
            ],
          ),
        ),
        for (final alerta in alertas)
          Dismissible(
            key: ValueKey(
              'alerta_estoque_${alerta.lojaId}_${alerta.item.id}',
            ),
            direction: DismissDirection.horizontal,
            background: FundoDescarteNotificacao(
              theme: theme,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: FundoDescarteNotificacao(
              theme: theme,
              alignment: Alignment.centerRight,
            ),
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
              onTap: () => Navigator.of(context).pop(alerta),
            ),
          ),
        if (exibirEspacamentoInferior) const SizedBox(height: 8),
      ],
    );
  }
}
