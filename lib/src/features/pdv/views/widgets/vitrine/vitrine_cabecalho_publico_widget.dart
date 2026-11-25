import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/cabecalho_perfil_publico_widget.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_editar_perfil_publico_loja.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Cabeçalho público da vitrine da loja com avatar/story, métricas, bio,
/// contatos copiáveis e barra de ações.
class VitrineCabecalhoPublicoWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja loja;
  final List<StorySocial> storiesLoja24h;
  final int totalPostsLoja;
  final bool exibindoTimelineSocial;
  final VoidCallback onSelecionarCompras;
  final VoidCallback onSelecionarPublicacoes;

  const VitrineCabecalhoPublicoWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.storiesLoja24h,
    required this.totalPostsLoja,
    required this.exibindoTimelineSocial,
    required this.onSelecionarCompras,
    required this.onSelecionarPublicacoes,
  });

  static String cpfSocialDaLoja(String idLoja) {
    var hash = 0;
    for (final code in idLoja.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return '99${(hash % 1000000000).toString().padLeft(9, '0')}';
  }

  static Color? parseHexLoja(String hex) {
    if (hex.trim().isEmpty) return null;
    final limpo = hex.replaceAll('#', '').trim();
    final val = int.tryParse(limpo, radix: 16);
    if (val == null) return null;
    return Color(limpo.length == 6 ? (0xFF000000 | val) : val);
  }

  static String formatarCategoriasLoja(String raw) {
    final limpo = raw.trim();
    if (limpo.isEmpty) return 'Loja Nous';
    final partes = limpo
        .split(RegExp(r'[,;•]+'))
        .map((p) {
          final semArroba = p.trim().replaceAll(RegExp(r'^@+'), '');
          if (semArroba.isEmpty) return '';
          final palavras = semArroba
              .replaceAll('_', ' ')
              .split(RegExp(r'\s+'))
              .where((w) => w.isNotEmpty)
              .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
              .toList();
          return palavras.join(' ');
        })
        .where((p) => p.isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Loja Nous' : partes.join(' • ');
  }

  void _copiarTextoVitrine(
    BuildContext context,
    String valor,
    String mensagem,
  ) {
    Clipboard.setData(ClipboardData(text: valor));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meuCpf = auth.cpf.replaceAll(RegExp(r'\D'), '');
    final ehMembroLoja = meuCpf.isNotEmpty &&
        (loja.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == meuCpf ||
            loja.membros.any(
              (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == meuCpf,
            ));
    final provLogo = ImagemService.obterImageProvider(loja.logo);
    final temLogo = provLogo != null;
    final subtituloHandle = formatarCategoriasLoja(loja.categorias);
    final enderecoCompleto = [
      loja.endereco.trim(),
      loja.numero.trim(),
    ].where((e) => e.isNotEmpty).join(', ');
    final biografiaLoja = loja.biografiaPublica.trim().isNotEmpty
        ? loja.biografiaPublica.trim()
        : (enderecoCompleto.isNotEmpty
            ? ''
            : 'Comércio Soberano na Rede Nous • Autoatendimento e Catálogo');
    final pdv = context.read<PdvProvider>();
    final podeEditarPerfilLoja = ehMembroLoja &&
        (pdv.possoEditarDadosLoja(loja.id) ||
            pdv.possoEditarLocalizacaoMapa(loja.id));
    final corDestaqueCustom = parseHexLoja(loja.corDestaquePerfilHex);
    final corBotaoAtivo = corDestaqueCustom ?? theme.buttonColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoPerfilPublicoWidget(
            theme: theme,
            providerFoto: provLogo,
            temFoto: temLogo,
            temStoryAtivo: storiesLoja24h.isNotEmpty,
            corDestaqueAnel: theme.buttonColor,
            iconeFallback: Icons.storefront_rounded,
            raioAvatar: 44,
            tooltipFoto: storiesLoja24h.isNotEmpty
                ? 'Toque para ver o Story da Loja • Segure para ampliar a logo'
                : (temLogo ? 'Toque ou segure para ampliar a logo' : ''),
            onTapFoto: () {
              if (storiesLoja24h.isNotEmpty) {
                DialogVisualizarStory.mostrar(
                  context,
                  theme: theme,
                  story: storiesLoja24h.first,
                  stories: storiesLoja24h,
                  ehAutor: ehMembroLoja,
                  usuarioLogado: auth.contaAtual,
                );
              } else if (temLogo) {
                final resolvido =
                    ImagemService.resolverCaminhoExistente(loja.logo);
                if (resolvido != null) {
                  VisualizadorImagemChatDialog.abrir(
                    context,
                    caminho: resolvido,
                    theme: theme,
                    permitirDownload: true,
                  );
                }
              }
            },
            onLongPressFoto: () {
              if (temLogo) {
                final resolvido =
                    ImagemService.resolverCaminhoExistente(loja.logo);
                if (resolvido != null) {
                  VisualizadorImagemChatDialog.abrir(
                    context,
                    caminho: resolvido,
                    theme: theme,
                    permitirDownload: true,
                  );
                }
              }
            },
            handleTexto: subtituloHandle,
            nomeTexto: loja.nome,
            metricas: [
              MetricaPerfilPublico(
                valor: '${loja.itensLoja.length}',
                rotulo: 'Itens',
              ),
              MetricaPerfilPublico(
                valor: '$totalPostsLoja',
                rotulo: 'Posts',
              ),
              MetricaPerfilPublico(
                valor: '${loja.membros.length}',
                rotulo: 'Equipe',
              ),
            ],
          ),
          if (biografiaLoja.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                biografiaLoja,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
          if (enderecoCompleto.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BuscaMapaView(lojaDestinoInicial: loja),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.textColor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          enderecoCompleto,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (loja.linksPublicos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: loja.linksPublicos.map((link) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      _copiarTextoVitrine(context, link, 'Link copiado!'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      link,
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D9BF0),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (loja.cnpj.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _copiarTextoVitrine(
                  context,
                  loja.cnpj.trim(),
                  'CNPJ copiado!',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 13,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'CNPJ: ${loja.cnpj.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (loja.telefone.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _copiarTextoVitrine(
                  context,
                  loja.telefone.trim(),
                  'Telefone copiado!',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Tel: ${loja.telefone.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final larguraBotao = (constraints.maxWidth - 16) / 3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (podeEditarPerfilLoja) ...[
                      SizedBox(
                        width: larguraBotao,
                        height: 34,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide(color: theme.borderColor),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => DialogEditarPerfilPublicoLoja.mostrar(
                            context,
                            theme: theme,
                            loja: loja,
                          ),
                          child: Text(
                            'Editar Perfil',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    SizedBox(
                      width: larguraBotao,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: !exibindoTimelineSocial
                              ? corBotaoAtivo
                              : Colors.transparent,
                          side: BorderSide(color: theme.borderColor),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onSelecionarCompras,
                        child: Text(
                          'Compras',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !exibindoTimelineSocial
                                ? theme.buttonTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: larguraBotao,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: exibindoTimelineSocial
                              ? theme.buttonColor
                              : Colors.transparent,
                          side: BorderSide(color: theme.borderColor),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onSelecionarPublicacoes,
                        child: Text(
                          'Publicações',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: exibindoTimelineSocial
                                ? theme.buttonTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: larguraBotao,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.borderColor),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final convId = ChatService.conversaIdLojaUsuario(
                            loja.id,
                            meuCpf.isNotEmpty ? meuCpf : 'visitante',
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MensageriaView(
                                modoLoja: false,
                                conversaInicialId: convId,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Mensagens',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Denunciar',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: auth.contaAtual == null
                            ? null
                            : () {
                                DialogDenunciaSocial.mostrar(
                                  context,
                                  theme: theme,
                                  denunciante: auth.contaAtual!,
                                  alvoCpf: cpfSocialDaLoja(loja.id),
                                  alvoNome: loja.nome,
                                );
                              },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
