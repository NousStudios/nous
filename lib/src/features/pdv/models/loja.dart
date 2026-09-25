import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';

class Loja {
  final String id;

  final String nome;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String categorias;
  final String tags;

  final List<CategoriaLoja> categoriasLoja;
  final List<ItemLoja> itensLoja;
  final List<GrupoComponentesLoja> gruposComponentesLoja;
  final List<Cliente> clientesLoja;
  final List<PedidoLoja> pedidosLoja;
  final List<RegistroAcao> acoes;
  final List<MembroLoja> membros;

  final ConfiguracoesImpressora configuracoesImpressora;

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
    this.categoriasLoja = const [],
    this.itensLoja = const [],
    this.gruposComponentesLoja = const [],
    this.clientesLoja = const [],
    this.pedidosLoja = const [],
    this.acoes = const [],
    this.membros = const [],
    this.configuracoesImpressora = const ConfiguracoesImpressora(),
  });

  Loja copyWith({
    String? nome,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? numero,
    String? email,
    String? categorias,
    String? tags,
    List<CategoriaLoja>? categoriasLoja,
    List<ItemLoja>? itensLoja,
    List<GrupoComponentesLoja>? gruposComponentesLoja,
    List<Cliente>? clientesLoja,
    List<PedidoLoja>? pedidosLoja,
    List<RegistroAcao>? acoes,
    List<MembroLoja>? membros,
    ConfiguracoesImpressora? configuracoesImpressora,
  }) {
    return Loja(
      id: id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      email: email ?? this.email,
      categorias: categorias ?? this.categorias,
      tags: tags ?? this.tags,
      categoriasLoja: categoriasLoja ?? this.categoriasLoja,
      itensLoja: itensLoja ?? this.itensLoja,
      gruposComponentesLoja: gruposComponentesLoja ?? this.gruposComponentesLoja,
      clientesLoja: clientesLoja ?? this.clientesLoja,
      pedidosLoja: pedidosLoja ?? this.pedidosLoja,
      acoes: acoes ?? this.acoes,
      membros: membros ?? this.membros,
      configuracoesImpressora:
          configuracoesImpressora ?? this.configuracoesImpressora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'email': email,
      'categorias': categorias,
      'tags': tags,
      'categoriasLoja': categoriasLoja.map((c) => c.toJson()).toList(),
      'itensLoja': itensLoja.map((i) => i.toJson()).toList(),
      'gruposComponentesLoja':
          gruposComponentesLoja.map((g) => g.toJson()).toList(),
      'clientesLoja': clientesLoja.map((c) => c.toJson()).toList(),
      'pedidosLoja': pedidosLoja.map((p) => p.toJson()).toList(),
      'acoes': acoes.map((a) => a.toJson()).toList(),
      'membros': membros.map((m) => m.toJson()).toList(),
      'configuracoesImpressora': configuracoesImpressora.toJson(),
    };
  }

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String,
      telefone: json['telefone'] as String,
      endereco: json['endereco'] as String,
      numero: json['numero'] as String,
      email: json['email'] as String,
      categorias: json['categorias'] as String,
      tags: json['tags'] as String,
      categoriasLoja: (json['categoriasLoja'] as List<dynamic>? ?? const [])
          .map((item) => CategoriaLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      itensLoja: (json['itensLoja'] as List<dynamic>? ?? const [])
          .map((item) => ItemLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      gruposComponentesLoja:
          (json['gruposComponentesLoja'] as List<dynamic>? ?? const [])
              .map((item) =>
                  GrupoComponentesLoja.fromJson(item as Map<String, dynamic>))
              .toList(),
      clientesLoja: (json['clientesLoja'] as List<dynamic>? ?? const [])
          .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
          .toList(),
      pedidosLoja: (json['pedidosLoja'] as List<dynamic>? ?? const [])
          .map((item) => PedidoLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      acoes: (json['acoes'] as List<dynamic>? ?? const [])
          .map((item) => RegistroAcao.fromJson(item as Map<String, dynamic>))
          .toList(),
      membros: (json['membros'] as List<dynamic>? ?? const [])
          .map((item) => MembroLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      configuracoesImpressora: json['configuracoesImpressora'] == null
          ? const ConfiguracoesImpressora()
          : ConfiguracoesImpressora.fromJson(
              json['configuracoesImpressora'] as Map<String, dynamic>,
            ),
    );
  }
}