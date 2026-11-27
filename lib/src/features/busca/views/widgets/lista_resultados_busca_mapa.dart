import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/views/detalhes_produto_mercado_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';

class ListaResultadosBuscaMapa extends StatelessWidget {
  final BuscaMapaController controller;
  final AppTheme theme;

  const ListaResultadosBuscaMapa({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final filtros = controller.filtrosAtivos;
    final semFiltro = controller.semFiltroEspecifico;

    final mostrarEnderecos =
        semFiltro || filtros.contains(FiltroBuscaMapa.enderecos);
    final mostrarLojas =
        semFiltro || filtros.contains(FiltroBuscaMapa.lojas);
    final mostrarProdutos = semFiltro ||
        filtros.contains(FiltroBuscaMapa.produtos) ||
        filtros.contains(FiltroBuscaMapa.servicos);
    final mostrarPerfis =
        semFiltro || filtros.contains(FiltroBuscaMapa.perfis);
    final mostrarProjetos =
        semFiltro || filtros.contains(FiltroBuscaMapa.projetos);

    final enderecos = mostrarEnderecos
        ? controller.enderecosEncontrados
        : const [];
    final lojas = mostrarLojas ? controller.lojasFiltradas : const [];
    final produtos =
        mostrarProdutos ? controller.produtosFiltrados : const [];
    final perfis = mostrarPerfis ? controller.perfisFiltrados : const [];
    final projetos =
        mostrarProjetos ? controller.projetosFiltrados : const [];
    final publicacoes =
        semFiltro ? controller.publicacoesFiltradas : const [];

    final termoLimpo = controller.termoBusca.trim().toLowerCase();
    final temResultadosLocais = lojas.isNotEmpty ||
        produtos.isNotEmpty ||
        perfis.isNotEmpty ||
        projetos.isNotEmpty ||
        publicacoes.isNotEmpty;
    final pareceEndereco = RegExp(
      r'^(rua|r\.|av|avenida|praça|praca|alameda|rodovia|travessa|estrada|cep)\b|\b\d{5}-?\d{3}\b|,\s*\d+',
    ).hasMatch(termoLimpo);
    final enderecosNoTopo = pareceEndereco || !temResultadosLocais;

    final secaoEnderecos = <Widget>[
      if (controller.buscandoEnderecos && enderecosNoTopo)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Buscando endereços...',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      if (enderecos.isNotEmpty) ...[
        _tituloSecao('Endereços'),
        ...enderecos.map((end) {
          return ListTile(
            dense: true,
            leading: Icon(Icons.place_outlined, color: theme.textColor),
            title: Text(
              end.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            subtitle: end.subtitulo.isNotEmpty
                ? Text(
                    end.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  )
                : null,
            onTap: () {
              controller.registrarHistoricoBusca(
                ItemHistoricoBuscaMapa(
                  titulo: end.titulo,
                  subtitulo: end.subtitulo,
                  tipo: 'endereco',
                  lat: end.coordenada.latitude,
                  lon: end.coordenada.longitude,
                ),
              );
              controller.tracarRotaPara(
                destino: end.coordenada,
                destinoLabel: end.titulo,
              );
            },
          );
        }),
      ],
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.56,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        children: [
          if (controller.termoBusca.trim().isEmpty &&
              controller.historicoBusca.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tituloSecao('Pesquisas recentes'),
                TextButton(
                  onPressed: controller.limparHistoricoBusca,
                  child: Text(
                    'Limpar',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            ...controller.historicoBusca.map((item) {
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                title: Text(
                  item.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: item.subtitulo.isNotEmpty
                    ? Text(
                        item.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      )
                    : null,
                trailing: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
                  onPressed: () =>
                      controller.removerHistoricoBusca(item.titulo),
                ),
                onTap: () {
                  if (item.lat != null && item.lon != null) {
                    controller.tracarRotaPara(
                      destino: LatLng(item.lat!, item.lon!),
                      destinoLabel: item.titulo,
                    );
                  } else if (item.lojaId != null) {
                    final loja = controller.lojas
                        .where((l) => l.id == item.lojaId)
                        .firstOrNull;
                    if (loja != null) {
                      controller.definirPainelBusca(false);
                      controller.selecionarLoja(loja);
                      return;
                    }
                    controller.atualizarBusca(item.titulo);
                  } else {
                    controller.atualizarBusca(item.titulo);
                  }
                },
              );
            }),
            const Divider(height: 12),
          ],

          if (enderecosNoTopo) ...secaoEnderecos,

          if (lojas.isNotEmpty) ...[
            _tituloSecao('Lojas (${lojas.length})'),
            ...lojas.take(8).map((loja) {
              final logo = ImagemService.resolverCaminhoExistente(loja.logo);
              final coordLoja = controller.coordenadasLojas[loja.id];
              final temCoord = coordLoja != null;
              final posUser = controller.posicaoUsuario;
              String distStr = '';
              if (temCoord && posUser != null) {
                final metros = MapaGeoService.distanciaMetros(posUser, coordLoja);
                distStr = metros >= 1000
                    ? '${(metros / 1000).toStringAsFixed(1)} km'
                    : '${metros.round()} m';
              }
              final endTexto = [loja.endereco, loja.numero]
                  .where((e) => e.trim().isNotEmpty)
                  .join(', ');
              final subtexto = distStr.isNotEmpty
                  ? (endTexto.isNotEmpty ? '$distStr • $endTexto' : distStr)
                  : endTexto;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                  backgroundImage: logo != null ? FileImage(File(logo)) : null,
                  child: logo == null
                      ? Icon(Icons.storefront_rounded,
                          size: 17, color: theme.textColor)
                      : null,
                ),
                title: Text(
                  loja.nome,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  subtexto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                trailing: Icon(
                  temCoord
                      ? Icons.location_searching_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                onTap: () {
                  final coord = controller.coordenadasLojas[loja.id];
                  controller.registrarHistoricoBusca(
                    ItemHistoricoBuscaMapa(
                      titulo: loja.nome,
                      subtitulo: [loja.endereco, loja.numero]
                          .where((e) => e.trim().isNotEmpty)
                          .join(', '),
                      tipo: 'loja',
                      lojaId: loja.id,
                      lat: coord?.latitude,
                      lon: coord?.longitude,
                    ),
                  );
                  controller.definirPainelBusca(false);
                  if (temCoord) {
                    controller.selecionarLoja(loja);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VitrineLojaView(
                          lojaId: loja.id,
                          lojaFallback: loja,
                        ),
                      ),
                    );
                  }
                },
              );
            }),
          ],

          if (produtos.isNotEmpty) ...[
            _tituloSecao('Produtos & Serviços (${produtos.length})'),
            ...produtos.take(8).map((p) {
              final foto = ImagemService.resolverCaminhoExistente(p.fotoDestaque);
              return ListTile(
                dense: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: theme.borderColor.withValues(alpha: 0.25),
                    child: foto != null
                        ? Image.file(
                            File(foto),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: theme.textColor,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: theme.textColor,
                          ),
                  ),
                ),
                title: Text(
                  p.nomeExibicao,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  '${p.loja.nome} • ${p.precoTexto} • ${p.distanciaFormatada}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetalhesProdutoMercadoView(produto: p),
                    ),
                  );
                },
              );
            }),
          ],

          if (perfis.isNotEmpty) ...[
            _tituloSecao('Perfis (${perfis.length})'),
            ...perfis.take(8).map((perfil) {
              final foto =
                  ImagemService.resolverCaminhoExistente(perfil.fotoExibicao);
              final meuCpf = auth.cpf.replaceAll(RegExp(r'\D'), '');
              final alvoCpf = perfil.cpf.replaceAll(RegExp(r'\D'), '');
              final ehProprio = meuCpf.isNotEmpty && meuCpf == alvoCpf;
              final seguindo = auth.contaAtual?.estaSeguindo(perfil.cpf) ?? false;

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 17,
                  backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                  backgroundImage: foto != null ? FileImage(File(foto)) : null,
                  child: foto == null
                      ? Icon(Icons.person_rounded,
                          size: 17, color: theme.textColor)
                      : null,
                ),
                title: Text(
                  perfil.nome.isNotEmpty
                      ? perfil.nome
                      : perfil.usernameExibicao,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: perfil.usernameExibicao.isNotEmpty
                    ? Text(
                        perfil.usernameExibicao,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      )
                    : null,
                trailing: ehProprio
                    ? null
                    : TextButton(
                        onPressed: () =>
                            auth.alternarSeguir(perfil.cpf),
                        child: Text(
                          seguindo ? 'Seguindo' : 'Seguir',
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: seguindo
                                ? theme.secondaryTextColor
                                : theme.buttonColor,
                          ),
                        ),
                      ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PerfilSocialView(
                        usuarioAlvo: perfil,
                        mostrarBotaoVoltar: true,
                      ),
                    ),
                  );
                },
              );
            }),
          ],

          if (projetos.isNotEmpty) ...[
            _tituloSecao('Projetos Comunitários (${projetos.length})'),
            ...projetos.take(8).map((proj) {
              return ListTile(
                dense: true,
                leading: Icon(Icons.handyman_outlined,
                    size: 18, color: theme.textColor),
                title: Text(
                  proj.titulo,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  '${proj.categoria} • ${proj.enderecoResumo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                onTap: () {
                  controller.definirPainelBusca(false);
                  controller.selecionarProjeto(proj);
                },
              );
            }),
          ],

          if (publicacoes.isNotEmpty) ...[
            _tituloSecao('Publicações (${publicacoes.length})'),
            ...publicacoes.take(6).map((pub) {
              return ListTile(
                dense: true,
                leading: Icon(Icons.article_outlined,
                    size: 18, color: theme.textColor),
                title: Text(
                  pub.texto.isNotEmpty ? pub.texto : pub.autorNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  'Por ${pub.autorNome}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                onTap: () {
                  DialogDetalhesPublicacao.mostrar(
                    context,
                    theme: theme,
                    publicacao: pub,
                    usuarioLogado: auth.contaAtual,
                  );
                },
              );
            }),
          ],

          if (!enderecosNoTopo) ...secaoEnderecos,

          if (enderecos.isEmpty &&
              lojas.isEmpty &&
              produtos.isEmpty &&
              perfis.isEmpty &&
              projetos.isEmpty &&
              publicacoes.isEmpty &&
              !controller.buscandoEnderecos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Nenhum resultado encontrado.',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
      child: Text(
        texto,
        style: theme.getTextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }
}
