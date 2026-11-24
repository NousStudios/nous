import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_editar_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/insights_publicacao_view.dart';

class DetalhesPubAcoesWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioEfetivo;
  final List<ReacaoSocial> reacoes;
  final int likes;
  final int deslikes;
  final int totalComentarios;
  final ReacaoSocial? minhaReacao;
  final ValueChanged<TipoReacaoSocial> onReagir;
  final VoidCallback onFocarComentario;
  final VoidCallback onRepublicar;
  final VoidCallback onEnviarNoChat;

  const DetalhesPubAcoesWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioEfetivo,
    required this.reacoes,
    required this.likes,
    required this.deslikes,
    required this.totalComentarios,
    required this.minhaReacao,
    required this.onReagir,
    required this.onFocarComentario,
    required this.onRepublicar,
    required this.onEnviarNoChat,
  });

  String _formatarDataHora(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$d/$m/${l.year} • $h:$min';
  }

  void _mostrarListaReacoes(BuildContext context, TipoReacaoSocial tipo) {
    DialogOpcoesPublicacao.mostrarListaReacoes(
      context,
      theme: theme,
      reacoes: reacoes,
      tipo: tipo,
    );
  }

  Widget _buildBotaoReacaoSemBorda({
    required IconData icone,
    required int contagem,
    required VoidCallback onTapIcone,
    required VoidCallback onTapContagem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTapIcone,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(icone, size: 19, color: theme.textColor),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTapContagem,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                '$contagem',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = usuarioEfetivo;
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBotaoReacaoSemBorda(
                  icone: minhaReacao?.tipo == TipoReacaoSocial.like
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_off_alt_rounded,
                  contagem: likes,
                  onTapIcone: () => onReagir(TipoReacaoSocial.like),
                  onTapContagem: () =>
                      _mostrarListaReacoes(context, TipoReacaoSocial.like),
                ),
                const SizedBox(width: 4),
                _buildBotaoReacaoSemBorda(
                  icone: minhaReacao?.tipo == TipoReacaoSocial.deslike
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_off_alt_rounded,
                  contagem: deslikes,
                  onTapIcone: () => onReagir(TipoReacaoSocial.deslike),
                  onTapContagem: () =>
                      _mostrarListaReacoes(context, TipoReacaoSocial.deslike),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Comentar',
                  icon: Icon(
                    Icons.mode_comment_outlined,
                    size: 18,
                    color: theme.textColor,
                  ),
                  onPressed: onFocarComentario,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Republicar no meu perfil',
                  icon: Icon(
                    Icons.repeat_rounded,
                    size: 19,
                    color: theme.textColor,
                  ),
                  onPressed: onRepublicar,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Enviar pelo chat',
                  icon: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                  onPressed: onEnviarNoChat,
                ),
                if (usuario != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Salvar conteúdo',
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 19,
                      color: theme.textColor,
                    ),
                    onPressed: () async {
                      final salvo = await DialogSalvarPublicacao.mostrar(
                        context,
                        theme: theme,
                        usuarioCpf: usuario.cpf,
                        publicacaoId: publicacao.id,
                      );
                      if (salvo == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Conteúdo salvo!'),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => InsightsPublicacaoView.abrir(
            context,
            theme: theme,
            publicacao: publicacao,
            totalCurtidas: likes,
            totalDeslikes: deslikes,
            totalComentarios: totalComentarios,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 13,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 3),
                Text(
                  '${publicacao.visualizacoes}',
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatarDataHora(publicacao.criadaEm),
          style: theme.getTextStyle(
            fontSize: 10.5,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  static Future<void> abrirMenuOpcoes(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required UsuarioNous? usuarioEfetivo,
    required bool ehAutor,
    required ValueChanged<PublicacaoSocial> onPublicacaoAtualizada,
    required VoidCallback onBaixarMidia,
    required VoidCallback onFecharTela,
  }) async {
    final acao = await DialogOpcoesPublicacao.mostrarMenuOpcoes(
      context,
      theme: theme,
      publicacao: publicacao,
      ehAutor: ehAutor,
      podeDenunciar: usuarioEfetivo != null,
    );

    if (!context.mounted || acao == null) return;
    switch (acao) {
      case 'fixar':
        final atualizada =
            await TimelineService.alternarFixarPublicacao(publicacao);
        if (context.mounted) {
          onPublicacaoAtualizada(atualizada);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                atualizada.fixada
                    ? 'Publicação fixada no topo!'
                    : 'Publicação desafixada.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      case 'editar':
        final atualizada = await DialogEditarPublicacao.mostrar(
          context,
          theme: theme,
          publicacao: publicacao,
        );
        if (atualizada != null && context.mounted) {
          onPublicacaoAtualizada(atualizada);
        }
      case 'arquivar':
        await TimelineService.arquivarPublicacao(
          publicacao,
          arquivar: !publicacao.arquivada,
        );
        if (context.mounted) onFecharTela();
      case 'excluir':
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.cardBackgroundColor,
            title: Text(
              'Excluir Publicação',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            content: Text(
              'Tem certeza que deseja excluir esta publicação?',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Excluir',
                  style: theme.getTextStyle(
                    color: theme.dangerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmar == true) {
          await TimelineService.excluirPublicacao(publicacao);
          if (context.mounted) onFecharTela();
        }
      case 'baixar':
        onBaixarMidia();
      case 'denunciar':
        if (usuarioEfetivo == null) return;
        final ok = await DialogDenunciaSocial.mostrar(
          context,
          theme: theme,
          denunciante: usuarioEfetivo,
          alvoCpf: publicacao.autorCpf,
          alvoNome: publicacao.autorNome,
          publicacaoId: publicacao.id,
        );
        if (ok == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Denúncia registrada.')),
          );
        }
    }
  }
}
