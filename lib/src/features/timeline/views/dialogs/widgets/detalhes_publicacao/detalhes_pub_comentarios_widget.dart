import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_mapa_comentarios.dart';
import 'package:nous/src/features/timeline/views/widgets/arvore_comentarios_widget.dart';

class DetalhesPubListaComentariosWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ComentarioSocial> todosComentarios;
  final List<ComentarioSocial> comentariosRaiz;
  final bool ehAutorPublicacao;
  final String meuCpf;
  final ValueChanged<ComentarioSocial> onResponder;
  final VoidCallback onInteracaoAlterada;

  const DetalhesPubListaComentariosWidget({
    super.key,
    required this.theme,
    required this.todosComentarios,
    required this.comentariosRaiz,
    required this.ehAutorPublicacao,
    required this.meuCpf,
    required this.onResponder,
    required this.onInteracaoAlterada,
  });

  @override
  Widget build(BuildContext context) {
    if (comentariosRaiz.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            'Nenhum comentário ainda. Seja o primeiro a comentar!',
            style: theme.getTextStyle(
              fontSize: 12.5,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in comentariosRaiz)
          ArvoreComentariosWidget(
            theme: theme,
            todosComentarios: todosComentarios,
            comentario: c,
            ehAutorPublicacao: ehAutorPublicacao,
            meuCpf: meuCpf,
            onResponder: onResponder,
            onAlternarFixar: (alvo) async {
              await TimelineService.alternarFixarComentario(alvo);
              onInteracaoAlterada();
            },
            onExcluir: (alvo) async {
              await TimelineService.excluirComentario(alvo);
              onInteracaoAlterada();
            },
            onReagirComentario: (alvo, ehLike) async {
              await TimelineService.alternarReacaoComentario(
                comentario: alvo,
                usuarioCpf: meuCpf,
                ehLike: ehLike,
              );
              onInteracaoAlterada();
            },
          ),
      ],
    );
  }
}

class DetalhesPubSecaoComentariosWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ComentarioSocial> todosComentarios;
  final List<ComentarioSocial> comentariosRaiz;
  final bool ehAutorPublicacao;
  final String meuCpf;
  final ValueChanged<ComentarioSocial> onResponder;
  final VoidCallback onInteracaoAlterada;
  final VoidCallback onAbrirMapaComentarios;

  const DetalhesPubSecaoComentariosWidget({
    super.key,
    required this.theme,
    required this.todosComentarios,
    required this.comentariosRaiz,
    required this.ehAutorPublicacao,
    required this.meuCpf,
    required this.onResponder,
    required this.onInteracaoAlterada,
    required this.onAbrirMapaComentarios,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comentários (${todosComentarios.length})',
              style: theme.getTextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            TextButton.icon(
              onPressed: onAbrirMapaComentarios,
              icon: Icon(
                Icons.account_tree_outlined,
                size: 16,
                color: theme.textColor,
              ),
              label: Text(
                'Mapa da Conversa',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DetalhesPubListaComentariosWidget(
          theme: theme,
          todosComentarios: todosComentarios,
          comentariosRaiz: comentariosRaiz,
          ehAutorPublicacao: ehAutorPublicacao,
          meuCpf: meuCpf,
          onResponder: onResponder,
          onInteracaoAlterada: onInteracaoAlterada,
        ),
      ],
    );
  }

  static void abrirMapa(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required List<ComentarioSocial> comentarios,
    required bool ehAutorPublicacao,
    required String meuCpfLimpo,
    required ValueChanged<ComentarioSocial> onResponder,
    required VoidCallback onInteracaoAlterada,
  }) {
    DialogMapaComentarios.mostrar(
      context,
      theme: theme,
      publicacao: publicacao,
      comentarios: comentarios,
      ehAutorPublicacao: ehAutorPublicacao,
      meuCpfLimpo: meuCpfLimpo,
      onResponder: onResponder,
      onAlternarFixar: (c) async {
        await TimelineService.alternarFixarComentario(c);
        onInteracaoAlterada();
      },
      onExcluir: (c) async {
        await TimelineService.excluirComentario(c);
        onInteracaoAlterada();
      },
      onReacaoAlterada: onInteracaoAlterada,
    );
  }
}

class DetalhesPubBarraInputComentarioWidget extends StatefulWidget {
  final AppTheme theme;
  final String publicacaoId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ComentarioSocial? respondendoAComentario;
  final VoidCallback onCancelarResposta;
  final VoidCallback onEnviar;

