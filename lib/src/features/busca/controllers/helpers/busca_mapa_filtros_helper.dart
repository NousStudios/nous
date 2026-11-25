import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

class BuscaMapaFiltrosHelper {
  const BuscaMapaFiltrosHelper._();

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
    FiltroBuscaMapa filtroAtivo,
  ) {
    final candidatos = <ProdutoMapaItem>[];
    for (final loja in lojas) {
      for (final item in loja.itensLoja) {
        final ehServico = item.tipo == TipoItemLoja.servico;
        if (filtroAtivo == FiltroBuscaMapa.servicos && !ehServico) continue;
        if (filtroAtivo == FiltroBuscaMapa.produtos && ehServico) continue;
        candidatos.add(ProdutoMapaItem(item: item, loja: loja));
      }
    }
    return _filtrarEOrdenar(
      candidatos,
      termoBusca,
      (p) => [p.item.nome, p.item.descricao, p.loja.nome],
    );
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
