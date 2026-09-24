class ConfiguracoesImpressora {
  final String rodape;
  final String tamanhoFonte;
  final String tipoConexao;
  final String enderecoRede;
  final String nomeImpressora;

  const ConfiguracoesImpressora({
    this.rodape = 'linktr.ee/nous72',
    this.tamanhoFonte = 'normal',
    this.tipoConexao = 'usb',
    this.enderecoRede = '',
    this.nomeImpressora = '',
  });

  ConfiguracoesImpressora copyWith({
    String? rodape,
    String? tamanhoFonte,
    String? tipoConexao,
    String? enderecoRede,
    String? nomeImpressora,
  }) {
    return ConfiguracoesImpressora(
      rodape: rodape ?? this.rodape,
      tamanhoFonte: tamanhoFonte ?? this.tamanhoFonte,
      tipoConexao: tipoConexao ?? this.tipoConexao,
      enderecoRede: enderecoRede ?? this.enderecoRede,
      nomeImpressora: nomeImpressora ?? this.nomeImpressora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rodape': rodape,
      'tamanhoFonte': tamanhoFonte,
      'tipoConexao': tipoConexao,
      'enderecoRede': enderecoRede,
      'nomeImpressora': nomeImpressora,
    };
  }

  factory ConfiguracoesImpressora.fromJson(Map<String, dynamic> json) {
    return ConfiguracoesImpressora(
      rodape: json['rodape'] as String? ?? 'linktr.ee/nous72',
      tamanhoFonte: json['tamanhoFonte'] as String? ?? 'normal',
      tipoConexao: json['tipoConexao'] as String? ?? 'usb',
      enderecoRede: json['enderecoRede'] as String? ?? '',
      nomeImpressora: json['nomeImpressora'] as String? ?? '',
    );
  }
}