import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/views/widgets/selo_verificado_widget.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Janela elegante e completa para compartilhamento do Perfil Público Nous.
class CompartilharPerfilDialog {
  CompartilharPerfilDialog._();

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required UsuarioNous conta,
  }) async {
    final nomeUsuario = conta.usernameExibicao.isNotEmpty
        ? conta.usernameExibicao
        : '@${conta.nomeExibicao.toLowerCase().replaceAll(' ', '')}';
    final linkPerfil = 'nous://perfil/${nomeUsuario.replaceAll('@', '')}';
    final textoCompartilhamento =
        '${conta.nomeExibicao} ($nomeUsuario) no Nous\n$linkPerfil';

    await Clipboard.setData(ClipboardData(text: nomeUsuario));
    if (!context.mounted) return;

    final fotoResolvida = ImagemService.resolverCaminhoExistente(
      conta.fotoExibicao,
    );
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 410,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 36),
                    Expanded(
                      child: Text(
                        'Compartilhar Perfil',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cartão de prévia do perfil público
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            theme.borderColor.withValues(alpha: 0.3),
                        backgroundImage:
                            temFoto ? FileImage(File(fotoResolvida)) : null,
                        child: !temFoto
                            ? Icon(
                                Icons.person,
                                size: 34,
                                color: theme.textColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: TextoRolante(
                              texto: conta.nomeExibicao,
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          if (conta.possuiValidacao) ...[
                            const SizedBox(width: 6),
                            SeloVerificadoWidget(
                              usuario: conta,
                              theme: theme,
                              tamanho: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nomeUsuario,
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      if (conta.biografia.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          conta.biografia.trim(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${conta.seguidores.length} seguidores • ${conta.seguindo.length} seguindo',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Text(
                  'Identificador & Link Nous',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          linkPerfil,
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text(
                          'Copiar Tudo',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: textoCompartilhamento),
                          );
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                content: Text(
                                  'Perfil copiado para a área de transferência!',
                                  style: theme.getTextStyle(
                                    color: theme.textColor,
                                  ),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          'Enviar no Chat',
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MensageriaView(
                                modoLoja: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
