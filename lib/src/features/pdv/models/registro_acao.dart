enum TipoAcao {
  dadosLojaAtualizados,
  novaVenda,
  pedidoAceito,
  pedidoRecusado,
  pedidoConcluido,
  pedidoExcluido,
  comentarioSalvo,
  clienteCriado,
  clienteAtualizado,
  clienteExcluido,
  itemCriado,
  itemAtualizado,
  itemExcluido,
  categoriaCriada,
  categoriaAtualizada,
  categoriaExcluida,
  grupoCriado,
  grupoAtualizado,
  grupoExcluido,
  lojaExcluida,
  membroAdicionado,
  membroRemovido,
  papelAlterado,
}

class RegistroAcao {
  final String id;
  final DateTime dataHora;
  final TipoAcao tipo;
  final String descricao;
  final String cpfAutor;
  final String nomeAutor;
  final String emailAutor;

  const RegistroAcao({
    required this.id,
    required this.dataHora,
    required this.tipo,
    required this.descricao,
    required this.cpfAutor,
    required this.nomeAutor,
    required this.emailAutor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataHora': dataHora.toIso8601String(),
      'tipo': tipo.name,
      'descricao': descricao,
      'cpfAutor': cpfAutor,
      'nomeAutor': nomeAutor,
      'emailAutor': emailAutor,
    };
  }

  factory RegistroAcao.fromJson(Map<String, dynamic> json) {
    return RegistroAcao(
      id: json['id'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      tipo: TipoAcao.values.byName(json['tipo'] as String),
      descricao: json['descricao'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
      emailAutor: json['emailAutor'] as String? ?? '',
    );
  }
}