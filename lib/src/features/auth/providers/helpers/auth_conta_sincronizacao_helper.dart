import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Helper responsável por consolidação local, chaves criptográficas,
/// sincronização com o balcão na rede local e exclusão de conta.
class AuthContaSincronizacaoHelper {
  AuthContaSincronizacaoHelper._();

  static Future<UsuarioNous?> prepararContaLocal(String cpf) async {
    var conta = await ContasNousService.buscarPorCpf(cpf);
    conta ??= await consolidarContaLocalSeExistir(cpf);
    if (conta == null) return null;

    final contaSegura = await sanitizarFotoLogoLoja(conta, cpf);
    return garantirChavesCriptografia(contaSegura, salvarSeAlterar: true);
  }

  static Future<UsuarioNous?> consolidarContaLocalSeExistir(String cpf) async {
    if (await ContasExcluidasService.estaExcluido(cpf)) return null;
    try {
      final dadosAuto = await DadosLocaisService.buscarPorDocumento(cpf);
      if (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty) {
        final conta = UsuarioNous(
          cpf: cpf,
          nome: dadosAuto.nome.trim(),
          dataNascimento: dadosAuto.dataNascimento,
          foto: dadosAuto.foto,
        );
        await ContasNousService.salvar(conta);
        debugPrint(
          '[AuthProvider] Conta consolidada automaticamente de dados locais para CPF $cpf (${conta.nome})',
        );
        return conta;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Erro ao consolidar dados locais: $e');
    }
    return null;
  }

  static Future<UsuarioNous> sanitizarFotoLogoLoja(
    UsuarioNous conta,
    String cpf,
  ) async {
    if (conta.foto.isEmpty) return conta;
    try {
      final lojasDoUsuario = await LojasService.carregar(cpf);
      final logos = lojasDoUsuario
          .map((l) => l.logo.trim())
          .where((logo) => logo.isNotEmpty)
          .toSet();
      if (logos.contains(conta.foto.trim())) {
        final atualizada = conta.copyWith(foto: '');
        await ContasNousService.salvar(atualizada);
        return atualizada;
      }
    } catch (_) {}
    return conta;
  }

  static Future<UsuarioNous> garantirChavesCriptografia(
    UsuarioNous conta, {
    bool salvarSeAlterar = false,
  }) async {
    try {
      final chavePub =
          await CriptografiaService.obterOuGerarChavePublica(conta.cpf);
      final chaveTroca =
          await CriptografiaService.obterOuGerarChaveTroca(conta.cpf);
      var atualizada = conta;
      var precisaSalvar = false;
      if (chavePub.isNotEmpty && atualizada.chavePublica != chavePub) {
        atualizada = atualizada.copyWith(chavePublica: chavePub);
        precisaSalvar = true;
      }
      if (chaveTroca.isNotEmpty && atualizada.chaveTrocaPublica != chaveTroca) {
        atualizada = atualizada.copyWith(chaveTrocaPublica: chaveTroca);
        precisaSalvar = true;
      }
      if (salvarSeAlterar && precisaSalvar) {
        await ContasNousService.salvar(atualizada);
      }
      return atualizada;
    } catch (e) {
      debugPrint(
        '[AuthProvider] Erro ao sincronizar chaves de criptografia: $e',
      );
      return conta;
    }
  }

  static Future<UsuarioNous?> buscarUsuarioRemotoESalvar(String cpf) async {
    try {
      final remoto = await ClienteRedeLocal().buscarUsuarioRemoto(cpf);
      if (remoto != null) {
        await ContasNousService.salvar(remoto);
        debugPrint(
          '[AuthProvider] Conta recuperada do balcão Wi-Fi para CPF $cpf (${remoto.nome})',
        );
        return remoto;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Erro ao buscar usuário remoto: $e');
    }
    return null;
  }

  static Future<void> mesclarComRemotoEmBackground({
    required String cpf,
    required UsuarioNous? Function() obterContaAtual,
    required void Function(UsuarioNous) aoAtualizar,
  }) async {
    try {
      final remoto = await ClienteRedeLocal().buscarUsuarioRemoto(cpf);
      final atual = obterContaAtual();
      if (remoto != null && atual != null && atual.cpf == cpf) {
        final contaAtualizada = atual.mesclarCom(remoto, priorizarOutro: true);
        await ContasNousService.salvar(contaAtualizada);
        ClienteRedeLocal().atualizarIdentidadeUsuario(
          cpf: contaAtualizada.cpf,
          nome: contaAtualizada.nome,
          apelido: contaAtualizada.apelido,
          foto: contaAtualizada.foto,
        );
        aoAtualizar(contaAtualizada);
      }
    } catch (_) {}
  }

  static Future<void> ativarSessaoLocal(UsuarioNous conta) async {
    await ThemeController.carregarTemaDoUsuario(conta.cpf);
    ClienteRedeLocal().atualizarIdentidadeUsuario(
      cpf: conta.cpf,
      nome: conta.nome,
      apelido: conta.apelido,
      foto: conta.foto,
    );
    ServidorRedeLocal().atualizarOperadorBalcao(conta);
  }

  static void propagarUsuarioNaRede(UsuarioNous usuario) {
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarUsuario(usuario);
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'usuario_atualizado',
        'usuario': usuario.toJson(),
      });
    }
  }

  static String resolverFotoPorCpf({
    required String cpf,
    required UsuarioNous? contaAtual,
    required Map<String, String> fotosPorCpf,
  }) {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (contaAtual != null) {
      final meuCpfLimpo = contaAtual.cpf.replaceAll(RegExp(r'\D'), '');
      if ((contaAtual.cpf == cpf ||
              (cpfLimpo.isNotEmpty && meuCpfLimpo == cpfLimpo)) &&
          contaAtual.fotoExibicao.trim().isNotEmpty) {
        return contaAtual.fotoExibicao.trim();
      }
    }
    if (fotosPorCpf.containsKey(cpf) && fotosPorCpf[cpf]!.isNotEmpty) {
      return fotosPorCpf[cpf]!;
    }
    if (cpfLimpo.isNotEmpty) {
      for (final entry in fotosPorCpf.entries) {
        if (entry.key.replaceAll(RegExp(r'\D'), '') == cpfLimpo &&
            entry.value.isNotEmpty) {
          return entry.value;
        }
      }
    }
    return '';
  }

  static UsuarioNous montarNovaContaCompleta({
    required String cpf,
    required String nome,
    required String apelido,
    required String nomeDeUsuario,
    required String foto,
    required String biografia,
    required List<String> dadosPrivados,
    required String termosAceitosVersao,
    required String termosAceitosEm,
  }) {
    final apelidoLimpo =
        apelido.trim().isNotEmpty ? apelido.trim() : nome.trim();
    final usernameLimpo = nomeDeUsuario
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('@', '');
    final hojeIso = DateTime.now().toIso8601String();

    return UsuarioNous(
      cpf: cpf,
      nome: nome.trim(),
      apelido: apelidoLimpo,
      nomeDeUsuario: usernameLimpo,
      dataNascimento: '',
      foto: foto.trim(),
      fotoPublica: foto.trim(),
      biografia: biografia.trim(),
      dadosPrivados: dadosPrivados,
      criadoEm: hojeIso,
      validadoPorNome: 'Rede Soberana Nous',
      validadoEm: hojeIso,
      verificado: true,
      termosAceitosVersao: termosAceitosVersao,
      termosAceitosEm: termosAceitosEm,
    );
  }

  static Future<void> excluirContaLocalERede({
    required String cpfLimpo,
    required UsuarioNous? contaExistente,
    required String chaveUltimoCpf,
  }) async {
    final regExcluida = contaExistente != null
        ? await ContasExcluidasService.registrarExclusao(contaExistente)
        : null;

    await ContasNousService.excluir(cpfLimpo);

    try {
      final coletiva =
          await LojasService.carregarLojaPorId('loja_nous_coletiva');
      if (coletiva != null) {
        final membrosAtualizados = coletiva.membros
            .where((m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpfLimpo)
            .toList();
        if (membrosAtualizados.length != coletiva.membros.length) {
          await LojasService.salvarLojaIndividual(
            coletiva.copyWith(membros: membrosAtualizados),
          );
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getString(chaveUltimoCpf);
    if (ultimo != null && ultimo.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
      await prefs.remove(chaveUltimoCpf);
    }

    final evento = <String, dynamic>{
      'tipo': 'usuario_nous_excluido',
      'cpf': cpfLimpo,
      if (regExcluida != null) 'registro': regExcluida.toJson(),
    };
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarEventoWs(evento);
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos(evento);
    }
  }
}
