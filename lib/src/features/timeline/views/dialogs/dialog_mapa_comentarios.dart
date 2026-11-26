import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/container_hold_hover_comentario.dart';

/// Visualização em Organograma Top-Down (Post Raiz no topo -> Comentários no
/// 2º nível -> Respostas no 3º nível -> Sub-respostas no 4º nível, etc.),
/// arrastável livremente em todas as direções via [InteractiveViewer].
class DialogMapaComentarios extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final List<ComentarioSocial> comentarios;
  final bool ehAutorPublicacao;
  final String meuCpfLimpo;
  final ValueChanged<ComentarioSocial> onResponder;
  final ValueChanged<ComentarioSocial> onAlternarFixar;
  final ValueChanged<ComentarioSocial> onExcluir;
  final VoidCallback? onReacaoAlterada;

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
    this.onReacaoAlterada,
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
    VoidCallback? onReacaoAlterada,
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
        onReacaoAlterada: onReacaoAlterada,
      ),
    );
  }

  @override
  State<DialogMapaComentarios> createState() => _DialogMapaComentariosState();
}

class _DialogMapaComentariosState extends State<DialogMapaComentarios> {
  late List<ComentarioSocial> _comentariosLocais;

  AppTheme get theme => widget.theme;
  PublicacaoSocial get publicacao => widget.publicacao;
  bool get ehAutorPublicacao => widget.ehAutorPublicacao;
  String get meuCpfLimpo => widget.meuCpfLimpo;
  ValueChanged<ComentarioSocial> get onResponder => widget.onResponder;
  ValueChanged<ComentarioSocial> get onAlternarFixar => widget.onAlternarFixar;
  ValueChanged<ComentarioSocial> get onExcluir => widget.onExcluir;

  @override
  void initState() {
    super.initState();
    _comentariosLocais = List<ComentarioSocial>.from(widget.comentarios);
  }

  Future<void> _reagir(ComentarioSocial c, bool ehLike) async {
    if (meuCpfLimpo.isEmpty) return;
    final atualizado = await TimelineService.alternarReacaoComentario(
      comentario: c,
      usuarioCpf: meuCpfLimpo,
      ehLike: ehLike,
    );
    if (!mounted) return;
    setState(() {
      final idx = _comentariosLocais.indexWhere((x) => x.id == atualizado.id);
      if (idx != -1) {
        _comentariosLocais[idx] = atualizado;
      }
    });
    widget.onReacaoAlterada?.call();
  }

  List<ComentarioSocial> _filhosDe(String parentId) {
    final lista = _comentariosLocais
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
    return '$d/$m $h:$min';
  }

