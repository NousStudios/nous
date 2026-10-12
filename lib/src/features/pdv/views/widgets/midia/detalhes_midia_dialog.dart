import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/widgets/reprodutor_audio_widget.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/editar_descricao_dialog.dart';

class DetalhesMidiaDialog extends StatefulWidget {
  final AppTheme theme;
  final String caminho;
  final List<String> itens;
  final int indiceInicial;
  final TipoAnexoLoja tipo;
  final Map<String, String> descricoes;
  final String descricao;
  final ValueChanged<String>? onSalvarDescricao;
  final void Function(String caminho, String novaDescricao)? onAtualizarDescricao;
  final ValueChanged<int>? onRemoverIndice;
  final VoidCallback? onRemover;

  const DetalhesMidiaDialog({
    super.key,
    required this.theme,
    required this.caminho,
    this.itens = const [],
    this.indiceInicial = 0,
    required this.tipo,
    this.descricoes = const {},
    this.descricao = '',
    this.onSalvarDescricao,
    this.onAtualizarDescricao,
    this.onRemoverIndice,
    this.onRemover,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String caminho,
    List<String> itens = const [],
    int indiceInicial = 0,
    required TipoAnexoLoja tipo,
    Map<String, String> descricoes = const {},
    String descricao = '',
    ValueChanged<String>? onSalvarDescricao,
    void Function(String caminho, String novaDescricao)? onAtualizarDescricao,
    ValueChanged<int>? onRemoverIndice,
    VoidCallback? onRemover,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => DetalhesMidiaDialog(
        theme: theme,
        caminho: caminho,
        itens: itens,
        indiceInicial: indiceInicial,
        tipo: tipo,
        descricoes: descricoes,
        descricao: descricao,
        onSalvarDescricao: onSalvarDescricao,
        onAtualizarDescricao: onAtualizarDescricao,
        onRemoverIndice: onRemoverIndice,
        onRemover: onRemover,
      ),
    );
  }

  @override
  State<DetalhesMidiaDialog> createState() => _DetalhesMidiaDialogState();
}

class _DetalhesMidiaDialogState extends State<DetalhesMidiaDialog> {
  late List<String> _itens;
  late int _indiceAtual;
  late Map<String, String> _descricoesLocais;

  @override
  void initState() {
    super.initState();
    _itens = widget.itens.isNotEmpty
        ? List<String>.from(widget.itens)
        : [widget.caminho];
    final idx = widget.itens.isNotEmpty
        ? widget.indiceInicial
        : _itens.indexOf(widget.caminho);
    _indiceAtual = idx.clamp(0, _itens.isNotEmpty ? _itens.length - 1 : 0);
    _descricoesLocais = Map<String, String>.from(widget.descricoes);
    if (widget.descricao.isNotEmpty &&
        !_descricoesLocais.containsKey(widget.caminho)) {
      _descricoesLocais[widget.caminho] = widget.descricao;
    }
  }

  String get _caminhoAtual =>
      _itens.isNotEmpty ? _itens[_indiceAtual] : widget.caminho;

  String get _descricaoAtual => _descricoesLocais[_caminhoAtual] ?? '';

  @override
  void dispose() {
    if (widget.tipo == TipoAnexoLoja.musicas ||
        widget.tipo == TipoAnexoLoja.arquivosAudio) {
      if (PlayerAudioService.instancia.estadoAtual.caminho == _caminhoAtual) {
        PlayerAudioService.instancia.parar();
      }
    }
    super.dispose();
  }

  void _irParaAnterior() {
    if (_indiceAtual > 0) {
      final tocando = PlayerAudioService.instancia.estadoAtual.caminho ==
              _caminhoAtual &&
          PlayerAudioService.instancia.estadoAtual.estado ==
              EstadoPlayerAudio.reproduzindo;
      setState(() => _indiceAtual--);
      if (tocando) {
        PlayerAudioService.instancia.tocar(_caminhoAtual);
      }
    }
  }

  void _irParaProximo() {
    if (_indiceAtual < _itens.length - 1) {
      final tocando = PlayerAudioService.instancia.estadoAtual.caminho ==
              _caminhoAtual &&
          PlayerAudioService.instancia.estadoAtual.estado ==
              EstadoPlayerAudio.reproduzindo;
      setState(() => _indiceAtual++);
      if (tocando) {
        PlayerAudioService.instancia.tocar(_caminhoAtual);
      }
    }
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
    final arquivo = File(_caminhoAtual);
    if (!arquivo.existsSync()) return 'Arquivo não localizado';
    try {
      final tamanho = arquivo.lengthSync();
      return ImagemService.formatarTamanhoBytes(tamanho);
    } catch (_) {
      return '';
    }
  }

