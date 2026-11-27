import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
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
  final double? distanciaKm;
  final CategoriaLoja? categoria;

  const ProdutoMapaItem({
    required this.item,
    required this.loja,
    this.distanciaKm,
    this.categoria,
  });

  /// Nome formatado para exibição comercial: se o item estiver associado a uma categoria
  /// (ex: Açaí com Copo de 300ml), exibe "Açaí - Copo 300ml".
  String get nomeExibicao {
    if (categoria != null && categoria!.nome.trim().isNotEmpty) {
      final catNome = categoria!.nome.trim();
      final itemNome = item.nome.trim();
      if (itemNome.toLowerCase().contains(catNome.toLowerCase())) {
        return itemNome;
      }
      return '$catNome - $itemNome';
    }
    return item.nome.trim();
  }

  /// Preço unitário total: soma o preço base do item (ou a menor variante se o preço base for vazio)
  /// com o preço base da categoria associada (ex: R$ 2,00 do copo + R$ 20,00 da categoria Açaí = R$ 22,00).
  double get precoTotal {
    final pCat = categoria != null
        ? CarrinhoComprasService.parsePreco(categoria!.preco)
        : 0.0;
    final pItem = CarrinhoComprasService.parsePreco(item.preco);
    if (pItem > 0) {
      return pItem + pCat;
    }
    final menorVar = _menorPrecoVariante();
    if (menorVar > 0) {
      return menorVar + pCat;
    }
    return pCat;
  }

  double _menorPrecoVariante() {
    double? menor;
    for (final v in item.variantes) {
      final pv = CarrinhoComprasService.parsePreco(v.preco);
      if (pv > 0 && (menor == null || pv < menor)) {
        menor = pv;
      }
    }
    return menor ?? 0.0;
  }

  bool get precoEhAPartir {
    final pItem = CarrinhoComprasService.parsePreco(item.preco);
    if (pItem > 0) return false;
    final precosValidos = item.variantes
        .map((v) => CarrinhoComprasService.parsePreco(v.preco))
        .where((p) => p > 0)
        .toSet();
    return precosValidos.length > 1;
  }

  /// Texto do preço formatado em Real (R$) ou 'Sob consulta'
  String get precoTexto {
    final total = precoTotal;
    if (total > 0) {
      final valorFmt = 'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
      return precoEhAPartir ? 'A partir de $valorFmt' : valorFmt;
    }
    if (item.preco.trim().isNotEmpty) return item.preco;
    return 'Sob consulta';
  }

  /// Lista completa de fotos do item (com fallback para a foto da categoria)
  List<String> get todasFotos {
    final fotos = item.imagens
        .where((img) => img.trim().isNotEmpty)
        .toList();
    if (fotos.isNotEmpty) return fotos;
    if (categoria != null && categoria!.foto.trim().isNotEmpty) {
      return [categoria!.foto];
    }
    return const [];
  }

  /// Foto em destaque: prioriza foto do item, fallback para foto da categoria
  String get fotoDestaque {
    final fotos = todasFotos;
    return fotos.isNotEmpty ? fotos.first : '';
  }

  /// Grupos de acompanhamentos/adicionais associados a esta oferta comercial
  List<String> get grupoIdsAcompanhamentos {
    if (categoria != null && categoria!.grupoIds.isNotEmpty) {
      return categoria!.grupoIds;
    }
    final ids = <String>{};
    for (final c in loja.categoriasLoja) {
      if (c.itemIds.contains(item.id)) {
        ids.addAll(c.grupoIds);
      }
    }
    return ids.toList();
  }

  String get distanciaFormatada {
    if (distanciaKm == null) return 'Disponível online';
    if (distanciaKm! < 1.0) {
      final metros = (distanciaKm! * 1000).round();
      return '$metros m de você';
    }
    if (distanciaKm! < 100) {
      return '${distanciaKm!.toStringAsFixed(1)} km de você';
    }
    return '${distanciaKm!.round()} km de você';
  }

  ProdutoMapaItem copyWith({
    ItemLoja? item,
    Loja? loja,
    double? distanciaKm,
    CategoriaLoja? categoria,
  }) {
    return ProdutoMapaItem(
      item: item ?? this.item,
      loja: loja ?? this.loja,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      categoria: categoria ?? this.categoria,
    );
  }
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
