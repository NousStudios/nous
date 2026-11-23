import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/animacao_story_sugado_overlay.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_story_view.dart';

/// Tela cheia animada para criação de novo Story (24h) ou Destaque permanente.
class DialogCriarStory extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous autor;

  const DialogCriarStory({
    super.key,
    required this.theme,
    required this.autor,
  });

  static Future<StorySocial?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous autor,
  }) {
    return Navigator.of(context).push<StorySocial>(
      PageRouteBuilder<StorySocial>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => DialogCriarStory(theme: theme, autor: autor),
        transitionsBuilder: (_, anim, _, child) {
          final curva = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curva,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curva),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<DialogCriarStory> createState() => _DialogCriarStoryState();
}

class _DialogCriarStoryState extends State<DialogCriarStory> {
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _textoCtrl = TextEditingController();
  String _caminhoImagem = '';
  bool _destaquePermanente = false;
  bool _salvando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Imagens',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (file != null && mounted) {
      setState(() => _caminhoImagem = file.path);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (_caminhoImagem.isEmpty && _textoCtrl.text.trim().isEmpty) return;
    setState(() => _salvando = true);

    String caminhoRelativo = '';
    if (_caminhoImagem.isNotEmpty) {
      final m = await TimelineService.importarMidiaLocal(_caminhoImagem);
      caminhoRelativo = m?.caminhoRelativo ?? '';
    }

    final story = await TimelineService.criarStory(
      autorCpf: widget.autor.cpf,
      autorNome: widget.autor.nomeExibicao,
      autorFoto: widget.autor.fotoExibicao,
      tituloDestaque: _tituloCtrl.text.trim(),
      caminhoMidia: caminhoRelativo,
      tipoMidia: caminhoRelativo.isNotEmpty ? 'imagem' : 'texto',
      texto: _textoCtrl.text.trim(),
      ehDestaquePermanente: _destaquePermanente,
    );

    if (mounted) {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      Navigator.of(context).pop(story);
      AnimacaoStorySugadoOverlay.disparar(
        overlay,
        theme: widget.theme,
        caminhoMidiaLocal: _caminhoImagem,
        fotoPerfil: widget.autor.fotoExibicao,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Novo Story (24h)',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
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
                        GestureDetector(
                          onTap: _escolherFoto,
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.borderColor),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _caminhoImagem.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(_caminhoImagem),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        child: InkWell(
                                          onTap: () async {
                                            final nav = Navigator.of(context);
                                            final overlay = Overlay.maybeOf(
                                              context,
                                              rootOverlay: true,
                                            );
                                            final publicado =
                                                await EditorStoryView.mostrar(
                                              context,
                                              theme: theme,
                                              autor: widget.autor,
                                              caminhoArquivo: _caminhoImagem,
                                            );
                                            if (publicado != null && mounted) {
                                              nav.pop(true);
                                              AnimacaoStorySugadoOverlay
                                                  .disparar(
                                                overlay,
                                                theme: theme,
                                                caminhoMidiaLocal:
                                                    _caminhoImagem,
                                                fotoPerfil:
                                                    widget.autor.fotoExibicao,
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.title_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Texto & Estilo',
                                                  style: theme.getTextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.65,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            'Trocar foto',
                                            style: theme.getTextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 42,
                                        color: theme.textColor,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Toque para escolher uma foto para o Story',
                                        textAlign: TextAlign.center,
                                        style: theme.getTextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Visível por 24 horas no perfil e na barra de chat',
                                        textAlign: TextAlign.center,
                                        style: theme.getTextStyle(
                                          fontSize: 11.5,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ThemedTextField(
                          theme: theme,
                          controller: _tituloCtrl,
                          linhas: 1,
                          label: 'Título para Destaque (opcional)',
                        ),
                        const SizedBox(height: 10),
                        ThemedTextField(
                          theme: theme,
                          controller: _textoCtrl,
                          linhas: 3,
                          label: 'Legenda ou frase do story (opcional)',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fixar nos Destaques do perfil',
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    'Continua visível no perfil mesmo após 24 horas',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ThemedSwitch(
                              value: _destaquePermanente,
                              onChanged: (v) =>
                                  setState(() => _destaquePermanente = v),
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _salvando ? null : _salvar,
                    child: Text(
                      _salvando ? 'Publicando...' : 'Compartilhar no Story',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
