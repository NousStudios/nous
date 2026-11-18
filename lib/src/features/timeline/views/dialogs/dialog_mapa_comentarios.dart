import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Visualização em Mapa Mental / Árvore de Ramificações dos Comentários e Sub-respostas.
class DialogMapaComentarios extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final List<ComentarioSocial> comentarios;
  final bool ehAutorPublicacao;
  final String meuCpfLimpo;
  final ValueChanged<ComentarioSocial> onResponder;
  final ValueChanged<ComentarioSocial> onAlternarFixar;
  final ValueChanged<ComentarioSocial> onExcluir;

  const DialogMapaComentarios({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.comentarios,
    required this.ehAutorPublicacao,
    required this.meuCpfLimpo,
    required this.onResponder,
    required this.onAlternarFixar,
    required this.onExcluir,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required List<ComentarioSocial> comentarios,
    required bool ehAutorPublicacao,
    required String meuCpfLimpo,
    required ValueChanged<ComentarioSocial> onResponder,
    required ValueChanged<ComentarioSocial> onAlternarFixar,
    required ValueChanged<ComentarioSocial> onExcluir,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogMapaComentarios(
        theme: theme,
        publicacao: publicacao,
        comentarios: comentarios,
        ehAutorPublicacao: ehAutorPublicacao,
        meuCpfLimpo: meuCpfLimpo,
        onResponder: onResponder,
        onAlternarFixar: onAlternarFixar,
        onExcluir: onExcluir,
      ),
    );
  }

  List<ComentarioSocial> _filhosDe(String parentId) {
    final lista = comentarios
        .where((c) => !c.excluido && c.respostaDeId == parentId)
        .toList();
    lista.sort((a, b) {
      if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
      return a.criadaEm.compareTo(b.criadaEm);
    });
    return lista;
  }

  Widget _buildRamoMapa(
    BuildContext context,
    ComentarioSocial c,
    int profundidade,
  ) {
    final filhos = _filhosDe(c.id);
    final ehMeuComentario =
        meuCpfLimpo.isNotEmpty &&
        c.autorCpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo;

    return Padding(
      padding: EdgeInsets.only(left: profundidade == 0 ? 0 : 22, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profundidade > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 6),
                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 16,
                    color: theme.buttonColor,
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.fixado
                        ? theme.buttonColor.withValues(alpha: 0.14)
                        : theme.backgroundColor.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.fixado
                          ? theme.buttonColor
                          : theme.borderColor.withValues(alpha: 0.6),
                      width: c.fixado ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (c.fixado) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: theme.buttonColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              c.autorNome.isNotEmpty
                                  ? c.autorNome
                                  : 'Cidadão Nous',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          Text(
                            'Nível ${profundidade + 1}',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor,
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
                      Wrap(
                        spacing: 12,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              onResponder(c);
                            },
                            child: Text(
                              'Responder',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.buttonColor,
                              ),
                            ),
                          ),
                          if (ehAutorPublicacao)
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                onAlternarFixar(c);
                              },
                              child: Text(
                                c.fixado ? 'Desafixar' : 'Fixar',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                          if (ehAutorPublicacao || ehMeuComentario)
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                onExcluir(c);
                              },
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (filhos.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.buttonColor.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in filhos)
                    _buildRamoMapa(context, f, profundidade + 1),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idsExistentes = comentarios.map((c) => c.id).toSet();
    final raizes = comentarios
        .where(
          (c) =>
              !c.excluido &&
              (c.respostaDeId.isEmpty ||
                  !idsExistentes.contains(c.respostaDeId)),
        )
        .toList()
      ..sort((a, b) {
        if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
        return a.criadaEm.compareTo(b.criadaEm);
      });

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Mapa da Conversa',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Divider(color: theme.borderColor.withValues(alpha: 0.4)),
              // Nó raiz da publicação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.buttonColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 18,
                      color: theme.buttonColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        publicacao.texto.isNotEmpty
                            ? '${publicacao.autorNome}: "${publicacao.texto}"'
                            : 'Publicação de ${publicacao.autorNome}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: raizes.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum comentário nesta conversa ainda.',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final r in raizes)
                              _buildRamoMapa(context, r, 0),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
