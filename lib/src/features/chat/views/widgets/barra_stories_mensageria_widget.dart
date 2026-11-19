import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Barra horizontal com as bolinhas de stories ainda não vistos (inclusive do
/// próprio usuário) exibida acima de "Solicitações de Mensagens" no Chat.
class BarraStoriesMensageriaWidget extends StatefulWidget {
  final AppTheme theme;

  const BarraStoriesMensageriaWidget({super.key, required this.theme});

  @override
  State<BarraStoriesMensageriaWidget> createState() =>
      _BarraStoriesMensageriaWidgetState();
}

class _BarraStoriesMensageriaWidgetState
    extends State<BarraStoriesMensageriaWidget> {
  Map<String, List<StorySocial>> _storiesPorAutor = {};

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final ativos = await TimelineService.listarStoriesAtivosDaRede();
    final agrupados = <String, List<StorySocial>>{};
    for (final s in ativos) {
      if (s.arquivado || s.excluido) continue;
      final cpf = s.autorCpf.replaceAll(RegExp(r'\D'), '');
      if (cpf.isEmpty) continue;
      agrupados.putIfAbsent(cpf, () => []).add(s);
    }
    for (final lista in agrupados.values) {
      lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    }
    if (!mounted) return;
    setState(() => _storiesPorAutor = agrupados);
  }

  Color _parseColor(String hex) {
    final limpo = hex.replaceAll('#', '').trim();
    final val = int.tryParse(limpo, radix: 16);
    if (val == null) return const Color(0xFF2E7D32);
    return Color(limpo.length == 6 ? (0xFF000000 | val) : val);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meuUsuario = auth.contaAtual;
    final meuCpf = (meuUsuario?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final theme = widget.theme;

    // Filtra apenas autores com stories ainda não vistos pelo usuário atual
    // (mantendo sempre o próprio usuário no início).
    final outrosNaoVistos = <MapEntry<String, List<StorySocial>>>[];
    for (final entry in _storiesPorAutor.entries) {
      if (entry.key == meuCpf) continue;
      final temNaoVisto = meuCpf.isEmpty ||
          entry.value.any(
            (s) => !s.visualizadoPorCpfs
                .map((c) => c.replaceAll(RegExp(r'\D'), ''))
                .contains(meuCpf),
          );
      if (temNaoVisto) {
        outrosNaoVistos.add(entry);
      }
    }

    final meusStories = meuCpf.isNotEmpty
        ? (_storiesPorAutor[meuCpf] ?? const <StorySocial>[])
        : const <StorySocial>[];

    if (meuUsuario == null && outrosNaoVistos.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        children: [
          if (meuUsuario != null)
            _buildBolinhaStory(
              theme: theme,
              conta: meuUsuario,
              nome: meusStories.isEmpty ? 'Seu story' : 'Você',
              foto: meuUsuario.fotoExibicao,
              corAnel: meusStories.isNotEmpty
                  ? _parseColor(meuUsuario.corStoryHex)
                  : theme.borderColor.withValues(alpha: 0.6),
              mostrarMais: meusStories.isEmpty,
              onTap: () {
                if (meusStories.isEmpty) {
                  DialogCriarStory.mostrar(
                    context,
                    theme: theme,
                    autor: meuUsuario,
                  );
                } else {
                  DialogVisualizarStory.mostrar(
                    context,
                    theme: theme,
                    story: meusStories.first,
                    stories: meusStories,
                    ehAutor: true,
                    usuarioLogado: meuUsuario,
                  );
                }
              },
            ),
          for (final entry in outrosNaoVistos)
            Builder(
              builder: (_) {
                final conta = auth.buscarContaPorCpf(entry.key);
                final primeiro = entry.value.first;
                final nome = (conta?.nomeExibicao.isNotEmpty ?? false)
                    ? conta!.nomeExibicao
                    : (primeiro.autorNome.isNotEmpty
                        ? primeiro.autorNome
                        : 'Usuário');
                final foto = (conta?.fotoExibicao.isNotEmpty ?? false)
                    ? conta!.fotoExibicao
                    : primeiro.autorFoto;
                final corAnel = _parseColor(
                  conta?.corStoryHex ?? '#2E7D32',
                );
                return _buildBolinhaStory(
                  theme: theme,
                  conta: conta,
                  nome: nome,
                  foto: foto,
                  corAnel: corAnel,
                  onTap: () => DialogVisualizarStory.mostrar(
                    context,
                    theme: theme,
                    story: entry.value.first,
                    stories: entry.value,
                    ehAutor: false,
                    usuarioLogado: meuUsuario,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBolinhaStory({
    required AppTheme theme,
    required UsuarioNous? conta,
    required String nome,
    required String foto,
    required Color corAnel,
    required VoidCallback onTap,
    bool mostrarMais = false,
  }) {
    final caminho = ImagemService.resolverCaminhoExistente(foto);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: corAnel, width: 2.2),
                    ),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor:
                          theme.borderColor.withValues(alpha: 0.25),
                      backgroundImage: caminho != null &&
                              File(caminho).existsSync()
                          ? FileImage(File(caminho))
                          : null,
                      child: caminho == null || !File(caminho).existsSync()
                          ? Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (mostrarMais)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.buttonColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.backgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 11,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 10.5,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
