import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

/// Bloco de exibição e edição resumida da Identidade Soberana da Conta Nous.
class BlocoIdentidadeContaWidget extends StatelessWidget {
  final UsuarioNous? conta;
  final AppTheme theme;

  const BlocoIdentidadeContaWidget({
    super.key,
    required this.conta,
    required this.theme,
  });

  Future<void> _editarNomeDeUsuario(BuildContext context, UsuarioNous conta) async {
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fotoResolvida =
        conta != null ? ImagemService.resolverCaminhoExistente(conta!.foto) : null;
    final temFoto = fotoResolvida != null;

    return Container(
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
                          ? () => _editarNomeDeUsuario(context, conta!)
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
                    usuario: conta!,
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
    );
  }
}
