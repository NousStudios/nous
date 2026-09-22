import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class ContasUsuarioView extends StatelessWidget {
  const ContasUsuarioView({super.key});

  Future<void> _entrarComEmail(BuildContext context) async {
    final cpf = context.read<AuthProvider>().cpf;
    await context.read<PdvProvider>().entrarComCpf(cpf);

    if (!context.mounted) return;
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
    if (sucesso == true && context.mounted) await _entrarComEmail(context);
  }

  void _voltar(BuildContext context) {
    context.read<AuthProvider>().sair();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _removerEmail(BuildContext context, String email) async {
    final theme = ThemeController.currentTheme.value;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir E-mail',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja remover o e-mail "$email" desta '
            'conta?',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      await context.read<AuthProvider>().removerEmail(email);
    }
  }

  Future<void> _excluirConta(BuildContext context) async {
    final theme = ThemeController.currentTheme.value;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Cadastro',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir este CPF do Nous? Essa ação '
            'não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && context.mounted) {
      await context.read<AuthProvider>().excluirConta();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.textColor),
                          onPressed: () => _voltar(context),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                                  aoExcluir: () =>
                                      _removerEmail(context, email),
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
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _excluirConta(context),
                        child: Text(
                          'Excluir Cadastro',
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
  final VoidCallback aoExcluir;

  const _BarraEmail({
    required this.theme,
    required this.email,
    required this.aoClicar,
    required this.aoExcluir,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.borderColor),
                ),
                onSelected: (valor) {
                  if (valor == 'excluir') widget.aoExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text(
                      'Excluir e-mail',
                      style: theme.getTextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}