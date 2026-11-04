import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class ListaPesquisaClientesWidget extends StatelessWidget {
  final AppTheme theme;
  final bool expandido;
  final List<Cliente> clientes;
  final TextEditingController pesquisaController;
  final ValueChanged<Cliente> onSelecionarCliente;
  final VoidCallback onPesquisaAlterada;
  final double Function(Cliente)? obterDividaCliente;

  const ListaPesquisaClientesWidget({
    super.key,
    required this.theme,
    required this.expandido,
    required this.clientes,
    required this.pesquisaController,
    required this.onSelecionarCliente,
    required this.onPesquisaAlterada,
    this.obterDividaCliente,
  });

  String _formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  InputDecoration _decoracaoPesquisa(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIcon: Icon(
        Icons.search,
        size: 18,
        color: theme.secondaryTextColor,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final termo = pesquisaController.text.trim();
    final filtrados = termo.isEmpty
        ? clientes
        : clientes.where((c) => c.correspondeABusca(termo)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Clientes Cadastrados',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: pesquisaController,
              onChanged: (_) => onPesquisaAlterada(),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              decoration:
                  _decoracaoPesquisa('Pesquisar por nome, rua, número, CPF...'),
            ),
          ),
          if (clientes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente cadastrado ainda.',
            )
          else if (filtrados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente encontrado.',
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: expandido ? 490 : 200,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cliente = filtrados[index];
                  final temEndereco =
                      cliente.endereco.isNotEmpty || cliente.numero.isNotEmpty;
                  final enderecoTexto = [
                    if (cliente.endereco.isNotEmpty) cliente.endereco,
                    if (cliente.numero.isNotEmpty) 'nº ${cliente.numero}',
                  ].join(', ');
                  final divida = obterDividaCliente?.call(cliente) ?? 0.0;
                  final temDivida = divida > 0.005;

                  return _LinhaClienteHover(
                    aoClicar: () => onSelecionarCliente(cliente),
                    builder: (hover) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hover
                            ? theme.borderColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: hover ? theme.textColor : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final fotoCliente =
                                  ImagemService.resolverCaminhoExistente(
                                      cliente.foto);
                              return CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.transparent,
                                backgroundImage: fotoCliente != null
                                    ? FileImage(File(fotoCliente))
                                    : null,
                                child: fotoCliente == null
                                    ? Icon(
                                        Icons.account_circle,
                                        size: 22,
                                        color: theme.textColor,
                                      )
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cliente.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (temEndereco)
                                  Text(
                                    enderecoTexto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (cliente.telefone.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                cliente.telefone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.getTextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                          if (temDivida) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaClienteHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaClienteHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaClienteHover> createState() => _LinhaClienteHoverState();
}

class _LinhaClienteHoverState extends State<_LinhaClienteHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}
