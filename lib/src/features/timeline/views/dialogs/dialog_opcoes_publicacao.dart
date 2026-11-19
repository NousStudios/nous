import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Diálogos auxiliares da publicação: menu de opções (Editar/Excluir/Baixar/Denunciar)
/// e lista de quem deu Like ou Deslike.
class DialogOpcoesPublicacao {
  DialogOpcoesPublicacao._();

  static Future<String?> mostrarMenuOpcoes(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required bool ehAutor,
    required bool podeDenunciar,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Opções da Publicação',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                if (ehAutor) ...[
                  ListTile(
                    leading: Icon(
                      publicacao.fixada
                          ? Icons.push_pin_outlined
                          : Icons.push_pin_rounded,
                      color: theme.textColor,
                    ),
                    title: Text(
                      publicacao.fixada ? 'Desafixar do topo' : 'Fixar no topo',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('fixar'),
                  ),
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: theme.textColor),
                    title: Text(
                      'Editar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('editar'),
                  ),
                  ListTile(
                    leading: Icon(
                      publicacao.arquivada
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      color: theme.textColor,
                    ),
                    title: Text(
                      publicacao.arquivada
                          ? 'Desarquivar publicação'
                          : 'Arquivar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('arquivar'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.dangerColor,
                    ),
                    title: Text(
                      'Excluir publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.dangerColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('excluir'),
                  ),
                ],
                if (publicacao.midias.isNotEmpty &&
                    (publicacao.permitirDownload || ehAutor))
                  ListTile(
                    leading: Icon(
                      Icons.download_rounded,
                      color: theme.textColor,
                    ),
                    title: Text(
                      'Baixar arquivo/mídia',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('baixar'),
                  ),
                if (podeDenunciar && !ehAutor)
                  ListTile(
                    leading: Icon(
                      Icons.shield_outlined,
                      color: theme.dangerColor,
                    ),
                    title: Text(
                      'Denunciar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.dangerColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('denunciar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> mostrarListaReacoes(
    BuildContext context, {
    required AppTheme theme,
    required List<ReacaoSocial> reacoes,
    required TipoReacaoSocial tipo,
  }) {
    final filtradas = reacoes.where((r) => r.tipo == tipo).toList();
    final titulo = tipo == TipoReacaoSocial.like
        ? 'Quem deu Like (${filtradas.length})'
        : 'Quem deu Deslike (${filtradas.length})';

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (filtradas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma reação registrada ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtradas.length,
                    itemBuilder: (_, i) {
                      final r = filtradas[i];
                      return ListTile(
                        leading: Icon(
                          tipo == TipoReacaoSocial.like
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_down_alt_rounded,
                          color: theme.buttonColor,
                          size: 18,
                        ),
                        title: Text(
                          r.usuarioNome.isNotEmpty
                              ? r.usuarioNome
                              : r.usuarioCpf,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
