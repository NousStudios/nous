import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class VisorUltimoProdutoWidget extends StatelessWidget {
  final AppTheme theme;
  final ItemLoja? item;
  final ItemVendido? itemVendido;
  final int quantidade;
  final String Function(double valor) formatarValor;

  const VisorUltimoProdutoWidget({
    super.key,
    required this.theme,
    required this.item,
    required this.itemVendido,
    required this.quantidade,
    required this.formatarValor,
  });

  static double _precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final foto = item?.imagens.firstOrNull ?? itemVendido?.foto ?? '';
    final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
    final temFoto = fotoResolvida != null;
    final nomeExibicao = itemVendido?.nomeExibicao ?? item?.nome ?? '';
    final precoUnitario =
        itemVendido?.precoUnitario ?? _precoComoNumero(item?.preco ?? '');
    final totalItem =
        itemVendido?.subtotal ?? (precoUnitario * quantidade);

    final temRegistro = item != null || itemVendido != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              image: temFoto
                  ? DecorationImage(
                      image: FileImage(File(fotoResolvida)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !temFoto
                ? Icon(Icons.shopping_bag_outlined,
                    size: 28, color: theme.textColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temRegistro
                      ? 'ÚLTIMO PRODUTO: $nomeExibicao'
                      : 'NENHUM PRODUTO REGISTRADO AINDA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: temRegistro
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  temRegistro
                      ? 'Qtd: $quantidade | Unitário: R\$ ${formatarValor(precoUnitario)}'
                      : 'Passe o leitor óptico sobre o código de barras',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (temRegistro)
            Text(
              'R\$ ${formatarValor(totalItem)}',
              style: theme.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
        ],
      ),
    );
  }
}
