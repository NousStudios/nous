import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';

/// Especialista em reconciliação mútua, mesclagem e sincronização de dados e mídias
/// de lojas entre o cliente de rede local e o servidor balcão.
class ReconciliadorLojaRede {
  final TransferenciaArquivosRede _transferencia;

  ReconciliadorLojaRede({TransferenciaArquivosRede? transferencia})
      : _transferencia = transferencia ?? TransferenciaArquivosRede();

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
        Uri.parse('http://$ipServidor:$portaServidor/api/loja/atualizar'),
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

    // F. Mesas com mesclagem aditiva granular de itens de comanda (blindagem contra concorrência)
    final mapaMesas = <String, MesaLoja>{
      for (final m in lojaParaServidor.mesas) m.id: m,
    };
    for (final mLocal in lojaLocal.mesas) {
      final mExistente = mapaMesas[mLocal.id];
      if (mExistente == null) {
        mapaMesas[mLocal.id] = mLocal;
        houveCuraNoServidor = true;
      } else if (mExistente.status == StatusMesa.ocupada &&
          mLocal.status == StatusMesa.ocupada) {
        // Ambas as pontas estão ocupadas na mesma sessão: mesclar itens de comanda por ID do item,
        // sem ressuscitar mesas já liberadas/fechadas no balcão.
        final aberturaMinima = mExistente.dataHoraAbertura
            ?.subtract(const Duration(seconds: 5));
        final mapaItens = <String, ItemComandaMesa>{
          for (final it in mExistente.itens) it.id: it,
        };
        var itensAdicionados = false;
        for (final itLocal in mLocal.itens) {
          if (aberturaMinima != null &&
              itLocal.dataHora.isBefore(aberturaMinima)) {
            continue;
          }
          if (!mapaItens.containsKey(itLocal.id)) {
            mapaItens[itLocal.id] = itLocal;
            itensAdicionados = true;
          }
        }
        if (itensAdicionados) {
          final todosItens = mapaItens.values.toList()
            ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
          final clienteEfetivo = mExistente.clienteNome.isNotEmpty
              ? mExistente.clienteNome
              : mLocal.clienteNome;
          final obsEfetiva = mExistente.observacoes.isNotEmpty
              ? mExistente.observacoes
              : mLocal.observacoes;

          mapaMesas[mLocal.id] = mExistente.copyWith(
            itens: todosItens,
            status: StatusMesa.ocupada,
            clienteNome: clienteEfetivo,
            observacoes: obsEfetiva,
          );
          houveCuraNoServidor = true;
        }
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(mesas: mapaMesas.values.toList());

    // G. Histórico de Auditoria (Ações) - Com janela de retenção de 2.000 itens para evitar OOM
    final acoesMescladas = List<RegistroAcao>.from(lojaParaServidor.acoes);
    final idsAcoes = acoesMescladas.map((a) => a.id).toSet();
    for (final aLocal in lojaLocal.acoes) {
      if (idsAcoes.add(aLocal.id)) {
        acoesMescladas.add(aLocal);
        houveCuraNoServidor = true;
      }
    }
    acoesMescladas.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final acoesLimitadas = acoesMescladas.length > 2000
        ? acoesMescladas.sublist(0, 2000)
        : acoesMescladas;
    lojaParaServidor = lojaParaServidor.copyWith(acoes: acoesLimitadas);

    // H. Pedidos, Movimentos de Estoque e Pagamentos - Indexação O(1)
    final mapaPedidos = <String, PedidoLoja>{
      for (final p in lojaParaServidor.pedidosLoja) p.id: p,
    };
    for (final pLocal in lojaLocal.pedidosLoja) {
      if (!mapaPedidos.containsKey(pLocal.id)) {
        mapaPedidos[pLocal.id] = pLocal;
        houveCuraNoServidor = true;
      } else {
        final existente = mapaPedidos[pLocal.id]!;
        final mesclado =
            ConsolidadorLojaLocal.mesclarDoisPedidos(existente, pLocal);
        if (mesclado != existente) {
          mapaPedidos[pLocal.id] = mesclado;
          if (mesclado.status != existente.status ||
              mesclado.quitado != existente.quitado ||
              mesclado.valorPago != existente.valorPago) {
            houveCuraNoServidor = true;
          }
        }
      }
    }
    final pedidosMesclados = mapaPedidos.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final movimentosMesclados =
        List<MovimentoEstoque>.from(lojaParaServidor.movimentosEstoque);
    final idsMovimentos = movimentosMesclados.map((m) => m.id).toSet();
    for (final mLocal in lojaLocal.movimentosEstoque) {
      if (idsMovimentos.add(mLocal.id)) {
        movimentosMesclados.add(mLocal);
        houveCuraNoServidor = true;
      }
    }
    movimentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosLimitados = movimentosMesclados.length > 2000
        ? movimentosMesclados.sublist(0, 2000)
        : movimentosMesclados;

    final pagamentosMesclados = List<PagamentoFuncionario>.from(
      lojaParaServidor.pagamentosFuncionarios,
    );
    final idsPagamentos = pagamentosMesclados.map((pg) => pg.id).toSet();
    for (final pgLocal in lojaLocal.pagamentosFuncionarios) {
      if (idsPagamentos.add(pgLocal.id)) {
        pagamentosMesclados.add(pgLocal);
        houveCuraNoServidor = true;
      }
    }
    pagamentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosLimitados = pagamentosMesclados.length > 1000
        ? pagamentosMesclados.sublist(0, 1000)
        : pagamentosMesclados;

    // I. Turnos de Caixa (Finanças e Fechamento) - Map O(1) com união de movimentações
    final mapaTurnos = <String, TurnoCaixa>{
      for (final t in lojaParaServidor.turnosCaixa) t.id: t,
    };
    for (final tLocal in lojaLocal.turnosCaixa) {
      final tExistente = mapaTurnos[tLocal.id];
      if (tExistente == null) {
        mapaTurnos[tLocal.id] = tLocal;
        houveCuraNoServidor = true;
      } else {
        final mesclado =
            ConsolidadorLojaLocal.mesclarDoisTurnosCaixa(tExistente, tLocal);
        if (mesclado.aberto != tExistente.aberto ||
            mesclado.movimentacoes.length != tExistente.movimentacoes.length) {
          mapaTurnos[tLocal.id] = mesclado;
          houveCuraNoServidor = true;
        }
      }
    }
    final turnosMesclados = mapaTurnos.values.toList()
      ..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

    // J. Pedidos Programados - O servidor balcão é soberano na lista ativa (evita ressuscitar excluídos),
    // preservando apenas ultimaDataGerado mais recente caso tenha sido gerado antes.
    final mapaProgramadosLocal = <String, PedidoProgramado>{
      for (final pp in lojaLocal.pedidosProgramados) pp.id: pp,
    };
    final programadosMesclados =
        lojaParaServidor.pedidosProgramados.map((ppRemoto) {
      final ppLocal = mapaProgramadosLocal[ppRemoto.id];
      if (ppLocal != null && ppLocal.ultimaDataGerado != null) {
        if (ppRemoto.ultimaDataGerado == null ||
            ppLocal.ultimaDataGerado!.isAfter(ppRemoto.ultimaDataGerado!)) {
          houveCuraNoServidor = true;
          return ppRemoto.copyWith(ultimaDataGerado: ppLocal.ultimaDataGerado);
        }
      }
      return ppRemoto;
    }).toList();

    // K. Cargos Personalizados - Set O(1)
    final cargosMesclados =
        List<CargoLoja>.from(lojaParaServidor.cargosPersonalizados);
    final idsCargos = cargosMesclados.map((c) => c.id).toSet();
    for (final cLocal in lojaLocal.cargosPersonalizados) {
      if (idsCargos.add(cLocal.id)) {
        cargosMesclados.add(cLocal);
        houveCuraNoServidor = true;
      }
    }

    lojaParaServidor = lojaParaServidor.copyWith(
      pedidosLoja: pedidosMesclados,
      movimentosEstoque: movimentosLimitados,
      pagamentosFuncionarios: pagamentosLimitados,
      turnosCaixa: turnosMesclados,
      pedidosProgramados: programadosMesclados,
      cargosPersonalizados: cargosMesclados,
    );

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
            '[ReconciliadorLojaRede] Erro ao baixar imagem "$caminhoLimpo": $e',
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
      debugPrint('[ReconciliadorLojaRede] Erro ao sincronizar imagens: $e');
      return lojaRemota;
    }
  }
}
