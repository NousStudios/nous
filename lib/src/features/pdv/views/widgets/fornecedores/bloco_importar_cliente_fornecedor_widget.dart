import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Bloco que permite selecionar um cliente para copiar seus dados como fornecedor.
class BlocoImportarClienteFornecedorWidget extends StatefulWidget {
  final AppTheme theme;
  final List<Cliente> clientes;
  final bool Function(Cliente) clienteJaEhFornecedor;
  final ValueChanged<Cliente> onCopiarCliente;

  const BlocoImportarClienteFornecedorWidget({
    super.key,
    required this.theme,
    required this.clientes,
    required this.clienteJaEhFornecedor,
    required this.onCopiarCliente,
  });

  @override
  State<BlocoImportarClienteFornecedorWidget> createState() =>
      _BlocoImportarClienteFornecedorWidgetState();
}

class _BlocoImportarClienteFornecedorWidgetState
    extends State<BlocoImportarClienteFornecedorWidget> {
  final _pesquisaClientesController = TextEditingController();

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _pesquisaClientesController.dispose();
    super.dispose();
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

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
    final termo = _pesquisaClientesController.text.trim();
    final disponiveis = termo.isEmpty
        ? widget.clientes
        : widget.clientes
            .where((c) => c.correspondeABusca(termo))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Usar cliente como fornecedor'),
          Text(
            'Clique em um cliente para preencher o formulário com os '
            'dados dele. Você pode ajustar antes de salvar.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pesquisaClientesController,
            onChanged: (_) => setState(() {}),
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoPesquisa('Pesquisar clientes...'),
          ),
          const SizedBox(height: 10),
          if (widget.clientes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente cadastrado ainda.',
            )
          else if (disponiveis.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente encontrado.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: disponiveis.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cliente = disponiveis[index];
                  final jaEh = widget.clienteJaEhFornecedor(cliente);
                  return _LinhaClienteHover(
                    aoClicar: jaEh
                        ? () {}
                        : () => widget.onCopiarCliente(cliente),
                    builder: (hover) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hover && !jaEh
                            ? theme.borderColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: hover && !jaEh
                              ? theme.textColor
                              : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final fotoCliente =
                                  ImagemService.resolverCaminhoExistente(cliente.foto);
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
                                        color: jaEh
                                            ? theme.secondaryTextColor
                                            : theme.textColor,
                                      )
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextoRolante(
                              texto: cliente.nome,
                              textAlign: TextAlign.start,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: jaEh
                                    ? theme.secondaryTextColor
                                    : theme.textColor,
                              ),
                            ),
                          ),
                          if (jaEh)
                            Text(
                              'Já é fornecedor',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          else if (cliente.telefone.isNotEmpty)
                            Text(
                              cliente.telefone,
                              style: theme.getTextStyle(fontSize: 11),
                            ),
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
