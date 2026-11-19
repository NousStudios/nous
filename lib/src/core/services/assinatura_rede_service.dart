import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';

/// Serviço de assinatura e verificação criptográfica Ed25519 para mutações
/// trafegadas via rede local / túnel HTTPS, prevenindo falsificação de identidade.
class AssinaturaRedeService {
  AssinaturaRedeService._();

  static String _construirMensagemCanonica(
    Map<String, dynamic> payload,
    String assinanteCpf,
    String assinadoEm,
  ) {
    final copia = Map<String, dynamic>.from(payload)
      ..remove('assinaturaEd25519')
      ..remove('assinanteCpf')
      ..remove('assinadoEm');
    final tipo = copia['tipo']?.toString() ?? '';
    return '$tipo|$assinanteCpf|$assinadoEm|${jsonEncode(copia)}';
  }

  /// Assina um payload de rede com a chave privada Ed25519 do [cpf].
  static Future<Map<String, dynamic>> assinarPayload(
    Map<String, dynamic> payload,
    String cpf,
  ) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.length != 11) return payload;
    try {
      await CriptografiaService.obterOuGerarChavePublica(cpfLimpo);
      final assinadoEm = DateTime.now().toUtc().toIso8601String();
      final msg = _construirMensagemCanonica(payload, cpfLimpo, assinadoEm);
      final sig = await CriptografiaService.assinarDados(
        cpf: cpfLimpo,
        mensagem: msg,
      );
      if (sig == null || sig.isEmpty) return payload;
      return {
        ...payload,
        'assinanteCpf': cpfLimpo,
        'assinadoEm': assinadoEm,
        'assinaturaEd25519': sig,
      };
    } catch (e) {
      debugPrint('[AssinaturaRedeService] Erro ao assinar payload: $e');
      return payload;
    }
  }

  /// Extrai o CPF do autor declarado dentro de um evento `timeline_*` ou `usuario_atualizado`.
  static String _extrairCpfDeclarado(Map<String, dynamic> payload) {
    String norm(dynamic v) => (v?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
    if (payload['publicacao'] is Map) {
      return norm((payload['publicacao'] as Map)['autorCpf']);
    }
    if (payload['comentario'] is Map) {
      return norm((payload['comentario'] as Map)['autorCpf']);
    }
    if (payload['story'] is Map) {
      return norm((payload['story'] as Map)['autorCpf']);
    }
    if (payload['reacao'] is Map) {
      return norm((payload['reacao'] as Map)['usuarioCpf']);
    }
    if (payload['usuario'] is Map) {
      return norm((payload['usuario'] as Map)['cpf']);
    }
    return norm(payload['usuarioCpf']);
  }

  /// Verifica a assinatura Ed25519 do payload recebido no servidor.
  /// Rejeita payloads com assinatura inválida ou tentativa de falsificar CPF de autor.
  static Future<bool> verificarPayload(Map<String, dynamic> payload) async {
    final assinatura = (payload['assinaturaEd25519'] as String? ?? '').trim();
    final assinanteCpf =
        (payload['assinanteCpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final assinadoEm = (payload['assinadoEm'] as String? ?? '').trim();

    if (assinatura.isEmpty || assinanteCpf.isEmpty || assinadoEm.isEmpty) {
      // Compatibilidade com nós legados na LAN sem chave assinante
      return true;
    }

    final cpfDeclarado = _extrairCpfDeclarado(payload);
    if (cpfDeclarado.isNotEmpty && cpfDeclarado != assinanteCpf) {
      debugPrint(
        '[AssinaturaRedeService] Bloqueado: assinante $assinanteCpf tentou agir como $cpfDeclarado.',
      );
      return false;
    }

    final conta = await ContasNousService.buscarPorCpf(assinanteCpf);
    final chavePub = conta?.chavePublica.trim() ?? '';
    if (chavePub.isEmpty) {
      // Conta ainda não sincronizou chave pública; não bloqueia fluxo inicial
      return true;
    }

    final msg = _construirMensagemCanonica(payload, assinanteCpf, assinadoEm);
    final ok = await CriptografiaService.verificarAssinatura(
      mensagem: msg,
      assinaturaHex: assinatura,
      chavePublicaHex: chavePub,
    );
    if (!ok) {
      debugPrint(
        '[AssinaturaRedeService] Assinatura Ed25519 inválida para CPF $assinanteCpf.',
      );
    }
    return ok;
  }
}
