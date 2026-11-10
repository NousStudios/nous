import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gerenciador dedicado à sincronização e reconciliação mútua
/// de conversas, mensagens e anexos de chat com o servidor balcão na rede local.
class SincronizadorChatBalcao {
  /// Sincroniza conversas e mensagens do balcão ao conectar um terminal móvel na rede local
  static Future<void> sincronizarMensagensComBalcao({
    required String ipServidor,
    required int portaServidor,
    String? cpfUsuario,
    String? lojaId,
  }) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final queryParams = <String, String>{};
      if (cpfUsuario != null && cpfUsuario.isNotEmpty) {
        queryParams['cpf'] = ChatService.normalizarCpf(cpfUsuario);
      }
      if (lojaId != null && lojaId.isNotEmpty) {
        queryParams['lojaId'] = lojaId;
      }

      // 1. Baixar conversas e grupos registrados no balcão
      try {
        final uriConversas = Uri.http(
          '$ipServidor:$portaServidor',
          '/api/chat/conversas',
          queryParams,
        );
        final reqConv = await client.getUrl(uriConversas);
        final respConv = await reqConv.close();
        if (respConv.statusCode == HttpStatus.ok) {
          final bodyConv = await utf8.decodeStream(respConv);
          final dadosConv = jsonDecode(bodyConv) as Map<String, dynamic>;

          if (dadosConv['excluidas'] is List) {
            for (final id in dadosConv['excluidas'] as List<dynamic>) {
              if (id is String && id.isNotEmpty) {
                final msgsLoc = await ChatService.carregarMensagens(id);
                if (msgsLoc.isEmpty) {
                  await ChatService.excluirConversaLocal(id);
                }
              }
            }
          }

          if (dadosConv['sucesso'] == true && dadosConv['conversas'] is List) {
            final listaConv = dadosConv['conversas'] as List<dynamic>;
            final idsServidorAtivos = <String>{};
            final excluidasLocais = await ChatService.obterIdsConversasExcluidas();
            int conversasNovas = 0;
            for (final c in listaConv) {
              if (c is Map<String, dynamic>) {
                final id = c['id'] as String? ?? '';
                if (id.isNotEmpty) {
                  idsServidorAtivos.add(id);
                  if (!excluidasLocais.contains(id)) {
                    final alterou = await salvarConversaLocal(c, notificar: false);
                    if (alterou) conversasNovas++;
                    final fotoRemota = (c['foto'] as String? ?? '').trim();
                    if (fotoRemota.isNotEmpty) {
                      unawaited(
                        ClienteRedeLocal().baixarImagemRemota(fotoRemota),
                      );
                    }
                    final idContato = (c['identificador'] as String? ?? '')
                        .replaceAll(RegExp(r'\D'), '');
                    if (idContato.length == 11) {
                      unawaited(
                        ClienteRedeLocal().buscarUsuarioRemoto(idContato),
                      );
                    }
                  }
                }
              }
            }
            if (conversasNovas > 0) {
              ChatService.notificarAlteracao();
            }
          }
        }
      } catch (e) {
        debugPrint(
          '[SincronizadorChatBalcao] Erro ao sincronizar conversas do balcão: $e',
        );
      }

