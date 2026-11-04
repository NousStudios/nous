import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_controller.dart';
import '../../../models/cliente.dart';

/// Widget responsável pela seleção e busca de clientes no diálogo de Nova Venda.
class ClienteSeletorNovaVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController clienteController;
  final FocusNode clienteFocusNode;
  final Cliente? clienteSelecionado;
  final bool clienteFocado;
  final List<Cliente> sugestoes;
  final List<Cliente> todosClientes;
  final ValueChanged<bool> onClienteFocadoChanged;
  final ValueChanged<String> onDigitarCliente;
  final ValueChanged<Cliente> onSelecionarCliente;
  final VoidCallback onNovoCliente;
  final String Function(Cliente) obterDadoPrioritario;
  final double Function(Cliente)? obterDividaCliente;
  final BoxDecoration decoracaoDoBloco;
  final InputDecoration Function(String) decoracaoCampo;
  final Widget Function(String) tituloDoBloco;
  final Widget Function(String, VoidCallback) botaoPequeno;

  const ClienteSeletorNovaVendaWidget({
    super.key,
    required this.theme,
    required this.clienteController,
    required this.clienteFocusNode,
    required this.clienteSelecionado,
    required this.clienteFocado,
    required this.sugestoes,
    required this.todosClientes,
    required this.onClienteFocadoChanged,
    required this.onDigitarCliente,
    required this.onSelecionarCliente,
    required this.onNovoCliente,
    required this.obterDadoPrioritario,
    this.obterDividaCliente,
    required this.decoracaoDoBloco,
    required this.decoracaoCampo,
    required this.tituloDoBloco,
    required this.botaoPequeno,
  });

  String _formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Widget _badgeDivida(double divida) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.dangerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dangerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        'Deve ${_formatarMoeda(divida)}',
        style: theme.getTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.dangerColor,
        ),
      ),
    );
  }

  Widget _linhaDeCliente(Cliente cliente) {
    final infoSecundaria = obterDadoPrioritario(cliente);
    final divida = obterDividaCliente?.call(cliente) ?? 0.0;
    final temDivida = divida > 0.005;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelecionarCliente(cliente),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                cliente.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            if (infoSecundaria.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Text(
                  infoSecundaria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
            if (temDivida) ...[
              const SizedBox(width: 8),
              _badgeDivida(divida),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostrarSugestoes = clienteFocado ||
        (clienteController.text.trim().isNotEmpty &&
            clienteSelecionado == null);
    final listaSugestoes = mostrarSugestoes ? sugestoes : <Cliente>[];

    return TapRegion(
      groupId: 'busca_cliente',
      onTapOutside: (_) {
        if (clienteFocado) {
          onClienteFocadoChanged(false);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: decoracaoDoBloco,
        child: Column(
          children: [
            tituloDoBloco('Nome do Cliente'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: clienteController,
                    focusNode: clienteFocusNode,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: decoracaoCampo('Nome do cliente'),
                    onTap: () {
                      onClienteFocadoChanged(true);
                      if (clienteController.text.isNotEmpty) {
                        clienteController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: clienteController.text.length,
                        );
                      }
                    },
                    onChanged: onDigitarCliente,
                  ),
                ),
                const SizedBox(width: 8),
                botaoPequeno('Novo Cliente', onNovoCliente),
              ],
            ),
            if (mostrarSugestoes) ...[
              const SizedBox(height: 8),
              if (listaSugestoes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    todosClientes.isEmpty
                        ? 'Nenhum cliente cadastrado ainda.'
                        : 'Nenhum resultado.',
                    style: theme.getTextStyle(fontSize: 11),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: listaSugestoes.length,
                    itemBuilder: (context, index) =>
                        _linhaDeCliente(listaSugestoes[index]),
                  ),
                ),
            ],
            if (clienteSelecionado != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final info = obterDadoPrioritario(clienteSelecionado!);
                  final divida =
                      obterDividaCliente?.call(clienteSelecionado!) ?? 0.0;
                  final temDivida = divida > 0.005;
                  return Row(
                    children: [
                      Text(
                        'Cliente selecionado: ',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (info.isNotEmpty)
                        Expanded(
                          child: Text(
                            info,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (temDivida) ...[
                        const SizedBox(width: 8),
                        _badgeDivida(divida),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
