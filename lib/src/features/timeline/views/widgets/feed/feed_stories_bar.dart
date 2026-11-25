import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';

class FeedStoriesBar extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous? contaAtual;
  final String meuCpf;
  final Map<String, List<StorySocial>> storiesPorAutor;
  final UsuarioNous? Function(String cpf) buscarContaPorCpf;

  const FeedStoriesBar({
    super.key,
    required this.theme,
    required this.contaAtual,
    required this.meuCpf,
    required this.storiesPorAutor,
    required this.buscarContaPorCpf,
  });

  @override
  Widget build(BuildContext context) {
    if (storiesPorAutor.isEmpty && contaAtual == null) {
      return const SizedBox.shrink();
    }

    final meuCpfLimpo = meuCpf.replaceAll(RegExp(r'\D'), '');

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (contaAtual != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => CameraCriacaoView(
                      theme: theme,
                      autor: contaAtual!,
                      ativa: true,
                      onVoltarPerfil: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardBackgroundColor,
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.7),
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 22,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+ Story',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (final entry in storiesPorAutor.entries)
            Builder(
              builder: (_) {
                final cpfAutor = entry.key;
                final storiesAutor = entry.value;
                final primeiro = storiesAutor.first;
                final conta = buscarContaPorCpf(cpfAutor);
                final foto = (conta?.fotoExibicao.isNotEmpty ?? false)
                    ? conta!.fotoExibicao
                    : primeiro.autorFoto;
                final nome = (conta?.nomeExibicao.isNotEmpty ?? false)
                    ? conta!.nomeExibicao
                    : (primeiro.autorNome.isNotEmpty
                        ? primeiro.autorNome
                        : 'Story');
                final ehEu = meuCpfLimpo.isNotEmpty && meuCpfLimpo == cpfAutor;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => DialogVisualizarStory.mostrar(
                      context,
                      theme: theme,
                      story: storiesAutor.first,
                      stories: storiesAutor,
                      ehAutor: ehEu,
                      usuarioLogado: contaAtual,
                    ),
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.borderColor,
                                width: 2.2,
                              ),
                            ),
                            child: _AvatarAutorStory(
                              theme: theme,
                              fotoAutor: foto,
                              rotuloAutor: nome,
                              raio: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AvatarAutorStory extends StatelessWidget {
  final AppTheme theme;
  final String fotoAutor;
  final String rotuloAutor;
  final double raio;

  const _AvatarAutorStory({
    required this.theme,
    required this.fotoAutor,
    required this.rotuloAutor,
    this.raio = 13,
  });

  Widget _buildFallback() {
    final inicial = rotuloAutor.trim().isNotEmpty
        ? rotuloAutor.trim()[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: raio,
      backgroundColor: theme.borderColor.withValues(alpha: 0.35),
      child: Text(
        inicial,
        style: theme.getTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerDireto = ImagemService.obterImageProvider(fotoAutor);
    if (providerDireto != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.35),
        backgroundImage: providerDireto,
      );
    }

    if (fotoAutor.trim().isEmpty) {
      return _buildFallback();
    }

    return FutureBuilder<String?>(
      future: TimelineService.resolverCaminhoMidia(fotoAutor),
      builder: (context, snapshot) {
        final caminho = snapshot.data;
        if (caminho != null && caminho.isNotEmpty) {
          final prov = ImagemService.obterImageProvider(caminho);
          if (prov != null) {
            return CircleAvatar(
              radius: raio,
              backgroundColor: theme.borderColor.withValues(alpha: 0.35),
              backgroundImage: prov,
            );
          }
        }
        return _buildFallback();
      },
    );
  }
}
