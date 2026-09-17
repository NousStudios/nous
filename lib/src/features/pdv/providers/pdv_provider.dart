import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

// ChangeNotifier é a classe base do Flutter para "algo que guarda estado e
// avisa quem está ouvindo quando esse estado muda" — o mesmo padrão já
// usado no AuthProvider. Aqui guardamos TODAS as lojas (ou outras funções,
// no futuro) que o usuário cadastrou no fluxo do PDV.
//
// Antes, este provider guardava os dados de UMA loja só, como campos
// soltos (nome, cnpj, etc.). Agora ele guarda uma LISTA de Loja, para o
// usuário poder ter quantas quiser.
class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];

  // Contador simples, só para gerar um "id" diferente para cada loja nova
  // (0, 1, 2, 3...). Não precisa ser sofisticado: o importante é que cada
  // loja cadastrada NESTA sessão do app tenha um id diferente das outras.
  int _proximoId = 0;

  // UnmodifiableListView: devolve a lista de lojas para quem pedir, mas
  // "travada" contra alterações por fora (ninguém de fora consegue dar
  // lojas.add(...) ou lojas.remove(...) diretamente). Isso obriga todo
  // mundo a passar pelos métodos salvarLoja()/excluirLoja() abaixo, que são
  // os únicos que sabem chamar notifyListeners() corretamente.
  List<Loja> get lojas => List.unmodifiable(_lojas);

  // true assim que existir pelo menos uma loja salva. É essa "bandeirinha"
  // que a tela "Meus Perfis" vai usar para decidir se mostra a seção de
  // cards ou não.
  bool get temLojaSalva => _lojas.isNotEmpty;

  /// Chamado ao clicar em "Cadastrar" na tela de Cadastrar Loja. Cria uma
  /// Loja nova (com um id novo) e ADICIONA ela à lista — as lojas
  /// cadastradas antes continuam intactas. Avisa quem estiver "ouvindo"
  /// este provider (a tela de Meus Perfis, por exemplo) para se redesenhar
  /// já mostrando o card novo.
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

  /// Devolve a loja com o id informado, ou null se não existir (por
  /// exemplo, se ela já tiver sido excluída). Usado pela tela de Dados do
  /// Perfil para saber qual loja mostrar.
  Loja? buscarPorId(String id) {
    for (final loja in _lojas) {
      if (loja.id == id) return loja;
    }
    return null;
  }

  /// Remove APENAS a loja com o id informado, mantendo todas as outras.
  /// Antes, excluirLoja() apagava os únicos dados que existiam (não havia
  /// lista); agora ele precisa saber qual das várias lojas remover.
  void excluirLoja(String id) {
    _lojas.removeWhere((loja) => loja.id == id);
    notifyListeners();
  }
}