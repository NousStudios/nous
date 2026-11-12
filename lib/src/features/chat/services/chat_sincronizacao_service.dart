import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Serviço responsável pelo despacho e propagação de eventos de chat na rede local
class ChatSincronizacaoService {
  ChatSincronizacaoService._();

  /// Despacha qualquer evento para a rede local (seja via servidor balcão ou cliente terminal)
  static void despacharEventoRede(Map<String, dynamic> evento) {
    try {
      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        servidor.notificarTodos(evento);
        return;
      }
      final cliente = ClienteRedeLocal();
      if (cliente.conectado) {
        cliente.enviarEventoWs(evento);
      }
    } catch (e) {
      debugPrint('[ChatSincronizacaoService] Erro ao despachar evento para a rede: $e');
    }
  }

  /// Despacha uma mensagem com anexos e metadados para a malha da rede local
  static Future<bool> despacharMensagemParaRede(MensagemChat mensagem) async {
    try {
      final dadosEnvio = mensagem.toJson();

      // Propaga metadados consolidados do grupo junto com a mensagem
      if (mensagem.conversaId.startsWith('grupo_')) {
        try {
          final db = await ChatRepositorioSqlite.obterDb();
          final convs = await db.query(
            'conversas_chat',
            where: 'id = ?',
            whereArgs: [mensagem.conversaId],
          );
          if (convs.isNotEmpty) {
            final c = convs.first;
            dadosEnvio['grupoTitulo'] = c['titulo'];
            dadosEnvio['grupoFoto'] = c['foto'];
            dadosEnvio['grupoParticipantesJson'] = c['participantes_json'];
          }
        } catch (_) {}
      }

      // Se for conversa E2EE e existir anexo físico cifrado (.enc), prioriza o envio da versão cifrada
      String caminhoAnexoParaEnvio = mensagem.caminhoAnexo;
      if (mensagem.caminhoAnexo.isNotEmpty &&
          ChatE2eeService.ehConversaElegivelE2ee(mensagem.conversaId)) {
        final caminhoFisico = ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo);
        if (caminhoFisico != null) {
          final arqEnc = File('$caminhoFisico.enc');
          if (arqEnc.existsSync()) {
            caminhoAnexoParaEnvio = arqEnc.path;
          }
        }
      }

      // Se contiver anexo, embute os bytes em Base64
      final base64 = await ChatMediaService.obterBytesBase64ParaEnvio(
        caminhoAnexoParaEnvio,
      );
      if (base64 != null) {
        dadosEnvio['anexoBytesBase64'] = base64;
      }

      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        if (mensagem.caminhoAnexo.isNotEmpty) {
          final nomeBase = p.basename(caminhoAnexoParaEnvio);
          dadosEnvio['caminhoAnexo'] = 'imagens/$nomeBase';
        }
        servidor.notificarTodos({
          'tipo': 'mensagem_chat',
          'mensagem': dadosEnvio,
        });
        return true;
      }

      final cliente = ClienteRedeLocal();
      final enviado = await cliente.enviarMensagemChat(
        mensagem,
        payloadCustomizado: dadosEnvio,
      );
      return enviado;
    } catch (e) {
      debugPrint('[ChatSincronizacaoService] Erro ao despachar mensagem pela rede: $e');
    }
    return false;
  }

  /// Despacha confirmação de leitura instantânea para o remetente (2 checks azuis)
  static void despacharConfirmacaoLida(String convId, String idLeitor) {
    despacharEventoRede({
      'tipo': 'mensagens_lidas',
      'conversaId': convId,
      'idLeitor': idLeitor,
    });
  }

  /// Despacha confirmação de entrega para o remetente (2 checks cinzas)
  static void despacharConfirmacaoEntrega(String msgId, String convId) {
    despacharEventoRede({
      'tipo': 'mensagem_entregue',
      'id': msgId,
      'conversaId': convId,
    });
  }

  /// Despacha aviso de conversa renomeada na rede local
  static void despacharConversaRenomeada(String conversaId, String novoTitulo) {
    despacharEventoRede({
      'tipo': 'conversa_renomeada',
      'conversaId': conversaId,
      'novoTitulo': novoTitulo,
    });
  }

  /// Despacha uma conversa inteira para espelhamento em outros dispositivos
  static void despacharConversaAtualizada(ConversaChat conversa) {
    despacharEventoRede({
      'tipo': 'conversa_atualizada',
      'conversa': conversa.toJson(),
    });
  }

  /// Drena mensagens pendentes na fila offline assim que uma conexão for restabelecida
  static Future<bool> drenarFilaDeSaida() async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query(
        'mensagens_chat',
        where: 'status_envio = ?',
        whereArgs: ['pendente'],
        orderBy: 'data_hora ASC',
      );
      if (rows.isEmpty) return false;

      final servidor = ServidorRedeLocal();
      final cliente = ClienteRedeLocal();
      if (!servidor.ativo && !cliente.conectado && cliente.ipServidor == null) {
        return false;
      }

      bool alterou = false;
      for (final r in rows) {
        final msg = MensagemChat.fromJson(r);
        final enviado = await despacharMensagemParaRede(msg);
        if (enviado) {
          alterou = true;
          await db.update(
            'mensagens_chat',
            {'status_envio': 'enviada'},
            where: 'id = ?',
            whereArgs: [msg.id],
          );
        }
      }
      return alterou;
    } catch (e) {
      debugPrint('[ChatSincronizacaoService] Erro ao drenar fila de saída: $e');
      return false;
    }
  }
}
