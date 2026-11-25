import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/app_bar/barra_sincronizacao_wifi_settings.dart';
import 'package:nous/src/core/widgets/app_bar/seletor_tema_dialog.dart';
import 'package:nous/src/core/widgets/atualizacao_dialog.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/conta_nous_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart';

String _formatarCpf(String cpf, {bool mascarado = false}) {
  final limpo = cpf.replaceAll(RegExp(r'\D'), '');
  if (limpo.length != 11) return cpf;
  if (mascarado) {
    return '${limpo.substring(0, 3)}.***.***-**';
  }
  return '${limpo.substring(0, 3)}.${limpo.substring(3, 6)}.'
      '${limpo.substring(6, 9)}-${limpo.substring(9, 11)}';
}

/// Diálogo de configurações rápidas exibido a partir da AppBar.
class ConfiguracoesAppBarDialog {
  const ConfiguracoesAppBarDialog._();

  static Future<void> mostrar(
    BuildContext context, {
    String? lojaId,
    VoidCallback? onLogout,
    required VoidCallback onLogoutPadrao,
  }) {
    final authProvider = context.read<AuthProvider>();
    var mostrarCpf = false;

    return GuardaAcaoUi.executarUnico<void>(
      'dialog_settings',
      () => showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return ValueListenableBuilder<AppTheme>(
                valueListenable: ThemeController.currentTheme,
                builder: (context, currentTheme, child) {
                  final conta = authProvider.contaAtual;
                  final mostrarGrupoConta = conta != null || onLogout != null;

                  return Dialog(
                    backgroundColor: currentTheme.cardBackgroundColor,
                    insetPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: currentTheme.borderColor),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 440,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Configurações',
                              textAlign: TextAlign.center,
                              style: currentTheme.getTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(
                                        Icons.palette_outlined,
                                        color: currentTheme.secondaryTextColor,
                                      ),
                                      title: Text(
                                        'Tema',
                                        style: currentTheme.getTextStyle(),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        SeletorTemaDialog.mostrar(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.language,
                                        color: currentTheme.secondaryTextColor,
                                      ),
                                      title: Text(
                                        'Idioma',
                                        style: currentTheme.getTextStyle(),
                                      ),
                                      onTap: () {},
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.info_outline,
                                        color: currentTheme.secondaryTextColor,
                                      ),
                                      title: Text(
                                        'Sobre o App',
                                        style: currentTheme.getTextStyle(),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        AtualizacaoDialog.mostrar(context);
                                      },
                                    ),
                                    Divider(color: currentTheme.borderColor),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: BarraSincronizacaoWifiSettings(
                                        theme: currentTheme,
                                        onTap: () {
                                          Navigator.pop(context);
                                          final pdv =
                                              context.read<PdvProvider>();
                                          final lojaAtual = lojaId != null
                                              ? pdv.buscarPorId(lojaId)
                                              : null;
                                          SincronizacaoRedeDialog.mostrar(
                                            context,
                                            loja: lojaAtual,
                                          );
                                        },
                                      ),
                                    ),
                                    if (mostrarGrupoConta) ...[
                                      Divider(color: currentTheme.borderColor),
                                      if (conta != null)
                                        _CartaoContaSettings(
                                          currentTheme: currentTheme,
                                          authProvider: authProvider,
                                          mostrarCpf: mostrarCpf,
                                          onAlternarMostrarCpf: () {
                                            setDialogState(() {
                                              mostrarCpf = !mostrarCpf;
                                            });
                                          },
                                          onAbrirConta: () {
                                            Navigator.pop(dialogCtx);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ContaNousView(),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                    if (conta != null ||
                                        onLogout != null ||
                                        authProvider.contaAtual != null) ...[
                                      Divider(color: currentTheme.borderColor),
                                      ListTile(
                                        leading: Icon(
                                          Icons.logout,
                                          color: currentTheme.dangerColor,
                                        ),
                                        title: Text(
                                          'Sair',
                                          style: currentTheme.getTextStyle(
                                            color: currentTheme.dangerColor,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (onLogout != null) {
                                            onLogout();
                                          } else {
                                            onLogoutPadrao();
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Fechar',
                                  style: currentTheme.getTextStyle(
                                    color: currentTheme.secondaryTextColor,
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
            },
          );
        },
      ),
    );
  }
}

class _CartaoContaSettings extends StatelessWidget {
  final AppTheme currentTheme;
  final AuthProvider authProvider;
  final bool mostrarCpf;
  final VoidCallback onAlternarMostrarCpf;
  final VoidCallback onAbrirConta;

  const _CartaoContaSettings({
    required this.currentTheme,
    required this.authProvider,
    required this.mostrarCpf,
    required this.onAlternarMostrarCpf,
    required this.onAbrirConta,
  });

  @override
  Widget build(BuildContext context) {
    final conta = authProvider.contaAtual!;
    final pdv = context.read<PdvProvider>();
    if (conta.foto.trim().isEmpty) {
      final fotoCliente = pdv.buscarFotoClientePorCpf(conta.cpf);
      if (fotoCliente != null && fotoCliente.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          authProvider.sincronizarFotoComClienteSeNecessario(fotoCliente);
        });
      }
    }

    final fotoResolvida = ImagemService.resolverCaminhoExistente(conta.foto);
    final temFoto = fotoResolvida != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentTheme.borderColor.withValues(alpha: 0.8),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: temFoto
                      ? Image.file(
                          File(fotoResolvida),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 28,
                            color: currentTheme.textColor,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 28,
                          color: currentTheme.textColor,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conta.nome,
                      style: currentTheme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatarCpf(
                            conta.cpf,
                            mascarado: !mostrarCpf,
                          ),
                          style: currentTheme.getTextStyle(
                            fontSize: 12,
                            color: currentTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onAlternarMostrarCpf,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              mostrarCpf
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 14,
                              color: currentTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (authProvider.emailAtivo != null &&
                        authProvider.emailAtivo!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      TextoRolante(
                        texto: authProvider.emailAtivo!,
                        style: currentTheme.getTextStyle(
                          fontSize: 11,
                          color: currentTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: currentTheme.borderColor.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAbrirConta,
              icon: Icon(
                Icons.manage_accounts_outlined,
                size: 18,
                color: currentTheme.textColor,
              ),
              label: Text(
                'Conta Nous',
                style: currentTheme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: currentTheme.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
