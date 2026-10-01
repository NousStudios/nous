const List<String> kCamposClienteComanda = [
  'cnpj',
  'telefone',
  'endereco',
  'email',
  'redesSociais',
  'descricao',
];

class ConfiguracoesImpressora {
  final String rodape;
  final String tamanhoFonte;
  final String tipoConexao;
  final String enderecoRede;
  final String nomeImpressora;
  final List<String> camposClienteComanda;

  const ConfiguracoesImpressora({
    this.rodape = 'linktr.ee/nous72',
    this.tamanhoFonte = 'normal',
    this.tipoConexao = 'usb',
    this.enderecoRede = '',
    this.nomeImpressora = '',
    this.camposClienteComanda = kCamposClienteComanda,
  });

  ConfiguracoesImpressora copyWith({
    String? rodape,
    String? tamanhoFonte,
    String? tipoConexao,
    String? enderecoRede,
    String? nomeImpressora,
    List<String>? camposClienteComanda,
  }) {
    return ConfiguracoesImpressora(
      rodape: rodape ?? this.rodape,
      tamanhoFonte: tamanhoFonte ?? this.tamanhoFonte,
      tipoConexao: tipoConexao ?? this.tipoConexao,
      enderecoRede: enderecoRede ?? this.enderecoRede,
      nomeImpressora: nomeImpressora ?? this.nomeImpressora,
      camposClienteComanda:
          camposClienteComanda ?? this.camposClienteComanda,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rodape': rodape,
      'tamanhoFonte': tamanhoFonte,
      'tipoConexao': tipoConexao,
      'enderecoRede': enderecoRede,
      'nomeImpressora': nomeImpressora,
      'camposClienteComanda': camposClienteComanda,
    };
  }

  factory ConfiguracoesImpressora.fromJson(Map<String, dynamic> json) {
    final camposBrutos = json['camposClienteComanda'] as List<dynamic>?;
    final List<String> campos;
    if (camposBrutos != null) {
      campos = camposBrutos.map((e) => e as String).toList();
    } else {
      final mostrarAntigo = json['mostrarDadosCliente'] as bool? ?? true;
      campos = mostrarAntigo ? List.of(kCamposClienteComanda) : <String>[];
    }
    return ConfiguracoesImpressora(
      rodape: json['rodape'] as String? ?? 'linktr.ee/nous72',
      tamanhoFonte: json['tamanhoFonte'] as String? ?? 'normal',
      tipoConexao: json['tipoConexao'] as String? ?? 'usb',
      enderecoRede: json['enderecoRede'] as String? ?? '',
      nomeImpressora: json['nomeImpressora'] as String? ?? '',
      camposClienteComanda: campos,
    );
  }
}