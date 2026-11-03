import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

/// Bloco que lista as vendas do período financeiro com pesquisa de texto,
/// filtro dinâmico por forma de pagamento e visualização de comprovante de venda.
class BlocoVendasFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final List<PedidoLoja> vendas;
  final TextEditingController pesquisaVendasController;
  final String? formaFiltroVendas;
  final List<String> formasDePagamento;
  final BoxDecoration decoracaoBloco;
  final Widget Function(AppTheme theme, String texto) tituloDoBloco;
  final void Function(String forma) onAlternarFormaPagamento;
  final VoidCallback onChangedPesquisa;
  final UsuarioNous? contaAtual;
  final String emailAtivo;

  const BlocoVendasFinanceiroWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.vendas,
    required this.pesquisaVendasController,
    required this.formaFiltroVendas,
    required this.formasDePagamento,
    required this.decoracaoBloco,
    required this.tituloDoBloco,
    required this.onAlternarFormaPagamento,
    required this.onChangedPesquisa,
    required this.contaAtual,
    required this.emailAtivo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        children: [
          tituloDoBloco(theme, 'Vendas do período'),
          TextField(
            controller: pesquisaVendasController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Pesquisar vendas do período',
              hintStyle: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              prefixIcon: Icon(
                Icons.search,
                size: 16,
                color: theme.secondaryTextColor,
              ),
              filled: true,
              fillColor: theme.cardBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.textColor,
                  width: 1.4,
                ),
              ),
            ),
            onChanged: (_) => onChangedPesquisa(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final forma in formasDePagamento)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: LinhaComHoverWidget(
                      aoClicar: () => onAlternarFormaPagamento(forma),
                      builder: (hover) {
                        final selecionada = formaFiltroVendas == forma;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selecionada
                                ? (hover
                                    ? (theme.buttonColor != Colors.transparent
                                        ? theme.buttonColor
                                            .withValues(alpha: 0.85)
                                        : theme.borderColor
                                            .withValues(alpha: 0.35))
                                    : (theme.buttonColor != Colors.transparent
                                        ? theme.buttonColor
                                        : theme.borderColor
                                            .withValues(alpha: 0.25)))
                                : (hover
                                    ? theme.borderColor.withValues(alpha: 0.18)
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selecionada || hover
                                  ? theme.textColor
                                  : theme.borderColor.withValues(alpha: 0.45),
                              width: selecionada ? 1.6 : 1.0,
                            ),
                          ),
                          child: Text(
                            forma,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: selecionada
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selecionada
                                  ? (theme.buttonColor != Colors.transparent
                                      ? theme.buttonTextColor
                                      : theme.textColor)
                                  : (hover
                                      ? theme.textColor
                                      : theme.secondaryTextColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (vendas.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma venda encontrada no período.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: vendas.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) => BarraVenda(
                  theme: theme,
                  lojaId: lojaId,
                  pedido: vendas[index],
                  mostrarCliente: true,
                  autorCpf: contaAtual?.cpf ?? '',
                  autorNome: contaAtual?.nome ?? '',
                  autorEmail: emailAtivo,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
