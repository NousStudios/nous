import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/detalhes_midia_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/editar_descricao_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/galeria_item_card.dart';
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
  final void Function(int index, String novoCaminho)? onSubstituirItem;
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
    this.onSubstituirItem,
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
            style: theme.getTextStyle(color: theme.dangerColor),
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

  Future<void> _confirmarRemover(BuildContext context, int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Remover Anexo',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Tem certeza de que deseja retirar este anexo da galeria?',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Remover',
              style: theme.getTextStyle(
                color: theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      onRemover(index);
    }
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
                  return GaleriaAdicionarCard(
                    theme: theme,
                    onTap: () => _selecionarArquivo(context),
                  );
                }
                final caminho = itens[index];
                return GaleriaItemCard(
                  theme: theme,
                  index: index,
                  caminho: caminho,
                  tipo: tipo,
                  iconeFallback: _iconeDoTipo(),
                  temDescricao: (descricoes[caminho] ?? '').isNotEmpty,
                  onAbrir: () => _abrirItem(context, index, caminho),
                  onConfirmarRemover: () => _confirmarRemover(context, index),
                  onSubstituirItem: onSubstituirItem,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}