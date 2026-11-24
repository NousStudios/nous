import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/cabecalho_criar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/lista_mencoes_criar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/publicacao_criar_pub_helper.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/secao_capa_video_criar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/secao_colaboradores_criar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/secao_midia_criar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/selecao_arquivos_criar_pub_helper.dart';

class DialogCriarPublicacao extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous autor;
  final TipoFeedSocial tipoInicial;

  const DialogCriarPublicacao({
    super.key,
    required this.theme,
    required this.autor,
    this.tipoInicial = TipoFeedSocial.fotos,
  });

  static Future<PublicacaoSocial?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous autor,
    TipoFeedSocial tipoInicial = TipoFeedSocial.fotos,
  }) {
    return Navigator.of(context).push<PublicacaoSocial>(
      MaterialPageRoute(
        builder: (_) => DialogCriarPublicacao(
          theme: theme,
          autor: autor,
          tipoInicial: tipoInicial,
        ),
      ),
    );
  }

  @override
  State<DialogCriarPublicacao> createState() => _DialogCriarPublicacaoState();
}

class _DialogCriarPublicacaoState extends State<DialogCriarPublicacao> {
  final TextEditingController _textoCtrl = TextEditingController();
  final TextEditingController _cifraCtrl = TextEditingController();
  final TextEditingController _larguraCtrl = TextEditingController(text: '4');
  final TextEditingController _alturaCtrl = TextEditingController(text: '5');
  final TextEditingController _buscaCoautorCtrl = TextEditingController();

  late TipoFeedSocial _tipo;
  bool _interacaoFotoAtiva = false;
  PadraoExibicaoMidia _padrao = PadraoExibicaoMidia.original;
  final int _colunasMosaico = 3;
  double _alinhamentoX = 0.0;
  double _alinhamentoY = 0.0;
  double _escalaZoom = 1.0;
  double _zoomBaseGestos = 1.0;
  int _indiceFotoPreview = 0;
  final Map<int, ({double x, double y, double zoom})> _ajustesPorFoto = {};
  int _etapa = 0;
  bool _permitirDownload = true;
  bool _mostrarBuscaColab = false;
  bool _salvando = false;
  bool _selecionandoArquivos = false;

  final List<XFile> _arquivosSelecionados = [];
  XFile? _capaVideo;
  Uint8List? _capaFrameBytes;
  final List<UsuarioNous> _coautoresSelecionados = [];
  List<UsuarioNous> _todosUsuarios = [];
  List<UsuarioNous> _todasContasMencao = [];
  String? _termoMencaoAtivo;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tipo = (widget.tipoInicial == TipoFeedSocial.fotos ||
            widget.tipoInicial == TipoFeedSocial.videos ||
            widget.tipoInicial == TipoFeedSocial.documentos ||
            widget.tipoInicial == TipoFeedSocial.livros ||
            widget.tipoInicial == TipoFeedSocial.musicas ||
            widget.tipoInicial == TipoFeedSocial.escritos)
        ? widget.tipoInicial
        : TipoFeedSocial.fotos;
    if (_tipo == TipoFeedSocial.videos) {
      _padrao = PadraoExibicaoMidia.paisagem16x9;
    }
    _textoCtrl.addListener(_aoDigitarTexto);
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _textoCtrl.removeListener(_aoDigitarTexto);
    _textoCtrl.dispose();
    _cifraCtrl.dispose();
    _larguraCtrl.dispose();
    _alturaCtrl.dispose();
    _buscaCoautorCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuarios() async {
    final todos = await ContasNousService.carregarTodas();
    final meuCpf = widget.autor.cpf.replaceAll(RegExp(r'\D'), '');
    if (!mounted) return;
    setState(() {
      _todasContasMencao = todos;
      _todosUsuarios = todos
          .where((u) => u.cpf.replaceAll(RegExp(r'\D'), '') != meuCpf)
          .toList();
    });
  }

  void _aoDigitarTexto() {
    final texto = _textoCtrl.text;
    final sel = _textoCtrl.selection;
    final pos = sel.isValid ? sel.baseOffset : texto.length;
    final ateCursor = pos <= texto.length ? texto.substring(0, pos) : texto;
    final match = RegExp(r'(?:^|\s)@([\p{L}\p{N}_\.]*)$', unicode: true)
        .firstMatch(ateCursor);
    final novoTermo = match?.group(1)?.toLowerCase();
    if (novoTermo != _termoMencaoAtivo && mounted) {
      setState(() => _termoMencaoAtivo = novoTermo);
    }
  }

