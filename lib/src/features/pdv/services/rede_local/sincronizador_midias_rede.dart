import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';

/// Especialista em baixar imagens e mídias remotas do servidor para o dispositivo local.
class SincronizadorMidiasRede {
  final TransferenciaArquivosRede _transferencia;

  SincronizadorMidiasRede({TransferenciaArquivosRede? transferencia})
      : _transferencia = transferencia ?? TransferenciaArquivosRede();

  /// Baixa imagens remotas do servidor que não existem no armazenamento local
  /// e regrava os caminhos locais atualizados para que fiquem 100% visíveis no dispositivo móvel.
  Future<Loja> sincronizarImagensRemotas({
    required String? ipServidor,
    required int? portaServidor,
    required Loja lojaRemota,
    PdvProvider? pdvProvider,
    Loja? lojaSincronizada,
  }) async {
    if (ipServidor == null || portaServidor == null) return lojaRemota;

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaImagens = Directory('${dirBase.path}/imagens');
      if (!await pastaImagens.exists()) {
        await pastaImagens.create(recursive: true);
      }

      final clienteHttp =
          HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final Map<String, String> mapaCaminhos = {};

      Future<String> resolverCaminhoImagem(
        String? caminhoRemoto, {
        String? itemId,
        String? categoriaId,
        String? cpf,
      }) async {
        if (caminhoRemoto == null || caminhoRemoto.trim().isEmpty) return '';
        final caminhoLimpo = caminhoRemoto.trim();
        if (ImagemService.ehAsset(caminhoLimpo)) return caminhoLimpo;

        if (File(caminhoLimpo).existsSync()) {
          return caminhoLimpo;
        }

        if (_transferencia.mapaUploadsRealizados.containsKey(caminhoLimpo)) {
          final original =
              _transferencia.mapaUploadsRealizados[caminhoLimpo]!;
          if (File(original).existsSync()) {
            return original;
          }
        }

        if (mapaCaminhos.containsKey(caminhoLimpo)) {
          return mapaCaminhos[caminhoLimpo]!;
        }

        final localExistente =
            ImagemService.resolverCaminhoExistente(caminhoLimpo);
        if (localExistente != null && File(localExistente).existsSync()) {
          mapaCaminhos[caminhoLimpo] = localExistente;
          return localExistente;
        }

        final ext = caminhoLimpo.split('.').last.toLowerCase();
        final extensaoFinal =
            ImagemService.extensoesImagem.contains(ext) ? ext : 'jpg';
        final nomeArquivoLocal =
            'remota_${caminhoLimpo.hashCode.abs()}.$extensaoFinal';
        final arquivoLocal = File('${pastaImagens.path}/$nomeArquivoLocal');

        if (arquivoLocal.existsSync() && arquivoLocal.lengthSync() > 0) {
          mapaCaminhos[caminhoLimpo] = arquivoLocal.path;
          return arquivoLocal.path;
        }

        try {
          final queryParams = <String, String>{
            'caminho': caminhoLimpo,
          };
          if (itemId != null && itemId.isNotEmpty) {
            queryParams['item_id'] = itemId;
          }
          if (categoriaId != null && categoriaId.isNotEmpty) {
            queryParams['categoria_id'] = categoriaId;
          }
          if (cpf != null && cpf.isNotEmpty) {
            queryParams['cpf'] = cpf;
          }

          final uri = Uri.http(
            '$ipServidor:$portaServidor',
            '/api/imagem',
            queryParams,
          );
          final req = await clienteHttp.getUrl(uri);
          final resp = await req.close();

          if (resp.statusCode == HttpStatus.ok) {
            final bytes = await resp.fold<List<int>>(
              [],
              (acc, chunk) => acc..addAll(chunk),
            );
            await arquivoLocal.writeAsBytes(bytes);

            if (await arquivoLocal.exists() && arquivoLocal.lengthSync() > 0) {
              mapaCaminhos[caminhoLimpo] = arquivoLocal.path;
              return arquivoLocal.path;
            }
          }
        } catch (e) {
          debugPrint(
            '[SincronizadorMidiasRede] Erro ao baixar imagem "$caminhoLimpo": $e',
          );
        }

        if (localExistente != null && File(localExistente).existsSync()) {
          return localExistente;
        }

        return caminhoLimpo;
      }

      // 1. Logo da loja
      String novaLogo = lojaRemota.logo;
      if (novaLogo.isNotEmpty) {
        novaLogo = await resolverCaminhoImagem(novaLogo);
      }

      // 2. Itens da loja
      final novosItens = <ItemLoja>[];
      for (final item in lojaRemota.itensLoja) {
        if (item.imagens.isNotEmpty) {
          final novasImgs = <String>[];
          for (final img in item.imagens) {
            novasImgs.add(await resolverCaminhoImagem(img, itemId: item.id));
          }
          novosItens.add(item.copyWith(imagens: novasImgs));
        } else {
          novosItens.add(item);
        }
      }

      // 3. Categorias da loja
      final novasCategorias = <CategoriaLoja>[];
      for (final cat in lojaRemota.categoriasLoja) {
        if (cat.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(cat.foto, categoriaId: cat.id);
          novasCategorias.add(cat.copyWith(foto: local));
        } else {
          novasCategorias.add(cat);
        }
      }

      // 4. Clientes da loja
      final novosClientes = <Cliente>[];
      for (final cli in lojaRemota.clientesLoja) {
        if (cli.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(cli.foto, cpf: cli.cnpj);
          novosClientes.add(cli.copyWith(foto: local));
        } else {
          novosClientes.add(cli);
        }
      }

      // 5. Fornecedores da loja
      final novosFornecedores = <Fornecedor>[];
      for (final forn in lojaRemota.fornecedoresLoja) {
        if (forn.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(forn.foto, cpf: forn.cnpj);
          novosFornecedores.add(forn.copyWith(foto: local));
        } else {
          novosFornecedores.add(forn);
        }
      }

      // 6. Galeria da loja
      final novaGaleria = <String>[];
      for (final g in lojaRemota.galeria) {
        novaGaleria.add(await resolverCaminhoImagem(g));
      }

      // 7. Músicas da loja
      final novasMusicas = <String>[];
      for (final m in lojaRemota.musicas) {
        final local = ImagemService.resolverCaminhoExistente(m);
        if (local != null) {
          novasMusicas.add(local);
        } else {
          novasMusicas.add(m);
          _transferencia
              .baixarAudioRemoto(
            caminhoRemoto: m,
            ipServidor: ipServidor,
            portaServidor: portaServidor,
          )
              .then((baixado) {
            if (baixado != m &&
                pdvProvider != null &&
                lojaSincronizada != null) {
              final lojaAtual =
                  pdvProvider.buscarPorId(lojaSincronizada.id);
              if (lojaAtual != null) {
                final musicasAtualizadas = lojaAtual.musicas
                    .map((x) => x == m ? baixado : x)
                    .toList();
                pdvProvider.adicionarOuAtualizarLoja(
                  lojaAtual.copyWith(musicas: musicasAtualizadas),
                );
              }
            }
          });
        }
      }

      // 8. Arquivos de áudio da loja
      final novosAudios = <String>[];
      for (final a in lojaRemota.arquivosAudio) {
        final local = ImagemService.resolverCaminhoExistente(a);
        if (local != null) {
          novosAudios.add(local);
        } else {
          novosAudios.add(a);
          _transferencia
              .baixarAudioRemoto(
            caminhoRemoto: a,
            ipServidor: ipServidor,
            portaServidor: portaServidor,
          )
              .then((baixado) {
            if (baixado != a &&
                pdvProvider != null &&
                lojaSincronizada != null) {
              final lojaAtual =
                  pdvProvider.buscarPorId(lojaSincronizada.id);
              if (lojaAtual != null) {
                final audiosAtualizados = lojaAtual.arquivosAudio
                    .map((x) => x == a ? baixado : x)
                    .toList();
                pdvProvider.adicionarOuAtualizarLoja(
                  lojaAtual.copyWith(arquivosAudio: audiosAtualizados),
                );
              }
            }
          });
        }
      }

      return lojaRemota.copyWith(
        logo: novaLogo,
        itensLoja: novosItens,
        categoriasLoja: novasCategorias,
        clientesLoja: novosClientes,
        fornecedoresLoja: novosFornecedores,
        galeria: novaGaleria,
        musicas: novasMusicas,
        arquivosAudio: novosAudios,
      );
    } catch (e) {
      debugPrint('[SincronizadorMidiasRede] Erro ao sincronizar imagens: $e');
      return lojaRemota;
    }
  }
}
