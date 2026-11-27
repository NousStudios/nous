import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/app_bar/configuracoes_app_bar_dialog.dart';
import 'package:nous/src/core/widgets/atualizacao_dialog.dart';
import 'package:nous/src/core/widgets/botao_notificacoes_app_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onLogout;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final String? lojaId;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onLogout,
    this.onBackPressed,
    this.actions,
    this.lojaId,
  });

  Widget _botaoNotificacoes(BuildContext context, AppTheme theme) {
    final auth = context.watch<AuthProvider>();
    final cpfUsuario = auth.contaAtual?.cpf ?? '';
    return BotaoNotificacoesAppBar(
      lojaId: lojaId,
      cpfUsuario: cpfUsuario,
      theme: theme,
    );
  }

  Widget _botaoAtualizacoes(BuildContext context, AppTheme theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: AtualizacaoService.temAtualizacao,
      builder: (context, temAtualizacao, child) {
        if (!temAtualizacao) return const SizedBox.shrink();

        final versaoNova = AtualizacaoService.infoAtualizacao.value?.versao;
        final tooltipTexto = (versaoNova != null && versaoNova.isNotEmpty)
            ? 'Nova Versão v$versaoNova Disponível! Toque para atualizar.'
            : 'Nova Atualização Disponível! Toque para atualizar.';

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.dangerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.dangerColor.withValues(alpha: 0.35),
                  ),
                ),
                child: IconButton(
                  tooltip: tooltipTexto,
                  icon: Icon(
                    Icons.system_update_alt_rounded,
                    color: theme.dangerColor,
                    size: 22,
                  ),
                  onPressed: () => AtualizacaoDialog.mostrar(context),
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: theme.dangerColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: theme.dangerColor.withValues(alpha: 0.45),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'NOVO',
                    style: theme.getTextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          automaticallyImplyLeading: false,
          title: TextoRolante(
            texto: title,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          centerTitle: true,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.secondaryTextColor,
                  ),
                  onPressed: () {
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : null,
          actions: [
            ...?actions,
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
              onPressed: () => ConfiguracoesAppBarDialog.mostrar(
                context,
                lojaId: lojaId,
                onLogout: onLogout,
                onLogoutPadrao: () => _efetuarLogoutPadrao(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _efetuarLogoutPadrao(BuildContext context) {
    try {
      ClienteRedeLocal().desconectar(manual: true);
    } catch (_) {}
    try {
      ServidorRedeLocal().parar();
    } catch (_) {}

    context.read<AuthProvider>().sair();
    context.read<PdvProvider>().entrarComoVisitante();
    context.read<NotificacoesProvider>().limpar();

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
