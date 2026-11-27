import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Responsável por despachar requisições REST pontuais do terminal móvel para o servidor balcão.
class DespachanteClienteRede {
  const DespachanteClienteRede();

  /// Envia um pedido para o servidor via HTTP REST
  Future<bool> enviarPedido({
    required String? ipServidor,
    required int? portaServidor,
    required PedidoLoja pedido,
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/pedido',
        ),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(pedido.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao enviar pedido ao servidor: $e');
      return false;
    }
  }

  /// Envia uma movimentação de estoque realizada no celular para o servidor
  Future<bool> enviarMovimentoEstoque({
    required String? ipServidor,
    required int? portaServidor,
    required MovimentoEstoque mov,
    String? lojaId,
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/movimento_estoque',
        ),
      );
      request.headers.contentType = ContentType.json;
      final payload = mov.toJson();
      if (lojaId != null && lojaId.isNotEmpty) {
        payload['lojaId'] = lojaId;
      }
      request.write(jsonEncode(payload));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao enviar estoque ao servidor: $e');
      return false;
    }
  }

  /// Envia atualização de mesa para o servidor central
  Future<bool> enviarMesa({
    required String? ipServidor,
    required int? portaServidor,
    required MesaLoja mesa,
    String? lojaId,
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ipServidor,
          porta: portaServidor,
          caminho: '/api/mesa',
        ),
      );
      request.headers.contentType = ContentType.json;
      final payload = mesa.toJson();
      if (lojaId != null && lojaId.isNotEmpty) {
        payload['lojaId'] = lojaId;
      }
      request.write(jsonEncode(payload));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao enviar mesa ao servidor: $e');
      return false;
    }
  }

  /// Verifica se o balcão possui atualizações do sistema ou APK disponível para download
  Future<void> verificarAtualizacaoLocal({
    required String? ipServidor,
    required int? portaServidor,
  }) async {
    if (ipServidor == null || portaServidor == null) return;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: ipServidor,
        porta: portaServidor,
        caminho: '/api/versao',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;

        if (dados['sucesso'] == true) {
          final versaoRemota = dados['versao'] as String? ?? AtualizacaoService.versaoAtual;
          final buildRemota = dados['build'] as int? ?? AtualizacaoService.buildAtual;
          final alteracoesRemotas = (dados['alteracoes'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

          var alteracoesFinais = alteracoesRemotas;
          if (alteracoesFinais.isEmpty) {
            final nov = ChangelogService.obterUltimaVersao(versaoRemota) ??
                ChangelogService.obterUltimaVersao();
            if (nov != null && nov.alteracoes.isNotEmpty) {
              alteracoesFinais = nov.alteracoes;
            }
          }

          final temNovaVersao = buildRemota > AtualizacaoService.buildAtual ||
              (buildRemota == AtualizacaoService.buildAtual &&
                  AtualizacaoService.versaoMaior(versaoRemota, AtualizacaoService.versaoAtual));

          final ehWindows = Platform.isWindows;
          final temBinarioLocal = ehWindows
              ? (dados['temZip'] == true || dados['temExe'] == true)
              : (dados['temApk'] == true);

          if (temNovaVersao && temBinarioLocal) {
            final infoAtual = AtualizacaoService.infoAtualizacao.value;
            final jaTemGithubIgualOuMaior = AtualizacaoService.temAtualizacao.value &&
                infoAtual != null &&
                !infoAtual.urlDownload.contains('/api/download_') &&
                !AtualizacaoService.versaoMaior(versaoRemota, infoAtual.versao);
            if (jaTemGithubIgualOuMaior) {
              return;
            }
            final String caminhoDownload;
            if (ehWindows) {
              caminhoDownload = dados['temZip'] == true
                  ? '/api/download_zip'
                  : '/api/download_exe';
            } else {
              caminhoDownload = '/api/download_apk';
            }
            AtualizacaoService.infoAtualizacao.value = InfoAtualizacao(
              versao: versaoRemota,
              nomeVersao: 'Atualização do Servidor Wi-Fi (v$versaoRemota • Build $buildRemota)',
              descricao:
                  'Instalação da versão estável mais recente transmitida diretamente pela rede Wi-Fi local.',
              urlDownload: ResolvedorUrlRede.montarUrlHttp(
                hostOuIp: ipServidor,
                porta: portaServidor,
                caminho: caminhoDownload,
              ),
              dataPublicacao: DateTime.now(),
              alteracoes: alteracoesFinais,
            );
            AtualizacaoService.temAtualizacao.value = true;
            AtualizacaoService.ultimaVerificacao.value = DateTime.now();
            AtualizacaoService.mensagemStatus.value =
                'Nova versão v$versaoRemota disponível para download na rede local!';
            debugPrint('[DespachanteClienteRede] Atualização disponível na rede via Wi-Fi ($caminhoDownload)!');
          } else if (temNovaVersao && !temBinarioLocal) {
            // Servidor local está mais atualizado, mas não possui o instalador desta plataforma em disco:
            // tenta buscar automaticamente o instalador na Release do GitHub caso haja internet.
            unawaited(AtualizacaoService.verificarAtualizacao(silencioso: true));
          } else {
            final urlAtual = AtualizacaoService.infoAtualizacao.value?.urlDownload ?? '';
            final temGithubAtivo = AtualizacaoService.temAtualizacao.value &&
                !urlAtual.contains('/api/download_');
            if (!temGithubAtivo) {
              AtualizacaoService.infoAtualizacao.value = null;
              AtualizacaoService.temAtualizacao.value = false;
              AtualizacaoService.ultimaVerificacao.value = DateTime.now();
              AtualizacaoService.mensagemStatus.value =
                  'O Nous já está na versão mais recente (v${AtualizacaoService.versaoAtual}).';
            }
            debugPrint('[DespachanteClienteRede] O aplicativo já está na mesma versão ou mais recente que o servidor.');
          }
        } else {
          final urlAtual = AtualizacaoService.infoAtualizacao.value?.urlDownload ?? '';
          final temGithubAtivo = AtualizacaoService.temAtualizacao.value &&
              !urlAtual.contains('/api/download_');
          if (!temGithubAtivo) {
            AtualizacaoService.infoAtualizacao.value = null;
            AtualizacaoService.temAtualizacao.value = false;
          }
        }
      }
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao checar atualização local: $e');
    }
  }

  /// Notifica o servidor balcão que o membro saiu da loja para desvinculação imediata
  Future<void> notificarSaidaLoja({
    required String? ipServidor,
    required int? portaServidor,
    required String lojaId,
    required String cpf,
  }) async {
    if (ipServidor == null || portaServidor == null) return;
    try {
      final ehNuvem = ResolvedorUrlRede.ehHostNuvem(ipServidor);
      final client = HttpClient()
        ..connectionTimeout = Duration(seconds: ehNuvem ? 12 : 5);
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: ipServidor,
        porta: portaServidor,
        caminho: '/api/loja/sair',
      );
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'cpf': cpf, 'lojaId': lojaId}));
      final resp = await req.close().timeout(Duration(seconds: ehNuvem ? 12 : 5));
      await resp.drain();
      debugPrint('[DespachanteClienteRede] Saída da loja $lojaId notificada ao balcão com sucesso.');
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao notificar saída da loja ao balcão: $e');
    }
  }

  /// Envia mensagem de chat em tempo real via WebSocket para o servidor (com fallback REST)
  Future<bool> enviarMensagemChat({
    required WebSocket? ws,
    required bool estaConectado,
    required String? ipServidor,
    required int? portaServidor,
    required List<DispositivoLojaInfo> lojasEncontradas,
    required MensagemChat msg,
    Map<String, dynamic>? payloadCustomizado,
    required Future<String> Function(String) uploadImagem,
    required Future<String> Function(String caminhoLocal, String subpasta) uploadAnexo,
  }) async {
    MensagemChat msgParaEnvio = msg;

    if (msg.caminhoAnexo.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(msg.caminhoAnexo);
      if (resolvida != null) {
        String arquivoParaUpload = resolvida;
        if (ChatE2eeService.ehConversaElegivelE2ee(msg.conversaId)) {
          final arqEnc = File('$resolvida.enc');
          if (arqEnc.existsSync()) {
            arquivoParaUpload = arqEnc.path;
          }
        }

        final jaTemBase64 =
            payloadCustomizado != null && payloadCustomizado['anexoBytesBase64'] != null;
        if (!jaTemBase64) {
          final String anexoNoServidor;
          if (msg.tipo == 'imagem') {
            anexoNoServidor = await uploadImagem(arquivoParaUpload);
          } else {
            anexoNoServidor = await uploadAnexo(
              arquivoParaUpload,
              msg.tipo == 'audio' ? 'audios' : 'anexos',
            );
          }
          if (anexoNoServidor.isNotEmpty) {
            msgParaEnvio = msgParaEnvio.copyWith(caminhoAnexo: anexoNoServidor);
          }
        } else {
          final nomeBase = arquivoParaUpload.split(RegExp(r'[/\\]')).last;
          final pasta = msg.tipo == 'imagem'
              ? 'imagens'
              : (msg.tipo == 'audio' ? 'audios' : 'anexos');
          msgParaEnvio = msgParaEnvio.copyWith(caminhoAnexo: '$pasta/$nomeBase');
          if (msg.tipo == 'imagem') {
            unawaited(uploadImagem(arquivoParaUpload));
          } else {
            unawaited(uploadAnexo(
              arquivoParaUpload,
              msg.tipo == 'audio' ? 'audios' : 'anexos',
            ));
          }
        }
      }
    }

    final dadosEnvio = payloadCustomizado != null
        ? Map<String, dynamic>.from(payloadCustomizado)
        : msgParaEnvio.toJson();
    if (msgParaEnvio.caminhoAnexo != msg.caminhoAnexo) {
      dadosEnvio['caminhoAnexo'] = msgParaEnvio.caminhoAnexo;
    }

    if (ws != null && estaConectado) {
      try {
        ws.add(
          jsonEncode({
            'tipo': 'mensagem_chat',
            'mensagem': dadosEnvio,
          }),
        );
        return true;
      } catch (e) {
        debugPrint('[DespachanteClienteRede] Erro ao enviar mensagem via WS, tentando REST: $e');
      }
    }

    String? ip = ipServidor;
    int porta = portaServidor ?? ServidorRedeLocal.portaPadraoHttp;
    if (ip == null && lojasEncontradas.isNotEmpty) {
      ip = lojasEncontradas.first.ip;
      porta = lojasEncontradas.first.porta;
    }
    if (ip == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        ip = prefs.getString('nous_ultimo_ip_balcao');
        porta = prefs.getInt('nous_ultima_porta_balcao') ?? ServidorRedeLocal.portaPadraoHttp;
      } catch (_) {}
    }

    if (ip != null) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final uri = ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ip,
          porta: porta,
          caminho: '/api/chat/mensagem',
        );
        final req = await client.postUrl(uri);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(dadosEnvio));
        final resp = await req.close();
        if (resp.statusCode == HttpStatus.ok) {
          return true;
        }
      } catch (e) {
        debugPrint('[DespachanteClienteRede] Erro ao enviar mensagem de chat via REST: $e');
      }
    }
    return false;
  }
}
