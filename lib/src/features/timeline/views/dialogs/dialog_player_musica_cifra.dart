import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/reprodutor_audio_widget.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Diálogo do Player de Música com alternância entre Áudio e Letra/Cifra/Tablatura
/// (base do módulo musical do Player Universal do Nous).
class DialogPlayerMusicaCifra extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final String caminhoAudio;
  final String tituloFaixa;

  const DialogPlayerMusicaCifra({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.caminhoAudio,
    required this.tituloFaixa,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required String caminhoAudio,
    required String tituloFaixa,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogPlayerMusicaCifra(
        theme: theme,
        publicacao: publicacao,
        caminhoAudio: caminhoAudio,
        tituloFaixa: tituloFaixa,
      ),
    );
  }

  @override
  State<DialogPlayerMusicaCifra> createState() =>
      _DialogPlayerMusicaCifraState();
}

class _DialogPlayerMusicaCifraState extends State<DialogPlayerMusicaCifra> {
  bool _verCifra = false;
  double _tamanhoFonteCifra = 13.5;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = widget.publicacao;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Áudio'),
                          icon: Icon(Icons.music_note_rounded, size: 16),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Cifra / Letra'),
                          icon: Icon(Icons.queue_music_rounded, size: 16),
                        ),
                      ],
                      selected: {_verCifra},
                      onSelectionChanged: (s) {
                        setState(() => _verCifra = s.first);
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!_verCifra) ...[
                Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 56,
                      color: theme.buttonColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.tituloFaixa,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pub.autorNome.isNotEmpty ? pub.autorNome : 'Cidadão Nous',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                ReprodutorAudioWidget(
                  theme: theme,
                  caminho: widget.caminhoAudio,
                  tituloPadrao: widget.tituloFaixa,
                  subtituloPadrao: pub.autorNome,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.tituloFaixa,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Diminuir fonte',
                          icon: Icon(
                            Icons.text_decrease_rounded,
                            size: 18,
                            color: theme.textColor,
                          ),
                          onPressed: () => setState(() {
                            _tamanhoFonteCifra =
                                (_tamanhoFonteCifra - 1.5).clamp(10.0, 24.0);
                          }),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Aumentar fonte',
                          icon: Icon(
                            Icons.text_increase_rounded,
                            size: 18,
                            color: theme.textColor,
                          ),
                          onPressed: () => setState(() {
                            _tamanhoFonteCifra =
                                (_tamanhoFonteCifra + 1.5).clamp(10.0, 24.0);
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.35)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: pub.cifraLetra.trim().isNotEmpty
                        ? SelectableText(
                            pub.cifraLetra,
                            style: theme.getTextStyle(
                              fontSize: _tamanhoFonteCifra,
                              color: theme.textColor,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'O autor não adicionou letra, cifra ou tablatura para esta faixa.',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 13,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
