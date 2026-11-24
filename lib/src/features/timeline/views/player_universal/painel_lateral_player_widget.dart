import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/player_universal/capa_midia_universal_widget.dart';

/// Painel reutilizável de Fila (`A SEGUIR`), `LETRA` e `CIFRA` do Player Universal.
class PainelLateralPlayerWidget extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final int abaIndex;
  final PlayerUniversalController controller;

  const PainelLateralPlayerWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.abaIndex,
    required this.controller,
  });

  @override
  State<PainelLateralPlayerWidget> createState() =>
      _PainelLateralPlayerWidgetState();
}

class _PainelLateralPlayerWidgetState extends State<PainelLateralPlayerWidget> {
  double _tamanhoFonteCifra = 15.0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ctrl = widget.controller;
    final pub = widget.publicacao;

    if (widget.abaIndex == 0) {
      final fila = ctrl.fila;
      if (fila.isEmpty) {
        return Center(
          child: Text(
            'Nenhuma mídia na fila.',
            style: TextStyle(color: theme.secondaryTextColor),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: fila.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: theme.borderColor.withValues(alpha: 0.3),
        ),
        itemBuilder: (context, index) {
          final item = fila[index];
          final ativo = index == ctrl.indiceAtual;
          return ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: ativo
                ? theme.textColor.withValues(alpha: 0.08)
                : Colors.transparent,
            leading: CapaMidiaUniversalWidget(
              theme: theme,
              publicacao: item,
              largura: 42,
              altura: 42,
              borderRadius: 8,
              tamanhoIcone: 20,
            ),
            title: Text(
              PlayerUniversalController.obterTitulo(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              item.autorNome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            trailing: ativo
                ? Icon(
                    Icons.equalizer_rounded,
                    color: theme.textColor,
                    size: 20,
                  )
                : null,
            onTap: () => ctrl.tocarPublicacao(item),
          );
        },
      );
    }

    final ehCifra = widget.abaIndex == 2;
    final textoConteudo = ehCifra
        ? (pub.cifraLetra.trim().isNotEmpty
            ? pub.cifraLetra.trim()
            : 'Nenhuma cifra cadastrada para esta faixa.')
        : (pub.texto.trim().isNotEmpty
            ? pub.texto.trim()
            : 'Nenhuma letra ou descrição informada.');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: [
              Text(
                ehCifra ? 'Cifra / Tablatura' : 'Letra / Descrição',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Diminuir fonte',
                onPressed: () {
                  setState(() {
                    _tamanhoFonteCifra =
                        (_tamanhoFonteCifra - 1.5).clamp(11.0, 26.0);
                  });
                },
                icon: Icon(
                  Icons.text_decrease_rounded,
                  color: theme.secondaryTextColor,
                  size: 19,
                ),
              ),
              IconButton(
                tooltip: 'Aumentar fonte',
                onPressed: () {
                  setState(() {
                    _tamanhoFonteCifra =
                        (_tamanhoFonteCifra + 1.5).clamp(11.0, 26.0);
                  });
                },
                icon: Icon(
                  Icons.text_increase_rounded,
                  color: theme.secondaryTextColor,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Align(
              alignment: Alignment.topLeft,
              child: SelectableText(
                textoConteudo,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: _tamanhoFonteCifra,
                  height: 1.6,
                  fontFamily: ehCifra ? 'monospace' : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
