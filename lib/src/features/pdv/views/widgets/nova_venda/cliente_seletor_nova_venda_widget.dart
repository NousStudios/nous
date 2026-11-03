import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_controller.dart';
import '../../../../../core/widgets/texto_rolante.dart';
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
    required this.decoracaoDoBloco,
    required this.decoracaoCampo,
    required this.tituloDoBloco,
    required this.botaoPequeno,
  });

  Widget _linhaDeCliente(Cliente cliente) {
    final infoSecundaria = obterDadoPrioritario(cliente);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelecionarCliente(cliente),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: TextoRolante(
                texto: cliente.nome,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
            if (infoSecundaria.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextoRolante(
                    texto: infoSecundaria,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final cliente in listaSugestoes)
                          _linhaDeCliente(cliente),
                      ],
                    ),
                  ),
                ),
            ],
            if (clienteSelecionado != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final info = obterDadoPrioritario(clienteSelecionado!);
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
                          child: TextoRolante(
                            texto: info,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
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
