import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

class ResultadoSelecaoArquivos {
  final List<XFile> arquivos;
  final TipoFeedSocial? tipoSugerido;
  final String? erro;
  final bool ehVideo;

  const ResultadoSelecaoArquivos({
    this.arquivos = const [],
    this.tipoSugerido,
    this.erro,
    this.ehVideo = false,
  });
}

class SelecaoArquivosCriarPubHelper {
  const SelecaoArquivosCriarPubHelper._();

  static Future<ResultadoSelecaoArquivos> selecionar(
    TipoFeedSocial tipo,
  ) async {
    try {
      await PlayerVideoNousWidget.pausarTodos();

      if (tipo == TipoFeedSocial.videos) {
        XFile? videoSelecionado;
        if (Platform.isAndroid || Platform.isIOS) {
          try {
            videoSelecionado = await ImagePicker().pickVideo(
              source: ImageSource.gallery,
            );
          } catch (_) {
            videoSelecionado = null;
          }
        }
        videoSelecionado ??= await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'Vídeos',
              extensions: ['mp4', 'mov', 'mkv', 'webm', 'avi'],
            ),
          ],
        );
        if (videoSelecionado == null) {
          return const ResultadoSelecaoArquivos();
        }
        return ResultadoSelecaoArquivos(
          arquivos: [videoSelecionado],
          ehVideo: true,
        );
      }

      final List<String> extensoes;
      final String label;
      switch (tipo) {
        case TipoFeedSocial.fotos:
          label = 'Imagens';
          extensoes = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
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
      if (files.isEmpty) {
        return const ResultadoSelecaoArquivos();
      }

      final aceitos = <XFile>[];
      TipoFeedSocial? tipoSugerido;
      for (final f in files) {
        final ext = f.path.split('.').last.toLowerCase();
        if (tipo == TipoFeedSocial.fotos &&
            ['pdf', 'txt', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'zip', 'epub']
                .contains(ext)) {
          tipoSugerido ??= TipoFeedSocial.documentos;
          aceitos.add(f);
        } else if (extensoes.contains(ext) || ext.isEmpty) {
          aceitos.add(f);
        }
      }

      if (aceitos.isEmpty) {
        return ResultadoSelecaoArquivos(
          erro:
              'Selecione apenas arquivos compatíveis com a timeline (${extensoes.join(", ")}).',
        );
      }

      return ResultadoSelecaoArquivos(
        arquivos: aceitos,
        tipoSugerido: tipoSugerido,
      );
    } catch (e) {
      return ResultadoSelecaoArquivos(
        erro: 'Não foi possível abrir o seletor de arquivos: $e',
      );
    }
  }
}
