import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/editar_descricao_dialog.dart';

class DetalhesMidiaDialog extends StatefulWidget {
  final AppTheme theme;
  final String caminho;
  final TipoAnexoLoja tipo;
  final String descricao;
  final ValueChanged<String> onSalvarDescricao;
  final VoidCallback? onRemover;

  const DetalhesMidiaDialog({
    super.key,
    required this.theme,
    required this.caminho,
    required this.tipo,
    required this.descricao,
    required this.onSalvarDescricao,
    this.onRemover,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String caminho,
    required TipoAnexoLoja tipo,
    required String descricao,
    required ValueChanged<String> onSalvarDescricao,
    VoidCallback? onRemover,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => DetalhesMidiaDialog(
        theme: theme,
        caminho: caminho,
        tipo: tipo,
        descricao: descricao,
        onSalvarDescricao: onSalvarDescricao,
        onRemover: onRemover,
      ),
    );
  }

  @override
  State<DetalhesMidiaDialog> createState() => _DetalhesMidiaDialogState();
}

class _DetalhesMidiaDialogState extends State<DetalhesMidiaDialog> {
  late String _descricaoAtual;

  @override
  void initState() {
    super.initState();
    _descricaoAtual = widget.descricao;
  }

  String _extrairNomeArquivo(String caminho) {
    final partes = caminho.replaceAll(r'\', '/').split('/');
    return partes.isNotEmpty ? partes.last : 'Arquivo';
  }

  IconData _iconeDoTipo() {
    switch (widget.tipo) {
      case TipoAnexoLoja.galeria:
        return Icons.image_outlined;
      case TipoAnexoLoja.arquivos:
        return Icons.insert_drive_file_outlined;
      case TipoAnexoLoja.musicas:
        return Icons.music_note_outlined;
      case TipoAnexoLoja.videos:
        return Icons.videocam_outlined;
      case TipoAnexoLoja.arquivosAudio:
        return Icons.audiotrack_outlined;
    }
  }

  String _rotuloDoTipo() {
    switch (widget.tipo) {
      case TipoAnexoLoja.galeria:
        return 'Imagem';
      case TipoAnexoLoja.arquivos:
        return 'Documento / Arquivo';
      case TipoAnexoLoja.musicas:
        return 'Música';
      case TipoAnexoLoja.videos:
        return 'Vídeo';
      case TipoAnexoLoja.arquivosAudio:
        return 'Arquivo de Áudio';
    }
  }

  String _obterTamanhoArquivo() {
    final arquivo = File(widget.caminho);
    if (!arquivo.existsSync()) return 'Arquivo não localizado';
    try {
      final tamanho = arquivo.lengthSync();
      return ImagemService.formatarTamanhoBytes(tamanho);
    } catch (_) {
      return '';
    }
  }

  Future<void> _reproduzirNoSistema() async {
    final sucesso = await ImagemService.abrirNoSistema(widget.caminho);
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.cardBackgroundColor,
          content: Text(
            'Não foi possível abrir o arquivo no sistema operacional.',
            style: widget.theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
  }

  Future<void> _editarDescricao() async {
    final nomeArquivo = _extrairNomeArquivo(widget.caminho);
    await EditarDescricaoDialog.mostrar(
      context,
      theme: widget.theme,
      nomeArquivo: nomeArquivo,
      descricaoInicial: _descricaoAtual,
      onSalvar: (novaDescricao) {
        setState(() => _descricaoAtual = novaDescricao);
        widget.onSalvarDescricao(novaDescricao);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final nomeArquivo = _extrairNomeArquivo(widget.caminho);
    final tamanhoTexto = _obterTamanhoArquivo();
    final ehMidiaReprodutivel = widget.tipo == TipoAnexoLoja.musicas ||
        widget.tipo == TipoAnexoLoja.videos ||
        widget.tipo == TipoAnexoLoja.arquivosAudio;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo com ícone e fechar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(
                        _iconeDoTipo(),
                        size: 28,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rotuloDoTipo(),
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nomeArquivo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          if (tamanhoTexto.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              tamanhoTexto,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textColor, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bloco de Descrição
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descrição / Legenda',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          InkWell(
                            onTap: _editarDescricao,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: theme.textColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _descricaoAtual.isEmpty ? 'Adicionar' : 'Editar',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _descricaoAtual.isNotEmpty
                            ? _descricaoAtual
                            : 'Nenhuma descrição adicionada para este arquivo.',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: _descricaoAtual.isNotEmpty
                              ? theme.textColor
                              : theme.secondaryTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Botão de Ação Principal: Reproduzir no Sistema ou Abrir
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    ehMidiaReprodutivel
                        ? Icons.play_circle_outline_rounded
                        : Icons.open_in_new_rounded,
                    size: 20,
                    color: theme.buttonTextColor,
                  ),
                  label: Text(
                    ehMidiaReprodutivel
                        ? 'Reproduzir no Reprodutor do Sistema'
                        : 'Abrir Arquivo no Computador',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.buttonTextColor,
                    ),
                  ),
                  onPressed: _reproduzirNoSistema,
                ),
                const SizedBox(height: 10),

                // Botão Fechar
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Fechar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
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
