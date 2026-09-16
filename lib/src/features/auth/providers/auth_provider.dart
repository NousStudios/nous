import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

// ChangeNotifier é a classe base do Flutter para "algo que guarda estado e
// avisa quem está ouvindo quando esse estado muda". O Provider usa isso por
// baixo dos panos.
class AuthProvider extends ChangeNotifier {
  String _cpf = ''; // CPF só com números, sem máscara
  String? _errorMessage; // null = sem erro
  bool _isCheckingWithServer = false; // reservado para a ETAPA 2 (futuro)

  String get cpf => _cpf;
  String? get errorMessage => _errorMessage;
  bool get isCheckingWithServer => _isCheckingWithServer;

  // O campo é considerado "válido" quando tem os 11 dígitos E passou na
  // validação matemática local.
  bool get isValid => CpfValidator.isValid(_cpf);

  /// Chamado toda vez que o usuário digita algo no campo de CPF.
  void updateCpf(String rawInput) {
    _cpf = CpfValidator.onlyDigits(rawInput);

    // Só mostramos erro quando o usuário já terminou de digitar os 11
    // dígitos. Antes disso, mostrar "CPF inválido" enquanto a pessoa ainda
    // está no meio da digitação seria confuso e irritante.
    if (_cpf.length < 11) {
      _errorMessage = null;
    } else if (!CpfValidator.isValid(_cpf)) {
      _errorMessage = 'CPF inválido';
    } else {
      _errorMessage = null;
    }

    // notifyListeners() avisa todos os widgets que estão "ouvindo" este
    // provider (via context.watch ou Consumer) para se redesenharem agora,
    // refletindo o novo estado.
    notifyListeners();
  }

  /// Placeholder para a ETAPA 2 (checagem real com um backend/servidor).
  /// Ainda não faz nada de verdade — só deixa o "encaixe" pronto para quando
  /// esse backend existir.
  Future<void> submitCpf() async {
    if (!isValid) return;

    _isCheckingWithServer = true;
    notifyListeners();

    // todo: no futuro, chamar aqui um serviço de backend próprio do Nous
    // (não a Receita Federal diretamente) que verifica o CPF e decide se é
    // cadastro novo ou login existente.

    _isCheckingWithServer = false;
    notifyListeners();
  }
}