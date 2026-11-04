import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
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

  String get descricaoFrequenciaCurta {
    if (modoProgramacao == 'dias_semana' || recorrente) {
      if (diasSemana.isEmpty || diasSemana.length == 7) {
        return 'Todos os dias';
      }
      final diasOrdenados = List<int>.from(diasSemana)..sort();
      if (diasOrdenados.length == 5 &&
          diasOrdenados[0] == 1 &&
          diasOrdenados[1] == 2 &&
          diasOrdenados[2] == 3 &&
          diasOrdenados[3] == 4 &&
          diasOrdenados[4] == 5) {
        return 'Seg a Sex';
      }
      if (diasOrdenados.length == 2 &&
          diasOrdenados[0] == 6 &&
          diasOrdenados[1] == 7) {
        return 'Sáb e Dom';
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
      return diasOrdenados.map((d) => nomes[d] ?? '$d').join(', ');
    }

    if (datasEspecificas.isNotEmpty) {
      if (datasEspecificas.length == 1) {
        final d = datasEspecificas.first;
        final diaStr = d.day.toString().padLeft(2, '0');
        final mesStr = d.month.toString().padLeft(2, '0');
        return '$diaStr/$mesStr/${d.year}';
      }
      return '${datasEspecificas.length} datas programadas';
    }

    if (dataProgramada != null) {
      final d = dataProgramada!;
      final diaStr = d.day.toString().padLeft(2, '0');
      final mesStr = d.month.toString().padLeft(2, '0');
      return '$diaStr/$mesStr/${d.year}';
    }

    return 'Agendado';
  }

  String get descricaoFrequencia => '$descricaoFrequenciaCurta às $horario';

  PedidoLoja toPedidoLoja({
    required int numero,
    DateTime? dataHora,
    String nomeVendedor = '',
    String cnpjVendedor = '',
    String? lojaId,
  }) {
    final momento = dataHora ?? DateTime.now();
    final diaStr = momento.day.toString().padLeft(2, '0');
    final mesStr = momento.month.toString().padLeft(2, '0');
    return PedidoLoja(
      id: 'prog_${id}_${momento.year}_${mesStr}_$diaStr',
      numero: numero,
      clienteId: clienteId.isEmpty ? null : clienteId,
      clienteNome: clienteNome,
      produtoNome: itens.map((e) => e.nomeExibicao).join(', '),
      dataHora: momento,
      valor: valorTotal,
      status: StatusPedido.novo,
      comanda: '',
      comentario: observacao.trim(),
      formaPagamento: formaPagamento,
      itens: itens,
      quitado: false,
      valorPago: 0,
      valorRecebido: 0,
      troco: 0,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      lojaId: lojaId ?? this.lojaId,
    );
  }

  /// Resolve o cliente correspondente na lista de clientes da loja ou cria um
  /// objeto com os dados de telefone/endereço salvos na programação.
  Cliente resolverCliente(List<Cliente> clientesCadastrados) {
    final cadastrado = clientesCadastrados
        .where((c) =>
            (clienteId.isNotEmpty && c.id == clienteId) ||
            (clienteNome.trim().isNotEmpty &&
                c.nome.trim().toLowerCase() ==
                    clienteNome.trim().toLowerCase()))
        .firstOrNull;
    if (cadastrado != null) {
      return cadastrado.copyWith(
        telefone: cadastrado.telefone.trim().isNotEmpty
            ? cadastrado.telefone
            : clienteTelefone,
        endereco: cadastrado.endereco.trim().isNotEmpty
            ? cadastrado.endereco
            : clienteEndereco,
      );
    }
    return Cliente(
      id: clienteId.isNotEmpty ? clienteId : 'cli_prog_$id',
      nome: clienteNome,
      cnpj: '',
      telefone: clienteTelefone,
      endereco: clienteEndereco,
      numero: '',
      email: '',
    );
  }

  /// Retorna o [PedidoLoja] já gerado para a [data] se existir em [pedidosExistentes],
  /// preservando o número real (#00XX) e status, ou gera uma prévia se ainda não existir.
  PedidoLoja resolverPedidoDoDia({
    required List<PedidoLoja> pedidosExistentes,
    DateTime? data,
    String nomeVendedor = '',
    String cnpjVendedor = '',
    String? lojaId,
  }) {
    final alvo = data ?? DateTime.now();
    final diaStr = alvo.day.toString().padLeft(2, '0');
    final mesStr = alvo.month.toString().padLeft(2, '0');
    final idEsperado = 'prog_${id}_${alvo.year}_${mesStr}_$diaStr';
    final existente = pedidosExistentes.where((p) {
      if (p.id == idEsperado) return true;
      if (p.id.startsWith('prog_${id}_') &&
          p.dataHora.year == alvo.year &&
          p.dataHora.month == alvo.month &&
          p.dataHora.day == alvo.day) {
        return true;
      }
      return false;
    }).firstOrNull;

    if (existente != null) {
      return existente;
    }

    return toPedidoLoja(
      numero: 0,
      dataHora: alvo,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      lojaId: lojaId ?? this.lojaId,
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
