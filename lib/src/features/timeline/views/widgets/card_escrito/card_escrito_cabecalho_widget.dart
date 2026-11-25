import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_colaboradores_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

/// Cabeçalho do card de escrito com avatar, nome do autor, data/hora,
/// indicador de colaboradores, @username, ícone de fixado e menu de opções.
class CardEscritoCabecalhoWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? autorResolvido;
  final List<UsuarioNous> coautoresResolvidos;
  final bool ehAutor;
  final bool abrirDetalhesAoTocarCabecalho;
  final VoidCallback onAbrirDetalhes;
  final VoidCallback onVisitarAutor;
  final VoidCallback onAbrirMenuOpcoes;

  const CardEscritoCabecalhoWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.autorResolvido,
    required this.coautoresResolvidos,
    required this.ehAutor,
    required this.abrirDetalhesAoTocarCabecalho,
    required this.onAbrirDetalhes,
    required this.onVisitarAutor,
    required this.onAbrirMenuOpcoes,
  });

  String _formatarDataHoraTweet(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    return '$h:$min • $d/$m/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nomeAutor = autorResolvido?.nomeExibicao.isNotEmpty == true
        ? autorResolvido!.nomeExibicao
        : (publicacao.autorNome.isNotEmpty
            ? publicacao.autorNome
            : 'Cidadão Nous');
    final handleAutor = autorResolvido?.usernameExibicao ?? '';
    final acaoCabecalho =
        abrirDetalhesAoTocarCabecalho ? onAbrirDetalhes : onVisitarAutor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IgnorePointer(
          ignoring: abrirDetalhesAoTocarCabecalho,
          child: AvatarComStoryWidget(
            theme: theme,
            cpf: publicacao.autorCpf,
            nome: nomeAutor,
            foto: autorResolvido?.fotoExibicao ?? publicacao.autorFoto,
            radius: 20,
            onTapSemStory: acaoCabecalho,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: acaoCabecalho,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nomeAutor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_formatarDataHoraTweet(publicacao.criadaEm)}',
                      style: theme.getTextStyle(
                        fontSize: 10.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    if (coautoresResolvidos.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => DialogColaboradoresPublicacao.mostrar(
                          context,
                          theme: theme,
                          publicacao: publicacao,
                        ),
                        child: Text(
                          '+ ${coautoresResolvidos.length} colab.',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (handleAutor.isNotEmpty)
                  Text(
                    handleAutor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (publicacao.fixada)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.push_pin_rounded,
              size: 15,
              color: theme.textColor,
            ),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          tooltip: 'Mais opções',
          icon: Icon(
            Icons.more_horiz_rounded,
            color: theme.secondaryTextColor,
          ),
          onPressed: onAbrirMenuOpcoes,
        ),
      ],
    );
  }
}
