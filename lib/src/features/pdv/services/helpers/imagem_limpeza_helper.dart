import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/services/helpers/imagem_caminhos_helper.dart';

/// Helper responsável pelo cálculo de uso de disco, limpeza de arquivos
/// temporários/LRU e remoção segura de mídias remotas órfãs.
class ImagemLimpezaHelper {
  ImagemLimpezaHelper._();

  /// Calcula o tamanho total somado de todas as pastas de mídias e anexos do aplicativo.
  static Future<int> obterTamanhoTotalCacheBytes() async {
    var totalBytes = 0;
    final pastas = ImagemCaminhosHelper.obterDiretoriosPossiveisSync();
    for (final dir in pastas) {
      try {
        if (!await dir.exists()) continue;
        await for (final entidade
            in dir.list(recursive: false, followLinks: false)) {
          if (entidade is File) {
            try {
              totalBytes += await entidade.length();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    return totalBytes;
  }

  /// Limpa arquivos temporários antigos e realiza limpeza LRU quando excede a cota.
  static Future<int> limparArquivosTemporariosExpirados({
    required Duration idadeMaxima,
    required int limiteTotalBytes,
  }) async {
    var bytesLiberados = 0;
    try {
      final base = await ImagemCaminhosHelper.obterDiretorioBase();
      final pastaTemp = Directory('${base.path}/temp');
      final agora = DateTime.now();

      if (await pastaTemp.exists()) {
        await for (final entidade in pastaTemp.list()) {
          if (entidade is File) {
            try {
              final stat = await entidade.stat();
              if (agora.difference(stat.modified) > idadeMaxima) {
                final len = await entidade.length();
                await entidade.delete();
                bytesLiberados += len;
              }
            } catch (_) {}
          }
        }
      }

      final tamanhoAtual = await obterTamanhoTotalCacheBytes();
      if (tamanhoAtual > limiteTotalBytes) {
        final arquivosRemotos = <File>[];
        final pastas = ImagemCaminhosHelper.obterDiretoriosPossiveisSync();
        for (final dir in pastas) {
          if (!await dir.exists()) continue;
          await for (final entidade in dir.list()) {
            if (entidade is File &&
                p.basename(entidade.path).startsWith('remota_')) {
              arquivosRemotos.add(entidade);
            }
          }
        }

        arquivosRemotos.sort((a, b) {
          try {
            return a.lastModifiedSync().compareTo(b.lastModifiedSync());
          } catch (_) {
            return 0;
          }
        });

        var tamanhoRestante = tamanhoAtual;
        for (final arq in arquivosRemotos) {
          if (tamanhoRestante <= limiteTotalBytes) break;
          try {
            final len = await arq.length();
            await arq.delete();
            bytesLiberados += len;
            tamanhoRestante -= len;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return bytesLiberados;
  }

  /// Remove com segurança arquivos `remota_*` órfãos (não referenciados no SQLite
  /// e com mais de 24h desde a última modificação).
  static Future<int> limparMidiasRemotasOrfas() async {
    var removidos = 0;
    try {
      final db = await BancoDadosService.db;
      final lojasRows = await db.query('lojas', columns: ['id', 'dados_json']);
      final contasRows =
          await db.query('contas_usuarios', columns: ['cpf', 'dados_json']);
      if (lojasRows.isEmpty && contasRows.isEmpty) return 0;

      final buffer = StringBuffer();
      for (final r in lojasRows) {
        buffer.writeln(r['dados_json'] ?? '');
      }
      for (final r in contasRows) {
        buffer.writeln(r['dados_json'] ?? '');
      }

      final nomesProtegidos = <String>{};
      void registrarCaminhoProtegido(String caminhoBruto) {
        final limpo = caminhoBruto.trim();
        if (limpo.isEmpty) return;
        final norm = limpo.replaceAll('\\', '/');
        final base = p.basename(norm);
        if (base.isNotEmpty) nomesProtegidos.add(base);
        final ext = p.extension(norm).replaceAll('.', '').toLowerCase();
        final extFinal =
            ImagemCaminhosHelper.extensoesImagem.contains(ext) ? ext : 'jpg';
        nomesProtegidos.add(
          ImagemCaminhosHelper.gerarNomeRemotoDeterministico(limpo, extFinal),
        );
        nomesProtegidos.add(
          ImagemCaminhosHelper.gerarNomeRemotoDeterministico(norm, extFinal),
        );
      }

      for (final tabela in const [
        'mensagens_chat',
        'conversas_chat',
        'pedidos',
        'movimentos_estoque',
        'pagamentos_funcionarios',
        'convites',
        'publicacoes_sociais',
        'stories_sociais',
      ]) {
        try {
          final rows = await db.query(tabela);
          for (final r in rows) {
            buffer.writeln(r.values.join(' '));
            for (final v in r.values) {
              if (v is String &&
                  (v.contains('/') || v.contains('\\') || v.contains('.'))) {
                for (final match in RegExp(
                  r'[\w\-./\\]+\.(?:jpg|jpeg|png|webp|gif|mp4|mp3|pdf)',
                  caseSensitive: false,
                ).allMatches(v)) {
                  registrarCaminhoProtegido(match.group(0)!);
                }
              }
            }
          }
        } catch (_) {}
      }

      final tudoNoBanco = buffer.toString();
      if (tudoNoBanco.isEmpty) return 0;

      final base = await ImagemCaminhosHelper.obterDiretorioBase();
      final limiteIdade = DateTime.now().subtract(const Duration(hours: 24));
      for (final sub in const ['imagens', 'anexos']) {
        final pasta = Directory('${base.path}/$sub');
        if (!await pasta.exists()) continue;
        await for (final entidade
            in pasta.list(recursive: true, followLinks: false)) {
          if (entidade is! File) continue;
          final nome = p.basename(entidade.path);
          if (!nome.startsWith('remota_')) continue;
          if (nomesProtegidos.contains(nome) || tudoNoBanco.contains(nome)) {
            continue;
          }
          try {
            final mod = await entidade.lastModified();
            if (mod.isBefore(limiteIdade)) {
              await entidade.delete();
              removidos++;
            }
          } catch (_) {}
        }
      }

      if (removidos > 0) {
        debugPrint(
          '[ImagemService] Limpeza de mídias órfãs removeu $removidos arquivo(s) remota_* sem referência.',
        );
      }
    } catch (_) {}
    return removidos;
  }
}
