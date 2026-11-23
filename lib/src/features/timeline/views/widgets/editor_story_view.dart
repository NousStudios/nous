import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Renderiza uma [CamadaTextoStory] com a fonte, alinhamento, cor e escala configurados.
class CamadaTextoStoryWidget extends StatelessWidget {
  final CamadaTextoStory camada;
  final ValueChanged<String>? onTapMencao;

  const CamadaTextoStoryWidget({
    super.key,
    required this.camada,
    this.onTapMencao,
  });

  static TextStyle resolverEstilo(CamadaTextoStory camada) {
    final corTexto = _parseHex(camada.corTextoHex, Colors.white);
    final tamanhoBase = 20.0 * camada.escala.clamp(0.6, 2.5);
    switch (camada.fonte) {
      case 'negrito':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        );
      case 'serif':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontFamily: 'serif',
          fontWeight: FontWeight.w600,
        );
      case 'mono':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase * 0.92,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        );
      default:
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontWeight: FontWeight.w600,
        );
    }
  }

  static Color _parseHex(String hex, Color fallback) {
    final limpo = hex.replaceAll('#', '').trim();
    if (limpo.isEmpty) return fallback;
    final norm = limpo.length == 6 ? 'FF$limpo' : limpo;
    final val = int.tryParse(norm, radix: 16);
    return val != null ? Color(val) : fallback;
  }

  TextAlign _alinhamento() {
    switch (camada.alinhamento) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final temFundo = camada.corFundoHex.trim().isNotEmpty;
    final corFundo = temFundo
        ? _parseHex(camada.corFundoHex, Colors.black54)
        : Colors.transparent;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: EdgeInsets.symmetric(
        horizontal: temFundo ? 12 : 4,
        vertical: temFundo ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(10),
        boxShadow: temFundo
            ? null
            : const [
                BoxShadow(color: Colors.black87, blurRadius: 8),
              ],
      ),
      child: (onTapMencao != null && camada.texto.contains('@'))
          ? _buildTextoComMencoes(resolverEstilo(camada))
          : Text(
              camada.texto,
              textAlign: _alinhamento(),
              style: resolverEstilo(camada),
            ),
    );
  }

  Widget _buildTextoComMencoes(TextStyle estiloBase) {
    final regex = RegExp(r'@([a-zA-Z0-9._]+)');
    final texto = camada.texto;
    final spans = <InlineSpan>[];
    var ultimo = 0;
    for (final m in regex.allMatches(texto)) {
      if (m.start > ultimo) {
        spans.add(
          TextSpan(text: texto.substring(ultimo, m.start), style: estiloBase),
        );
      }
      final handle = m.group(1) ?? '';
      spans.add(
        TextSpan(
          text: m.group(0),
          style: estiloBase.copyWith(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w800,
          ),
          recognizer: handle.isNotEmpty
              ? (TapGestureRecognizer()..onTap = () => onTapMencao!(handle))
              : null,
        ),
      );
      ultimo = m.end;
    }
    if (ultimo < texto.length) {
      spans.add(TextSpan(text: texto.substring(ultimo), style: estiloBase));
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: _alinhamento(),
    );
  }
}

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

  static const _paletas = <({String label, String textoHex, String fundoHex})>[
    (label: 'Escuro', textoHex: 'FFFFFFFF', fundoHex: 'B3000000'),
    (label: 'Claro', textoHex: 'FF111111', fundoHex: 'E6FFFFFF'),
    (label: 'Limpo', textoHex: 'FFFFFFFF', fundoHex: ''),
    (label: 'Destaque', textoHex: 'FFFFFFFF', fundoHex: 'CCDC2626'),
    (label: 'Solar', textoHex: 'FF111111', fundoHex: 'E6FACC15'),
  ];

  static const _fontes = <({String id, String label})>[
    (id: 'padrao', label: 'Padrão'),
    (id: 'negrito', label: 'Forte'),
    (id: 'serif', label: 'Clássica'),
    (id: 'mono', label: 'Máquina'),
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

  @override
  void dispose() {
    _textoInlineCtrl.dispose();
    super.dispose();
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
        final midia = await TimelineService.importarMidiaLocal(
          _caminhoAtual,
        );
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

  Widget _botaoFerramentaLateral({
    required IconData icone,
    required String tooltip,
    required VoidCallback onTap,
    bool ativo = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: ativo ? 0.58 : 0.32),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: ativo ? 0.45 : 0.18),
            ),
          ),
          child: Icon(
            icone,
            size: 20,
            color: ativo ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildEditorTextoEmTempoReal() {
    final temFundo = _rascunhoTexto.corFundoHex.trim().isNotEmpty;
    final corFundo = temFundo
        ? CamadaTextoStoryWidget._parseHex(
            _rascunhoTexto.corFundoHex,
            Colors.black54,
          )
        : Colors.transparent;
    final align = switch (_rascunhoTexto.alinhamento) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.32),
        child: Column(
          children: [
            // Barra superior: Remover, Alinhamento e Concluir
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (_indiceEdicaoTexto != null)
                    TextButton(
                      onPressed: _removerTextoEmEdicao,
                      child: Text(
                        'Remover',
                        style: widget.theme.getTextStyle(
                          color: widget.theme.dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _editandoTexto = false),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Alinhar à esquerda',
                    icon: Icon(
                      Icons.format_align_left_rounded,
                      color: _rascunhoTexto.alinhamento == 'left'
                          ? Colors.white
                          : Colors.white54,
                    ),
                    onPressed: () => setState(
                      () => _rascunhoTexto =
                          _rascunhoTexto.copyWith(alinhamento: 'left'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Centralizar',
                    icon: Icon(
                      Icons.format_align_center_rounded,
                      color: _rascunhoTexto.alinhamento == 'center'
                          ? Colors.white
                          : Colors.white54,
                    ),
                    onPressed: () => setState(
                      () => _rascunhoTexto =
                          _rascunhoTexto.copyWith(alinhamento: 'center'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Alinhar à direita',
                    icon: Icon(
                      Icons.format_align_right_rounded,
                      color: _rascunhoTexto.alinhamento == 'right'
                          ? Colors.white
                          : Colors.white54,
                    ),
                    onPressed: () => setState(
                      () => _rascunhoTexto =
                          _rascunhoTexto.copyWith(alinhamento: 'right'),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _concluirEdicaoTexto,
                    child: const Text(
                      'Concluir',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Área central: texto ao vivo sobre o Story
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: EdgeInsets.symmetric(
                      horizontal: temFundo ? 14 : 6,
                      vertical: temFundo ? 8 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: corFundo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _textoInlineCtrl,
                      autofocus: true,
                      maxLines: 5,
                      minLines: 1,
                      textAlign: align,
                      style: CamadaTextoStoryWidget.resolverEstilo(
                        _rascunhoTexto,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _concluirEdicaoTexto(),
                      decoration: InputDecoration(
                        hintText: 'Digite seu texto...',
                        hintStyle: CamadaTextoStoryWidget.resolverEstilo(
                          _rascunhoTexto,
                        ).copyWith(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Controles inferiores em tempo real: Tamanho, Fonte e Estilo/Cor
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Colors.black.withValues(alpha: 0.52),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_size_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      Expanded(
                        child: Slider(
                          value: _rascunhoTexto.escala.clamp(0.7, 2.0),
                          min: 0.7,
                          max: 2.0,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => setState(
                            () => _rascunhoTexto =
                                _rascunhoTexto.copyWith(escala: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final f in _fontes)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(f.label),
                              selected: _rascunhoTexto.fonte == f.id,
                              onSelected: (_) => setState(
                                () => _rascunhoTexto =
                                    _rascunhoTexto.copyWith(fonte: f.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final p in _paletas)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(p.label),
                              selected:
                                  _rascunhoTexto.corTextoHex == p.textoHex &&
                                      _rascunhoTexto.corFundoHex == p.fundoHex,
                              onSelected: (_) => setState(
                                () => _rascunhoTexto = _rascunhoTexto.copyWith(
                                  corTextoHex: p.textoHex,
                                  corFundoHex: p.fundoHex,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      backgroundColor: _caminhoAtual.isEmpty ? corFundoStory : Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (_ehVideoAtual)
                  const Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      size: 68,
                      color: Colors.white70,
                    ),
                  )
                else if (caminhoResolvido.isNotEmpty &&
                    File(caminhoResolvido).existsSync())
                  Image.file(
                    File(caminhoResolvido),
                    fit: BoxFit.contain,
                  )
                else if (_caminhoAtual.isEmpty)
                  Container(color: corFundoStory)
                else
                  const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 56,
                      color: Colors.white54,
                    ),
                  ),

                // Camadas de texto arrastáveis e redimensionáveis (pinça, arrasto e scroll)
                for (int i = 0; i < _camadas.length; i++)
                  if (!_editandoTexto || _indiceEdicaoTexto != i)
                    Positioned(
                      left: (_camadas[i].x * w - 110).clamp(8.0, w - 120),
                      top: (_camadas[i].y * h - 24).clamp(56.0, h - 120),
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            final delta = -event.scrollDelta.dy * 0.0015;
                            setState(() {
                              final novaEscala =
                                  (_camadas[i].escala + delta).clamp(0.7, 2.2);
                              _camadas[i] =
                                  _camadas[i].copyWith(escala: novaEscala);
                            });
                          }
                        },
                        child: GestureDetector(
                          onTap: () => _abrirEditorTexto(indiceEdicao: i),
                          onScaleStart: (_) =>
                              _escalaBaseGesto = _camadas[i].escala,
                          onScaleUpdate: (d) {
                            setState(() {
                              final nx =
                                  (_camadas[i].x + d.focalPointDelta.dx / w)
                                      .clamp(0.12, 0.88);
                              final ny =
                                  (_camadas[i].y + d.focalPointDelta.dy / h)
                                      .clamp(0.10, 0.85);
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
                    ),

                if (_editandoTexto)
                  _buildEditorTextoEmTempoReal(),

                // Topo: Fechar + selo de repostagem
                if (!_editandoTexto)
                  Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (widget.storyRepostOriginal != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Repostando de ${widget.storyRepostOriginal!.autorNome}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Barra de ícones na lateral esquerda (estilo Instagram, leve e extensível)
                if (!_editandoTexto)
                  Positioned(
                  top: 76,
                  left: 12,
                  child: Column(
                    children: [
                      _botaoFerramentaLateral(
                        icone: Icons.title_rounded,
                        tooltip: 'Adicionar texto (Aa)',
                        onTap: () => _abrirEditorTexto(),
                      ),
                      _botaoFerramentaLateral(
                        icone: Icons.photo_library_outlined,
                        tooltip: 'Escolher foto da pasta',
                        onTap: _selecionarFotoDaPasta,
                      ),
                      if (_caminhoAtual.isEmpty)
                        _botaoFerramentaLateral(
                          icone: Icons.palette_outlined,
                          tooltip: 'Trocar cor de fundo',
                          onTap: _alternarCorFundo,
                        ),
                      _botaoFerramentaLateral(
                        icone: Icons.emoji_emotions_outlined,
                        tooltip: 'Figurinhas (em breve)',
                        ativo: false,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Figurinhas chegarão em breve!'),
                          ),
                        ),
                      ),
                      _botaoFerramentaLateral(
                        icone: Icons.brush_outlined,
                        tooltip: 'Desenho (em breve)',
                        ativo: false,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ferramenta de desenho em breve!'),
                          ),
                        ),
                      ),
                      _botaoFerramentaLateral(
                        icone: Icons.music_note_outlined,
                        tooltip: 'Música (em breve)',
                        ativo: false,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Músicas no Story em breve!'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra inferior: Destacar + Compartilhar no Story
                if (!_editandoTexto)
                  Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _configurarDestaque,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _destaquePermanente
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _destaquePermanente
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _destaquePermanente ? 'Destacado' : 'Destacar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _publicando ? null : _publicar,
                          icon: _publicando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _publicando
                                ? 'Publicando...'
                                : 'Compartilhar no Story',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
