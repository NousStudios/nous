const List<String> kCamposClienteComanda = [
  'cnpj',
  'telefone',
  'endereco',
  'email',
  'redesSociais',
  'descricao',
];

const List<String> kCamposClienteComandaPadrao = [
  'telefone',
  'endereco',
];

class ConfiguracoesImpressora {
  final double larguraPapelMm;
  final String rodape;
  final String tamanhoFonte;
  final String tipoConexao;
  final String enderecoRede;
  final String nomeImpressora;
  final List<String> camposClienteComanda;
  final bool camposClientePersonalizados;
  final double margemEsquerdaMm;
  final double margemDireitaMm;
  final String modeloFonte;

  const ConfiguracoesImpressora({
    this.larguraPapelMm = 58.0,
    this.rodape = 'linktr.ee/nous72',
    this.tamanhoFonte = 'normal',
    this.tipoConexao = 'usb',
    this.enderecoRede = '',
    this.nomeImpressora = '',
    this.camposClienteComanda = kCamposClienteComandaPadrao,
    this.camposClientePersonalizados = false,
    this.margemEsquerdaMm = 5.0,
    this.margemDireitaMm = 3.0,
    this.modeloFonte = 'belleza',
  });

  ConfiguracoesImpressora copyWith({
    double? larguraPapelMm,
    String? rodape,
    String? tamanhoFonte,
    String? tipoConexao,
    String? enderecoRede,
    String? nomeImpressora,
    List<String>? camposClienteComanda,
    bool? camposClientePersonalizados,
    double? margemEsquerdaMm,
    double? margemDireitaMm,
    String? modeloFonte,
  }) {
    return ConfiguracoesImpressora(
      larguraPapelMm: larguraPapelMm ?? this.larguraPapelMm,
      rodape: rodape ?? this.rodape,
      tamanhoFonte: tamanhoFonte ?? this.tamanhoFonte,
      tipoConexao: tipoConexao ?? this.tipoConexao,
      enderecoRede: enderecoRede ?? this.enderecoRede,
      nomeImpressora: nomeImpressora ?? this.nomeImpressora,
      camposClienteComanda:
          camposClienteComanda ?? this.camposClienteComanda,
      camposClientePersonalizados:
          camposClientePersonalizados ?? this.camposClientePersonalizados,
      margemEsquerdaMm: margemEsquerdaMm ?? this.margemEsquerdaMm,
      margemDireitaMm: margemDireitaMm ?? this.margemDireitaMm,
      modeloFonte: modeloFonte ?? this.modeloFonte,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'larguraPapelMm': larguraPapelMm,
      'rodape': rodape,
      'tamanhoFonte': tamanhoFonte,
      'tipoConexao': tipoConexao,
      'enderecoRede': enderecoRede,
      'nomeImpressora': nomeImpressora,
      'camposClienteComanda': camposClienteComanda,
      'camposClientePersonalizados': camposClientePersonalizados,
      'margemEsquerdaMm': margemEsquerdaMm,
      'margemDireitaMm': margemDireitaMm,
      'modeloFonte': modeloFonte,
    };
  }

  factory ConfiguracoesImpressora.fromJson(Map<String, dynamic> json) {
    final camposBrutos = json['camposClienteComanda'] as List<dynamic>?;
    final personalizado =
        json['camposClientePersonalizados'] as bool? ?? false;
    final List<String> campos;
    if (camposBrutos != null) {
      final lista = camposBrutos.map((e) => e as String).toList();
      final ehPadraoAntigoCompleto = !personalizado &&
          lista.length == kCamposClienteComanda.length &&
          kCamposClienteComanda.every((ch) => lista.contains(ch));

      if (ehPadraoAntigoCompleto) {
        campos = List.of(kCamposClienteComandaPadrao);
      } else {
        campos = lista;
      }
    } else {
      final mostrarAntigo = json['mostrarDadosCliente'] as bool?;
      campos = mostrarAntigo == false
          ? <String>[]
          : List.of(kCamposClienteComandaPadrao);
    }
    return ConfiguracoesImpressora(
      larguraPapelMm: (json['larguraPapelMm'] as num?)?.toDouble() ?? 58.0,
      rodape: json['rodape'] as String? ?? 'linktr.ee/nous72',
      tamanhoFonte: json['tamanhoFonte'] as String? ?? 'normal',
      tipoConexao: json['tipoConexao'] as String? ?? 'usb',
      enderecoRede: json['enderecoRede'] as String? ?? '',
      nomeImpressora: json['nomeImpressora'] as String? ?? '',
      camposClienteComanda: campos,
      camposClientePersonalizados: personalizado,
      margemEsquerdaMm: (json['margemEsquerdaMm'] as num?)?.toDouble() ?? 5.0,
      margemDireitaMm: (json['margemDireitaMm'] as num?)?.toDouble() ?? 3.0,
      modeloFonte: json['modeloFonte'] as String? ?? 'belleza',
    );
  }
}