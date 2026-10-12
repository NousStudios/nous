import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/detalhes_midia_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/editar_descricao_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/visualizador_galeria_dialog.dart';

enum TipoAnexoLoja {
  galeria,
  arquivos,
  musicas,
  videos,
  arquivosAudio,
}

class GaleriaEstiloContainer extends StatelessWidget {
  final AppTheme theme;
  final String titulo;
  final List<String> itens;
  final TipoAnexoLoja tipo;
  final ValueChanged<String> onAdicionar;
  final ValueChanged<int> onRemover;
  final Map<String, String> descricoes;
  final void Function(String caminho, String novaDescricao)? onAtualizarDescricao;

  const GaleriaEstiloContainer({
    super.key,
    required this.theme,
    required this.titulo,
    this.itens = const [],
    this.tipo = TipoAnexoLoja.galeria,
    required this.onAdicionar,
    required this.onRemover,
    this.descricoes = const {},
    this.onAtualizarDescricao,
  });

  IconData _iconeDoTipo() {
    switch (tipo) {
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

  XTypeGroup _extensoesDoTipo() {
    switch (tipo) {
      case TipoAnexoLoja.galeria:
        return const XTypeGroup(
          label: 'Imagens',
          extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
        );
      case TipoAnexoLoja.arquivos:
        return const XTypeGroup(
          label: 'Documentos',
          extensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'rar'],
        );
      case TipoAnexoLoja.musicas:
        return const XTypeGroup(
          label: 'Músicas',
          extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'],
        );
      case TipoAnexoLoja.videos:
        return const XTypeGroup(
          label: 'Vídeos',
          extensions: ['mp4', 'mkv', 'mov', 'avi', 'webm'],
        );
      case TipoAnexoLoja.arquivosAudio:
        return const XTypeGroup(
          label: 'Áudios',
          extensions: ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'wma'],
        );
    }
  }

