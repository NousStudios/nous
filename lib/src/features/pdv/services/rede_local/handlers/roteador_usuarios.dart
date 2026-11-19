import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Roteador responsável pelos endpoints REST de Identidade, Usuários e Perfis no Servidor Local.
class RoteadorUsuarios {
  RoteadorUsuarios._();

  static Future<bool> atender(
    HttpRequest request, {
    required ServidorRedeLocal servidor,
  }) async {
    final path = request.uri.path;

    // 1. Obter dados cadastrais da Identidade do Usuário por CPF
    if (path == '/api/usuario' && request.method == 'GET') {
      final cpfParam = request.uri.queryParameters['cpf'];
      if (cpfParam == null || cpfParam.trim().isEmpty) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'mensagem': 'CPF não informado'},
          statusCode: HttpStatus.badRequest,
        );
        return true;
      }

      var conta = await ContasNousService.buscarPorCpf(cpfParam.trim());
      if (conta == null &&
          !await ContasExcluidasService.estaExcluido(cpfParam.trim())) {
        final dadosAuto =
            await DadosLocaisService.buscarPorDocumento(cpfParam.trim());
        if (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty) {
          conta = UsuarioNous(
            cpf: cpfParam.trim(),
            nome: dadosAuto.nome.trim(),
            dataNascimento: dadosAuto.dataNascimento,
            foto: dadosAuto.foto,
          );
          await ContasNousService.salvar(conta);
          debugPrint(
            '[ServidorRedeLocal] Conta unificada e salva no balcão a partir de dados locais para CPF $cpfParam (${conta.nome})',
          );
        } else if (servidor.lojaAtiva != null) {
          final digitos = cpfParam.replaceAll(RegExp(r'\D'), '');
          final membro = servidor.lojaAtiva!.membros
              .where(
                (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == digitos,
              )
              .firstOrNull;
          if (membro != null && membro.nome.trim().isNotEmpty) {
            conta = UsuarioNous(
              cpf: cpfParam.trim(),
              nome: membro.nome.trim(),
              dataNascimento: '',
            );
            await ContasNousService.salvar(conta);
          }
        }
      }

      if (conta == null) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Usuário não encontrado'},
          statusCode: HttpStatus.notFound,
        );
        return true;
      }

      if (conta.foto.isNotEmpty) {
        final resolvida = ImagemService.resolverCaminhoExistente(conta.foto);
        if (resolvida == null) {
          conta = conta.copyWith(foto: '');
          await ContasNousService.salvar(conta);
        } else if (resolvida != conta.foto) {
          conta = conta.copyWith(foto: resolvida);
          await ContasNousService.salvar(conta);
        }
      }

      ServidorRedeLocal.responderJson(request, {
        'sucesso': true,
        'usuario': conta.toJson(),
      });
      return true;
    }

    // 2. Salvar ou atualizar Identidade do Usuário
    if ((path == '/api/usuario' || path == '/api/usuario/atualizar') &&
        request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        var usuario = UsuarioNous.fromJson(dados);

        if (usuario.foto.isNotEmpty) {
          final fotoResolvida =
              ImagemService.resolverCaminhoExistente(usuario.foto);
          if (fotoResolvida != null) {
            usuario = usuario.copyWith(foto: fotoResolvida);
          }
        }

        final contaExistente =
            await ContasNousService.buscarPorCpf(usuario.cpf);
        if (contaExistente != null) {
          final fotoLocalValida = contaExistente.foto.isNotEmpty &&
              ImagemService.existe(contaExistente.foto);
          final fotoRemotaValida =
              usuario.foto.isNotEmpty && ImagemService.existe(usuario.foto);
          usuario = contaExistente.mesclarCom(usuario, priorizarOutro: true);
          if (!fotoRemotaValida && fotoLocalValida) {
            usuario = usuario.copyWith(foto: contaExistente.foto);
          }
        }

        await ContasNousService.salvar(usuario);

        servidor.pdvProvider?.sincronizarDadosUsuarioEmLojas(usuario);

        servidor.authProvider?.atualizarContaNoCache(usuario);
        servidor.pdvProvider?.notificarMudanca();

        if (servidor.authProvider != null &&
            (servidor.authProvider!.contaAtual?.cpf == usuario.cpf ||
                servidor.authProvider!.cpf == usuario.cpf)) {
          await servidor.authProvider!.recarregarConta();
        }

        servidor.notificarTodos({
          'tipo': 'usuario_atualizado',
          'usuario': usuario.toJson(),
        });

        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': true, 'usuario': usuario.toJson()},
        );
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return true;
      }
    }

    // 3. Sincronização em massa de contas de usuários (GET)
    if (path == '/api/usuarios' && request.method == 'GET') {
      await ContasNousService.varrerECorrigirBanco();
      final excluidos = await ContasExcluidasService.carregarTodas();
      final contas = await ContasNousService.carregarTodas();
      final contasValidas = contas.where((c) {
        final cpfLimpo = c.cpf.replaceAll(RegExp(r'\D'), '');
        return cpfLimpo.length == 11 && c.nome.toLowerCase() != 'blackview';
      }).toList();

      ServidorRedeLocal.responderJson(request, {
        'sucesso': true,
        'usuarios': contasValidas.map((c) => c.toJson()).toList(),
        'excluidos': excluidos.map((e) => e.toJson()).toList(),
      });
      return true;
    }

    // 4. Sincronização em massa de contas de usuários (POST)
    if (path == '/api/usuarios' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final excluidosRecebidos = (dados['excluidos'] as List<dynamic>?) ?? [];
        var houveExclusao = false;
        for (final ex in excluidosRecebidos) {
          if (ex is Map<String, dynamic>) {
            await ContasExcluidasService.salvarRegistro(
              ContaExcluidaNous.fromMap(ex),
            );
            houveExclusao = true;
          }
        }
        if (houveExclusao) {
          await ContasNousService.varrerECorrigirBanco();
          await servidor.authProvider?.carregarCacheContas();
        }
        final lista = (dados['usuarios'] as List<dynamic>?) ?? [];
        for (final item in lista) {
          if (item is Map<String, dynamic>) {
            final u = UsuarioNous.fromJson(item);
            final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
            if (cpfLimpo.length == 11 && u.nome.toLowerCase() != 'blackview') {
              final existente = await ContasNousService.buscarPorCpf(u.cpf);
              if (existente == null) {
                await ContasNousService.salvar(u);
                servidor.pdvProvider?.sincronizarDadosUsuarioEmLojas(u);
              } else {
                var mesclada = existente.mesclarCom(u);
                if (existente.foto.isNotEmpty &&
                    ImagemService.existe(existente.foto)) {
                  mesclada = mesclada.copyWith(foto: existente.foto);
                }
                await ContasNousService.salvar(mesclada);
                servidor.pdvProvider?.sincronizarDadosUsuarioEmLojas(mesclada);
              }
            }
          }
        }
        ServidorRedeLocal.responderJson(request, {'sucesso': true});
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return true;
      }
    }

    // 5. Sincronização Pan-Dispositivo de Perfis e Lojas por CPF
    if (path == '/api/sincronizar_perfis_usuario' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final cpf =
            (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');

        if (cpf.isNotEmpty) {
          final referenciasRecebidas =
              dados['referencias'] as List<dynamic>? ?? [];
          final lojasRecebidas = dados['lojas'] as List<dynamic>? ?? [];

          for (final lJson in lojasRecebidas) {
            try {
              final loja = Loja.fromJson(lJson as Map<String, dynamic>);
              if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) {
                continue;
              }
              final lojaExistente =
                  await LojasService.carregarLojaPorId(loja.id);
              final lojaConsolidada =
                  LojasService.consolidarLojaComImagensLocais(
                loja,
                lojaExistente,
                manterItensAusentes: true,
              );
              await LojasService.salvarLojaIndividual(lojaConsolidada);
              if (servidor.pdvProvider != null) {
                await servidor.pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);
              }
              if (servidor.lojaAtiva?.id == lojaConsolidada.id) {
                servidor.lojaAtiva = lojaConsolidada;
                servidor.notificarLojaAtualizada(lojaConsolidada);
              }
              await _extrairContasNousDeLoja(lojaConsolidada);
            } catch (e) {
              debugPrint('[ServidorRedeLocal] Erro ao salvar loja recebida: $e');
            }
          }

          for (final rJson in referenciasRecebidas) {
            try {
              final ref =
                  ReferenciaLoja.fromJson(rJson as Map<String, dynamic>);
              if (LojasService.ehLojaHostFalsa(ref.lojaId)) {
                continue;
              }
              await LojasService.adicionarReferencia(cpf, ref);
            } catch (e) {
              debugPrint(
                '[ServidorRedeLocal] Erro ao salvar referência recebida: $e',
              );
            }
          }

          final cpfServidor =
              servidor.authProvider?.cpf.replaceAll(RegExp(r'\D'), '') ?? '';

          final referenciasLocais =
              await LojasService.carregarReferencias(cpf);
          final referenciasValidas = <ReferenciaLoja>[];
          final lojasDoServidor = <Map<String, dynamic>>[];
          final idsLojasColetadas = <String>{};

          for (final r in referenciasLocais) {
            final l = await LojasService.carregarLojaPorId(r.lojaId);
            if (l != null) {
              final cpfDonoDigitos =
                  l.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '');
              final ehMembro = l.membros.any(
                (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpf,
              );
              if (ehMembro || cpfDonoDigitos == cpf) {
                referenciasValidas.add(r);
                idsLojasColetadas.add(l.id);
                lojasDoServidor.add(
                  LojasService.sanitizarCaminhosImagens(l).toJson(),
                );
              } else {
                await LojasService.removerReferencia(cpf, r.lojaId);
              }
            } else {
              await LojasService.removerReferencia(cpf, r.lojaId);
            }
          }

          final lojasProprias = await LojasService.carregar(cpf);
          for (final lp in lojasProprias) {
            if (idsLojasColetadas.add(lp.id)) {
              lojasDoServidor.add(
                LojasService.sanitizarCaminhosImagens(lp).toJson(),
              );
            }
          }

          // Inclui lojas hospedadas no servidor onde o solicitante participa como membro
          final todasLojasServidor = <Loja>[
            ...?servidor.pdvProvider?.lojas,
            if (cpfServidor.isNotEmpty) ...await LojasService.carregar(cpfServidor),
          ];
          if (cpfServidor.isNotEmpty) {
            final refsServidor = await LojasService.carregarReferencias(cpfServidor);
            for (final ref in refsServidor) {
              final l = await LojasService.carregarLojaPorId(ref.lojaId);
              if (l != null && !todasLojasServidor.any((item) => item.id == l.id)) {
                todasLojasServidor.add(l);
              }
            }
          }
          for (final ls in todasLojasServidor) {
            if (LojasService.ehLojaHostFalsa(ls.id, ls.tags, ls.nome)) continue;
            await _extrairContasNousDeLoja(ls);
            final ehMembro = ls.membros.any(
              (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpf,
            );
            final ehDono = ls.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == cpf;
            if (ehMembro || ehDono) {
              if (idsLojasColetadas.add(ls.id)) {
                lojasDoServidor.add(
                  LojasService.sanitizarCaminhosImagens(ls).toJson(),
                );
                final novaRef = ReferenciaLoja(
                  lojaId: ls.id,
                  cpfDonoOriginal: ls.cpfDonoOriginal,
                );
                referenciasValidas.add(novaRef);
                await LojasService.adicionarReferencia(cpf, novaRef);
              }
            }
          }

          ServidorRedeLocal.responderJson(request, {
            'sucesso': true,
            'referencias':
                referenciasValidas.map((r) => r.toJson()).toList(),
            'lojas': lojasDoServidor,
          });
          return true;
        }

        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': 'CPF vazio'},
          statusCode: HttpStatus.badRequest,
        );
        return true;
      } catch (e) {
        debugPrint(
          '[ServidorRedeLocal] Erro em /api/sincronizar_perfis_usuario: $e',
        );
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    if (path == '/api/timeline/sincronizar' && request.method == 'POST') {
      try {
        final corpo = await utf8.decoder.bind(request).join();
        DateTime? desde;
        int offset = 0;
        if (corpo.trim().isNotEmpty) {
          final snapshotCliente = await decodificarJsonMapaSeguro(corpo);
          final rawDesde = snapshotCliente['desde'] as String?;
          if (rawDesde != null && rawDesde.isNotEmpty) {
            desde = DateTime.tryParse(rawDesde);
          }
          offset = (snapshotCliente['offset'] as num?)?.toInt() ?? 0;
          await TimelineService.mesclarSnapshotSocial(snapshotCliente);
        }
        final snapshotServidor = await TimelineService.exportarSnapshotSocial(
          desde: desde,
          offset: offset,
        );
        ServidorRedeLocal.responderJson(request, {
          'sucesso': true,
          'snapshot': snapshotServidor,
        });
        return true;
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro em /api/timeline/sincronizar: $e');
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    return false;
  }

  static Future<void> _extrairContasNousDeLoja(Loja loja) async {
    if (loja.id == 'loja_nous_coletiva') return;
    try {
      for (final m in loja.membros) {
        final mCpf = m.cpf.replaceAll(RegExp(r'\D'), '');
        final nomeLower = m.nome.trim().toLowerCase();
        if (mCpf.length == 11) {
          final existente = await ContasNousService.buscarPorCpf(mCpf);
          if (existente == null &&
              m.nome.trim().isNotEmpty &&
              nomeLower != 'blackview' &&
              nomeLower != 'celular' &&
              nomeLower != 'usuário nous' &&
              nomeLower != 'usuario nous') {
            await ContasNousService.salvar(
              UsuarioNous(
                cpf: mCpf,
                nome: m.nome.trim(),
                apelido: m.nome.trim(),
                dataNascimento: '',
              ),
            );
          }
        }
      }
      for (final c in loja.clientesLoja) {
        final cCpf = c.cnpj.replaceAll(RegExp(r'\D'), '');
        if (cCpf.length == 11) {
          final existente = await ContasNousService.buscarPorCpf(cCpf);
          if (existente == null &&
              c.nome.trim().isNotEmpty &&
              c.nome.toLowerCase() != 'blackview' &&
              c.nome.toLowerCase() != 'celular') {
            await ContasNousService.salvar(
              UsuarioNous(
                cpf: cCpf,
                nome: c.nome.trim(),
                apelido: c.nome.trim(),
                foto: c.foto,
                dataNascimento: '',
              ),
            );
          } else if (existente != null && existente.foto.isEmpty && c.foto.isNotEmpty) {
            await ContasNousService.salvar(existente.copyWith(foto: c.foto));
          }
        }
      }
    } catch (_) {}
  }
}
