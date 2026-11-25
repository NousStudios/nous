import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

enum FiltroBuscaMapa {
  todos,
  produtos,
  servicos,
  perfis,
  lojas,
  enderecos,
  projetos,
}

class ProdutoMapaItem {
  final ItemLoja item;
  final Loja loja;

  const ProdutoMapaItem({required this.item, required this.loja});
}

class ItemHistoricoBuscaMapa {
  final String titulo;
  final String subtitulo;
  final String tipo;
  final double? lat;
  final double? lon;
  final String? lojaId;

  const ItemHistoricoBuscaMapa({
    required this.titulo,
    this.subtitulo = '',
    this.tipo = 'termo',
    this.lat,
    this.lon,
    this.lojaId,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'subtitulo': subtitulo,
        'tipo': tipo,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (lojaId != null) 'lojaId': lojaId,
      };

  factory ItemHistoricoBuscaMapa.fromJson(Map<String, dynamic> json) {
    return ItemHistoricoBuscaMapa(
      titulo: json['titulo'] as String? ?? '',
      subtitulo: json['subtitulo'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'termo',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      lojaId: json['lojaId'] as String?,
    );
  }
}
