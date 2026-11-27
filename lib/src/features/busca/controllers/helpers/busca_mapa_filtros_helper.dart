import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

class BuscaMapaFiltrosHelper {
  const BuscaMapaFiltrosHelper._();

  /// Calcula a distância geográfica em km (fórmula de Haversine) entre dois pontos
  static double? calcularDistanciaKm({
    required double? lat1,
    required double? lon1,
    required double? lat2,
    required double? lon2,
  }) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  static double _melhorScore(List<String> campos, String termo) {
    var melhor = 0.0;
    for (final c in campos) {
      if (c.trim().isEmpty) continue;
      final s = TextoUtils.calcularRelevanciaBusca(c, termo);
      if (s > melhor) melhor = s;
    }
    return melhor;
  }

  static List<T> _filtrarEOrdenar<T>(
    List<T> itens,
    String termoBusca,
    List<String> Function(T item) camposDe,
  ) {
    final q = termoBusca.trim();
    if (q.isEmpty) return List<T>.from(itens);
    final pontuados = <(T item, double score)>[];
    for (final item in itens) {
      final score = _melhorScore(camposDe(item), q);
      if (score > 0.0) {
        pontuados.add((item, score));
      }
    }
    pontuados.sort((a, b) => b.$2.compareTo(a.$2));
    return pontuados.map((e) => e.$1).toList();
  }

  static List<Loja> filtrarLojas(List<Loja> lojas, String termoBusca) {
    return _filtrarEOrdenar(
      lojas,
      termoBusca,
      (l) => [l.nome, l.categorias, l.tags, l.endereco],
    );
  }

  static List<UsuarioNous> filtrarPerfis(
    List<UsuarioNous> usuarios,
    String termoBusca,
  ) {
    return _filtrarEOrdenar(
      usuarios,
      termoBusca,
      (u) => [u.nome, u.apelido, u.nomeDeUsuario],
    );
  }

  static List<ProdutoMapaItem> filtrarProdutos(
    List<Loja> lojas,
    String termoBusca,
    Set<FiltroBuscaMapa> filtrosAtivos, {
    double? latUsuario,
    double? lonUsuario,
    Map<String, LatLng>? coordenadasLojas,
  }) {
    final filtraProd = filtrosAtivos.contains(FiltroBuscaMapa.produtos);
    final filtraServ = filtrosAtivos.contains(FiltroBuscaMapa.servicos);
    final restringirTipo = !filtrosAtivos.contains(FiltroBuscaMapa.todos) &&
        (filtraProd != filtraServ);

    final candidatos = <ProdutoMapaItem>[];
    for (final loja in lojas) {
      final coordMapa = coordenadasLojas?[loja.id];
      final latLoja = loja.latitude ?? coordMapa?.latitude;
      final lonLoja = loja.longitude ?? coordMapa?.longitude;
      final distKm = calcularDistanciaKm(
        lat1: latUsuario,
        lon1: lonUsuario,
        lat2: latLoja,
        lon2: lonLoja,
      );

      final itensPorId = {for (final i in loja.itensLoja) i.id: i};
      final idsEmCategorias = <String>{};

      // 1. Produtos e Serviços combinados com Categorias (ex: Açaí + Copo de 300ml = R$ 22,00)
      for (final categoria in loja.categoriasLoja) {
        for (final itemId in categoria.itemIds) {
          final item = itensPorId[itemId];
          if (item == null) continue;

          final ehServico = item.tipo == TipoItemLoja.servico ||
              categoria.tipo == TipoItemLoja.servico;
          if (restringirTipo) {
            if (filtraServ && !ehServico) continue;
            if (filtraProd && ehServico) continue;
          }

          idsEmCategorias.add(item.id);
          candidatos.add(
            ProdutoMapaItem(
              item: item,
              loja: loja,
              distanciaKm: distKm,
              categoria: categoria,
            ),
          );
        }
      }

      // 2. Itens avulsos ou não vinculados a categorias
      for (final item in loja.itensLoja) {
        final ehServico = item.tipo == TipoItemLoja.servico;
        if (restringirTipo) {
          if (filtraServ && !ehServico) continue;
          if (filtraProd && ehServico) continue;
        }

        // Se o item não está em nenhuma categoria, ou se foi cadastrado com preço próprio para venda avulsa
        final jaInseridoComCategoria = idsEmCategorias.contains(item.id);
        if (!jaInseridoComCategoria || item.preco.trim().isNotEmpty) {
          candidatos.add(
            ProdutoMapaItem(
              item: item,
              loja: loja,
              distanciaKm: distKm,
              categoria: null,
            ),
          );
        }
      }
    }

    final filtrados = _filtrarEOrdenar(
      candidatos,
      termoBusca,
      (p) => [
        p.nomeExibicao,
        p.item.nome,
        p.categoria?.nome ?? '',
        p.item.descricao,
        p.loja.nome,
        p.loja.categorias,
        p.loja.tags,
      ],
    );

    // Ordenação gradual por proximidade: itens mais próximos do usuário primeiro,
    // mantendo itens distantes (ex: outro estado) abaixo caso existam.
    if (latUsuario != null && lonUsuario != null) {
      filtrados.sort((a, b) {
        if (a.distanciaKm != null && b.distanciaKm != null) {
          return a.distanciaKm!.compareTo(b.distanciaKm!);
        }
        if (a.distanciaKm != null) return -1;
        if (b.distanciaKm != null) return 1;
        return 0;
      });
    }

    return filtrados;
  }

  static List<ProjetoComunitario> filtrarProjetos(
    List<ProjetoComunitario> projetos,
    String termoBusca,
  ) {
    return _filtrarEOrdenar(
      projetos,
      termoBusca,
      (p) => [p.titulo, p.descricao, p.categoria, p.enderecoResumo],
    );
  }

  static List<PublicacaoSocial> filtrarPublicacoes(
    List<PublicacaoSocial> publicacoes,
    String termoBusca,
  ) {
    if (termoBusca.trim().isEmpty) return const [];
    return _filtrarEOrdenar(
      publicacoes,
      termoBusca,
      (pub) => [
        pub.texto,
        pub.autorNome,
        ...pub.midias.map((m) => m.nomeArquivo),
      ],
    );
  }
}
