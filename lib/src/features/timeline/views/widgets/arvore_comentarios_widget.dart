import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';

/// Renderiza um comentário e toda a sua árvore recursiva de sub-respostas,
/// com suporte a múltiplos comentários fixados, resposta direta e exclusão.
class ArvoreComentariosWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ComentarioSocial> todosComentarios;
  final ComentarioSocial comentario;
  final int nivel;
  final bool ehAutorPublicacao;
  final String meuCpf;
  final ValueChanged<ComentarioSocial> onResponder;
  final ValueChanged<ComentarioSocial> onAlternarFixar;
  final ValueChanged<ComentarioSocial> onExcluir;

  const ArvoreComentariosWidget({
    super.key,
    required this.theme,
    required this.todosComentarios,
    required this.comentario,
    this.nivel = 0,
    required this.ehAutorPublicacao,
    required this.meuCpf,
    required this.onResponder,
    required this.onAlternarFixar,
    required this.onExcluir,
  });

  List<ComentarioSocial> _filhosDeComentario(String parentId) {
    final lista = todosComentarios
        .where((c) => !c.excluido && c.respostaDeId == parentId)
        .toList();
    lista.sort((a, b) {
      if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
      return a.criadaEm.compareTo(b.criadaEm);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final c = comentario;
    final filhos = _filhosDeComentario(c.id);
    final ehMeuComentario =
        meuCpf.isNotEmpty &&
        c.autorCpf.replaceAll(RegExp(r'\D'), '') == meuCpf;

    return Padding(
      padding: EdgeInsets.only(
        left: (nivel * 18.0).clamp(0.0, 72.0),
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.fixado
                  ? theme.buttonColor.withValues(alpha: 0.12)
                  : theme.cardBackgroundColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.fixado
                    ? theme.buttonColor
                    : theme.borderColor.withValues(alpha: 0.45),
                width: c.fixado ? 1.4 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (nivel > 0) ...[
                      Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 14,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        c.autorNome.isNotEmpty ? c.autorNome : c.autorCpf,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    if (c.fixado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.buttonColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 11,
                              color: theme.buttonColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Fixado',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.buttonColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.texto,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: () => onResponder(c),
                      child: Text(
                        'Responder',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonColor,
                        ),
                      ),
                    ),
                    if (ehAutorPublicacao) ...[
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () => onAlternarFixar(c),
                        child: Text(
                          c.fixado ? 'Desafixar' : 'Fixar',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                    if (ehAutorPublicacao || ehMeuComentario) ...[
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () => onExcluir(c),
                        child: Text(
                          'Excluir',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.dangerColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (filhos.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final f in filhos)
              ArvoreComentariosWidget(
                theme: theme,
                todosComentarios: todosComentarios,
                comentario: f,
                nivel: nivel + 1,
                ehAutorPublicacao: ehAutorPublicacao,
                meuCpf: meuCpf,
                onResponder: onResponder,
                onAlternarFixar: onAlternarFixar,
                onExcluir: onExcluir,
              ),
          ],
        ],
      ),
    );
  }
}
