import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Aba visual de Calendário de Stories da Central da Conta.
class AbaCalendarioContaWidget extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final List<StorySocial> historicoStories;

  const AbaCalendarioContaWidget({
    super.key,
    required this.theme,
    required this.usuario,
    required this.historicoStories,
  });

  @override
  State<AbaCalendarioContaWidget> createState() =>
      _AbaCalendarioContaWidgetState();
}

class _AbaCalendarioContaWidgetState extends State<AbaCalendarioContaWidget> {
  static const List<String> _nomesMeses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  DateTime _mesVisivel = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _mudarMes(int delta) {
    setState(() {
      _mesVisivel = DateTime(_mesVisivel.year, _mesVisivel.month + delta, 1);
    });
  }

  List<StorySocial> _storiesDoDia(int ano, int mes, int dia) {
    final lista = widget.historicoStories.where((s) {
      final l = s.criadoEm.toLocal();
      return l.year == ano && l.month == mes && l.day == dia;
    }).toList();
    lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ano = _mesVisivel.year;
    final mes = _mesVisivel.month;
    final primeiroDiaSemana = DateTime(ano, mes, 1).weekday % 7; // 0 = Dom
    final totalDiasMes = DateTime(ano, mes + 1, 0).day;
    final totalCelulas = primeiroDiaSemana + totalDiasMes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: theme.textColor,
                      ),
                      onPressed: () => _mudarMes(-1),
                    ),
                    Text(
                      '${_nomesMeses[mes - 1]} $ano',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.textColor,
                      ),
                      onPressed: () => _mudarMes(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCelulas,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    if (index < primeiroDiaSemana) {
                      return const SizedBox.shrink();
                    }
                    final dia = index - primeiroDiaSemana + 1;
                    final storiesDia = _storiesDoDia(ano, mes, dia);
                    final temStory = storiesDia.isNotEmpty;

                    return GestureDetector(
                      onTap: temStory
                          ? () => DialogVisualizarStory.mostrar(
                                context,
                                theme: theme,
                                story: storiesDia.first,
                                stories: storiesDia,
                                ehAutor: true,
                                usuarioLogado: widget.usuario,
                              )
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: temStory
                              ? theme.buttonColor.withValues(alpha: 0.18)
                              : Colors.transparent,
                          border: temStory
                              ? Border.all(
                                  color: theme.buttonColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (temStory &&
                                storiesDia.last.caminhoMidia.isNotEmpty)
                              FutureBuilder<String?>(
                                future: TimelineService.resolverCaminhoMidia(
                                  storiesDia.last.caminhoMidia,
                                ),
                                builder: (_, snap) {
                                  if (snap.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.55,
                                      child: Image.file(
                                        File(snap.data!),
                                        fit: BoxFit.cover,
                                        cacheWidth: 160,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Text(
                              '$dia',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: temStory
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: temStory
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                            if (storiesDia.length > 1)
                              Positioned(
                                bottom: 2,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.buttonColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Toque em qualquer dia marcado no calendário para rever os stories publicados naquela data (mesmo após expirarem as 24 horas).',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
