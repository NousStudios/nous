import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/criar_perfil_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class PerfisPdvView extends StatelessWidget {
  const PerfisPdvView({super.key});

  static const double _larguraMaximaConteudo = 600;

  void _handleLogout(BuildContext context) {
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lojas.map((loja) {
        return _PerfilCard(
          theme: theme,
          icon: Icons.storefront,
          label: loja.nome,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DadosPerfilView(lojaId: loja.id),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdvProvider = context.watch<PdvProvider>();

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Meus Perfis',
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
                        constraints: const BoxConstraints(
                          maxWidth: _larguraMaximaConteudo,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _blocoComTitulo(
                                theme: theme,
                                titulo: 'Meus Perfis Profissionais',
                                conteudo: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (pdvProvider
                                        .lojasQueAdministro.isEmpty)
                                      EstadoVazioContainer(
                                        theme: theme,
                                        mensagem:
                                            'Nenhum perfil profissional ainda.',
                                      )
                                    else
                                      _wrapDeLojas(
                                        context: context,
                                        theme: theme,
                                        lojas: pdvProvider.lojasQueAdministro,
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
                                          side: BorderSide(
                                              color: theme.borderColor),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          showCriarPerfilDialog(context);
                                        },
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
                              ),
                              const SizedBox(height: 16),
                              _blocoComTitulo(
                                theme: theme,
                                titulo: 'Perfis que eu participo',
                                conteudo: pdvProvider
                                        .lojasQueParticipo.isEmpty
                                    ? EstadoVazioContainer(
                                        theme: theme,
                                        mensagem:
                                            'Você não participa de nenhum perfil.',
                                      )
                                    : _wrapDeLojas(
                                        context: context,
                                        theme: theme,
                                        lojas: pdvProvider.lojasQueParticipo,
                                      ),
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
          bottomNavigationBar: const FloatingBottomNavBar(
            maxWidth: _larguraMaximaConteudo,
          ),
        );
      },
    );
  }
}

class _PerfilCard extends StatefulWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.theme,
    required this.icon,
    required this.label,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovering ? theme.buttonColor : theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: _hovering
                    ? theme.buttonTextColor
                    : theme.secondaryTextColor,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: _hovering ? theme.buttonTextColor : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}