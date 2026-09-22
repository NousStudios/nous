import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

class AuthProvider extends ChangeNotifier {
  String _cpf = '';
  String? _errorMessage;
  bool _carregando = false;
  UsuarioNous? _contaAtual;

  String get cpf => _cpf;
  String? get errorMessage => _errorMessage;
  bool get carregando => _carregando;
  UsuarioNous? get contaAtual => _contaAtual;

  bool get isValid => CpfValidator.isValid(_cpf);

  void updateCpf(String rawInput) {
    _cpf = CpfValidator.onlyDigits(rawInput);

    if (_cpf.length < 11) {
      _errorMessage = null;
    } else if (!CpfValidator.isValid(_cpf)) {
      _errorMessage = 'CPF inválido';
    } else {
      _errorMessage = null;
    }

    notifyListeners();
  }

  Future<bool> buscarConta() async {
    if (!isValid) return false;

    _carregando = true;
    notifyListeners();

    final conta = await ContasNousService.buscarPorCpf(_cpf);
    _contaAtual = conta;

    _carregando = false;
    notifyListeners();

    return conta != null;
  }

  Future<void> associarConta({
    required String nome,
    required String dataNascimento,
  }) async {
    final conta = UsuarioNous(
      cpf: _cpf,
      nome: nome.trim(),
      dataNascimento: dataNascimento.trim(),
    );

    await ContasNousService.salvar(conta);

    _contaAtual = conta;
    notifyListeners();
  }

  Future<String?> adicionarEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return 'Nenhuma conta carregada.';

    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return 'Informe um e-mail válido.';
    }
    if (conta.emails.contains(emailLimpo)) {
      return 'Este e-mail já está nesta conta.';
    }

    final donoAtual = await ContasNousService.buscarCpfDoEmail(emailLimpo);
    if (donoAtual != null && donoAtual != conta.cpf) {
      return 'Este e-mail já está associado a outro CPF.';
    }

    final atualizado = conta.copyWith(emails: [...conta.emails, emailLimpo]);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    notifyListeners();
    return null;
  }

  Future<void> removerEmail(String email) async {
    final conta = _contaAtual;
    if (conta == null) return;

    final novosEmails = conta.emails.where((e) => e != email).toList();
    final atualizado = conta.copyWith(emails: novosEmails);
    await ContasNousService.salvar(atualizado);
    _contaAtual = atualizado;
    notifyListeners();
  }

  Future<void> excluirConta() async {
    final conta = _contaAtual;
    if (conta == null) return;
    await ContasNousService.excluir(conta.cpf);
    sair();
  }

  void sair() {
    _cpf = '';
    _errorMessage = null;
    _contaAtual = null;
    notifyListeners();
  }
}