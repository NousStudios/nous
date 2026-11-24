import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Diálogos de fluxo de visitante e conta aguardando aprovação na vitrine.
class VitrineDialogsVisitanteHelper {
  const VitrineDialogsVisitanteHelper._();

  static Future<void> mostrarDialogCriarContaVisitante({
    required BuildContext context,
    required AppTheme theme,
    required Loja loja,
    required List<ItemVendido> carrinho,
    required int quantidadeTotal,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Crie sua Conta Nous para pedir',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Você selecionou $quantidadeTotal ${quantidadeTotal == 1 ? "item" : "itens"} em ${loja.nome}.\n\n'
          'Para enviar seu pedido para o chat da loja, crie sua Conta Nous com seus dados e aguarde a aprovação de um usuário Nous verificado.',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Continuar vendo',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await PreferenciasSoberanasService.salvarTexto(
                  'vitrine_carrinho_pendente_${loja.id}',
                  jsonEncode(carrinho.map((e) => e.toJson()).toList()),
                );
              } catch (_) {}
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!context.mounted) return;
              context.read<AuthProvider>().sair();
              context.read<PdvProvider>().limparSessao();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            child: Text(
              'Criar Conta Nous',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> mostrarDialogAguardandoAprovacao({
    required BuildContext context,
    required AppTheme theme,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Conta aguardando aprovação',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Sua Conta Nous já foi criada, mas ainda aguarda a aprovação de um usuário Nous verificado para enviar pedidos às lojas da rede.',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendi',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
