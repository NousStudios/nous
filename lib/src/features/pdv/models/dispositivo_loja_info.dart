/// Informações de um servidor de loja anunciado na rede Wi-Fi local.
class DispositivoLojaInfo {
  final String lojaId;
  final String lojaNome;
  final String ip;
  final int porta;
  final DateTime vistoEm;
  final String tipoHost;

  const DispositivoLojaInfo({
    required this.lojaId,
    required this.lojaNome,
    required this.ip,
    required this.porta,
    required this.vistoEm,
    this.tipoHost = 'loja',
  });

  bool get ehUsuario => tipoHost == 'usuario' || lojaId.isEmpty;
  String get enderecoCompleto => '$ip:$porta';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispositivoLojaInfo &&
          runtimeType == other.runtimeType &&
          lojaId == other.lojaId &&
          ip == other.ip &&
          porta == other.porta;

  @override
  int get hashCode => lojaId.hashCode ^ ip.hashCode ^ porta.hashCode;
}
