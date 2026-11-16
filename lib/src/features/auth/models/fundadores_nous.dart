import 'package:nous/src/features/auth/models/usuario_nous.dart';

/// Registro soberano dos Membros Fundadores do Nous, reconhecidos
/// automaticamente pelo próprio sistema com selo de verificação.
class FundadoresNous {
  FundadoresNous._();

  /// CPFs normalizados (somente dígitos) dos membros fundadores.
  static const Set<String> cpfsFundadores = {
    '47192956813', // taddeoleonardo
  };

  static const String idSistemaFundador = 'sistema_nous';
  static const String nomeSeloFundador = 'Sistema Nous • Membro Fundador';

  static String _limparCpf(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

  static bool ehFundador(String cpf) {
    final limpo = _limparCpf(cpf);
    return limpo.isNotEmpty && cpfsFundadores.contains(limpo);
  }

  /// Garante que um membro fundador possua o selo oficial de verificação
  /// emitido pelo próprio sistema, preservando demais validações comunitárias.
  static UsuarioNous aplicarSeloFundadorSeAplicavel(UsuarioNous usuario) {
    if (!ehFundador(usuario.cpf)) return usuario;

    final dataPadrao = usuario.criadoEm.trim().isNotEmpty
        ? usuario.criadoEm.trim()
        : '2026-01-01T00:00:00.000';

    final validacoesAtualizadas = <Map<String, String>>[
      for (final v in usuario.validacoes) Map<String, String>.from(v),
    ];

    final jaTemSeloSistema = validacoesAtualizadas.any(
      (v) => (v['cpf'] ?? '').trim() == idSistemaFundador,
    );

    if (!jaTemSeloSistema) {
      validacoesAtualizadas.insert(0, {
        'cpf': idSistemaFundador,
        'nome': nomeSeloFundador,
        'dataHora': dataPadrao,
        'assinatura': 'FUNDADOR_NOUS',
      });
    }

    return usuario.copyWith(
      verificado: true,
      validadoPorCpf: usuario.validadoPorCpf.trim().isNotEmpty
          ? usuario.validadoPorCpf
          : idSistemaFundador,
      validadoPorNome: usuario.validadoPorNome.trim().isNotEmpty
          ? usuario.validadoPorNome
          : nomeSeloFundador,
      validadoEm: usuario.validadoEm.trim().isNotEmpty
          ? usuario.validadoEm
          : dataPadrao,
      validacoes: validacoesAtualizadas,
    );
  }
}
