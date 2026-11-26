import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart';

/// Helper para processamento de identificação, desidentificação e contas de usuário no servidor WS.
class ServidorWsIdentificacaoUsuariosHelper {
  /// Tenta processar eventos de identificação, presença e usuários. Retorna `true` se tratado.
  static Future<bool> tentarProcessar(
    String? tipo,
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (tipo == 'logout' || tipo == 'desidentificacao') {
      processarDesidentificacao(ws, ctx);
      return true;
    }

    if (tipo == 'identificacao') {
      await processarIdentificacao(ws, dados, ctx);
      return true;
    }

    if (tipo == 'usuario_atualizado') {
      await processarUsuarioAtualizado(ws, dados, ctx);
      return true;
    }

    if (tipo == 'usuario_nous_excluido') {
      await processarUsuarioNousExcluido(ws, dados, ctx);
      return true;
    }

    return false;
  }

  static void processarDesidentificacao(WebSocket ws, ServidorWsContext ctx) {
    final terminal = ctx.terminaisWs[ws];
    if (terminal != null) {
      terminal.cpf = null;
      terminal.nomeUsuario = null;
      terminal.apelido = null;
      terminal.tipoConexao = 'desconhecido';
      ctx.atualizarListasTerminais();
      ctx.notificarPresencas();
      debugPrint(
        '[ServidorRedeLocal] Terminal deslogado/desidentificado: ${terminal.nome} (${terminal.ip})',
      );
    }
  }

  static Future<void> processarIdentificacao(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final nome = dados['nomeDispositivo'] as String?;
    final cpf = dados['cpf'] as String?;
    final nomeUsuario = dados['nomeUsuario'] as String?;
    final apelido = dados['apelido'] as String?;
    final foto = dados['foto'] as String?;
    final versaoApp = dados['versaoApp'] as String?;
    final buildRaw = dados['buildApp'];
    final buildApp = buildRaw is int
        ? buildRaw
        : int.tryParse(buildRaw?.toString() ?? '');
    final terminal = ctx.terminaisWs[ws];
    if (terminal == null) return;

    if (nome != null && nome.trim().isNotEmpty) {
      terminal.nome = nome.trim();
    }
    if (cpf != null && cpf.trim().isNotEmpty) {
      terminal.cpf = cpf.trim();
    }
    if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) {
      terminal.nomeUsuario = nomeUsuario.trim();
    }
    if (apelido != null && apelido.trim().isNotEmpty) {
      terminal.apelido = apelido.trim();
    }
    if (versaoApp != null && versaoApp.trim().isNotEmpty) {
      terminal.versaoApp = versaoApp.trim();
    }
    if (buildApp != null && buildApp > 0) {
      terminal.buildApp = buildApp;
    }

    final cpfLimpoTerm = (cpf != null) ? ChatService.normalizarCpf(cpf) : '';
    final cpfBalcaoAtual = ChatService.normalizarCpf(
      ctx.authProvider?.contaAtual?.cpf ?? ctx.authProvider?.cpf ?? '',
    );
    final ehMesmaContaBalcao =
        cpfLimpoTerm.isNotEmpty && cpfLimpoTerm == cpfBalcaoAtual;
    final lojaAtiva = ctx.obterLojaAtiva();
    final lojasHospedadas = [
      ?lojaAtiva,
      ...?ctx.pdvProvider?.lojas,
    ];
    final ehDonoOuMembro = cpfLimpoTerm.isNotEmpty &&
        lojasHospedadas.any((l) =>
            ChatService.normalizarCpf(l.cpfDonoOriginal) == cpfLimpoTerm ||
            l.membros.any(
              (m) => ChatService.normalizarCpf(m.cpf) == cpfLimpoTerm,
            ));
    terminal.tipoConexao =
        (ehMesmaContaBalcao || ehDonoOuMembro) ? 'membro' : 'cliente';
    final socketsParaRemover = <WebSocket>[];
    for (final entry in ctx.terminaisWs.entries) {
      if (entry.key != ws) {
        final outroTerm = entry.value;
        final outroCpfLimpo = outroTerm.cpf != null
            ? ChatService.normalizarCpf(outroTerm.cpf!)
            : '';
        final mesmoCpf =
            cpfLimpoTerm.isNotEmpty && outroCpfLimpo == cpfLimpoTerm;
        final mesmoIp = terminal.ip.isNotEmpty && outroTerm.ip == terminal.ip;
        final ehDuplicada = mesmoCpf ||
            (cpfLimpoTerm.isEmpty && outroCpfLimpo.isEmpty && mesmoIp);
        if (ehDuplicada) {
          socketsParaRemover.add(entry.key);
        }
      }
    }
    for (final velhoWs in socketsParaRemover) {
      ctx.clientesWs.remove(velhoWs);
      ctx.terminaisWs.remove(velhoWs);
      try {
        debugPrint(
          '[ServidorRedeLocal] Encerrando conexão duplicada anterior para CPF: $cpfLimpoTerm / IP: ${terminal.ip}',
        );
        velhoWs.close();
      } catch (_) {}
    }

    ctx.atualizarListasTerminais();
    debugPrint(
      '[ServidorRedeLocal] Terminal identificado: "${terminal.nome}" (CPF: ${terminal.cpf}, Nome: ${terminal.nomeUsuario}, Apelido: ${terminal.apelido}, IP: ${terminal.ip})',
    );

