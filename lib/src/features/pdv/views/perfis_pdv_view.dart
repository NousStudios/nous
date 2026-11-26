import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/criar_perfil_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class PerfisPdvView extends StatefulWidget {
  final bool abrirSincronizacaoInicial;

  const PerfisPdvView({
    super.key,
    this.abrirSincronizacaoInicial = false,
  });

  @override
  State<PerfisPdvView> createState() => _PerfisPdvViewState();
}

class _PerfisPdvViewState extends State<PerfisPdvView> {
  static const double _larguraMaximaConteudo = 600;

  @override
  void initState() {
    super.initState();
    ThemeController.isLoginScreen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pdv = context.read<PdvProvider>();
      final auth = context.read<AuthProvider>();

      final plataforma = Theme.of(context).platform;
      if (plataforma != TargetPlatform.windows &&
          plataforma != TargetPlatform.linux &&
          plataforma != TargetPlatform.macOS) {
        await ClienteRedeLocal().tentarAutoConectarSeDisponivel(pdv, auth);
      }
      unawaited(ClienteRedeLocal().verificarAtualizacaoLocal());

      if (widget.abrirSincronizacaoInicial && mounted) {
        SincronizacaoRedeDialog.mostrar(
          context,
          theme: ThemeController.currentTheme.value,
        );
      }
    });
  }

  Future<void> _aoTentarCriarPerfil(BuildContext context, AppTheme theme) async {
    final auth = context.read<AuthProvider>();
    if (auth.modoVisitante) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Modo Visitante',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Você está no modo visitante. Entre com sua Conta Nous para criar ou administrar uma loja.',
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
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                auth.sair();
                context.read<PdvProvider>().limparSessao();
                _handleLogout(context);
              },
              child: Text(
                'Fazer Login',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    showCriarPerfilDialog(context);
  }

  void _handleLogout(BuildContext context) {
    context.read<AuthProvider>().sair();
    context.read<PdvProvider>().limparSessao();
    context.read<NotificacoesProvider>().limpar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  Widget _blocoComTitulo({
    required AppTheme theme,
    required String titulo,
    required Widget conteudo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              titulo,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          conteudo,
        ],
      ),
    );
  }

  Widget _wrapDeLojas({
    required BuildContext context,
    required AppTheme theme,
    required List<Loja> lojas,
  }) {
    final auth = context.read<AuthProvider>();
    final cpfLimpo = auth.cpf.replaceAll(RegExp(r'\D'), '');
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lojas.map((loja) {
        final ehMembro = !auth.modoVisitante &&
            cpfLimpo.isNotEmpty &&
            (loja.id == PdvProvider.idLojaColetivaNous ||
                loja.membros.any(
                  (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
                ));
        return _PerfilCard(
          theme: theme,
          icon: Icons.storefront,
          label: loja.nome,
          logoUrl: loja.logo,
          onTap: () {
            GuardaAcaoUi.executarSincrono('abrir_loja_${loja.id}', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ehMembro
                      ? DadosPerfilView(
                          lojaId: loja.id,
                          abaInicial: AbaLoja.gestao,
                        )
                      : VitrineLojaView(
                          lojaId: loja.id,
                          lojaFallback: loja,
                        ),
                ),
              );
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdvProvider = context.watch<PdvProvider>();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f11): () {
          JanelaWindowsService.alternarTelaCheia();
        },
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            final authProvider = context.watch<AuthProvider>();
            final ehVisitante = authProvider.modoVisitante;
            final ehIsolado = authProvider.perfilIsolado;
            final lojasVisiveisAdmin = ehVisitante
                ? pdvProvider.lojas
                    .where((l) => l.id != PdvProvider.idLojaColetivaNous)
                    .toList()
                : pdvProvider.lojasQueAdministro;

            final larguraDaTela = MediaQuery.sizeOf(context).width;
            final expandido =
                pdvProvider.layoutDesktopGlobal && larguraDaTela > 850;

            final blocoAdministro = _blocoComTitulo(
              theme: theme,
              titulo: ehVisitante
                  ? 'Lojas na Rede (Modo Visitante)'
                  : 'Meus Perfis Profissionais',
              conteudo: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lojasVisiveisAdmin.isEmpty)
                    EstadoVazioContainer(
                      theme: theme,
                      mensagem: ehVisitante
                          ? 'Nenhuma loja disponível na rede local ainda.'
                          : 'Nenhum perfil profissional ainda.',
                    )
                  else
                    _wrapDeLojas(
                      context: context,
                      theme: theme,
                      lojas: lojasVisiveisAdmin,
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        side: BorderSide(color: theme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => GuardaAcaoUi.executarUnico(
                        'criar_perfil_dialog',
                        () => _aoTentarCriarPerfil(context, theme),
                      ),
                      icon: Icon(
                        Icons.add,
                        color: theme.textColor,
                        size: 18,
                      ),
                      label: Text(
                        'Criar Perfil',
                        style: theme.getTextStyle(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final blocoParticipo = _blocoComTitulo(
              theme: theme,
              titulo: 'Perfis que eu participo',
              conteudo: pdvProvider.lojasQueParticipo.isEmpty
                  ? EstadoVazioContainer(
                      theme: theme,
                      mensagem:
                          'Você não participa de nenhum perfil ainda.',
                    )
                  : _wrapDeLojas(
                      context: context,
                      theme: theme,
                      lojas: pdvProvider.lojasQueParticipo,
                    ),
            );

            final bannerAvisoModo = (ehVisitante || ehIsolado)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ehVisitante
                              ? Icons.visibility_outlined
                              : Icons.shield_outlined,
                          size: 20,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ehVisitante
                                ? 'Você está no Modo Visitante: pode explorar as lojas da rede, mas as identidades dos usuários ficam ocultas.'
                                : 'Perfil em Modo Isolado: você pode criar e configurar sua loja normalmente. A interação com outros usuários será liberada após a primeira verificação.',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();

            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: CustomAppBar(
                title: ehVisitante ? 'Explorar (Visitante)' : 'Meus Perfis',
                showBackButton: false,
                onLogout: () => _handleLogout(context),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: expandido
                                  ? 1200
                                  : _larguraMaximaConteudo,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  bannerAvisoModo,
                                  expandido && !ehVisitante
                                      ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: blocoAdministro,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 5,
                                              child: blocoParticipo,
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            blocoAdministro,
                                            if (!ehVisitante) ...[
                                              const SizedBox(height: 16),
                                              blocoParticipo,
                                            ],
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: FloatingBottomNavBar(
                maxWidth: expandido ? 1200 : _larguraMaximaConteudo,
                slotSelecionado: 0,
                subIndiceSelecionado: 1,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PerfilCard extends StatefulWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final String logoUrl;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.theme,
    required this.icon,
    required this.label,
    this.logoUrl = '',
    required this.onTap,
  });

  @override
  State<_PerfilCard> createState() => _PerfilCardState();
}

class _PerfilCardState extends State<_PerfilCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final temLogo = ImagemService.existe(widget.logoUrl);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 108,
          height: 108,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? theme.buttonColor : theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (temLogo)
                ImagemService.construirImagem(
                  widget.logoUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  fallback: Icon(
                    widget.icon,
                    size: 32,
                    color: _hovering
                        ? theme.buttonTextColor
                        : theme.secondaryTextColor,
                  ),
                )
              else
                Icon(
                  widget.icon,
                  size: 32,
                  color: _hovering
                      ? theme.buttonTextColor
                      : theme.secondaryTextColor,
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextoRolante(
                  texto: widget.label,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: _hovering ? theme.buttonTextColor : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}