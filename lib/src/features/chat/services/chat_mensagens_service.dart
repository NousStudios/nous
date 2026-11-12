import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_processador_rede_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_conversa_info_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class ChatMensagensService {
  static Future<void> consolidarConversasDuplicadas() async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query('conversas_chat');
      final Map<String, List<Map<String, dynamic>>> porInterlocutor = {};

      for (final r in rows) {
        final id = r['id'] as String;
        final ehGrupo = (r['eh_grupo'] as int? ?? 0) == 1;
        final ehLoja = (r['eh_loja'] as int? ?? 0) == 1;
        if (ehGrupo ||
            ehLoja ||
            id.startsWith('grupo_') ||
            id.startsWith('loja_')) {
          continue;
        }

        final match = RegExp(r'^user_(\d{11})_user_(\d{11})$').firstMatch(id);
        if (match != null) {
          final c1 = match.group(1)!;
          final c2 = match.group(2)!;
          final min = c1.compareTo(c2) <= 0 ? c1 : c2;
          final max = c1.compareTo(c2) <= 0 ? c2 : c1;
          final chaveCanonica = 'user_${min}_user_$max';
          porInterlocutor.putIfAbsent(chaveCanonica, () => []).add(r);
        }
      }

      for (final entry in porInterlocutor.entries) {
        final chaveCanonica = entry.key;
        final lista = entry.value;
        if (lista.length <= 1 && lista.first['id'] == chaveCanonica) continue;

        // O ID principal sempre deve ser o canônico user_{min}_user_{max}
        final principalId = chaveCanonica;
        final existePrincipal = lista.any((item) => item['id'] == principalId);

        if (!existePrincipal) {
          final primeiro = lista.first;
          final idAntigo = primeiro['id'] as String;
          await db.update(
            'conversas_chat',
            {'id': principalId},
            where: 'id = ?',
            whereArgs: [idAntigo],
          );
          await db.update(
            'mensagens_chat',
            {'conversa_id': principalId},
            where: 'conversa_id = ?',
            whereArgs: [idAntigo],
          );
        }

        for (final item in lista) {
          final dupId = item['id'] as String;
          if (dupId == principalId) continue;

          await db.update(
            'mensagens_chat',
            {'conversa_id': principalId},
            where: 'conversa_id = ?',
            whereArgs: [dupId],
          );

          await db.delete(
            'conversas_chat',
            where: 'id = ?',
            whereArgs: [dupId],
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatMensagensService] Erro ao consolidar conversas duplicadas: $e');
    }
  }

  static Future<MensagemChat> enviarMensagemInstantanea(
    MensagemChat mensagem, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);

    DateTime dataHoraAjustada = mensagem.dataHora;
    final ultimas = await db.query(
      'mensagens_chat',
      columns: ['data_hora'],
      where: 'conversa_id = ? AND id != ?',
      whereArgs: [mensagem.conversaId, mensagem.id],
      orderBy: 'data_hora DESC, id DESC',
      limit: 1,
    );
    if (ultimas.isNotEmpty) {
      final ultimaStr = ultimas.first['data_hora'] as String?;
      if (ultimaStr != null && ultimaStr.isNotEmpty) {
        final ultimaData = DateTime.tryParse(ultimaStr);
        if (ultimaData != null && !dataHoraAjustada.isAfter(ultimaData)) {
          dataHoraAjustada = ultimaData.add(const Duration(milliseconds: 10));
        }
      }
    }
    if (dataHoraAjustada != mensagem.dataHora) {
      mensagem = mensagem.copyWith(dataHora: dataHoraAjustada);
    }

    MensagemChat mensagemPersistida =
        await ChatE2eeService.cifrarMensagemSeAplicavel(mensagem);

    if (mensagemPersistida.assinatura.isEmpty) {
      final cpfLimpo =
          ChatRepositorioSqlite.normalizarCpf(mensagemPersistida.remetenteId);
      if (cpfLimpo.length == 11) {
        final payloadParaAssinar =
            '${mensagemPersistida.id}:${mensagemPersistida.conversaId}:${mensagemPersistida.remetenteId}:${mensagemPersistida.texto}:${mensagemPersistida.dataHora.toIso8601String()}';
        try {
          final sig = await CriptografiaService.assinarDados(
            cpf: cpfLimpo,
            mensagem: payloadParaAssinar,
          );
          if (sig != null && sig.isNotEmpty) {
            mensagemPersistida = mensagemPersistida.copyWith(assinatura: sig);
          }
        } catch (_) {}
      }
    }

    final resumo = ChatMediaService.gerarResumoMensagem(mensagemPersistida);

    await db.insert('mensagens_chat', {
      'id': mensagemPersistida.id,
      'conversa_id': mensagemPersistida.conversaId,
      'remetente_id': mensagemPersistida.remetenteId,
      'remetente_nome': mensagemPersistida.remetenteNome,
      'remetente_foto': mensagemPersistida.remetenteFoto,
      'destinatario_id': mensagemPersistida.destinatarioId,
      'texto': mensagemPersistida.texto,
      'data_hora': mensagemPersistida.dataHora.toIso8601String(),
      'nome_atendente': mensagemPersistida.nomeAtendente,
      'cpf_atendente': mensagemPersistida.cpfAtendente,
      'lida': 0,
      'tipo': mensagemPersistida.tipo,
      'caminho_anexo': mensagemPersistida.caminhoAnexo,
      'nome_anexo': mensagemPersistida.nomeAnexo,
      'tamanho_anexo': mensagemPersistida.tamanhoAnexo,
      'pedido_id': mensagemPersistida.pedidoId,
      'dados_pedido_json': mensagemPersistida.dadosPedidoJson,
      'editada': 0,
      'historico_edicoes': jsonEncode(mensagemPersistida.historicoEdicoes),
      'status_envio': 'enviada',
      'entregue': mensagemPersistida.entregue ? 1 : 0,
      'favorita': mensagemPersistida.favorita ? 1 : 0,
      'fixada': mensagemPersistida.fixada ? 1 : 0,
      'reacoes_json': jsonEncode(mensagemPersistida.reacoes),
      'assinatura': mensagemPersistida.assinatura,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final ehConvLojaUsuario = mensagem.conversaId.startsWith('loja_') &&
        mensagem.conversaId.contains('_usuario_');
    final lojaIdConv = ehConvLojaUsuario
        ? mensagem.conversaId.substring(
            5,
            mensagem.conversaId.indexOf('_usuario_'),
          )
        : '';

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
        if (ehConvLojaUsuario) 'eh_loja': 1,
        if (ehConvLojaUsuario && lojaIdConv.isNotEmpty) 'loja_id': lojaIdConv,
      },
      where: 'id = ?',
      whereArgs: [mensagem.conversaId],
    );

    if (count == 0) {
      final cpfLogado = ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
      final info = await ResolvedorConversaInfoService.resolverMetadadosParaMensagem(
        mensagem,
        cpfLogado: cpfLogado,
      );

      await db.insert('conversas_chat', {
        'id': mensagem.conversaId,
        'titulo': info.titulo,
        'subtitulo': info.subtitulo,
        'foto': info.foto,
        'identificador': info.identificador,
        'eh_loja': (ehConvLojaUsuario || info.ehLoja) ? 1 : 0,
        'eh_grupo': info.ehGrupo ? 1 : 0,
        'loja_id': (info.lojaId?.isNotEmpty == true) ? info.lojaId! : lojaIdConv,
        'participantes_json': jsonEncode([
          mensagem.remetenteId,
          mensagem.destinatarioId,
        ]),
        'criado_em': mensagem.dataHora.toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'arquivada': 0,
        'fixada': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    aoNotificar();

    unawaited(() async {
      try {
        final servidor = ServidorRedeLocal();
        final cliente = ClienteRedeLocal();
        if (!servidor.ativo && !cliente.conectado && cliente.ipServidor == null) {
          final ultimo = await GerenciadorDispositivoLocal.obterUltimoBalcao();
          if (ultimo.ip != null && ultimo.ip!.isNotEmpty) {
            cliente.configurarServidorManual(
              ultimo.ip!,
              ultimo.porta ?? ServidorRedeLocal.portaPadraoHttp,
            );
          }
        }
        if (servidor.ativo || cliente.conectado || cliente.ipServidor != null) {
          final enviado =
              await ChatSincronizacaoService.despacharMensagemParaRede(mensagemPersistida);
          if (enviado) {
            await db.update(
              'mensagens_chat',
              {'status_envio': 'enviada'},
              where: 'id = ?',
              whereArgs: [mensagem.id],
            );
            aoNotificar();
          }
        }
      } catch (e) {
        debugPrint('[ChatMensagensService] Despacho em background mantido na fila: $e');
      }
    }());

    return mensagem.copyWith(statusEnvio: 'enviada');
  }

  static Future<bool> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
    required Future<String> Function() obterCpfLogadoLocal,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);
    final meuCpf = await obterCpfLogadoLocal();

    // Validação de autenticidade criptográfica (Ed25519)
    if (originadaDaRede && mensagem.assinatura.isNotEmpty) {
      final cpfRemNorm =
          ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
      if (cpfRemNorm.length == 11) {
        final contaRem = await ContasNousService.buscarPorCpf(cpfRemNorm);
        if (contaRem != null && contaRem.chavePublica.isNotEmpty) {
          final payload =
              '${mensagem.id}:${mensagem.conversaId}:${mensagem.remetenteId}:${mensagem.texto}:${mensagem.dataHora.toIso8601String()}';
          final valida = await CriptografiaService.verificarAssinatura(
            mensagem: payload,
            assinaturaHex: mensagem.assinatura,
            chavePublicaHex: contaRem.chavePublica,
          );
          if (!valida) {
            debugPrint(
              '[ChatMensagensService] AVISO AUDITORIA: Assinatura digital não verificada para mensagem ${mensagem.id}',
            );
          }
        }
      }
    }

    // Validação de permissão soberana de mensagens diretas (Ponto 4)
    if (originadaDaRede &&
        !mensagem.conversaId.startsWith('grupo_') &&
        !mensagem.conversaId.startsWith('loja_') &&
        !mensagem.conversaId.startsWith('topico_')) {
      final cpfDestNorm =
          ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);
      if (cpfDestNorm.length == 11 && cpfDestNorm == meuCpf) {
        final contaDest = await ContasNousService.buscarPorCpf(cpfDestNorm);
        if (contaDest != null &&
            contaDest.quemPodeEnviarMensagens == 'apenas_seguidos') {
          final cpfRemNorm =
              ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
          if (!contaDest.estaSeguindo(cpfRemNorm)) {
            debugPrint(
              '[ChatMensagensService] Bloqueada: $cpfRemNorm não é seguido por $cpfDestNorm',
            );
            return false;
          }
        }
      }
    }

    // Deduplicação sem ruído: se a mensagem já existe no banco com exatamente os mesmos campos, ignora
    final existentes = await db.query(
      'mensagens_chat',
      columns: [
        'id',
        'conversa_id',
        'status_envio',
        'texto',
        'lida',
        'entregue',
        'editada',
        'caminho_anexo',
        'dados_pedido_json',
        'fixada',
        'reacoes_json',
      ],
      where: 'id = ?',
      whereArgs: [mensagem.id],
      limit: 1,
    );
    if (existentes.isNotEmpty) {
      final ex = existentes.first;
      final convEx = ex['conversa_id'] as String? ?? '';
      final stEx = ex['status_envio'] as String? ?? '';
      final txtEx = ex['texto'] as String? ?? '';
      final lidaEx = (ex['lida'] as int? ?? 0) == 1;
      final entEx = (ex['entregue'] as int? ?? 0) == 1;
      final editEx = (ex['editada'] as int? ?? 0) == 1;
      final anexoEx = ex['caminho_anexo'] as String? ?? '';
      final dadosPedEx = ex['dados_pedido_json'] as String? ?? '';
      final fixadaEx = (ex['fixada'] as int? ?? 0) == 1;
      final reacoesEx = ex['reacoes_json'] as String? ?? '{}';
      if (convEx == mensagem.conversaId &&
          stEx == mensagem.statusEnvio &&
          txtEx == mensagem.texto &&
          lidaEx == mensagem.lida &&
          entEx == mensagem.entregue &&
          editEx == mensagem.editada &&
          anexoEx == mensagem.caminhoAnexo &&
          dadosPedEx == mensagem.dadosPedidoJson &&
          fixadaEx == mensagem.fixada &&
          reacoesEx == jsonEncode(mensagem.reacoes)) {
        return false;
      }
    }

    DateTime dataHoraAjustada = mensagem.dataHora.toLocal();
    final agoraRede = RelogioRedeService.agora().toLocal();

    // Se o remetente estiver com relógio adiantado no futuro além de 5 segundos, calibra para o tempo de rede
    if (originadaDaRede && dataHoraAjustada.difference(agoraRede).inSeconds > 5) {
      dataHoraAjustada = agoraRede;
    }

    final ultimas = await db.query(
      'mensagens_chat',
      columns: ['data_hora'],
      where: 'conversa_id = ? AND id != ?',
      whereArgs: [mensagem.conversaId, mensagem.id],
      orderBy: 'data_hora DESC, id DESC',
      limit: 1,
    );
    if (ultimas.isNotEmpty) {
      final ultimaStr = ultimas.first['data_hora'] as String?;
      if (ultimaStr != null && ultimaStr.isNotEmpty) {
        final ultimaData = DateTime.tryParse(ultimaStr)?.toLocal();
        if (ultimaData != null && !dataHoraAjustada.isAfter(ultimaData)) {
          // Se ultimaData no banco estiver no futuro além de 30 segundos de agoraRede,
          // trata como anomalia de timezone legado e não propaga o erro
          if (ultimaData.difference(agoraRede).inSeconds > 30) {
            dataHoraAjustada = agoraRede;
          } else {
            dataHoraAjustada = ultimaData.add(const Duration(milliseconds: 5));
          }
        }
      }
    }
    if (dataHoraAjustada != mensagem.dataHora) {
      mensagem = mensagem.copyWith(dataHora: dataHoraAjustada);
    }

    final resumo = ChatMediaService.gerarResumoMensagem(mensagem);

    await db.insert('mensagens_chat', {
      'id': mensagem.id,
      'conversa_id': mensagem.conversaId,
      'remetente_id': mensagem.remetenteId,
      'remetente_nome': mensagem.remetenteNome,
      'remetente_foto': mensagem.remetenteFoto,
      'destinatario_id': mensagem.destinatarioId,
      'texto': mensagem.texto,
      'data_hora': mensagem.dataHora.toIso8601String(),
      'nome_atendente': mensagem.nomeAtendente,
      'cpf_atendente': mensagem.cpfAtendente,
      'lida': mensagem.lida ? 1 : 0,
      'tipo': mensagem.tipo,
      'caminho_anexo': mensagem.caminhoAnexo,
      'nome_anexo': mensagem.nomeAnexo,
      'tamanho_anexo': mensagem.tamanhoAnexo,
      'pedido_id': mensagem.pedidoId,
      'dados_pedido_json': mensagem.dadosPedidoJson,
      'editada': mensagem.editada ? 1 : 0,
      'historico_edicoes': jsonEncode(mensagem.historicoEdicoes),
      'status_envio': mensagem.statusEnvio,
      'entregue': mensagem.entregue ? 1 : 0,
      'favorita': mensagem.favorita ? 1 : 0,
      'fixada': mensagem.fixada ? 1 : 0,
      'reacoes_json': jsonEncode(mensagem.reacoes),
      'assinatura': mensagem.assinatura,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final ehConvLojaUsuario = mensagem.conversaId.startsWith('loja_') &&
        mensagem.conversaId.contains('_usuario_');
    final lojaIdConv = ehConvLojaUsuario
        ? mensagem.conversaId.substring(
            5,
            mensagem.conversaId.indexOf('_usuario_'),
          )
        : '';

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
        if (ehConvLojaUsuario) 'eh_loja': 1,
        if (ehConvLojaUsuario && lojaIdConv.isNotEmpty) 'loja_id': lojaIdConv,
      },
      where: 'id = ?',
      whereArgs: [mensagem.conversaId],
    );

    if (count == 0) {
      final info = await ResolvedorConversaInfoService.resolverMetadadosParaMensagem(
        mensagem,
        cpfLogado: meuCpf,
      );

      await db.insert('conversas_chat', {
        'id': mensagem.conversaId,
        'titulo': info.titulo,
        'subtitulo': info.subtitulo,
        'foto': info.foto,
        'identificador': info.identificador,
        'eh_loja': (ehConvLojaUsuario || info.ehLoja) ? 1 : 0,
        'eh_grupo': info.ehGrupo ? 1 : 0,
        'loja_id': (info.lojaId?.isNotEmpty == true) ? info.lojaId! : lojaIdConv,
        'participantes_json': jsonEncode([
          mensagem.remetenteId,
          mensagem.destinatarioId,
        ]),
        'criado_em': mensagem.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'arquivada': 0,
        'fixada': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    aoNotificar();
    return true;
  }

  static Future<void> processarMensagemRecebidaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
    required String? idConversaAtiva,
    required Future<String> Function() obterCpfLogadoLocal,
    required Future<bool> Function(String conversaId) deveNotificarConversa,
    required VoidCallback aoNotificar,
  }) async {
    await ChatProcessadorRedeService.processarMensagemRecebidaRede(
      payloadMensagem,
      emitirAlertaSonoro: emitirAlertaSonoro,
      idConversaAtiva: idConversaAtiva,
      obterCpfLogadoLocal: obterCpfLogadoLocal,
      deveNotificarConversa: deveNotificarConversa,
      aoNotificar: aoNotificar,
      salvarMensagemCallback: salvarMensagem,
    );
  }

  static Future<void> editarMensagem(
    String id,
    String novoTexto, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final r = rows.first;
    final textoAntigo = r['texto'] as String? ?? '';
    final historicoRaw = r['historico_edicoes'] as String? ?? '[]';
    List<Map<String, dynamic>> historico = [];
    try {
      historico = (jsonDecode(historicoRaw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {}

    historico.add({
      'texto': textoAntigo,
      'dataHora': DateTime.now().toIso8601String(),
    });

    await db.update(
      'mensagens_chat',
      {
        'texto': novoTexto.trim(),
        'editada': 1,
        'historico_edicoes': jsonEncode(historico),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    aoNotificar();

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_editada',
      'id': id,
      'conversaId': r['conversa_id'],
      'novoTexto': novoTexto.trim(),
      'historicoEdicoes': historico,
    });
  }

  static Future<bool> excluirMensagem(
    String id, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final dataHoraStr = rows.first['data_hora'] as String? ?? '';
    final dataHora = DateTime.tryParse(dataHoraStr) ?? DateTime.now();
    final diferencaSegundos = DateTime.now().difference(dataHora).inSeconds;

    if (diferencaSegundos > 60) {
      return false;
    }

    final conversaId = rows.first['conversa_id'] as String? ?? '';
    await db.delete('mensagens_chat', where: 'id = ?', whereArgs: [id]);

    aoNotificar();

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_excluida',
      'id': id,
      'conversaId': conversaId,
    });
    return true;
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDaLoja(
    String lojaId, {
    String? idConversaAtiva,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final idLimpo = lojaId.startsWith('loja_') ? lojaId.substring(5) : lojaId;
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR destinatario_id = ? OR conversa_id LIKE ?) '
          'AND remetente_id NOT IN (?, ?) '
          'AND remetente_id NOT LIKE \'loja_%\' '
          'AND remetente_id != \'\' '
          'AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') '
          'AND conversa_id NOT IN (SELECT conversa_id FROM conversas_excluidas) '
          'AND lida = 0$condicaoAtiva',
      whereArgs: [
        idLimpo,
        'loja_$idLimpo',
        'loja_${idLimpo}_%',
        idLimpo,
        'loja_$idLimpo',
        if (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
          idConversaAtiva,
      ],
      orderBy: 'data_hora DESC',
    );
    return rows
        .map(
          (r) => MensagemChat(
            id: r['id'] as String? ?? '',
            conversaId: r['conversa_id'] as String? ?? '',
            remetenteId: r['remetente_id'] as String? ?? '',
            remetenteNome: r['remetente_nome'] as String? ?? '',
            remetenteFoto: r['remetente_foto'] as String? ?? '',
            destinatarioId: r['destinatario_id'] as String? ?? '',
            texto: r['texto'] as String? ?? '',
            dataHora:
                DateTime.tryParse(r['data_hora'] as String? ?? '') ??
                DateTime.now(),
            enviadaPorMim: false,
            nomeAtendente: r['nome_atendente'] as String? ?? '',
            cpfAtendente: r['cpf_atendente'] as String? ?? '',
            lida: false,
          ),
        )
        .toList();
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDoUsuario(
    String cpf, {
    String? idConversaAtiva,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return [];
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR conversa_id LIKE ? OR '
          'conversa_id IN (SELECT id FROM conversas_chat WHERE id LIKE \'grupo_%\' AND participantes_json LIKE ?)) '
          'AND (conversa_id NOT LIKE \'loja_%\' OR remetente_id LIKE \'loja_%\') '
          'AND remetente_id NOT IN (?, ?, ?) '
          'AND remetente_id != \'\' '
          'AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') '
          'AND conversa_id NOT IN (SELECT conversa_id FROM conversas_excluidas) '
          'AND lida = 0$condicaoAtiva',
      whereArgs: [
        cpfNorm,
        '%$cpfNorm%',
        '%$cpfNorm%',
        cpf,
        cpfNorm,
        'user_$cpfNorm',
        if (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
          idConversaAtiva,
      ],
      orderBy: 'data_hora DESC',
    );
    return rows
        .map(
          (r) => MensagemChat(
            id: r['id'] as String? ?? '',
            conversaId: r['conversa_id'] as String? ?? '',
            remetenteId: r['remetente_id'] as String? ?? '',
            remetenteNome: r['remetente_nome'] as String? ?? '',
            remetenteFoto: r['remetente_foto'] as String? ?? '',
            destinatarioId: r['destinatario_id'] as String? ?? '',
            texto: r['texto'] as String? ?? '',
            dataHora:
                DateTime.tryParse(r['data_hora'] as String? ?? '') ??
                DateTime.now(),
            enviadaPorMim: false,
            nomeAtendente: r['nome_atendente'] as String? ?? '',
            cpfAtendente: r['cpf_atendente'] as String? ?? '',
            lida: false,
          ),
        )
        .toList();
  }

  static Future<Map<String, ({String nome, String foto})>>
      obterInterlocutoresDoUsuario(String cpf) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return {};

    final rows = await db.query(
      'mensagens_chat',
      columns: [
        'remetente_id',
        'remetente_nome',
        'remetente_foto',
        'destinatario_id',
      ],
      where: 'conversa_id LIKE ? AND remetente_id != ?',
      whereArgs: ['%$cpfNorm%', 'sistema'],
      orderBy: 'data_hora DESC',
    );

    final resultado = <String, ({String nome, String foto})>{};
    for (final r in rows) {
      final rem =
          ChatRepositorioSqlite.normalizarCpf(r['remetente_id'] as String? ?? '');
      final dest =
          ChatRepositorioSqlite.normalizarCpf(r['destinatario_id'] as String? ?? '');
      final outroCpf = rem == cpfNorm ? dest : rem;
      if (outroCpf.length == 11 &&
          outroCpf != cpfNorm &&
          !resultado.containsKey(outroCpf)) {
        final nome = rem != cpfNorm
            ? (r['remetente_nome'] as String? ?? '')
            : '';
        final foto = rem != cpfNorm
            ? (r['remetente_foto'] as String? ?? '')
            : '';
        resultado[outroCpf] = (nome: nome, foto: foto);
      }
    }
    return resultado;
  }
}
