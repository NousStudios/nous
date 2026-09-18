// Este arquivo guarda os "moldes" de dados (modelos) de tudo que existe
// dentro da aba Loja: Itens, Categorias e Grupos de Componentes.
//
// Seguimos o mesmo padrão já usado no modelo Loja: cada classe é
// IMUTÁVEL (todos os campos são "final", ou seja, depois de criado o
// objeto não muda mais) e tem um "id" próprio, único. Se algum campo
// precisar mudar (por exemplo, editar o nome de um item depois), a
// gente cria um objeto NOVO com o campo atualizado, usando o método
// copyWith — nunca alteramos o objeto antigo por dentro.
//
// Por que fazer assim, em vez de só mudar o campo direto? Porque isso
// deixa bem claro, no código, todo lugar em que um dado mudou (sempre
// que aparece um "objeto novo" sendo criado), o que facilita muito
// achar bugs no futuro, e é o mesmo padrão que o PdvProvider já usa
// para a lista de Lojas.

// Um Item pode ser um Produto (algo físico) ou um Serviço (algo que
// não se entrega, como um corte de cabelo). Usamos um "enum" (uma
// lista fechada de opções possíveis) em vez de um simples texto,
// porque isso IMPEDE que alguém digite um valor errado por engano
// (ex: "produt" com erro de digitação) — só existem essas duas opções.
enum TipoItemLoja { produto, servico }

// Gera um identificador único e simples, baseado no horário exato em
// que o objeto foi criado (em milissegundos). Como é bem improvável
// duas coisas serem criadas no EXATO mesmo milissegundo, isso funciona
// bem como id único para este estágio do projeto (sem backend ainda).
String _gerarIdUnico() => DateTime.now().millisecondsSinceEpoch.toString();

// Representa um Item da Loja (o que aparece nos cards da seção
// "Itens"), com todos os campos vistos no popup "Novo Item" do
// protótipo.
class ItemLoja {
  final String id;
  final String nome;
  final TipoItemLoja? tipo;

  // Guardamos só o ID da categoria/grupo escolhido (não o objeto
  // inteiro). Isso evita duplicar dados: se o nome de uma categoria
  // mudar depois, não precisamos "avisar" todos os itens que a usam —
  // eles continuam apontando para o mesmo id, e a busca pelo nome
  // atualizado é feita na hora de exibir na tela.
  final String? categoriaId;
  final String? grupoComponentesId;

  // Cada variante, por enquanto, é só um nome simples (ex: "Tamanho P",
  // "Cor Azul"). Poderemos evoluir isso para algo mais completo (com
  // preço próprio, por exemplo) quando isso for pedido.
  final List<String> variantes;

  final String descricao;
  final bool possuiDelivery;
  final String freteGratisAte;
  final String valorPorKm;

  const ItemLoja({
    required this.id,
    required this.nome,
    this.tipo,
    this.categoriaId,
    this.grupoComponentesId,
    this.variantes = const [],
    this.descricao = '',
    this.possuiDelivery = false,
    this.freteGratisAte = '',
    this.valorPorKm = '',
  });

  // Fábrica usada quando o usuário está CRIANDO um item novo (não tem
  // id ainda, porque nunca existiu antes) — o id é gerado aqui, uma
  // única vez, na criação.
  factory ItemLoja.novo({
    required String nome,
    TipoItemLoja? tipo,
    String? categoriaId,
    String? grupoComponentesId,
    List<String> variantes = const [],
    String descricao = '',
    bool possuiDelivery = false,
    String freteGratisAte = '',
    String valorPorKm = '',
  }) {
    return ItemLoja(
      id: _gerarIdUnico(),
      nome: nome,
      tipo: tipo,
      categoriaId: categoriaId,
      grupoComponentesId: grupoComponentesId,
      variantes: variantes,
      descricao: descricao,
      possuiDelivery: possuiDelivery,
      freteGratisAte: freteGratisAte,
      valorPorKm: valorPorKm,
    );
  }

  // Cria uma CÓPIA deste item, com os campos passados substituídos
  // pelos novos valores (e o resto continua igual). Usado quando o
  // usuário edita um item já existente.
  ItemLoja copyWith({
    String? nome,
    TipoItemLoja? tipo,
    String? categoriaId,
    String? grupoComponentesId,
    List<String>? variantes,
    String? descricao,
    bool? possuiDelivery,
    String? freteGratisAte,
    String? valorPorKm,
  }) {
    return ItemLoja(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      grupoComponentesId: grupoComponentesId ?? this.grupoComponentesId,
      variantes: variantes ?? this.variantes,
      descricao: descricao ?? this.descricao,
      possuiDelivery: possuiDelivery ?? this.possuiDelivery,
      freteGratisAte: freteGratisAte ?? this.freteGratisAte,
      valorPorKm: valorPorKm ?? this.valorPorKm,
    );
  }
}

// Representa uma Categoria da Loja, com os campos vistos no popup
// "Nova Categoria" do protótipo.
class CategoriaLoja {
  final String id;
  final String nome;
  final String? grupoComponentesId;
  final TipoItemLoja? tipo;

  const CategoriaLoja({
    required this.id,
    required this.nome,
    this.grupoComponentesId,
    this.tipo,
  });

  factory CategoriaLoja.nova({
    required String nome,
    String? grupoComponentesId,
    TipoItemLoja? tipo,
  }) {
    return CategoriaLoja(
      id: _gerarIdUnico(),
      nome: nome,
      grupoComponentesId: grupoComponentesId,
      tipo: tipo,
    );
  }

  CategoriaLoja copyWith({
    String? nome,
    String? grupoComponentesId,
    TipoItemLoja? tipo,
  }) {
    return CategoriaLoja(
      id: id,
      nome: nome ?? this.nome,
      grupoComponentesId: grupoComponentesId ?? this.grupoComponentesId,
      tipo: tipo ?? this.tipo,
    );
  }
}

// Representa um Grupo de Componentes "solto", criado direto pelo botão
// "Novo Grupo de Componentes" da aba Loja — diferente dos grupos que já
// existiam dentro da árvore Categoria > Produto > Grupo (esses
// continuam sendo tratados pelo GrupoComponentesContainer, sem
// mudança). Este aqui guarda uma lista de IDs de Itens que já foram
// criados antes pelo botão "Novo Item".
class GrupoComponentesLoja {
  final String id;
  final String nome;
  final List<String> itemIds;

  const GrupoComponentesLoja({
    required this.id,
    required this.nome,
    this.itemIds = const [],
  });

  factory GrupoComponentesLoja.novo({
    required String nome,
    List<String> itemIds = const [],
  }) {
    return GrupoComponentesLoja(
      id: _gerarIdUnico(),
      nome: nome,
      itemIds: itemIds,
    );
  }

  GrupoComponentesLoja copyWith({
    String? nome,
    List<String>? itemIds,
  }) {
    return GrupoComponentesLoja(
      id: id,
      nome: nome ?? this.nome,
      itemIds: itemIds ?? this.itemIds,
    );
  }
}