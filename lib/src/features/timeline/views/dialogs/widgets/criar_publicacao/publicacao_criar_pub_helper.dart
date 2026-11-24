import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/criar_publicacao/secao_capa_video_criar_pub_widget.dart';

class PublicacaoCriarPubHelper {
  const PublicacaoCriarPubHelper._();

  static Future<PublicacaoSocial> criarPublicacao({
    required UsuarioNous autor,
    required TipoFeedSocial tipo,
    required String texto,
    required List<XFile> arquivosSelecionados,
    required Map<int, ({double x, double y, double zoom})> ajustesPorFoto,
    required double alinhamentoX,
    required double alinhamentoY,
    required double escalaZoom,
    required XFile? capaVideo,
    required Uint8List? capaFrameBytes,
    required List<UsuarioNous> coautoresSelecionados,
    required PadraoExibicaoMidia padraoExibicao,
    required double? proporcaoCustom,
    required int colunasMosaico,
    required bool permitirDownload,
    required String cifraLetra,
  }) async {
    final midias = <MidiaPublicacao>[];
    for (int i = 0; i < arquivosSelecionados.length; i++) {
      final arq = arquivosSelecionados[i];
      final ajuste = ajustesPorFoto[i];
      final m = await TimelineService.importarMidiaLocal(
        arq.path,
        nomeArquivo: arq.name,
      );
      if (m != null) {
        midias.add(
          m.copyWith(
            alinhamentoX: ajuste?.x ?? alinhamentoX,
            alinhamentoY: ajuste?.y ?? alinhamentoY,
            escalaZoom: ajuste?.zoom ?? escalaZoom,
          ),
        );
      }
    }

    final primeiroAjuste = ajustesPorFoto[0];
    String capaCaminho = '';
    if (tipo == TipoFeedSocial.videos) {
      if (capaVideo != null) {
        final capaImportada = await TimelineService.importarMidiaLocal(
          capaVideo.path,
          nomeArquivo: capaVideo.name,
        );
        if (capaImportada != null) {
          capaCaminho = capaImportada.caminhoRelativo;
        }
      } else if (capaFrameBytes != null && capaFrameBytes.isNotEmpty) {
        final salvo = await ImagemService.salvarBytesImagemLocal(
          capaFrameBytes,
          extensaoOriginal: 'jpg',
        );
        if (salvo != null && salvo.isNotEmpty) {
          capaCaminho = ImagemService.paraCaminhoRelativoCanonico(salvo);
        }
      } else if (arquivosSelecionados.isNotEmpty) {
        capaCaminho =
            await SecaoCapaVideoCriarPubWidget.capturarPrimeiroFrameVideo(
          arquivosSelecionados.first.path,
        );
      }
    } else if ((tipo == TipoFeedSocial.documentos ||
            tipo == TipoFeedSocial.livros) &&
        midias.isNotEmpty &&
        midias.first.nomeArquivo.toLowerCase().endsWith('.pdf')) {
      final thumbBytes = await TimelineService.obterOuGerarMiniaturaPdf(
        midias.first.caminhoRelativo,
      );
      if (thumbBytes != null && thumbBytes.isNotEmpty) {
        final salvo = await ImagemService.salvarBytesImagemLocal(
          thumbBytes,
          extensaoOriginal: 'png',
        );
        if (salvo != null && salvo.isNotEmpty) {
          capaCaminho = ImagemService.paraCaminhoRelativoCanonico(salvo);
        }
      }
    }

    return TimelineService.criarPublicacao(
      autorCpf: autor.cpf,
      autorNome: autor.nomeExibicao,
      autorFoto: autor.fotoExibicao,
      tipo: tipo,
      texto: texto,
      midias: midias,
      coautoresCpfs: coautoresSelecionados.map((u) => u.cpf).toList(),
      padraoExibicao: padraoExibicao,
      proporcaoCustom: proporcaoCustom,
      colunasMosaico: colunasMosaico,
      permitirDownload: permitirDownload,
      alinhamentoX: primeiroAjuste?.x ?? alinhamentoX,
      alinhamentoY: primeiroAjuste?.y ?? alinhamentoY,
      escalaZoom: primeiroAjuste?.zoom ?? escalaZoom,
      capaCaminho: capaCaminho,
      cifraLetra: cifraLetra,
    );
  }
}
