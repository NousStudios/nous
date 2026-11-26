import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';

/// Diálogo centralizado para criar/editar filtros personalizados e atribuir conversas a eles.
class DialogAtribuirFiltroChat {
  DialogAtribuirFiltroChat._();

  static Future<String?> mostrarCriarOuRenomear(
    BuildContext context, {
    required AppTheme theme,
    String? nomeInicial,
  }) {
    final ctrl = TextEditingController(text: nomeInicial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nomeInicial == null
                      ? 'Novo filtro personalizado'
                      : 'Renomear filtro',
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dê um nome ao filtro (ex.: Família, Trabalho, Fornecedores).',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Nome do filtro...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  onSubmitted: (v) {
                    final limpo = v.trim();
                    if (limpo.isNotEmpty) Navigator.pop(ctx, limpo);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.textColor,
                        foregroundColor: theme.backgroundColor,
                      ),
                      onPressed: () {
                        final limpo = ctrl.text.trim();
                        if (limpo.isNotEmpty) Navigator.pop(ctx, limpo);
                      },
                      child: const Text('Salvar'),
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

  static Future<void> mostrarAtribuirConversa(
    BuildContext context, {
    required AppTheme theme,
    required ConversaChat conversa,
    required List<FiltroChatPersonalizado> filtros,
    required Future<void> Function(String filtroId) onAlternarFiltro,
    required Future<FiltroChatPersonalizado?> Function(String nome)
        onCriarEAtribuir,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateLocal) {
          return Dialog(
            backgroundColor: theme.cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Adicionar "${conversa.titulo}" ao filtro',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    if (filtros.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Você ainda não criou nenhum filtro personalizado.',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filtros.map((f) {
                              final marcado =
                                  f.conversasIds.contains(conversa.id);
                              return CheckboxListTile(
                                value: marcado,
                                activeColor: theme.textColor,
                                checkColor: theme.backgroundColor,
                                title: Text(
                                  f.nome,
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    color: theme.textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '${f.conversasIds.length} conversa(s)',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                onChanged: (_) async {
                                  await onAlternarFiltro(f.id);
                                  setStateLocal(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final nome = await mostrarCriarOuRenomear(
                              ctx,
                              theme: theme,
                            );
                            if (nome != null && nome.isNotEmpty) {
                              await onCriarEAtribuir(nome);
                              setStateLocal(() {});
                            }
                          },
                          icon: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: theme.textColor,
                          ),
                          label: Text(
                            'Novo filtro',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Concluir',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
