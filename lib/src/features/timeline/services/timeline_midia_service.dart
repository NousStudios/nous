import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';

/// Serviço responsável por importação, cache síncrono em memória, download
/// com autocura e limpeza de mídias expiradas da Timeline.
class TimelineMidiaService {
  TimelineMidiaService._();

  static final Map<String, String> _cacheCaminhosMidia = {};
  static final Map<String, Future<String?>> _downloadsEmAndamento = {};

  /// Importa um arquivo local para a pasta soberana do Nous.
  /// Imagens menores que 1.5 MB são salvas diretamente para evitar travamento na UI.
  static Future<MidiaPublicacao?> importarMidiaLocal(
    String caminhoOrigem, {
    String nomeArquivo = '',
  }) async {
    final arquivo = File(caminhoOrigem);
    if (!arquivo.existsSync()) return null;

    final ext = p.extension(caminhoOrigem).toLowerCase();
    final ehImagem =
        ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp';

    if (ehImagem) {
      final bytesBrutos = await arquivo.readAsBytes();
      final bytesParaSalvar = bytesBrutos.lengthInBytes > 1500 * 1024
          ? await ImagemService.otimizarBytesImagem(bytesBrutos)
          : bytesBrutos;
      final extLimpa = ext.replaceAll('.', '');
      final nomeFinal =
          '${gerarIdUnico()}.${extLimpa.isNotEmpty ? extLimpa : "jpg"}';
      final caminhoSalvo = await ImagemService.salvarBytesImagemLocal(
        bytesParaSalvar,
        extensaoOriginal: extLimpa.isNotEmpty ? extLimpa : 'jpg',
        nomeSugerido: nomeFinal,
      );
      if (caminhoSalvo != null) {
        _cacheCaminhosMidia[caminhoSalvo] = caminhoSalvo;
        return MidiaPublicacao(
          caminhoRelativo: caminhoSalvo,
          nomeArquivo: nomeArquivo.isNotEmpty
              ? nomeArquivo
              : p.basename(caminhoOrigem),
          mimeTipo: extLimpa.isNotEmpty ? extLimpa : 'jpg',
          tamanhoBytes: bytesParaSalvar.length,
        );
      }
    }

    final dirBase = await getApplicationSupportDirectory();
    final pastaMidias =
        Directory(p.join(dirBase.path, 'Nous', 'timeline_midias'));
    if (!pastaMidias.existsSync()) {
      await pastaMidias.create(recursive: true);
    }

    final nomeFinal = '${gerarIdUnico()}$ext';
    final destino = File(p.join(pastaMidias.path, nomeFinal));
    await arquivo.copy(destino.path);

    final bytes = await destino.length();
    final rel = p.join('timeline_midias', nomeFinal);
    _cacheCaminhosMidia[rel] = destino.path;

    return MidiaPublicacao(
      caminhoRelativo: rel,
      nomeArquivo: nomeArquivo.isNotEmpty ? nomeArquivo : p.basename(caminhoOrigem),
      mimeTipo: ext.replaceAll('.', ''),
      tamanhoBytes: bytes,
    );
  }

  static String? resolverCaminhoMidiaSync(String caminho) {
    if (caminho.isEmpty) return null;
    final emCache = _cacheCaminhosMidia[caminho];
    if (emCache != null && File(emCache).existsSync()) {
      return emCache;
    }
    if (File(caminho).existsSync()) {
      _cacheCaminhosMidia[caminho] = caminho;
      return caminho;
    }
    final resolvidoImg = ImagemService.resolverCaminhoExistente(caminho);
    if (resolvidoImg != null && File(resolvidoImg).existsSync()) {
      _cacheCaminhosMidia[caminho] = resolvidoImg;
      return resolvidoImg;
    }
    return null;
  }

  static Future<String?> resolverCaminhoMidia(String caminho) async {
    if (caminho.isEmpty) return null;
    final sync = resolverCaminhoMidiaSync(caminho);
    if (sync != null) return sync;

    final emVoo = _downloadsEmAndamento[caminho];
    if (emVoo != null) return emVoo;

    final futuro = _resolverOuBaixarMidiaInterno(caminho);
    _downloadsEmAndamento[caminho] = futuro;
    try {
      return await futuro;
    } finally {
      _downloadsEmAndamento.remove(caminho);
    }
  }