    ctx.consolidarContaTerminal(terminal);

    if (cpf != null &&
        cpf.trim().isNotEmpty &&
        foto != null &&
        foto.trim().isNotEmpty) {
      final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
      if (fotoResolvida != null) {
        final c = await ContasNousService.buscarPorCpf(cpf.trim());
        if (c != null &&
            (c.foto.isEmpty ||
                !ImagemService.existe(c.foto) ||
                c.foto != fotoResolvida)) {
          final atualizado = c.copyWith(foto: fotoResolvida);
          await ContasNousService.salvar(atualizado);
          ctx.authProvider?.atualizarContaNoCache(atualizado);
        }
      }
    }

    ctx.notificarPresencas();

    if (cpfLimpoTerm.isNotEmpty) {
      try {
        final convitesPendentes = await ConvitesService.carregar(cpfLimpoTerm);
        if (convitesPendentes.isNotEmpty) {
          ws.add(jsonEncode({
            'tipo': 'sincronizacao_convites',
            'convites': convitesPendentes.map((c) => c.toJson()).toList(),
          }));
          debugPrint(
            '[ServidorRedeLocal] Sincronizados ${convitesPendentes.length} convite(s) pendente(s) com terminal $cpfLimpoTerm',
          );
        }
      } catch (e) {
        debugPrint(
          '[ServidorRedeLocal] Erro ao sincronizar convites com terminal: $e',
        );
      }

      // Portabilidade automática de chaves E2EE/Ed25519 entre aparelhos do MESMO CPF
      final cpfBalcao = ChatService.normalizarCpf(
        ctx.authProvider?.contaAtual?.cpf ?? ctx.authProvider?.cpf ?? '',
      );
      if (cpfBalcao.isNotEmpty && cpfBalcao == cpfLimpoTerm) {
        try {
          final pacoteChaves = await CriptografiaService.exportarChavesDoCpf(
            cpfLimpoTerm,
          );
          if (pacoteChaves != null) {
            ws.add(jsonEncode({
              'tipo': 'chaves_proprias_cpf',
              'cpf': cpfLimpoTerm,
              'pacote': pacoteChaves,
            }));
          }
        } catch (e) {
          debugPrint(
            '[ServidorRedeLocal] Erro ao sincronizar chaves do mesmo CPF: $e',
          );
        }
      }
    }

    // Drena quaisquer mensagens que estavam retidas na fila aguardando a conexão deste terminal
    ChatService.drenarFilaDeSaida();
  }

  static Future<void> processarUsuarioAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['usuario'] == null) return;
    try {
      var usuario = UsuarioNous.fromJson(
        dados['usuario'] as Map<String, dynamic>,
      );
      if (await ContasExcluidasService.estaExcluido(usuario.cpf)) {
        return;
      }
      final local = await ContasNousService.buscarPorCpf(usuario.cpf);
      if (local != null) {
        final fotoFinal =
            (usuario.foto.isNotEmpty && ImagemService.existe(usuario.foto))
                ? usuario.foto
                : (local.foto.isNotEmpty && ImagemService.existe(local.foto)
                    ? local.foto
                    : usuario.foto);
        usuario = local
            .mesclarCom(usuario, priorizarOutro: true)
            .copyWith(foto: fotoFinal);
      }
      await ContasNousService.salvar(usuario);
      ctx.pdvProvider?.sincronizarDadosUsuarioEmLojas(usuario);
      ctx.authProvider?.atualizarContaNoCache(usuario);
      await ctx.authProvider?.carregarCacheContas();
      ctx.pdvProvider?.notificarMudanca();

      final payload = jsonEncode({
        'tipo': 'usuario_atualizado',
        'usuario': usuario.toJson(),
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    } catch (e) {
      debugPrint(
        '[ServidorRedeLocal] Erro ao processar usuario_atualizado via WS: $e',
      );
    }
  }

  static Future<void> processarUsuarioNousExcluido(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final cpf = (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    if (cpf.isEmpty) return;
    try {
      final regJson = dados['registro'] as Map<String, dynamic>?;
      if (regJson != null) {
        await ContasExcluidasService.salvarRegistro(
          ContaExcluidaNous.fromMap(regJson),
        );
      } else {
        final local = await ContasNousService.buscarPorCpf(cpf);
        if (local != null) {
          await ContasExcluidasService.registrarExclusao(local);
        }
      }
      await ContasNousService.excluir(cpf);
      final coletiva = ctx.pdvProvider?.buscarPorId('loja_nous_coletiva');
      if (coletiva != null) {
        final membrosAtualizados = coletiva.membros
            .where((m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpf)
            .toList();
        if (membrosAtualizados.length != coletiva.membros.length) {
          final atualizada = coletiva.copyWith(membros: membrosAtualizados);
          await LojasService.salvarLojaIndividual(atualizada);
          await ctx.pdvProvider?.adicionarOuAtualizarLoja(atualizada);
        }
      }
      await ctx.authProvider?.carregarCacheContas();
      ctx.pdvProvider?.notificarMudanca();
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
    } catch (e) {
      debugPrint(
        '[ServidorRedeLocal] Erro ao processar usuario_nous_excluido: $e',
      );
    }
  }
}
