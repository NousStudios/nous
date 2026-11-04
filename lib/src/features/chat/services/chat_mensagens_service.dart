import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/notificacao_android_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_conversa_info_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
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
            id.startsWith('loja_nous_coletiva_')) {
          continue;
        }

        final ident =
            ChatRepositorioSqlite.normalizarCpf(r['identificador'] as String? ?? '');
        if (ident.length == 11) {
          porInterlocutor.putIfAbsent(ident, () => []).add(r);
        }
      }

      for (final entry in porInterlocutor.entries) {
        final lista = entry.value;
        if (lista.length <= 1) continue;

        lista.sort((a, b) {
          final dataA = a['data_hora_ultima_mensagem'] as String? ?? '';
          final dataB = b['data_hora_ultima_mensagem'] as String? ?? '';
          return dataB.compareTo(dataA);
        });

        final principal = lista.first;
        final principalId = principal['id'] as String;

        for (int i = 1; i < lista.length; i++) {
          final duplicata = lista[i];
          final dupId = duplicata['id'] as String;
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
      'lida': 0,
      'tipo': mensagem.tipo,
      'caminho_anexo': mensagem.caminhoAnexo,
      'nome_anexo': mensagem.nomeAnexo,
      'tamanho_anexo': mensagem.tamanhoAnexo,
      'pedido_id': mensagem.pedidoId,
      'dados_pedido_json': mensagem.dadosPedidoJson,
      'editada': 0,
      'historico_edicoes': jsonEncode(mensagem.historicoEdicoes),
      'status_envio': 'pendente',
      'entregue': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
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
        'eh_loja': info.ehLoja ? 1 : 0,
        'eh_grupo': info.ehGrupo ? 1 : 0,
        'loja_id': info.lojaId ?? '',
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
        if (servidor.ativo || cliente.conectado || cliente.ipServidor != null) {
          final enviado =
              await ChatSincronizacaoService.despacharMensagemParaRede(mensagem);
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

  static Future<void> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
    required Future<String> Function() obterCpfLogadoLocal,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);
    final meuCpf = await obterCpfLogadoLocal();

    DateTime dataHoraAjustada = mensagem.dataHora;
    final agoraRede = RelogioRedeService.agora();

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
        final ultimaData = DateTime.tryParse(ultimaStr);
        if (ultimaData != null && !dataHoraAjustada.isAfter(ultimaData)) {
          dataHoraAjustada = ultimaData.add(const Duration(milliseconds: 5));
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mensagem.conversaId],
    );

    if (count == 0) {
      final ehLoja = mensagem.conversaId.startsWith('loja_');
      final ehGrupo = mensagem.conversaId.startsWith('grupo_');
      String? lojaId;
      String identificadorSalvar = mensagem.destinatarioId;

      if (ehLoja && mensagem.conversaId.contains('_usuario_')) {
        lojaId = mensagem.conversaId.substring('loja_'.length, mensagem.conversaId.indexOf('_usuario_'));
        final cpfCli = ChatRepositorioSqlite.normalizarCpf(
          mensagem.conversaId.split('_usuario_').last,
        );
        if (cpfCli.length == 11) {
          identificadorSalvar = cpfCli;
        }
      }

      String tituloConversa = ehGrupo ? 'Grupo' : '';
      String subtituloConversa = ehLoja ? 'Loja Nous' : 'Contato Nous';
      String fotoConversa = '';

      if (ehLoja && identificadorSalvar.length == 11) {
        final contaCliente = await ContasNousService.buscarPorCpf(identificadorSalvar);
        if (contaCliente != null) {
          tituloConversa = contaCliente.nomeExibicao;
          subtituloConversa = contaCliente.usernameExibicao.isNotEmpty
              ? contaCliente.usernameExibicao
              : 'Cliente Nous';
          fotoConversa = contaCliente.fotoExibicao;
        } else if (mensagem.remetenteNome.isNotEmpty && mensagem.remetenteId == identificadorSalvar) {
          tituloConversa = mensagem.remetenteNome;
          fotoConversa = mensagem.remetenteFoto;
        }
      } else if (!ehGrupo && !ehLoja) {
        var outroCpf =
            ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);
        if (outroCpf.length != 11 || outroCpf == meuCpf) {
          outroCpf = ChatRepositorioSqlite.extrairOutroCpf(
              mensagem.conversaId, meuCpf);
        }
        if (outroCpf.length == 11) {
          final conta = await ContasNousService.buscarPorCpf(outroCpf);
          if (conta != null) {
            tituloConversa = conta.nomeExibicao;
            subtituloConversa = conta.usernameExibicao.isNotEmpty
                ? conta.usernameExibicao
                : 'Usuário Nous';
            fotoConversa = conta.fotoExibicao;
          }
        }
      }
      if (tituloConversa.isEmpty) {
        tituloConversa = ehGrupo ? 'Grupo' : (ehLoja ? 'Cliente' : 'Contato Nous');
      }

      await db.insert('conversas_chat', {
        'id': mensagem.conversaId,
        'titulo': tituloConversa,
        'subtitulo': subtituloConversa,
        'foto': fotoConversa,
        'identificador': identificadorSalvar,
        'eh_loja': ehLoja ? 1 : 0,
        'eh_grupo': ehGrupo ? 1 : 0,
        'loja_id': lojaId ?? '',
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
  }

  static Future<void> processarMensagemRecebidaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
    required String? idConversaAtiva,
    required Future<String> Function() obterCpfLogadoLocal,
    required Future<bool> Function(String conversaId) deveNotificarConversa,
    required VoidCallback aoNotificar,
  }) async {
    try {
      final tipoEvento = payloadMensagem['tipo'] as String? ?? 'texto';
      if (tipoEvento == 'mensagem_entregue' || tipoEvento == 'mensagens_lidas') {
        return;
      }
      final msgIdBruto = payloadMensagem['id'] as String? ?? '';
      if (msgIdBruto.trim().isEmpty) {
        return;
      }

      var mensagem = MensagemChat.fromJson(payloadMensagem);
      if (mensagem.id.trim().isEmpty) {
        return;
      }
      if (mensagem.tipo == 'texto' &&
          mensagem.texto.trim().isEmpty &&
          mensagem.caminhoAnexo.trim().isEmpty &&
          mensagem.pedidoId.trim().isEmpty) {
        return;
      }

      if (mensagem.tipo == 'imagem' && mensagem.caminhoAnexo.isNotEmpty) {
        final caminhoAjustado =
            ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo);
        if (caminhoAjustado != null &&
            caminhoAjustado != mensagem.caminhoAnexo) {
          mensagem = mensagem.copyWith(caminhoAnexo: caminhoAjustado);
        }
      }

      final db = await ChatRepositorioSqlite.obterDb();
      await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);

      if (mensagem.conversaId.startsWith('grupo_')) {
        final gTitulo = payloadMensagem['nomeGrupo'] as String? ??
            payloadMensagem['grupoTitulo'] as String? ??
            'Grupo';
        final gFoto = payloadMensagem['grupoFoto'] as String?;
        final gParts = payloadMensagem['participantesJson'] as String?;

        final existeGrupo = await db.query(
          'conversas_chat',
          where: 'id = ?',
          whereArgs: [mensagem.conversaId],
          limit: 1,
        );
        if (existeGrupo.isEmpty) {
          await db.insert('conversas_chat', {
            'id': mensagem.conversaId,
            'titulo': gTitulo,
            'nome_grupo': gTitulo,
            'subtitulo': 'Grupo • $gTitulo',
            if (gFoto != null && gFoto.isNotEmpty) 'foto': gFoto,
            'identificador': mensagem.conversaId,
            'eh_loja': 0,
            'eh_grupo': 1,
            if (gParts != null && gParts.isNotEmpty)
              'participantes_json': gParts,
            'criado_em': mensagem.dataHora.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      final anexoBase64 = payloadMensagem['anexoBytesBase64'] as String?;
      if (anexoBase64 != null && anexoBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(anexoBase64);
          if (bytes.isNotEmpty) {
            final salvo = await ChatMediaService.salvarBytesAnexo(
              bytes,
              nomeSugerido: mensagem.nomeAnexo,
            );
            if (salvo != null) {
              mensagem = mensagem.copyWith(caminhoAnexo: salvo);
            }
          }
        } catch (e) {
          debugPrint(
              '[ChatMensagensService] Erro ao gravar anexo recebido via rede: $e');
        }
      } else if (mensagem.tipo == 'imagem' &&
          mensagem.caminhoAnexo.isNotEmpty) {
        final existeLocal =
            ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo) !=
                null;
        if (!existeLocal && ClienteRedeLocal().conectado) {
          final caminhoRemotoMsg = mensagem.caminhoAnexo;
          final msgIdParaAtualizar = mensagem.id;
          unawaited(() async {
            try {
              final baixado = await ClienteRedeLocal().baixarImagemRemota(
                caminhoRemotoMsg,
              );
              if (baixado.isNotEmpty && baixado != caminhoRemotoMsg) {
                final d = await ChatRepositorioSqlite.obterDb();
                await d.update(
                  'mensagens_chat',
                  {'caminho_anexo': baixado},
                  where: 'id = ?',
                  whereArgs: [msgIdParaAtualizar],
                );
                aoNotificar();
              }
            } catch (_) {}
          }());
        }
      }

      final meuCpf = await obterCpfLogadoLocal();
      final remetenteCpf =
          ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);

      // Verifica se a mensagem já foi criada/enviada localmente neste próprio aparelho
      final msgsExistentes = await db.query(
        'mensagens_chat',
        where: 'id = ?',
        whereArgs: [mensagem.id],
        limit: 1,
      );
      final jaExisteLocal = msgsExistentes.isNotEmpty;
      final jaFoiEnviadaPorMim = jaExisteLocal &&
          (msgsExistentes.first['status_envio'] == 'pendente' ||
              msgsExistentes.first['status_envio'] == 'enviada');

      // Se este nó é o servidor balcão (hospedeiro da loja) e a mensagem é de uma conversa de loja:
      final ehConversaLoja = mensagem.conversaId.startsWith('loja_');
      final receptorEhLojaBalcao = ehConversaLoja && ServidorRedeLocal().ativo;

      final bool ehMinhaPropriaMensagem;
      if (jaFoiEnviadaPorMim) {
        ehMinhaPropriaMensagem = true;
      } else if (receptorEhLojaBalcao) {
        final remLimpo = mensagem.remetenteId.startsWith('loja_')
            ? mensagem.remetenteId.substring(5)
            : mensagem.remetenteId;
        final lojaBalcaoId = ServidorRedeLocal().lojaAtiva?.id ?? '';
        ehMinhaPropriaMensagem = lojaBalcaoId.isNotEmpty && remLimpo == lojaBalcaoId;
      } else {
        final remEhLoja = mensagem.remetenteId.startsWith('loja_') ||
            (ehConversaLoja && mensagem.remetenteId != meuCpf);
        if (remEhLoja) {
          ehMinhaPropriaMensagem = false;
        } else {
          ehMinhaPropriaMensagem = meuCpf.isNotEmpty && remetenteCpf == meuCpf;
        }
      }

      if (ehMinhaPropriaMensagem) {
        mensagem = mensagem.copyWith(
          enviadaPorMim: true,
          statusEnvio: 'enviada',
        );
      }

      final usuarioEstaOlhandoConversa = idConversaAtiva != null &&
          idConversaAtiva.isNotEmpty &&
          idConversaAtiva == mensagem.conversaId;

      if (!ehMinhaPropriaMensagem && usuarioEstaOlhandoConversa) {
        mensagem = mensagem.copyWith(lida: true, statusEnvio: 'lida');
        NotificacaoAndroidService.cancelarNotificacaoConversa(mensagem.conversaId);
      }

      await salvarMensagem(
        mensagem,
        originadaDaRede: true,
        obterCpfLogadoLocal: obterCpfLogadoLocal,
        aoNotificar: aoNotificar,
      );

      if (!ehMinhaPropriaMensagem) {
        if (usuarioEstaOlhandoConversa) {
          ChatSincronizacaoService.despacharConfirmacaoLida(
              mensagem.conversaId, meuCpf);
        } else {
          ChatSincronizacaoService.despacharConfirmacaoEntrega(
              mensagem.id, mensagem.conversaId);

          final deveNotificar =
              await deveNotificarConversa(mensagem.conversaId);
          if (emitirAlertaSonoro && deveNotificar) {
            SomService.tocarBipPadrao();
          }
          if (deveNotificar) {
            await NotificacaoAndroidService.exibirNotificacaoMensagem(mensagem);
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[ChatMensagensService] Erro ao processar mensagem recebida da rede: $e');
    }
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
    String lojaId,
  ) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [lojaId, 'loja_${lojaId}_%', lojaId],
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
    String cpf,
  ) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return [];
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR conversa_id LIKE ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [cpfNorm, '%$cpfNorm%', 'grupo_%', cpfNorm],
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
