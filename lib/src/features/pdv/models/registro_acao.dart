import 'package:nous/src/core/services/cripto_service.dart';

enum TipoAcao {
  dadosLojaAtualizados,
  novaVenda,
  pedidoAceito,
  pedidoRecusado,
  pedidoConcluido,
  pedidoCancelado,
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
  conviteEnviado,
  pagamentoPrazoRecebido,
  itemVinculadoCategoria,
  itemDesvinculadoCategoria,
  itemVinculadoGrupo,
  itemDesvinculadoGrupo,
  movimentoEstoqueRegistrado,
  movimentoEstoqueRemovido,
  pagamentoFuncionarioRegistrado,
  pagamentoFuncionarioRemovido,
  mesaCriada,
  mesaExcluida,
  mesaAberta,
  itemAdicionadoMesa,
  itemRemovidoMesa,
  mesaFechada,
  mesaLiberada,
  mesaTransferida,
  caixaAberto,
  caixaFechado,
  sangriaRegistrada,
  suprimentoRegistrado,
  turnoCaixaExcluido,
  transacoesResetadas,
}

class RegistroAcao {
  final String id;
  final DateTime dataHora;
  final TipoAcao tipo;
  final String descricao;
  final String cpfAutor;
  final String nomeAutor;
  final String emailAutor;
  final String hashAnterior;
  final String hash;

  const RegistroAcao({
    required this.id,
    required this.dataHora,
    required this.tipo,
    required this.descricao,
    required this.cpfAutor,
    required this.nomeAutor,
    required this.emailAutor,
    this.hashAnterior = '',
    this.hash = '',
  });

  /// Gera o hash criptográfico (SHA-256) encadeado com o hash anterior
  String calcularHash([String? hashPrev]) {
    final prev = hashPrev ?? hashAnterior;
    final payload = '$id|${dataHora.toIso8601String()}|${tipo.name}|$descricao|$cpfAutor|$prev';
    return CriptoService.sha256(payload);
  }

  RegistroAcao copyWith({
    String? id,
    DateTime? dataHora,
    TipoAcao? tipo,
    String? descricao,
    String? cpfAutor,
    String? nomeAutor,
    String? emailAutor,
    String? hashAnterior,
    String? hash,
  }) {
    return RegistroAcao(
      id: id ?? this.id,
      dataHora: dataHora ?? this.dataHora,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      cpfAutor: cpfAutor ?? this.cpfAutor,
      nomeAutor: nomeAutor ?? this.nomeAutor,
      emailAutor: emailAutor ?? this.emailAutor,
      hashAnterior: hashAnterior ?? this.hashAnterior,
      hash: hash ?? this.hash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataHora': dataHora.toIso8601String(),
      'tipo': tipo.name,
      'descricao': descricao,
      'cpfAutor': cpfAutor,
      'nomeAutor': nomeAutor,
      'emailAutor': emailAutor,
      'hashAnterior': hashAnterior,
      'hash': hash,
    };
  }

  factory RegistroAcao.fromJson(Map<String, dynamic> json) {
    final tipoTexto = json['tipo'] as String? ?? '';
    final tipo = TipoAcao.values
        .where((t) => t.name == tipoTexto)
        .cast<TipoAcao?>()
        .firstWhere((t) => t != null, orElse: () => TipoAcao.dadosLojaAtualizados)!;
    return RegistroAcao(
      id: json['id'] as String? ?? '',
      dataHora: DateTime.tryParse(json['dataHora'] as String? ?? '') ?? DateTime.now(),
      tipo: tipo,
      descricao: json['descricao'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
      emailAutor: json['emailAutor'] as String? ?? '',
      hashAnterior: json['hashAnterior'] as String? ?? '',
      hash: json['hash'] as String? ?? '',
    );
  }
}