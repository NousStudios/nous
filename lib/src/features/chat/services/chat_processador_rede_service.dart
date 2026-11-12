import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/notificacao_android_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Especialista no processamento, enriquecimento e despacho de reações/notificações
/// de mensagens e eventos de chat recebidos através da rede local.
class ChatProcessadorRedeService {
  /// Processa eventos e payloads de mensagens recebidas pela rede local
  static Future<void> processarMensagemRecebidaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
    required String? idConversaAtiva,
    required Future<String> Function() obterCpfLogadoLocal,
    required Future<bool> Function(String conversaId) deveNotificarConversa,
    required VoidCallback aoNotificar,
    required Future<bool> Function(
      MensagemChat mensagem, {
      bool originadaDaRede,
      required Future<String> Function() obterCpfLogadoLocal,
      required VoidCallback aoNotificar,
    }) salvarMensagemCallback,
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

      if (tipoEvento == 'mensagem_excluida') {
        final db = await ChatRepositorioSqlite.obterDb();
        await db.delete('mensagens_chat', where: 'id = ?', whereArgs: [msgIdBruto]);
        aoNotificar();
        return;
      }

      if (tipoEvento == 'mensagem_editada') {
        final db = await ChatRepositorioSqlite.obterDb();
        final novoTexto = payloadMensagem['novoTexto'] as String? ??
            payloadMensagem['texto'] as String? ??
            '';
        final hist = payloadMensagem['historicoEdicoes'];
        await db.update(
          'mensagens_chat',
          {
            'texto': novoTexto,
            'editada': 1,
            if (hist != null) 'historico_edicoes': jsonEncode(hist),
          },
          where: 'id = ?',
          whereArgs: [msgIdBruto],
        );
        aoNotificar();
        return;
      }

      if (tipoEvento == 'mensagem_fixada') {
        final fixadaVal = payloadMensagem['fixada'] == true || payloadMensagem['fixada'] == 1;
        await ChatRepositorioSqlite.alternarFixarMensagem(msgIdBruto, fixar: fixadaVal);
        aoNotificar();
        return;
      }

      if (tipoEvento == 'mensagem_reacao') {
        final db = await ChatRepositorioSqlite.obterDb();
        final reacoesRaw = payloadMensagem['reacoes'];
        if (reacoesRaw is Map) {
          await db.update(
            'mensagens_chat',
            {'reacoes_json': jsonEncode(reacoesRaw)},
            where: 'id = ?',
            whereArgs: [msgIdBruto],
          );
          aoNotificar();
        }
        return;
      }

