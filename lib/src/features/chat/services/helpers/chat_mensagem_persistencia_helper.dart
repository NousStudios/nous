import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_conversa_info_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Resultado da verificação de deduplicação e mesclagem de status de uma mensagem.
class ResultadoDeduplicacaoMensagem {
  final bool ignorar;
  final bool jaExiste;
  final MensagemChat mensagem;

  const ResultadoDeduplicacaoMensagem({
    required this.ignorar,
    required this.jaExiste,
    required this.mensagem,
  });
}

/// Helper coeso para ajuste temporal, deduplicação, persistência SQLite
/// e despacho de mensagens do chat na rede local.
class ChatMensagemPersistenciaHelper {
  /// Garante ordenação monotônica da [mensagem] enviada localmente.
  static Future<MensagemChat> ajustarDataHoraEnvio(
    Database db,
    MensagemChat mensagem,
  ) async {
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
      return mensagem.copyWith(dataHora: dataHoraAjustada);
    }
    return mensagem;
  }

  /// Verifica se a mensagem já existe exatamente igual no banco e, caso exista
  /// com alterações, impede rebaixamento de status de entrega/leitura.
  static Future<ResultadoDeduplicacaoMensagem> verificarDeduplicacaoEMesclar(
    Database db,
    MensagemChat mensagem,
  ) async {
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

    if (existentes.isEmpty) {
      return ResultadoDeduplicacaoMensagem(
        ignorar: false,
        jaExiste: false,
        mensagem: mensagem,
      );
    }

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
      return ResultadoDeduplicacaoMensagem(
        ignorar: true,
        jaExiste: true,
        mensagem: mensagem,
      );
    }

    final statusFinal =
        _pesoStatus(stEx) > _pesoStatus(mensagem.statusEnvio)
            ? stEx
            : mensagem.statusEnvio;

    return ResultadoDeduplicacaoMensagem(
      ignorar: false,
      jaExiste: true,
      mensagem: mensagem.copyWith(
        lida: lidaEx || mensagem.lida,
        entregue: entEx || mensagem.entregue,
        statusEnvio: statusFinal,
      ),
    );
  }

  static int _pesoStatus(String s) {
    switch (s) {
      case 'lida':
        return 3;
      case 'entregue':
        return 2;
      case 'enviada':
        return 1;
      default:
        return 0;
    }
  }

  /// Ajusta o timestamp da mensagem recebida/salva preservando o horário
  /// original em atualizações e calibrando anomalias de relógio na rede.
  static Future<MensagemChat> ajustarDataHoraSalva(
    Database db,
    MensagemChat mensagem, {
    required bool originadaDaRede,
    required bool jaExiste,
  }) async {
    DateTime dataHoraAjustada = mensagem.dataHora.toLocal();
    final agoraRede = RelogioRedeService.agora().toLocal();

    if (originadaDaRede && dataHoraAjustada.difference(agoraRede).inSeconds > 5) {
      dataHoraAjustada = agoraRede;
    }

    if (jaExiste) {
      final rowsDataExistente = await db.query(
        'mensagens_chat',
        columns: ['data_hora'],
        where: 'id = ?',
        whereArgs: [mensagem.id],
        limit: 1,
      );
      if (rowsDataExistente.isNotEmpty) {
        final dtEx = DateTime.tryParse(
          rowsDataExistente.first['data_hora'] as String? ?? '',
        )?.toLocal();
        if (dtEx != null) {
          dataHoraAjustada = dtEx;
        }
      }
    } else {
      final ultimas = await db.query(
        'mensagens_chat',
        columns: ['data_hora', 'remetente_id'],
        where: 'conversa_id = ? AND id != ?',
        whereArgs: [mensagem.conversaId, mensagem.id],
        orderBy: 'data_hora DESC, id DESC',
        limit: 1,
      );
      if (ultimas.isNotEmpty) {
        final ultimaStr = ultimas.first['data_hora'] as String?;
        final ultimoRem = ChatRepositorioSqlite.normalizarCpf(
          ultimas.first['remetente_id'] as String? ?? '',
        );
        final atualRem = ChatRepositorioSqlite.normalizarCpf(
          mensagem.remetenteId,
        );
        final mesmoRemetente = (atualRem.isNotEmpty && ultimoRem == atualRem) ||
            ultimas.first['remetente_id'] == mensagem.remetenteId;
        final ehMidiaAtrasadaDaRede = originadaDaRede &&
            mensagem.tipo != 'texto' &&
            agoraRede.difference(dataHoraAjustada).inSeconds.abs() <= 120;

        if (ultimaStr != null && ultimaStr.isNotEmpty) {
          final ultimaData = DateTime.tryParse(ultimaStr)?.toLocal();
          if (ultimaData != null && !dataHoraAjustada.isAfter(ultimaData)) {
            if (!(originadaDaRede && (mesmoRemetente || ehMidiaAtrasadaDaRede))) {
              if (ultimaData.difference(agoraRede).inSeconds > 30) {
                dataHoraAjustada = agoraRede;
              } else {
                dataHoraAjustada = ultimaData.add(const Duration(milliseconds: 5));
              }
            }
          }
        }
      }
    }

    if (dataHoraAjustada != mensagem.dataHora) {
      return mensagem.copyWith(dataHora: dataHoraAjustada);
    }
    return mensagem;
  }

  /// Persiste a mensagem na tabela `mensagens_chat` e atualiza ou cria o
  /// registro correspondente em `conversas_chat`.
  static Future<void> persistirMensagemEAtualizarConversa(
    Database db, {
    required MensagemChat mensagemPersistida,
    required MensagemChat mensagemReferencia,
    required String resumo,
    required String cpfParaMetadados,
    required String statusEnvio,
    required bool lida,
    required bool editada,
    required bool usarRelogioRedeAoCriar,
  }) async {
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
      'lida': lida ? 1 : 0,
      'tipo': mensagemPersistida.tipo,
      'caminho_anexo': mensagemPersistida.caminhoAnexo,
      'nome_anexo': mensagemPersistida.nomeAnexo,
      'tamanho_anexo': mensagemPersistida.tamanhoAnexo,
      'pedido_id': mensagemPersistida.pedidoId,
      'dados_pedido_json': mensagemPersistida.dadosPedidoJson,
      'editada': editada ? 1 : 0,
      'historico_edicoes': jsonEncode(mensagemPersistida.historicoEdicoes),
      'status_envio': statusEnvio,
      'entregue': mensagemPersistida.entregue ? 1 : 0,
      'favorita': mensagemPersistida.favorita ? 1 : 0,
      'fixada': mensagemPersistida.fixada ? 1 : 0,
      'reacoes_json': jsonEncode(mensagemPersistida.reacoes),
      'assinatura': mensagemPersistida.assinatura,
      'resposta_a_id': mensagemPersistida.respostaAId,
      'resposta_a_texto': mensagemPersistida.respostaATexto,
      'resposta_a_autor': mensagemPersistida.respostaAAutor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final ehConvLojaUsuario = mensagemReferencia.conversaId.startsWith('loja_') &&
        mensagemReferencia.conversaId.contains('_usuario_');
    final lojaIdConv = ehConvLojaUsuario
        ? mensagemReferencia.conversaId.substring(
            5,
            mensagemReferencia.conversaId.indexOf('_usuario_'),
          )
        : '';

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem':
            mensagemReferencia.dataHora.toIso8601String(),
        'atualizado_em': RelogioRedeService.agora().toIso8601String(),
        if (ehConvLojaUsuario) 'eh_loja': 1,
        if (ehConvLojaUsuario && lojaIdConv.isNotEmpty) 'loja_id': lojaIdConv,
      },
      where: 'id = ?',
      whereArgs: [mensagemReferencia.conversaId],
    );

    if (count == 0) {
      final info =
          await ResolvedorConversaInfoService.resolverMetadadosParaMensagem(
        mensagemReferencia,
        cpfLogado: cpfParaMetadados,
      );

      await db.insert('conversas_chat', {
        'id': mensagemReferencia.conversaId,
        'titulo': info.titulo,
        'subtitulo': info.subtitulo,
        'foto': info.foto,
        'identificador': info.identificador,
        'eh_loja': (ehConvLojaUsuario || info.ehLoja) ? 1 : 0,
        'eh_grupo': info.ehGrupo ? 1 : 0,
        'loja_id': (info.lojaId?.isNotEmpty == true) ? info.lojaId! : lojaIdConv,
        'participantes_json': jsonEncode([
          mensagemReferencia.remetenteId,
          mensagemReferencia.destinatarioId,
        ]),
        'criado_em': mensagemReferencia.dataHora.toIso8601String(),
        'atualizado_em': usarRelogioRedeAoCriar
            ? RelogioRedeService.agora().toIso8601String()
            : DateTime.now().toIso8601String(),
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem':
            mensagemReferencia.dataHora.toIso8601String(),
        'arquivada': 0,
        'fixada': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Dispara o envio em segundo plano para a rede local e atualiza o status
  /// para `'enviada'` em caso de sucesso.
  static void despacharEnvioBackground(
    Database db,
    MensagemChat mensagemPersistida, {
    required VoidCallback aoNotificar,
  }) {
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
              await ChatSincronizacaoService.despacharMensagemParaRede(
            mensagemPersistida,
          );
          if (enviado) {
            await db.update(
              'mensagens_chat',
              {'status_envio': 'enviada'},
              where: 'id = ?',
              whereArgs: [mensagemPersistida.id],
            );
            aoNotificar();
          }
        }
      } catch (e) {
        debugPrint(
          '[ChatMensagensService] Despacho em background mantido na fila: $e',
        );
      }
    }());
  }

  /// Converte linhas do SQLite em lista de [MensagemChat] não lidas.
  static List<MensagemChat> mapearLinhasNaoLidas(
    List<Map<String, dynamic>> rows,
  ) {
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
            tipo: r['tipo'] as String? ?? 'texto',
            caminhoAnexo: r['caminho_anexo'] as String? ?? '',
            nomeAnexo: r['nome_anexo'] as String? ?? '',
            tamanhoAnexo: r['tamanho_anexo'] as int? ?? 0,
            dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '') ??
                DateTime.now(),
            enviadaPorMim: false,
            nomeAtendente: r['nome_atendente'] as String? ?? '',
            cpfAtendente: r['cpf_atendente'] as String? ?? '',
            lida: false,
          ),
        )
        .toList();
  }
}
