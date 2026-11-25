import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';

/// Helper coeso para cifragem E2EE, assinatura Ed25519, validação de origem
/// e geração segura de resumos de mensagens do chat.
class ChatMensagemSegurancaHelper {
  /// Cifra a mensagem via E2EE (quando aplicável) e assina o payload com Ed25519
  /// caso ainda não possua assinatura.
  static Future<MensagemChat> cifrarEAssinarMensagem(
    MensagemChat mensagem,
  ) async {
    MensagemChat mensagemPersistida =
        await ChatE2eeService.cifrarMensagemSeAplicavel(mensagem);

    if (mensagemPersistida.assinatura.isEmpty) {
      final cpfLimpo =
          ChatRepositorioSqlite.normalizarCpf(mensagemPersistida.remetenteId);
      if (cpfLimpo.length == 11) {
        final payloadParaAssinar =
            '${mensagemPersistida.id}:${mensagemPersistida.conversaId}:${mensagemPersistida.remetenteId}:${mensagemPersistida.texto}:${mensagemPersistida.dataHora.toIso8601String()}';
        try {
          final sig = await CriptografiaService.assinarDados(
            cpf: cpfLimpo,
            mensagem: payloadParaAssinar,
          );
          if (sig != null && sig.isNotEmpty) {
            mensagemPersistida = mensagemPersistida.copyWith(assinatura: sig);
          }
        } catch (_) {}
      }
    }

    return mensagemPersistida;
  }

  /// Valida assinatura Ed25519 (auditoria) e permissão soberana de envio
  /// para mensagens recebidas pela rede. Retorna `false` se o envio for bloqueado.
  static Future<bool> validarOrigemEPermissaoRede(
    MensagemChat mensagem, {
    required String meuCpf,
  }) async {
    if (mensagem.assinatura.isNotEmpty) {
      final cpfRemNorm =
          ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
      if (cpfRemNorm.length == 11) {
        final contaRem = await ContasNousService.buscarPorCpf(cpfRemNorm);
        if (contaRem != null && contaRem.chavePublica.isNotEmpty) {
          final payload =
              '${mensagem.id}:${mensagem.conversaId}:${mensagem.remetenteId}:${mensagem.texto}:${mensagem.dataHora.toIso8601String()}';
          final valida = await CriptografiaService.verificarAssinatura(
            mensagem: payload,
            assinaturaHex: mensagem.assinatura,
            chavePublicaHex: contaRem.chavePublica,
          );
          if (!valida) {
            debugPrint(
              '[ChatMensagensService] AVISO AUDITORIA: Assinatura digital não verificada para mensagem ${mensagem.id}',
            );
          }
        }
      }
    }

    if (!mensagem.conversaId.startsWith('grupo_') &&
        !mensagem.conversaId.startsWith('loja_') &&
        !mensagem.conversaId.startsWith('topico_')) {
      final cpfDestNorm =
          ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);
      if (cpfDestNorm.length == 11 && cpfDestNorm == meuCpf) {
        final contaDest = await ContasNousService.buscarPorCpf(cpfDestNorm);
        if (contaDest != null &&
            contaDest.quemPodeEnviarMensagens == 'apenas_seguidos') {
          final cpfRemNorm =
              ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId);
          if (!contaDest.estaSeguindo(cpfRemNorm)) {
            debugPrint(
              '[ChatMensagensService] Bloqueada: $cpfRemNorm não é seguido por $cpfDestNorm',
            );
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Gera o resumo textual para exibição na lista de conversas, decifrando
  /// temporariamente quando necessário para não expor o envelope cifrado.
  static Future<String> gerarResumoSeguro(
    MensagemChat mensagem, {
    required String meuCpf,
  }) async {
    MensagemChat msgParaResumo = mensagem;
    if (CriptografiaService.ehTextoCifrado(mensagem.texto) &&
        meuCpf.length == 11) {
      msgParaResumo = await ChatE2eeService.decifrarMensagemSeAplicavel(
        mensagem,
        cpfVisualizador: meuCpf,
      );
    }
    final resumoBruto = ChatMediaService.gerarResumoMensagem(msgParaResumo);
    return CriptografiaService.ehTextoCifrado(resumoBruto)
        ? '[Mensagem Cifrada Protegida]'
        : resumoBruto;
  }
}
