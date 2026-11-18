import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

/// Helper para gerenciar e trocar a foto exclusiva do Perfil Público do usuário.
class PerfilFotoPublicaHelper {
  PerfilFotoPublicaHelper._();

  static Future<void> gerenciar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous conta,
    required void Function(String? caminhoSalvo) onAtualizada,
  }) async {
    if (conta.fotoPublica.trim().isNotEmpty) {
      await OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto do Perfil Público',
        onEscolherNova: () => _escolherNovaFoto(
          context,
          conta: conta,
          onAtualizada: onAtualizada,
        ),
        onRemover: () async {
          final auth = context.read<AuthProvider>();
          await auth.atualizarFotoPublica('');
          final cpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
          if (cpfLimpo.length == 11 && conta.foto.isNotEmpty) {
            ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, conta.foto);
          }
          onAtualizada(null);
        },
      );
      return;
    }

    await _escolherNovaFoto(
      context,
      conta: conta,
      onAtualizada: onAtualizada,
    );
  }

  static Future<void> _escolherNovaFoto(
    BuildContext context, {
    required UsuarioNous conta,
    required void Function(String? caminhoSalvo) onAtualizada,
  }) async {
    final auth = context.read<AuthProvider>();
    String? caminhoSelecionado;
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 75,
      );
      caminhoSelecionado = foto?.path;
    } catch (_) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        const grupo = XTypeGroup(
          label: 'Imagens',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
        );
        final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
        caminhoSelecionado = arquivo?.path;
      }
    }

    if (caminhoSelecionado == null || caminhoSelecionado.isEmpty) return;
    final salvo = await ImagemService.salvarImagemLocal(caminhoSelecionado);
    if (salvo == null || salvo.isEmpty) return;

    await auth.atualizarFotoPublica(salvo);
    final cpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.length == 11) {
      ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, salvo);
    }
    onAtualizada(salvo);
  }
}
