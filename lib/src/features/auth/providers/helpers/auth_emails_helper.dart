import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';

/// Helper responsável pela gestão de e-mails vinculados à conta Nous.
class AuthEmailsHelper {
  AuthEmailsHelper._();

  static Future<({String? erro, UsuarioNous? contaAtualizada})> adicionarEmail({
    required UsuarioNous conta,
    required String email,
    bool verificadoGoogle = false,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return (erro: 'Informe um e-mail válido.', contaAtualizada: null);
    }

    final jaExisteNaConta = conta.emails.any(
      (e) => e.trim().toLowerCase() == emailLimpo,
    );
    if (jaExisteNaConta && !verificadoGoogle) {
      return (
        erro: 'Este e-mail já está nesta conta.',
        contaAtualizada: null,
      );
    }

    final donoAtual = await ContasNousService.buscarCpfDoEmail(emailLimpo);
    if (donoAtual != null && donoAtual != conta.cpf) {
      return (
        erro: 'Este e-mail já está associado a outro CPF.',
        contaAtualizada: null,
      );
    }

    final novosEmails = jaExisteNaConta
        ? conta.emails
        : [...conta.emails, emailLimpo];
    final novosVerificados =
        verificadoGoogle && !conta.emailEstaVerificado(emailLimpo)
            ? [...conta.emailsVerificados, emailLimpo]
            : conta.emailsVerificados;

    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: novosVerificados,
      atualizadoEm: RelogioRedeService.agora().toIso8601String(),
    );
    await ContasNousService.salvar(atualizado);
    propagarUsuarioAtualizado(atualizado);
    return (erro: null, contaAtualizada: atualizado);
  }

  static Future<UsuarioNous?> marcarEmailComoVerificadoGoogle({
    required UsuarioNous conta,
    required String email,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || conta.emailEstaVerificado(emailLimpo)) {
      return null;
    }

    final novosEmails =
        conta.emails.any((e) => e.trim().toLowerCase() == emailLimpo)
            ? conta.emails
            : [...conta.emails, emailLimpo];
    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: [...conta.emailsVerificados, emailLimpo],
      atualizadoEm: RelogioRedeService.agora().toIso8601String(),
    );
    await ContasNousService.salvar(atualizado);
    propagarUsuarioAtualizado(atualizado);
    return atualizado;
  }

  static Future<({UsuarioNous contaAtualizada, String? novoEmailAtivo})>
      removerEmail({
    required UsuarioNous conta,
    required String email,
    required String? emailAtivoAtual,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final emailLimpo = email.trim().toLowerCase();
    final novosEmails = conta.emails
        .where((e) => e.trim().toLowerCase() != emailLimpo)
        .toList();
    final novosVerificados = conta.emailsVerificados
        .where((e) => e.trim().toLowerCase() != emailLimpo)
        .toList();
    final atualizado = conta.copyWith(
      emails: novosEmails,
      emailsVerificados: novosVerificados,
      atualizadoEm: RelogioRedeService.agora().toIso8601String(),
    );
    await ContasNousService.salvar(atualizado);

    final proximoAtivo = emailAtivoAtual?.trim().toLowerCase() == emailLimpo
        ? (novosEmails.isEmpty ? null : novosEmails.first)
        : emailAtivoAtual;

    propagarUsuarioAtualizado(atualizado);
    return (contaAtualizada: atualizado, novoEmailAtivo: proximoAtivo);
  }
}
