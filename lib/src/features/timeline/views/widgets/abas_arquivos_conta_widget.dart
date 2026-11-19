import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Aba visual de itens Arquivados (publicações e stories) com restauração rápida.
class AbaArquivadosContaWidget extends StatelessWidget {
  final AppTheme theme;
  final List<PublicacaoSocial> publicacoesArquivadas;
  final List<StorySocial> storiesArquivados;
  final Future<void> Function(PublicacaoSocial pub) onRestaurarPublicacao;
  final Future<void> Function(StorySocial story) onRestaurarStory;

  const AbaArquivadosContaWidget({
    super.key,
    required this.theme,
    required this.publicacoesArquivadas,
    required this.storiesArquivados,
    required this.onRestaurarPublicacao,
    required this.onRestaurarStory,
  });

  @override
  Widget build(BuildContext context) {
    if (publicacoesArquivadas.isEmpty && storiesArquivados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum conteúdo arquivado no momento.',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (publicacoesArquivadas.isNotEmpty) ...[
          Text(
            'Publicações Arquivadas (${publicacoesArquivadas.length})',
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: publicacoesArquivadas.length,
            itemBuilder: (_, idx) {
              final pub = publicacoesArquivadas[idx];
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: pub.midias.isNotEmpty
                          ? FutureBuilder<String?>(
                              future: TimelineService.resolverCaminhoMidia(
                                pub.midias.first.caminhoRelativo,
                              ),
                              builder: (_, snap) {
                                final caminho = snap.data;
                                if (caminho != null &&
                                    File(caminho).existsSync()) {
                                  return Image.file(
                                    File(caminho),
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Center(
                                  child: Icon(
                                    Icons.archive_outlined,
                                    color: theme.secondaryTextColor,
                                  ),
                                );
                              },
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  pub.texto.isNotEmpty
                                      ? pub.texto
                                      : 'Publicação',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    InkWell(
                      onTap: () => onRestaurarPublicacao(pub),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: theme.buttonColor,
                        child: Text(
                          'Restaurar',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (storiesArquivados.isNotEmpty) ...[
          Text(
            'Stories Arquivados (${storiesArquivados.length})',
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          for (final story in storiesArquivados)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      story.texto.isNotEmpty
                          ? story.texto
                          : 'Story arquivado (${story.criadoEm.day.toString().padLeft(2, '0')}/${story.criadoEm.month.toString().padLeft(2, '0')}/${story.criadoEm.year})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onRestaurarStory(story),
                    child: const Text('Restaurar'),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Aba de registros simbólicos compactados de publicações excluídas pelo usuário.
class AbaExcluidosContaWidget extends StatelessWidget {
  final AppTheme theme;
  final List<PublicacaoSocial> publicacoesExcluidas;
  final Future<void> Function(PublicacaoSocial pub) onRecuperarPublicacao;

  const AbaExcluidosContaWidget({
    super.key,
    required this.theme,
    required this.publicacoesExcluidas,
    required this.onRecuperarPublicacao,
  });

  @override
  Widget build(BuildContext context) {
    if (publicacoesExcluidas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum registro de exclusão encontrado.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: publicacoesExcluidas.length,
      itemBuilder: (_, idx) {
        final pub = publicacoesExcluidas[idx];
        final dt = pub.atualizadaEm.toLocal();
        final dataStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                size: 20,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registro simbólico • ${pub.tipo.name}',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Excluída pelo usuário em $dataStr',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onRecuperarPublicacao(pub),
                child: Text(
                  'Recuperar',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
