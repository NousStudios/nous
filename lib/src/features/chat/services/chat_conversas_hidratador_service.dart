import 'dart:async';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Especialista em enriquecer, hidratar e resolver nomes reais, avatares e contadores
/// de mensagens não lidas para a lista de conversas do Chat.
class ChatConversasHidratadorService {
  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  /// Obtém e hidrata a lista completa de conversas a partir do SQLite
  static Future<List<ConversaChat>> obterTodasConversas({
    String? cpfUsuario,
    String? lojaId,
    bool incluirArquivadas = false,
    required Future<Map<String, String>> Function([String? cpfLogado]) obterTitulosCustomizados,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();

    List<Map<String, dynamic>> rows;
    if (lojaId != null && lojaId.isNotEmpty) {
      final lojaIdLimpo =
          lojaId.startsWith('loja_') ? lojaId.substring(5) : lojaId;
      final lojaIdComPrefixo =
          lojaId.startsWith('loja_') ? lojaId : 'loja_$lojaId';
      rows = await db.query(
        'conversas_chat',
        where:
            '(loja_id = ? OR loja_id = ? OR id LIKE ? OR id LIKE ?) ${incluirArquivadas ? "" : "AND (arquivada IS NULL OR arquivada = 0)"}',
        whereArgs: [
          lojaIdComPrefixo,
          lojaIdLimpo,
          '${lojaIdComPrefixo}_%',
          'loja_${lojaIdLimpo}_%',
        ],
        orderBy:
            'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
      );
    } else {
      final cpfNorm =
          cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
      if (cpfNorm.isNotEmpty) {
        rows = await db.query(
          'conversas_chat',
          where:
              '${incluirArquivadas ? "" : "(arquivada IS NULL OR arquivada = 0) AND "}(participantes_json LIKE ? OR identificador = ? OR id LIKE ? OR eh_grupo = 1)',
          whereArgs: ['%$cpfNorm%', cpfNorm, '%$cpfNorm%'],
          orderBy:
              'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
        );
      } else {
        rows = await db.query(
          'conversas_chat',
          where: incluirArquivadas
              ? null
              : '(arquivada IS NULL OR arquivada = 0)',
          orderBy:
              'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
        );
      }
    }

    final excluidas = await ChatRepositorioSqlite.obterIdsConversasExcluidas();
    if (excluidas.isNotEmpty) {
      rows = rows.where((r) => !excluidas.contains(r['id'])).toList();
    }

    final cpfNormUsuario =
        cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
    final todasContas = await ContasNousService.carregarTodas();
    final mapaContasPorCpf = <String, UsuarioNous>{
      for (final c in todasContas) ChatRepositorioSqlite.normalizarCpf(c.cpf): c,
    };
    final contaLogada = mapaContasPorCpf[cpfNormUsuario];

    final mapaLojasPorId = <String, Loja?>{};
    Future<Loja?> obterLojaCacheada(String idBruto) async {
      final idLimpo = idBruto.startsWith('loja_') ? idBruto.substring(5) : idBruto;
      if (idLimpo.isEmpty) return null;
      if (mapaLojasPorId.containsKey(idLimpo)) {
        return mapaLojasPorId[idLimpo];
      }
      var l = await LojasService.carregarLojaPorId(idLimpo);
      l ??= await LojasService.carregarLojaPorId('loja_$idLimpo');
      mapaLojasPorId[idLimpo] = l;
      return l;
    }

    final lojaIdLimpoModo = (lojaId != null && lojaId.isNotEmpty)
        ? (lojaId.startsWith('loja_') ? lojaId.substring(5) : lojaId)
        : '';

    final mapaNaoLidas = <String, int>{};
    final mapaUltimaMsgStatus = <String, ({bool enviadaPorMim, String status})>{};

    try {
      final rowsNaoLidas = await db.rawQuery(
        'SELECT conversa_id, remetente_id FROM mensagens_chat WHERE lida = 0',
      );
      final idVisNorm = cpfNormUsuario;
      for (final nr in rowsNaoLidas) {
        final cid = nr['conversa_id'] as String? ?? '';
        final rem = nr['remetente_id'] as String? ?? '';
        final bool ehProprio;
        if (lojaIdLimpoModo.isNotEmpty) {
          final remLimpo = rem.startsWith('loja_') ? rem.substring(5) : rem;
          ehProprio = rem.startsWith('loja_') || remLimpo == lojaIdLimpoModo;
        } else {
          final remLimpo = rem.startsWith('loja_') ? rem.substring(5) : rem;
          String lojaIdConv = '';
          if (cid.startsWith('loja_') && cid.contains('_usuario_')) {
            lojaIdConv = cid.substring(5, cid.indexOf('_usuario_'));
          }
          final ehMsgLoja = rem.startsWith('loja_') ||
              (lojaIdConv.isNotEmpty && remLimpo == lojaIdConv);
          ehProprio = !ehMsgLoja &&
              (rem == (cpfUsuario ?? '') ||
                  (idVisNorm.isNotEmpty &&
                      ChatRepositorioSqlite.normalizarCpf(rem) == idVisNorm));
        }
        if (!ehProprio && cid.isNotEmpty) {
          mapaNaoLidas[cid] = (mapaNaoLidas[cid] ?? 0) + 1;
        }
      }

      final rowsUltimas = await db.rawQuery('''
        SELECT m.conversa_id, m.remetente_id, m.status_envio, m.lida, m.entregue
        FROM mensagens_chat m
        INNER JOIN (
          SELECT conversa_id, MAX(data_hora) AS max_data
          FROM mensagens_chat
          GROUP BY conversa_id
        ) u ON m.conversa_id = u.conversa_id AND m.data_hora = u.max_data
      ''');
      for (final ur in rowsUltimas) {
        final cid = ur['conversa_id'] as String? ?? '';
        if (cid.isEmpty) continue;
        final rem = ur['remetente_id'] as String? ?? '';
        final bool envPorMim;
        if (lojaIdLimpoModo.isNotEmpty) {
          final remLimpo = rem.startsWith('loja_') ? rem.substring(5) : rem;
          envPorMim = rem.startsWith('loja_') || remLimpo == lojaIdLimpoModo;
        } else {
          final remNorm = ChatRepositorioSqlite.normalizarCpf(rem);
          final remLimpo = rem.startsWith('loja_') ? rem.substring(5) : rem;
          String lojaIdConv = '';
          if (cid.startsWith('loja_') && cid.contains('_usuario_')) {
            lojaIdConv = cid.substring(5, cid.indexOf('_usuario_'));
          }
          final ehMsgLoja = rem.startsWith('loja_') ||
              (lojaIdConv.isNotEmpty && remLimpo == lojaIdConv);
          envPorMim = !ehMsgLoja &&
              cpfNormUsuario.isNotEmpty &&
              remNorm == cpfNormUsuario;
        }
        final lidaInt = (ur['lida'] as int? ?? 0) == 1;
        final entregueInt = (ur['entregue'] as int? ?? 0) == 1;
        final stBruto = ur['status_envio'] as String? ?? 'enviada';
        final String stFinal;
        if (lidaInt || stBruto == 'lida') {
          stFinal = 'lida';
        } else if (entregueInt || stBruto == 'entregue') {
          stFinal = 'entregue';
        } else {
          stFinal = 'enviada';
        }
        mapaUltimaMsgStatus[cid] = (enviadaPorMim: envPorMim, status: stFinal);
      }
    } catch (_) {}

    final titulosCustom = await obterTitulosCustomizados();
    final resultado = <ConversaChat>[];

    for (final r in rows) {
      final convId = r['id'] as String;
      final ultMsg = r['ultima_mensagem'] as String? ?? '';
      final dataHoraUlt = DateTime.tryParse(
            r['data_hora_ultima_mensagem'] as String? ?? '',
          ) ??
          DateTime.tryParse(r['atualizado_em'] as String? ?? '') ??
          DateTime.tryParse(r['criado_em'] as String? ?? '') ??
          DateTime.now();
      final naoLidas = mapaNaoLidas[convId] ?? 0;
      final msgs = const <MensagemChat>[];

      final titConversaDb = (r['titulo_conversa'] as String? ?? '').trim();
      var tituloFinal = (r['titulo'] as String? ?? '').trim();
      var tituloConversaFinal =
          titConversaDb.isNotEmpty ? titConversaDb : (titulosCustom[convId] ?? '');
      var subtituloFinal = r['subtitulo'] as String? ?? '';
      var fotoFinal = r['foto'] as String? ?? '';
      final ehConvLojaUsuario =
          convId.startsWith('loja_') && convId.contains('_usuario_');
      final ehLoja = ehConvLojaUsuario || (r['eh_loja'] as int? ?? 0) == 1;
      final ehGrupo = (r['eh_grupo'] as int? ?? 0) == 1;
      final nGrupo = (r['nome_grupo'] as String? ?? '').trim();
      String lojaIdExtraido = (r['loja_id'] as String? ?? '').trim();
      if (ehConvLojaUsuario && lojaIdExtraido.isEmpty) {
        lojaIdExtraido = convId.substring(5, convId.indexOf('_usuario_'));
      }
      String idNorm = '';
      String identificadorOverride = '';

      if (!ehGrupo &&
          ehLoja &&
          (convId.contains('loja_nous_coletiva') ||
              convId.contains('loja_nous') ||
              lojaIdExtraido == idLojaColetivaNous ||
              lojaIdExtraido == 'nous' ||
              tituloFinal.toLowerCase() == 'nous')) {
        continue;
      }

      if (ehGrupo && nGrupo.isNotEmpty) {
        if (tituloFinal.isEmpty ||
            tituloFinal == 'Conversa' ||
            tituloFinal == 'Grupo') {
          tituloFinal = nGrupo;
        }
      } else if (!ehGrupo && !ehLoja) {
        idNorm =
            ChatRepositorioSqlite.normalizarCpf(r['identificador'] as String? ?? '');
        if (idNorm.length != 11 ||
            (cpfNormUsuario.isNotEmpty && idNorm == cpfNormUsuario)) {
          idNorm = ChatRepositorioSqlite.extrairOutroCpf(convId, cpfNormUsuario);
        }
        final u = mapaContasPorCpf[idNorm];
        if (u != null) {
          final ehNomeProprioUsuario = contaLogada != null &&
              (tituloFinal == contaLogada.nome ||
                  tituloFinal == contaLogada.nomeExibicao ||
                  tituloFinal == contaLogada.nomePublico ||
                  tituloFinal == contaLogada.apelido ||
                  tituloFinal == contaLogada.apelidoExibicao);
          final ehFotoPropriaUsuario = contaLogada != null &&
              ((contaLogada.foto.isNotEmpty && fotoFinal == contaLogada.foto) ||
                  (contaLogada.fotoExibicao.isNotEmpty &&
                      fotoFinal == contaLogada.fotoExibicao));

          if (tituloFinal.isNotEmpty &&
              tituloFinal != 'Conversa' &&
              tituloFinal != 'Nova Conversa' &&
              tituloFinal != 'Contato' &&
              tituloFinal != 'Contato Nous' &&
              tituloFinal != u.nomeExibicao &&
              !ehNomeProprioUsuario &&
              tituloConversaFinal.isEmpty) {
            tituloConversaFinal = tituloFinal;
          }

          tituloFinal = u.nomeExibicao;

          if (fotoFinal.isEmpty ||
              !ImagemService.existe(fotoFinal) ||
              ehFotoPropriaUsuario) {
            fotoFinal = u.fotoExibicao;
          }
          if (subtituloFinal.isEmpty ||
              subtituloFinal == 'Conversa' ||
              subtituloFinal == 'Contato Nous' ||
              subtituloFinal == 'Usuário Nous') {
            subtituloFinal = u.usernameExibicao.isNotEmpty
                ? u.usernameExibicao
                : 'Usuário Nous';
          }
        }
      } else if (ehLoja) {
        final lojaObj = await obterLojaCacheada(lojaIdExtraido);
        if (lojaId != null && lojaId.isNotEmpty) {
          var idCliNorm = '';
          if (ehConvLojaUsuario) {
            idCliNorm = ChatRepositorioSqlite.normalizarCpf(
              convId.split('_usuario_').last,
            );
          }
          if (idCliNorm.length != 11) {
            idCliNorm = ChatRepositorioSqlite.normalizarCpf(
              r['identificador'] as String? ?? '',
            );
          }
          if (idCliNorm.length != 11) {
            idCliNorm = ChatRepositorioSqlite.extrairOutroCpf(convId, '');
          }
          if (idCliNorm.length == 11) {
            identificadorOverride = idCliNorm;
          }
          final u = mapaContasPorCpf[idCliNorm];
          if (u != null) {
            tituloFinal = u.nomeExibicao;
            if (u.fotoExibicao.isNotEmpty) {
              fotoFinal = u.fotoExibicao;
            } else if (fotoFinal.isEmpty ||
                !ImagemService.existe(fotoFinal) ||
                (lojaObj != null && fotoFinal == lojaObj.logo)) {
              fotoFinal = u.foto;
            }
            subtituloFinal = u.usernameExibicao.isNotEmpty
                ? u.usernameExibicao
                : 'Cliente Nous';
          } else if (contaLogada != null &&
              idCliNorm.length == 11 &&
              idCliNorm == cpfNormUsuario) {
            tituloFinal = contaLogada.nomeExibicao;
            fotoFinal = contaLogada.fotoExibicao;
            subtituloFinal = contaLogada.usernameExibicao.isNotEmpty
                ? contaLogada.usernameExibicao
                : 'Cliente Nous';
          } else if (lojaObj != null && idCliNorm.length == 11) {
            final cli = lojaObj.clientesLoja
                .where(
                  (c) =>
                      ChatRepositorioSqlite.normalizarCpf(c.cnpj) == idCliNorm,
                )
                .firstOrNull;
            if (cli != null && cli.nome.trim().isNotEmpty) {
              tituloFinal = cli.nome.trim();
              if (cli.foto.isNotEmpty) fotoFinal = cli.foto;
              subtituloFinal = 'Cliente';
            }
          }
        } else {
          if (lojaIdExtraido.isNotEmpty) {
            identificadorOverride = lojaIdExtraido;
          }
          if (lojaObj != null) {
            tituloFinal = lojaObj.nome;
            if (lojaObj.logo.isNotEmpty) {
              fotoFinal = lojaObj.logo;
            }
            subtituloFinal =
                lojaObj.categorias.isNotEmpty ? lojaObj.categorias : 'Loja Nous';
          } else {
            final ehFotoPropria = contaLogada != null &&
                ((contaLogada.foto.isNotEmpty && fotoFinal == contaLogada.foto) ||
                    (contaLogada.fotoExibicao.isNotEmpty &&
                        fotoFinal == contaLogada.fotoExibicao));
            if (ehFotoPropria) {
              fotoFinal = '';
            }
            if (subtituloFinal.isEmpty ||
                subtituloFinal == 'Conversa' ||
                subtituloFinal == 'Contato Nous' ||
                subtituloFinal == 'Cliente Nous') {
              subtituloFinal = 'Loja';
            }
          }
        }
      }
      if (tituloFinal.isEmpty || tituloFinal == 'Conversa') {
        tituloFinal =
            (subtituloFinal.isNotEmpty &&
                subtituloFinal != 'Conversa' &&
                subtituloFinal != 'Contato Nous')
            ? subtituloFinal
            : (ehGrupo
                  ? (nGrupo.isNotEmpty ? nGrupo : 'Grupo')
                  : 'Contato Nous');
      }

      String identificadorFinal = identificadorOverride.isNotEmpty
          ? identificadorOverride
          : (r['identificador'] as String? ?? convId);
      if (!ehGrupo && !ehLoja && idNorm.length == 11) {
        identificadorFinal = idNorm;
      }

      resultado.add(
        ConversaChat(
          id: convId,
          titulo: tituloFinal,
          subtitulo: subtituloFinal,
          foto: fotoFinal,
          identificador: identificadorFinal,
          ehLoja: ehLoja,
          ehGrupo: ehGrupo,
          nomeGrupo: nGrupo,
          tituloConversa: tituloConversaFinal,
          lojaId: lojaIdExtraido.isNotEmpty
              ? lojaIdExtraido
              : (r['loja_id'] as String?),
          participantesIds: ChatRepositorioSqlite.decodificarParticipantes(
            r['participantes_json'] as String?,
          ),
          ultimaMensagem: ultMsg,
          dataHoraUltimaMensagem: dataHoraUlt,
          naoLidasCount: naoLidas,
          mensagens: msgs,
          fixada: (r['fixada'] as int? ?? 0) == 1,
          arquivada: (r['arquivada'] as int? ?? 0) == 1,
          silenciada: (r['silenciada'] as int? ?? 0) == 1,
          atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
          ultimaMensagemEnviadaPorMim:
              mapaUltimaMsgStatus[convId]?.enviadaPorMim ?? false,
          statusUltimaMensagem:
              mapaUltimaMsgStatus[convId]?.status ?? '',
        ),
      );
    }

    return resultado;
  }
}
