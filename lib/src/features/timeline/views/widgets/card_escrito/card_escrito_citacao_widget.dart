import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/widget_midia_publicacao.dart';

/// Bloco de publicação citada (quote) exibido dentro do card de escrito.
class CardEscritoCitacaoWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacaoCitada;
  final UsuarioNous? usuarioLogado;

  const CardEscritoCitacaoWidget({
    super.key,
    required this.theme,
    required this.publicacaoCitada,
    required this.usuarioLogado,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => DialogDetalhesPublicacao.mostrar(
        context,
        theme: theme,
        publicacao: publicacaoCitada,
        usuarioLogado: usuarioLogado,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarComStoryWidget(
                  theme: theme,
                  cpf: publicacaoCitada.autorCpf,
                  nome: publicacaoCitada.autorNome,
                  foto: publicacaoCitada.autorFoto,
                  radius: 10,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    publicacaoCitada.autorNome.isNotEmpty
                        ? publicacaoCitada.autorNome
                        : 'Publicação original',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            if (publicacaoCitada.texto.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                publicacaoCitada.texto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
            if (publicacaoCitada.midias.isNotEmpty) ...[
              const SizedBox(height: 8),
              WidgetMidiaPublicacao(
                theme: theme,
                publicacao: publicacaoCitada,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
