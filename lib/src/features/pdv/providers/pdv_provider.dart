import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];

  String? _cpfAtual;

  List<Loja> get lojas => List.unmodifiable(_lojas);

  bool get temLojaSalva => _lojas.isNotEmpty;

  Future<void> entrarComCpf(String cpf) async {
    _cpfAtual = cpf;
    final lojasSalvas = await LojasService.carregar(cpf);
    _lojas
      ..clear()
      ..addAll(lojasSalvas);
    notifyListeners();
  }

  void entrarComoVisitante() {
    _cpfAtual = null;
    _lojas.clear();
    notifyListeners();
  }

  void _persistir() {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    LojasService.salvar(cpf, _lojas);
  }

  void salvarLoja({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    required String categorias,
    required String tags,
  }) {
    final novaLoja = Loja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      categorias: categorias,
      tags: tags,
    );

    _lojas.add(novaLoja);
    notifyListeners();
    _persistir();
  }

  Loja? buscarPorId(String id) {
    for (final loja in _lojas) {
      if (loja.id == id) return loja;
    }
    return null;
  }

  void excluirLoja(String id) {
    _lojas.removeWhere((loja) => loja.id == id);
    notifyListeners();
    _persistir();
  }

  void atualizarListasLoja(
    String id, {
    List<CategoriaLoja>? categorias,
    List<ItemLoja>? itens,
    List<GrupoComponentesLoja>? gruposComponentes,
    List<Cliente>? clientes,
    List<PedidoLoja>? pedidos,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      pedidosLoja: pedidos,
    );

    notifyListeners();
    _persistir();
  }
}