      // 2. Baixar mensagens registradas no balcão
      final uri = Uri.http(
        '$ipServidor:$portaServidor',
        '/api/chat/mensagens',
        queryParams,
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['sucesso'] == true && dados['mensagens'] is List) {
          final lista = dados['mensagens'] as List<dynamic>;
          final meuCpfNorm = (cpfUsuario != null && cpfUsuario.isNotEmpty)
              ? ChatService.normalizarCpf(cpfUsuario)
              : await ChatService.obterCpfLogadoLocal();
          int mensagensNovas = 0;
          for (final item in lista) {
            if (item is Map<String, dynamic>) {
              var msg = MensagemChat.fromJson(item);
              final remCpf = ChatService.normalizarCpf(msg.remetenteId);
              final destCpf = ChatService.normalizarCpf(msg.destinatarioId);
              final souDest = meuCpfNorm.isNotEmpty &&
                  remCpf != meuCpfNorm &&
                  (destCpf == meuCpfNorm ||
                      msg.conversaId.endsWith('_usuario_$meuCpfNorm') ||
                      msg.conversaId.contains('user_$meuCpfNorm'));
              if (souDest && !msg.entregue && !msg.lida) {
                msg = msg.copyWith(entregue: true);
                ChatService.despacharConfirmacaoEntrega(msg.id, msg.conversaId);
              }
              final alterou = await ChatService.salvarMensagem(
                msg,
                originadaDaRede: true,
                notificar: false,
              );
              if (alterou) mensagensNovas++;

              if (msg.tipo == 'imagem' && msg.caminhoAnexo.isNotEmpty) {
                final existeLocal =
                    ImagemService.resolverCaminhoExistente(msg.caminhoAnexo) !=
                        null;
                if (!existeLocal && ClienteRedeLocal().conectado) {
                  final caminhoRemoto = msg.caminhoAnexo;
                  final msgId = msg.id;
                  unawaited(() async {
                    try {
                      final baixado = await ClienteRedeLocal().baixarImagemRemota(
                        caminhoRemoto,
                      );
                      if (baixado.isNotEmpty && baixado != caminhoRemoto) {
                        final db = await ChatService.obterDb();
                        await db.update(
                          'mensagens_chat',
                          {'caminho_anexo': baixado},
                          where: 'id = ?',
                          whereArgs: [msgId],
                        );
                        ChatService.notificarAlteracao();
                      }
                    } catch (_) {}
                  }());
                }
              }
            }
          }
          if (mensagensNovas > 0) {
            ChatService.notificarAlteracao();
          }
        }
      }

      // 3. Enviar conversas, mensagens e exclusões locais para o balcão
      try {
        final conversasLocais = await obterConversasParaSincronizacao(
          cpf: cpfUsuario,
          lojaId: lojaId,
        );
        final mensagensLocais = await obterMensagensParaSincronizacao(
          cpf: cpfUsuario,
          lojaId: lojaId,
        );
        final excluidasLocais = await ChatService.obterIdsConversasExcluidas();
        if (conversasLocais.isNotEmpty ||
            mensagensLocais.isNotEmpty ||
            excluidasLocais.isNotEmpty) {
          final uriSync = Uri.http(
            '$ipServidor:$portaServidor',
            '/api/chat/conversas/sync',
          );
          final reqSync = await client.postUrl(uriSync);
          reqSync.headers.contentType = ContentType.json;
          reqSync.write(
            jsonEncode({
              'conversas': conversasLocais,
              'mensagens': mensagensLocais,
              'excluidas': excluidasLocais,
            }),
          );
          await reqSync.close();
        }
      } catch (_) {}

      ChatService.notificarAlteracao();
    } catch (e) {
      debugPrint(
        '[SincronizadorChatBalcao] Erro ao sincronizar mensagens com balcão: $e',
      );
    }
  }

  /// Retorna as conversas persistidas no banco para envio em bloco pela rede Wi-Fi
  static Future<List<Map<String, dynamic>>> obterConversasParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) async {
    final db = await ChatService.obterDb();
    final excluidas = await ChatService.obterIdsConversasExcluidas();
    List<Map<String, dynamic>> lista;
    if (lojaId != null && lojaId.isNotEmpty) {
      lista = await db.query(
        'conversas_chat',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
      );
    } else if (cpf != null && cpf.isNotEmpty) {
      final cpfNorm = ChatService.normalizarCpf(cpf);
      lista = await db.query(
        'conversas_chat',
        where:
            'participantes_json LIKE ? OR id LIKE ? OR id LIKE ? OR identificador = ? OR identificador = ? OR eh_grupo = 1 OR loja_id = ? OR id LIKE ?',
        whereArgs: [
          '%$cpfNorm%',
          '%$cpfNorm%',
          '%$cpf%',
          cpfNorm,
          cpf,
          PdvProvider.idLojaColetivaNous,
          'loja_nous_coletiva_%',
        ],
      );
    } else {
      lista = await db.query('conversas_chat');
    }

    final ativas = excluidas.isNotEmpty
        ? lista.where((c) => !excluidas.contains(c['id'])).toList()
        : lista;

    final resultado = <Map<String, dynamic>>[];
    for (final raw in ativas) {
      final c = Map<String, dynamic>.from(raw);
      var foto = (c['foto'] as String? ?? '').trim();
      final id = c['identificador'] as String? ?? '';
      final cpfLimpo = ChatService.normalizarCpf(id);
      if (foto.isEmpty && cpfLimpo.length == 11) {
        final conta = await ContasNousService.buscarPorCpf(cpfLimpo);
        if (conta != null && conta.foto.isNotEmpty) {
          foto = conta.foto;
          c['foto'] = foto;
        }
      }
      resultado.add(c);
    }
    return resultado;
  }

  /// Salva ou mescla uma conversa recebida da rede local
  static Future<bool> salvarConversaLocal(
    Map<String, dynamic> c, {
    bool notificar = true,
  }) async {
    final db = await ChatService.obterDb();
    final id = c['id'] as String? ?? '';
    if (id.isEmpty) return false;

    if (await ChatService.isConversaExcluida(id)) return false;

    final ultMsg = c['ultima_mensagem'] ?? c['ultimaMensagem'] ?? '';
    final ultData =
        c['data_hora_ultima_mensagem'] ??
        c['dataHoraUltimaMensagem'] ??
        DateTime.now().toIso8601String();
    final atzEm =
        c['atualizado_em'] ??
        c['atualizadaEm'] ??
        DateTime.now().toIso8601String();

    String participantesJson = '[]';
    if (c['participantes_json'] is String &&
        (c['participantes_json'] as String).isNotEmpty) {
      participantesJson = c['participantes_json'] as String;
    } else if (c['participantesIds'] is List) {
      participantesJson = jsonEncode(c['participantesIds']);
    }

    final fotoOriginal = (c['foto'] as String? ?? '').trim();
    var fotoSalvar = fotoOriginal;

    if (fotoOriginal.isNotEmpty &&
        ImagemService.resolverCaminhoExistente(fotoOriginal) == null) {
      if (ClienteRedeLocal().conectado) {
        unawaited(() async {
          try {
            final baixada = await ClienteRedeLocal().baixarImagemRemota(
              fotoOriginal,
            );
            if (baixada.isNotEmpty && baixada != fotoOriginal) {
              final d = await ChatService.obterDb();
              await d.update(
                'conversas_chat',
                {'foto': baixada},
                where: 'id = ?',
                whereArgs: [id],
              );
              ChatService.notificarAlteracao();
            }
          } catch (_) {}
        }());
      }
    }

    final ehG = (c['eh_grupo'] as int?) ?? ((c['ehGrupo'] == true) ? 1 : 0);
    var nGrupo = (c['nome_grupo'] ?? c['nomeGrupo'] ?? '').toString();
    final tit = (c['titulo'] ?? 'Conversa').toString();
    if (nGrupo.isEmpty &&
        ehG == 1 &&
        tit.isNotEmpty &&
        tit != 'Conversa' &&
        tit != 'Nova Conversa') {
      nGrupo = tit;
    }

    final existentes = await db.query(
      'conversas_chat',
      columns: [
        'id',
        'titulo',
        'ultima_mensagem',
        'data_hora_ultima_mensagem',
        'foto',
        'fixada',
        'arquivada',
      ],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final fixadaEsperada =
        (c['fixada'] as int?) ?? ((c['fixada'] == true) ? 1 : 0);
    final arquivadaEsperada =
        (c['arquivada'] as int?) ?? ((c['arquivada'] == true) ? 1 : 0);
    if (existentes.isNotEmpty) {
      final ex = existentes.first;
      if (ex['titulo'] == tit &&
          ex['ultima_mensagem'] == ultMsg &&
          ex['data_hora_ultima_mensagem'] == ultData &&
          ex['foto'] == fotoSalvar &&
          ex['fixada'] == fixadaEsperada &&
          ex['arquivada'] == arquivadaEsperada) {
        return false;
      }
    }

    await db.insert('conversas_chat', {
      'id': id,
      'titulo': tit,
      'nome_grupo': nGrupo,
      'subtitulo': c['subtitulo'] ?? '',
      'foto': fotoSalvar,
      'identificador': c['identificador'] ?? id,
      'eh_loja': (c['eh_loja'] as int?) ?? ((c['ehLoja'] == true) ? 1 : 0),
      'eh_grupo': ehG,
      'loja_id': c['loja_id'] ?? c['lojaId'] ?? '',
      'participantes_json': participantesJson,
      'criado_em': c['criado_em'] ?? DateTime.now().toIso8601String(),
      'atualizado_em': atzEm,
      'ultima_mensagem': ultMsg,
      'data_hora_ultima_mensagem': ultData,
      'arquivada': arquivadaEsperada,
      'fixada': fixadaEsperada,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (notificar) {
      ChatService.notificarAlteracao();
    }
    return true;
  }

  /// Retorna as mensagens persistidas no banco para envio em bloco pela rede Wi-Fi
  static Future<List<Map<String, dynamic>>> obterMensagensParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) async {
    final db = await ChatService.obterDb();
    if (cpf != null && cpf.isNotEmpty) {
      final cpfNorm = ChatService.normalizarCpf(cpf);
      return await db.query(
        'mensagens_chat',
        where:
            'remetente_id = ? OR destinatario_id = ? OR remetente_id = ? OR destinatario_id = ? OR conversa_id LIKE ? OR conversa_id LIKE ? OR conversa_id LIKE ? OR conversa_id LIKE ?',
        whereArgs: [
          cpf,
          cpf,
          cpfNorm,
          cpfNorm,
          '%$cpfNorm%',
          '%$cpf%',
          'grupo_%',
          'loja_nous_coletiva_%',
        ],
        orderBy: 'data_hora ASC',
      );
    } else if (lojaId != null && lojaId.isNotEmpty) {
      return await db.query(
        'mensagens_chat',
        where: 'remetente_id = ? OR destinatario_id = ? OR conversa_id LIKE ?',
        whereArgs: [lojaId, lojaId, '%$lojaId%'],
        orderBy: 'data_hora ASC',
      );
    } else {
      return await db.query('mensagens_chat', orderBy: 'data_hora ASC');
    }
  }
}
