import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/theme_customizer_dialog.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/notificacoes_dialog.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/widgets/atualizacao_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/backup_dialog.dart';

String _formatarCpf(String cpf) {
  if (cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
      '${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onLogout,
  });

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, currentTheme, child) {
            return ValueListenableBuilder<List<SavedTheme>>(
              valueListenable: ThemeController.savedThemes,
              builder: (context, savedThemesList, child) {
                final screenWidth = MediaQuery.of(context).size.width;
                final selectorWidth =
                    screenWidth < 360 ? screenWidth * 0.9 : 320.0;

                return AlertDialog(
                  backgroundColor: currentTheme.cardBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: currentTheme.borderColor),
                  ),
                  title: Text(
                    'Aparência',
                    textAlign: TextAlign.center,
                    style: currentTheme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: currentTheme.textColor,
                    ),
                  ),
                  content: SizedBox(
                    width: selectorWidth,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.dark_mode,
                                color: currentTheme.secondaryTextColor),
                            title: Text('Modo Escuro (Padrão)',
                                style: currentTheme.getTextStyle()),
                            onTap: () {
                              ThemeController.updateTheme(AppTheme.dark);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.light_mode,
                                color: currentTheme.secondaryTextColor),
                            title: Text('Modo Claro',
                                style: currentTheme.getTextStyle()),
                            onTap: () {
                              ThemeController.updateTheme(AppTheme.light);
                              Navigator.pop(context);
                            },
                          ),
                          if (savedThemesList.isNotEmpty) ...[
                            Divider(color: currentTheme.borderColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Meus Temas',
                                  style: currentTheme.getTextStyle(
                                    fontSize: 12,
                                    color: currentTheme.secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            ...savedThemesList.map((saved) {
                              return ListTile(
                                leading: Icon(Icons.palette,
                                    color: currentTheme.textColor),
                                title: Text(saved.name,
                                    style: currentTheme.getTextStyle()),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: currentTheme.secondaryTextColor),
                                  tooltip: 'Excluir tema',
                                  onPressed: () => ThemeController
                                      .deleteSavedTheme(saved.name),
                                ),
                                onTap: () {
                                  ThemeController.updateTheme(saved.theme);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],
                          Divider(color: currentTheme.borderColor),
                          ListTile(
                            leading: Icon(Icons.color_lens_outlined,
                                color: currentTheme.secondaryTextColor),
                            title: Text(
                              'Personalizar Cores e Fontes...',
                              style: currentTheme.getTextStyle(),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    const ThemeCustomizerDialog(),
                              );
                            },
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

  void _showSettingsDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, currentTheme, child) {
            final conta = authProvider.contaAtual;
            final mostrarGrupoConta = conta != null || onLogout != null;

            return AlertDialog(
              backgroundColor: currentTheme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: currentTheme.borderColor),
              ),
              titlePadding:
                  const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
              title: Text(
                'Configurações',
                textAlign: TextAlign.center,
                style: currentTheme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.textColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined,
                        color: currentTheme.secondaryTextColor),
                    title: Text('Tema',
                        style: currentTheme.getTextStyle()),
                    onTap: () {
                      Navigator.pop(context);
                      _showThemeSelector(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.language,
                        color: currentTheme.secondaryTextColor),
                    title: Text('Idioma',
                        style: currentTheme.getTextStyle()),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline,
                        color: currentTheme.secondaryTextColor),
                    title: Text('Sobre o App',
                        style: currentTheme.getTextStyle()),
                    onTap: () {
                      Navigator.pop(context);
                      AtualizacaoDialog.mostrar(context);
                    },
                  ),
                  if (mostrarGrupoConta) ...[
                    Divider(color: currentTheme.borderColor),
                    if (conta != null) ...[
                      Builder(builder: (dialogCtx) {
                        final pdv = dialogCtx.read<PdvProvider>();
                        if (conta.foto.trim().isEmpty) {
                          final fotoCliente =
                              pdv.buscarFotoClientePorCpf(conta.cpf);
                          if (fotoCliente != null && fotoCliente.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              authProvider
                                  .sincronizarFotoComClienteSeNecessario(
                                      fotoCliente);
                            });
                          }
                        }

                        final temFoto = conta.foto.isNotEmpty &&
                            File(conta.foto).existsSync();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  FichaUsuarioDialog.mostrar(
                                    dialogCtx,
                                    theme: currentTheme,
                                    usuario: conta,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: currentTheme.borderColor),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          child: temFoto
                                              ? Image.file(
                                                  File(conta.foto),
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error,
                                                              stackTrace) =>
                                                          Icon(
                                                    Icons.person,
                                                    size: 32,
                                                    color:
                                                        currentTheme.textColor,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  size: 32,
                                                  color:
                                                      currentTheme.textColor,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        conta.nome,
                                        textAlign: TextAlign.center,
                                        style: currentTheme.getTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: currentTheme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatarCpf(conta.cpf),
                                        textAlign: TextAlign.center,
                                        style: currentTheme.getTextStyle(
                                            fontSize: 12),
                                      ),
                                      if (authProvider.emailAtivo != null &&
                                          authProvider.emailAtivo!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          authProvider.emailAtivo!,
                                          textAlign: TextAlign.center,
                                          style: currentTheme.getTextStyle(
                                            fontSize: 12,
                                            color: currentTheme.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  BackupDialog.mostrar(
                                    context,
                                    theme: currentTheme,
                                  );
                                },
                                icon: Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 18,
                                  color: currentTheme.secondaryTextColor,
                                ),
                                label: Text(
                                  'Backup dos dados',
                                  style: currentTheme.getTextStyle(
                                    fontSize: 13,
                                    color: currentTheme.secondaryTextColor,
                                  ).copyWith(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (onLogout != null)
                      ListTile(
                        leading: const Icon(Icons.logout,
                            color: Colors.redAccent),
                        title: Text(
                          'Sair',
                          style: currentTheme.getTextStyle(
                              color: Colors.redAccent),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onLogout!();
                        },
                      ),
                    Divider(color: currentTheme.borderColor),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Fechar',
                    style: currentTheme.getTextStyle(
                        color: currentTheme.secondaryTextColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _botaoNotificacoes(BuildContext context, AppTheme theme) {
    final notificacoes = context.watch<NotificacoesProvider>();
    final pdv = context.watch<PdvProvider>();
    final quantidadeConvites = notificacoes.quantidadePendentes;
    final totalEstoqueBaixo = pdv.totalItensEstoqueBaixo;
    final quantidadeTotal = quantidadeConvites + totalEstoqueBaixo;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: totalEstoqueBaixo > 0
              ? 'Notificações ($totalEstoqueBaixo item(ns) com estoque baixo/esgotado)'
              : 'Notificações',
          icon: Icon(
            quantidadeTotal > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none,
            color: totalEstoqueBaixo > 0
                ? Colors.redAccent
                : theme.secondaryTextColor,
          ),
          onPressed: () => NotificacoesDialog.mostrar(context),
        ),
        if (quantidadeTotal > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quantidadeTotal > 9 ? '9+' : '$quantidadeTotal',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _botaoAtualizacoes(BuildContext context, AppTheme theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: AtualizacaoService.temAtualizacao,
      builder: (context, temAtualizacao, child) {
        if (!temAtualizacao) return const SizedBox.shrink();

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Nova Atualização Disponível!',
              icon: Icon(
                Icons.system_update_alt_rounded,
                color: theme.textColor,
                size: 22,
              ),
              onPressed: () => AtualizacaoDialog.mostrar(context),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return AppBar(
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          title: Text(
            title,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          centerTitle: true,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: theme.secondaryTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: [
            _botaoNotificacoes(context, theme),
            _botaoAtualizacoes(context, theme),
            IconButton(
              tooltip: 'Configurações',
              icon: Image.asset(
                'assets/icons/settings_icon.png',
                width: 24,
                height: 24,
                color: theme.secondaryTextColor,
              ),
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}