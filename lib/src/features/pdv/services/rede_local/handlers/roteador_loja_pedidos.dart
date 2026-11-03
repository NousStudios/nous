import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Roteador responsável pelos endpoints REST de Loja, Pedidos, Estoque e Mesas no Servidor Local.
class RoteadorLojaPedidos {
  RoteadorLojaPedidos._();

  static Future<bool> atender(
    HttpRequest request, {
    required ServidorRedeLocal servidor,
  }) async {
    final path = request.uri.path;

    // 1. Obter dados completos da loja
    if (path == '/api/loja' && request.method == 'GET') {
      final ipRemoto =
          request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
      final cpfParam = request.uri.queryParameters['cpf'];
      final nomeParam = request.uri.queryParameters['nome'];
      final apelidoParam = request.uri.queryParameters['apelido'];
      final dispositivoParam = request.uri.queryParameters['dispositivo'];

      final ehLocal =
          request.connectionInfo?.remoteAddress.isLoopback ?? false;
      final cpfParamLimpo =
          (cpfParam != null) ? ChatService.normalizarCpf(cpfParam) : '';
      final ehDono = servidor.lojaAtiva != null &&
          cpfParamLimpo.isNotEmpty &&
          ChatService.normalizarCpf(servidor.lojaAtiva!.cpfDonoOriginal) ==
              cpfParamLimpo;
      final jaEhMembro = servidor.lojaAtiva != null &&
          cpfParamLimpo.isNotEmpty &&
          servidor.lojaAtiva!.membros.any(
            (m) => ChatService.normalizarCpf(m.cpf) == cpfParamLimpo,
          );

      final usuarioLogado = servidor.authProvider?.contaAtual;
      final cpfBalcao = usuarioLogado != null
          ? ChatService.normalizarCpf(usuarioLogado.cpf)
          : (servidor.pdvProvider?.cpfAtual != null
              ? ChatService.normalizarCpf(servidor.pdvProvider!.cpfAtual!)
              : '');
      final ehMesmaConta =
          cpfBalcao.isNotEmpty && cpfBalcao == cpfParamLimpo;

      final chaveTerminal = (cpfParamLimpo.isNotEmpty)
          ? '${ipRemoto}_$cpfParamLimpo'
          : '${ipRemoto}_${dispositivoParam?.trim() ?? ''}';

      ResultadoAutorizacaoConexao? decisao =
          servidor.decisoesTerminais[chaveTerminal];

      final ehUsuarioNous = cpfParamLimpo.length == 11;
      if (ehLocal || ehMesmaConta || ehDono || jaEhMembro || ehUsuarioNous) {
        decisao = (ehLocal || ehMesmaConta || ehDono || jaEhMembro)
            ? ResultadoAutorizacaoConexao.autorizadoMembro
            : ResultadoAutorizacaoConexao.autorizadoCliente;
        servidor.decisoesTerminais[chaveTerminal] = decisao;
        servidor.terminaisAutorizados.add(chaveTerminal);
        debugPrint(
          '[ServidorRedeLocal] Terminal auto-autorizado instantaneamente (MesmaConta: $ehMesmaConta, Dono: $ehDono, Membro: $jaEhMembro, UsuarioNous: $ehUsuarioNous, Local: $ehLocal): $chaveTerminal',
        );
      } else if (!servidor.terminaisAutorizados.contains(chaveTerminal)) {
        final resultado = await servidor.solicitarAutorizacaoTerminal(
          ip: ipRemoto,
          nomeDispositivo: (dispositivoParam != null &&
                  dispositivoParam.trim().isNotEmpty)
              ? dispositivoParam.trim()
              : 'Terminal Móvel',
          nomeUsuario: (apelidoParam != null &&
                  apelidoParam.trim().isNotEmpty)
              ? '$nomeParam ($apelidoParam)'
              : nomeParam,
          cpf: cpfParam,
          jaEhMembro: false,
        );

        if (resultado == ResultadoAutorizacaoConexao.recusado) {
          debugPrint(
            '[ServidorRedeLocal] Conexão recusada pelo administrador para terminal $chaveTerminal ($ipRemoto)',
          );
          ServidorRedeLocal.responderJson(
            request,
            {
              'sucesso': false,
              'mensagem': 'Conexão recusada pelo Administrador do Balcão.',
            },
            statusCode: HttpStatus.forbidden,
          );
          return true;
        }

        decisao = resultado;
        servidor.decisoesTerminais[chaveTerminal] = resultado;
        servidor.terminaisAutorizados.add(chaveTerminal);
      }

      final ehCliente =
          decisao == ResultadoAutorizacaoConexao.autorizadoCliente;

      if (cpfParam != null &&
          cpfParam.trim().isNotEmpty &&
          servidor.pdvProvider != null) {
        final terminalTemp = TerminalConectadoInfo(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          nome: (dispositivoParam != null &&
                  dispositivoParam.trim().isNotEmpty)
              ? dispositivoParam.trim()
              : 'Terminal Móvel',
          ip: ipRemoto,
          conectadoEm: DateTime.now(),
          cpf: cpfParam.trim(),
          nomeUsuario: nomeParam?.trim(),
          apelido: apelidoParam?.trim(),
          tipoConexao: ehCliente ? 'cliente' : 'membro',
        );
        servidor.consolidarContaTerminal(terminalTemp);
      }

      final lojaRetorno = servidor.lojaAtiva;
      if (lojaRetorno == null ||
          LojasService.ehLojaHostFalsa(
            lojaRetorno.id,
            lojaRetorno.tags,
            lojaRetorno.nome,
          )) {
        final lojaNous =
            servidor.pdvProvider?.buscarPorId(PdvProvider.idLojaColetivaNous);
        final nomeHost = servidor.authProvider?.contaAtual?.nomeExibicao
                    .isNotEmpty ==
                true
            ? servidor.authProvider!.contaAtual!.nomeExibicao
            : (servidor.authProvider?.contaAtual?.nome.isNotEmpty == true
                ? servidor.authProvider!.contaAtual!.nome
                : 'Usuário Nous');
        ServidorRedeLocal.responderJson(
          request,
          {
            'sucesso': true,
            'loja': null,
            'tipoHost': 'usuario',
            'hostNome': nomeHost,
            if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
            'mensagem':
                'Servidor ativo em Modo Usuário Nous (sem loja vinculada)',
            'presencas':
                servidor.obterTodasPresencas().map((p) => p.toJson()).toList(),
            'imagensAusentes': <String>[],
            'fotosUsuariosAusentes': <String>[],
          },
        );
        return true;
      }

      final imagensAusentes = <String>[];
      if (lojaRetorno.logo.trim().isEmpty ||
          !ImagemService.existe(lojaRetorno.logo)) {
        imagensAusentes.add('logo');
      }
      for (final cat in lojaRetorno.categoriasLoja) {
        if (cat.foto.trim().isEmpty || !ImagemService.existe(cat.foto)) {
          imagensAusentes.add('categoria_${cat.id}');
        }
      }
      for (final item in lojaRetorno.itensLoja) {
        if (item.imagens.isEmpty) {
          imagensAusentes.add('item_${item.id}');
        } else {
          var temAlgumaValida = false;
          for (final img in item.imagens) {
            if (ImagemService.existe(img)) {
              temAlgumaValida = true;
              break;
            }
          }
          if (!temAlgumaValida) {
            imagensAusentes.add('item_${item.id}');
          }
        }
      }
      for (final cli in lojaRetorno.clientesLoja) {
        if (cli.foto.trim().isEmpty || !ImagemService.existe(cli.foto)) {
          imagensAusentes.add('cliente_${cli.id}');
        }
      }
      for (final forn in lojaRetorno.fornecedoresLoja) {
        if (forn.foto.trim().isEmpty || !ImagemService.existe(forn.foto)) {
          imagensAusentes.add('fornecedor_${forn.id}');
        }
      }

      final fotosUsuariosAusentes = <String>[];
      for (final m in lojaRetorno.membros) {
        final cpfLimpo = m.cpf.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.isNotEmpty) {
          final contaMembro = await ContasNousService.buscarPorCpf(cpfLimpo);
          final temFotoFisica = contaMembro != null &&
              contaMembro.foto.trim().isNotEmpty &&
              ImagemService.resolverCaminhoExistente(contaMembro.foto) !=
                  null;
          if (!temFotoFisica) {
            fotosUsuariosAusentes.add(cpfLimpo);
          }
        }
      }

      ServidorRedeLocal.responderJson(request, {
        'sucesso': true,
        'loja': lojaRetorno.toJson(),
        'papelConexao': ehCliente ? 'cliente' : 'membro',
        'imagensAusentes': imagensAusentes,
        'fotosUsuariosAusentes': fotosUsuariosAusentes,
      });
      return true;
    }

