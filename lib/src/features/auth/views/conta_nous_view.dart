import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/auth/views/widgets/adicionar_email_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/backup_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

/// Tela dedicada para gerenciamento da Conta Nous Soberana do Cidadão.
/// Reúne Identidade, E-mails associados, Backup dos dados e Exclusão de Conta.
class ContaNousView extends StatelessWidget {
  const ContaNousView({super.key});

  Future<void> _abrirAdicionarEmail(BuildContext context) async {
    await AdicionarEmailDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
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
            'Tem certeza que deseja remover o e-mail "$email" desta conta?',
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
                style: theme.getTextStyle(color: theme.dangerColor),
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

  Future<void> _editarNomeDeUsuario(BuildContext context, UsuarioNous conta) async {
    final theme = ThemeController.currentTheme.value;
    final controller = TextEditingController(text: conta.nomeDeUsuario);

    final novoUsername = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Nome de Usuário (@)',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identificador único do seu perfil na rede soberana (não é o apelido). Permite que outros membros encontrem e sigam seu perfil.',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: theme.getTextStyle(fontSize: 14),
              cursorColor: theme.textColor,
              decoration: InputDecoration(
                prefixText: '@',
                prefixStyle: theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
                hintText: 'nome.usuario',
                hintStyle: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.secondaryTextColor.withValues(alpha: 0.6),
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.textColor),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () {
              final texto = controller.text
                  .trim()
                  .toLowerCase()
                  .replaceAll('@', '')
                  .replaceAll(' ', '_');
              Navigator.of(ctx).pop(texto);
            },
            child: Text(
              'Salvar',
              style: theme.getTextStyle(
                color: theme.buttonTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (novoUsername != null && context.mounted) {
      await context.read<AuthProvider>().atualizarNomeDeUsuario(novoUsername);
    }
  }

  Widget _itemPrivacidade({
    required BuildContext context,
    required AppTheme theme,
    required String titulo,
    required String subtitulo,
    required bool privado,
    required List<String> chaves,
    required UsuarioNous? conta,
    required VoidCallback onAlternar,
  }) {
    final auth = context.read<AuthProvider>();
    final cpfsAutorizados = <String>{};
    if (conta != null) {
      for (final chave in chaves) {
        cpfsAutorizados.addAll(conta.obterCpfsAutorizadosPara(chave));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        if (privado) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      privado
                          ? 'Privado (exige aprovação prévia para visualização)'
                          : subtitulo,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ThemedSwitch(
                theme: theme,
                value: !privado,
                onChanged: (_) => onAlternar(),
              ),
            ],
          ),
          if (cpfsAutorizados.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Usuários com acesso concedido (${cpfsAutorizados.length}):',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cpfsAutorizados.map((cpfAlvo) {
                      final usuarioAlvo = auth.buscarContaPorCpf(cpfAlvo);
                      final nomeAlvo = usuarioAlvo?.nomeExibicao.isNotEmpty == true
                          ? usuarioAlvo!.nomeExibicao
                          : _formatarCpf(cpfAlvo);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nomeAlvo,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () async {
                                for (final chave in chaves) {
                                  await auth.revogarAcessoDado(chave, cpfAlvo);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: theme.dangerColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
            'Excluir Conta Nous Definitivamente',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.dangerColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir esta Conta Nous definitivamente? Isso também '
            'apaga todas as lojas criadas por este CPF neste dispositivo. '
            'Esta ação não pode ser desfeita.',
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
                'Excluir Definitivamente',
                style: theme.getTextStyle(
                  color: theme.dangerColor,
                  fontWeight: FontWeight.bold,
                ),
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
      await context.read<AuthProvider>().excluirConta(cpf);

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
    final auth = context.watch<AuthProvider>();
    final conta = auth.contaAtual;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final fotoResolvida =
            conta != null ? ImagemService.resolverCaminhoExistente(conta.foto) : null;
        final temFoto = fotoResolvida != null;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Conta Nous',
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloco 1: Identidade do Usuário
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.borderColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: temFoto
                                        ? Image.file(
                                            File(fotoResolvida),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Icon(
                                              Icons.person,
                                              size: 32,
                                              color: theme.textColor,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 32,
                                            color: theme.textColor,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final privado = conta?.dadoEstaPrivado('nome') ?? false;
                                          final revelado = auth.dadoEstaReveladoParaDono('nome');
                                          final nomeTexto = privado
                                              ? (revelado
                                                  ? (conta?.nome.isNotEmpty == true ? conta!.nome : 'Usuário Nous')
                                                  : (conta?.apelido.isNotEmpty == true ? conta!.apelido : '••••••••'))
                                              : (conta?.nome.isNotEmpty == true ? conta!.nome : 'Usuário Nous');

                                          return Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  nomeTexto,
                                                  style: theme.getTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                              if (privado) ...[
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () => auth.alternarRevelacaoParaDono('nome'),
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Icon(
                                                      revelado
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined,
                                                      size: 16,
                                                      color: theme.secondaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 3),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: conta != null
                                            ? () => _editarNomeDeUsuario(context, conta)
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                (conta?.usernameExibicao.isNotEmpty == true)
                                                    ? conta!.usernameExibicao
                                                    : '@usuario',
                                                style: theme.getTextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.buttonColor,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 13,
                                                color: theme.buttonColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (conta?.apelido.isNotEmpty == true) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Apelido: ${conta!.apelido}',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            color: theme.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Builder(
                                        builder: (context) {
                                          final privado = conta?.dadoEstaPrivado('cpf') ?? false;
                                          final revelado = auth.dadoEstaReveladoParaDono('cpf');
                                          final cpfTexto = privado
                                              ? (revelado
                                                  ? _formatarCpf(conta?.cpf ?? auth.cpf)
                                                  : '•••.•••.•••-••')
                                              : _formatarCpf(conta?.cpf ?? auth.cpf);

                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                cpfTexto,
                                                style: theme.getTextStyle(
                                                  fontSize: 12,
                                                  color: theme.secondaryTextColor,
                                                ),
                                              ),
                                              if (privado) ...[
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () => auth.alternarRevelacaoParaDono('cpf'),
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Icon(
                                                      revelado
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined,
                                                      size: 14,
                                                      color: theme.secondaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.borderColor.withValues(alpha: 0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  if (conta != null) {
                                    FichaUsuarioDialog.mostrar(
                                      context,
                                      theme: theme,
                                      usuario: conta,
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.badge_outlined,
                                  size: 16,
                                  color: theme.textColor,
                                ),
                                label: Text(
                                  'Ver / Editar Identidade Completa',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco: Privacidade e Transparência dos Dados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Privacidade e Transparência',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Defina quais dados você permite que fiquem visíveis para outros usuários nas lojas e no mapa. Se um dado for mantido privado, outros membros verão um ícone de cadeado e precisarão solicitar sua aprovação por notificação.',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Nome Próprio / Nome Civil',
                              subtitulo: 'Exibir seu nome civil completo (se privado, exibe apenas seu apelido)',
                              privado: conta?.dadoEstaPrivado('nome') ?? false,
                              chaves: const ['nome'],
                              conta: conta,
                              onAlternar: () => auth.alternarPrivacidadeDado('nome'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'CPF do Cidadão',
                              subtitulo: 'Exibir seu CPF publicamente em lojas',
                              privado: conta?.dadoEstaPrivado('cpf') ?? false,
                              chaves: const ['cpf'],
                              conta: conta,
                              onAlternar: () => auth.alternarPrivacidadeDado('cpf'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Data de Nascimento',
                              subtitulo: 'Exibir sua data de nascimento',
                              privado: conta?.dadoEstaPrivado('dataNascimento') ?? false,
                              chaves: const ['dataNascimento'],
                              conta: conta,
                              onAlternar: () =>
                                  auth.alternarPrivacidadeDado('dataNascimento'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Filiação (Mãe e Pai)',
                              subtitulo: 'Exibir nomes dos pais na identidade',
                              privado: (conta?.dadoEstaPrivado('nomeMae') ?? false) ||
                                  (conta?.dadoEstaPrivado('nomePai') ?? false),
                              chaves: const ['nomeMae', 'nomePai'],
                              conta: conta,
                              onAlternar: () {
                                auth.alternarPrivacidadeDado('nomeMae');
                                auth.alternarPrivacidadeDado('nomePai');
                              },
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Local de Nascimento',
                              subtitulo: 'Exibir cidade e estado de origem',
                              privado: conta?.dadoEstaPrivado('localNascimento') ?? false,
                              chaves: const ['localNascimento'],
                              conta: conta,
                              onAlternar: () =>
                                  auth.alternarPrivacidadeDado('localNascimento'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Tipo Sanguíneo',
                              subtitulo: 'Exibir seu tipo sanguíneo',
                              privado: conta?.dadoEstaPrivado('tipoSanguineo') ?? false,
                              chaves: const ['tipoSanguineo'],
                              conta: conta,
                              onAlternar: () =>
                                  auth.alternarPrivacidadeDado('tipoSanguineo'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Estado Civil',
                              subtitulo: 'Exibir estado civil',
                              privado: conta?.dadoEstaPrivado('estadoCivil') ?? false,
                              chaves: const ['estadoCivil'],
                              conta: conta,
                              onAlternar: () =>
                                  auth.alternarPrivacidadeDado('estadoCivil'),
                            ),
                            _itemPrivacidade(
                              context: context,
                              theme: theme,
                              titulo: 'Telefone e Endereço',
                              subtitulo: 'Exibir contato telefônico e localização',
                              privado: (conta?.dadoEstaPrivado('telefone') ?? false) ||
                                  (conta?.dadoEstaPrivado('endereco') ?? false),
                              chaves: const ['telefone', 'endereco'],
                              conta: conta,
                              onAlternar: () {
                                auth.alternarPrivacidadeDado('telefone');
                                auth.alternarPrivacidadeDado('endereco');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco 2: E-mails Associados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alternate_email_rounded,
                                      size: 18,
                                      color: theme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'E-mails Associados',
                                      style: theme.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _abrirAdicionarEmail(context),
                                  icon: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: theme.textColor,
                                  ),
                                  label: Text(
                                    'Adicionar',
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (conta == null || conta.emails.isEmpty)
                              EstadoVazioContainer(
                                theme: theme,
                                mensagem: 'Nenhum e-mail associado a esta conta.',
                              )
                            else
                              Column(
                                children: conta.emails.map((email) {
                                  final ehAtivo = auth.emailAtivo == email;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ehAtivo
                                          ? theme.borderColor.withValues(alpha: 0.2)
                                          : theme.backgroundColor.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: ehAtivo
                                            ? theme.textColor
                                            : theme.borderColor.withValues(alpha: 0.5),
                                        width: ehAtivo ? 1.3 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ehAtivo
                                              ? Icons.check_circle_rounded
                                              : Icons.mail_outline_rounded,
                                          size: 16,
                                          color: ehAtivo
                                              ? theme.textColor
                                              : theme.secondaryTextColor,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                email,
                                                style: theme.getTextStyle(
                                                  fontSize: 13,
                                                  fontWeight: ehAtivo
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              if (ehAtivo)
                                                Text(
                                                  'E-mail ativo da sessão',
                                                  style: theme.getTextStyle(
                                                    fontSize: 10,
                                                    color: theme.secondaryTextColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (!ehAtivo)
                                          TextButton(
                                            onPressed: () => auth.definirEmailAtivo(email),
                                            child: Text(
                                              'Usar',
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: theme.dangerColor,
                                          ),
                                          onPressed: () => _removerEmail(context, email),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco 3: Backup Soberano dos Dados
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Backup dos Dados',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gere cópias de segurança de todas as suas lojas, caixas, históricos e cadastros vinculados a este CPF em um único arquivo soberano.',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.borderColor.withValues(alpha: 0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  BackupDialog.mostrar(context, theme: theme);
                                },
                                icon: Icon(
                                  Icons.save_alt_rounded,
                                  size: 16,
                                  color: theme.textColor,
                                ),
                                label: Text(
                                  'Gerenciar Backup / Restaurar Dados',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco 4: Zona de Perigo (Excluir Conta Nous)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.dangerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dangerColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: theme.dangerColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Excluir Conta Nous',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.dangerColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Apaga permanentemente os dados cadastrais deste CPF e de suas lojas locais deste computador. Esta ação não poderá ser desfeita.',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.dangerColor,
                                  side: BorderSide(color: theme.dangerColor),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _excluirConta(context),
                                icon: Icon(
                                  Icons.delete_forever_rounded,
                                  size: 16,
                                  color: theme.dangerColor,
                                ),
                                label: Text(
                                  'Excluir Conta Nous Definitivamente',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.dangerColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
