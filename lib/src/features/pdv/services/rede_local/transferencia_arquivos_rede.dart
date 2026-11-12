import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador de transferência de arquivos (imagens, fotos, áudios e anexos)
/// via HTTP multipart/binário entre o terminal cliente e o servidor do balcão na rede local.
class TransferenciaArquivosRede {
  static final TransferenciaArquivosRede _instancia =
      TransferenciaArquivosRede._interno();
  factory TransferenciaArquivosRede() => _instancia;
  TransferenciaArquivosRede._interno();

  final Map<String, String> _mapaUploadsRealizados = {};

  /// Registra ou recupera caminho de upload já efetuado
  Map<String, String> get mapaUploadsRealizados => _mapaUploadsRealizados;

  /// Faz o upload de um arquivo de imagem local para o servidor balcão e retorna o caminho registrado no servidor
  Future<String> enviarUploadImagemParaServidor({
    required String? ipServidor,
    required int? portaServidor,
    required String caminhoLocal,
  }) async {
    if (ipServidor == null || portaServidor == null) return caminhoLocal;
    final limpo = caminhoLocal.trim();
    if (limpo.isEmpty) return '';

    for (final entry in _mapaUploadsRealizados.entries) {
      if (entry.value == limpo) {
        return entry.key;
      }
    }

    final resolvido =
        ImagemService.resolverCaminhoExistente(limpo) ?? limpo;
    final arquivo = File(resolvido);
    if (!arquivo.existsSync() || arquivo.lengthSync() == 0) return limpo;

    try {
      final nome = p.basename(limpo);
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/upload_imagem',
          parametros: {'nome': nome},
        ),
      );
      req.headers.contentType = ContentType.binary;
      await req.addStream(arquivo.openRead());
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final caminhoServidor = json['caminho'] as String?;
        if (caminhoServidor != null && caminhoServidor.isNotEmpty) {
          _mapaUploadsRealizados[caminhoServidor] = limpo;
          debugPrint(
            '[TransferenciaArquivosRede] Imagem enviada com sucesso ao servidor: $caminhoServidor',
          );
          return caminhoServidor;
        }
      }
    } catch (e) {
      debugPrint(
        '[TransferenciaArquivosRede] Erro ao enviar imagem "$limpo" para o servidor: $e',
      );
    }
    return limpo;
  }

  /// Faz o upload de um anexo (música, documento, mídia) local para o servidor balcão
  Future<String> enviarUploadAnexoParaServidor({
    required String? ipServidor,
    required int? portaServidor,
    required String caminhoLocal,
    String subpasta = 'musicas',
  }) async {
    if (ipServidor == null || portaServidor == null) return caminhoLocal;
    final limpo = caminhoLocal.trim();
    if (limpo.isEmpty) return '';

    for (final entry in _mapaUploadsRealizados.entries) {
      if (entry.value == limpo) {
        return entry.key;
      }
    }

    final resolvido = ImagemService.resolverCaminhoExistente(limpo) ?? limpo;
    final arquivo = File(resolvido);
    if (!arquivo.existsSync() || arquivo.lengthSync() == 0) return limpo;

    try {
      final nome = p.basename(limpo);
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 30);
      final req = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/upload_anexo',
          parametros: {'nome': nome, 'pasta': subpasta},
        ),
      );
      req.headers.contentType = ContentType.binary;
      await req.addStream(arquivo.openRead());
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final caminhoServidor = json['caminho'] as String?;
        if (caminhoServidor != null && caminhoServidor.isNotEmpty) {
          _mapaUploadsRealizados[caminhoServidor] = limpo;
          debugPrint(
            '[TransferenciaArquivosRede] Anexo ($subpasta) enviado com sucesso ao servidor: $caminhoServidor',
          );
          return caminhoServidor;
        }
      }
    } catch (e) {
      debugPrint(
        '[TransferenciaArquivosRede] Erro ao enviar anexo "$limpo" para o servidor: $e',
      );
    }
    return limpo;
  }

  /// Baixa uma imagem remota do balcão e salva no armazenamento local
  Future<String> baixarImagemRemota({
    required String caminhoRemoto,
    String? ipServidor,
    int? portaServidor,
    String? cpf,
    Future<void> Function(String cpf, String caminho)? onFotoUsuarioBaixada,
  }) async {
    String? ip = ipServidor;
    int? porta = portaServidor;

    if (ip == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        ip = prefs.getString('nous_ultimo_ip_balcao');
        porta = prefs.getInt('nous_ultima_porta_balcao') ??
            ServidorRedeLocal.portaPadraoHttp;
      } catch (_) {}
    }

    if (ip == null || porta == null) return caminhoRemoto;
    final caminhoLimpo = caminhoRemoto.trim();
    if (caminhoLimpo.isEmpty && (cpf == null || cpf.trim().isEmpty)) return '';

    final resolvido = ImagemService.resolverCaminhoExistente(caminhoLimpo);
    if (resolvido != null && File(resolvido).existsSync()) {
      return resolvido;
    }

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaImagens = Directory('${dirBase.path}/imagens');
      if (!await pastaImagens.exists()) {
        await pastaImagens.create(recursive: true);
      }

      final caminhoNormalizado = caminhoLimpo.replaceAll('\\', '/');
      final ext =
          p.extension(caminhoNormalizado).replaceAll('.', '').toLowerCase();
      final extensaoFinal =
          ImagemService.extensoesImagem.contains(ext) ? ext : 'jpg';
      final nomeBase = p.basename(caminhoNormalizado);
      final nomeHash =
          'remota_${(caminhoLimpo.isNotEmpty ? caminhoLimpo : (cpf ?? '')).hashCode.abs()}.$extensaoFinal';

      final arquivoHash = File('${pastaImagens.path}/$nomeHash');
      if (arquivoHash.existsSync() && arquivoHash.lengthSync() > 0) {
        if (cpf != null && cpf.trim().isNotEmpty) {
          ResolvedorFotoChat.instancia
              .registrarFoto(cpf.trim(), arquivoHash.path);
        }
        return arquivoHash.path;
      }
      if (nomeBase.isNotEmpty &&
          !nomeBase.contains('/') &&
          !nomeBase.contains('\\')) {
        final arquivoNome = File('${pastaImagens.path}/$nomeBase');
        if (arquivoNome.existsSync() && arquivoNome.lengthSync() > 0) {
          if (cpf != null && cpf.trim().isNotEmpty) {
            ResolvedorFotoChat.instancia
                .registrarFoto(cpf.trim(), arquivoNome.path);
          }
          return arquivoNome.path;
        }
      }

      final clienteHttp =
          HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final queryParams = <String, String>{};
      if (caminhoLimpo.isNotEmpty) queryParams['caminho'] = caminhoLimpo;
      if (cpf != null && cpf.trim().isNotEmpty) queryParams['cpf'] = cpf.trim();

      final uri = Uri.http('$ip:$porta', '/api/imagem', queryParams);
      final req = await clienteHttp.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final bytes =
            await resp.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await arquivoHash.writeAsBytes(bytes);
        if (nomeBase.isNotEmpty &&
            nomeBase != nomeHash &&
            !nomeBase.contains('/') &&
            !nomeBase.contains('\\')) {
          final arquivoNome = File('${pastaImagens.path}/$nomeBase');
          try {
            await arquivoNome.writeAsBytes(bytes);
          } catch (_) {}
        }

        if (await arquivoHash.exists() && arquivoHash.lengthSync() > 0) {
          final pathFinal = arquivoHash.path;
          ResolvedorFotoChat.instancia.registrarFoto(caminhoLimpo, pathFinal);
          if (cpf != null && cpf.trim().isNotEmpty) {
            final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
            ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, pathFinal);
            if (onFotoUsuarioBaixada != null) {
              try {
                await onFotoUsuarioBaixada(cpfLimpo, pathFinal);
              } catch (_) {}
            }
          }
          ChatService.notificarAlteracao();
          return pathFinal;
        }
      }
    } catch (e) {
      debugPrint('[TransferenciaArquivosRede] Erro ao baixar imagem remota: $e');
    }

    return caminhoLimpo;
  }

  /// Baixa um arquivo de áudio/música remoto do balcão e salva no armazenamento local
  Future<String> baixarAudioRemoto({
    required String caminhoRemoto,
    required String? ipServidor,
    required int? portaServidor,
  }) async {
    if (ipServidor == null || portaServidor == null) return caminhoRemoto;
    final caminhoLimpo = caminhoRemoto.trim();
    if (caminhoLimpo.isEmpty) return '';

    final caminhoExistente =
        ImagemService.resolverCaminhoExistente(caminhoLimpo);
    if (caminhoExistente != null) {
      return caminhoExistente;
    }

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaAudios = Directory('${dirBase.path}/audios');
      if (!await pastaAudios.exists()) {
        await pastaAudios.create(recursive: true);
      }

      final ext = caminhoLimpo.split('.').last.toLowerCase();
      final extensaoFinal = (ext.isNotEmpty && ext.length <= 5) ? ext : 'mp3';
      final nomeArquivoLocal =
          'remoto_audio_${caminhoLimpo.hashCode.abs()}.$extensaoFinal';
      final arquivoLocal = File('${pastaAudios.path}/$nomeArquivoLocal');

      if (arquivoLocal.existsSync() && arquivoLocal.lengthSync() > 0) {
        return arquivoLocal.path;
      }

      final clienteHttp =
          HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: ipServidor,
        porta: portaServidor,
        caminho: '/api/audio',
        parametros: {'caminho': caminhoLimpo},
      );
      final req = await clienteHttp.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final sink = arquivoLocal.openWrite();
        await resp.pipe(sink);

        if (await arquivoLocal.exists() && arquivoLocal.lengthSync() > 0) {
          return arquivoLocal.path;
        } else {
          try {
            if (await arquivoLocal.exists()) await arquivoLocal.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[TransferenciaArquivosRede] Erro ao baixar áudio remoto: $e');
    }

    return caminhoLimpo;
  }
}
