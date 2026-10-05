import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class ContasUsuarioView extends StatefulWidget {
  const ContasUsuarioView({super.key});

  @override
  State<ContasUsuarioView> createState() => _ContasUsuarioViewState();
}

class _ContasUsuarioViewState extends State<ContasUsuarioView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarFotoSeNecessario();
    });
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
            'Tem certeza que deseja excluir este CPF do Nous? Isso também '
            'apaga todas as lojas criadas por ele. Essa ação não pode ser '
            'desfeita.',
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
      final cpf = context.read<AuthProvider>().cpf;
      await context.read<PdvProvider>().excluirDadosDoCpf(cpf);

      if (!context.mounted) return;
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
                      _CardConta(theme: theme, conta: conta),
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
  final UsuarioNous? conta;

  const _CardConta({required this.theme, required this.conta});

  Future<void> _aoClicarFoto(BuildContext context) async {
    final c = conta;
    if (c == null) return;
    final temFoto = c.foto.isNotEmpty && File(c.foto).existsSync();

    if (temFoto) {
      await OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto de Perfil',
        onEscolherNova: () => _selecionarNovaFoto(context),
        onRemover: () => _salvarFoto(context, ''),
      );
    } else {
      await _selecionarNovaFoto(context);
    }
  }

  Future<void> _selecionarNovaFoto(BuildContext context) async {
    const typeGroup = XTypeGroup(
      label: 'Imagens',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null && context.mounted) {
      final salvo = await ImagemService.salvarImagemLocal(file.path);
      if (salvo != null && context.mounted) {
        await _salvarFoto(context, salvo);
      }
    }
  }

  Future<void> _salvarFoto(BuildContext context, String novaFoto) async {
    final auth = context.read<AuthProvider>();
    await auth.atualizarFoto(novaFoto);
    if (!context.mounted) return;
    context
        .read<PdvProvider>()
        .sincronizarFotoUsuarioEmClientes(conta?.cpf ?? '', novaFoto);
  }

  void _aoClicarCard(BuildContext context) {
    final c = conta;
    if (c == null) return;
    FichaUsuarioDialog.mostrar(
      context,
      theme: theme,
      usuario: c,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = conta;
    final nome = c?.nome ?? '';
    final temFoto = c != null && c.foto.isNotEmpty && File(c.foto).existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _aoClicarCard(context),
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _aoClicarFoto(context),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: temFoto
                      ? Image.file(
                          File(c.foto),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 40,
                            color: theme.textColor,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: theme.textColor,
                        ),
                ),
              ),
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