  Future<void> _selecionarArquivo(BuildContext context) async {
    final grupo = _extensoesDoTipo();
    final arquivos = await openFiles(acceptedTypeGroups: [grupo]);
    if (arquivos.isEmpty) return;

    var bloqueadosPorTamanho = 0;
    final salvos = <String>[];

    for (final arq in arquivos) {
      final arquivoFisico = File(arq.path);
      if (!await arquivoFisico.exists()) continue;

      final tamanho = await arquivoFisico.length();
      if (tamanho > ImagemService.limiteBytesMeioGiga) {
        bloqueadosPorTamanho++;
        continue;
      }

      final salvo = await ImagemService.salvarAnexoLocal(arq.path, tipo.name);
      if (salvo != null) {
        onAdicionar(salvo);
        salvos.add(salvo);
      }
    }

    if (bloqueadosPorTamanho > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            '$bloqueadosPorTamanho arquivo(s) não foram enviados por ultrapassar o limite de meio giga (500MB).',
            style: theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    // Se adicionou 1 arquivo, convida o usuário a adicionar uma descrição opcional
    if (salvos.length == 1 && context.mounted) {
      final salvo = salvos.first;
      await EditarDescricaoDialog.mostrar(
        context,
        theme: theme,
        nomeArquivo: _extrairNomeArquivo(salvo),
        descricaoInicial: '',
        onSalvar: (desc) {
          if (desc.isNotEmpty) {
            onAtualizarDescricao?.call(salvo, desc);
          }
        },
      );
    }
  }

  String _extrairNomeArquivo(String caminho) {
    final partes = caminho.replaceAll(r'\', '/').split('/');
    return partes.isNotEmpty ? partes.last : 'Arquivo';
  }

  String _extrairExtensao(String caminho) {
    try {
      final partes = caminho.split('.');
      if (partes.length > 1) {
        return partes.last.toUpperCase();
      }
    } catch (_) {}
    return '';
  }

  String _obterTamanhoFormatado(String caminho) {
    try {
      final arq = File(caminho);
      if (arq.existsSync()) {
        return ImagemService.formatarTamanhoBytes(arq.lengthSync());
      }
    } catch (_) {}
    return '';
  }

  void _abrirItem(BuildContext context, int index, String caminho) {
    final ehImagem = tipo == TipoAnexoLoja.galeria ||
        ImagemService.extensaoImagemValida(caminho);

    if (ehImagem) {
      VisualizadorGaleriaDialog.mostrar(
        context,
        theme: theme,
        imagens: itens,
        indiceInicial: index,
        descricoes: descricoes,
        onSalvarDescricao: onAtualizarDescricao,
      );
    } else {
      DetalhesMidiaDialog.mostrar(
        context,
        theme: theme,
        caminho: caminho,
        itens: itens,
        indiceInicial: index,
        tipo: tipo,
        descricoes: descricoes,
        descricao: descricoes[caminho] ?? '',
        onAtualizarDescricao: onAtualizarDescricao,
        onSalvarDescricao: (novaDescricao) {
          onAtualizarDescricao?.call(caminho, novaDescricao);
        },
        onRemoverIndice: onRemover,
        onRemover: () => onRemover(index),
      );
    }
  }

  Widget _buildCardAdicionar(BuildContext context) {
    return Container(
      width: 126,
      height: 156,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selecionarArquivo(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adicionar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Novo arquivo',
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviaVisual(String caminho, MetadadosAudio? metaAudio) {
    final ehImagem = tipo == TipoAnexoLoja.galeria ||
        ImagemService.extensaoImagemValida(caminho);
    final ext = _extrairExtensao(caminho);

    if (ehImagem) {
      return Image.file(
        File(caminho),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            _iconeDoTipo(),
            size: 32,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    if (tipo == TipoAnexoLoja.musicas ||
        tipo == TipoAnexoLoja.arquivosAudio) {
      if (metaAudio?.temCapa == true) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              metaAudio!.capaBytes!,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.buttonColor.withValues(alpha: 0.25),
              theme.backgroundColor.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 36,
                color: theme.buttonColor,
              ),
              if (ext.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    ext,
                    style: theme.getTextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (tipo == TipoAnexoLoja.videos) {
      return Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_display_rounded,
                size: 36,
                color: theme.buttonColor,
              ),
              if (ext.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext,
                    style: theme.getTextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Documentos / Arquivos em Geral
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconeDoTipo(),
              size: 36,
              color: theme.textColor,
            ),
            if (ext.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  ext,
                  style: theme.getTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index, String caminho) {
    final nomeArquivo = _extrairNomeArquivo(caminho);
    final temDescricao = (descricoes[caminho] ?? '').isNotEmpty;
    final tamanhoTexto = _obterTamanhoFormatado(caminho);

    MetadadosAudio? metaAudio;
    if (tipo == TipoAnexoLoja.musicas ||
        tipo == TipoAnexoLoja.arquivosAudio) {
      metaAudio = MetadadosAudioService.extrair(caminho);
    }

    final tituloExibido = (metaAudio?.titulo?.trim().isNotEmpty == true)
        ? metaAudio!.titulo!
        : nomeArquivo;
    final subtituloExibido = (metaAudio?.artista?.trim().isNotEmpty == true)
        ? metaAudio!.artista!
        : (tamanhoTexto.isNotEmpty ? tamanhoTexto : '');

    return Container(
      width: 126,
      height: 156,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _abrirItem(context, index, caminho),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Área Visual Superior (Prévia com 96px)
                    Expanded(
                      flex: 6,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        child: _buildPreviaVisual(caminho, metaAudio),
                      ),
                    ),

                    // Área Textual Inferior (Legível com fundo contrastante)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        color: theme.backgroundColor.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tituloExibido,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            if (subtituloExibido.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtituloExibido,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de Descrição Existente
            if (temDescricao)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 11,
                    color: theme.textColor,
                  ),
                ),
              ),

            // Botão Excluir (X)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => onRemover(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 13,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itens.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == itens.length) {
                  return _buildCardAdicionar(context);
                }
                return _buildItemCard(context, index, itens[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}