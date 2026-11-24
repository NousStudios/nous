import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/biometria_auth_service.dart';
import 'package:nous/src/features/auth/views/dialogs/dialog_onboarding_identidade_nous.dart';
import 'package:nous/src/features/auth/views/widgets/cadastrar_nome_usuario_dialog.dart';
import 'package:nous/src/features/auth/views/contas_usuario_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart';

class LoginButtonsWidget extends StatefulWidget {
  const LoginButtonsWidget({super.key});

  @override
  State<LoginButtonsWidget> createState() => _LoginButtonsWidgetState();
}

class _LoginButtonsWidgetState extends State<LoginButtonsWidget> {
  late final Future<String?> _cpfBiometriaFuture;

  @override
  void initState() {
    super.initState();
    _cpfBiometriaFuture = BiometriaAuthService.obterCpfVinculado();
  }

  Future<void> _entrar(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final notificacoesProvider = context.read<NotificacoesProvider>();
    final pdvProvider = context.read<PdvProvider>();
    final theme = ThemeController.currentTheme.value;

    // FLUXO MANDATÓRIO:
    // 1. Login (CPF digitado)
    // 2. Tela de Sincronia Wi-Fi (conectar ao balcão para reconciliar a conta)
    await SincronizacaoRedeDialog.mostrar(
      context,
      theme: theme,
      modoLogin: true,
    );

    if (!context.mounted) return;

    // 3. Consulta a conta na rede local Wi-Fi / cofre local
    final contaEncontrada = await authProvider.buscarConta();

    if (!context.mounted) return;

    if (!contaEncontrada) {
      // 1. Cadastra primeiro o nome de usuário (@username) soberano
      final username = await CadastrarNomeUsuarioDialog.mostrar(
        context,
        cpf: authProvider.cpf,
        theme: theme,
      );
      if (username == null || username.trim().isEmpty || !context.mounted) {
        return;
      }

      // 2. Onboarding completo da Identidade do Usuário & Regras de Transparência
      final dadosIdentidade = await DialogOnboardingIdentidadeNous.mostrar(
        context,
        cpf: authProvider.cpf,
        username: username.trim(),
        theme: theme,
      );
      if (dadosIdentidade == null || !context.mounted) {
        return;
      }

      await authProvider.registrarNovaContaCompleta(
        nome: dadosIdentidade.nome,
        apelido: dadosIdentidade.apelido,
        nomeDeUsuario: username.trim(),
        foto: dadosIdentidade.foto,
        biografia: dadosIdentidade.biografia,
        dadosPrivados: dadosIdentidade.dadosPrivados,
        termosAceitosVersao: dadosIdentidade.termosAceitosVersao,
        termosAceitosEm: dadosIdentidade.termosAceitosEm,
      );
    } else {
      // Conta antiga existente: verifica se possui nome de usuário cadastrado
      final conta = authProvider.contaAtual;
      if (conta != null && conta.nomeDeUsuario.trim().isEmpty) {
        final username = await CadastrarNomeUsuarioDialog.mostrar(
          context,
          cpf: authProvider.cpf,
          nomeOuApelidoAtual: conta.apelido.isNotEmpty ? conta.apelido : conta.nome,
          theme: theme,
        );
        if (username == null || username.trim().isEmpty || !context.mounted) {
          return;
        }
        await authProvider.atualizarNomeDeUsuario(username.trim());
      }
    }

    await authProvider.salvarUltimoCpf(authProvider.cpf);
    await BiometriaAuthService.vincularCpfComBiometria(authProvider.cpf);
    await notificacoesProvider.carregarParaCpf(authProvider.cpf);
    await pdvProvider.entrarComCpf(authProvider.cpf);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ContasUsuarioView(),
      ),
      (route) => false,
    );
  }

  Future<void> _entrarComoVisitante(BuildContext context) async {
    context.read<AuthProvider>().entrarComoVisitante();
    await context.read<PdvProvider>().entrarComoVisitante();
    if (!context.mounted) return;
    context.read<NotificacoesProvider>().limpar();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final canSubmit = authProvider.isValid && !authProvider.carregando;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                disabledBackgroundColor:
                    theme.buttonColor.withValues(alpha: 0.3),
                disabledForegroundColor:
                    theme.buttonTextColor.withValues(alpha: 0.4),
                elevation: 0,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(
                  color: canSubmit
                      ? theme.borderColor
                      : theme.borderColor.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: canSubmit
                  ? () => GuardaAcaoUi.executarUnico('auth_entrar', () => _entrar(context))
                  : null,
              child: authProvider.carregando
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.buttonTextColor,
                      ),
                    )
                  : Text(
                      'Entrar',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        color: canSubmit
                            ? theme.buttonTextColor
                            : theme.buttonTextColor.withValues(alpha: 0.4),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                elevation: 0,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(color: theme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => GuardaAcaoUi.executarUnico(
                'auth_visitante',
                () => _entrarComoVisitante(context),
              ),
              child: Text(
                'Entrar como visitante',
                style: theme.getTextStyle(
                  fontSize: 16,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
            if (BiometriaAuthService.ehCelular)
              FutureBuilder<String?>(
                future: _cpfBiometriaFuture,
                builder: (context, snap) {
                  final cpfSalvo = snap.data;
                  if (cpfSalvo == null || cpfSalvo.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: TextButton.icon(
                      onPressed: () => GuardaAcaoUi.executarUnico(
                        'auth_biometria',
                        () => BiometriaAuthService.tentarLoginAutomatico(context),
                      ),
                      icon: Icon(
                        Icons.fingerprint_rounded,
                        color: theme.textColor,
                        size: 22,
                      ),
                      label: Text(
                        'Entrar com biometria',
                        style: theme.getTextStyle(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}