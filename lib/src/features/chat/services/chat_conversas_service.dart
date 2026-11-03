import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class ChatConversasService {
  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  static Future<List<ConversaChat>> obterTodasConversas({
    String? cpfUsuario,
    String? lojaId,
    bool incluirArquivadas = false,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();

    List<Map<String, dynamic>> rows;
    if (lojaId != null && lojaId.isNotEmpty) {
      rows = await db.query(
        'conversas_chat',
        where:
            'loja_id = ? ${incluirArquivadas ? "" : "AND (arquivada IS NULL OR arquivada = 0)"}',
        whereArgs: [lojaId],
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

    final mapaNaoLidas = <String, int>{};
    try {
      final rowsNaoLidas = await db.rawQuery(
        'SELECT conversa_id, remetente_id FROM mensagens_chat WHERE lida = 0',
      );
      final idVisNorm = cpfNormUsuario;
      for (final nr in rowsNaoLidas) {
        final cid = nr['conversa_id'] as String? ?? '';
        final rem = nr['remetente_id'] as String? ?? '';
        final ehProprio = rem == (cpfUsuario ?? '') ||
            (idVisNorm.isNotEmpty &&
                ChatRepositorioSqlite.normalizarCpf(rem) == idVisNorm);
        if (!ehProprio && cid.isNotEmpty) {
          mapaNaoLidas[cid] = (mapaNaoLidas[cid] ?? 0) + 1;
        }
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
      final ehLoja = (r['eh_loja'] as int? ?? 0) == 1;
      final ehGrupo = (r['eh_grupo'] as int? ?? 0) == 1;
      final nGrupo = (r['nome_grupo'] as String? ?? '').trim();

      if (!ehGrupo &&
          ehLoja &&
          (convId.contains('loja_nous_coletiva') ||
              convId.contains('loja_nous') ||
              r['loja_id'] == idLojaColetivaNous ||
              r['loja_id'] == 'nous' ||
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
        var idNorm =
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
        if (lojaId != null && lojaId.isNotEmpty) {
          var idNorm = ChatRepositorioSqlite.normalizarCpf(
              r['identificador'] as String? ?? '');
          if (idNorm.length != 11) {
            idNorm = ChatRepositorioSqlite.extrairOutroCpf(convId, '');
          }
          final u = mapaContasPorCpf[idNorm];
          if (u != null) {
            if (tituloFinal.isEmpty ||
                tituloFinal == 'Conversa' ||
                tituloFinal == 'Nova Conversa' ||
                tituloFinal == 'Contato' ||
                tituloFinal == 'Contato Nous' ||
                tituloFinal == 'Cliente') {
              tituloFinal = u.nomeExibicao;
            }
            if (fotoFinal.isEmpty || !ImagemService.existe(fotoFinal)) {
              fotoFinal = u.fotoExibicao;
            }
            if (subtituloFinal.isEmpty ||
                subtituloFinal == 'Conversa' ||
                subtituloFinal == 'Contato Nous' ||
                subtituloFinal == 'Loja Nous') {
              subtituloFinal = u.usernameExibicao.isNotEmpty
                  ? u.usernameExibicao
                  : 'Cliente Nous';
            }
          }
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

      resultado.add(
        ConversaChat(
          id: convId,
          titulo: tituloFinal,
          subtitulo: subtituloFinal,
          foto: fotoFinal,
          identificador: r['identificador'] as String? ?? convId,
          ehLoja: ehLoja,
          ehGrupo: ehGrupo,
          nomeGrupo: nGrupo,
          tituloConversa: tituloConversaFinal,
          lojaId: r['loja_id'] as String?,
          participantesIds: ChatRepositorioSqlite.decodificarParticipantes(
            r['participantes_json'] as String?,
          ),
          ultimaMensagem: ultMsg,
          dataHoraUltimaMensagem: dataHoraUlt,
          naoLidasCount: naoLidas,
          mensagens: msgs,
          fixada: (r['fixada'] as int? ?? 0) == 1,
          arquivada: (r['arquivada'] as int? ?? 0) == 1,
          atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
        ),
      );
    }

    return resultado;
  }

  static Future<ConversaChat> obterOuCriarConversa({
    required String id,
    required String titulo,
    String subtitulo = '',
    String foto = '',
    required String identificador,
    bool ehLoja = false,
    bool ehGrupo = false,
    String? lojaId,
    String? cpfUsuario,
    List<String> participantesIds = const [],
    required VoidCallback aoNotificar,
  }) async {
    final listaParticipantes = Set<String>.from(participantesIds);
    if (cpfUsuario != null && cpfUsuario.isNotEmpty) {
      listaParticipantes.add(ChatRepositorioSqlite.normalizarCpf(cpfUsuario));
    }
    if (identificador.isNotEmpty) {
      final idNorm = ChatRepositorioSqlite.normalizarCpf(identificador);
      if (idNorm.length == 11) {
        listaParticipantes.add(idNorm);
      } else {
        listaParticipantes.add(identificador);
      }
    }
    final listaFinalParticipantes = listaParticipantes.toList();

    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(id);
    final rows = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final r = rows.first;

      String ultMsg = r['ultima_mensagem'] as String? ?? '';
      DateTime dataHoraUlt = DateTime.tryParse(
            r['data_hora_ultima_mensagem'] as String? ?? '',
          ) ??
          DateTime.now();

      final ultimasMsgs = await db.query(
        'mensagens_chat',
        columns: ['texto', 'tipo', 'nome_anexo', 'data_hora'],
        where: 'conversa_id = ?',
        whereArgs: [id],
        orderBy: 'data_hora DESC, id DESC',
        limit: 1,
      );

      if (ultimasMsgs.isNotEmpty) {
        final u = ultimasMsgs.first;
        final uTipo = u['tipo'] as String? ?? 'texto';
        final uTexto = u['texto'] as String? ?? '';
        final uAnexo = u['nome_anexo'] as String? ?? '';
        ultMsg = uTipo == 'imagem'
            ? (uTexto.isNotEmpty ? '📷 $uTexto' : '📷 Foto')
            : (uTipo == 'audio'
                ? '🎤 Mensagem de Voz'
                : (uTipo == 'arquivo'
                    ? '📎 ${uAnexo.isNotEmpty ? uAnexo : "Arquivo"}'
                    : (uTipo == 'comanda' ? '🧾 Comanda de Pedido' : uTexto)));
        dataHoraUlt =
            DateTime.tryParse(u['data_hora'] as String? ?? '') ?? dataHoraUlt;
      }

      var partsExistentes = ChatRepositorioSqlite.decodificarParticipantes(
        r['participantes_json'] as String?,
      );
      if (partsExistentes.isEmpty && listaFinalParticipantes.isNotEmpty) {
        partsExistentes = listaFinalParticipantes;
        await db.update(
          'conversas_chat',
          {'participantes_json': jsonEncode(partsExistentes)},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      final titDb = (r['titulo'] as String? ?? '').trim();
      final subDb = (r['subtitulo'] as String? ?? '').trim();
      final fotoDb = (r['foto'] as String? ?? '').trim();

      final titValido =
          titDb.isNotEmpty &&
          titDb != 'Conversa' &&
          titDb != 'Nova Conversa' &&
          titDb != 'Contato' &&
          titDb != 'Contato Nous';
      var titFinal = (titulo.isNotEmpty &&
              titulo != 'Conversa' &&
              titulo != 'Nova Conversa' &&
              titulo != 'Contato' &&
              titulo != 'Contato Nous')
          ? titulo
          : (titValido ? titDb : '');
      var fotoFinal = foto.isNotEmpty ? foto : fotoDb;
      var subFinal = (subtitulo.isNotEmpty &&
              subtitulo != 'Conversa' &&
              subtitulo != 'Contato Nous')
          ? subtitulo
          : ((subDb.isNotEmpty && subDb != 'Conversa')
              ? subDb
              : '');

      if (!ehLoja &&
          !ehGrupo &&
          (titFinal.isEmpty || subFinal.isEmpty || fotoFinal.isEmpty)) {
        final cpfNormUsuario =
            cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
        var outroCpf = ChatRepositorioSqlite.normalizarCpf(
          r['identificador'] as String? ?? identificador,
        );
        if (outroCpf.length != 11 ||
            (cpfNormUsuario.isNotEmpty && outroCpf == cpfNormUsuario)) {
          outroCpf = ChatRepositorioSqlite.extrairOutroCpf(id, cpfNormUsuario);
        }
        if (outroCpf.length == 11) {
          final u = await ContasNousService.buscarPorCpf(outroCpf);
          if (u != null) {
            if (titFinal.isEmpty) titFinal = u.nomeExibicao;
            if (fotoFinal.isEmpty) fotoFinal = u.fotoExibicao;
            if (subFinal.isEmpty) {
              subFinal = u.usernameExibicao.isNotEmpty
                  ? u.usernameExibicao
                  : 'Usuário Nous';
            }
          }
        }
      }

      return ConversaChat(
        id: id,
        titulo: titFinal.isNotEmpty ? titFinal : 'Contato Nous',
        subtitulo: subFinal.isNotEmpty ? subFinal : 'Contato Nous',
        foto: fotoFinal,
        identificador: r['identificador'] as String? ?? identificador,
        ehLoja: (r['eh_loja'] as int? ?? 0) == 1,
        ehGrupo: (r['eh_grupo'] as int? ?? 0) == 1,
        nomeGrupo: (r['nome_grupo'] as String? ?? '').trim(),
        tituloConversa: (r['titulo_conversa'] as String? ?? '').trim(),
        lojaId: r['loja_id'] as String? ?? lojaId,
        participantesIds: partsExistentes,
        ultimaMensagem: ultMsg,
        dataHoraUltimaMensagem: dataHoraUlt,
        mensagens: const [],
        fixada: (r['fixada'] as int? ?? 0) == 1,
        arquivada: (r['arquivada'] as int? ?? 0) == 1,
        atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
      );
    }

    var tituloInserir = titulo;
    var subtituloInserir = subtitulo;
    var fotoInserir = foto;

    if (!ehLoja &&
        !ehGrupo &&
        (tituloInserir.isEmpty ||
            tituloInserir == 'Conversa' ||
            tituloInserir == 'Nova Conversa' ||
            tituloInserir == 'Contato' ||
            tituloInserir == 'Contato Nous')) {
      final cpfNormUsuario =
          cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
      var outroCpf = ChatRepositorioSqlite.normalizarCpf(identificador);
      if (outroCpf.length != 11 ||
          (cpfNormUsuario.isNotEmpty && outroCpf == cpfNormUsuario)) {
        outroCpf = ChatRepositorioSqlite.extrairOutroCpf(id, cpfNormUsuario);
      }
      if (outroCpf.length == 11) {
        final u = await ContasNousService.buscarPorCpf(outroCpf);
        if (u != null) {
          tituloInserir = u.nomeExibicao;
          if (fotoInserir.isEmpty) fotoInserir = u.fotoExibicao;
          if (subtituloInserir.isEmpty ||
              subtituloInserir == 'Conversa' ||
              subtituloInserir == 'Contato Nous') {
            subtituloInserir = u.usernameExibicao.isNotEmpty
                ? u.usernameExibicao
                : 'Usuário Nous';
          }
        }
      }
    }
    if (tituloInserir.isEmpty || tituloInserir == 'Conversa') {
      tituloInserir = 'Contato Nous';
    }
    if (subtituloInserir.isEmpty || subtituloInserir == 'Conversa') {
      subtituloInserir =
          ehLoja ? 'Loja Nous' : (ehGrupo ? 'Grupo Nous' : 'Usuário Nous');
    }

    final agora = DateTime.now();
    await db.insert('conversas_chat', {
      'id': id,
      'titulo': tituloInserir,
      'subtitulo': subtituloInserir,
      'foto': fotoInserir,
      'identificador': identificador,
      'eh_loja': ehLoja ? 1 : 0,
      'eh_grupo': ehGrupo ? 1 : 0,
      'loja_id': lojaId ?? '',
      'participantes_json': jsonEncode(listaFinalParticipantes),
      'criado_em': agora.toIso8601String(),
      'atualizado_em': agora.toIso8601String(),
      'ultima_mensagem': '',
      'data_hora_ultima_mensagem': agora.toIso8601String(),
      'arquivada': 0,
      'fixada': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    aoNotificar();

    final novaConversa = ConversaChat(
      id: id,
      titulo: tituloInserir,
      subtitulo: subtituloInserir,
      foto: fotoInserir,
      identificador: identificador,
      ehLoja: ehLoja,
      ehGrupo: ehGrupo,
      lojaId: lojaId,
      participantesIds: listaFinalParticipantes,
      ultimaMensagem: '',
      dataHoraUltimaMensagem: agora,
      atualizadaEm: agora,
      mensagens: const [],
    );

    ChatSincronizacaoService.despacharConversaAtualizada(novaConversa);
    return novaConversa;
  }

  static Future<void> salvarConversa(
    ConversaChat conversa, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final agora = DateTime.now();
    await db.insert('conversas_chat', {
      'id': conversa.id,
      'titulo': conversa.titulo,
      'subtitulo': conversa.subtitulo,
      'foto': conversa.foto,
      'identificador': conversa.identificador,
      'eh_loja': conversa.ehLoja ? 1 : 0,
      'eh_grupo': conversa.ehGrupo ? 1 : 0,
      'nome_grupo': conversa.nomeGrupo,
      'titulo_conversa': conversa.tituloConversa,
      'loja_id': conversa.lojaId ?? '',
      'participantes_json': jsonEncode(conversa.participantesIds),
      'criado_em': agora.toIso8601String(),
      'atualizado_em': agora.toIso8601String(),
      'ultima_mensagem': conversa.ultimaMensagem,
      'data_hora_ultima_mensagem': conversa.dataHoraUltimaMensagem
          .toIso8601String(),
      'arquivada': conversa.arquivada ? 1 : 0,
      'fixada': conversa.fixada ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    aoNotificar();
    ChatSincronizacaoService.despacharConversaAtualizada(conversa);
  }

  static Future<void> alternarFixarConversa(
    String conversaId, [
    bool? fixar,
    VoidCallback? aoNotificar,
  ]) async {
    final db = await ChatRepositorioSqlite.obterDb();
    bool novoValor = fixar ?? false;
    if (fixar == null) {
      final rows = await db.query(
        'conversas_chat',
        columns: ['fixada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        novoValor = (rows.first['fixada'] as int? ?? 0) == 0;
      } else {
        novoValor = true;
      }
    }
    await db.update(
      'conversas_chat',
      {'fixada': novoValor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversaId],
    );
    aoNotificar?.call();
  }

  static Future<void> alternarArquivarConversa(
    String conversaId, [
    bool? arquivar,
    VoidCallback? aoNotificar,
  ]) async {
    final db = await ChatRepositorioSqlite.obterDb();
    bool novoValor = arquivar ?? false;
    if (arquivar == null) {
      final rows = await db.query(
        'conversas_chat',
        columns: ['arquivada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        novoValor = (rows.first['arquivada'] as int? ?? 0) == 0;
      } else {
        novoValor = true;
      }
    }
    await db.update(
      'conversas_chat',
      {'arquivada': novoValor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversaId],
    );
    aoNotificar?.call();
  }

  static Future<void> renomearConversa(
    String conversaId,
    String novoTitulo, {
    bool originadoDaRede = false,
    VoidCallback? aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final tLimpo = novoTitulo.trim();
    final ehGrupo = conversaId.startsWith('grupo_');

    if (ehGrupo) {
      await db.update(
        'conversas_chat',
        {
          'titulo': tLimpo,
          'nome_grupo': tLimpo,
          'titulo_conversa': tLimpo,
        },
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    } else {
      await db.update(
        'conversas_chat',
        {'titulo_conversa': tLimpo},
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    }

    aoNotificar?.call();

    if (!originadoDaRede) {
      ChatSincronizacaoService.despacharConversaRenomeada(conversaId, tLimpo);
    }
  }

  static Future<void> atualizarMetadadosContatoConversa({
    required String conversaId,
    required String titulo,
    required String subtitulo,
    required String foto,
  }) async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      await db.update(
        'conversas_chat',
        {
          'titulo': titulo,
          'subtitulo': subtitulo,
          'foto': foto,
        },
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    } catch (_) {}
  }

  static Future<Map<String, String>> obterTitulosCustomizados([
    String? cpfLogado,
  ]) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'conversas_chat',
      columns: ['id', 'titulo', 'titulo_conversa'],
    );
    final mapa = <String, String>{};
    for (final r in rows) {
      final id = r['id'] as String? ?? '';
      final titConv = (r['titulo_conversa'] as String? ?? '').trim();
      if (id.isEmpty) continue;
      if (titConv.isNotEmpty) {
        mapa[id] = titConv;
      }
    }
    return mapa;
  }
}