  void _inserirMencao(UsuarioNous usuario) {
    final handle = usuario.usernameExibicao.isNotEmpty
        ? usuario.usernameExibicao
        : '@${usuario.nomeDeUsuario.replaceAll('@', '').trim()}';
    if (handle.length <= 1) return;

    final texto = _textoCtrl.text;
    final sel = _textoCtrl.selection;
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
    _textoCtrl.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(offset: novaPos),
    );
    setState(() => _termoMencaoAtivo = null);
  }

  Future<void> _selecionarArquivos() async {
    if (_selecionandoArquivos) return;
    _selecionandoArquivos = true;
    try {
      final res = await SelecaoArquivosCriarPubHelper.selecionar(_tipo);
      if (!mounted) return;
      if (res.erro != null) {
        setState(() => _erro = res.erro);
        return;
      }
      if (res.arquivos.isEmpty) return;

      if (res.ehVideo) {
        final videoSelecionado = res.arquivos.first;
        setState(() {
          _arquivosSelecionados
            ..clear()
            ..add(videoSelecionado);
          _capaVideo = null;
          _capaFrameBytes = null;
          _erro = null;
        });
        unawaited(() async {
          final bytes =
              await SecaoCapaVideoCriarPubWidget.capturarPrimeiroFrameBytes(
            videoSelecionado.path,
          );
          if (mounted &&
              bytes != null &&
              _capaVideo == null &&
              _capaFrameBytes == null) {
            setState(() => _capaFrameBytes = bytes);
          }
        }());
        return;
      }

      setState(() {
        if (res.tipoSugerido != null) {
          _tipo = res.tipoSugerido!;
        }
        _arquivosSelecionados.addAll(res.arquivos);
        _erro = null;
      });
      if (res.tipoSugerido != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Arquivo de documento detectado: publicação direcionada para a timeline de Documentos.',
            ),
          ),
        );
      }
    } finally {
      _selecionandoArquivos = false;
    }
  }

  double? _obterAspectRatioPrevia() {
    switch (_padrao) {
      case PadraoExibicaoMidia.quadrado1x1:
        return 1.0;
      case PadraoExibicaoMidia.retrato4x5:
        return 4 / 5;
      case PadraoExibicaoMidia.paisagem16x9:
        return 16 / 9;
      case PadraoExibicaoMidia.vertical9x16:
        return 9 / 16;
      case PadraoExibicaoMidia.personalizado:
        final l = double.tryParse(_larguraCtrl.text.replaceAll(',', '.')) ?? 0;
        final a = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 0;
        return (l > 0 && a > 0) ? (l / a) : null;
      case PadraoExibicaoMidia.original:
      case PadraoExibicaoMidia.mosaico:
        return null;
    }
  }

  Future<void> _publicar() async {
    if (_salvando) return;
    final texto = _textoCtrl.text.trim();
    if (_tipo == TipoFeedSocial.escritos && texto.isEmpty) {
      setState(() => _erro = 'Escreva o conteúdo da publicação.');
      return;
    }
    if (_tipo != TipoFeedSocial.escritos &&
        _arquivosSelecionados.isEmpty &&
        texto.isEmpty) {
      setState(() => _erro = 'Selecione um arquivo ou escreva algo.');
      return;
    }

    double? proporcaoCustom;
    if (_padrao == PadraoExibicaoMidia.personalizado) {
      final l = double.tryParse(_larguraCtrl.text.replaceAll(',', '.')) ?? 0;
      final a = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 0;
      if (l <= 0 || a <= 0) {
        setState(() => _erro = 'Informe largura e altura válidas.');
        return;
      }
      proporcaoCustom = l / a;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      _ajustesPorFoto[_indiceFotoPreview] = (
        x: _alinhamentoX,
        y: _alinhamentoY,
        zoom: _escalaZoom,
      );
      final pub = await PublicacaoCriarPubHelper.criarPublicacao(
        autor: widget.autor,
        tipo: _tipo,
        texto: texto,
        arquivosSelecionados: _arquivosSelecionados,
        ajustesPorFoto: _ajustesPorFoto,
        alinhamentoX: _alinhamentoX,
        alinhamentoY: _alinhamentoY,
        escalaZoom: _escalaZoom,
        capaVideo: _capaVideo,
        capaFrameBytes: _capaFrameBytes,
        coautoresSelecionados: _coautoresSelecionados,
        padraoExibicao: _padrao,
        proporcaoCustom: proporcaoCustom,
        colunasMosaico: _colunasMosaico,
        permitirDownload: _permitirDownload,
        cifraLetra: _cifraCtrl.text.trim(),
      );

      if (mounted) Navigator.of(context).pop(pub);
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = 'Erro ao publicar: $e';
        });
      }
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
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CabecalhoCriarPubWidget(
                  theme: theme,
                  etapa: _etapa,
                  tipoAtivo: _tipo,
                  onVoltarEtapa: () => setState(() => _etapa = 0),
                  onFechar: () => Navigator.of(context).pop(),
                  onSelecionarTipo: (tipo) {
                    setState(() {
                      _tipo = tipo;
                      _arquivosSelecionados.clear();
                      _erro = null;
                    });
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: _interacaoFotoAtiva
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_etapa == 0 && _tipo != TipoFeedSocial.escritos) ...[
                          _buildSecaoMidia(theme),
                          if (_tipo == TipoFeedSocial.videos) ...[
                            const SizedBox(height: 14),
                            SecaoCapaVideoCriarPubWidget(
                              theme: theme,
                              capaVideo: _capaVideo,
                              capaFrameBytes: _capaFrameBytes,
                              arquivosSelecionados: _arquivosSelecionados,
                              aspectRatio: _obterAspectRatioPrevia() ?? (16 / 9),
                              onCapaImagemSelecionada: (arq) => setState(() {
                                _capaVideo = arq;
                                _capaFrameBytes = null;
                              }),
                              onFrameEscolhido: (bytes) => setState(() {
                                _capaFrameBytes = bytes;
                                _capaVideo = null;
                              }),
                              onRemoverCapa: () => setState(() {
                                _capaVideo = null;
                                _capaFrameBytes = null;
                              }),
                            ),
                            const SizedBox(height: 14),
                            SeletorFormatoVisualCriarPubWidget(
                              theme: theme,
                              tipo: _tipo,
                              padraoAtual: _padrao,
                              onSelecionarPadrao: (p) =>
                                  setState(() => _padrao = p),
                            ),
                          ],
                          if (_tipo == TipoFeedSocial.fotos) ...[
                            const SizedBox(height: 14),
                            SeletorFormatoVisualCriarPubWidget(
                              theme: theme,
                              tipo: _tipo,
                              padraoAtual: _padrao,
                              onSelecionarPadrao: (p) =>
                                  setState(() => _padrao = p),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.music_note_outlined,
                                color: theme.textColor,
                                size: 20,
                              ),
                              title: Text(
                                'Adicionar música',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),
                              subtitle: Text(
                                'Em breve • trilha sonora de fundo nas fotos',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: theme.secondaryTextColor,
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Música de fundo nas fotos estará disponível em breve!',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                        if (_etapa == 1 || _tipo == TipoFeedSocial.escritos) ...[
                          if (_tipo != TipoFeedSocial.escritos &&
                              _arquivosSelecionados.isNotEmpty) ...[
                            Row(
                              children: [
                                if (_tipo == TipoFeedSocial.fotos)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_arquivosSelecionados.first.path),
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      alignment: Alignment(
                                        _alinhamentoX,
                                        _alinhamentoY,
                                      ),
                                    ),
                                  )
                                else if (_tipo == TipoFeedSocial.videos &&
                                    _capaVideo != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_capaVideo!.path),
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${_arquivosSelecionados.length} arquivo(s) selecionado(s)',
                                    style: theme.getTextStyle(
                                      fontSize: 12.5,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          ThemedTextField(
                            theme: theme,
                            controller: _textoCtrl,
                            linhas: _tipo == TipoFeedSocial.escritos ? 7 : 3,
                            label: _tipo == TipoFeedSocial.escritos
                                ? 'Escreva sua publicação (use @ para mencionar)...'
                                : 'Escreva uma legenda, #tags ou @menções...',
                          ),
                          if (_termoMencaoAtivo != null)
                            ListaMencoesCriarPubWidget(
                              theme: theme,
                              termoMencao: _termoMencaoAtivo!,
                              todasContas: _todasContasMencao,
                              onSelecionarUsuario: _inserirMencao,
                            ),
                          if (_tipo == TipoFeedSocial.musicas) ...[
                            const SizedBox(height: 10),
                            ThemedTextField(
                              theme: theme,
                              controller: _cifraCtrl,
                              linhas: 5,
                              label: 'Letra, Cifra ou Tablatura (opcional)...',
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: theme.borderColor.withValues(alpha: 0.3),
                          ),
                          SecaoColaboradoresCriarPubWidget(
                            theme: theme,
                            expandido: _mostrarBuscaColab,
                            buscaCtrl: _buscaCoautorCtrl,
                            todosUsuarios: _todosUsuarios,
                            selecionados: _coautoresSelecionados,
                            onAlternarExpandido: () => setState(
                              () => _mostrarBuscaColab = !_mostrarBuscaColab,
                            ),
                            onBuscaAlterada: () => setState(() {}),
                            onRemoverCoautor: (u) => setState(
                              () => _coautoresSelecionados.remove(u),
                            ),
                            onAlternarCoautor: (u) {
                              setState(() {
                                final jaTem = _coautoresSelecionados.any(
                                  (c) => c.cpf == u.cpf,
                                );
                                if (jaTem) {
                                  _coautoresSelecionados
                                      .removeWhere((c) => c.cpf == u.cpf);
                                } else {
                                  _coautoresSelecionados.add(u);
                                }
                              });
                            },
                          ),
                          if (_tipo != TipoFeedSocial.escritos)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.download_outlined,
                                color: theme.textColor,
                                size: 20,
                              ),
                              title: Text(
                                'Permitir download',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),
                              subtitle: Text(
                                'Outros usuários poderão baixar este arquivo',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              trailing: ThemedSwitch(
                                value: _permitirDownload,
                                onChanged: (v) =>
                                    setState(() => _permitirDownload = v),
                                theme: theme,
                              ),
                            ),
                        ],
                        if (_erro != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _erro!,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.dangerColor,
                            ),
                          ),
                        ],
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
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _salvando
                        ? null
                        : () {
                            if (_etapa == 0 &&
                                _tipo != TipoFeedSocial.escritos) {
                              if (_arquivosSelecionados.isEmpty) {
                                setState(
                                  () => _erro =
                                      'Selecione ao menos um arquivo para avançar.',
                                );
                                return;
                              }
                              setState(() {
                                _erro = null;
                                _etapa = 1;
                              });
                            } else {
                              _publicar();
                            }
                          },
                    child: Text(
                      (_etapa == 0 && _tipo != TipoFeedSocial.escritos)
                          ? 'Avançar'
                          : (_salvando ? 'Publicando...' : 'Publicar'),
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

  Widget _buildSecaoMidia(AppTheme theme) {
    return SecaoMidiaCriarPubWidget(
      theme: theme,
      tipo: _tipo,
      arquivosSelecionados: _arquivosSelecionados,
      indiceFotoPreview: _indiceFotoPreview,
      aspectRatioPrevia: _obterAspectRatioPrevia(),
      alinhamentoX: _alinhamentoX,
      alinhamentoY: _alinhamentoY,
      escalaZoom: _escalaZoom,
      onSelecionarArquivos: _selecionarArquivos,
      onSelecionarIndice: (novoIdx) {
        _ajustesPorFoto[_indiceFotoPreview] = (
          x: _alinhamentoX,
          y: _alinhamentoY,
          zoom: _escalaZoom,
        );
        final salvo = _ajustesPorFoto[novoIdx];
        setState(() {
          _indiceFotoPreview = novoIdx;
          _alinhamentoX = salvo?.x ?? 0.0;
          _alinhamentoY = salvo?.y ?? 0.0;
          _escalaZoom = salvo?.zoom ?? 1.0;
        });
      },
      onRemoverIndice: (i) {
        setState(() {
          _arquivosSelecionados.removeAt(i);
          _ajustesPorFoto.remove(i);
          if (_indiceFotoPreview >= _arquivosSelecionados.length) {
            _indiceFotoPreview = (_arquivosSelecionados.length - 1).clamp(0, 99);
          }
        });
      },
      onAtualizarAjuste: (x, y, zoom) {
        setState(() {
          _alinhamentoX = x;
          _alinhamentoY = y;
          _escalaZoom = zoom;
          _ajustesPorFoto[_indiceFotoPreview] = (x: x, y: y, zoom: zoom);
        });
      },
      onInteracaoAtivaMudou: (ativa) {
        if (_interacaoFotoAtiva != ativa) {
          setState(() => _interacaoFotoAtiva = ativa);
        }
      },
      onScaleStart: () {
        _zoomBaseGestos = _escalaZoom;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.scale != 1.0) {
            _escalaZoom = (_zoomBaseGestos * details.scale).clamp(1.0, 3.0);
          }
          final divisor = 130.0 * _escalaZoom;
          _alinhamentoX =
              (_alinhamentoX - details.focalPointDelta.dx / divisor)
                  .clamp(-1.0, 1.0);
          _alinhamentoY =
              (_alinhamentoY - details.focalPointDelta.dy / divisor)
                  .clamp(-1.0, 1.0);
          _ajustesPorFoto[_indiceFotoPreview] = (
            x: _alinhamentoX,
            y: _alinhamentoY,
            zoom: _escalaZoom,
          );
        });
      },
      onLimparTudo: () => setState(() {
        _arquivosSelecionados.clear();
        _ajustesPorFoto.clear();
        _indiceFotoPreview = 0;
      }),
    );
  }
}
