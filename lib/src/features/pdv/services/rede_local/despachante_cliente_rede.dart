import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

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
        Uri.parse('http://$ipServidor:$portaServidor/api/pedido'),
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
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$ipServidor:$portaServidor/api/movimento_estoque'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(mov.toJson()));
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
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$ipServidor:$portaServidor/api/mesa'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(mesa.toJson()));
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
      final uri = Uri.parse('http://$ipServidor:$portaServidor/api/versao');
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;

        if (dados['sucesso'] == true && dados['temApk'] == true) {
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

          if (temNovaVersao) {
            AtualizacaoService.infoAtualizacao.value = InfoAtualizacao(
              versao: versaoRemota,
              nomeVersao: 'Atualização do Balcão Wi-Fi (v$versaoRemota • Build $buildRemota)',
              descricao:
                  'Instalação da versão estável mais recente transmitida diretamente pelo Computador Balcão via Wi-Fi.',
              urlDownload: 'http://$ipServidor:$portaServidor/api/download_apk',
              dataPublicacao: DateTime.now(),
              alteracoes: alteracoesFinais,
            );
            AtualizacaoService.temAtualizacao.value = true;
            AtualizacaoService.ultimaVerificacao.value = DateTime.now();
            AtualizacaoService.mensagemStatus.value =
                'Nova versão v$versaoRemota disponível para download no balcão!';
            debugPrint('[DespachanteClienteRede] Atualização disponível no balcão via Wi-Fi!');
          } else {
            AtualizacaoService.infoAtualizacao.value = null;
            AtualizacaoService.temAtualizacao.value = false;
            AtualizacaoService.ultimaVerificacao.value = DateTime.now();
            AtualizacaoService.mensagemStatus.value =
                'O Nous já está na versão mais recente (v${AtualizacaoService.versaoAtual}).';
            debugPrint('[DespachanteClienteRede] O aplicativo já está na mesma versão ou mais recente que o balcão.');
          }
        } else {
          AtualizacaoService.infoAtualizacao.value = null;
          AtualizacaoService.temAtualizacao.value = false;
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
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse('http://$ipServidor:$portaServidor/api/loja/sair');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'cpf': cpf, 'lojaId': lojaId}));
      final resp = await req.close();
      await resp.drain();
      debugPrint('[DespachanteClienteRede] Saída da loja $lojaId notificada ao balcão com sucesso.');
    } catch (e) {
      debugPrint('[DespachanteClienteRede] Erro ao notificar saída da loja ao balcão: $e');
    }
  }
}
