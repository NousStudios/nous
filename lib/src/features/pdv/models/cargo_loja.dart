class PermissaoLojaConst {
  static const String editarAbaLoja = 'editarAbaLoja';
  static const String usarImpressora = 'usarImpressora';
  static const String editarDadosLoja = 'editarDadosLoja';
  static const String usarFinanceiro = 'usarFinanceiro';
  static const String registrarPagamento = 'registrarPagamento';
  static const String gerenciarMembros = 'gerenciarMembros';
  static const String excluirLoja = 'excluirLoja';

  static const List<PermissaoInfo> todas = [
    PermissaoInfo(
      chave: editarAbaLoja,
      titulo: 'Editar Catálogo e Estoque',
      descricao:
          'Permite criar, alterar e reordenar produtos, categorias, grupos de componentes e gerenciar estoque.',
    ),
    PermissaoInfo(
      chave: usarImpressora,
      titulo: 'Configurar Impressora',
      descricao:
          'Permite configurar impressoras térmicas (58mm/80mm), tamanhos de fonte e testes de impressão.',
    ),
    PermissaoInfo(
      chave: editarDadosLoja,
      titulo: 'Editar Dados da Loja e Anexos',
      descricao:
          'Permite alterar informações cadastrais, logotipo, fotos da galeria, áudios e arquivos da loja.',
    ),
    PermissaoInfo(
      chave: usarFinanceiro,
      titulo: 'Acessar Módulo Financeiro',
      descricao:
          'Permite visualizar entradas, saídas, fechamento de caixa e transparência contábil da loja.',
    ),
    PermissaoInfo(
      chave: registrarPagamento,
      titulo: 'Registrar Pagamento a Trabalhadores',
      descricao:
          'Permite lançar e efetivar pagamentos e adiantamentos a membros da equipe.',
    ),
    PermissaoInfo(
      chave: gerenciarMembros,
      titulo: 'Gerenciar Membros e Cargos',
      descricao:
          'Permite enviar convites, vincular cargos e gerenciar a equipe de trabalhadores da loja.',
    ),
    PermissaoInfo(
      chave: excluirLoja,
      titulo: 'Excluir Perfil da Loja',
      descricao:
          'Poder destrutivo máximo para apagar a loja inteira e seus registros do cofre.',
    ),
  ];
}

class PermissaoInfo {
  final String chave;
  final String titulo;
  final String descricao;

  const PermissaoInfo({
    required this.chave,
    required this.titulo,
    required this.descricao,
  });
}

class CargoLoja {
  final String id;
  final String nome;
  final Map<String, bool> permissoes;
  final String? corHex;

  const CargoLoja({
    required this.id,
    required this.nome,
    this.permissoes = const {},
    this.corHex,
  });

  bool temPermissao(String chave) => permissoes[chave] ?? false;

  CargoLoja copyWith({
    String? nome,
    Map<String, bool>? permissoes,
    String? corHex,
  }) {
    return CargoLoja(
      id: id,
      nome: nome ?? this.nome,
      permissoes: permissoes ?? this.permissoes,
      corHex: corHex ?? this.corHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'permissoes': permissoes,
      if (corHex != null) 'corHex': corHex,
    };
  }

  factory CargoLoja.fromJson(Map<String, dynamic> json) {
    return CargoLoja(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      permissoes: (json['permissoes'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v as bool? ?? false)),
      corHex: json['corHex'] as String?,
    );
  }
}
