import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class CardContaUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous? conta;

  const CardContaUsuario({
    super.key,
    required this.theme,
    required this.conta,
  });

  Future<void> _aoClicarFoto(BuildContext context) async {
    final c = conta;
    if (c == null) return;
    final temFoto = c.foto.isNotEmpty && ImagemService.existe(c.foto);

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
    final fotoResolvida =
        c != null ? ImagemService.resolverCaminhoExistente(c.foto) : null;
    final temFoto = fotoResolvida != null;

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
                          File(fotoResolvida),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
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
