import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';

/// Diálogo exibido no servidor balcão para autorizar a conexão de novos terminais Wi-Fi.
class DialogAutorizacaoTerminal {
  static Future<ResultadoAutorizacaoConexao> exibir({
    required String ip,
    required String nomeDispositivo,
    String? nomeUsuario,
    String? cpf,
    required bool jaEhMembro,
  }) async {
    final context = NavigatorKeyService.currentContext;
    if (context == null || !context.mounted) {
      return jaEhMembro
          ? ResultadoAutorizacaoConexao.autorizadoMembro
          : ResultadoAutorizacaoConexao.autorizadoCliente;
    }

    SomService.tocarBipPadrao();

    final completer = Completer<ResultadoAutorizacaoConexao>();
    var respondido = false;
    String tipoAcesso = 'cliente';

    showDialog<ResultadoAutorizacaoConexao>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = ThemeController.currentTheme.value;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, color: theme.textColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Solicitação de Acesso',
                    style: theme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Um terminal móvel está solicitando sincronização com esta loja na rede Wi-Fi:',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _itemInfo(theme, 'Aparelho:', nomeDispositivo, Icons.smartphone_rounded),
                            if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _itemInfo(theme, 'Usuário:', nomeUsuario.trim(), Icons.person_rounded),
                            ],
                            if (cpf != null && cpf.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _itemInfo(theme, 'CPF:', CpfValidator.formatProtegido(cpf.trim()), Icons.badge_outlined),
                            ],
                            const SizedBox(height: 6),
                            _itemInfo(theme, 'Endereço IP:', ip, Icons.wifi_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (jaEhMembro) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: theme.textColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Este operador já consta cadastrado na equipe desta Loja.',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Como este dispositivo deve se conectar?',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Opção Cliente / Comprador
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => tipoAcesso = 'cliente'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tipoAcesso == 'cliente'
                                  ? theme.borderColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tipoAcesso == 'cliente'
                                    ? theme.textColor
                                    : theme.borderColor.withValues(alpha: 0.4),
                                width: tipoAcesso == 'cliente' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tipoAcesso == 'cliente'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cliente / Comprador',
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Poderá consultar cardápio e fazer pedidos futuros. Sem gerência.',
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Opção Membro da Loja
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => tipoAcesso = 'membro'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tipoAcesso == 'membro'
                                  ? theme.borderColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tipoAcesso == 'membro'
                                    ? theme.textColor
                                    : theme.borderColor.withValues(alpha: 0.4),
                                width: tipoAcesso == 'membro' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tipoAcesso == 'membro'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Novo Membro da Loja',
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Adiciona à equipe de trabalhadores com acesso operacional.',
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
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Você autoriza que este aparelho se conecte e sincronize com a loja?',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () {
                    if (!respondido) {
                      respondido = true;
                      Navigator.of(dialogCtx).pop(ResultadoAutorizacaoConexao.recusado);
                      if (!completer.isCompleted) {
                        completer.complete(ResultadoAutorizacaoConexao.recusado);
                      }
                    }
                  },
                  child: Text(
                    'Recusar',
                    style: theme.getTextStyle(
                      color: theme.dangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (!respondido) {
                      respondido = true;
                      final resultado = jaEhMembro || tipoAcesso == 'membro'
                          ? ResultadoAutorizacaoConexao.autorizadoMembro
                          : ResultadoAutorizacaoConexao.autorizadoCliente;
                      Navigator.of(dialogCtx).pop(resultado);
                      if (!completer.isCompleted) completer.complete(resultado);
                    }
                  },
                  child: Text(
                    'Autorizar',
                    style: theme.getTextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Timeout de segurança de 45 segundos para não prender a conexão caso o operador esteja ausente
    Future.delayed(const Duration(seconds: 45), () {
      if (!respondido) {
        respondido = true;
        if (context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop(ResultadoAutorizacaoConexao.recusado);
          } catch (_) {}
        }
        if (!completer.isCompleted) {
          completer.complete(ResultadoAutorizacaoConexao.recusado);
        }
      }
    });

    return completer.future;
  }

  static Widget _itemInfo(AppTheme theme, String rotulo, String valor, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 16, color: theme.secondaryTextColor),
        const SizedBox(width: 6),
        Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valor,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
