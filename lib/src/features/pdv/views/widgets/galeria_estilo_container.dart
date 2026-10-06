import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

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

  const GaleriaEstiloContainer({
    super.key,
    required this.theme,
    required this.titulo,
    this.itens = const [],
    this.tipo = TipoAnexoLoja.galeria,
    required this.onAdicionar,
    required this.onRemover,
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
  }

  String _extrairNomeArquivo(String caminho) {
    final partes = caminho.replaceAll(r'\', '/').split('/');
    return partes.isNotEmpty ? partes.last : 'Arquivo';
  }

  Widget _buildCardAdicionar(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selecionarArquivo(context),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 28,
                color: theme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index, String caminho) {
    final nomeArquivo = _extrairNomeArquivo(caminho);
    final ehImagem = tipo == TipoAnexoLoja.galeria &&
        ImagemService.extensaoImagemValida(caminho);

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ehImagem
                  ? Image.file(
                      File(caminho),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          _iconeDoTipo(),
                          size: 28,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _iconeDoTipo(),
                            size: 28,
                            color: theme.secondaryTextColor,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: TextoRolante(
                              texto: nomeArquivo,
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemover(index),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
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
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itens.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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