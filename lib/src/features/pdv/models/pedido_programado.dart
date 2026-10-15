import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class PedidoProgramado {
  final String id;
  final String lojaId;
  final String clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final String clienteEndereco;
  final List<ItemVendido> itens;
  final double valorTotal;
  final String formaPagamento;
  final String horario; // Formato HH:mm, ex: "14:30"
  final bool recorrente; // true: recorrente; false: pontual
  final String modoProgramacao; // 'dias_semana' ou 'datas_especificas'
  final List<int> diasSemana; // 1 = Seg ... 7 = Dom
  final List<DateTime> datasEspecificas; // Lista de datas selecionadas
  final DateTime? dataProgramada; // Para compatibilidade com dados anteriores
  final bool ativo;
  final DateTime dataCriacao;
  final DateTime? ultimaDataGerado; // Data do último dia em que gerou pedido em "Novos"
  final String observacao;

  const PedidoProgramado({
    required this.id,
    required this.lojaId,
    this.clienteId = '',
    required this.clienteNome,
    this.clienteTelefone = '',
    this.clienteEndereco = '',
    required this.itens,
    required this.valorTotal,
    this.formaPagamento = 'Dinheiro',
    required this.horario,
    this.recorrente = false,
    this.modoProgramacao = 'dias_semana',
    this.diasSemana = const [],
    this.datasEspecificas = const [],
    this.dataProgramada,
    this.ativo = true,
    required this.dataCriacao,
    this.ultimaDataGerado,
    this.observacao = '',
  });

  factory PedidoProgramado.novo({
    required String lojaId,
    String clienteId = '',
    required String clienteNome,
    String clienteTelefone = '',
    String clienteEndereco = '',
    required List<ItemVendido> itens,
    required double valorTotal,
    String formaPagamento = 'Dinheiro',
    required String horario,
    bool recorrente = false,
    String modoProgramacao = 'dias_semana',
    List<int> diasSemana = const [],
    List<DateTime> datasEspecificas = const [],
    DateTime? dataProgramada,
    String observacao = '',
  }) {
    return PedidoProgramado(
      id: gerarIdUnico(),
      lojaId: lojaId,
      clienteId: clienteId,
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      clienteEndereco: clienteEndereco,
      itens: itens,
      valorTotal: valorTotal,
      formaPagamento: formaPagamento,
      horario: horario,
      recorrente: recorrente,
      modoProgramacao: modoProgramacao,
      diasSemana: diasSemana,
      datasEspecificas: datasEspecificas,
      dataProgramada: dataProgramada,
      ativo: true,
      dataCriacao: DateTime.now(),
      observacao: observacao,
    );
  }

  bool coincideComData(DateTime dia) {
    if (!ativo) return false;

    if (modoProgramacao == 'dias_semana' || recorrente) {
      if (diasSemana.isEmpty) {
        return true;
      }
      return diasSemana.contains(dia.weekday);
    }

    if (datasEspecificas.isNotEmpty) {
      return datasEspecificas.any((d) =>
          d.year == dia.year && d.month == dia.month && d.day == dia.day);
    }

    if (dataProgramada != null) {
      return dataProgramada!.year == dia.year &&
          dataProgramada!.month == dia.month &&
          dataProgramada!.day == dia.day;
    }

    return false;
  }

  String get descricaoFrequencia {
    if (modoProgramacao == 'dias_semana' || recorrente) {
      if (diasSemana.isEmpty || diasSemana.length == 7) {
        return 'Todos os dias às $horario';
      }
      const nomes = {
        1: 'Seg',
        2: 'Ter',
        3: 'Qua',
        4: 'Qui',
        5: 'Sex',
        6: 'Sáb',
        7: 'Dom',
      };
      final diasOrdenados = List<int>.from(diasSemana)..sort();
      final formatados = diasOrdenados.map((d) => nomes[d] ?? '$d').join(', ');
      return '$formatados às $horario';
    }

    if (datasEspecificas.isNotEmpty) {
      if (datasEspecificas.length == 1) {
        final d = datasEspecificas.first;
        final diaStr = d.day.toString().padLeft(2, '0');
        final mesStr = d.month.toString().padLeft(2, '0');
        return '$diaStr/$mesStr/${d.year} às $horario';
      }
      return '${datasEspecificas.length} datas programadas às $horario';
    }

    if (dataProgramada != null) {
      final d = dataProgramada!;
      final diaStr = d.day.toString().padLeft(2, '0');
      final mesStr = d.month.toString().padLeft(2, '0');
      return '$diaStr/$mesStr/${d.year} às $horario';
    }

    return 'Horário: $horario';
  }

  PedidoLoja toPedidoLoja({
    required int numero,
    DateTime? dataHora,
  }) {
    final momento = dataHora ?? DateTime.now();
    return PedidoLoja(
      id: 'prog_${id}_${momento.millisecondsSinceEpoch}',
      numero: numero,
      clienteId: clienteId.isEmpty ? null : clienteId,
      clienteNome: clienteNome,
      produtoNome: itens.map((e) => e.nomeExibicao).join(', '),
      dataHora: momento,
      valor: valorTotal,
      status: StatusPedido.novo,
      comanda: 'Programado: $descricaoFrequencia',
      formaPagamento: formaPagamento,
      itens: itens,
      quitado: false,
      valorPago: 0,
      valorRecebido: 0,
      troco: 0,
    );
  }

  PedidoProgramado copyWith({
    String? id,
    String? lojaId,
    String? clienteId,
    String? clienteNome,
    String? clienteTelefone,
    String? clienteEndereco,
    List<ItemVendido>? itens,
    double? valorTotal,
    String? formaPagamento,
    String? horario,
    bool? recorrente,
    String? modoProgramacao,
    List<int>? diasSemana,
    List<DateTime>? datasEspecificas,
    DateTime? dataProgramada,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? ultimaDataGerado,
    String? observacao,
  }) {
    return PedidoProgramado(
      id: id ?? this.id,
      lojaId: lojaId ?? this.lojaId,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      clienteEndereco: clienteEndereco ?? this.clienteEndereco,
      itens: itens ?? this.itens,
      valorTotal: valorTotal ?? this.valorTotal,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      horario: horario ?? this.horario,
      recorrente: recorrente ?? this.recorrente,
      modoProgramacao: modoProgramacao ?? this.modoProgramacao,
      diasSemana: diasSemana ?? this.diasSemana,
      datasEspecificas: datasEspecificas ?? this.datasEspecificas,
      dataProgramada: dataProgramada ?? this.dataProgramada,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ultimaDataGerado: ultimaDataGerado ?? this.ultimaDataGerado,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lojaId': lojaId,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'clienteTelefone': clienteTelefone,
      'clienteEndereco': clienteEndereco,
      'itens': itens.map((i) => i.toJson()).toList(),
      'valorTotal': valorTotal,
      'formaPagamento': formaPagamento,
      'horario': horario,
      'recorrente': recorrente,
      'modoProgramacao': modoProgramacao,
      'diasSemana': diasSemana,
      'datasEspecificas':
          datasEspecificas.map((d) => d.toIso8601String()).toList(),
      'dataProgramada': dataProgramada?.toIso8601String(),
      'ativo': ativo,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ultimaDataGerado': ultimaDataGerado?.toIso8601String(),
      'observacao': observacao,
    };
  }

  factory PedidoProgramado.fromJson(Map<String, dynamic> json) {
    return PedidoProgramado(
      id: json['id'] as String? ?? '',
      lojaId: json['lojaId'] as String? ?? '',
      clienteId: json['clienteId'] as String? ?? '',
      clienteNome: json['clienteNome'] as String? ?? '',
      clienteTelefone: json['clienteTelefone'] as String? ?? '',
      clienteEndereco: json['clienteEndereco'] as String? ?? '',
      itens: (json['itens'] as List<dynamic>? ?? const [])
          .map((i) => ItemVendido.fromJson(i as Map<String, dynamic>))
          .toList(),
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
      formaPagamento: json['formaPagamento'] as String? ?? 'Dinheiro',
      horario: json['horario'] as String? ?? '12:00',
      recorrente: json['recorrente'] as bool? ?? false,
      modoProgramacao: json['modoProgramacao'] as String? ??
          ((json['recorrente'] as bool? ?? false)
              ? 'dias_semana'
              : 'datas_especificas'),
      diasSemana: (json['diasSemana'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      datasEspecificas:
          (json['datasEspecificas'] as List<dynamic>? ?? const [])
              .map((e) => DateTime.tryParse(e.toString()))
              .whereType<DateTime>()
              .toList(),
      dataProgramada: json['dataProgramada'] != null
          ? DateTime.tryParse(json['dataProgramada'] as String)
          : null,
      ativo: json['ativo'] as bool? ?? true,
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'] as String) ?? DateTime.now()
          : DateTime.now(),
      ultimaDataGerado: json['ultimaDataGerado'] != null
          ? DateTime.tryParse(json['ultimaDataGerado'] as String)
          : null,
      observacao: json['observacao'] as String? ?? '',
    );
  }
}
