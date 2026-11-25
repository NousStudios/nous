import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/google_oauth_service.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/cadastrar_nome_usuario_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/contas/acoes_conta_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/contas/card_conta_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/contas/secao_emails_usuario.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class ContasUsuarioView extends StatefulWidget {
  const ContasUsuarioView({super.key});

  @override
  State<ContasUsuarioView> createState() => _ContasUsuarioViewState();
}

class _ContasUsuarioViewState extends State<ContasUsuarioView> {
  bool _autenticandoGoogle = false;

  @override
  void initState() {
    super.initState();
    ThemeController.entrarTelaLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarNomeDeUsuarioSeNecessario();
      _sincronizarFotoSeNecessario();
    });
  }

  @override
  void dispose() {
    ThemeController.sairTelaLogin();
    super.dispose();
  }

  Future<void> _verificarNomeDeUsuarioSeNecessario() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta != null && conta.nomeDeUsuario.trim().isEmpty) {
      final username = await CadastrarNomeUsuarioDialog.mostrar(
        context,
        cpf: conta.cpf,
        nomeOuApelidoAtual:
            conta.apelido.isNotEmpty ? conta.apelido : conta.nome,
        theme: ThemeController.currentTheme.value,
      );
      if (username != null && username.trim().isNotEmpty && mounted) {
        await auth.atualizarNomeDeUsuario(username.trim());
      }
    }
  }

  void _sincronizarFotoSeNecessario() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final conta = auth.contaAtual;
    if (conta != null && conta.foto.trim().isEmpty) {
      final fotoCliente = pdv.buscarFotoClientePorCpf(conta.cpf);
      if (fotoCliente != null && fotoCliente.isNotEmpty) {
        auth.sincronizarFotoComClienteSeNecessario(fotoCliente);
      }
    }
  }

  Future<void> _entrarComEmail(BuildContext context, [String? email]) async {
    final emailFinal = email?.trim();
    if (emailFinal == null || emailFinal.isEmpty) {
      AcoesContaUsuario.mostrarErro(
        context,
        ThemeController.currentTheme.value,
        'É obrigatório cadastrar e selecionar um e-mail para prosseguir.',
      );
      await _abrirAdicionarEmail(context);
      return;
    }

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    if (conta != null && !conta.emailEstaVerificado(emailFinal)) {
      if (_autenticandoGoogle) return;
      setState(() => _autenticandoGoogle = true);
      final resultado = await GoogleOAuthService.autenticarComGoogle(
        loginHint: emailFinal,
      );
      if (!context.mounted) return;
      setState(() => _autenticandoGoogle = false);

      final emailGoogle = resultado.email?.trim().toLowerCase() ?? '';
      if (!resultado.sucesso || emailGoogle.isEmpty) {
        AcoesContaUsuario.mostrarErro(
          context,
          ThemeController.currentTheme.value,
          resultado.erro ??
              'Autenticação Google necessária para validar este e-mail.',
        );
        return;
      }

      if (emailGoogle != emailFinal.toLowerCase()) {
        AcoesContaUsuario.mostrarErro(
          context,
          ThemeController.currentTheme.value,
          'O e-mail autenticado ($emailGoogle) é diferente de $emailFinal.',
        );
        return;
      }

      await auth.marcarEmailComoVerificadoGoogle(emailFinal);
      if (!context.mounted) return;
    }

    auth.definirEmailAtivo(emailFinal);
    unawaited(ClienteRedeLocal().verificarAtualizacaoLocal());
    final cpf = auth.cpf;
    await context.read<PdvProvider>().entrarComCpf(cpf);
    if (context.mounted) {
      await context.read<NotificacoesProvider>().carregarParaCpf(cpf);
    }

    final telaInicial = await FloatingBottomNavBar.obterTelaInicialPorCpf(cpf);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => telaInicial,
      ),
      (route) => false,
    );
  }

  Future<void> _abrirAdicionarEmail(BuildContext context) async {
    final sucesso = await AdicionarEmailDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
    );
    if (sucesso == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.emailAtivo != null && auth.emailAtivo!.isNotEmpty) {
        await _entrarComEmail(context, auth.emailAtivo);
      }
    }
  }

  Future<void> _conectarComGoogleDireto(BuildContext context) async {
    if (_autenticandoGoogle) return;
    setState(() => _autenticandoGoogle = true);

    final resultado = await GoogleOAuthService.autenticarComGoogle();
    if (!context.mounted) return;
    setState(() => _autenticandoGoogle = false);

    final email = resultado.email?.trim() ?? '';
    if (!resultado.sucesso || email.isEmpty) {
      AcoesContaUsuario.mostrarErro(
        context,
        ThemeController.currentTheme.value,
        resultado.erro ?? 'Falha ao autenticar com o Google.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.adicionarEmail(email, verificadoGoogle: true);
    auth.definirEmailAtivo(email);

    if (context.mounted) {
      await _entrarComEmail(context, auth.emailAtivo ?? email);
    }
  }

  void _voltar(BuildContext context) {
    context.read<AuthProvider>().sair();
    context.read<PdvProvider>().limparSessao();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _removerEmail(BuildContext context, String email) async {
    final confirmar = await AcoesContaUsuario.confirmarExclusaoEmail(
      context,
      ThemeController.currentTheme.value,
      email,
    );
    if (confirmar && context.mounted) {
      await context.read<AuthProvider>().removerEmail(email);
    }
  }

  Future<void> _excluirConta(BuildContext context) async {
    final confirmar = await AcoesContaUsuario.confirmarExclusaoContaDefinitiva(
      context,
      ThemeController.currentTheme.value,
    );
    if (!confirmar || !context.mounted) return;

    final cpf = context.read<AuthProvider>().cpf;
    await context.read<PdvProvider>().excluirDadosDoCpf(cpf);

    if (!context.mounted) return;
    await context.read<AuthProvider>().excluirConta(cpf);

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
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
                      CardContaUsuario(theme: theme, conta: conta),
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
                      SecaoEmailsUsuario(
                        theme: theme,
                        conta: conta,
                        autenticandoGoogle: _autenticandoGoogle,
                        aoConectarGoogle: () =>
                            _conectarComGoogleDireto(context),
                        aoAdicionarEmail: () => _abrirAdicionarEmail(context),
                        aoEntrarComEmail: (email) =>
                            _entrarComEmail(context, email),
                        aoExcluirEmail: (email) =>
                            _removerEmail(context, email),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _excluirConta(context),
                        child: Text(
                          'Excluir Conta Nous Definitivamente',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.dangerColor,
                          ),
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
