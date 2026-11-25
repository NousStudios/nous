import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_acoes_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_comentarios_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_midias_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';

class DetalhesPubLayoutPadraoWidget extends StatelessWidget {
  final AppTheme theme;
  final bool ehDesktop;
  final List<PublicacaoSocial> lista;
  final PublicacaoSocial pub;
  final int indiceAtivo;
  final PageController desktopPageController;
  final GlobalKey midiasKey;
  final bool pdfEmTelaCheia;
  final UsuarioNous? usuarioEfetivo;
  final List<UsuarioNous> coautoresResolvidos;
  final List<ReacaoSocial> reacoes;
  final List<ComentarioSocial> comentarios;
  final List<ComentarioSocial> comentariosRaiz;
  final ReacaoSocial? minhaReacao;
  final int likes;
  final int deslikes;
  final bool ehAutor;
  final String meuCpf;
  final ValueChanged<int> onTrocarPublicacao;
  final ValueChanged<TipoReacaoSocial> onReagir;
  final ValueChanged<bool> onAlternarPdfFullScreen;
  final VoidCallback onAbrirMenuOpcoes;
  final VoidCallback onFocarComentario;
  final VoidCallback onRepublicar;
  final VoidCallback onEnviarNoChat;
  final ValueChanged<ComentarioSocial> onResponderComentario;
  final VoidCallback onInteracaoAlterada;
  final VoidCallback onAbrirMapaComentarios;
  final Widget inputComentario;

  const DetalhesPubLayoutPadraoWidget({
    super.key,
    required this.theme,
    required this.ehDesktop,
    required this.lista,
    required this.pub,
    required this.indiceAtivo,
    required this.desktopPageController,
    required this.midiasKey,
    required this.pdfEmTelaCheia,
    required this.usuarioEfetivo,
    required this.coautoresResolvidos,
    required this.reacoes,
    required this.comentarios,
    required this.comentariosRaiz,
    required this.minhaReacao,
    required this.likes,
    required this.deslikes,
    required this.ehAutor,
    required this.meuCpf,
    required this.onTrocarPublicacao,
    required this.onReagir,
    required this.onAlternarPdfFullScreen,
    required this.onAbrirMenuOpcoes,
    required this.onFocarComentario,
    required this.onRepublicar,
    required this.onEnviarNoChat,
    required this.onResponderComentario,
    required this.onInteracaoAlterada,
    required this.onAbrirMapaComentarios,
    required this.inputComentario,
  });

  Widget _buildCabecalhoAutor() {
    return CabecalhoAutorColaboradoresWidget(
      theme: theme,
      publicacao: pub,
      coautoresResolvidos: coautoresResolvidos,
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Mais opções da publicação',
        icon: Icon(Icons.more_horiz_rounded, color: theme.textColor),
        onPressed: onAbrirMenuOpcoes,
      ),
    );
  }

  Widget _buildBarraAcoes() {
    return DetalhesPubAcoesWidget(
      theme: theme,
      publicacao: pub,
      usuarioEfetivo: usuarioEfetivo,
      reacoes: reacoes,
      likes: likes,
      deslikes: deslikes,
      totalComentarios: comentarios.length,
      minhaReacao: minhaReacao,
      onReagir: onReagir,
      onFocarComentario: onFocarComentario,
      onRepublicar: onRepublicar,
      onEnviarNoChat: onEnviarNoChat,
    );
  }

  Widget _buildSecaoComentarios() {
    return DetalhesPubSecaoComentariosWidget(
      theme: theme,
      todosComentarios: comentarios,
      comentariosRaiz: comentariosRaiz,
      ehAutorPublicacao: ehAutor,
      meuCpf: meuCpf,
      onResponder: onResponderComentario,
      onInteracaoAlterada: onInteracaoAlterada,
      onAbrirMapaComentarios: onAbrirMapaComentarios,
    );
  }

  Widget _buildCorpoDesktop() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pub.midias.isNotEmpty)
            Expanded(
              flex: 3,
              child: DetalhesPubPainelMidiaDesktopWidget(
                theme: theme,
                lista: lista,
                pubAtiva: pub,
                indiceAtivo: indiceAtivo,
                pageController: desktopPageController,
                midiasKey: midiasKey,
                pdfFullScreen: pdfEmTelaCheia,
                onPageChanged: onTrocarPublicacao,
                onDoubleTapLike: () => onReagir(TipoReacaoSocial.like),
                onAlternarPdfFullScreen: onAlternarPdfFullScreen,
              ),
            ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: pub.midias.isNotEmpty
                    ? Border(
                        left: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                    child: _buildCabecalhoAutor(),
                  ),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (pub.texto.isNotEmpty) ...[
                            TextoComHashtagsWidget(
                              theme: theme,
                              texto: pub.texto,
                              fontSize: 13.5,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildSecaoComentarios(),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
                    child: _buildBarraAcoes(),
                  ),
                  if (usuarioEfetivo != null) inputComentario,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorpoMobile() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
        child: _buildCabecalhoAutor(),
      ),
      Divider(
        height: 1,
        color: theme.borderColor.withValues(alpha: 0.4),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pub.midias.isNotEmpty) ...[
                Builder(
                  builder: (ctx) {
                    final ehPdf = pub.midias.any(
                      (m) =>
                          m.mimeTipo.toLowerCase() == 'pdf' ||
                          m.nomeArquivo.toLowerCase().endsWith('.pdf'),
                    );
                    final h = MediaQuery.sizeOf(ctx).height;
                    final midia = DetalhesPubMidiasWidget(
                      theme: theme,
                      publicacao: pub,
                      ajustarTelaCheia: true,
                      autoPlayVideo: true,
                      midiaKey: midiasKey,
                      onDoubleTapLike: () => onReagir(TipoReacaoSocial.like),
                      pdfFullScreen: pdfEmTelaCheia,
                      onAlternarPdfFullScreen: onAlternarPdfFullScreen,
                    );
                    return ehPdf
                        ? SizedBox(height: h * 0.46, child: midia)
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: h * 0.50),
                            child: midia,
                          );
                  },
                ),
                const SizedBox(height: 10),
              ],
              _buildBarraAcoes(),
              const SizedBox(height: 10),
              if (pub.texto.isNotEmpty) ...[
                TextoComHashtagsWidget(
                  theme: theme,
                  texto: pub.texto,
                  fontSize: 14,
                ),
                const SizedBox(height: 14),
              ],
              _buildSecaoComentarios(),
            ],
          ),
        ),
      ),
      if (usuarioEfetivo != null) inputComentario,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ehDesktop ? 1080 : 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.textColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Publicação',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
                if (ehDesktop) _buildCorpoDesktop() else ..._buildCorpoMobile(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