  Future<void> _reproduzirNoSistema() async {
    final sucesso = await ImagemService.abrirNoSistema(_caminhoAtual);
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
    final nomeArquivo = _extrairNomeArquivo(_caminhoAtual);
    await EditarDescricaoDialog.mostrar(
      context,
      theme: widget.theme,
      nomeArquivo: nomeArquivo,
      descricaoInicial: _descricaoAtual,
      onSalvar: (novaDescricao) {
        setState(() => _descricoesLocais[_caminhoAtual] = novaDescricao);
        widget.onAtualizarDescricao?.call(_caminhoAtual, novaDescricao);
        widget.onSalvarDescricao?.call(novaDescricao);
      },
    );
  }

  void _removerItemAtual() {
    final indiceParaRemover = _indiceAtual;
    widget.onRemoverIndice?.call(indiceParaRemover);
    widget.onRemover?.call();

    if (_itens.length <= 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _itens.removeAt(indiceParaRemover);
      if (_indiceAtual >= _itens.length) {
        _indiceAtual = _itens.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final total = _itens.length;
    final nomeArquivo = _extrairNomeArquivo(_caminhoAtual);
    final tamanhoTexto = _obterTamanhoArquivo();
    final ehMidiaReprodutivel = widget.tipo == TipoAnexoLoja.musicas ||
        widget.tipo == TipoAnexoLoja.videos ||
        widget.tipo == TipoAnexoLoja.arquivosAudio;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _irParaAnterior,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _irParaProximo,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        // Topo com indicador de páginas, ícone e fechar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color:
                                    theme.backgroundColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      theme.borderColor.withValues(alpha: 0.6),
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
                                  Row(
                                    children: [
                                      Text(
                                        _rotuloDoTipo(),
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                      if (total > 1) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.backgroundColor
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: theme.borderColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Text(
                                            '${_indiceAtual + 1} / $total',
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                              icon: Icon(Icons.close,
                                  color: theme.textColor, size: 20),
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
                const SizedBox(height: 18),

                // Player Interno para Áudios e Músicas
                if (widget.tipo == TipoAnexoLoja.musicas ||
                    widget.tipo == TipoAnexoLoja.arquivosAudio) ...[
                  ReprodutorAudioWidget(
                    theme: theme,
                    caminho: _caminhoAtual,
                    tituloPadrao: _descricaoAtual.isNotEmpty
                        ? _descricaoAtual
                        : null,
                    onAnterior: _indiceAtual > 0 ? _irParaAnterior : null,
                    onProximo: _indiceAtual < total - 1 ? _irParaProximo : null,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.secondaryTextColor,
                      side: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: theme.secondaryTextColor,
                    ),
                    label: Text(
                      'Abrir no Reprodutor do Windows',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    onPressed: _reproduzirNoSistema,
                  ),
                ] else ...[
                  // Arquivo de vídeo ou documento comum
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
                          ? 'Reproduzir Vídeo no Reprodutor do Sistema'
                          : 'Abrir Arquivo no Computador',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.buttonTextColor,
                      ),
                    ),
                    onPressed: _reproduzirNoSistema,
                  ),
                ],
                const SizedBox(height: 10),

                // Botão Fechar e Excluir
                Row(
                  children: [
                    if (widget.onRemover != null ||
                        widget.onRemoverIndice != null) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(
                          'Remover Anexo',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                          ),
                        ),
                        onPressed: _removerItemAtual,
                      ),
                      const Spacer(),
                    ],
                    Expanded(
                      flex: (widget.onRemover != null ||
                              widget.onRemoverIndice != null)
                          ? 0
                          : 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Botão Flutuante Anterior (Esquerda)
        if (total > 1 && _indiceAtual > 0)
          Positioned(
            left: -4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _irParaAnterior,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ),

        // Botão Flutuante Próximo (Direita)
        if (total > 1 && _indiceAtual < total - 1)
          Positioned(
            right: -4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _irParaProximo,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: theme.textColor,
                  ),
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
