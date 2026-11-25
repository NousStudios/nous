import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/story/camada_texto_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/story/editor_story_barras.dart';
import 'package:nous/src/features/timeline/views/widgets/story/editor_story_texto_overlay.dart';

export 'package:nous/src/features/timeline/views/widgets/story/camada_texto_story_widget.dart';

/// Editor interativo de Story estilo Instagram com barra lateral esquerda minimalista,
/// criação/organização de textos arrastáveis, troca de fonte/estilo e publicação leve.
class EditorStoryView extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous autor;
  final String caminhoArquivo;
  final bool ehVideo;
  final bool abrirTextoAoEntrar;
  final StorySocial? storyRepostOriginal;

  const EditorStoryView({
    super.key,
    required this.theme,
    required this.autor,
    this.caminhoArquivo = '',
    this.ehVideo = false,
    this.abrirTextoAoEntrar = false,
    this.storyRepostOriginal,
  });

  static Future<StorySocial?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous autor,
    String caminhoArquivo = '',
    bool ehVideo = false,
    bool abrirTextoAoEntrar = false,
    StorySocial? storyRepostOriginal,
  }) {
    return Navigator.of(context).push<StorySocial>(
      MaterialPageRoute(
        builder: (_) => EditorStoryView(
          theme: theme,
          autor: autor,
          caminhoArquivo: caminhoArquivo,
          ehVideo: ehVideo,
          abrirTextoAoEntrar: abrirTextoAoEntrar,
          storyRepostOriginal: storyRepostOriginal,
        ),
      ),
    );
  }

  @override
  State<EditorStoryView> createState() => _EditorStoryViewState();
}

class _EditorStoryViewState extends State<EditorStoryView> {
  final List<CamadaTextoStory> _camadas = [];
  late String _caminhoAtual;
  late bool _ehVideoAtual;
  String _corFundoStoryHex = 'FF18181B';
  int _indiceCorFundo = 0;
  double _escalaBaseGesto = 1.0;
  bool _destaquePermanente = false;
  String _tituloDestaque = '';
  bool _publicando = false;
  bool _editandoTexto = false;
  int? _indiceEdicaoTexto;
  final TextEditingController _textoInlineCtrl = TextEditingController();
  CamadaTextoStory _rascunhoTexto = const CamadaTextoStory(texto: '');

  static const _coresFundoStory = <String>[
    'FF18181B',
    'FF1E3A8A',
    'FF7C2D12',
    'FF14532D',
    'FF581C87',
    'FF831843',
  ];

