import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Serviço especialista na aplicação e orquestração de Criptografia de Ponta a Ponta (E2EE)
/// para mensagens privadas e soberanas do Chat Nous, englobando textos e mídias/anexos (AES-256-GCM).
class ChatE2eeService {
  ChatE2eeService._();

  /// Verifica se uma conversa é elegível para criptografia E2EE (conversa direta entre usuários)
  static bool ehConversaElegivelE2ee(String conversaId) {
    return conversaId.startsWith('user_') && conversaId.contains('_user_');
  }

  /// Cifra o texto e prepara a cifragem de mídias/anexos antes de salvar no SQLite e transmitir pela rede.
  static Future<MensagemChat> cifrarMensagemSeAplicavel(MensagemChat mensagem) async {
    // Apenas mensagens de conversas diretas entre pessoas físicas são cifradas com E2EE
    if (!ehConversaElegivelE2ee(mensagem.conversaId)) {
      return mensagem;
    }

    if (CriptografiaService.ehTextoCifrado(mensagem.texto)) {
      return mensagem;
    }

    final meuCpf = ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
    var destCpf = ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);

    if (destCpf.length != 11 || destCpf == meuCpf) {
      destCpf = ChatRepositorioSqlite.extrairOutroCpf(mensagem.conversaId, meuCpf);
    }

    if (meuCpf.length != 11 || destCpf.length != 11) {
      return mensagem;
    }

    try {
      final contaDest = await ContasNousService.buscarPorCpf(destCpf);
      var chaveDest = contaDest?.chaveTrocaPublica ?? '';
      if (chaveDest.isEmpty) {
        chaveDest = await CriptografiaService.obterOuGerarChaveTroca(destCpf);
      }

      if (chaveDest.isEmpty) {
        return mensagem;
      }

      // Se a mensagem contiver anexo físico, cifra os bytes do anexo com AES-GCM 256-bit
      String textoParaCifrar = mensagem.texto;
      if (mensagem.caminhoAnexo.isNotEmpty) {
        try {
          final caminhoFisico = ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo);
          if (caminhoFisico != null && File(caminhoFisico).existsSync()) {
            final arq = File(caminhoFisico);
            final bytesOriginais = await arq.readAsBytes();
            if (bytesOriginais.isNotEmpty) {
              final chaveMidia = await CriptografiaService.gerarChaveSimetricaMidia();
              final chaveHex = await CriptografiaService.exportarChaveHex(chaveMidia);
              final bytesCifrados = await CriptografiaService.cifrarBytesComChave(
                bytesOriginais,
                chaveMidia,
              );

              // Salva a cópia cifrada .enc para trânsito pela rede
              final arqEnc = File('$caminhoFisico.enc');
              await arqEnc.writeAsBytes(bytesCifrados);

              final envelopeJson = {
                't': mensagem.texto,
                'midia': {
                  'chave': chaveHex,
                  'nome': mensagem.nomeAnexo,
                  'cifrada': true,
                },
              };
              textoParaCifrar = jsonEncode(envelopeJson);
            }
          }
        } catch (e) {
          debugPrint('[ChatE2eeService] Erro ao cifrar bytes de anexo para E2EE: $e');
        }
      }

      final textoCifrado = await CriptografiaService.cifrarTextoPara(
        texto: textoParaCifrar,
        meuCpf: meuCpf,
        chavePublicaDestinatarioHex: chaveDest,
      );

