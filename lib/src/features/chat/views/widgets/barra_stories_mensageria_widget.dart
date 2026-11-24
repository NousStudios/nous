import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/constants/frases_pensamento.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_nota_pensamento.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';

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
  late final String _fraseSugerida;
  final Set<String> _fotosTentadas = {};

  @override
  void initState() {
    super.initState();
    _fraseSugerida =
        kFrasesPensamentoChat[Random().nextInt(kFrasesPensamentoChat.length)];
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

    // Contatos com nota de pensamento ativa (24h) mesmo sem story ativo
    final cpfsJaNaBarra = {
      if (meuCpf.isNotEmpty) meuCpf,
      for (final e in outrosNaoVistos) e.key,
    };
    final contatosSoComNota = <UsuarioNous>[];
    for (final c in auth.contasCache) {
      final cCpf = c.cpf.replaceAll(RegExp(r'\D'), '');
      if (cCpf.isEmpty || cpfsJaNaBarra.contains(cCpf)) continue;
      if (c.temNotaPensamentoAtiva) {
        cpfsJaNaBarra.add(cCpf);
        contatosSoComNota.add(c);
      }
    }

    if (meuUsuario == null &&
        outrosNaoVistos.isEmpty &&
        contatosSoComNota.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
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
              textoNuvem: meuUsuario.temNotaPensamentoAtiva
                  ? meuUsuario.notaPensamento
                  : _fraseSugerida,
              nuvemEhSugestao: !meuUsuario.temNotaPensamentoAtiva,
              onTapNuvem: () => DialogNotaPensamento.mostrar(
                context,
                theme: theme,
                usuario: meuUsuario,
                fraseSugerida: _fraseSugerida,
              ),
              onTap: () {
                if (meusStories.isEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => CameraCriacaoView(
                        theme: theme,
                        autor: meuUsuario,
                        ativa: true,
                        onVoltarPerfil: () => Navigator.of(ctx).pop(),
                      ),
                    ),
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
                final nota = (conta?.temNotaPensamentoAtiva ?? false)
                    ? conta!.notaPensamento
                    : null;
                return _buildBolinhaStory(
                  theme: theme,
                  conta: conta,
                  nome: nome,
                  foto: foto,
                  corAnel: corAnel,
                  textoNuvem: nota,
                  onTapNuvem: nota != null
                      ? () => _mostrarNotaContato(context, theme, nome, nota)
                      : null,
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
          for (final conta in contatosSoComNota)
            _buildBolinhaStory(
              theme: theme,
              conta: conta,
              nome: conta.nomeExibicao.isNotEmpty
                  ? conta.nomeExibicao
                  : 'Usuário',
              foto: conta.fotoExibicao,
              corAnel: theme.borderColor.withValues(alpha: 0.45),
              textoNuvem: conta.notaPensamento,
              onTapNuvem: () => _mostrarNotaContato(
                context,
                theme,
                conta.nomeExibicao,
                conta.notaPensamento,
              ),
              onTap: () => _mostrarNotaContato(
                context,
                theme,
                conta.nomeExibicao,
                conta.notaPensamento,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarNotaContato(
    BuildContext context,
    AppTheme theme,
    String nome,
    String nota,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nota,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Fechar',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    String? textoNuvem,
    bool nuvemEhSugestao = false,
    VoidCallback? onTapNuvem,
  }) {
    final caminho = ImagemService.resolverCaminhoExistente(foto);
    if (caminho == null &&
        foto.isNotEmpty &&
        !_fotosTentadas.contains(foto)) {
      _fotosTentadas.add(foto);
      TimelineService.resolverCaminhoMidia(foto).then((res) {
        if (res != null && mounted) setState(() {});
      });
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (textoNuvem != null && textoNuvem.trim().isNotEmpty)
              GestureDetector(
                onTap: onTapNuvem ?? onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor.withValues(alpha: 0.92),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: TextoRolante(
                        texto: textoNuvem,
                        textAlign: TextAlign.center,
                        velocidadePxPorSegundo: 22.0,
                        style: theme.getTextStyle(
                          fontSize: 8.8,
                          fontWeight: nuvemEhSugestao
                              ? FontWeight.normal
                              : FontWeight.w500,
                          color: nuvemEhSugestao
                              ? theme.secondaryTextColor
                              : theme.textColor,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-10, -1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor
                                  .withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    theme.borderColor.withValues(alpha: 0.45),
                                width: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      theme.borderColor.withValues(alpha: 0.45),
                                  width: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 26),
            GestureDetector(
              onTap: onTap,
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
                              ? ImagemService.obterImageProvider(
                                  caminho,
                                  cacheWidth: 140,
                                )
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
          ],
        ),
      ),
    );
  }
}
