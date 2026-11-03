enum ResultadoAutorizacaoConexao {
  recusado,
  autorizadoMembro,
  autorizadoCliente,
}

/// Informações de um terminal móvel conectado ao balcão
class TerminalConectadoInfo {
  final String id;
  String nome;
  final String ip;
  final DateTime conectadoEm;
  String? cpf;
  String? nomeUsuario;
  String? apelido;
  String? tipoConexao;

  TerminalConectadoInfo({
    required this.id,
    required this.nome,
    required this.ip,
    required this.conectadoEm,
    this.cpf,
    this.nomeUsuario,
    this.apelido,
    this.tipoConexao = 'membro',
  });

  bool get ehHost => id == 'balcao_servidor_local' || id.startsWith('host_');

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ip': ip,
        'conectadoEm': conectadoEm.toIso8601String(),
        'cpf': cpf,
        'nomeUsuario': nomeUsuario,
        'apelido': apelido,
        'tipoConexao': tipoConexao,
      };

  factory TerminalConectadoInfo.fromJson(Map<String, dynamic> json) {
    return TerminalConectadoInfo(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Terminal',
      ip: json['ip'] as String? ?? '',
      conectadoEm: DateTime.tryParse(json['conectadoEm'] as String? ?? '') ??
          DateTime.now(),
      cpf: json['cpf'] as String?,
      nomeUsuario: json['nomeUsuario'] as String?,
      apelido: json['apelido'] as String?,
      tipoConexao: json['tipoConexao'] as String? ?? 'membro',
    );
  }
}