  static Future<String?> _resolverOuBaixarMidiaInterno(String caminho) async {
    try {
      final dirBase = await getApplicationSupportDirectory();
      final candidato = p.join(dirBase.path, 'Nous', caminho);
      if (File(candidato).existsSync()) {
        _cacheCaminhosMidia[caminho] = candidato;
        return candidato;
      }
    } catch (_) {}

    if (ClienteRedeLocal().conectado) {
      try {
        final baixado = await ClienteRedeLocal()
            .baixarImagemRemota(caminho)
            .timeout(const Duration(seconds: 5));
        if (baixado.isNotEmpty && File(baixado).existsSync()) {
          _cacheCaminhosMidia[caminho] = baixado;
          return baixado;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<List<MidiaPublicacao>> sincronizarMidiasParaServidor(
    List<MidiaPublicacao> midias,
  ) async {
    if (!ClienteRedeLocal().conectado || midias.isEmpty) return midias;
    return Future.wait(midias.map((m) async {
      final ehImg = m.mimeTipo == 'jpg' ||
          m.mimeTipo == 'jpeg' ||
          m.mimeTipo == 'png' ||
          m.mimeTipo == 'webp';
      if (ehImg) {
        final local = await resolverCaminhoMidia(m.caminhoRelativo);
        if (local != null) {
          try {
            final remoto = await ClienteRedeLocal().enviarUploadImagem(local);
            if (remoto.isNotEmpty) {
              return m.copyWith(caminhoRelativo: remoto);
            }
          } catch (_) {}
        }
      } else {
        final local = await resolverCaminhoMidia(m.caminhoRelativo);
        if (local != null) {
          try {
            final remoto = await ClienteRedeLocal().enviarUploadAnexo(local);
            if (remoto.isNotEmpty) {
              return m.copyWith(caminhoRelativo: remoto);
            }
          } catch (_) {}
        }
      }
      return m;
    }));
  }

  /// Baixa a mídia da publicação quando permitido pelo autor.
  static Future<String?> baixarMidia(MidiaPublicacao midia) async {
    final caminhoReal = await resolverCaminhoMidia(midia.caminhoRelativo);
    if (caminhoReal == null) return null;
    final origem = File(caminhoReal);
    if (!origem.existsSync()) return null;

    final nomeSugerido = midia.nomeArquivo.isNotEmpty
        ? midia.nomeArquivo
        : p.basename(caminhoReal);

    String? destino;
    try {
      final local = await getSaveLocation(suggestedName: nomeSugerido);
      if (local != null) destino = local.path;
    } catch (_) {}

    if (destino == null) {
      Directory? dirDestino;
      if (Platform.isAndroid) {
        dirDestino = Directory('/storage/emulated/0/Download');
        if (!dirDestino.existsSync()) {
          dirDestino = await getExternalStorageDirectory();
        }
      }
      dirDestino ??= await getApplicationDocumentsDirectory();
      final pasta = Directory(p.join(dirDestino.path, 'Nous_Downloads'));
      if (!pasta.existsSync()) await pasta.create(recursive: true);
      destino = p.join(pasta.path, nomeSugerido);
    }

    await origem.copy(destino);
    return destino;
  }

  /// Remove arquivos de mídia cacheados de stories expirados há >24h de terceiros
  /// (mantém integralmente os stories do próprio usuário para o Calendário/Arquivo).
  static Future<int> limparMidiasStoriesExpiradosDeTerceiros(
    String meuCpf,
  ) async {
    final meuCpfNorm = TimelineRepositorioSqlite.normalizarCpf(meuCpf);
    if (meuCpfNorm.isEmpty) return 0;

    final db = await TimelineRepositorioSqlite.obterDb();
    final rows = await db.query('stories_sociais');
    final agora = DateTime.now();
    var removidos = 0;

    for (final r in rows) {
      try {
        final dec = jsonDecode(r['dados_json'] as String? ?? '{}');
        if (dec is! Map<String, dynamic>) continue;
        final story = StorySocial.fromJson(dec);
        final autorNorm =
            TimelineRepositorioSqlite.normalizarCpf(story.autorCpf);
        if (autorNorm == meuCpfNorm) continue;
        if (story.ehDestaquePermanente) continue;

        final expirouHaTempo = story.expiraEm != null &&
            agora.difference(story.expiraEm!).inHours >= 24;
        if (!expirouHaTempo && !story.excluido) continue;

        if (story.caminhoMidia.isNotEmpty) {
          final caminhoLocal = resolverCaminhoMidiaSync(story.caminhoMidia);
          if (caminhoLocal != null) {
            final f = File(caminhoLocal);
            if (f.existsSync()) {
              await f.delete();
              _cacheCaminhosMidia.remove(story.caminhoMidia);
              removidos++;
            }
          }
        }
      } catch (_) {}
    }
    return removidos;
  }
}
