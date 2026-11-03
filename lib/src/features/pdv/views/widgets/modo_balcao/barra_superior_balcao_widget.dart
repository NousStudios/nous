import 'package:flutter/material.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra superior informativa e de navegação rápida do Modo Balcão / Frente de Caixa.
class BarraSuperiorBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final String nomeLoja;
  final String logoLoja;
  final bool caixaAberto;
  final VoidCallback onSair;
  final VoidCallback onLimparVenda;

  const BarraSuperiorBalcaoWidget({
    super.key,
    required this.theme,
    required this.nomeLoja,
    required this.logoLoja,
    required this.caixaAberto,
    required this.onSair,
    required this.onLimparVenda,
  });

  @override
  Widget build(BuildContext context) {
    final providerLogo = ImagemService.obterImageProvider(logoLoja);
    final temLogo = providerLogo != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onSair,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              'Voltar ao PDV (Esc)',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.borderColor.withValues(alpha: 0.3),
            backgroundImage: providerLogo,
            child: !temLogo
                ? Icon(Icons.storefront, size: 16, color: theme.textColor)
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nomeLoja.isNotEmpty ? nomeLoja : 'Minha Loja',
                style: theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: caixaAberto
                          ? const Color(0xFF4CAF50)
                          : theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    caixaAberto ? 'Caixa Aberto' : 'Caixa Fechado',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.textColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.point_of_sale_rounded,
                    size: 16, color: theme.textColor),
                const SizedBox(width: 8),
                Text(
                  'MODO BALCÃO • FRENTE DE CAIXA',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ).copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.fullscreen_rounded,
                color: theme.textColor, size: 20),
            tooltip: 'Alternar Tela Cheia (F11)',
            onPressed: () => JanelaWindowsService.alternarTelaCheia(),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined,
                color: theme.secondaryTextColor, size: 20),
            tooltip: 'Limpar Venda Atual',
            onPressed: onLimparVenda,
          ),
        ],
      ),
    );
  }
}