  @override
  void initState() {
    super.initState();
    _caminhoAtual = widget.caminhoArquivo;
    _ehVideoAtual = widget.ehVideo;
    if (widget.storyRepostOriginal != null) {
      _camadas.addAll(widget.storyRepostOriginal!.camadasTexto);
      if (widget.storyRepostOriginal!.corFundoHex.isNotEmpty) {
        _corFundoStoryHex = widget.storyRepostOriginal!.corFundoHex;
      }
    }
    if (widget.abrirTextoAoEntrar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirEditorTexto();
      });
    }
  }

  @override
  void dispose() {
    _textoInlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarFotoDaPasta() async {
    final arq = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Imagens e Vídeos',
          extensions: ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov', 'webm'],
        ),
      ],
    );
    if (arq == null || !mounted) return;
    final lower = arq.path.toLowerCase();
    final ehVid =
        lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm');
    setState(() {
      _caminhoAtual = arq.path;
      _ehVideoAtual = ehVid;
    });
  }

  void _alternarCorFundo() {
    setState(() {
      _indiceCorFundo = (_indiceCorFundo + 1) % _coresFundoStory.length;
      _corFundoStoryHex = _coresFundoStory[_indiceCorFundo];
    });
  }

  void _abrirEditorTexto({int? indiceEdicao}) {
    final inicial = indiceEdicao != null
        ? _camadas[indiceEdicao]
        : const CamadaTextoStory(texto: '');
    _textoInlineCtrl.text = inicial.texto;
    setState(() {
      _indiceEdicaoTexto = indiceEdicao;
      _rascunhoTexto = inicial;
      _editandoTexto = true;
    });
  }

  void _concluirEdicaoTexto() {
    final txt = _textoInlineCtrl.text.trim();
    setState(() {
      if (txt.isEmpty) {
        if (_indiceEdicaoTexto != null &&
            _indiceEdicaoTexto! < _camadas.length) {
          _camadas.removeAt(_indiceEdicaoTexto!);
        }
      } else {
        final finalizada = _rascunhoTexto.copyWith(texto: txt);
        if (_indiceEdicaoTexto != null &&
            _indiceEdicaoTexto! < _camadas.length) {
          _camadas[_indiceEdicaoTexto!] = finalizada;
        } else {
          _camadas.add(finalizada);
        }
      }
      _editandoTexto = false;
      _indiceEdicaoTexto = null;
    });
  }

  void _removerTextoEmEdicao() {
    setState(() {
      if (_indiceEdicaoTexto != null &&
          _indiceEdicaoTexto! < _camadas.length) {
        _camadas.removeAt(_indiceEdicaoTexto!);
      }
      _editandoTexto = false;
      _indiceEdicaoTexto = null;
    });
  }

  Future<void> _configurarDestaque() async {
    if (_destaquePermanente) {
      setState(() => _destaquePermanente = false);
      return;
    }
    final ctrl = TextEditingController(text: _tituloDestaque);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        title: Text(
          'Fixar nos Destaques',
          style: widget.theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Nome do destaque (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      setState(() {
        _destaquePermanente = true;
        _tituloDestaque = ctrl.text.trim();
      });
    }
    ctrl.dispose();
  }

  Future<void> _publicar() async {
    if (_publicando) return;
    setState(() => _publicando = true);
    try {
      StorySocial story;
      if (widget.storyRepostOriginal != null) {
        story = await TimelineService.repostarStory(
          original: widget.storyRepostOriginal!,
          meuCpf: widget.autor.cpf,
          meuNome: widget.autor.nomeExibicao,
          minhaFoto: widget.autor.fotoExibicao,
          camadasExtras: _camadas
              .skip(widget.storyRepostOriginal!.camadasTexto.length)
              .toList(),
        );
      } else if (_caminhoAtual.trim().isNotEmpty) {
        final midia = await TimelineService.importarMidiaLocal(_caminhoAtual);
        story = await TimelineService.criarStory(
          autorCpf: widget.autor.cpf,
          autorNome: widget.autor.nomeExibicao,
          autorFoto: widget.autor.fotoExibicao,
          tituloDestaque: _tituloDestaque,
          caminhoMidia: midia?.caminhoRelativo ?? _caminhoAtual,
          tipoMidia: _ehVideoAtual ? 'video' : 'imagem',
          ehDestaquePermanente: _destaquePermanente,
          camadasTexto: _camadas,
        );
      } else {
        if (_camadas.isEmpty) {
          if (mounted) {
            setState(() => _publicando = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adicione um texto ou uma foto antes de publicar.'),
              ),
            );
          }
          return;
        }
        story = await TimelineService.criarStory(
          autorCpf: widget.autor.cpf,
          autorNome: widget.autor.nomeExibicao,
          autorFoto: widget.autor.fotoExibicao,
          tituloDestaque: _tituloDestaque,
          tipoMidia: 'texto',
          corFundoHex: _corFundoStoryHex,
          ehDestaquePermanente: _destaquePermanente,
          camadasTexto: _camadas,
        );
      }
      if (mounted) Navigator.of(context).pop(story);
    } catch (e) {
      if (mounted) {
        setState(() => _publicando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao publicar story: $e')),
        );
      }
    }
  }

  void _mostrarAvisoEmBreve(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caminhoResolvido = _caminhoAtual.isNotEmpty
        ? (TimelineService.resolverCaminhoMidiaSync(_caminhoAtual) ??
            _caminhoAtual)
        : '';
    final corFundoStory = Color(
      int.tryParse(_corFundoStoryHex, radix: 16) ?? 0xFF18181B,
    );

    return Scaffold(
      backgroundColor:
          _caminhoAtual.isEmpty ? corFundoStory : widget.theme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                _buildConteudoFundo(caminhoResolvido, corFundoStory),
                for (int i = 0; i < _camadas.length; i++)
                  if (!_editandoTexto || _indiceEdicaoTexto != i)
                    _buildCamadaTextoInterativa(i, w, h),
                if (_editandoTexto)
                  Positioned.fill(
                    child: EditorStoryTextoOverlay(
                      theme: widget.theme,
                      controller: _textoInlineCtrl,
                      rascunho: _rascunhoTexto,
                      editandoExistente: _indiceEdicaoTexto != null,
                      onFechar: () => setState(() => _editandoTexto = false),
                      onRemover: _removerTextoEmEdicao,
                      onConcluir: _concluirEdicaoTexto,
                      onRascunhoChanged: (novo) =>
                          setState(() => _rascunhoTexto = novo),
                      onTextoChanged: () => setState(() {}),
                    ),
                  ),
                if (!_editandoTexto)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: EditorStoryBarraTopo(
                      theme: widget.theme,
                      autorRepostNome: widget.storyRepostOriginal?.autorNome,
                      onFechar: () => Navigator.of(context).pop(),
                    ),
                  ),
                if (!_editandoTexto)
                  Positioned(
                    top: 76,
                    left: 12,
                    child: EditorStoryBarraLateral(
                      theme: widget.theme,
                      mostrarBotaoCorFundo: _caminhoAtual.isEmpty,
                      onAdicionarTexto: () => _abrirEditorTexto(),
                      onSelecionarMidia: _selecionarFotoDaPasta,
                      onAlternarCorFundo: _alternarCorFundo,
                      onRecursoEmBreve: _mostrarAvisoEmBreve,
                    ),
                  ),
                if (!_editandoTexto)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: EditorStoryBarraInferior(
                      theme: widget.theme,
                      destaquePermanente: _destaquePermanente,
                      publicando: _publicando,
                      onConfigurarDestaque: _configurarDestaque,
                      onPublicar: _publicar,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConteudoFundo(String caminhoResolvido, Color corFundoStory) {
    if (_ehVideoAtual) {
      return Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 68,
          color: widget.theme.secondaryTextColor.withValues(alpha: 0.7),
        ),
      );
    }
    if (caminhoResolvido.isNotEmpty && File(caminhoResolvido).existsSync()) {
      return Image.file(
        File(caminhoResolvido),
        fit: BoxFit.contain,
      );
    }
    if (_caminhoAtual.isEmpty) {
      return Container(color: corFundoStory);
    }
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 56,
        color: widget.theme.secondaryTextColor.withValues(alpha: 0.54),
      ),
    );
  }

  Widget _buildCamadaTextoInterativa(int i, double w, double h) {
    return Positioned(
      left: (_camadas[i].x * w - 110).clamp(8.0, w - 120),
      top: (_camadas[i].y * h - 24).clamp(56.0, h - 120),
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final delta = -event.scrollDelta.dy * 0.0015;
            setState(() {
              final novaEscala = (_camadas[i].escala + delta).clamp(0.7, 2.2);
              _camadas[i] = _camadas[i].copyWith(escala: novaEscala);
            });
          }
        },
        child: GestureDetector(
          onTap: () => _abrirEditorTexto(indiceEdicao: i),
          onScaleStart: (_) => _escalaBaseGesto = _camadas[i].escala,
          onScaleUpdate: (d) {
            setState(() {
              final nx =
                  (_camadas[i].x + d.focalPointDelta.dx / w).clamp(0.12, 0.88);
              final ny =
                  (_camadas[i].y + d.focalPointDelta.dy / h).clamp(0.10, 0.85);
              final novaEscala = d.scale != 1.0
                  ? (_escalaBaseGesto * d.scale).clamp(0.7, 2.2)
                  : _camadas[i].escala;
              _camadas[i] = _camadas[i].copyWith(
                x: nx,
                y: ny,
                escala: novaEscala,
              );
            });
          },
          child: CamadaTextoStoryWidget(camada: _camadas[i]),
        ),
      ),
    );
  }
}
