import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

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

  int _aba = 0; // 0: Calendário de Stories, 1: Arquivo & Destaques, 2: Conta & Timelines
  DateTime _mesVisivel = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<StorySocial> _historicoStories = [];
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
    final visiveis = await TimelineService.obterTimelinesVisiveis(
      widget.usuario.cpf,
    );
    if (!mounted) return;
    setState(() {
      _historicoStories = stories;
      _timelinesVisiveis = visiveis;
      _carregando = false;
    });
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesVisivel = DateTime(_mesVisivel.year, _mesVisivel.month + delta, 1);
    });
  }

  List<StorySocial> _storiesDoDia(int ano, int mes, int dia) {
    final lista = _historicoStories.where((s) {
      final l = s.criadoEm.toLocal();
      return l.year == ano && l.month == mes && l.day == dia;
    }).toList();
    lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    return lista;
  }

  String _rotuloTimeline(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.musicas:
        return 'Músicas';
      case TipoFeedSocial.escritos:
        return 'Escritos';
      case TipoFeedSocial.interacoes:
        return 'Interações';
      case TipoFeedSocial.republicacoes:
        return 'Republicações';
      case TipoFeedSocial.salvos:
        return 'Conteúdos Salvos';
      case TipoFeedSocial.likes:
        return 'Curtidas (Likes)';
      case TipoFeedSocial.deslikes:
        return 'Deslikes';
      case TipoFeedSocial.denuncias:
        return 'Denúncias';
    }
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
                          'Conta e Arquivo de Stories',
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
                  child: Row(
                    children: [
                      _buildBotaoAba(
                        theme,
                        0,
                        Icons.calendar_month_outlined,
                        'Calendário',
                      ),
                      const SizedBox(width: 8),
                      _buildBotaoAba(
                        theme,
                        1,
                        Icons.history_toggle_off_rounded,
                        'Arquivo (${_historicoStories.length})',
                      ),
                      const SizedBox(width: 8),
                      _buildBotaoAba(
                        theme,
                        2,
                        Icons.tune_rounded,
                        'Configurações',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _carregando
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _aba == 0
                          ? _buildAbaCalendario(theme)
                          : _aba == 1
                              ? _buildAbaArquivo(theme)
                              : _buildAbaConfiguracoes(theme),
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
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _aba = indice),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
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
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                    color: ativo ? theme.buttonTextColor : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaCalendario(AppTheme theme) {
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

  Widget _buildAbaArquivo(AppTheme theme) {
    if (_historicoStories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Seus stories publicados aparecerão arquivados aqui.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _historicoStories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final s = _historicoStories[index];
        final dt = s.criadoEm.toLocal();
        final dataFmt =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

        return GestureDetector(
          onTap: () => DialogVisualizarStory.mostrar(
            context,
            theme: theme,
            story: s,
            stories: _historicoStories,
            indiceInicial: index,
            ehAutor: true,
            usuarioLogado: widget.usuario,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: s.ehDestaquePermanente
                    ? theme.buttonColor
                    : theme.borderColor.withValues(alpha: 0.45),
                width: s.ehDestaquePermanente ? 1.8 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s.caminhoMidia.isNotEmpty)
                  FutureBuilder<String?>(
                    future: TimelineService.resolverCaminhoMidia(
                      s.caminhoMidia,
                    ),
                    builder: (_, snap) {
                      if (snap.data == null) return const SizedBox.shrink();
                      return Image.file(
                        File(snap.data!),
                        fit: BoxFit.cover,
                        cacheWidth: 360,
                      );
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        s.texto,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dataFmt,
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => TimelineService.alternarDestaqueStory(s),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.60),
                      ),
                      child: Icon(
                        s.ehDestaquePermanente
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbaConfiguracoes(AppTheme theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.person_outline, color: theme.buttonColor),
          title: Text(
            'Editar Perfil Público, Biografia e Links',
            style: theme.getTextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          subtitle: Text(
            'Personalize cores, foto pública, apelido e links',
            style: theme.getTextStyle(
              fontSize: 11.5,
              color: theme.secondaryTextColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.secondaryTextColor,
          ),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (_) => EditarPerfilDialog(usuario: widget.usuario),
            );
          },
        ),
        Divider(color: theme.borderColor.withValues(alpha: 0.35)),
        const SizedBox(height: 8),
        Text(
          'Timelines Visíveis no Perfil Público',
          style: theme.getTextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ative ou oculte as abas exibidas no seu perfil público.',
          style: theme.getTextStyle(
            fontSize: 11.5,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        for (final tipo in TipoFeedSocial.values)
          if (tipo != TipoFeedSocial.republicacoes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _rotuloTimeline(tipo),
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.textColor,
                ),
              ),
              trailing: ThemedSwitch(
                value: _timelinesVisiveis.contains(tipo),
                onChanged: (ativo) {
                  final nova = List<TipoFeedSocial>.from(_timelinesVisiveis);
                  if (ativo) {
                    if (!nova.contains(tipo)) nova.add(tipo);
                  } else {
                    nova.remove(tipo);
                  }
                  TimelineService.salvarTimelinesVisiveis(
                    widget.usuario.cpf,
                    nova,
                  );
                },
                theme: theme,
              ),
            ),
      ],
    );
  }
}
