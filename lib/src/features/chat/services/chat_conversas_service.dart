import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_conversas_hidratador_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';

class ChatConversasService {
  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  static Future<List<ConversaChat>> obterTodasConversas({
    String? cpfUsuario,
    String? lojaId,
    bool incluirArquivadas = false,
    required VoidCallback aoNotificar,
  }) async {
    return ChatConversasHidratadorService.obterTodasConversas(
      cpfUsuario: cpfUsuario,
      lojaId: lojaId,
      incluirArquivadas: incluirArquivadas,
      obterTitulosCustomizados: obterTitulosCustomizados,
    );
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

      final cpfNormUsuario =
          cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
      var outroCpf = ChatRepositorioSqlite.normalizarCpf(
        r['identificador'] as String? ?? identificador,
      );
      if (outroCpf.length != 11 ||
          (cpfNormUsuario.isNotEmpty && outroCpf == cpfNormUsuario)) {
        outroCpf = ChatRepositorioSqlite.extrairOutroCpf(id, cpfNormUsuario);
      }

      String idFinalConversa = r['identificador'] as String? ?? identificador;
      if (!ehLoja && !ehGrupo && outroCpf.length == 11) {
        idFinalConversa = outroCpf;
        if (r['identificador'] != outroCpf) {
          unawaited(db.update(
            'conversas_chat',
            {'identificador': outroCpf},
            where: 'id = ?',
            whereArgs: [id],
          ));
        }
      }

      if (!ehLoja &&
          !ehGrupo &&
          (titFinal.isEmpty || subFinal.isEmpty || fotoFinal.isEmpty)) {
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

      final ehConvLojaUsuario =
          id.startsWith('loja_') && id.contains('_usuario_');
      final ehLojaFinal =
          ehConvLojaUsuario || ehLoja || (r['eh_loja'] as int? ?? 0) == 1;
      var lojaIdFinal = (r['loja_id'] as String? ?? lojaId ?? '').trim();
      if (ehConvLojaUsuario && lojaIdFinal.isEmpty) {
        lojaIdFinal = id.substring(5, id.indexOf('_usuario_'));
      }

      return ConversaChat(
        id: id,
        titulo: titFinal.isNotEmpty ? titFinal : 'Contato Nous',
        subtitulo: subFinal.isNotEmpty ? subFinal : 'Contato Nous',
        foto: fotoFinal,
        identificador: idFinalConversa,
        ehLoja: ehLojaFinal,
        ehGrupo: (r['eh_grupo'] as int? ?? 0) == 1,
        nomeGrupo: (r['nome_grupo'] as String? ?? '').trim(),
        tituloConversa: (r['titulo_conversa'] as String? ?? '').trim(),
        lojaId: lojaIdFinal.isNotEmpty ? lojaIdFinal : lojaId,
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

    final ehConvLojaUsuario =
        id.startsWith('loja_') && id.contains('_usuario_');
    final ehLojaEfetivo = ehConvLojaUsuario || ehLoja;
    var lojaIdEfetivo = (lojaId ?? '').trim();
    if (ehConvLojaUsuario && lojaIdEfetivo.isEmpty) {
      lojaIdEfetivo = id.substring(5, id.indexOf('_usuario_'));
    }

    final cpfNormUsuario =
        cpfUsuario != null ? ChatRepositorioSqlite.normalizarCpf(cpfUsuario) : '';
    var outroCpf = ChatRepositorioSqlite.normalizarCpf(identificador);
    if (outroCpf.length != 11 ||
        (cpfNormUsuario.isNotEmpty && outroCpf == cpfNormUsuario)) {
      outroCpf = ChatRepositorioSqlite.extrairOutroCpf(id, cpfNormUsuario);
    }
    var idParaSalvar = identificador;
    if (!ehLojaEfetivo && !ehGrupo && outroCpf.length == 11) {
      idParaSalvar = outroCpf;
    }

    if (!ehLojaEfetivo &&
        !ehGrupo &&
        (tituloInserir.isEmpty ||
            tituloInserir == 'Conversa' ||
            tituloInserir == 'Nova Conversa' ||
            tituloInserir == 'Contato' ||
            tituloInserir == 'Contato Nous')) {
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
          ehLojaEfetivo ? 'Loja Nous' : (ehGrupo ? 'Grupo Nous' : 'Usuário Nous');
    }

    final agora = DateTime.now();
    await db.insert('conversas_chat', {
      'id': id,
      'titulo': tituloInserir,
      'subtitulo': subtituloInserir,
      'foto': fotoInserir,
      'identificador': idParaSalvar,
      'eh_loja': ehLojaEfetivo ? 1 : 0,
      'eh_grupo': ehGrupo ? 1 : 0,
      'loja_id': lojaIdEfetivo,
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
      ehLoja: ehLojaEfetivo,
      ehGrupo: ehGrupo,
      lojaId: lojaIdEfetivo.isNotEmpty ? lojaIdEfetivo : lojaId,
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
    final ehConvLojaUsuario =
        conversa.id.startsWith('loja_') && conversa.id.contains('_usuario_');
    final ehLojaEfetivo = ehConvLojaUsuario || conversa.ehLoja;
    var lojaIdEfetivo = (conversa.lojaId ?? '').trim();
    if (ehConvLojaUsuario && lojaIdEfetivo.isEmpty) {
      lojaIdEfetivo =
          conversa.id.substring(5, conversa.id.indexOf('_usuario_'));
    }
    await db.insert('conversas_chat', {
      'id': conversa.id,
      'titulo': conversa.titulo,
      'subtitulo': conversa.subtitulo,
      'foto': conversa.foto,
      'identificador': conversa.identificador,
      'eh_loja': ehLojaEfetivo ? 1 : 0,
      'eh_grupo': conversa.ehGrupo ? 1 : 0,
      'nome_grupo': conversa.nomeGrupo,
      'titulo_conversa': conversa.tituloConversa,
      'loja_id': lojaIdEfetivo,
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
