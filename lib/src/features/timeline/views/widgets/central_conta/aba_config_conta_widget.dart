import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Aba visual de Configurações e Visibilidade de Timelines da Central da Conta.
class AbaConfigContaWidget extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final List<TipoFeedSocial> timelinesVisiveis;

  const AbaConfigContaWidget({
    super.key,
    required this.theme,
    required this.usuario,
    required this.timelinesVisiveis,
  });

  String _rotuloTimeline(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.livros:
        return 'Livros';
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
              builder: (_) => EditarPerfilDialog(usuario: usuario),
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
                value: timelinesVisiveis.contains(tipo),
                onChanged: (ativo) {
                  final nova = List<TipoFeedSocial>.from(timelinesVisiveis);
                  if (ativo) {
                    if (!nova.contains(tipo)) nova.add(tipo);
                  } else {
                    nova.remove(tipo);
                  }
                  TimelineService.salvarTimelinesVisiveis(
                    usuario.cpf,
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