  Widget _buildCardComentario(
    BuildContext context,
    ComentarioSocial c,
  ) {
    final podeAgir = ehAutorPublicacao ||
        (meuCpfLimpo.isNotEmpty &&
            c.autorCpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo);

    return Builder(
      builder: (cardCtx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ContainerHoldHoverComentario(
          theme: theme,
          habilitado: podeAgir,
          borderRadius: BorderRadius.circular(12),
          onAbrirMenu: (pos) =>
              ContainerHoldHoverComentario.mostrarMenuAcoesComentario(
            cardCtx,
            theme: theme,
            comentario: c,
            ehAutorPublicacao: ehAutorPublicacao,
            meuCpfLimpo: meuCpfLimpo,
            posicaoGlobal: pos,
            onAlternarFixar: (alvo) {
              Navigator.of(context).pop();
              onAlternarFixar(alvo);
            },
            onExcluir: (alvo) {
              setState(() {
                _comentariosLocais = _comentariosLocais
                    .where((item) => item.id != alvo.id)
                    .toList();
              });
              onExcluir(alvo);
            },
          ),
          child: Container(
            width: 210,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.fixado
                  ? theme.textColor.withValues(alpha: 0.09)
                  : theme.backgroundColor.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(12),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarComStoryWidget(
                  theme: theme,
                  cpf: c.autorCpf,
                  nome: c.autorNome,
                  foto: c.autorFoto,
                  radius: 13,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.fixado) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 12,
                              color: theme.textColor,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Flexible(
                            child: Text(
                              c.autorNome.isNotEmpty
                                  ? c.autorNome
                                  : 'Cidadão Nous',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatarDataHora(c.criadaEm),
                        style: theme.getTextStyle(
                          fontSize: 9.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.texto,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (_) {
                    final deuLike = meuCpfLimpo.isNotEmpty &&
                        c.curtidasCpfs.any(
                          (cpf) => cpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo,
                        );
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: meuCpfLimpo.isNotEmpty
                          ? () => _reagir(c, true)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              deuLike
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.thumb_up_off_alt_rounded,
                              size: 13,
                              color: deuLike
                                  ? theme.textColor
                                  : theme.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${c.curtidasCpfs.length}',
                              style: theme.getTextStyle(
                                fontSize: 10.5,
                                fontWeight: deuLike
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: deuLike
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Builder(
                  builder: (_) {
                    final deuDeslike = meuCpfLimpo.isNotEmpty &&
                        c.descurtidasCpfs.any(
                          (cpf) => cpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo,
                        );
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: meuCpfLimpo.isNotEmpty
                          ? () => _reagir(c, false)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              deuDeslike
                                  ? Icons.thumb_down_alt_rounded
                                  : Icons.thumb_down_off_alt_rounded,
                              size: 13,
                              color: deuDeslike
                                  ? theme.dangerColor
                                  : theme.secondaryTextColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${c.descurtidasCpfs.length}',
                              style: theme.getTextStyle(
                                fontSize: 10.5,
                                fontWeight: deuDeslike
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: deuDeslike
                                    ? theme.dangerColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).pop();
                    onResponder(c);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Responder',
                      style: theme.getTextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
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

  Widget _buildSubArvoreTopDown(
    BuildContext context,
    ComentarioSocial c,
  ) {
    final filhos = _filhosDe(c.id);
    final card = _buildCardComentario(context, c);
    if (filhos.isEmpty) return card;

    final corConector = theme.borderColor.withValues(alpha: 0.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        card,
        Container(
          width: 1.5,
          height: 18,
          color: corConector,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < filhos.length; i++)
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 18),
                      painter: _ChaveTopDownPainter(
                        cor: corConector,
                        ehPrimeiro: i == 0,
                        ehUltimo: i == filhos.length - 1,
                      ),
                    ),
                    _buildSubArvoreTopDown(context, filhos[i]),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrganogramaTopDown(
    BuildContext context,
    List<ComentarioSocial> raizes,
  ) {
    final corConector = theme.borderColor.withValues(alpha: 0.7);
    final cardPublicacao = Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarComStoryWidget(
                theme: theme,
                cpf: publicacao.autorCpf,
                nome: publicacao.autorNome,
                foto: publicacao.autorFoto,
                radius: 13,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  publicacao.autorNome.isNotEmpty
                      ? publicacao.autorNome
                      : 'Publicação',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            publicacao.texto.isNotEmpty
                ? publicacao.texto
                : 'Publicação sem legenda',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 11.5,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        cardPublicacao,
        Container(
          width: 1.5,
          height: 18,
          color: corConector,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < raizes.length; i++)
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 18),
                      painter: _ChaveTopDownPainter(
                        cor: corConector,
                        ehPrimeiro: i == 0,
                        ehUltimo: i == raizes.length - 1,
                      ),
                    ),
                    _buildSubArvoreTopDown(context, raizes[i]),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final idsExistentes = _comentariosLocais.map((c) => c.id).toSet();
    final raizes = _comentariosLocais
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
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 880,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mapa da Conversa',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, color: theme.secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: theme.borderColor.withValues(alpha: 0.25)),
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              constrained: false,
                              boundaryMargin: const EdgeInsets.all(140),
                              minScale: 0.40,
                              maxScale: 2.0,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      12,
                                      20,
                                      24,
                                    ),
                                    child: _buildOrganogramaTopDown(
                                      context,
                                      raizes,
                                    ),
                                  ),
                                ),
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

/// Desenha o conector horizontal e a haste vertical descendo para cada filho
/// em organograma top-down (post no topo, níveis abaixo).
class _ChaveTopDownPainter extends CustomPainter {
  final Color cor;
  final bool ehPrimeiro;
  final bool ehUltimo;

  const _ChaveTopDownPainter({
    required this.cor,
    required this.ehPrimeiro,
    required this.ehUltimo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;

    // Haste vertical descendo até o card filho
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);

    // Barra horizontal no topo conectando aos irmãos
    if (!ehPrimeiro || !ehUltimo) {
      final leftX = ehPrimeiro ? midX : 0.0;
      final rightX = ehUltimo ? midX : size.width;
      canvas.drawLine(Offset(leftX, 0), Offset(rightX, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChaveTopDownPainter oldDelegate) {
    return oldDelegate.cor != cor ||
        oldDelegate.ehPrimeiro != ehPrimeiro ||
        oldDelegate.ehUltimo != ehUltimo;
  }
}
