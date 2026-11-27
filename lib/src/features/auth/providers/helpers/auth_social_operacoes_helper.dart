import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Helper com operações sociais da conta Nous (validação de identidade e seguir/deixar de seguir).
class AuthSocialOperacoesHelper {
  AuthSocialOperacoesHelper._();

  static Future<UsuarioNous?> validarIdentidadeUsuario({
    required UsuarioNous validador,
    required UsuarioNous alvo,
    required UsuarioNous? Function(String cpf) buscarContaPorCpf,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    if (!validador.possuiValidacao) return null;

    final cpfValidador = CpfValidator.onlyDigits(validador.cpf);
    final cpfAlvo = CpfValidator.onlyDigits(alvo.cpf);
    if (cpfValidador.isEmpty || cpfAlvo.isEmpty || cpfValidador == cpfAlvo) {
      return null;
    }

    final alvoVivo = buscarContaPorCpf(cpfAlvo) ?? alvo;
    if (alvoVivo.jaValidadoPor(cpfValidador)) {
      return alvoVivo;
    }

    final agoraIso = DateTime.now().toIso8601String();
    final assinatura = await CriptografiaService.assinarDados(
          cpf: cpfValidador,
          mensagem: 'validar_identidade:$cpfAlvo:$cpfValidador:$agoraIso',
        ) ??
        '';

    final novaValidacao = <String, String>{
      'cpf': cpfValidador,
      'nome': validador.nome.isNotEmpty
          ? validador.nome
          : validador.nomeExibicao,
      'dataHora': agoraIso,
      'assinatura': assinatura,
    };

    final listaAtualizada = List<Map<String, String>>.from(
      alvoVivo.validacoesOrdenadas,
    )..add(novaValidacao);

    final primeiro = listaAtualizada.first;
    final alvoAtualizado = alvoVivo.copyWith(
      verificado: true,
      validacoes: listaAtualizada,
      validadoPorCpf: alvoVivo.validadoPorCpf.isNotEmpty
          ? alvoVivo.validadoPorCpf
          : (primeiro['cpf'] ?? cpfValidador),
      validadoPorNome: alvoVivo.validadoPorNome.isNotEmpty
          ? alvoVivo.validadoPorNome
          : (primeiro['nome'] ?? novaValidacao['nome']!),
      validadoEm: alvoVivo.validadoEm.isNotEmpty
          ? alvoVivo.validadoEm
          : (primeiro['dataHora'] ?? agoraIso),
      atualizadoEm: RelogioRedeService.agora().toIso8601String(),
    );

    await ContasNousService.salvar(alvoAtualizado);
    propagarUsuarioAtualizado(alvoAtualizado);
    return alvoAtualizado;
  }

  static Future<UsuarioNous> alternarSeguir({
    required UsuarioNous conta,
    required String cpfAlvo,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final alvoLimpo = cpfAlvo.replaceAll(RegExp(r'\D'), '');
    final novaListaSeguindo = List<String>.from(conta.seguindo);

    final jaSegue = novaListaSeguindo
        .any((s) => s.replaceAll(RegExp(r'\D'), '') == alvoLimpo);
    if (jaSegue) {
      novaListaSeguindo
          .removeWhere((s) => s.replaceAll(RegExp(r'\D'), '') == alvoLimpo);
    } else {
      novaListaSeguindo.add(alvoLimpo);
    }

    final atualizado = conta.copyWith(
      seguindo: novaListaSeguindo,
      atualizadoEm: RelogioRedeService.agora().toIso8601String(),
    );
    await ContasNousService.salvar(atualizado);

    final meuCpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
    final eventoSeguir = {
      'tipo': 'usuario_seguir_atualizado',
      'autorCpf': meuCpfLimpo,
      'alvoCpf': alvoLimpo,
      'seguindo': !jaSegue,
    };
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos(eventoSeguir);
    } else if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarEventoWs(eventoSeguir);
    }

    final contaAlvo = await ContasNousService.buscarPorCpf(alvoLimpo);
    if (contaAlvo != null) {
      final seguidoresAlvo = List<String>.from(contaAlvo.seguidores);
      if (jaSegue) {
        seguidoresAlvo
            .removeWhere((s) => s.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo);
      } else {
        if (!seguidoresAlvo.contains(meuCpfLimpo)) {
          seguidoresAlvo.add(meuCpfLimpo);
        }
      }
      final alvoAtualizado = contaAlvo.copyWith(
        seguidores: seguidoresAlvo,
        atualizadoEm: RelogioRedeService.agora().toIso8601String(),
      );
      await ContasNousService.salvar(alvoAtualizado);
      if (!jaSegue) {
        await TimelineService.emitirNotificacaoSocial(
          destinatarioCpf: alvoLimpo,
          autorCpf: conta.cpf,
          autorNome: conta.nomeExibicao,
          autorFoto: conta.fotoExibicao,
          tipo: TipoNotificacaoSocial.novoSeguidor,
          resumo: '${conta.nomeExibicao} começou a seguir você.',
        );
      }
    }

    propagarUsuarioAtualizado(atualizado);
    return atualizado;
  }
}
