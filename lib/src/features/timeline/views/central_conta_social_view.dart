import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/abas_arquivos_conta_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/central_conta/aba_calendario_conta_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/central_conta/aba_config_conta_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/central_conta/aba_stories_conta_widget.dart';

/// Central "Conta" do Perfil Social (inspirada no Arquivo/Calendário e Configurações do Instagram).
class CentralContaSocialView extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous usuario;

  const CentralContaSocialView({
    super.key,
    required this.theme,
    required this.usuario,
  });

  static Future<void> abrir(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous usuario,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CentralContaSocialView(
          theme: theme,
          usuario: usuario,
        ),
      ),
    );
  }

  @override
  State<CentralContaSocialView> createState() => _CentralContaSocialViewState();
}

class _CentralContaSocialViewState extends State<CentralContaSocialView> {
  int _aba = 0; // 0: Calendário, 1: Stories, 2: Arquivados, 3: Excluídos, 4: Config
  List<StorySocial> _historicoStories = [];
  List<PublicacaoSocial> _publicacoesArquivadas = [];
  List<PublicacaoSocial> _publicacoesExcluidas = [];
  List<TipoFeedSocial> _timelinesVisiveis = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_recarregar);
    _recarregar();
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_recarregar);
    super.dispose();
  }

  Future<void> _recarregar() async {
    final stories = await TimelineService.listarTodosStoriesHistorico(
      widget.usuario.cpf,
    );
    final pubArq = await TimelineRepositorioSqlite
        .listarPublicacoesArquivadasDoUsuario(widget.usuario.cpf);
    final pubExc = await TimelineRepositorioSqlite
        .listarPublicacoesExcluidasDoUsuario(widget.usuario.cpf);
    final visiveis = await TimelineService.obterTimelinesVisiveis(
      widget.usuario.cpf,
    );
    if (!mounted) return;
    setState(() {
      _historicoStories = stories;
      _publicacoesArquivadas = pubArq;
      _publicacoesExcluidas = pubExc;
      _timelinesVisiveis = visiveis;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.textColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Arquivos da Conta',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),

                // Abas superiores
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildBotaoAba(
                          theme,
                          0,
                          Icons.calendar_month_outlined,
                          'Calendário',
                        ),
                        const SizedBox(width: 6),
                        _buildBotaoAba(
                          theme,
                          1,
                          Icons.history_toggle_off_rounded,
                          'Stories (${_historicoStories.where((s) => !s.arquivado).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildBotaoAba(
                          theme,
                          2,
                          Icons.archive_outlined,
                          'Arquivados (${_publicacoesArquivadas.length + _historicoStories.where((s) => s.arquivado).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildBotaoAba(
                          theme,
                          3,
                          Icons.delete_outline,
                          'Excluídos (${_publicacoesExcluidas.length})',
                        ),
                        const SizedBox(width: 6),
                        _buildBotaoAba(
                          theme,
                          4,
                          Icons.tune_rounded,
                          'Config',
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _carregando
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _aba == 0
                          ? AbaCalendarioContaWidget(
                              theme: theme,
                              usuario: widget.usuario,
                              historicoStories: _historicoStories,
                            )
                          : _aba == 1
                              ? AbaStoriesContaWidget(
                                  theme: theme,
                                  usuario: widget.usuario,
                                  historicoStories: _historicoStories,
                                )
                              : _aba == 2
                                  ? AbaArquivadosContaWidget(
                                      theme: theme,
                                      publicacoesArquivadas:
                                          _publicacoesArquivadas,
                                      storiesArquivados: _historicoStories
                                          .where((s) => s.arquivado)
                                          .toList(),
                                      onRestaurarPublicacao: (pub) async {
                                        await TimelineService.arquivarPublicacao(
                                          pub,
                                          arquivar: false,
                                        );
                                        await _recarregar();
                                      },
                                      onRestaurarStory: (story) async {
                                        await TimelineRepositorioSqlite
                                            .salvarStory(
                                          story.copyWith(
                                            arquivado: false,
                                            atualizadoEm: DateTime.now(),
                                          ),
                                        );
                                        TimelineService.notificarAlteracao();
                                        await _recarregar();
                                      },
                                    )
                                  : _aba == 3
                                      ? AbaExcluidosContaWidget(
                                          theme: theme,
                                          publicacoesExcluidas:
                                              _publicacoesExcluidas,
                                          onRecuperarPublicacao: (pub) async {
                                            await TimelineService
                                                .restaurarPublicacaoExcluida(
                                              pub,
                                            );
                                            await _recarregar();
                                          },
                                        )
                                      : AbaConfigContaWidget(
                                          theme: theme,
                                          usuario: context
                                                  .watch<AuthProvider>()
                                                  .contaAtual ??
                                              widget.usuario,
                                          timelinesVisiveis: _timelinesVisiveis,
                                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoAba(
    AppTheme theme,
    int indice,
    IconData icone,
    String rotulo,
  ) {
    final ativo = _aba == indice;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _aba = indice),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: ativo ? theme.buttonColor : theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ativo
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 16,
              color: ativo ? theme.buttonTextColor : theme.textColor,
            ),
            const SizedBox(width: 5),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                color: ativo ? theme.buttonTextColor : theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
