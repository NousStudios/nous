import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

// ChangeNotifier é a classe base do Flutter para "algo que guarda estado e
// avisa quem está ouvindo quando esse estado muda" — o mesmo padrão já
// usado no AuthProvider. Aqui guardamos TODAS as lojas (ou outras funções,
// no futuro) que o usuário cadastrou no fluxo do PDV.
class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];

  int _proximoId = 0;

  List<Loja> get lojas => List.unmodifiable(_lojas);

  bool get temLojaSalva => _lojas.isNotEmpty;

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
      id: 'loja_${_proximoId++}',
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
  }

  /// Guarda as listas de Categorias/Itens/Grupos de Componentes da aba
  /// "Loja" dentro da loja correspondente. É assim que esses dados
  /// deixam de morar só na memória da tela DadosPerfilView e passam a
  /// sobreviver quando o usuário sai e volta pra tela.
  void atualizarListasLoja(
    String id, {
    List<CategoriaLoja>? categorias,
    List<ItemLoja>? itens,
    List<GrupoComponentesLoja>? gruposComponentes,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
    );

    notifyListeners();
  }
}