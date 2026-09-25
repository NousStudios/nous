import 'package:flutter/foundation.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';

class NotificacoesProvider extends ChangeNotifier {
  String? _cpfAtual;
  List<ConviteLoja> _convites = [];

  List<ConviteLoja> get convites => List.unmodifiable(_convites);

  int get quantidadePendentes => _convites.length;

  bool get temConvitesPendentes => _convites.isNotEmpty;

  Future<void> carregarParaCpf(String cpf) async {
    _cpfAtual = cpf;
    _convites = await ConvitesService.carregar(cpf);
    notifyListeners();
  }

  Future<void> limpar() async {
    _cpfAtual = null;
    _convites = [];
    notifyListeners();
  }

  Future<void> enviarConvite(ConviteLoja convite) async {
    await ConvitesService.adicionar(convite.cpfConvidado, convite);
  }

  Future<void> aceitar(String conviteId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    await ConvitesService.remover(cpf, conviteId);
    _convites = _convites.where((c) => c.id != conviteId).toList();
    notifyListeners();
  }

  Future<void> recusar(String conviteId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    await ConvitesService.remover(cpf, conviteId);
    _convites = _convites.where((c) => c.id != conviteId).toList();
    notifyListeners();
  }
}