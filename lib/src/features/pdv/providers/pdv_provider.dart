import 'package:flutter/foundation.dart';

// ChangeNotifier é a classe base do Flutter para "algo que guarda estado e
// avisa quem está ouvindo quando esse estado muda" — o mesmo padrão já
// usado no AuthProvider. Aqui guardamos os dados da loja (ou função) que o
// usuário cadastrou no fluxo do PDV.
//
// Por enquanto só guardamos UMA loja (a "Loja Padrão"). No futuro, quando o
// app permitir vários perfis por usuário (Motoboy, Motorista, Professor,
// mais de uma loja, etc.), isso provavelmente vai virar uma Lista de lojas
// em vez de campos soltos como estão agora.
class PdvProvider extends ChangeNotifier {
  String _nome = '';
  String _cnpj = '';
  String _telefone = '';
  String _endereco = '';
  String _numero = '';
  String _email = '';
  String _categorias = '';
  String _tags = '';

  String get nome => _nome;
  String get cnpj => _cnpj;
  String get telefone => _telefone;
  String get endereco => _endereco;
  String get numero => _numero;
  String get email => _email;
  String get categorias => _categorias;
  String get tags => _tags;

  // true assim que existir uma loja salva (ou seja, assim que o nome não
  // estiver mais vazio). É essa "bandeirinha" que a tela "Meus Perfis" vai
  // usar para decidir se mostra o card da loja ou não.
  bool get temLojaSalva => _nome.isNotEmpty;

  /// Chamado ao clicar em "Cadastrar" na tela de Cadastrar Loja. Guarda
  /// todos os dados do formulário e avisa quem estiver "ouvindo" este
  /// provider (a tela de Meus Perfis, por exemplo) para se redesenhar já
  /// mostrando o card novo.
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
    _nome = nome;
    _cnpj = cnpj;
    _telefone = telefone;
    _endereco = endereco;
    _numero = numero;
    _email = email;
    _categorias = categorias;
    _tags = tags;

    notifyListeners();
  }

  /// Apaga os dados da loja salva. Ainda não é chamado de nenhum lugar —
  /// fica pronto para quando conectarmos o botão "Excluir Loja" da tela de
  /// Dados do Perfil numa próxima etapa.
  void excluirLoja() {
    _nome = '';
    _cnpj = '';
    _telefone = '';
    _endereco = '';
    _numero = '';
    _email = '';
    _categorias = '';
    _tags = '';

    notifyListeners();
  }
}