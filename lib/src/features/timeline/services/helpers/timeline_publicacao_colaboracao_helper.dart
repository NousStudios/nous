import 'package:flutter/foundation.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_publicacao_feed_helper.dart';
import 'package:nous/src/features/timeline/services/timeline_interacoes_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Resultado da resolução de coautores aceitos, pendentes e recém-convidados.
class ResolucaoCoautores {
  final List<String> aceitos;
  final List<String> pendentes;
  final List<String> novosConvidados;

  const ResolucaoCoautores({
    required this.aceitos,
    required this.pendentes,
    required this.novosConvidados,
  });
}

/// Helper responsável por convites, respostas, cancelamentos e resolução de
/// coautores em publicações colaborativas.
class TimelinePublicacaoColaboracaoHelper {
  TimelinePublicacaoColaboracaoHelper._();

  static ResolucaoCoautores resolverCoautoresEdicao({
    required PublicacaoSocial pub,
    required List<String>? coautoresCpfs,
  }) {
    if (coautoresCpfs == null) {
      return ResolucaoCoautores(
        aceitos: pub.coautoresCpfs,
        pendentes: pub.coautoresPendentesCpfs,
        novosConvidados: const [],
      );
    }
    final autorNorm = TimelineRepositorioSqlite.normalizarCpf(pub.autorCpf);
    final desejados = coautoresCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty && c != autorNorm)
        .toSet();
    final jaAceitos =
        pub.coautoresCpfs.map(TimelineRepositorioSqlite.normalizarCpf).toSet();
    final jaPendentes = pub.coautoresPendentesCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .toSet();
    final aceitos = desejados.where((c) => jaAceitos.contains(c)).toList();
    final pendentes = desejados.where((c) => !jaAceitos.contains(c)).toList();
    final novosConvidados =
        pendentes.where((c) => !jaPendentes.contains(c)).toList();
    return ResolucaoCoautores(
      aceitos: aceitos,
      pendentes: pendentes,
      novosConvidados: novosConvidados,
    );
  }

  static Future<void> notificarConvitesColaboracao({
    required List<String> convidadosCpfs,
    required String autorCpf,
    required String autorNome,
    required String autorFoto,
    required String publicacaoId,
  }) async {
    for (final destCpf in convidadosCpfs) {
      await TimelineInteracoesService.emitirNotificacaoSocial(
        destinatarioCpf: destCpf,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        tipo: TipoNotificacaoSocial.conviteColaboracao,
        publicacaoId: publicacaoId,
        resumo: '$autorNome marcou você para colaborar em uma publicação.',
      );
    }
  }

  static Future<PublicacaoSocial?> responderConviteColaboracao({
    required String publicacaoId,
    required String usuarioCpf,
    required bool aceitar,
    String? notificacaoId,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    if (cpfNorm.isEmpty) return null;
    final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
      publicacaoId,
    );
    if (pub != null) {
      final novosPendentes = pub.coautoresPendentesCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty && c != cpfNorm)
          .toSet()
          .toList();
      final novosAceitos = pub.coautoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (aceitar && !novosAceitos.contains(cpfNorm)) {
        novosAceitos.add(cpfNorm);
      }
      final atualizada = pub.copyWith(
        coautoresCpfs: novosAceitos,
        coautoresPendentesCpfs: novosPendentes,
        atualizadaEm: DateTime.now(),
      );
      await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
      if (aceitar) {
        await TimelinePublicacaoFeedHelper.ativarTimelineAutomaticamente(
          cpfNorm,
          atualizada.tipo,
          onNotificar: onNotificar,
        );
      }
      onNotificar?.call();
      TimelineSyncService.despacharEventoRede(
        'timeline_publicacao',
        {'publicacao': atualizada.toJson()},
      );
      if (notificacaoId != null && notificacaoId.isNotEmpty) {
        await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(
          notificacaoId,
        );
      }
      return atualizada;
    }
    if (notificacaoId != null && notificacaoId.isNotEmpty) {
      await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(
        notificacaoId,
      );
      onNotificar?.call();
    }
    return null;
  }

  static Future<PublicacaoSocial> cancelarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpfAlvo);
    final novosPendentes = publicacao.coautoresPendentesCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty && c != cpfNorm)
        .toSet()
        .toList();
    final atualizada = publicacao.copyWith(
      coautoresPendentesCpfs: novosPendentes,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
    return atualizada;
  }

  static Future<void> reenviarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpfAlvo);
    if (cpfNorm.isEmpty) return;
    await notificarConvitesColaboracao(
      convidadosCpfs: [cpfNorm],
      autorCpf: publicacao.autorCpf,
      autorNome: publicacao.autorNome,
      autorFoto: publicacao.autorFoto,
      publicacaoId: publicacao.id,
    );
  }
}
