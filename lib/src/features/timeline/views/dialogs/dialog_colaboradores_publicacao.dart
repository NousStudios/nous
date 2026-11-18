import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Janela de Colaboradores da Publicação:
/// - Título "Colaboradores" centralizado no topo;
/// - Lista rolável no meio com barras mostrando avatar (com anel de Story ativo clicável),
///   nome/username e botão individual de Seguir;
/// - Botão centralizado "Seguir todos" na base.
class DialogColaboradoresPublicacao extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;

  const DialogColaboradoresPublicacao({
    super.key,
    required this.theme,
    required this.publicacao,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogColaboradoresPublicacao(
        theme: theme,
        publicacao: publicacao,
      ),
    );
  }

  @override
  State<DialogColaboradoresPublicacao> createState() =>
      _DialogColaboradoresPublicacaoState();
}

class _DialogColaboradoresPublicacaoState
    extends State<DialogColaboradoresPublicacao> {
  final ScrollController _scrollCtrl = ScrollController();
  List<UsuarioNous> _participantes = [];
  Map<String, List<StorySocial>> _storiesPorCpf = {};
  bool _carregando = true;
  bool _seguindoTodos = false;

  @override
  void initState() {
    super.initState();
    _carregarParticipantes();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarParticipantes() async {
    final todas = await ContasNousService.carregarTodas();
    final cpfsAlvo = <String>{
      widget.publicacao.autorCpf.replaceAll(RegExp(r'\D'), ''),
      ...widget.publicacao.coautoresCpfs.map(
        (c) => c.replaceAll(RegExp(r'\D'), ''),
      ),
    }..removeWhere((c) => c.isEmpty);

    final lista = <UsuarioNous>[];
    final storiesMap = <String, List<StorySocial>>{};

    for (final cpf in cpfsAlvo) {
      final conta = todas
          .where((u) => u.cpf.replaceAll(RegExp(r'\D'), '') == cpf)
          .firstOrNull;
      if (conta != null) {
        lista.add(conta);
      } else {
        lista.add(
          UsuarioNous(
            cpf: cpf,
            nome: cpf ==
                    widget.publicacao.autorCpf.replaceAll(RegExp(r'\D'), '')
                ? widget.publicacao.autorNome
                : 'Colaborador Nous',
            dataNascimento: '',
            foto: cpf ==
                    widget.publicacao.autorCpf.replaceAll(RegExp(r'\D'), '')
                ? widget.publicacao.autorFoto
                : '',
          ),
        );
      }
      storiesMap[cpf] = await TimelineService.listarStoriesAtivos24h(cpf);
    }

    if (!mounted) return;
    setState(() {
      _participantes = lista;
      _storiesPorCpf = storiesMap;
      _carregando = false;
    });
  }

  Future<void> _seguirTodos(AuthProvider auth) async {
    final contaPropria = auth.contaAtual;
    if (contaPropria == null || _seguindoTodos) return;
    setState(() => _seguindoTodos = true);
    final meuCpf = contaPropria.cpf.replaceAll(RegExp(r'\D'), '');

    for (final u in _participantes) {
      final cpfAlvo = u.cpf.replaceAll(RegExp(r'\D'), '');
      if (cpfAlvo.isEmpty || cpfAlvo == meuCpf) continue;
      final jaSegue = auth.contaAtual?.estaSeguindo(cpfAlvo) ?? false;
      if (!jaSegue) {
        await auth.alternarSeguir(cpfAlvo);
      }
    }
    if (mounted) {
      setState(() => _seguindoTodos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final auth = context.watch<AuthProvider>();
    final contaPropria = auth.contaAtual;
    final meuCpf = (contaPropria?.cpf ?? '').replaceAll(RegExp(r'\D'), '');

    final outrosParaSeguir = _participantes.where((u) {
      final c = u.cpf.replaceAll(RegExp(r'\D'), '');
      return c.isNotEmpty &&
          c != meuCpf &&
          !(contaPropria?.estaSeguindo(c) ?? false);
    }).toList();

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.80,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título matematicamente centralizado
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Colaboradores',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Divider(color: theme.borderColor.withValues(alpha: 0.4)),

              // Lista rolável entre o título e o botão "Seguir todos"
              Flexible(
                child: _carregando
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollCtrl,
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          shrinkWrap: true,
                          itemCount: _participantes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = _participantes[i];
                            final cpfLimpo =
                                u.cpf.replaceAll(RegExp(r'\D'), '');
                            final stories =
                                _storiesPorCpf[cpfLimpo] ?? const [];
                            final temStory = stories.isNotEmpty;
                            final prov =
                                ImagemService.obterImageProvider(u.fotoExibicao);
                            final ehEu = cpfLimpo == meuCpf;
                            final jaSegue =
                                contaPropria?.estaSeguindo(cpfLimpo) ?? false;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.backgroundColor.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.borderColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (temStory) {
                                        DialogVisualizarStory.mostrar(
                                          context,
                                          theme: theme,
                                          story: stories.first,
                                          stories: stories,
                                          ehAutor: ehEu,
                                          usuarioLogado: contaPropria,
                                        );
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PerfilSocialView(
                                              usuarioAlvo: u,
                                              mostrarBotaoVoltar: true,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: temStory
                                          ? const EdgeInsets.all(2.2)
                                          : EdgeInsets.zero,
                                      decoration: temStory
                                          ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: theme.buttonColor,
                                                width: 2.2,
                                              ),
                                            )
                                          : null,
                                      child: CircleAvatar(
                                        radius: 19,
                                        backgroundColor: theme.borderColor
                                            .withValues(alpha: 0.35),
                                        backgroundImage: prov,
                                        child: prov == null
                                            ? Icon(
                                                Icons.person,
                                                size: 18,
                                                color: theme.textColor,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PerfilSocialView(
                                              usuarioAlvo: u,
                                              mostrarBotaoVoltar: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.nomeExibicao,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.getTextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          Text(
                                            i == 0
                                                ? 'Autor principal${temStory ? " • Story ativo" : ""}'
                                                : 'Colaborador${temStory ? " • Story ativo" : ""}',
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!ehEu && contaPropria != null)
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: jaSegue
                                            ? Colors.transparent
                                            : theme.buttonColor,
                                        foregroundColor: jaSegue
                                            ? theme.textColor
                                            : theme.buttonTextColor,
                                        side: BorderSide(
                                          color: theme.borderColor,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () =>
                                          auth.alternarSeguir(cpfLimpo),
                                      child: Text(
                                        jaSegue ? 'Seguindo' : 'Seguir',
                                        style: theme.getTextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: jaSegue
                                              ? theme.textColor
                                              : theme.buttonTextColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),

              if (contaPropria != null && _participantes.length > 1) ...[
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        (outrosParaSeguir.isEmpty || _seguindoTodos)
                            ? null
                            : () => _seguirTodos(auth),
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: Text(
                      outrosParaSeguir.isEmpty
                          ? 'Seguindo todos'
                          : 'Seguir todos',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
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
