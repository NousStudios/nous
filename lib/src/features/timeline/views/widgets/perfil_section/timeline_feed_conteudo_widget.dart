import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_publicacao_completo_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/lista_interacoes_perfil_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/perfil_section/timeline_galeria_grid_widget.dart';

/// Renderiza o conteúdo principal do feed selecionado no perfil público.
class TimelineFeedConteudoWidget extends StatelessWidget {
  final AppTheme theme;
  final FeedPersonalizado? feedExtraSelecionado;
  final TipoFeedSocial? tipoSelecionado;
  final bool estaEmGaleria;
  final List<PublicacaoSocial> publicacoes;
  final List<RegistroInteracaoUsuario> interacoes;
  final List<DenunciaSocial> denuncias;
  final UsuarioNous contaPerfil;
  final UsuarioNous? usuarioLogado;
  final bool ehProprioUsuario;
  final bool modoGaleria3Colunas;
  final Future<void> Function() onRecarregar;

  const TimelineFeedConteudoWidget({
    super.key,
    required this.theme,
    required this.feedExtraSelecionado,
    required this.tipoSelecionado,
    required this.estaEmGaleria,
    required this.publicacoes,
    required this.interacoes,
    required this.denuncias,
    required this.contaPerfil,
    required this.usuarioLogado,
    required this.ehProprioUsuario,
    required this.modoGaleria3Colunas,
    required this.onRecarregar,
  });

  @override
  Widget build(BuildContext context) {
    if (feedExtraSelecionado != null) {
      final extra = feedExtraSelecionado!;
      final origem = extra.urlOuIdentificador.isNotEmpty
          ? extra.urlOuIdentificador
          : 'local';
      return EstadoVazioContainer(
        theme: theme,
        mensagem:
            'Feed conectado: ${extra.titulo}\nOrigem: ${extra.origem.name} ($origem)',
      );
    }

    if (tipoSelecionado == TipoFeedSocial.interacoes) {
      return ListaInteracoesPerfilWidget(
        theme: theme,
        interacoes: interacoes,
        denuncias: denuncias,
        cpfPerfil: contaPerfil.cpf,
        nomePerfil: contaPerfil.nomeExibicao,
        fotoPerfil: contaPerfil.fotoExibicao,
        usuarioLogado: usuarioLogado,
      );
    }

    if (tipoSelecionado == TipoFeedSocial.denuncias) {
      if (denuncias.isEmpty) {
        return EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma denúncia registrada.',
        );
      }
      final cpfLimpo = contaPerfil.cpf.replaceAll(RegExp(r'\D'), '');
      return Column(
        children: denuncias.map((d) {
          final euDenunciei = d.denuncianteCpf == cpfLimpo;
          return Card(
            color: theme.cardBackgroundColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: theme.dangerColor),
              title: Text(
                euDenunciei
                    ? 'Denúncia feita contra ${d.alvoNome}'
                    : 'Denúncia recebida de ${d.denuncianteNome}',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              subtitle: Text(
                d.motivo,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (publicacoes.isEmpty) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Nenhuma publicação neste feed ainda.',
      );
    }

    if (tipoSelecionado != null && estaEmGaleria) {
      return TimelineGaleriaGridWidget(
        theme: theme,
        publicacoes: publicacoes,
        usuarioLogado: usuarioLogado,
        ehProprioUsuario: ehProprioUsuario,
        modoGaleria3Colunas: modoGaleria3Colunas,
        onRecarregar: onRecarregar,
      );
    }

    return Column(
      children: publicacoes.asMap().entries.map((entry) {
        final pub = entry.value;
        final ehEscrito = pub.tipo == TipoFeedSocial.escritos ||
            (tipoSelecionado == TipoFeedSocial.republicacoes &&
                pub.midias.isEmpty);
        if (ehEscrito) {
          return CardEscritoWidget(
            key: ValueKey('feed_escrito_${tipoSelecionado?.name}_${pub.id}'),
            theme: theme,
            publicacao: pub,
            usuarioLogado: usuarioLogado,
            listaPublicacoes: publicacoes,
            indiceInicial: entry.key,
            abrirDetalhesAoTocarCabecalho: true,
          );
        }
        return CardPublicacaoCompletoWidget(
          key: ValueKey('feed_card_${tipoSelecionado?.name}_${pub.id}'),
          theme: theme,
          publicacao: pub,
          usuarioLogado: usuarioLogado,
          listaPublicacoes: publicacoes,
          indiceInicial: entry.key,
          abrirDetalhesAoTocarCabecalho: true,
          subtituloRepublicadoPor:
              tipoSelecionado == TipoFeedSocial.republicacoes
                  ? contaPerfil.nomeExibicao
                  : null,
        );
      }).toList(),
    );
  }
}
