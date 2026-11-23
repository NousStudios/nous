import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Visualizador interno de documentos (textos, markdown, csv, json, logs e
/// cartão detalhado com abertura direta para PDFs e planilhas).
class DialogVisualizarDocumento extends StatefulWidget {
  final AppTheme theme;
  final String caminho;
  final String nomeArquivo;
  final int tamanhoBytes;

  const DialogVisualizarDocumento({
    super.key,
    required this.theme,
    required this.caminho,
    this.nomeArquivo = '',
    this.tamanhoBytes = 0,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String caminho,
    String nomeArquivo = '',
    int tamanhoBytes = 0,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogVisualizarDocumento(
        theme: theme,
        caminho: caminho,
        nomeArquivo: nomeArquivo,
        tamanhoBytes: tamanhoBytes,
      ),
    );
  }

  @override
  State<DialogVisualizarDocumento> createState() =>
      _DialogVisualizarDocumentoState();
}

class _DialogVisualizarDocumentoState extends State<DialogVisualizarDocumento> {
  String? _conteudoTexto;
  bool _carregando = true;
  bool _ehTextoLegivel = false;

  static const _extTexto = {
    'txt',
    'md',
    'csv',
    'json',
    'log',
    'xml',
    'yaml',
    'yml',
    'dart',
    'sql',
    'ini',
  };

  String get _ext {
    final nome = widget.nomeArquivo.isNotEmpty
        ? widget.nomeArquivo
        : widget.caminho;
    return p.extension(nome).replaceAll('.', '').toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final ext = _ext;
    if (_extTexto.contains(ext)) {
      try {
        final f = File(widget.caminho);
        if (await f.exists()) {
          final txt = await f.readAsString();
          if (mounted) {
            setState(() {
              _conteudoTexto = txt;
              _ehTextoLegivel = true;
              _carregando = false;
            });
            return;
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  String _formatarTamanho(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _abrirExterno() async {
    try {
      final abriu = await launchUrl(
        Uri.file(widget.caminho),
        mode: LaunchMode.externalApplication,
      );
      if (!abriu && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o arquivo neste aparelho.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o documento.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final nome = widget.nomeArquivo.isNotEmpty
        ? widget.nomeArquivo
        : p.basename(widget.caminho);
    final extUpper = _ext.isNotEmpty ? _ext.toUpperCase() : 'DOC';
    final tam = _formatarTamanho(widget.tamanhoBytes);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 660,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 68),
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_ehTextoLegivel && _conteudoTexto != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Copiar conteúdo',
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: theme.textColor,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _conteudoTexto!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Texto copiado!'),
                                ),
                              );
                            },
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Abrir fora do Nous',
                          icon: Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: theme.buttonColor,
                          ),
                          onPressed: _abrirExterno,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.secondaryTextColor,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
            if (_carregando)
              Padding(
                padding: const EdgeInsets.all(36),
                child: Center(
                  child: CircularProgressIndicator(color: theme.buttonColor),
                ),
              )
            else if (_ehTextoLegivel && _conteudoTexto != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _conteudoTexto!,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.buttonColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.buttonColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 30,
                            color: theme.buttonColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            extUpper,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nome,
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (tam.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$extUpper • $tam',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _abrirExterno,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        'Abrir $extUpper',
                        style: theme.getTextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonTextColor,
                        ),
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
