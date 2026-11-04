import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';

/// Gerencia a sincronização pan-dispositivo de identidades de usuários,
/// fotos de perfil e perfis de lojas com o balcão.
class SincronizadorUsuariosRede {
  final TransferenciaArquivosRede _transferencia;
  final ReconciliadorLojaRede _reconciliador;

  bool _sincronizandoPerfisLojas = false;
  bool get sincronizandoPerfisLojas => _sincronizandoPerfisLojas;

  SincronizadorUsuariosRede({
    TransferenciaArquivosRede? transferencia,
    ReconciliadorLojaRede? reconciliador,
  })  : _transferencia = transferencia ?? TransferenciaArquivosRede(),
        _reconciliador = reconciliador ?? ReconciliadorLojaRede();

  /// Mescla duas fichas de usuário preservando dados preenchidos de ambas as pontas
  UsuarioNous mesclarUsuarios(UsuarioNous local, UsuarioNous remoto) {
    return UsuarioNous(
      cpf: local.cpf.isNotEmpty ? local.cpf : remoto.cpf,
      nome: (local.nome.isNotEmpty && local.nome.toLowerCase() != 'blackview')
          ? local.nome
          : remoto.nome,
      apelido: local.apelido.isNotEmpty ? local.apelido : remoto.apelido,
      nomeDeUsuario: local.nomeDeUsuario.isNotEmpty
          ? local.nomeDeUsuario
          : remoto.nomeDeUsuario,
      dataNascimento: local.dataNascimento.isNotEmpty
          ? local.dataNascimento
          : remoto.dataNascimento,
      emails: {...local.emails, ...remoto.emails}.toList(),
      foto: local.foto.isNotEmpty && ImagemService.existe(local.foto)
          ? local.foto
          : remoto.foto,
      nomePai: local.nomePai.isNotEmpty ? local.nomePai : remoto.nomePai,
      nomeMae: local.nomeMae.isNotEmpty ? local.nomeMae : remoto.nomeMae,
      localNascimento: local.localNascimento.isNotEmpty
          ? local.localNascimento
          : remoto.localNascimento,
      tipoSanguineo: local.tipoSanguineo.isNotEmpty
          ? local.tipoSanguineo
          : remoto.tipoSanguineo,
      estadoCivil: local.estadoCivil.isNotEmpty
          ? local.estadoCivil
          : remoto.estadoCivil,
      biografia:
          local.biografia.isNotEmpty ? local.biografia : remoto.biografia,
      nomePublico: local.nomePublico.isNotEmpty
          ? local.nomePublico
          : remoto.nomePublico,
      apelidoPublico: local.apelidoPublico.isNotEmpty
          ? local.apelidoPublico
          : remoto.apelidoPublico,
      fotoPublica: local.fotoPublica.isNotEmpty
          ? local.fotoPublica
          : remoto.fotoPublica,
      dadosPrivados: local.dadosPrivados.isNotEmpty
          ? local.dadosPrivados
          : remoto.dadosPrivados,
      dadosAutorizadosPorCpf: {
        ...local.dadosAutorizadosPorCpf,
        ...remoto.dadosAutorizadosPorCpf
      }.toList(),
      seguindo: {...local.seguindo, ...remoto.seguindo}.toList(),
      seguidores: {...local.seguidores, ...remoto.seguidores}.toList(),
    );
  }

