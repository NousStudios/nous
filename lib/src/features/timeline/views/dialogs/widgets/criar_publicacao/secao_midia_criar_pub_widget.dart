import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_fotos_carrossel_widget.dart';

class SecaoMidiaCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final TipoFeedSocial tipo;
  final List<XFile> arquivosSelecionados;
  final int indiceFotoPreview;
  final double? aspectRatioPrevia;
  final double alinhamentoX;
  final double alinhamentoY;
  final double escalaZoom;
  final VoidCallback onSelecionarArquivos;
  final ValueChanged<int> onSelecionarIndice;
  final ValueChanged<int> onRemoverIndice;
  final void Function(double x, double y, double zoom) onAtualizarAjuste;
  final ValueChanged<bool> onInteracaoAtivaMudou;
  final VoidCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onLimparTudo;

  const SecaoMidiaCriarPubWidget({
    super.key,
    required this.theme,
    required this.tipo,
    required this.arquivosSelecionados,
    required this.indiceFotoPreview,
    required this.aspectRatioPrevia,
    required this.alinhamentoX,
    required this.alinhamentoY,
    required this.escalaZoom,
    required this.onSelecionarArquivos,
    required this.onSelecionarIndice,
    required this.onRemoverIndice,
    required this.onAtualizarAjuste,
    required this.onInteracaoAtivaMudou,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onLimparTudo,
  });

  @override
  Widget build(BuildContext context) {
    final ehFotoOuVideo =
        tipo == TipoFeedSocial.fotos || tipo == TipoFeedSocial.videos;

    if (arquivosSelecionados.isEmpty) {
      final IconData icone;
      final String titulo;
      final String subtitulo;
      switch (tipo) {
        case TipoFeedSocial.fotos:
          icone = Icons.add_photo_alternate_outlined;
          titulo = 'Selecionar fotos';
          subtitulo = 'Toque para escolher uma ou várias imagens';
          break;
        case TipoFeedSocial.videos:
          icone = Icons.video_call_outlined;
          titulo = 'Selecionar vídeo';
          subtitulo = 'Toque para escolher o vídeo da galeria';
          break;
        case TipoFeedSocial.musicas:
          icone = Icons.library_music_outlined;
          titulo = 'Selecionar música ou áudio';
          subtitulo = 'MP3, WAV, M4A, OGG ou FLAC';
          break;
        default:
          icone = Icons.upload_file_outlined;
          titulo = 'Selecionar documento';
          subtitulo = 'PDF, planilhas, textos ou arquivos';
          break;
      }

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelecionarArquivos,
        child: Container(
          height: ehFotoOuVideo ? 220 : 130,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icone,
                  size: ehFotoOuVideo ? 46 : 34,
                  color: theme.buttonColor,
                ),
                const SizedBox(height: 10),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (tipo == TipoFeedSocial.fotos) {
      final indiceSeguro = indiceFotoPreview >= arquivosSelecionados.length
          ? 0
          : indiceFotoPreview;
      return EditorFotosCarrosselWidget(
        theme: theme,
        arquivos: arquivosSelecionados,
        indiceAtivo: indiceSeguro,
        aspectRatio: aspectRatioPrevia,
        alinhamentoX: alinhamentoX,
        alinhamentoY: alinhamentoY,
        escalaZoom: escalaZoom,
        onSelecionarIndice: onSelecionarIndice,
        onRemoverIndice: onRemoverIndice,
        onAtualizarAjuste: onAtualizarAjuste,
        onInteracaoAtivaMudou: onInteracaoAtivaMudou,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onAdicionarMais: onSelecionarArquivos,
        onLimparTudo: onLimparTudo,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < arquivosSelecionados.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                tipo == TipoFeedSocial.videos
                    ? Icons.play_circle_fill_rounded
                    : tipo == TipoFeedSocial.musicas
                        ? Icons.music_note_rounded
                        : Icons.description_rounded,
                color: theme.buttonColor,
                size: 28,
              ),
              title: Text(
                arquivosSelecionados[i].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18, color: theme.dangerColor),
                onPressed: () => onRemoverIndice(i),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSelecionarArquivos,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar outro'),
            ),
          ),
        ],
      ),
    );
  }
}

class SeletorFormatoVisualCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final TipoFeedSocial tipo;
  final PadraoExibicaoMidia padraoAtual;
  final ValueChanged<PadraoExibicaoMidia> onSelecionarPadrao;

  const SeletorFormatoVisualCriarPubWidget({
    super.key,
    required this.theme,
    required this.tipo,
    required this.padraoAtual,
    required this.onSelecionarPadrao,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = tipo == TipoFeedSocial.videos
        ? <(PadraoExibicaoMidia, IconData, String)>[
            (
              PadraoExibicaoMidia.paisagem16x9,
              Icons.crop_16_9_rounded,
              'Horizontal 16:9',
            ),
            (
              PadraoExibicaoMidia.vertical9x16,
              Icons.smartphone_rounded,
              'Vertical 9:16',
            ),
          ]
        : <(PadraoExibicaoMidia, IconData, String)>[
            (PadraoExibicaoMidia.original, Icons.crop_free_rounded, 'Original'),
            (PadraoExibicaoMidia.quadrado1x1, Icons.crop_square_rounded, '1:1'),
            (
              PadraoExibicaoMidia.retrato4x5,
              Icons.crop_portrait_rounded,
              '4:5',
            ),
            (
              PadraoExibicaoMidia.paisagem16x9,
              Icons.crop_16_9_rounded,
              '16:9',
            ),
            (
              PadraoExibicaoMidia.vertical9x16,
              Icons.smartphone_rounded,
              '9:16',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enquadramento',
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opcoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (padrao, icone, rotulo) = opcoes[i];
              final ativo = padraoAtual == padrao;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelecionarPadrao(padrao),
                child: Container(
                  width: tipo == TipoFeedSocial.videos ? 112 : 68,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: ativo
                        ? theme.buttonColor
                        : theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ativo
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.5),
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icone,
                        size: 18,
                        color: ativo ? theme.buttonTextColor : theme.textColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rotulo,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              ativo ? FontWeight.bold : FontWeight.normal,
                          color:
                              ativo ? theme.buttonTextColor : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
