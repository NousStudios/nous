import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Bloco de listagem detalhada dos itens vendidos, variantes e acompanhamentos.
class BlocoItensVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final double larguraBloco;

  const BlocoItensVendaWidget({
    super.key,
    required this.theme,
    required this.pedido,
    required this.larguraBloco,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pedido.itens.isEmpty) {
      return Center(
        child: Container(
          width: larguraBloco,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: _decoracaoDoBloco,
          child: Column(
            children: [
              _tituloDoBloco('Itens'),
              EstadoVazioContainer(
                theme: theme,
                mensagem: 'Sem itens detalhados nesta venda.',
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Itens'),
            for (final item in pedido.itens) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantidade}x ${item.nomeExibicao}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          _valor(item.subtotalBase),
                          style: theme.getTextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    for (final a in item.acompanhamentos)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              _valor(a.precoItem *
                                  a.quantidadePorUnidade *
                                  item.quantidade),
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.observacao.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 3),
                        child: Text(
                          'Obs: ${item.observacao.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
