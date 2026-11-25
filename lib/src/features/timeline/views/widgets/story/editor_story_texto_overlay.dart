import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/views/widgets/story/camada_texto_story_widget.dart';

/// Sobreposição de edição em tempo real para criar ou editar uma [CamadaTextoStory].
class EditorStoryTextoOverlay extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final CamadaTextoStory rascunho;
  final bool editandoExistente;
  final VoidCallback onFechar;
  final VoidCallback onRemover;
  final VoidCallback onConcluir;
  final ValueChanged<CamadaTextoStory> onRascunhoChanged;
  final VoidCallback onTextoChanged;

  const EditorStoryTextoOverlay({
    super.key,
    required this.theme,
    required this.controller,
    required this.rascunho,
    required this.editandoExistente,
    required this.onFechar,
    required this.onRemover,
    required this.onConcluir,
    required this.onRascunhoChanged,
    required this.onTextoChanged,
  });

  static const _paletas = <({String label, String textoHex, String fundoHex})>[
    (label: 'Escuro', textoHex: 'FFFFFFFF', fundoHex: 'B3000000'),
    (label: 'Claro', textoHex: 'FF111111', fundoHex: 'E6FFFFFF'),
    (label: 'Limpo', textoHex: 'FFFFFFFF', fundoHex: ''),
    (label: 'Destaque', textoHex: 'FFFFFFFF', fundoHex: 'CCDC2626'),
    (label: 'Solar', textoHex: 'FF111111', fundoHex: 'E6FACC15'),
  ];

  static const _fontes = <({String id, String label})>[
    (id: 'padrao', label: 'Padrão'),
    (id: 'negrito', label: 'Forte'),
    (id: 'serif', label: 'Clássica'),
    (id: 'mono', label: 'Máquina'),
  ];

  @override
  Widget build(BuildContext context) {
    final temFundo = rascunho.corFundoHex.trim().isNotEmpty;
    final corFundo = temFundo
        ? CamadaTextoStoryWidget.parseHex(
            rascunho.corFundoHex,
            theme.backgroundColor.withValues(alpha: 0.54),
          )
        : Colors.transparent;
    final align = switch (rascunho.alinhamento) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

    return Container(
      color: theme.backgroundColor.withValues(alpha: 0.32),
      child: Column(
        children: [
          _buildBarraSuperior(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: EdgeInsets.symmetric(
                    horizontal: temFundo ? 14 : 6,
                    vertical: temFundo ? 8 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: corFundo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 1,
                    textAlign: align,
                    style: CamadaTextoStoryWidget.resolverEstilo(rascunho),
                    onChanged: (_) => onTextoChanged(),
                    onSubmitted: (_) => onConcluir(),
                    decoration: InputDecoration(
                      hintText: 'Digite seu texto...',
                      hintStyle: CamadaTextoStoryWidget.resolverEstilo(
                        rascunho,
                      ).copyWith(
                        color: theme.secondaryTextColor.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildControlesInferiores(),
        ],
      ),
    );
  }

  Widget _buildBarraSuperior() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (editandoExistente)
            TextButton(
              onPressed: onRemover,
              child: Text(
                'Remover',
                style: theme.getTextStyle(
                  color: theme.dangerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: theme.textColor),
              onPressed: onFechar,
            ),
          const Spacer(),
          _botaoAlinhamento(
            tooltip: 'Alinhar à esquerda',
            icone: Icons.format_align_left_rounded,
            valor: 'left',
          ),
          _botaoAlinhamento(
            tooltip: 'Centralizar',
            icone: Icons.format_align_center_rounded,
            valor: 'center',
          ),
          _botaoAlinhamento(
            tooltip: 'Alinhar à direita',
            icone: Icons.format_align_right_rounded,
            valor: 'right',
          ),
          const Spacer(),
          TextButton(
            onPressed: onConcluir,
            child: Text(
              'Concluir',
              style: theme.getTextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAlinhamento({
    required String tooltip,
    required IconData icone,
    required String valor,
  }) {
    final selecionado = rascunho.alinhamento == valor;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(
        icone,
        color: selecionado
            ? theme.textColor
            : theme.secondaryTextColor.withValues(alpha: 0.54),
      ),
      onPressed: () => onRascunhoChanged(rascunho.copyWith(alinhamento: valor)),
    );
  }

  Widget _buildControlesInferiores() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: theme.backgroundColor.withValues(alpha: 0.52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_size_rounded,
                color: theme.secondaryTextColor.withValues(alpha: 0.7),
                size: 18,
              ),
              Expanded(
                child: Slider(
                  value: rascunho.escala.clamp(0.7, 2.0),
                  min: 0.7,
                  max: 2.0,
                  activeColor: theme.textColor,
                  inactiveColor: theme.textColor.withValues(alpha: 0.24),
                  onChanged: (v) =>
                      onRascunhoChanged(rascunho.copyWith(escala: v)),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in _fontes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: rascunho.fonte == f.id,
                      onSelected: (_) =>
                          onRascunhoChanged(rascunho.copyWith(fonte: f.id)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in _paletas)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: rascunho.corTextoHex == p.textoHex &&
                          rascunho.corFundoHex == p.fundoHex,
                      onSelected: (_) => onRascunhoChanged(
                        rascunho.copyWith(
                          corTextoHex: p.textoHex,
                          corFundoHex: p.fundoHex,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
