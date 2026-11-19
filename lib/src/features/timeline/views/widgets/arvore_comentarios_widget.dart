import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

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

  String _formatarDataHora(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    if (l.year != DateTime.now().year) {
      return '$d/$m/${l.year} • $h:$min';
    }
    return '$d/$m • $h:$min';
  }

  List<InlineSpan> _montarSpansTextoComHashtags(String texto) {
    final regex = RegExp(r'#[\p{L}\p{N}_]+', unicode: true);
    final spans = <InlineSpan>[];
    int ultimoIndice = 0;
    const corHashtag = Color(0xFF1D9BF0);

    for (final match in regex.allMatches(texto)) {
      if (match.start > ultimoIndice) {
        spans.add(
          TextSpan(
            text: texto.substring(ultimoIndice, match.start),
            style: theme.getTextStyle(
              fontSize: 12.5,
              color: theme.textColor,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: corHashtag,
          ),
        ),
      );
      ultimoIndice = match.end;
    }

    if (ultimoIndice < texto.length) {
      spans.add(
        TextSpan(
          text: texto.substring(ultimoIndice),
          style: theme.getTextStyle(
            fontSize: 12.5,
            color: theme.textColor,
          ),
        ),
      );
    }

    return spans;
  }

  Future<void> _mostrarMenuAcoesComentario(
    BuildContext context,
    Offset posicaoGlobal,
  ) async {
    final c = comentario;
    final ehMeuComentario =
        meuCpf.isNotEmpty &&
        c.autorCpf.replaceAll(RegExp(r'\D'), '') == meuCpf;
    if (!ehAutorPublicacao && !ehMeuComentario) return;

    final box = Overlay.maybeOf(context)?.context.findRenderObject()
        as RenderBox?;
    final tamanhoTela = box?.size ?? MediaQuery.sizeOf(context);
    final position = RelativeRect.fromLTRB(
      posicaoGlobal.dx - 70,
      (posicaoGlobal.dy - 92).clamp(8.0, tamanhoTela.height - 96),
      tamanhoTela.width - posicaoGlobal.dx - 70,
      tamanhoTela.height - posicaoGlobal.dy,
    );

    final acao = await showMenu<String>(
      context: context,
      color: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      position: position,
      items: [
        if (ehAutorPublicacao)
          PopupMenuItem<String>(
            value: 'fixar',
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.fixado ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  size: 16,
                  color: theme.textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  c.fixado ? 'Desafixar' : 'Fixar',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        if (ehAutorPublicacao || ehMeuComentario)
          PopupMenuItem<String>(
            value: 'excluir',
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: theme.dangerColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Excluir',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.dangerColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (acao == 'fixar') {
      onAlternarFixar(c);
    } else if (acao == 'excluir') {
      onExcluir(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = comentario;
    final filhos = _filhosDeComentario(c.id);
    final nomeExibir = c.autorNome.isNotEmpty ? c.autorNome : c.autorCpf;

    return Padding(
      padding: EdgeInsets.only(
        left: (nivel * 22.0).clamp(0.0, 66.0),
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (itemCtx) => GestureDetector(
              onLongPressStart: (d) =>
                  _mostrarMenuAcoesComentario(itemCtx, d.globalPosition),
              onSecondaryTapUp: (d) =>
                  _mostrarMenuAcoesComentario(itemCtx, d.globalPosition),
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.fixado
                  ? theme.buttonColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: c.fixado
                  ? Border.all(color: theme.buttonColor.withValues(alpha: 0.6))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarComStoryWidget(
                  theme: theme,
                  cpf: c.autorCpf,
                  nome: nomeExibir,
                  foto: c.autorFoto,
                  radius: nivel > 0 ? 12 : 15,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$nomeExibir ',
                                    style: theme.getTextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  ..._montarSpansTextoComHashtags(c.texto),
                                ],
                              ),
                            ),
                          ),
                          if (c.fixado)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 13,
                                color: theme.buttonColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatarDataHora(c.criadaEm),
                            style: theme.getTextStyle(
                              fontSize: 10.5,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => onResponder(c),
                            child: Text(
                              'Responder',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
