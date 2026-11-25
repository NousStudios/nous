import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

/// Diálogos detalhados de listas e gráficos de engajamento dos insights.
class InsightsEngajamentoDialogs {
  const InsightsEngajamentoDialogs._();

  /// Formata uma duração em segundos para exibição compacta (ex.: `45s`, `2m 10s`).
  static String formatarTempo(int segundos) {
    if (segundos <= 0) return '0s';
    if (segundos < 60) return '${segundos}s';
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return '${min}m ${seg}s';
  }

  static String _classificarEngajamento(int segundos) {
    if (segundos >= 30) return 'Muito engajado';
    if (segundos >= 10) return 'Engajado';
    return 'Leitura rápida';
  }

  /// Exibe o diálogo com quem visualizou a publicação.
  static Future<void> mostrarListaVisualizadores(
    BuildContext context, {
    required AppTheme theme,
    required List<String> visualizadoresCpfs,
    required Map<String, UsuarioNous> contasPorCpf,
    required Future<void> Function(BuildContext ctxDialog, String cpf)
        onAbrirPerfil,
  }) {
    final cpfs = visualizadoresCpfs
        .map((c) => c.replaceAll(RegExp(r'\D'), ''))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return showDialog<void>(
      context: context,
      builder: (ctx) => _InsightDialogShell(
        theme: theme,
        titulo: 'Quem visualizou (${cpfs.length})',
        maxWidth: 400,
        maxHeightFactor: 0.75,
        child: cpfs.isEmpty
            ? _MensagemVaziaDialog(
                theme: theme,
                mensagem: 'Nenhuma visualização nominal registrada ainda.',
              )
            : Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cpfs.length,
                  itemBuilder: (_, i) {
                    final cpf = cpfs[i];
                    final conta = contasPorCpf[cpf];
                    final nome = conta?.nomeExibicao.isNotEmpty == true
                        ? conta!.nomeExibicao
                        : cpf;
                    final handle = conta?.usernameExibicao ?? '';
                    return ListTile(
                      leading: AvatarComStoryWidget(
                        theme: theme,
                        cpf: cpf,
                        nome: nome,
                        foto: conta?.fotoExibicao ?? '',
                        radius: 17,
                        usuario: conta,
                      ),
                      title: Text(
                        nome,
                        style: theme.getTextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      subtitle: handle.isNotEmpty
                          ? Text(
                              handle,
                              style: theme.getTextStyle(
                                fontSize: 11.5,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      onTap: () => onAbrirPerfil(ctx, cpf),
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// Exibe o gráfico de engajamento por tempo de permanência.
  static Future<void> mostrarGraficoTempoEngajamento(
    BuildContext context, {
    required AppTheme theme,
    required Map<String, int> tempoPorVisualizador,
    required Map<String, UsuarioNous> contasPorCpf,
    required Future<void> Function(BuildContext ctxDialog, String cpf)
        onAbrirPerfil,
  }) {
    final entradas = tempoPorVisualizador.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSeg = entradas.isNotEmpty ? entradas.first.value : 1;

    return showDialog<void>(
      context: context,
      builder: (ctx) => _InsightDialogShell(
        theme: theme,
        titulo: 'Engajamento por Tempo',
        maxWidth: 460,
        maxHeightFactor: 0.80,
        child: entradas.isEmpty
            ? _MensagemVaziaDialog(
                theme: theme,
                mensagem:
                    'Ainda não há registros individuais de tempo de permanência.',
                textAlign: TextAlign.center,
              )
            : Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: entradas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final entry = entradas[i];
                    final cpf = entry.key.replaceAll(RegExp(r'\D'), '');
                    final seg = entry.value;
                    final conta = contasPorCpf[cpf];
                    final nome = conta?.nomeExibicao.isNotEmpty == true
                        ? conta!.nomeExibicao
                        : cpf;
                    final fracao = (seg / maxSeg).clamp(0.05, 1.0);
                    final nivel = _classificarEngajamento(seg);

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onAbrirPerfil(ctx, cpf),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                AvatarComStoryWidget(
                                  theme: theme,
                                  cpf: cpf,
                                  nome: nome,
                                  foto: conta?.fotoExibicao ?? '',
                                  radius: 15,
                                  usuario: conta,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: seg >= 30
                                        ? theme.buttonColor
                                            .withValues(alpha: 0.16)
                                        : theme.backgroundColor
                                            .withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    nivel,
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: seg >= 30
                                          ? theme.buttonColor
                                          : theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatarTempo(seg),
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: fracao,
                                minHeight: 8,
                                backgroundColor:
                                    theme.borderColor.withValues(alpha: 0.25),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  seg >= 30
                                      ? theme.buttonColor
                                      : theme.textColor.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// Exibe a lista de autores dos comentários da publicação.
  static Future<void> mostrarListaComentarios(
    BuildContext context, {
    required AppTheme theme,
    required List<ComentarioSocial> comentarios,
    required Future<void> Function(BuildContext ctxDialog, String cpf)
        onAbrirPerfil,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _InsightDialogShell(
        theme: theme,
        titulo: 'Quem comentou (${comentarios.length})',
        maxWidth: 420,
        maxHeightFactor: 0.75,
        child: comentarios.isEmpty
            ? _MensagemVaziaDialog(
                theme: theme,
                mensagem: 'Nenhum comentário registrado ainda.',
              )
            : Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: comentarios.length,
                  itemBuilder: (_, i) {
                    final c = comentarios[i];
                    final nome =
                        c.autorNome.isNotEmpty ? c.autorNome : c.autorCpf;
                    return ListTile(
                      leading: AvatarComStoryWidget(
                        theme: theme,
                        cpf: c.autorCpf,
                        nome: nome,
                        foto: c.autorFoto,
                        radius: 17,
                      ),
                      title: Text(
                        nome,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      subtitle: Text(
                        c.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      onTap: () => onAbrirPerfil(ctx, c.autorCpf),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _InsightDialogShell extends StatelessWidget {
  final AppTheme theme;
  final String titulo;
  final double maxWidth;
  final double maxHeightFactor;
  final Widget child;

  const _InsightDialogShell({
    required this.theme,
    required this.titulo,
    required this.maxWidth,
    required this.maxHeightFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      titulo,
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.35)),
            child,
          ],
        ),
      ),
    );
  }
}

class _MensagemVaziaDialog extends StatelessWidget {
  final AppTheme theme;
  final String mensagem;
  final TextAlign? textAlign;

  const _MensagemVaziaDialog({
    required this.theme,
    required this.mensagem,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        mensagem,
        textAlign: textAlign,
        style: theme.getTextStyle(
          fontSize: 12.5,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }
}
