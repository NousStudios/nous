import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_criar_publicacao.dart';

enum DestinoCapturaCamera {
  story,
  fotos,
  videos,
  documentos,
  musicas,
  escritos,
}

/// Tela de câmera e criação rápida estilo Instagram (arrastar da esquerda para a direita
/// no Perfil Público). Toque curto captura foto do preview ao vivo; segurar grava vídeo.
class CameraCriacaoView extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous autor;
  final bool ativa;
  final VoidCallback onVoltarPerfil;

  const CameraCriacaoView({
    super.key,
    required this.theme,
    required this.autor,
    required this.ativa,
    required this.onVoltarPerfil,
  });

  @override
  State<CameraCriacaoView> createState() => _CameraCriacaoViewState();
}

class _CameraCriacaoViewState extends State<CameraCriacaoView> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  MediaStream? _streamPreview;
  MediaRecorder? _recorder;
  String? _caminhoVideoGravando;

  bool _rendererInicializado = false;
  bool _cameraPronta = false;
  bool _cameraFrontal = false;
  bool _processando = false;
  bool _gravandoVideo = false;
  DestinoCapturaCamera _destino = DestinoCapturaCamera.story;

  @override
  void initState() {
    super.initState();
    if (widget.ativa) {
      _iniciarPreview();
    }
  }

  @override
  void didUpdateWidget(covariant CameraCriacaoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ativa && !oldWidget.ativa) {
      _iniciarPreview();
    } else if (!widget.ativa && oldWidget.ativa) {
      _liberarPreview();
    }
  }

  @override
  void dispose() {
    _liberarPreview();
    if (_rendererInicializado) {
      _renderer.dispose();
    }
    super.dispose();
  }

  Future<void> _iniciarPreview() async {
    try {
      if (!_rendererInicializado) {
        await _renderer.initialize();
        _rendererInicializado = true;
      }
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': _cameraFrontal ? 'user' : 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });
      if (!mounted || !widget.ativa) {
        stream.getTracks().forEach((t) => t.stop());
        await stream.dispose();
        return;
      }
      _streamPreview = stream;
      _renderer.srcObject = stream;
      setState(() => _cameraPronta = true);
    } catch (e) {
      debugPrint('[CameraCriacaoView] Preview indisponível: $e');
      if (mounted) setState(() => _cameraPronta = false);
    }
  }

  Future<void> _liberarPreview() async {
    try {
      if (_gravandoVideo && _recorder != null) {
        await _recorder!.stop();
      }
    } catch (_) {}
    _gravandoVideo = false;
    _recorder = null;

    try {
      _streamPreview?.getTracks().forEach((t) => t.stop());
      await _streamPreview?.dispose();
    } catch (_) {}
    _streamPreview = null;
    if (_rendererInicializado) {
      _renderer.srcObject = null;
    }
    if (mounted) setState(() => _cameraPronta = false);
  }

  Future<void> _alternarCamera() async {
    _cameraFrontal = !_cameraFrontal;
    await _liberarPreview();
    await _iniciarPreview();
  }

  Future<void> _tirarFoto() async {
    if (_processando || _gravandoVideo) return;
    setState(() => _processando = true);

    try {
      final videoTrack = _streamPreview?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        try {
          final buffer = await videoTrack.captureFrame();
          final bytes = buffer.asUint8List();
          if (bytes.isNotEmpty) {
            final dirTemp = await getTemporaryDirectory();
            final nome = 'foto_${DateTime.now().millisecondsSinceEpoch}.png';
            final arqTemp = File(p.join(dirTemp.path, nome));
            await arqTemp.writeAsBytes(bytes, flush: true);
            await _publicarArquivoCapturado(
              arqTemp.path,
              nome,
              ehVideo: false,
            );
            return;
          }
        } catch (e) {
          debugPrint('[CameraCriacaoView] captureFrame falhou, usando fallback: $e');
        }
      }

      // Fallback via câmera nativa do sistema
      await _liberarPreview();
      final picker = ImagePicker();
      final XFile? arq = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (arq != null) {
        await _publicarArquivoCapturado(arq.path, arq.name, ehVideo: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível capturar a foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
        if (widget.ativa && !_cameraPronta) {
          _iniciarPreview();
        }
      }
    }
  }

  Future<void> _iniciarGravacaoVideo() async {
    if (_processando || _gravandoVideo) return;
    final videoTrack = _streamPreview?.getVideoTracks().firstOrNull;
    if (videoTrack == null) {
      await _gravarVideoFallback();
      return;
    }

    try {
      final dirTemp = await getTemporaryDirectory();
      final nome = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final caminho = p.join(dirTemp.path, nome);
      final recorder = MediaRecorder();
      await recorder.start(
        caminho,
        videoTrack: videoTrack,
        audioChannel: RecorderAudioChannel.INPUT,
      );
      if (!mounted) {
        await recorder.stop();
        return;
      }
      setState(() {
        _recorder = recorder;
        _caminhoVideoGravando = caminho;
        _gravandoVideo = true;
      });
    } catch (e) {
      debugPrint('[CameraCriacaoView] MediaRecorder falhou, usando fallback: $e');
      await _gravarVideoFallback();
    }
  }

  Future<void> _pararGravacaoVideo() async {
    if (!_gravandoVideo || _recorder == null) return;
    final caminho = _caminhoVideoGravando;
    setState(() {
      _gravandoVideo = false;
      _processando = true;
    });

    try {
      await _recorder!.stop();
      _recorder = null;
      _caminhoVideoGravando = null;
      if (caminho != null && File(caminho).existsSync()) {
        await _publicarArquivoCapturado(
          caminho,
          p.basename(caminho),
          ehVideo: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar vídeo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _gravarVideoFallback() async {
    setState(() => _processando = true);
    await _liberarPreview();
    try {
      final picker = ImagePicker();
      final XFile? arq = await picker.pickVideo(source: ImageSource.camera);
      if (arq != null) {
        await _publicarArquivoCapturado(arq.path, arq.name, ehVideo: true);
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
        if (widget.ativa) _iniciarPreview();
      }
    }
  }

  Future<void> _abrirGaleria() async {
    if (_processando) return;
    if (_destino == DestinoCapturaCamera.escritos) {
      await DialogCriarPublicacao.mostrar(
        context,
        theme: widget.theme,
        autor: widget.autor,
        tipoInicial: TipoFeedSocial.escritos,
      );
      widget.onVoltarPerfil();
      return;
    }

    setState(() => _processando = true);
    try {
      final files = await openFiles();
      if (files.isNotEmpty) {
        final f = files.first;
        final ext = f.name.toLowerCase();
        final ehVideo = ext.endsWith('.mp4') ||
            ext.endsWith('.mov') ||
            ext.endsWith('.mkv') ||
            ext.endsWith('.webm');
        await _publicarArquivoCapturado(f.path, f.name, ehVideo: ehVideo);
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _publicarArquivoCapturado(
    String caminho,
    String nome, {
    required bool ehVideo,
  }) async {
    if (!File(caminho).existsSync()) return;
    final midia = await TimelineService.importarMidiaLocal(
      caminho,
      nomeArquivo: nome,
    );
    if (midia == null) return;

    if (_destino == DestinoCapturaCamera.story) {
      await TimelineService.criarStory(
        autorCpf: widget.autor.cpf,
        autorNome: widget.autor.nomeExibicao,
        autorFoto: widget.autor.fotoExibicao,
        caminhoMidia: midia.caminhoRelativo,
        tipoMidia: ehVideo ? 'video' : 'imagem',
      );
    } else {
      final tipo = switch (_destino) {
        DestinoCapturaCamera.fotos => TipoFeedSocial.fotos,
        DestinoCapturaCamera.videos => TipoFeedSocial.videos,
        DestinoCapturaCamera.documentos => TipoFeedSocial.documentos,
        DestinoCapturaCamera.musicas => TipoFeedSocial.musicas,
        DestinoCapturaCamera.escritos => TipoFeedSocial.escritos,
        DestinoCapturaCamera.story => TipoFeedSocial.fotos,
      };
      await TimelineService.criarPublicacao(
        autorCpf: widget.autor.cpf,
        autorNome: widget.autor.nomeExibicao,
        autorFoto: widget.autor.fotoExibicao,
        tipo: tipo,
        midias: [midia],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publicado em ${_rotuloDestino(_destino)}!'),
        ),
      );
      widget.onVoltarPerfil();
    }
  }

  String _rotuloDestino(DestinoCapturaCamera d) {
    switch (d) {
      case DestinoCapturaCamera.story:
        return 'Story';
      case DestinoCapturaCamera.fotos:
        return 'Fotos';
      case DestinoCapturaCamera.videos:
        return 'Vídeos';
      case DestinoCapturaCamera.documentos:
        return 'Docs';
      case DestinoCapturaCamera.musicas:
        return 'Músicas';
      case DestinoCapturaCamera.escritos:
        return 'Escritos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _cameraPronta
                  ? RTCVideoView(
                      _renderer,
                      mirror: _cameraFrontal,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 56,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            kIsWeb || Platform.isWindows
                                ? 'Toque na câmera ou escolha da galeria'
                                : 'Preparando câmera...',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Voltar ao perfil',
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                    ),
                    onPressed: widget.onVoltarPerfil,
                  ),
                  if (_gravandoVideo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.dangerColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'GRAVANDO...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Inverter câmera',
                    icon: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _alternarCamera,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Toque para foto • Segure para gravar vídeo',
                    child: GestureDetector(
                      onTap: _tirarFoto,
                      onLongPressStart: (_) => _iniciarGravacaoVideo(),
                      onLongPressEnd: (_) => _pararGravacaoVideo(),
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _gravandoVideo
                                ? theme.dangerColor
                                : Colors.white,
                            width: 4,
                          ),
                          color: _gravandoVideo
                              ? theme.dangerColor.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        child: _processando
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _abrirGaleria,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: DestinoCapturaCamera.values.map((d) {
                              final ativo = _destino == d;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    _rotuloDestino(d),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: ativo
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color:
                                          ativo ? Colors.black : Colors.white,
                                    ),
                                  ),
                                  selected: ativo,
                                  selectedColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                  onSelected: (_) {
                                    setState(() => _destino = d);
                                    if (d == DestinoCapturaCamera.escritos) {
                                      _abrirGaleria();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
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
}