    // 2. Receber atualização completa da loja vinda de um terminal móvel
    if (path == '/api/loja/atualizar' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final lojaRemota = Loja.fromJson(dados);

        if (servidor.pdvProvider != null &&
            servidor.lojaAtiva != null &&
            servidor.lojaAtiva!.id == lojaRemota.id) {
          final lojaAtual =
              servidor.pdvProvider!.buscarPorId(servidor.lojaAtiva!.id) ??
                  servidor.lojaAtiva!;

          for (final m in lojaAtual.membros) {
            final aindaExiste =
                lojaRemota.membros.any((rm) => rm.cpf == m.cpf);
            if (!aindaExiste) {
              await LojasService.removerReferencia(m.cpf, lojaAtual.id);
              debugPrint(
                '[ServidorRedeLocal] Membro ${m.nome} (${m.cpf}) removido via sincronização do terminal móvel',
              );
            }
          }

          final acoesMescladas = List<RegistroAcao>.from(lojaAtual.acoes);
          for (final acao in lojaRemota.acoes) {
            if (!acoesMescladas.any((a) => a.id == acao.id)) {
              acoesMescladas.add(acao);
            }
          }

          final lojaConsolidada =
              LojasService.consolidarLojaComImagensLocais(
            lojaRemota.copyWith(acoes: acoesMescladas),
            lojaAtual,
            manterItensAusentes: false,
          );

          servidor.lojaAtiva = lojaConsolidada;
          await servidor.pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);

          servidor.notificarTodos({
            'tipo': 'loja_atualizada',
            'loja': lojaConsolidada.toJson(),
          });
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

    // 3. Receber novo pedido do celular
    if (path == '/api/pedido' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final pedido = PedidoLoja.fromJson(dados);

        if (servidor.pdvProvider != null && servidor.lojaAtiva != null) {
          final lojaAtual =
              servidor.pdvProvider!.buscarPorId(servidor.lojaAtiva!.id);
          if (lojaAtual != null) {
            final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
            final idx = pedidos.indexWhere((p) => p.id == pedido.id);
            if (idx != -1) {
              pedidos[idx] = pedido;
              servidor.pdvProvider!.atualizarListasLoja(
                lojaAtual.id,
                pedidos: pedidos,
              );

              servidor.notificarTodos({
                'tipo': 'pedido_atualizado',
                'pedido': pedido.toJson(),
              });
            } else {
              pedidos.insert(0, pedido);
              servidor.pdvProvider!.atualizarListasLoja(
                lojaAtual.id,
                pedidos: pedidos,
              );

              SomService.tocarEvento(
                SomService.eventoNovoPedido,
                loja: lojaAtual,
              );

              servidor.notificarTodos({
                'tipo': 'pedido_adicionado',
                'pedido': pedido.toJson(),
              });
            }
          }
        }

        ServidorRedeLocal.responderJson(request, {
          'sucesso': true,
          'pedidoId': pedido.id,
          'numero': pedido.numero,
        });
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

    // 4. Receber movimentação de estoque
    if (path == '/api/movimento_estoque' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final mov = MovimentoEstoque.fromJson(dados);

        if (servidor.pdvProvider != null && servidor.lojaAtiva != null) {
          final lojaAtual =
              servidor.pdvProvider!.buscarPorId(servidor.lojaAtiva!.id);
          if (lojaAtual != null) {
            final movs =
                List<MovimentoEstoque>.from(lojaAtual.movimentosEstoque);
            movs.insert(0, mov);
            servidor.pdvProvider!.atualizarListasLoja(
              lojaAtual.id,
              movimentosEstoque: movs,
            );
            servidor.notificarTodos({
              'tipo': 'estoque_atualizado',
              'movimento': mov.toJson(),
            });
          }
        }

        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': true, 'movimentoId': mov.id},
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

    // 5. Atualizar mesa
    if (path == '/api/mesa' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final mesa = MesaLoja.fromJson(dados);

        if (servidor.pdvProvider != null && servidor.lojaAtiva != null) {
          final lojaAtual =
              servidor.pdvProvider!.buscarPorId(servidor.lojaAtiva!.id);
          if (lojaAtual != null) {
            final mesas = List<MesaLoja>.from(lojaAtual.mesas);
            final idx = mesas.indexWhere((m) => m.id == mesa.id);
            if (idx != -1) {
              mesas[idx] = mesa;
            } else {
              mesas.add(mesa);
            }
            servidor.pdvProvider!.atualizarListasLoja(
              lojaAtual.id,
              mesas: mesas,
            );
            servidor.notificarTodos({
              'tipo': 'mesa_atualizada',
              'mesa': mesa.toJson(),
            });
          }
        }

        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': true, 'mesaId': mesa.id},
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

    // 6. Sair de uma loja via rede local
    if (path == '/api/loja/sair' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final cpf =
            (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        final lojaId = dados['lojaId'] as String? ?? '';

        if (cpf.isNotEmpty && lojaId.isNotEmpty) {
          final loja = await LojasService.carregarLojaPorId(lojaId);
          if (loja != null) {
            final novosMembros = loja.membros.where(
              (m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpf,
            ).toList();
            final lojaAtualizada = loja.copyWith(membros: novosMembros);
            await LojasService.salvarLojaIndividual(lojaAtualizada);
            await LojasService.removerReferencia(cpf, lojaId);

            if (servidor.lojaAtiva?.id == lojaId) {
              servidor.lojaAtiva = lojaAtualizada;
            }
            if (servidor.pdvProvider != null) {
              await servidor.pdvProvider!.adicionarOuAtualizarLoja(
                lojaAtualizada,
              );
            }

            servidor.notificarLojaAtualizada(lojaAtualizada);
          }
          ServidorRedeLocal.responderJson(request, {'sucesso': true});
          return true;
        }

        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': 'Dados incompletos'},
          statusCode: HttpStatus.badRequest,
        );
        return true;
      } catch (e) {
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
