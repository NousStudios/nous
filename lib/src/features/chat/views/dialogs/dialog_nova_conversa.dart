import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';

class DialogNovaConversa {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ConversaChat> todosContatosDisponiveis,
    required void Function(ConversaChat contato) onSelecionarContato,
  }) {
    final TextEditingController filtroController = TextEditingController();
    String termo = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final tLimpo = termo.trim().toLowerCase();
            final termoSemArroba = tLimpo.startsWith('@')
                ? tLimpo.substring(1)
                : tLimpo;
            final termoDigitos = tLimpo.replaceAll(RegExp(r'\D'), '');

            final contatosFiltrados = todosContatosDisponiveis.where((c) {
              // O usuário Nous não conversa diretamente com a Loja Nous (chat público na própria loja)
              if (c.ehLoja &&
                  (c.lojaId == 'loja_nous_coletiva' ||
                      c.lojaId == 'nous' ||
                      c.id.contains('nous_coletiva') ||
                      c.titulo.trim().toLowerCase() == 'nous')) {
                return false;
              }
              if (termo.isEmpty) return true;
              if (TextoUtils.contemIgnorandoAcentos(c.titulo, tLimpo) ||
                  TextoUtils.contemIgnorandoAcentos(c.titulo, termoSemArroba)) {
                return true;
              }
              if (TextoUtils.contemIgnorandoAcentos(c.subtitulo, tLimpo) ||
                  TextoUtils.contemIgnorandoAcentos(
                    c.subtitulo,
                    termoSemArroba,
                  )) {
                return true;
              }
              if (c.ehGrupo &&
                  (TextoUtils.contemIgnorandoAcentos(c.nomeGrupo, tLimpo) ||
                      TextoUtils.contemIgnorandoAcentos(
                        c.nomeGrupo,
                        termoSemArroba,
                      ))) {
                return true;
              }
              if (c.identificador.isNotEmpty) {
                if (TextoUtils.contemIgnorandoAcentos(c.identificador, tLimpo)) {
                  return true;
                }
                if (termoDigitos.isNotEmpty) {
                  final idDigitos = c.identificador.replaceAll(
                    RegExp(r'\D'),
                    '',
                  );
                  if (idDigitos.contains(termoDigitos)) return true;
                }
              }
              final cpfNorm = ChatService.normalizarCpf(c.identificador);
              if (termoDigitos.isNotEmpty && cpfNorm.contains(termoDigitos)) {
                return true;
              }
              return false;
            }).toList();

            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nova Conversa',
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 460,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: filtroController,
                      onChanged: (val) {
                        setDialogState(() {
                          termo = val;
                        });
                      },
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Filtrar por nome, @usuario ou CPF...',
                        hintStyle: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: theme.secondaryTextColor,
                        ),
                        suffixIcon: filtroController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: theme.secondaryTextColor,
                                ),
                                onPressed: () {
                                  filtroController.clear();
                                  setDialogState(() {
                                    termo = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: contatosFiltrados.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum contato encontrado.',
                                style: theme.getTextStyle(
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: contatosFiltrados.length,
                              separatorBuilder: (context, index) => Divider(
                                color: theme.borderColor.withValues(alpha: 0.3),
                              ),
                              itemBuilder: (_, index) {
                                final c = contatosFiltrados[index];
                                final tituloItem = (c.titulo.isNotEmpty &&
                                        c.titulo != 'Conversa' &&
                                        c.titulo != 'Nova Conversa' &&
                                        c.titulo != 'Contato' &&
                                        c.titulo != 'Contato Nous')
                                    ? c.titulo
                                    : (c.subtitulo.isNotEmpty &&
                                            c.subtitulo != 'Conversa' &&
                                            c.subtitulo != 'Contato Nous'
                                        ? c.subtitulo
                                        : 'Contato Nous');
                                final subtituloItem = (c.subtitulo.isNotEmpty &&
                                        c.subtitulo != tituloItem &&
                                        c.subtitulo != 'Conversa' &&
                                        c.subtitulo != 'Contato Nous')
                                    ? c.subtitulo
                                    : 'Usuário Nous';

                                return ListTile(
                                  leading: ResolvedorFotoChat.instancia
                                      .buildAvatar(
                                        ctx,
                                        theme: theme,
                                        conversa: c,
                                        raio: 18,
                                      ),
                                  title: Text(
                                    tituloItem,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    subtituloItem,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onSelecionarContato(
                                      c.copyWith(
                                        titulo: tituloItem,
                                        subtitulo: subtituloItem,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Fechar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