  const DetalhesPubBarraInputComentarioWidget({
    super.key,
    required this.theme,
    required this.publicacaoId,
    required this.controller,
    required this.focusNode,
    required this.respondendoAComentario,
    required this.onCancelarResposta,
    required this.onEnviar,
  });

  @override
  State<DetalhesPubBarraInputComentarioWidget> createState() =>
      _DetalhesPubBarraInputComentarioWidgetState();
}

class _DetalhesPubBarraInputComentarioWidgetState
    extends State<DetalhesPubBarraInputComentarioWidget> {
  List<UsuarioNous> _todasContasMencao = [];
  String? _termoMencaoAtivo;

  @override
  void initState() {
    super.initState();
    _carregarContasMencao();
  }

  @override
  void didUpdateWidget(covariant DetalhesPubBarraInputComentarioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicacaoId != widget.publicacaoId &&
        _termoMencaoAtivo != null) {
      setState(() => _termoMencaoAtivo = null);
    }
  }

  Future<void> _carregarContasMencao() async {
    final contas = await ContasNousService.carregarTodas();
    if (!mounted) return;
    setState(() => _todasContasMencao = contas);
  }

  void _aoDigitarComentario(String texto) {
    final sel = widget.controller.selection;
    final pos = sel.isValid ? sel.baseOffset : texto.length;
    final ateCursor = pos <= texto.length ? texto.substring(0, pos) : texto;
    final match = RegExp(r'(?:^|\s)@([\p{L}\p{N}_\.]*)$', unicode: true)
        .firstMatch(ateCursor);
    final novoTermo = match?.group(1)?.toLowerCase();
    if (novoTermo != _termoMencaoAtivo) {
      setState(() => _termoMencaoAtivo = novoTermo);
    }
  }

  void _inserirMencao(UsuarioNous usuario) {
    final handle = usuario.usernameExibicao.isNotEmpty
        ? usuario.usernameExibicao
        : '@${usuario.nomeDeUsuario.replaceAll('@', '').trim()}';
    if (handle.length <= 1) return;

    final texto = widget.controller.text;
    final sel = widget.controller.selection;
    final pos = sel.isValid ? sel.baseOffset : texto.length;
    final ateCursor = pos <= texto.length ? texto.substring(0, pos) : texto;
    final aposCursor = pos <= texto.length ? texto.substring(pos) : '';
    final match = RegExp(r'@([\p{L}\p{N}_\.]*)$', unicode: true)
        .firstMatch(ateCursor);
    if (match == null) return;

    final inicioArroba = match.start;
    final novoTexto =
        '${ateCursor.substring(0, inicioArroba)}$handle $aposCursor';
    final novaPos = inicioArroba + handle.length + 1;
    widget.controller.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(offset: novaPos),
    );
    setState(() => _termoMencaoAtivo = null);
    widget.focusNode.requestFocus();
  }

  void _enviar() {
    if (_termoMencaoAtivo != null) {
      setState(() => _termoMencaoAtivo = null);
    }
    widget.onEnviar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_termoMencaoAtivo != null) _buildSugestoesMencao(theme),
          if (widget.respondendoAComentario != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 15, color: theme.textColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Respondendo a ${widget.respondendoAComentario!.autorNome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onCancelarResposta,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onChanged: _aoDigitarComentario,
                  onSubmitted: (_) => _enviar(),
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.respondendoAComentario != null
                        ? 'Escrever sub-resposta...'
                        : 'Escrever um comentário...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(11),
                  minimumSize: const Size(42, 42),
                ),
                onPressed: _enviar,
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: theme.buttonTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSugestoesMencao(AppTheme theme) {
    final q = _termoMencaoAtivo!;
    final sugestoes = _todasContasMencao.where((u) {
      final un = u.usernameExibicao.replaceAll('@', '').toLowerCase();
      if (un.isEmpty) return false;
      if (q.isEmpty) return true;
      return un.contains(q) || u.nomeExibicao.toLowerCase().contains(q);
    }).take(4).toList();
    if (sugestoes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final u in sugestoes)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () => _inserirMencao(u),
              title: Text(
                u.nomeExibicao,
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              trailing: Text(
                u.usernameExibicao,
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: const Color(0xFF1D9BF0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
