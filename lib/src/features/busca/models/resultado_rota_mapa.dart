import 'package:latlong2/latlong.dart';

class PassoRotaMapa {
  final String instrucao;
  final double distanciaMetros;
  final String nomeRua;
  final LatLng? coordenada;

  const PassoRotaMapa({
    required this.instrucao,
    required this.distanciaMetros,
    this.nomeRua = '',
    this.coordenada,
  });

  String get distanciaFormatada {
    if (distanciaMetros >= 1000) {
      return '${(distanciaMetros / 1000).toStringAsFixed(1)} km';
    }
    return '${distanciaMetros.round()} m';
  }
}

class ResultadoRotaMapa {
  final List<LatLng> pontos;
  final double distanciaMetros;
  final double duracaoSegundos;
  final String origemLabel;
  final String destinoLabel;
  final List<PassoRotaMapa> passos;
  final bool ehRotaRealOnline;

  const ResultadoRotaMapa({
    required this.pontos,
    required this.distanciaMetros,
    required this.duracaoSegundos,
    required this.origemLabel,
    required this.destinoLabel,
    this.passos = const [],
    this.ehRotaRealOnline = true,
  });

  String get distanciaFormatada {
    if (distanciaMetros >= 1000) {
      return '${(distanciaMetros / 1000).toStringAsFixed(1)} km';
    }
    return '${distanciaMetros.round()} m';
  }

  String get duracaoFormatada {
    final mins = (duracaoSegundos / 60).round();
    if (mins < 60) return '$mins min';
    final horas = mins ~/ 60;
    final resto = mins % 60;
    return '${horas}h ${resto}min';
  }

  String get horarioChegadaFormatado {
    final chegada = DateTime.now().add(
      Duration(seconds: duracaoSegundos.round()),
    );
    final h = chegada.hour.toString().padLeft(2, '0');
    final m = chegada.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
