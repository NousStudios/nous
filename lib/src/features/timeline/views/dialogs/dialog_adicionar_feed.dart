import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

class DialogAdicionarFeed extends StatefulWidget {
  final AppTheme theme;
  final String donoCpf;

  const DialogAdicionarFeed({
    super.key,
    required this.theme,
    required this.donoCpf,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String donoCpf,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DialogAdicionarFeed(theme: theme, donoCpf: donoCpf),
    );
  }

  @override
  State<DialogAdicionarFeed> createState() => _DialogAdicionarFeedState();
}

class _DialogAdicionarFeedState extends State<DialogAdicionarFeed> {
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  OrigemFeedExterno _origem = OrigemFeedExterno.rssAtom;
  List<TipoFeedSocial> _timelinesAtivas = [];
  bool _mostrarExterno = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarVisiveis();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarVisiveis() async {
    final visiveis = await TimelineService.obterTimelinesVisiveis(widget.donoCpf);
    if (!mounted) return;
    setState(() => _timelinesAtivas = visiveis);
  }

  Future<void> _alternarTimeline(TipoFeedSocial tipo) async {
    final nova = List<TipoFeedSocial>.from(_timelinesAtivas);
    if (nova.contains(tipo)) {
      nova.remove(tipo);
    } else {
      nova.add(tipo);
    }
    await TimelineService.salvarTimelinesVisiveis(widget.donoCpf, nova);
    if (mounted) setState(() => _timelinesAtivas = nova);
  }

  Future<void> _salvarExterno() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'Informe um nome para este feed.');
      return;
    }
    await TimelineService.adicionarFeedPersonalizado(
      donoCpf: widget.donoCpf,
      titulo: titulo,
      origem: _origem,
      urlOuIdentificador: _urlCtrl.text.trim(),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  String _nomeTimeline(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.livros:
        return 'Livros';
      case TipoFeedSocial.musicas:
        return 'Músicas';
      case TipoFeedSocial.escritos:
        return 'Escritos';
      case TipoFeedSocial.republicacoes:
        return 'Republicações';
      case TipoFeedSocial.interacoes:
        return 'Interações';
      case TipoFeedSocial.salvos:
        return 'Conteúdos Salvos';
      case TipoFeedSocial.likes:
        return 'Conteúdos com Like';
      case TipoFeedSocial.deslikes:
        return 'Conteúdos com Deslike';
      case TipoFeedSocial.denuncias:
        return 'Denúncias';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gerenciar Timelines',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Escolha quais timelines ficam visíveis no seu perfil público:',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: TipoFeedSocial.values.map((t) {
                  final ativa = _timelinesAtivas.contains(t);
                  return FilterChip(
                    label: Text(
                      _nomeTimeline(t),
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        color: ativa ? theme.buttonTextColor : theme.textColor,
                      ),
                    ),
                    selected: ativa,
                    selectedColor: theme.buttonColor,
                    backgroundColor:
                        theme.backgroundColor.withValues(alpha: 0.4),
                    onSelected: (_) => _alternarTimeline(t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _mostrarExterno = !_mostrarExterno),
                icon: const Icon(Icons.rss_feed_rounded, size: 18),
                label: const Text('Importar feed de outras redes (molde)'),
              ),
              if (_mostrarExterno) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(theme, OrigemFeedExterno.rssAtom, 'RSS / Atom'),
                    _chip(theme, OrigemFeedExterno.instagramPonte, 'Instagram'),
                    _chip(theme, OrigemFeedExterno.youtubePonte, 'YouTube'),
                    _chip(theme, OrigemFeedExterno.webhookJson, 'JSON / Ponte'),
                  ],
                ),
                const SizedBox(height: 12),
                ThemedTextField(
                  theme: theme,
                  controller: _tituloCtrl,
                  label: 'Nome da aba do feed (ex.: YouTube, Blog)',
                ),
                const SizedBox(height: 10),
                ThemedTextField(
                  theme: theme,
                  controller: _urlCtrl,
                  label: 'URL ou @identificador',
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _erro!,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                  ),
                  onPressed: _salvarExterno,
                  child: const Text('Adicionar Feed Externo'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Concluir',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(AppTheme theme, OrigemFeedExterno origem, String label) {
    final ativo = _origem == origem;
    return ChoiceChip(
      label: Text(
        label,
        style: theme.getTextStyle(
          fontSize: 11,
          color: ativo ? theme.buttonTextColor : theme.textColor,
        ),
      ),
      selected: ativo,
      selectedColor: theme.buttonColor,
      backgroundColor: theme.backgroundColor.withValues(alpha: 0.4),
      onSelected: (_) => setState(() => _origem = origem),
    );
  }
}