      return mensagem.copyWith(texto: textoCifrado);
    } catch (_) {
      return mensagem;
    }
  }

  /// Decifra o texto e o arquivo anexo de uma mensagem se ela contiver o envelope E2EE.
  static Future<MensagemChat> decifrarMensagemSeAplicavel(
    MensagemChat mensagem, {
    required String cpfVisualizador,
  }) async {
    if (!CriptografiaService.ehTextoCifrado(mensagem.texto)) {
      return mensagem;
    }

    final visNorm = ChatRepositorioSqlite.normalizarCpf(cpfVisualizador);
    if (visNorm.length != 11) {
      return mensagem.copyWith(texto: '[Mensagem Cifrada Protegida]');
    }

    final remNorm = ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
    final destNorm = ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);

    // Identifica com quem a troca Diffie-Hellman deve ser calculada
    final String outroCpf;
    if (remNorm == visNorm) {
      outroCpf = destNorm.length == 11
          ? destNorm
          : ChatRepositorioSqlite.extrairOutroCpf(mensagem.conversaId, visNorm);
    } else {
      outroCpf = remNorm.length == 11
          ? remNorm
          : ChatRepositorioSqlite.extrairOutroCpf(mensagem.conversaId, visNorm);
    }

    if (outroCpf.length != 11) {
      return mensagem.copyWith(texto: '[Mensagem Cifrada Protegida]');
    }

    try {
      final contaOutro = await ContasNousService.buscarPorCpf(outroCpf);
      var chaveOutro = contaOutro?.chaveTrocaPublica ?? '';
      if (chaveOutro.isEmpty) {
        chaveOutro = await CriptografiaService.obterOuGerarChaveTroca(outroCpf);
      }

      if (chaveOutro.isEmpty) {
        return mensagem.copyWith(texto: '[Mensagem Cifrada Protegida]');
      }

      final textoDecifradoBruto = await CriptografiaService.decifrarTextoDe(
        textoCifrado: mensagem.texto,
        meuCpf: visNorm,
        chavePublicaRemetenteHex: chaveOutro,
      );

      var textoReal = textoDecifradoBruto;
      String? novoCaminhoAnexo;

      if (textoDecifradoBruto.startsWith('{') && textoDecifradoBruto.endsWith('}')) {
        try {
          final map = jsonDecode(textoDecifradoBruto);
          if (map is Map<String, dynamic> && map.containsKey('t')) {
            textoReal = map['t']?.toString() ?? '';
            final midia = map['midia'] as Map<String, dynamic>?;
            if (midia != null && midia['cifrada'] == true && mensagem.caminhoAnexo.isNotEmpty) {
              final chaveHex = midia['chave']?.toString() ?? '';
              novoCaminhoAnexo = await decifrarArquivoAnexoSeNecessario(
                mensagemId: mensagem.id,
                caminhoAnexo: mensagem.caminhoAnexo,
                chaveHex: chaveHex,
              );
            }
          }
        } catch (_) {}
      }

      return mensagem.copyWith(
        texto: textoReal,
        caminhoAnexo: novoCaminhoAnexo ?? mensagem.caminhoAnexo,
      );
    } catch (_) {
      return mensagem.copyWith(texto: '[Mensagem Cifrada Protegida]');
    }
  }

  /// Decifra o arquivo anexo no disco usando a chave simétrica AES-GCM transportada no envelope E2EE.
  static Future<String?> decifrarArquivoAnexoSeNecessario({
    required String mensagemId,
    required String caminhoAnexo,
    required String chaveHex,
  }) async {
    if (caminhoAnexo.isEmpty || chaveHex.isEmpty) return null;
    try {
      final caminhoFisico = ImagemService.resolverCaminhoExistente(caminhoAnexo);
      if (caminhoFisico == null || !File(caminhoFisico).existsSync()) {
        return null;
      }
      final arquivo = File(caminhoFisico);
      final ehEnc = caminhoFisico.toLowerCase().endsWith('.enc');

      if (!ehEnc) {
        // Verifica se os primeiros bytes já são de uma mídia clara válida
        final bytes = await arquivo.readAsBytes();
        if (bytes.length >= 4) {
          final b0 = bytes[0];
          final b1 = bytes[1];
          final ehJpeg = b0 == 0xFF && b1 == 0xD8;
          final ehPng = b0 == 0x89 && b1 == 0x50;
          final ehWebp = b0 == 0x52 && b1 == 0x49;
          final ehMp3 = b0 == 0x49 && b1 == 0x44;
          if (ehJpeg || ehPng || ehWebp || ehMp3) {
            return caminhoFisico; // Arquivo já se encontra decifrado
          }
        }
      }

      // Decifra os bytes do arquivo
      final chaveSimetrica = CriptografiaService.importarChaveHex(chaveHex);
      final bytesCifrados = await arquivo.readAsBytes();
      final bytesClaros = await CriptografiaService.decifrarBytesComChave(
        bytesCifrados,
        chaveSimetrica,
      );

      if (bytesClaros != null && bytesClaros.isNotEmpty) {
        final String caminhoDestino;
        if (ehEnc) {
          caminhoDestino = caminhoFisico.substring(0, caminhoFisico.length - 4);
        } else {
          caminhoDestino = caminhoFisico;
        }

        await File(caminhoDestino).writeAsBytes(bytesClaros);

        // Atualiza o caminho no SQLite caso tenha mudado
        if (caminhoDestino != caminhoFisico) {
          final db = await ChatRepositorioSqlite.obterDb();
          await db.update(
            'mensagens_chat',
            {'caminho_anexo': caminhoDestino},
            where: 'id = ?',
            whereArgs: [mensagemId],
          );
          try {
            await arquivo.delete();
          } catch (_) {}
        }

        return caminhoDestino;
      }
    } catch (e) {
      debugPrint('[ChatE2eeService] Falha ao decifrar anexo físico: $e');
    }
    return null;
  }

  /// Decifra uma lista inteira de mensagens com cache de chave pública em lote
  static Future<List<MensagemChat>> decifrarListaMensagens(
    List<MensagemChat> mensagens, {
    required String cpfVisualizador,
  }) async {
    if (mensagens.isEmpty) return mensagens;

    final visNorm = ChatRepositorioSqlite.normalizarCpf(cpfVisualizador);
    if (visNorm.length != 11) {
      return mensagens.map((m) {
        if (CriptografiaService.ehTextoCifrado(m.texto)) {
          return m.copyWith(texto: '[Mensagem Cifrada Protegida]');
        }
        return m;
      }).toList();
    }

    final cacheChaves = <String, String>{};
    final resultado = <MensagemChat>[];

    for (final m in mensagens) {
      if (!CriptografiaService.ehTextoCifrado(m.texto)) {
        resultado.add(m);
        continue;
      }

      final remNorm = ChatRepositorioSqlite.normalizarCpf(m.remetenteId);
      final destNorm = ChatRepositorioSqlite.normalizarCpf(m.destinatarioId);

      final String outroCpf;
      if (remNorm == visNorm) {
        outroCpf = destNorm.length == 11
            ? destNorm
            : ChatRepositorioSqlite.extrairOutroCpf(m.conversaId, visNorm);
      } else {
        outroCpf = remNorm.length == 11
            ? remNorm
            : ChatRepositorioSqlite.extrairOutroCpf(m.conversaId, visNorm);
      }

      if (outroCpf.length != 11) {
        resultado.add(m.copyWith(texto: '[Mensagem Cifrada Protegida]'));
        continue;
      }

      var chaveOutro = cacheChaves[outroCpf];
      if (chaveOutro == null) {
        final contaOutro = await ContasNousService.buscarPorCpf(outroCpf);
        chaveOutro = contaOutro?.chaveTrocaPublica ?? '';
        if (chaveOutro.isEmpty) {
          chaveOutro = await CriptografiaService.obterOuGerarChaveTroca(outroCpf);
        }
        cacheChaves[outroCpf] = chaveOutro;
      }

      if (chaveOutro.isEmpty) {
        resultado.add(m.copyWith(texto: '[Mensagem Cifrada Protegida]'));
        continue;
      }

      final textoDecifradoBruto = await CriptografiaService.decifrarTextoDe(
        textoCifrado: m.texto,
        meuCpf: visNorm,
        chavePublicaRemetenteHex: chaveOutro,
      );

      var textoReal = textoDecifradoBruto;
      String? novoCaminhoAnexo;

      if (textoDecifradoBruto.startsWith('{') && textoDecifradoBruto.endsWith('}')) {
        try {
          final map = jsonDecode(textoDecifradoBruto);
          if (map is Map<String, dynamic> && map.containsKey('t')) {
            textoReal = map['t']?.toString() ?? '';
            final midia = map['midia'] as Map<String, dynamic>?;
            if (midia != null && midia['cifrada'] == true && m.caminhoAnexo.isNotEmpty) {
              final chaveHex = midia['chave']?.toString() ?? '';
              novoCaminhoAnexo = await decifrarArquivoAnexoSeNecessario(
                mensagemId: m.id,
                caminhoAnexo: m.caminhoAnexo,
                chaveHex: chaveHex,
              );
            }
          }
        } catch (_) {}
      }

      resultado.add(m.copyWith(
        texto: textoReal,
        caminhoAnexo: novoCaminhoAnexo ?? m.caminhoAnexo,
      ));
    }

    return resultado;
  }
}
