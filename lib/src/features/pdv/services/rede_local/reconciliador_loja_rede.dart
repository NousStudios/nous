import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/mesclador_entidades_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/sincronizador_midias_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';

/// Especialista em reconciliação mútua, mesclagem e sincronização de dados e mídias
/// de lojas entre o cliente de rede local e o servidor balcão.
class ReconciliadorLojaRede {
  final TransferenciaArquivosRede _transferencia;
  final SincronizadorMidiasRede _sincronizadorMidias;

  ReconciliadorLojaRede({TransferenciaArquivosRede? transferencia})
      : _transferencia = transferencia ?? TransferenciaArquivosRede(),
        _sincronizadorMidias = SincronizadorMidiasRede(
          transferencia: transferencia ?? TransferenciaArquivosRede(),
        );

  /// Envia a loja curada via HTTP POST para a API do servidor balcão
  Future<bool> enviarLojaCuradaParaServidor({
    required String? ipServidor,
    required int? portaServidor,
    required Loja lojaCurada,
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/loja/atualizar',
        ),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(lojaCurada.toJson()));
      final response = await request.close();
      final ok = response.statusCode == HttpStatus.ok;
      debugPrint(
        '[ReconciliadorLojaRede] Cura da loja enviada com sucesso ao servidor: $ok (HTTP ${response.statusCode})',
      );
      return ok;
    } catch (e) {
      debugPrint(
        '[ReconciliadorLojaRede] Erro ao enviar cura da loja ao servidor: $e',
      );
      return false;
    }
  }

  /// Prepara uma loja convertendo todos os caminhos locais de arquivos para caminhos no servidor balcão
  Future<Loja> prepararLojaComUploadsParaServidor({
    required String? ipServidor,
    required int? portaServidor,
    required Loja loja,
  }) async {
    Loja lojaParaEnvio = loja;

    Future<String> garantirUpload(String caminho) async {
      return await _transferencia.enviarUploadImagemParaServidor(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        caminhoLocal: caminho,
      );
    }

    Future<String> garantirUploadAnexo(String caminho, String pasta) async {
      return await _transferencia.enviarUploadAnexoParaServidor(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        caminhoLocal: caminho,
        subpasta: pasta,
      );
    }

    if (lojaParaEnvio.logo.isNotEmpty &&
        !ImagemService.ehAsset(lojaParaEnvio.logo)) {
      final logoNoServidor = await garantirUpload(lojaParaEnvio.logo);
      if (logoNoServidor != lojaParaEnvio.logo) {
        lojaParaEnvio = lojaParaEnvio.copyWith(logo: logoNoServidor);
      }
    }

    final categoriasAjustadas = <CategoriaLoja>[];
    for (final cat in lojaParaEnvio.categoriasLoja) {
      if (cat.foto.isNotEmpty && !ImagemService.ehAsset(cat.foto)) {
        final fotoNoServidor = await garantirUpload(cat.foto);
        categoriasAjustadas.add(cat.copyWith(foto: fotoNoServidor));
      } else {
        categoriasAjustadas.add(cat);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(categoriasLoja: categoriasAjustadas);

    final itensAjustados = <ItemLoja>[];
    for (final it in lojaParaEnvio.itensLoja) {
      final imgsAjustadas = <String>[];
      for (final img in it.imagens) {
        if (img.isNotEmpty && !ImagemService.ehAsset(img)) {
          imgsAjustadas.add(await garantirUpload(img));
        } else {
          imgsAjustadas.add(img);
        }
      }
      itensAjustados.add(it.copyWith(imagens: imgsAjustadas));
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(itensLoja: itensAjustados);

    final clientesAjustados = <Cliente>[];
    for (final c in lojaParaEnvio.clientesLoja) {
      if (c.foto.isNotEmpty && !ImagemService.ehAsset(c.foto)) {
        final fotoServidor = await garantirUpload(c.foto);
        clientesAjustados.add(c.copyWith(foto: fotoServidor));
      } else {
        clientesAjustados.add(c);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(clientesLoja: clientesAjustados);

    final fornecedoresAjustados = <Fornecedor>[];
    for (final f in lojaParaEnvio.fornecedoresLoja) {
      if (f.foto.isNotEmpty && !ImagemService.ehAsset(f.foto)) {
        final fotoServidor = await garantirUpload(f.foto);
        fornecedoresAjustados.add(f.copyWith(foto: fotoServidor));
      } else {
        fornecedoresAjustados.add(f);
      }
    }
    lojaParaEnvio =
        lojaParaEnvio.copyWith(fornecedoresLoja: fornecedoresAjustados);

    final galeriaAjustada = <String>[];
    for (final g in lojaParaEnvio.galeria) {
      if (g.isNotEmpty) {
        galeriaAjustada.add(await garantirUpload(g));
      } else {
        galeriaAjustada.add(g);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(galeria: galeriaAjustada);

    final musicasAjustadas = <String>[];
    for (final m in lojaParaEnvio.musicas) {
      if (m.isNotEmpty) {
        musicasAjustadas.add(
          await garantirUploadAnexo(m, 'musicas'),
        );
      } else {
        musicasAjustadas.add(m);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(musicas: musicasAjustadas);

    final audiosAjustados = <String>[];
    for (final a in lojaParaEnvio.arquivosAudio) {
      if (a.isNotEmpty) {
        audiosAjustados.add(
          await garantirUploadAnexo(a, 'arquivosAudio'),
        );
      } else {
        audiosAjustados.add(a);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(arquivosAudio: audiosAjustados);

    final videosAjustados = <String>[];
    for (final v in lojaParaEnvio.videos) {
      if (v.isNotEmpty) {
        videosAjustados.add(
          await garantirUploadAnexo(v, 'videos'),
        );
      } else {
        videosAjustados.add(v);
      }
    }
    lojaParaEnvio = lojaParaEnvio.copyWith(videos: videosAjustados);

    final arquivosAjustados = <String>[];
    for (final arq in lojaParaEnvio.arquivos) {
      if (arq.isNotEmpty) {
        arquivosAjustados.add(
          await garantirUploadAnexo(arq, 'arquivos'),
        );
      } else {
        arquivosAjustados.add(arq);
      }
    }
    return lojaParaEnvio.copyWith(arquivos: arquivosAjustados);
  }

  /// Realiza a reconciliação mútua e bidirecional de dados e imagens entre o Servidor e este Cliente
  Future<Loja> reconciliarLojaMutua({
    required String? ipServidor,
    required int? portaServidor,
    required Loja lojaRemota,
    required List<String> imagensAusentesNoServidor,
    PdvProvider? pdvProvider,
    Loja? lojaSincronizada,
  }) async {
    // 1. Carrega o estado da loja gravado localmente neste dispositivo
    Loja? lojaLocal = pdvProvider?.buscarPorId(lojaRemota.id);
    if (lojaLocal == null) {
      try {
        lojaLocal = await LojasService.carregarLojaPorId(lojaRemota.id);
      } catch (e) {
        debugPrint(
          '[ReconciliadorLojaRede] Erro ao carregar loja local para reconciliação: $e',
        );
      }
    }

    // Se este dispositivo nunca teve dados prévios desta loja, apenas baixa do servidor normalmente
    if (lojaLocal == null) {
      return await sincronizarImagensRemotas(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        lojaRemota: lojaRemota,
        pdvProvider: pdvProvider,
        lojaSincronizada: lojaSincronizada,
      );
    }

    debugPrint(
      '[ReconciliadorLojaRede] Iniciando reconciliação mútua. Servidor reportou ${imagensAusentesNoServidor.length} lacunas de imagem.',
    );

    var houveCuraNoServidor = false;
    Loja lojaParaServidor = lojaRemota;

    Future<String> enviarUpload(String local) async {
      return await _transferencia.enviarUploadImagemParaServidor(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        caminhoLocal: local,
      );
    }

    // A. Logo da Loja
    final precisaLogoNoServidor =
        imagensAusentesNoServidor.contains('logo') ||
            lojaRemota.logo.trim().isEmpty;
    if (precisaLogoNoServidor && lojaLocal.logo.trim().isNotEmpty) {
      final logoLocalResolvida =
          ImagemService.resolverCaminhoExistente(lojaLocal.logo);
      if (logoLocalResolvida != null && File(logoLocalResolvida).existsSync()) {
        final logoNoServidor = await enviarUpload(logoLocalResolvida);
        if (logoNoServidor.isNotEmpty && logoNoServidor != logoLocalResolvida) {
          lojaParaServidor = lojaParaServidor.copyWith(logo: logoNoServidor);
          houveCuraNoServidor = true;
          debugPrint(
            '[ReconciliadorLojaRede] Logo restaurada no servidor: $logoNoServidor',
          );
        }
      }
    }

    // B. Categorias da Loja
    final novasCategoriasServidor = <CategoriaLoja>[];
    for (final catRemota in lojaRemota.categoriasLoja) {
      final precisaFoto =
          imagensAusentesNoServidor.contains('categoria_${catRemota.id}') ||
              catRemota.foto.trim().isEmpty;
      if (precisaFoto) {
        CategoriaLoja? catLocal;
        for (final cl in lojaLocal.categoriasLoja) {
          if (cl.id == catRemota.id ||
              cl.nome.trim().toLowerCase() ==
                  catRemota.nome.trim().toLowerCase()) {
            catLocal = cl;
            break;
          }
        }
        if (catLocal != null && catLocal.foto.trim().isNotEmpty) {
          final fotoLocalResolvida =
              ImagemService.resolverCaminhoExistente(catLocal.foto);
          if (fotoLocalResolvida != null &&
              File(fotoLocalResolvida).existsSync()) {
            final fotoNoServidor = await enviarUpload(fotoLocalResolvida);
            if (fotoNoServidor.isNotEmpty &&
                fotoNoServidor != fotoLocalResolvida) {
              novasCategoriasServidor
                  .add(catRemota.copyWith(foto: fotoNoServidor));
              houveCuraNoServidor = true;
              debugPrint(
                '[ReconciliadorLojaRede] Foto da categoria "${catRemota.nome}" restaurada no servidor: $fotoNoServidor',
              );
              continue;
            }
          }
        }
      }
      novasCategoriasServidor.add(catRemota);
    }

    final idsCats = novasCategoriasServidor.map((c) => c.id).toSet();
    final nomesCats = novasCategoriasServidor
        .map((c) => c.nome.trim().toLowerCase())
        .toSet();

    for (final catLocal in lojaLocal.categoriasLoja) {
      final id = catLocal.id;
      final nome = catLocal.nome.trim().toLowerCase();
      if (!idsCats.contains(id) && !nomesCats.contains(nome)) {
        String fotoServidor = '';
        if (catLocal.foto.trim().isNotEmpty) {
          final fotoResolvida =
              ImagemService.resolverCaminhoExistente(catLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            fotoServidor = await enviarUpload(fotoResolvida);
          }
        }
        final catAdicionada = catLocal.copyWith(foto: fotoServidor);
        novasCategoriasServidor.add(catAdicionada);
        idsCats.add(id);
        nomesCats.add(nome);
        houveCuraNoServidor = true;
        debugPrint(
          '[ReconciliadorLojaRede] Categoria "${catLocal.nome}" restaurada no servidor',
        );
      }
    }
    lojaParaServidor =
        lojaParaServidor.copyWith(categoriasLoja: novasCategoriasServidor);

    // C. Itens da Loja
    final novosItensServidor = <ItemLoja>[];
    for (final itemRemoto in lojaRemota.itensLoja) {
      final precisaImagens =
          imagensAusentesNoServidor.contains('item_${itemRemoto.id}') ||
              itemRemoto.imagens.isEmpty;
      if (precisaImagens) {
        ItemLoja? itemLocal;
        for (final il in lojaLocal.itensLoja) {
          if (il.id == itemRemoto.id ||
              il.nome.trim().toLowerCase() ==
                  itemRemoto.nome.trim().toLowerCase()) {
            itemLocal = il;
            break;
          }
        }
        if (itemLocal != null && itemLocal.imagens.isNotEmpty) {
          final novasImagensNoServidor = <String>[];
          for (final img in itemLocal.imagens) {
            final imgResolvida = ImagemService.resolverCaminhoExistente(img);
            if (imgResolvida != null && File(imgResolvida).existsSync()) {
              final imgServidor = await enviarUpload(imgResolvida);
              if (imgServidor.isNotEmpty && imgServidor != imgResolvida) {
                novasImagensNoServidor.add(imgServidor);
              }
            }
          }
          if (novasImagensNoServidor.isNotEmpty) {
            novosItensServidor.add(
              itemRemoto.copyWith(imagens: novasImagensNoServidor),
            );
            houveCuraNoServidor = true;
            debugPrint(
              '[ReconciliadorLojaRede] Imagens do produto "${itemRemoto.nome}" restauradas no servidor (${novasImagensNoServidor.length})',
            );
            continue;
          }
        }
      }
      novosItensServidor.add(itemRemoto);
    }

    final idsItens = novosItensServidor.map((i) => i.id).toSet();
    final nomesItens =
        novosItensServidor.map((i) => i.nome.trim().toLowerCase()).toSet();

    for (final itemLocal in lojaLocal.itensLoja) {
      final id = itemLocal.id;
      final nome = itemLocal.nome.trim().toLowerCase();
      if (!idsItens.contains(id) && !nomesItens.contains(nome)) {
        final novasImagensServidor = <String>[];
        for (final img in itemLocal.imagens) {
          final imgResolvida = ImagemService.resolverCaminhoExistente(img);
          if (imgResolvida != null && File(imgResolvida).existsSync()) {
            final imgServidor = await enviarUpload(imgResolvida);
            if (imgServidor.isNotEmpty && imgServidor != imgResolvida) {
              novasImagensServidor.add(imgServidor);
            }
          }
        }
        final itemAdicionado =
            itemLocal.copyWith(imagens: novasImagensServidor);
        novosItensServidor.add(itemAdicionado);
        idsItens.add(id);
        nomesItens.add(nome);
        houveCuraNoServidor = true;
        debugPrint(
          '[ReconciliadorLojaRede] Produto "${itemLocal.nome}" restaurado no servidor',
        );
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(itensLoja: novosItensServidor);

    // D. Clientes da Loja
    final novosClientesServidor = <Cliente>[];
    for (final cliRemoto in lojaRemota.clientesLoja) {
      final precisaFoto =
          imagensAusentesNoServidor.contains('cliente_${cliRemoto.id}') ||
              cliRemoto.foto.trim().isEmpty;
      if (precisaFoto) {
        Cliente? cliLocal;
        for (final cl in lojaLocal.clientesLoja) {
          if (cl.id == cliRemoto.id ||
              (cl.cnpj.isNotEmpty && cl.cnpj == cliRemoto.cnpj)) {
            cliLocal = cl;
            break;
          }
        }
        if (cliLocal != null && cliLocal.foto.trim().isNotEmpty) {
          final fotoResolvida =
              ImagemService.resolverCaminhoExistente(cliLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            final fotoServidor = await enviarUpload(fotoResolvida);
            if (fotoServidor.isNotEmpty && fotoServidor != fotoResolvida) {
              novosClientesServidor
                  .add(cliRemoto.copyWith(foto: fotoServidor));
              houveCuraNoServidor = true;
              continue;
            }
          }
        }
      }
      novosClientesServidor.add(cliRemoto);
    }
    final idsClientes = novosClientesServidor.map((c) => c.id).toSet();
    for (final cLocal in lojaLocal.clientesLoja) {
      if (idsClientes.add(cLocal.id)) {
        novosClientesServidor.add(cLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor =
        lojaParaServidor.copyWith(clientesLoja: novosClientesServidor);

    // E. Fornecedores da Loja
    final novosFornecedoresServidor = <Fornecedor>[];
    for (final fornRemoto in lojaRemota.fornecedoresLoja) {
      final precisaFoto =
          imagensAusentesNoServidor.contains('fornecedor_${fornRemoto.id}') ||
              fornRemoto.foto.trim().isEmpty;
      if (precisaFoto) {
        Fornecedor? fornLocal;
        for (final fl in lojaLocal.fornecedoresLoja) {
          if (fl.id == fornRemoto.id ||
              (fl.cnpj.isNotEmpty && fl.cnpj == fornRemoto.cnpj)) {
            fornLocal = fl;
            break;
          }
        }
        if (fornLocal != null && fornLocal.foto.trim().isNotEmpty) {
          final fotoResolvida =
              ImagemService.resolverCaminhoExistente(fornLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            final fotoServidor = await enviarUpload(fotoResolvida);
            if (fotoServidor.isNotEmpty && fotoServidor != fotoResolvida) {
              novosFornecedoresServidor
                  .add(fornRemoto.copyWith(foto: fotoServidor));
              houveCuraNoServidor = true;
              continue;
            }
          }
        }
      }
      novosFornecedoresServidor.add(fornRemoto);
    }
    final idsFornecedores = novosFornecedoresServidor.map((f) => f.id).toSet();
    for (final fLocal in lojaLocal.fornecedoresLoja) {
      if (idsFornecedores.add(fLocal.id)) {
        novosFornecedoresServidor.add(fLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor =
        lojaParaServidor.copyWith(fornecedoresLoja: novosFornecedoresServidor);

    // F-P. Reconciliação e Mesclagem de Entidades de Negócio (Mesas, Auditoria, Pedidos, Turnos, Ponto, etc.)
    final resultadoEntidades = MescladorEntidadesRede.mesclarEntidades(
      lojaBase: lojaParaServidor,
      lojaLocal: lojaLocal,
    );
    lojaParaServidor = resultadoEntidades.loja;
    if (resultadoEntidades.houveCuraNoServidor) {
      houveCuraNoServidor = true;
    }

    // Se houve alguma cura ou restauração necessária no servidor, envia o estado curado ao balcão
    if (houveCuraNoServidor) {
      debugPrint(
        '[ReconciliadorLojaRede] Enviando cura consolidada da loja ao servidor balcão...',
      );
      await enviarLojaCuradaParaServidor(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        lojaCurada: lojaParaServidor,
      );
    }

    // Finalmente, este cliente sincroniza e baixa todas as imagens do servidor para si mesmo
    return await sincronizarImagensRemotas(
      ipServidor: ipServidor,
      portaServidor: portaServidor,
      lojaRemota: lojaParaServidor,
      pdvProvider: pdvProvider,
      lojaSincronizada: lojaSincronizada,
    );
  }

  /// Baixa imagens remotas do servidor que não existem no armazenamento local
  /// e regrava os caminhos locais atualizados para que fiquem 100% visíveis no dispositivo móvel.
  Future<Loja> sincronizarImagensRemotas({
    required String? ipServidor,
    required int? portaServidor,
    required Loja lojaRemota,
    PdvProvider? pdvProvider,
    Loja? lojaSincronizada,
  }) async {
    return _sincronizadorMidias.sincronizarImagensRemotas(
      ipServidor: ipServidor,
      portaServidor: portaServidor,
      lojaRemota: lojaRemota,
      pdvProvider: pdvProvider,
      lojaSincronizada: lojaSincronizada,
    );
  }
}

