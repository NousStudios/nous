// "Molde" (modelo de dados) que representa UMA loja cadastrada pelo
// usuário. Antes, o PdvProvider guardava os dados de uma loja direto como
// campos soltos (nome, cnpj, etc.). Agora que o usuário pode ter VÁRIAS
// lojas, precisamos de uma "caixinha" para cada loja individual, e o
// PdvProvider vai guardar uma LISTA dessas caixinhas.
//
// Usamos uma classe "imutável" (todos os campos são "final", ou seja,
// não mudam depois de criados) porque isso deixa o código mais previsível:
// para "editar" uma loja no futuro, vamos criar uma Loja nova com os dados
// atualizados e substituir a antiga na lista, em vez de alterar os campos
// dela escondido por aí.
class Loja {
  // Identificador único de cada loja. É o que permite ao app saber
  // exatamente QUAL loja o usuário está vendo ou querendo excluir, mesmo
  // que duas lojas tenham o mesmo nome. Gerado automaticamente quando a
  // loja é criada (veja o PdvProvider).
  final String id;

  final String nome;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String categorias;
  final String tags;

  const Loja({
    required this.id,
    required this.nome,
    required this.cnpj,
    required this.telefone,
    required this.endereco,
    required this.numero,
    required this.email,
    required this.categorias,
    required this.tags,
  });
}