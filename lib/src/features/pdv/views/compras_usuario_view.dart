import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

class ComprasUsuarioView extends StatelessWidget {
  const ComprasUsuarioView({super.key});

  Widget _buildContainerGenerico({
    required BuildContext context,
    required AppTheme theme,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required String detalhe,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 22, color: theme.buttonColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: titulo,
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: subtitulo,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextoRolante(
                    texto: detalhe,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Compras & Carteira',
            showBackButton: false,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildContainerGenerico(
                      context: context,
                      theme: theme,
                      icone: Icons.account_balance_wallet_outlined,
                      titulo: 'Carteira Soberana',
                      subtitulo: 'Saldos, moedas locais e meios de pagamento',
                      detalhe: 'Em construção • Gestão financeira soberana',
                    ),
                    const SizedBox(height: 16),
                    _buildContainerGenerico(
                      context: context,
                      theme: theme,
                      icone: Icons.shopping_cart_outlined,
                      titulo: 'Carrinho de Compras',
                      subtitulo: 'Itens adicionados de lojas e produtores locais',
                      detalhe: 'Em construção • Catálogo compartilhado em rede',
                    ),
                    const SizedBox(height: 16),
                    _buildContainerGenerico(
                      context: context,
                      theme: theme,
                      icone: Icons.receipt_long_outlined,
                      titulo: 'Histórico de Compras',
                      subtitulo: 'Recibos, pedidos anteriores e notas fiscais',
                      detalhe: 'Em construção • Registro transparente e imutável',
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const FloatingBottomNavBar(
            maxWidth: 600,
            slotSelecionado: 0,
            subIndiceSelecionado: 0,
          ),
        );
      },
    );
  }
}
