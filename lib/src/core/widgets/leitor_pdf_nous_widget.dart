import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Leitor e gerador de prévia visual de PDFs nativo do Nous (via `printing`).
/// - No feed (`modoFeedPreview: true`), exibe a primeira página do PDF e abre a
///   janela da publicação ao tocar.
/// - Na janela da publicação (`modoFeedPreview: false`), renderiza todas as páginas
///   e alterna entre rolagem de publicações (layout normal) e rolagem das páginas
///   do PDF (modo Full Screen).
class LeitorPdfNousWidget extends StatefulWidget {
  final AppTheme theme;
  final String caminhoArquivo;
  final String nomeArquivo;
  final int tamanhoBytes;
  final bool modoFeedPreview;
  final bool modoFullScreen;
  final VoidCallback? onAbrirPublicacao;
  final ValueChanged<bool>? onAlternarFullScreen;

  const LeitorPdfNousWidget({
    super.key,
    required this.theme,
    required this.caminhoArquivo,
    this.nomeArquivo = '',
    this.tamanhoBytes = 0,
    this.modoFeedPreview = false,
    this.modoFullScreen = false,
    this.onAbrirPublicacao,
    this.onAlternarFullScreen,
  });

  @override
  State<LeitorPdfNousWidget> createState() => _LeitorPdfNousWidgetState();
}

class _LeitorPdfNousWidgetState extends State<LeitorPdfNousWidget> {
  static final Map<String, Uint8List> _cacheCapa = {};
  static final Map<String, List<Uint8List>> _cachePaginas = {};

  final ScrollController _scrollCtrl = ScrollController();
  List<Uint8List> _paginas = [];
  Uint8List? _capa;
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregarPdf();
  }

  @override
  void didUpdateWidget(covariant LeitorPdfNousWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caminhoArquivo != widget.caminhoArquivo ||
        oldWidget.modoFeedPreview != widget.modoFeedPreview) {
      _carregarPdf();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarPdf() async {
    final path = widget.caminhoArquivo;
    if (widget.modoFeedPreview) {
      final cache = _cacheCapa[path];
      if (cache != null) {
        if (mounted) {
          setState(() {
            _capa = cache;
            _carregando = false;
            _erro = false;
          });
        }
        return;
      }
    } else {
      final cacheTodas = _cachePaginas[path];
      if (cacheTodas != null && cacheTodas.isNotEmpty) {
        if (mounted) {
          setState(() {
            _paginas = cacheTodas;
            _carregando = false;
            _erro = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = false;
      });
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted) setState(() => _erro = true);
        return;
      }
      final bytes = await file.readAsBytes();

      if (widget.modoFeedPreview) {
        await for (final page in Printing.raster(bytes, pages: const [0], dpi: 140)) {
          final png = await page.toPng();
          _cacheCapa[path] = png;
          if (mounted) {
            setState(() {
              _capa = png;
              _carregando = false;
            });
          }
          break;
        }
        if (mounted && _capa == null) {
          setState(() => _carregando = false);
        }
        return;
      }

      final lista = <Uint8List>[];
      await for (final page in Printing.raster(bytes, dpi: 180)) {
        final png = await page.toPng();
        lista.add(png);
        if (mounted) {
          setState(() {
            _paginas = List<Uint8List>.from(lista);
            _carregando = false;
          });
        }
      }
      if (lista.isNotEmpty) {
        _cachePaginas[path] = lista;
        _cacheCapa[path] ??= lista.first;
      }
      if (mounted) setState(() => _carregando = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = true;
        });
      }
    }
  }

  String _formatarTamanho(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tam = _formatarTamanho(widget.tamanhoBytes);

    if (widget.modoFeedPreview) {
      return GestureDetector(
        onTap: widget.onAbrirPublicacao,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_capa != null)
                Flexible(
                  child: Container(
                    color: const Color(0xFFF7F7F7),
                    alignment: Alignment.center,
                    child: Image.memory(
                      _capa!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else if (_carregando)
                SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.buttonColor,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: Center(
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 40,
                      color: theme.buttonColor,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.9),
                  border: Border(
                    top: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: theme.buttonColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.nomeArquivo.isNotEmpty
                            ? widget.nomeArquivo
                            : 'Documento PDF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tam.isNotEmpty ? 'PDF • $tam' : 'PDF',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
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

    // Modo Leitor Completo (dentro da tela da Publicação)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: theme.backgroundColor.withValues(alpha: 0.8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_erro)
              Center(
                child: Text(
                  'Não foi possível renderizar este PDF.',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                ),
              )
            else if (_paginas.isEmpty && _carregando)
              Center(
                child: CircularProgressIndicator(color: theme.buttonColor),
              )
            else
              Scrollbar(
                controller: _scrollCtrl,
                thumbVisibility: widget.modoFullScreen,
                child: ListView.separated(
                  controller: _scrollCtrl,
                  physics: widget.modoFullScreen
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 44, 10, 14),
                  itemCount: _paginas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) => Center(
                    child: InteractiveViewer(
                      panEnabled: widget.modoFullScreen,
                      scaleEnabled: widget.modoFullScreen,
                      minScale: 1.0,
                      maxScale: 3.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          color: const Color(0xFFF7F7F7),
                          child: Image.memory(
                            _paginas[idx],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Barra flutuante superior: contador de páginas + botão Full Screen
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _paginas.isEmpty
                          ? 'Carregando PDF...'
                          : '${_paginas.length} ${_paginas.length == 1 ? 'página' : 'páginas'}${widget.modoFullScreen ? ' • Role para ler' : ''}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.onAlternarFullScreen != null)
                    IconButton(
                      tooltip: widget.modoFullScreen
                          ? 'Sair da tela cheia'
                          : 'Ler em tela cheia',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.cardBackgroundColor.withValues(alpha: 0.88),
                      ),
                      icon: Icon(
                        widget.modoFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        size: 20,
                        color: theme.textColor,
                      ),
                      onPressed: () =>
                          widget.onAlternarFullScreen!(!widget.modoFullScreen),
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
