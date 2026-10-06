import 'package:nous/src/features/pdv/models/pedido_loja.dart';

enum StatusMesa { livre, ocupada }

class ItemComandaMesa {
  final String id;
  final ItemVendido item;
  final String autorCpf;
  final String autorNome;
  final DateTime dataHora;

  const ItemComandaMesa({
    required this.id,
    required this.item,
    this.autorCpf = '',
    this.autorNome = '',
    required this.dataHora,
  });

  ItemComandaMesa copyWith({
    String? id,
    ItemVendido? item,
    String? autorCpf,
    String? autorNome,
    DateTime? dataHora,
  }) {
    return ItemComandaMesa(
      id: id ?? this.id,
      item: item ?? this.item,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      dataHora: dataHora ?? this.dataHora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item.toJson(),
      'autorCpf': autorCpf,
      'autorNome': autorNome,
      'dataHora': dataHora.toIso8601String(),
    };
  }

  factory ItemComandaMesa.fromJson(Map<String, dynamic> json) {
    return ItemComandaMesa(
      id: json['id'] as String? ?? '',
      item: json['item'] != null
          ? ItemVendido.fromJson(json['item'] as Map<String, dynamic>)
          : const ItemVendido(
              itemId: '',
              nomeItem: '',
              precoItem: 0,
              quantidade: 1,
            ),
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      dataHora: json['dataHora'] != null
          ? DateTime.tryParse(json['dataHora'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MesaLoja {
  final String id;
  final String numero;
  final String descricao;
  final StatusMesa status;
  final String clienteNome;
  final String atendenteCpf;
  final String atendenteNome;
  final DateTime? dataHoraAbertura;
  final List<ItemComandaMesa> itens;
  final String observacoes;

  const MesaLoja({
    required this.id,
    required this.numero,
    this.descricao = '',
    this.status = StatusMesa.livre,
    this.clienteNome = '',
    this.atendenteCpf = '',
    this.atendenteNome = '',
    this.dataHoraAbertura,
    this.itens = const [],
    this.observacoes = '',
  });

  double get totalAcumulado =>
      itens.fold(0.0, (acc, elem) => acc + elem.item.subtotal);

  int get quantidadeItensTotal =>
      itens.fold(0, (acc, elem) => acc + elem.item.quantidade);

  MesaLoja copyWith({
    String? id,
    String? numero,
    String? descricao,
    StatusMesa? status,
    String? clienteNome,
    String? atendenteCpf,
    String? atendenteNome,
    DateTime? dataHoraAbertura,
    List<ItemComandaMesa>? itens,
    String? observacoes,
  }) {
    return MesaLoja(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      clienteNome: clienteNome ?? this.clienteNome,
      atendenteCpf: atendenteCpf ?? this.atendenteCpf,
      atendenteNome: atendenteNome ?? this.atendenteNome,
      dataHoraAbertura: dataHoraAbertura ?? this.dataHoraAbertura,
      itens: itens ?? this.itens,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'descricao': descricao,
      'status': status.name,
      'clienteNome': clienteNome,
      'atendenteCpf': atendenteCpf,
      'atendenteNome': atendenteNome,
      'dataHoraAbertura': dataHoraAbertura?.toIso8601String(),
      'itens': itens.map((i) => i.toJson()).toList(),
      'observacoes': observacoes,
    };
  }

  factory MesaLoja.fromJson(Map<String, dynamic> json) {
    return MesaLoja(
      id: json['id'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      status: StatusMesa.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => StatusMesa.livre,
      ),
      clienteNome: json['clienteNome'] as String? ?? '',
      atendenteCpf: json['atendenteCpf'] as String? ?? '',
      atendenteNome: json['atendenteNome'] as String? ?? '',
      dataHoraAbertura: json['dataHoraAbertura'] != null
          ? DateTime.tryParse(json['dataHoraAbertura'] as String)
          : null,
      itens: (json['itens'] as List<dynamic>? ?? const [])
          .map((i) => ItemComandaMesa.fromJson(i as Map<String, dynamic>))
          .toList(),
      observacoes: json['observacoes'] as String? ?? '',
    );
  }
}
