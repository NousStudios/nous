import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_publicacao_completo_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/feed/card_produto_feed_comercio_widget.dart';

class FeedDescobertaSliverLista extends StatelessWidget {
  final AppTheme theme;
  final bool carregando;
  final bool carregandoMais;
  final bool modoApenasAmigos;
  final List<PublicacaoSocial> publicacoes;
  final List<ProdutoMapaItem> produtosComercio;
  final UsuarioNous? usuarioLogado;
  final ValueChanged<String> onTapTag;

  const FeedDescobertaSliverLista({
    super.key,
    required this.theme,
    required this.carregando,
    required this.carregandoMais,
    required this.modoApenasAmigos,
    required this.publicacoes,
    this.produtosComercio = const [],
    required this.usuarioLogado,
    required this.onTapTag,
  });

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (publicacoes.isEmpty && produtosComercio.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: EstadoVazioContainer(
                theme: theme,
                mensagem: modoApenasAmigos
                    ? 'Siga outros usuários Nous para acompanhar as publicações deles aqui.'
                    : 'Nenhuma publicação encontrada para esta timeline ainda.',
              ),
            ),
          ),
        ),
      );
    }

    final totalItens = produtosComercio.length +
        publicacoes.length +
        (carregandoMais ? 1 : 0);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      sliver: SliverList.builder(
        itemCount: totalItens,
        itemBuilder: (context, index) {
          if (index < produtosComercio.length) {
            final prod = produtosComercio[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: CardProdutoFeedComercioWidget(
                  key: ValueKey(
                    'prod_desc_${prod.loja.id}_${prod.item.id}_${prod.categoria?.id ?? ''}',
                  ),
                  theme: theme,
                  produto: prod,
                ),
              ),
            );
          }

          final idxPub = index - produtosComercio.length;
          if (idxPub >= publicacoes.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final pub = publicacoes[idxPub];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: pub.tipo == TipoFeedSocial.escritos
                  ? CardEscritoWidget(
                      key: ValueKey('pub_desc_${pub.id}'),
                      theme: theme,
                      publicacao: pub,
                      usuarioLogado: usuarioLogado,
                      listaPublicacoes: publicacoes,
                      indiceInicial: idxPub,
                      abrirDetalhesAoTocarCabecalho: true,
                      onTapTag: onTapTag,
                    )
                  : CardPublicacaoCompletoWidget(
                      key: ValueKey('pub_desc_${pub.id}'),
                      theme: theme,
                      publicacao: pub,
                      usuarioLogado: usuarioLogado,
                      listaPublicacoes: publicacoes,
                      indiceInicial: idxPub,
                      abrirDetalhesAoTocarCabecalho: true,
                      onTapTag: onTapTag,
                    ),
            ),
          );
        },
      ),
    );
  }
}
