import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Serviço responsável pelo gerenciamento de mídias, anexos e resumos de mensagens
class ChatMediaService {
  ChatMediaService._();

  /// Converte qualquer mensagem em resumo textual legível para a lista de conversas
  static String gerarResumoMensagem(MensagemChat msg) {
    if (msg.tipo == 'imagem') {
      return msg.texto.isNotEmpty ? '📷 ${msg.texto}' : '📷 Foto';
    } else if (msg.tipo == 'arquivo') {
      return msg.texto.isNotEmpty
          ? '📎 ${msg.texto}'
          : '📎 ${msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : "Arquivo"}';
    } else if (msg.tipo == 'audio') {
      return msg.texto.isNotEmpty ? '🎤 ${msg.texto}' : '🎤 Mensagem de Voz';
    } else if (msg.tipo == 'comanda') {
      return msg.texto.isNotEmpty ? '🧾 ${msg.texto}' : '🧾 Comanda de Pedido';
    }
    return msg.texto;
  }

  /// Salva uma cópia permanente do arquivo anexo no diretório seguro de dados do aplicativo
  static Future<String?> salvarArquivoAnexo(String caminhoOriginal) async {
    try {
      final arquivoOriginal = File(caminhoOriginal);
      if (!await arquivoOriginal.exists()) return null;
      final base = await ImagemService.obterDiretorioBase();
      final pasta = Directory('${base.path}/anexos_chat');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }
      final nome = p.basename(caminhoOriginal);
      final idUnico = DateTime.now().millisecondsSinceEpoch;
      final destino = File('${pasta.path}/${idUnico}_$nome');
      await arquivoOriginal.copy(destino.path);
      return destino.path;
    } catch (e) {
      debugPrint('[ChatMediaService] Erro ao salvar anexo de arquivo: $e');
      return null;
    }
  }

  /// Limite máximo seguro de bytes embutidos em Base64 no WebSocket (64 KB).
  /// Arquivos maiores devem transitar via streaming HTTP binário para não sobrecarregar o socket.
  static const int limiteBytesBase64Ws = 64 * 1024;

  /// Lê os bytes de um anexo leve para envio direto pela malha local (até 64 KB).
  /// Retorna null para arquivos maiores, delegando ao pipeline de upload binário HTTP em background.
  static Future<String?> obterBytesBase64ParaEnvio(String caminhoAnexo) async {
    if (caminhoAnexo.isEmpty) return null;
    final caminhoResolvido = ImagemService.resolverCaminhoExistente(caminhoAnexo);
    if (caminhoResolvido != null && File(caminhoResolvido).existsSync()) {
      try {
        final arquivo = File(caminhoResolvido);
        final tamanho = arquivo.lengthSync();
        if (tamanho > 0 && tamanho <= limiteBytesBase64Ws) {
          final bytes = await arquivo.readAsBytes();
          return base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('[ChatMediaService] Erro ao ler bytes do anexo leve: $e');
      }
    }
    return null;
  }

  /// Salva bytes de anexo recebido via rede local no diretório seguro de anexos
  static Future<String?> salvarBytesAnexo(Uint8List bytes, {String? nomeSugerido}) async {
    try {
      if (bytes.isEmpty) return null;
      final base = await ImagemService.obterDiretorioBase();
      final pasta = Directory('${base.path}/anexos_chat');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }
      final nome = (nomeSugerido != null && nomeSugerido.trim().isNotEmpty)
          ? p.basename(nomeSugerido)
          : 'anexo_${DateTime.now().millisecondsSinceEpoch}.dat';
      final idUnico = DateTime.now().millisecondsSinceEpoch;
      final destino = File('${pasta.path}/${idUnico}_$nome');
      await destino.writeAsBytes(bytes);
      return destino.path;
    } catch (e) {
      debugPrint('[ChatMediaService] Erro ao salvar bytes de anexo: $e');
      return null;
    }
  }
}
