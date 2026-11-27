import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Linha com identificação clicável da loja e card de estrelas/comentários do produto.
class CabecalhoLojaEAvaliacoesProdutoWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja loja;
  final String distanciaFormatada;
  final double mediaEstrelas;
  final int totalAvaliacoes;
  final VoidCallback onAbrirLoja;
  final VoidCallback onAbrirComentarios;

  const CabecalhoLojaEAvaliacoesProdutoWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.distanciaFormatada,
    required this.mediaEstrelas,
    required this.totalAvaliacoes,
    required this.onAbrirLoja,
    required this.onAbrirComentarios,
  });

  @override
  Widget build(BuildContext context) {
    final logoProvider = ImagemService.obterImageProvider(loja.logo);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: onAbrirLoja,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                    backgroundImage: logoProvider,
                    child: logoProvider == null
                        ? Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: theme.textColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                loja.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: theme.secondaryTextColor,
                            ),
                          ],
                        ),
                        Text(
                          distanciaFormatada,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onAbrirComentarios,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.65),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(5, (index) {
                      final v = index + 1;
                      return Icon(
                        v <= mediaEstrelas.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 15,
                        color: theme.textColor,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      mediaEstrelas.toStringAsFixed(1),
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 13,
                      color: theme.secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Comentários ($totalAvaliacoes)',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
