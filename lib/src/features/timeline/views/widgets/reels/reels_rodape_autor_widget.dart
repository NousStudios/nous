import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';

/// Formata data e hora para exibição no rodapé e na descrição do Reels.
String formatarDataReels(DateTime d) {
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  final ano = d.year;
  final hora = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dia/$mes/$ano • $hora:$min';
}

/// Rodapé esquerdo do visualizador Reels compacto com autor, prévia de 2 linhas
/// da legenda, miniaturas de seguidos que interagiram, visualizações e data.
class ReelsRodapeAutorWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;
  final List<UsuarioNous> coautoresResolvidos;
  final List<ReacaoSocial> reacoes;
  final List<PublicacaoSocial> republicacoes;
  final VoidCallback onAbrirDescricao;

  const ReelsRodapeAutorWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    this.usuarioLogado,
    required this.coautoresResolvidos,
    required this.reacoes,
    required this.republicacoes,
    required this.onAbrirDescricao,
  });

  List<InteracaoUsuarioResumo> _construirResumoInteracoes() {
    final mapa = <String, InteracaoUsuarioResumo>{};
    for (final r in reacoes) {
      final cpf = r.usuarioCpf.replaceAll(RegExp(r'\D'), '');
      if (cpf.isEmpty) continue;
      final atual = mapa[cpf];
      mapa[cpf] = InteracaoUsuarioResumo(
        cpf: cpf,
        nome: r.usuarioNome.isNotEmpty
            ? r.usuarioNome
            : (atual?.nome ?? cpf),
        foto: r.usuarioFoto.isNotEmpty
            ? r.usuarioFoto
            : (atual?.foto ?? ''),
        deuLike: (atual?.deuLike ?? false) || r.tipo == TipoReacaoSocial.like,
        deuDeslike:
            (atual?.deuDeslike ?? false) || r.tipo == TipoReacaoSocial.deslike,
        republicou: atual?.republicou ?? false,
      );
    }
    for (final rep in republicacoes) {
      final cpf = rep.autorCpf.replaceAll(RegExp(r'\D'), '');
      if (cpf.isEmpty) continue;
      final atual = mapa[cpf];
      mapa[cpf] = InteracaoUsuarioResumo(
        cpf: cpf,
        nome: rep.autorNome.isNotEmpty
            ? rep.autorNome
            : (atual?.nome ?? cpf),
        foto: rep.autorFoto.isNotEmpty
            ? rep.autorFoto
            : (atual?.foto ?? ''),
        deuLike: atual?.deuLike ?? false,
        deuDeslike: atual?.deuDeslike ?? false,
        republicou: true,
      );
    }
    return mapa.values.toList();
  }

  Widget _buildMiniaturasSeguidos(
    BuildContext context,
    List<InteracaoUsuarioResumo> todasInteracoes,
  ) {
    if (todasInteracoes.isEmpty) return const SizedBox.shrink();
    final seguindoSet = (usuarioLogado?.seguindo ?? const <String>[])
        .map((c) => c.replaceAll(RegExp(r'\D'), ''))
        .where((c) => c.isNotEmpty)
        .toSet();
    final seguidos = todasInteracoes
        .where((i) => seguindoSet.contains(i.cpf))
        .take(3)
        .toList();
    if (seguidos.isEmpty) return const SizedBox.shrink();

    final largura = 22.0 + (seguidos.length - 1) * 14.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => DialogOpcoesPublicacao.mostrarTodasInteracoes(
        context,
        theme: theme,
        interacoes: todasInteracoes,
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: largura,
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < seguidos.length; i++)
                Positioned(
                  left: i * 14.0,
                  top: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarComStoryWidget(
                        theme: theme,
                        cpf: seguidos[i].cpf,
                        nome: seguidos[i].nome,
                        foto: seguidos[i].foto,
                        radius: 11,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            seguidos[i].deuLike
                                ? Icons.thumb_up_alt_rounded
                                : seguidos[i].republicou
                                    ? Icons.repeat_rounded
                                    : Icons.thumb_down_alt_rounded,
                            size: 8,
                            color: seguidos[i].deuDeslike &&
                                    !seguidos[i].deuLike &&
                                    !seguidos[i].republicou
                                ? theme.secondaryTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todasInteracoes = _construirResumoInteracoes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CabecalhoAutorColaboradoresWidget(
          theme: theme,
          publicacao: publicacao,
          coautoresResolvidos: coautoresResolvidos,
        ),
        if (publicacao.texto.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAbrirDescricao,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  publicacao.texto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ver descrição completa',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            _buildMiniaturasSeguidos(context, todasInteracoes),
            Expanded(
              child: Text(
                publicacao.tipo == TipoFeedSocial.videos
                    ? '${publicacao.visualizacoes} visualizações • ${formatarDataReels(publicacao.criadaEm)}'
                    : formatarDataReels(publicacao.criadaEm),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
