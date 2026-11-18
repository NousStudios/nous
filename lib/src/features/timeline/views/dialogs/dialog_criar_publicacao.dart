import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_fotos_carrossel_widget.dart';

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
  final TextEditingController _larguraCtrl = TextEditingController(text: '4');
  final TextEditingController _alturaCtrl = TextEditingController(text: '5');
  final TextEditingController _buscaCoautorCtrl = TextEditingController();

  late TipoFeedSocial _tipo;
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

  final List<XFile> _arquivosSelecionados = [];
  final List<UsuarioNous> _coautoresSelecionados = [];
  List<UsuarioNous> _todosUsuarios = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tipo = (widget.tipoInicial == TipoFeedSocial.fotos ||
            widget.tipoInicial == TipoFeedSocial.videos ||
            widget.tipoInicial == TipoFeedSocial.documentos ||
            widget.tipoInicial == TipoFeedSocial.musicas ||
            widget.tipoInicial == TipoFeedSocial.escritos)
        ? widget.tipoInicial
        : TipoFeedSocial.fotos;
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
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
      _todosUsuarios = todos
          .where((u) => u.cpf.replaceAll(RegExp(r'\D'), '') != meuCpf)
          .toList();
    });
  }

  Future<void> _selecionarArquivos() async {
    final List<String> extensoes;
    final String label;
    switch (_tipo) {
      case TipoFeedSocial.fotos:
        label = 'Imagens';
        extensoes = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
        break;
      case TipoFeedSocial.videos:
        label = 'Vídeos';
        extensoes = ['mp4', 'mov', 'mkv', 'webm', 'avi'];
        break;
      case TipoFeedSocial.musicas:
        label = 'Áudios e Músicas';
        extensoes = ['mp3', 'wav', 'm4a', 'ogg', 'flac'];
        break;
      default:
        label = 'Documentos';
        extensoes = ['pdf', 'txt', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'zip'];
        break;
    }

    final files = await openFiles(
      acceptedTypeGroups: [XTypeGroup(label: label, extensions: extensoes)],
    );
    if (files.isEmpty || !mounted) return;
    setState(() {
      _arquivosSelecionados.addAll(files);
      _erro = null;
    });
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
      final midias = <MidiaPublicacao>[];
      for (int i = 0; i < _arquivosSelecionados.length; i++) {
        final arq = _arquivosSelecionados[i];
        final ajuste = _ajustesPorFoto[i];
        final m = await TimelineService.importarMidiaLocal(
          arq.path,
          nomeArquivo: arq.name,
        );
        if (m != null) {
          midias.add(
            m.copyWith(
              alinhamentoX: ajuste?.x ?? _alinhamentoX,
              alinhamentoY: ajuste?.y ?? _alinhamentoY,
              escalaZoom: ajuste?.zoom ?? _escalaZoom,
            ),
          );
        }
      }

      final primeiroAjuste = _ajustesPorFoto[0];
      final pub = await TimelineService.criarPublicacao(
        autorCpf: widget.autor.cpf,
        autorNome: widget.autor.nomeExibicao,
        autorFoto: widget.autor.fotoExibicao,
        tipo: _tipo,
        texto: texto,
        midias: midias,
        coautoresCpfs: _coautoresSelecionados.map((u) => u.cpf).toList(),
        padraoExibicao: _padrao,
        proporcaoCustom: proporcaoCustom,
        colunasMosaico: _colunasMosaico,
        permitirDownload: _permitirDownload,
        alinhamentoX: primeiroAjuste?.x ?? _alinhamentoX,
        alinhamentoY: primeiroAjuste?.y ?? _alinhamentoY,
        escalaZoom: primeiroAjuste?.zoom ?? _escalaZoom,
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
    final filtroCoautor = _buscaCoautorCtrl.text.trim().toLowerCase();
    final sugestoesCoautor = filtroCoautor.isEmpty
        ? const <UsuarioNous>[]
        : _todosUsuarios
            .where((u) =>
                u.nomeExibicao.toLowerCase().contains(filtroCoautor) ||
                u.usernameExibicao.toLowerCase().contains(filtroCoautor))
            .take(5)
            .toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Cabeçalho com título matematicamente centralizado
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_etapa == 1 && _tipo != TipoFeedSocial.escritos)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Voltar',
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.textColor,
                        ),
                        onPressed: () => setState(() => _etapa = 0),
                      ),
                    ),
                  Center(
                    child: Text(
                      'Nova Publicação',
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
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),

            if (_etapa == 0) ...[
              // Seletor minimalista de categoria por ícone
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _abaCategoria(theme, TipoFeedSocial.fotos, Icons.grid_on_sharp, 'Fotos'),
                    _abaCategoria(theme, TipoFeedSocial.videos, Icons.play_circle_outline_rounded, 'Vídeos'),
                    _abaCategoria(theme, TipoFeedSocial.documentos, Icons.description_outlined, 'Docs'),
                    _abaCategoria(theme, TipoFeedSocial.musicas, Icons.music_note_outlined, 'Músicas'),
                    _abaCategoria(theme, TipoFeedSocial.escritos, Icons.article_outlined, 'Escrito'),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.25)),
            ],

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ETAPA 0: Mídia, Enquadramento e Música
                    if (_etapa == 0 && _tipo != TipoFeedSocial.escritos) ...[
                      _buildAreaSelecaoMidia(theme),
                      if (_tipo == TipoFeedSocial.fotos) ...[
                        const SizedBox(height: 14),
                        _buildSeletorFormatoVisual(theme),
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

                    // ETAPA 1 (ou Escrito direto): Descrição, Colaboradores e Download
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
                                  alignment:
                                      Alignment(_alinhamentoX, _alinhamentoY),
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
                            ? 'Escreva sua publicação...'
                            : 'Escreva uma legenda ou #tags...',
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: theme.borderColor.withValues(alpha: 0.3),
                      ),

                    // Linha: Marcar colaboradores
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: theme.textColor,
                        size: 20,
                      ),
                      title: Text(
                        'Marcar colaboradores',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                      subtitle: _coautoresSelecionados.isNotEmpty
                          ? Text(
                              '${_coautoresSelecionados.length} selecionado(s)',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        _mostrarBuscaColab
                            ? Icons.expand_less_rounded
                            : Icons.chevron_right_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onTap: () => setState(
                        () => _mostrarBuscaColab = !_mostrarBuscaColab,
                      ),
                    ),

                    if (_mostrarBuscaColab) ...[
                      ThemedTextField(
                        theme: theme,
                        controller: _buscaCoautorCtrl,
                        label: 'Buscar usuário por nome ou @',
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_coautoresSelecionados.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _coautoresSelecionados.map((u) {
                            return Chip(
                              label: Text(
                                u.nomeExibicao,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.textColor,
                                ),
                              ),
                              onDeleted: () => setState(
                                () => _coautoresSelecionados.remove(u),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (sugestoesCoautor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: sugestoesCoautor.map((u) {
                            final jaTem = _coautoresSelecionados.any(
                              (c) => c.cpf == u.cpf,
                            );
                            return ActionChip(
                              label: Text(
                                '${jaTem ? "✓ " : "+ "}${u.nomeExibicao}',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.textColor,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (jaTem) {
                                    _coautoresSelecionados
                                        .removeWhere((c) => c.cpf == u.cpf);
                                  } else {
                                    _coautoresSelecionados.add(u);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],

                    // Linha: Permitir download
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

            // Botão claro e visível: Avançar (Etapa 0) ou Publicar (Etapa 1 / Escrito)
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
                        if (_etapa == 0 && _tipo != TipoFeedSocial.escritos) {
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

  Widget _abaCategoria(
    AppTheme theme,
    TipoFeedSocial tipo,
    IconData icone,
    String tooltip,
  ) {
    final ativo = _tipo == tipo;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _tipo = tipo;
            _arquivosSelecionados.clear();
            _erro = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ativo ? theme.textColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icone,
            size: 21,
            color: ativo ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaSelecaoMidia(AppTheme theme) {
    final ehFotoOuVideo =
        _tipo == TipoFeedSocial.fotos || _tipo == TipoFeedSocial.videos;

    if (_arquivosSelecionados.isEmpty) {
      final IconData icone;
      final String titulo;
      final String subtitulo;
      switch (_tipo) {
        case TipoFeedSocial.fotos:
          icone = Icons.add_photo_alternate_outlined;
          titulo = 'Selecionar fotos';
          subtitulo = 'Toque para escolher uma ou várias imagens';
          break;
        case TipoFeedSocial.videos:
          icone = Icons.video_call_outlined;
          titulo = 'Selecionar vídeo';
          subtitulo = 'Toque para escolher o vídeo da galeria';
          break;
        case TipoFeedSocial.musicas:
          icone = Icons.library_music_outlined;
          titulo = 'Selecionar música ou áudio';
          subtitulo = 'MP3, WAV, M4A, OGG ou FLAC';
          break;
        default:
          icone = Icons.upload_file_outlined;
          titulo = 'Selecionar documento';
          subtitulo = 'PDF, planilhas, textos ou arquivos';
          break;
      }

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _selecionarArquivos,
        child: Container(
          height: ehFotoOuVideo ? 220 : 130,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icone,
                  size: ehFotoOuVideo ? 46 : 34,
                  color: theme.buttonColor,
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
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
      );
    }

    // Prévia quando há arquivos selecionados
    if (_tipo == TipoFeedSocial.fotos) {
      if (_indiceFotoPreview >= _arquivosSelecionados.length) {
        _indiceFotoPreview = 0;
      }
      return EditorFotosCarrosselWidget(
        theme: theme,
        arquivos: _arquivosSelecionados,
        indiceAtivo: _indiceFotoPreview,
        aspectRatio: _obterAspectRatioPrevia(),
        alinhamentoX: _alinhamentoX,
        alinhamentoY: _alinhamentoY,
        escalaZoom: _escalaZoom,
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
              _indiceFotoPreview =
                  (_arquivosSelecionados.length - 1).clamp(0, 99);
            }
          });
        },
        onAtualizarAjuste: (x, y, zoom) {
          setState(() {
            _alinhamentoX = x;
            _alinhamentoY = y;
            _escalaZoom = zoom;
            _ajustesPorFoto[_indiceFotoPreview] = (
              x: x,
              y: y,
              zoom: zoom,
            );
          });
        },
        onScaleStart: () {
          _zoomBaseGestos = _escalaZoom;
        },
        onScaleUpdate: (details) {
          setState(() {
            if (details.scale != 1.0) {
              _escalaZoom = (_zoomBaseGestos * details.scale).clamp(1.0, 3.0);
            }
            _alinhamentoX =
                (_alinhamentoX - details.focalPointDelta.dx / 110)
                    .clamp(-1.0, 1.0);
            _alinhamentoY =
                (_alinhamentoY - details.focalPointDelta.dy / 110)
                    .clamp(-1.0, 1.0);
            _ajustesPorFoto[_indiceFotoPreview] = (
              x: _alinhamentoX,
              y: _alinhamentoY,
              zoom: _escalaZoom,
            );
          });
        },
        onAdicionarMais: _selecionarArquivos,
        onLimparTudo: () => setState(() {
          _arquivosSelecionados.clear();
          _ajustesPorFoto.clear();
          _indiceFotoPreview = 0;
        }),
      );
    }

    // Prévia para Vídeos, Músicas e Documentos
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _arquivosSelecionados.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _tipo == TipoFeedSocial.videos
                    ? Icons.play_circle_fill_rounded
                    : _tipo == TipoFeedSocial.musicas
                        ? Icons.music_note_rounded
                        : Icons.description_rounded,
                color: theme.buttonColor,
                size: 28,
              ),
              title: Text(
                _arquivosSelecionados[i].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18, color: theme.dangerColor),
                onPressed: () =>
                    setState(() => _arquivosSelecionados.removeAt(i)),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _selecionarArquivos,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar outro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorFormatoVisual(AppTheme theme) {
    final opcoes = <(PadraoExibicaoMidia, IconData, String)>[
      (PadraoExibicaoMidia.original, Icons.crop_free_rounded, 'Original'),
      (PadraoExibicaoMidia.quadrado1x1, Icons.crop_square_rounded, '1:1'),
      (PadraoExibicaoMidia.retrato4x5, Icons.crop_portrait_rounded, '4:5'),
      (PadraoExibicaoMidia.paisagem16x9, Icons.crop_16_9_rounded, '16:9'),
      (PadraoExibicaoMidia.vertical9x16, Icons.smartphone_rounded, '9:16'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enquadramento',
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opcoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (padrao, icone, rotulo) = opcoes[i];
              final ativo = _padrao == padrao;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _padrao = padrao),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: ativo
                        ? theme.buttonColor
                        : theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ativo
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.5),
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icone,
                        size: 18,
                        color: ativo ? theme.buttonTextColor : theme.textColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rotulo,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              ativo ? FontWeight.bold : FontWeight.normal,
                          color:
                              ativo ? theme.buttonTextColor : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