      if (tipoEvento == 'comanda_atualizada') {
        final db = await ChatRepositorioSqlite.obterDb();
        final dadosPed = payloadMensagem['dadosPedidoJson'] as String? ?? '';
        final textoNovo = payloadMensagem['texto'] as String?;
        await db.update(
          'mensagens_chat',
          {
            'dados_pedido_json': dadosPed,
            if (textoNovo != null && textoNovo.isNotEmpty) 'texto': textoNovo,
          },
          where: 'id = ?',
          whereArgs: [msgIdBruto],
        );
        aoNotificar();
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
              '[ChatProcessadorRedeService] Erro ao gravar anexo recebido via rede: $e');
        }
      } else if (mensagem.caminhoAnexo.isNotEmpty) {
        final existeLocal =
            ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo) !=
                null;
        if (!existeLocal && ClienteRedeLocal().conectado) {
          final caminhoRemotoMsg = mensagem.caminhoAnexo;
          final msgIdParaAtualizar = mensagem.id;
          final tipoMsg = mensagem.tipo;
          unawaited(() async {
            try {
              final String baixado;
              if (tipoMsg == 'audio') {
                baixado = await ClienteRedeLocal().baixarAudioRemoto(caminhoRemotoMsg);
              } else {
                baixado = await ClienteRedeLocal().baixarImagemRemota(caminhoRemotoMsg);
              }
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

      // Identificação se a conversa pertence a uma Loja
      final ehConversaLoja = mensagem.conversaId.startsWith('loja_');
      String cpfClienteConv = '';
      String lojaIdConv = '';
      if (ehConversaLoja && mensagem.conversaId.contains('_usuario_')) {
        final antesUsuario = mensagem.conversaId.substring(0, mensagem.conversaId.indexOf('_usuario_'));
        lojaIdConv = antesUsuario.startsWith('loja_') ? antesUsuario.substring(5) : antesUsuario;
        cpfClienteConv = ChatRepositorioSqlite.normalizarCpf(
          mensagem.conversaId.split('_usuario_').last,
        );
      }

      final lojaAtivaBalcao = ServidorRedeLocal().lojaAtiva != null
          ? PdvProvider.normalizarIdLoja(ServidorRedeLocal().lojaAtiva!.id)
          : '';
      final lojaAtivaPdv =
          ServidorRedeLocal().pdvProvider?.buscarPorId(lojaIdConv) != null
              ? lojaIdConv
              : '';
      final lojaClienteConectado = ClienteRedeLocal().lojaSincronizada != null
          ? PdvProvider.normalizarIdLoja(ClienteRedeLocal().lojaSincronizada!.id)
          : '';

      final operaComoServidorBalcao = ServidorRedeLocal().ativo &&
          lojaIdConv.isNotEmpty &&
          (lojaAtivaBalcao == lojaIdConv || lojaAtivaPdv == lojaIdConv);
      final operaComoTerminalLoja =
          lojaIdConv.isNotEmpty && lojaClienteConectado == lojaIdConv;

      final souClienteDaConversa = meuCpf.isNotEmpty &&
          cpfClienteConv.isNotEmpty &&
          meuCpf == cpfClienteConv;

      bool temLojaNoCofreLocal = false;
      if (!operaComoServidorBalcao &&
          !operaComoTerminalLoja &&
          !souClienteDaConversa &&
          ehConversaLoja &&
          lojaIdConv.isNotEmpty) {
        try {
          final lojaLocal = await LojasService.carregarLojaPorId(lojaIdConv);
          if (lojaLocal != null) {
            temLojaNoCofreLocal = true;
          }
        } catch (_) {}
      }

      final esteDispositivoOperaComoEstaLoja = ehConversaLoja &&
          lojaIdConv.isNotEmpty &&
          (operaComoServidorBalcao ||
              operaComoTerminalLoja ||
              temLojaNoCofreLocal);

      final bool ehMinhaPropriaMensagem;
      final bool souDestinatarioReal;
      final destCpf = ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);

      if (jaFoiEnviadaPorMim) {
        ehMinhaPropriaMensagem = true;
        souDestinatarioReal = false;
      } else if (ehConversaLoja) {
        final remEhLoja = mensagem.remetenteId.startsWith('loja_') ||
            (cpfClienteConv.isNotEmpty && remetenteCpf != cpfClienteConv);

        if (remEhLoja) {
          // Mensagem enviada pela Loja: se este aparelho pertence ao cliente da conversa
          // e não é o servidor balcão enviando para si mesmo, deve notificar o cliente!
          if (souClienteDaConversa && !operaComoServidorBalcao) {
            ehMinhaPropriaMensagem = false;
            souDestinatarioReal = true;
          } else {
            ehMinhaPropriaMensagem = true;
            souDestinatarioReal = false;
          }
        } else {
          // Mensagem enviada pelo Cliente
          if (esteDispositivoOperaComoEstaLoja &&
              (operaComoServidorBalcao ||
                  operaComoTerminalLoja ||
                  !souClienteDaConversa)) {
            ehMinhaPropriaMensagem = false;
            souDestinatarioReal = true;
          } else {
            ehMinhaPropriaMensagem = meuCpf.isNotEmpty && remetenteCpf == meuCpf;
            souDestinatarioReal = false;
          }
        }
      } else if (mensagem.conversaId.startsWith('grupo_')) {
        ehMinhaPropriaMensagem = meuCpf.isNotEmpty && remetenteCpf == meuCpf;
        souDestinatarioReal = meuCpf.isNotEmpty && !ehMinhaPropriaMensagem;
      } else {
        ehMinhaPropriaMensagem = meuCpf.isNotEmpty && remetenteCpf == meuCpf;
        final outroCpfConv = ChatRepositorioSqlite.extrairOutroCpf(
          mensagem.conversaId,
          remetenteCpf,
        );
        souDestinatarioReal = meuCpf.isNotEmpty &&
            !ehMinhaPropriaMensagem &&
            ((destCpf.isNotEmpty && destCpf == meuCpf) ||
                (outroCpfConv.isNotEmpty && outroCpfConv == meuCpf));
      }

      final bool souApenasRetransmissor = !souDestinatarioReal;

      final usuarioEstaOlhandoConversa = !souApenasRetransmissor &&
          souDestinatarioReal &&
          idConversaAtiva != null &&
          idConversaAtiva.isNotEmpty &&
          idConversaAtiva == mensagem.conversaId;

      if (ehMinhaPropriaMensagem) {
        final statusAtualLocal = jaExisteLocal
            ? (msgsExistentes.first['status_envio'] as String? ?? 'enviada')
            : 'enviada';
        mensagem = mensagem.copyWith(
          enviadaPorMim: true,
          statusEnvio: statusAtualLocal == 'pendente' ? 'enviada' : statusAtualLocal,
        );
      } else {
        mensagem = mensagem.copyWith(
          enviadaPorMim: false,
          statusEnvio: usuarioEstaOlhandoConversa ? 'lida' : 'recebida',
          lida: usuarioEstaOlhandoConversa,
          entregue: souDestinatarioReal ? true : mensagem.entregue,
        );
        if (usuarioEstaOlhandoConversa) {
          NotificacaoAndroidService.cancelarNotificacaoConversa(mensagem.conversaId);
        }
      }

      await salvarMensagemCallback(
        mensagem,
        originadaDaRede: true,
        obterCpfLogadoLocal: obterCpfLogadoLocal,
        aoNotificar: aoNotificar,
      );

      if (!ehMinhaPropriaMensagem && souDestinatarioReal && !souApenasRetransmissor) {
        final leitorIdEnvio = (ehConversaLoja && esteDispositivoOperaComoEstaLoja)
            ? 'loja_$lojaIdConv'
            : meuCpf;
        if (usuarioEstaOlhandoConversa) {
          ChatSincronizacaoService.despacharConfirmacaoLida(
              mensagem.conversaId, leitorIdEnvio);
        } else {
          ChatSincronizacaoService.despacharConfirmacaoEntrega(
              mensagem.id, mensagem.conversaId);

          final deveNotificar =
              await deveNotificarConversa(mensagem.conversaId);
          if (emitirAlertaSonoro && deveNotificar) {
            SomService.tocarBipPadrao();
          }
          if (deveNotificar) {
            MensagemChat msgParaNotificar = mensagem;
            if (CriptografiaService.ehTextoCifrado(mensagem.texto)) {
              msgParaNotificar = await ChatE2eeService.decifrarMensagemSeAplicavel(
                mensagem,
                cpfVisualizador: meuCpf,
              );
            }
            await NotificacaoAndroidService.exibirNotificacaoMensagem(msgParaNotificar);
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[ChatProcessadorRedeService] Erro ao processar mensagem recebida da rede: $e');
    }
  }
}
