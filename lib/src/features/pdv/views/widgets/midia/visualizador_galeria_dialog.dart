import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/editar_descricao_dialog.dart';

class VisualizadorGaleriaDialog extends StatefulWidget {
  final AppTheme theme;
  final List<String> imagens;
  final int indiceInicial;
  final Map<String, String> descricoes;
  final void Function(String caminho, String novaDescricao)? onSalvarDescricao;

  const VisualizadorGaleriaDialog({
    super.key,
    required this.theme,
    required this.imagens,
    required this.indiceInicial,
    this.descricoes = const {},
    this.onSalvarDescricao,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<String> imagens,
    required int indiceInicial,
    Map<String, String> descricoes = const {},
    void Function(String caminho, String novaDescricao)? onSalvarDescricao,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => VisualizadorGaleriaDialog(
        theme: theme,
        imagens: imagens,
        indiceInicial: indiceInicial,
        descricoes: descricoes,
        onSalvarDescricao: onSalvarDescricao,
      ),
    );
  }

  @override
  State<VisualizadorGaleriaDialog> createState() =>
      _VisualizadorGaleriaDialogState();
}

class _VisualizadorGaleriaDialogState extends State<VisualizadorGaleriaDialog> {
  late final PageController _pageController;
  late int _indiceAtual;
  late Map<String, String> _descricoesLocais;

  @override
  void initState() {
    super.initState();
    _indiceAtual = widget.indiceInicial.clamp(0, widget.imagens.length - 1);
    _pageController = PageController(initialPage: _indiceAtual);
    _descricoesLocais = Map<String, String>.from(widget.descricoes);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irParaAnterior() {
    if (_indiceAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _irParaProximo() {
    if (_indiceAtual < widget.imagens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _extrairNomeArquivo(String caminho) {
    final partes = caminho.replaceAll(r'\', '/').split('/');
    return partes.isNotEmpty ? partes.last : 'Imagem';
  }

  Future<void> _editarDescricao() async {
    if (widget.imagens.isEmpty) return;
    final caminhoAtual = widget.imagens[_indiceAtual];
    final nomeArquivo = _extrairNomeArquivo(caminhoAtual);
    final descricaoAtual = _descricoesLocais[caminhoAtual] ?? '';

    await EditarDescricaoDialog.mostrar(
      context,
      theme: widget.theme,
      nomeArquivo: nomeArquivo,
      descricaoInicial: descricaoAtual,
      onSalvar: (novaDescricao) {
        setState(() {
          _descricoesLocais[caminhoAtual] = novaDescricao;
        });
        widget.onSalvarDescricao?.call(caminhoAtual, novaDescricao);
      },
    );
  }

  Future<void> _abrirNoWindows() async {
    if (widget.imagens.isEmpty) return;
    final caminhoAtual = widget.imagens[_indiceAtual];
    final sucesso = await ImagemService.abrirNoSistema(caminhoAtual);
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.cardBackgroundColor,
          content: Text(
            'Arquivo de imagem não encontrado no disco.',
            style: widget.theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    if (widget.imagens.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Nenhuma imagem disponível.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
    }

    final caminhoAtual = widget.imagens[_indiceAtual];
    final nomeArquivoAtual = _extrairNomeArquivo(caminhoAtual);
    final descricaoAtual = _descricoesLocais[caminhoAtual] ?? '';
    final total = widget.imagens.length;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _irParaAnterior();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _irParaProximo();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: theme.backgroundColor.withValues(alpha: 0.96),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Área Principal com PageView
              Column(
                children: [
                  // Barra Superior
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor.withValues(alpha: 0.9),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            '${_indiceAtual + 1} / $total',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nomeArquivoAtual,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Abrir no Visualizador do Sistema',
                          icon: Icon(
                            Icons.open_in_new,
                            color: theme.textColor,
                            size: 18,
                          ),
                          onPressed: _abrirNoWindows,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Fechar (Esc)',
                          icon: Icon(
                            Icons.close,
                            color: theme.textColor,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Imagem com Zoom
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: total,
                      onPageChanged: (index) {
                        setState(() => _indiceAtual = index);
                      },
                      itemBuilder: (context, index) {
                        final caminho = widget.imagens[index];
                        final arquivo = File(caminho);

                        if (!arquivo.existsSync()) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: theme.secondaryTextColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Arquivo não encontrado no disco.',
                                  style: theme.getTextStyle(
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 5.0,
                          child: Center(
                            child: Image.file(
                              arquivo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Barra Inferior (Descrição e Legenda)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor.withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Descrição',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                descricaoAtual.isNotEmpty
                                    ? descricaoAtual
                                    : 'Nenhuma descrição adicionada.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: descricaoAtual.isNotEmpty
                                      ? theme.textColor
                                      : theme.secondaryTextColor
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          icon: Icon(
                            Icons.edit_note,
                            size: 18,
                            color: theme.textColor,
                          ),
                          label: Text(
                            descricaoAtual.isEmpty
                                ? 'Adicionar Descrição'
                                : 'Editar Legenda',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          onPressed: _editarDescricao,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Botão Anterior Flutuante
              if (total > 1 && _indiceAtual > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 54, // acima do rodapé
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _irParaAnterior,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor
                                .withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 28,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Botão Próximo Flutuante
              if (total > 1 && _indiceAtual < total - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 54, // acima do rodapé
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _irParaProximo,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor
                                .withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 28,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
