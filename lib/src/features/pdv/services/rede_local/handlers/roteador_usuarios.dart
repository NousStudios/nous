import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

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
      if (conta == null) {
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
    if (path == '/api/usuario' && request.method == 'POST') {
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
        if (contaExistente != null &&
            contaExistente.foto.isNotEmpty &&
            ImagemService.existe(contaExistente.foto) &&
            (usuario.foto.isEmpty || !ImagemService.existe(usuario.foto))) {
          usuario = usuario.copyWith(foto: contaExistente.foto);
        }

        await ContasNousService.salvar(usuario);

        if (usuario.foto.isNotEmpty && ImagemService.existe(usuario.foto)) {
          servidor.pdvProvider?.sincronizarFotoUsuarioEmClientes(
            usuario.cpf,
            usuario.foto,
          );
        }

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
      final contas = await ContasNousService.carregarTodas();
      final contasValidas = contas.where((c) {
        final cpfLimpo = c.cpf.replaceAll(RegExp(r'\D'), '');
        return cpfLimpo.length == 11 && c.nome.toLowerCase() != 'blackview';
      }).toList();

      ServidorRedeLocal.responderJson(request, {
        'sucesso': true,
        'usuarios': contasValidas.map((c) => c.toJson()).toList(),
      });
      return true;
    }

    // 4. Sincronização em massa de contas de usuários (POST)
    if (path == '/api/usuarios' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final lista = (dados['usuarios'] as List<dynamic>?) ?? [];
        for (final item in lista) {
          if (item is Map<String, dynamic>) {
            final u = UsuarioNous.fromJson(item);
            final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
            if (cpfLimpo.length == 11 && u.nome.toLowerCase() != 'blackview') {
              final existente = await ContasNousService.buscarPorCpf(u.cpf);
              if (existente == null) {
                await ContasNousService.salvar(u);
              } else {
                final mesclada = existente.copyWith(
                  nome: (existente.nome.isEmpty ||
                          existente.nome.toLowerCase() == 'blackview')
                      ? u.nome
                      : existente.nome,
                  nomeDeUsuario: existente.nomeDeUsuario.isEmpty
                      ? u.nomeDeUsuario
                      : existente.nomeDeUsuario,
                  apelido:
                      existente.apelido.isEmpty ? u.apelido : existente.apelido,
                  foto: existente.foto.isEmpty ? u.foto : existente.foto,
                  emails: {...existente.emails, ...u.emails}.toList(),
                );
                await ContasNousService.salvar(mesclada);
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
              );
              await LojasService.salvarLojaIndividual(lojaConsolidada);
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
          if (cpfServidor == cpf) {
            await servidor.pdvProvider?.entrarComCpf(cpf);
          } else if (cpfServidor.isNotEmpty) {
            await servidor.pdvProvider?.entrarComCpf(cpfServidor);
          }

          final referenciasLocais =
              await LojasService.carregarReferencias(cpf);
          final referenciasValidas = <ReferenciaLoja>[];
          final lojasDoServidor = <Map<String, dynamic>>[];
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
            if (!lojasDoServidor.any((m) => m['id'] == lp.id)) {
              lojasDoServidor.add(
                LojasService.sanitizarCaminhosImagens(lp).toJson(),
              );
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

    return false;
  }
}
