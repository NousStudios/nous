import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class ContasUsuarioView extends StatelessWidget {
  const ContasUsuarioView({super.key});

  void _entrarComEmail(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  Future<void> _abrirAdicionarEmail(BuildContext context) async {
    final sucesso = await AdicionarEmailDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
    );
    if (sucesso == true && context.mounted) _entrarComEmail(context);
  }

  @override
  Widget build(BuildContext context) {
    final conta = context.watch<AuthProvider>().contaAtual;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      _CardConta(theme: theme, nome: conta?.nome ?? ''),
                      const SizedBox(height: 24),
                      Text(
                        'Contas do usuário',
                        style: theme.getTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (conta == null || conta.emails.isEmpty)
                        EstadoVazioContainer(
                          theme: theme,
                          mensagem: 'Nenhum e-mail associado ainda.',
                        )
                      else
                        Column(
                          children: [
                            for (final email in conta.emails)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _BarraEmail(
                                  theme: theme,
                                  email: email,
                                  aoClicar: () => _entrarComEmail(context),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _abrirAdicionarEmail(context),
                        child: Text(
                          'Adicionar email',
                          style: theme.getTextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardConta extends StatelessWidget {
  final AppTheme theme;
  final String nome;

  const _CardConta({required this.theme, required this.nome});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ficha do usuário: em construção')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Icon(Icons.person, size: 40, color: theme.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              nome.isEmpty ? 'Nome Associado ao CPF' : nome,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraEmail extends StatefulWidget {
  final AppTheme theme;
  final String email;
  final VoidCallback aoClicar;

  const _BarraEmail({
    required this.theme,
    required this.email,
    required this.aoClicar,
  });

  @override
  State<_BarraEmail> createState() => _BarraEmailState();
}

class _BarraEmailState extends State<_BarraEmail> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline, size: 20, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}