  /// Obtém o caminho físico existente e válido de uma foto local para um CPF específico
  Future<String?> obterFotoLocalValidaPorCpf(
    String cpf, {
    PdvProvider? pdvProvider,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return null;

    final conta = await ContasNousService.buscarPorCpf(cpfLimpo);
    if (conta != null && conta.foto.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(conta.foto);
      if (resolvida != null) return resolvida;
    }

    final fotoCli = pdvProvider?.buscarFotoClientePorCpf(cpfLimpo);
    if (fotoCli != null && fotoCli.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(fotoCli);
      if (resolvida != null) return resolvida;
    }

    try {
      final dadosAuto =
          await DadosLocaisService.buscarPorDocumento(cpfLimpo);
      if (dadosAuto != null && dadosAuto.foto.isNotEmpty) {
        final resolvida =
            ImagemService.resolverCaminhoExistente(dadosAuto.foto);
        if (resolvida != null) return resolvida;
      }
    } catch (_) {}

    return null;
  }

  /// Cura ativamente lacunas de fotos de membros/usuários reportadas pelo servidor balcão
  Future<void> curarFotosUsuariosAusentesNoServidor({
    required String? ipServidor,
    required int? portaServidor,
    required List<String> cpfsAusentes,
    PdvProvider? pdvProvider,
  }) async {
    if (ipServidor == null || portaServidor == null || cpfsAusentes.isEmpty) {
      return;
    }

    for (final cpfBruto in cpfsAusentes) {
      final cpfLimpo = cpfBruto.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isEmpty) continue;

      final fotoFisicaLocal = await obterFotoLocalValidaPorCpf(
        cpfLimpo,
        pdvProvider: pdvProvider,
      );
      if (fotoFisicaLocal != null) {
        debugPrint(
          '[SincronizadorUsuariosRede] Autocura mútua: servidor balcão reportou ausência de foto física para CPF $cpfLimpo. Enviando foto local...',
        );
        var conta = await ContasNousService.buscarPorCpf(cpfLimpo);
        if (conta == null) {
          final dadosAuto =
              await DadosLocaisService.buscarPorDocumento(cpfLimpo);
          conta = UsuarioNous(
            cpf: cpfLimpo,
            nome: dadosAuto?.nome ?? 'Usuário',
            apelido: dadosAuto?.apelido ?? '',
            dataNascimento: dadosAuto?.dataNascimento ?? '',
            foto: fotoFisicaLocal,
          );
        } else {
          conta = conta.copyWith(foto: fotoFisicaLocal);
        }
        await enviarUsuario(
          ipServidor: ipServidor,
          portaServidor: portaServidor,
          usuario: conta,
        );
      }
    }
  }

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão
  Future<bool> enviarUsuario({
    required String? ipServidor,
    required int? portaServidor,
    required UsuarioNous usuario,
  }) async {
    if (ipServidor == null || portaServidor == null) return false;
    try {
      var usuarioParaEnvio = usuario;
      if (usuario.foto.isNotEmpty && !ImagemService.ehAsset(usuario.foto)) {
        final fotoNoServidor =
            await _transferencia.enviarUploadImagemParaServidor(
          ipServidor: ipServidor,
          portaServidor: portaServidor,
          caminhoLocal: usuario.foto,
        );
        if (fotoNoServidor.isNotEmpty && fotoNoServidor != usuario.foto) {
          usuarioParaEnvio = usuarioParaEnvio.copyWith(foto: fotoNoServidor);
        }
      }

      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri =
          Uri.parse('http://$ipServidor:$portaServidor/api/usuario/atualizar');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(usuarioParaEnvio.toJson()));
      final resp = await req.close();
      final sucesso = resp.statusCode == HttpStatus.ok;
      debugPrint(
        '[SincronizadorUsuariosRede] Envio de usuário ${usuario.cpf} (${usuario.nome}) para o servidor balcão: ${sucesso ? 'SUCESSO' : 'FALHA (status ${resp.statusCode})'}',
      );
      return sucesso;
    } catch (e) {
      debugPrint(
        '[SincronizadorUsuariosRede] Erro ao enviar usuário ao servidor: $e',
      );
      return false;
    }
  }

  /// Consulta um usuário no servidor central por CPF
  Future<UsuarioNous?> buscarUsuarioRemoto({
    required String? ipServidor,
    required int? portaServidor,
    required String cpf,
    AuthProvider? authProvider,
    PdvProvider? pdvProvider,
  }) async {
    if (ipServidor == null || portaServidor == null) return null;
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return null;

    try {
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'http://$ipServidor:$portaServidor/api/usuario?cpf=$cpfLimpo',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['encontrado'] == true && dados['usuario'] != null) {
          final usuarioRemoto =
              UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);

          if (usuarioRemoto.foto.isNotEmpty &&
              !ImagemService.existe(usuarioRemoto.foto)) {
            final novaFotoLocal = await _transferencia.baixarImagemRemota(
              caminhoRemoto: usuarioRemoto.foto,
              ipServidor: ipServidor,
              portaServidor: portaServidor,
              cpf: usuarioRemoto.cpf,
            );
            if (novaFotoLocal.isNotEmpty &&
                ImagemService.existe(novaFotoLocal)) {
              ResolvedorFotoChat.instancia
                  .registrarFoto(usuarioRemoto.cpf, novaFotoLocal);
              final uFinal = usuarioRemoto.copyWith(foto: novaFotoLocal);
              await ContasNousService.salvar(uFinal);
              authProvider?.atualizarContaNoCache(uFinal);
              pdvProvider?.sincronizarFotoUsuarioEmClientes(
                uFinal.cpf,
                uFinal.foto,
              );
              return uFinal;
            }
          }

          final local = await ContasNousService.buscarPorCpf(cpfLimpo);
          final contaFinal = local != null
              ? mesclarUsuarios(local, usuarioRemoto)
              : usuarioRemoto;

          await ContasNousService.salvar(contaFinal);
          authProvider?.atualizarContaNoCache(contaFinal);
          pdvProvider?.sincronizarFotoUsuarioEmClientes(
            contaFinal.cpf,
            contaFinal.foto,
          );
          return contaFinal;
        }
      }
    } catch (e) {
      debugPrint(
        '[SincronizadorUsuariosRede] Erro ao buscar usuário remoto: $e',
      );
    }
    return null;
  }

  /// Sincroniza a Identidade do Usuário (dados cadastrais e foto) a partir do balcão (autocura mútua)
  Future<void> sincronizarIdentidadeUsuario({
    required String? ipServidor,
    required int? portaServidor,
    AuthProvider? auth,
    PdvProvider? pdvProvider,
  }) async {
    if (ipServidor == null || portaServidor == null) return;
    final cpf = (auth?.cpf ?? auth?.contaAtual?.cpf ?? pdvProvider?.cpfAtual ?? '')
        .replaceAll(RegExp(r'\D'), '');
    if (cpf.isEmpty) return;

    try {
      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri =
          Uri.parse('http://$ipServidor:$portaServidor/api/usuario?cpf=$cpf');
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['encontrado'] == true && dados['usuario'] != null) {
          final usuarioRemoto =
              UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);
          final contaLocal = await ContasNousService.buscarPorCpf(cpf);

          if (usuarioRemoto.foto.isNotEmpty &&
              (contaLocal == null ||
                  contaLocal.foto.isEmpty ||
                  !ImagemService.existe(contaLocal.foto))) {
            final novaFotoLocal = await _transferencia.baixarImagemRemota(
              caminhoRemoto: usuarioRemoto.foto,
              ipServidor: ipServidor,
              portaServidor: portaServidor,
              cpf: cpf,
            );
            if (novaFotoLocal.isNotEmpty &&
                ImagemService.existe(novaFotoLocal)) {
              ResolvedorFotoChat.instancia.registrarFoto(cpf, novaFotoLocal);
            }
          }

          UsuarioNous contaFinal;
          if (contaLocal != null) {
            contaFinal = mesclarUsuarios(contaLocal, usuarioRemoto);
          } else {
            contaFinal = usuarioRemoto;
          }

          await ContasNousService.salvar(contaFinal);
          auth?.atualizarContaNoCache(contaFinal);
          pdvProvider?.sincronizarFotoUsuarioEmClientes(
            contaFinal.cpf,
            contaFinal.foto,
          );
          await auth?.recarregarConta();
          debugPrint(
            '[SincronizadorUsuariosRede] Identidade sincronizada do balcão com sucesso: CPF $cpf (${contaFinal.nome})',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[SincronizadorUsuariosRede] Erro ao sincronizar identidade do usuário com o balcão: $e',
      );
    }
  }

  /// Reconcilia todas as contas cadastradas neste dispositivo com o servidor balcão
  Future<void> reconciliarTodasContasLocaisComServidor({
    required String? ipServidor,
    required int? portaServidor,
    AuthProvider? authProvider,
    PdvProvider? pdvProvider,
  }) async {
    if (ipServidor == null || portaServidor == null) return;
    try {
      final cpfsServidor = <String>{};

      // 0. Consulta todos os usuários disponíveis no servidor balcão
      try {
        final clientUsuarios =
            HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final uriUsuarios =
            Uri.parse('http://$ipServidor:$portaServidor/api/usuarios');
        final reqUsuarios = await clientUsuarios.getUrl(uriUsuarios);
        final respUsuarios = await reqUsuarios.close();
        if (respUsuarios.statusCode == HttpStatus.ok) {
          final bodyUsuarios = await utf8.decodeStream(respUsuarios);
          final dadosUsuarios =
              jsonDecode(bodyUsuarios) as Map<String, dynamic>;
          final listaUsuarios =
              (dadosUsuarios['usuarios'] as List<dynamic>?) ?? [];
          for (final uJson in listaUsuarios) {
            if (uJson is Map<String, dynamic>) {
              final u = UsuarioNous.fromJson(uJson);
              final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
              if (cpfLimpo.length == 11 &&
                  u.nome.toLowerCase() != 'blackview') {
                cpfsServidor.add(cpfLimpo);
                final existente = await ContasNousService.buscarPorCpf(u.cpf);
                var mesclada =
                    existente == null ? u : mesclarUsuarios(existente, u);

                if (u.foto.isNotEmpty && !ImagemService.existe(mesclada.foto)) {
                  final fotoBaixada = await _transferencia.baixarImagemRemota(
                    caminhoRemoto: u.foto,
                    ipServidor: ipServidor,
                    portaServidor: portaServidor,
                    cpf: u.cpf,
                  );
                  if (fotoBaixada.isNotEmpty &&
                      ImagemService.existe(fotoBaixada)) {
                    mesclada = mesclada.copyWith(foto: fotoBaixada);
                    ResolvedorFotoChat.instancia
                        .registrarFoto(u.cpf, fotoBaixada);
                  }
                }

                await ContasNousService.salvar(mesclada);
                authProvider?.atualizarContaNoCache(mesclada);
                pdvProvider?.sincronizarFotoUsuarioEmClientes(
                  mesclada.cpf,
                  mesclada.foto,
                );

                final cpfAtivo = pdvProvider?.cpfAtual ??
                    authProvider?.contaAtual?.cpf ??
                    authProvider?.cpf;
                if (cpfAtivo != null &&
                    cpfAtivo.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
                  await authProvider?.recarregarConta();
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
          '[SincronizadorUsuariosRede] Erro ao sincronizar catálogo global de usuários do balcão: $e',
        );
      }

      // 1. Envia contas locais ao balcão
      final contasLocais = await ContasNousService.carregarTodas();
      for (final conta in contasLocais) {
        final cpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.isEmpty) continue;
        if (!cpfsServidor.contains(cpfLimpo) ||
            (conta.foto.isNotEmpty && ImagemService.existe(conta.foto))) {
          await enviarUsuario(
            ipServidor: ipServidor,
            portaServidor: portaServidor,
            usuario: conta,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[SincronizadorUsuariosRede] Erro ao reconciliar contas com balcão: $e',
      );
    }
  }

  /// Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF ativo
  Future<void> sincronizarPerfisLojasComServidor({
    required String? ipServidor,
    required int? portaServidor,
    AuthProvider? authProvider,
    PdvProvider? pdvProvider,
    Loja? lojaSincronizada,
  }) async {
    if (ipServidor == null || portaServidor == null) return;
    if (_sincronizandoPerfisLojas) return;
    final cpf = (pdvProvider?.cpfAtual ?? authProvider?.cpf ?? '')
        .replaceAll(RegExp(r'\D'), '');
    if (cpf.isEmpty) return;

    _sincronizandoPerfisLojas = true;
    try {
      final referenciasLocais = await LojasService.carregarReferencias(cpf);
      final lojasAEnviar = <Map<String, dynamic>>[];

      for (final ref in referenciasLocais) {
        final loja = await LojasService.carregarLojaPorId(ref.lojaId);
        if (loja != null) {
          final lojaPronta =
              await _reconciliador.prepararLojaComUploadsParaServidor(
            ipServidor: ipServidor,
            portaServidor: portaServidor,
            loja: loja,
          );
          lojasAEnviar.add(
            LojasService.sanitizarCaminhosImagens(lojaPronta).toJson(),
          );
        }
      }

      final lojasProprias = await LojasService.carregar(cpf);
      for (final lp in lojasProprias) {
        if (!lojasAEnviar.any((m) => m['id'] == lp.id)) {
          final lpPronta =
              await _reconciliador.prepararLojaComUploadsParaServidor(
            ipServidor: ipServidor,
            portaServidor: portaServidor,
            loja: lp,
          );
          lojasAEnviar.add(
            LojasService.sanitizarCaminhosImagens(lpPronta).toJson(),
          );
        }
      }

      final client =
          HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse(
        'http://$ipServidor:$portaServidor/api/sincronizar_perfis_usuario',
      );
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;

      final payload = {
        'cpf': cpf,
        'referencias': referenciasLocais.map((r) => r.toJson()).toList(),
        'lojas': lojasAEnviar,
      };

      req.write(jsonEncode(payload));
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;

        if (dados['sucesso'] == true) {
          final referenciasRecebidas =
              dados['referencias'] as List<dynamic>? ?? [];
          final lojasRecebidas = dados['lojas'] as List<dynamic>? ?? [];
          var houveAlteracao = false;

          for (final lJson in lojasRecebidas) {
            try {
              final loja = Loja.fromJson(lJson as Map<String, dynamic>);
              if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) {
                continue;
              }
              final lojaComImagens =
                  await _reconciliador.sincronizarImagensRemotas(
                ipServidor: ipServidor,
                portaServidor: portaServidor,
                lojaRemota: loja,
                pdvProvider: pdvProvider,
                lojaSincronizada: lojaSincronizada,
              );
              final lojaExistente =
                  await LojasService.carregarLojaPorId(loja.id);
              final lojaConsolidada =
                  LojasService.consolidarLojaComImagensLocais(
                lojaComImagens,
                lojaExistente,
                manterItensAusentes: true,
              );
              await LojasService.salvarLojaIndividual(lojaConsolidada);
              if (pdvProvider != null) {
                await pdvProvider.adicionarOuAtualizarLoja(lojaConsolidada);
              }
              houveAlteracao = true;
            } catch (_) {}
          }

          for (final rJson in referenciasRecebidas) {
            try {
              final ref =
                  ReferenciaLoja.fromJson(rJson as Map<String, dynamic>);
              final jaExiste = referenciasLocais.any((r) => r.lojaId == ref.lojaId);
              if (!jaExiste) {
                await LojasService.adicionarReferencia(cpf, ref);
                houveAlteracao = true;
              }
            } catch (_) {}
          }

          if (houveAlteracao && pdvProvider != null) {
            pdvProvider.notificarMudanca();
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[SincronizadorUsuariosRede] Erro na sincronização de perfis de lojas: $e',
      );
    } finally {
      _sincronizandoPerfisLojas = false;
    }
  }
}
