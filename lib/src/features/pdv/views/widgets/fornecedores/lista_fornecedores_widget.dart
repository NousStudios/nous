import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Lista de fornecedores cadastrados com barra de pesquisa e seleção para edição.
class ListaFornecedoresWidget extends StatefulWidget {
  final AppTheme theme;
  final List<Fornecedor> fornecedores;
  final ValueChanged<Fornecedor> onAbrirEdicao;

  const ListaFornecedoresWidget({
    super.key,
    required this.theme,
    required this.fornecedores,
    required this.onAbrirEdicao,
  });

  @override
  State<ListaFornecedoresWidget> createState() =>
      _ListaFornecedoresWidgetState();
}

class _ListaFornecedoresWidgetState extends State<ListaFornecedoresWidget> {
  final _pesquisaController = TextEditingController();

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _pesquisaController.dispose();
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
    final termo = _pesquisaController.text.trim();
    final filtrados = termo.isEmpty
        ? widget.fornecedores
        : widget.fornecedores
            .where((f) => f.correspondeABusca(termo))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Fornecedores Cadastrados'),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _pesquisaController,
              onChanged: (_) => setState(() {}),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              decoration: _decoracaoPesquisa(
                'Pesquisar por nome, rua, número, CNPJ...',
              ),
            ),
          ),
          if (widget.fornecedores.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum fornecedor cadastrado ainda.',
            )
          else if (filtrados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum fornecedor encontrado.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final fornecedor = filtrados[index];
                  final temEndereco = fornecedor.endereco.isNotEmpty ||
                      fornecedor.numero.isNotEmpty;
                  final enderecoTexto = [
                    if (fornecedor.endereco.isNotEmpty) fornecedor.endereco,
                    if (fornecedor.numero.isNotEmpty) 'nº ${fornecedor.numero}',
                  ].join(', ');

                  return _LinhaFornecedorHover(
                    aoClicar: () => widget.onAbrirEdicao(fornecedor),
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
                          color:
                              hover ? theme.textColor : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final fotoFornecedor =
                                  ImagemService.resolverCaminhoExistente(fornecedor.foto);
                              return CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.transparent,
                                backgroundImage: fotoFornecedor != null
                                    ? FileImage(File(fotoFornecedor))
                                    : null,
                                child: fotoFornecedor == null
                                    ? Icon(
                                        Icons.storefront_outlined,
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
                                  fornecedor.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
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
                          if (fornecedor.telefone.isNotEmpty)
                            Text(
                              fornecedor.telefone,
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

class _LinhaFornecedorHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaFornecedorHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaFornecedorHover> createState() => _LinhaFornecedorHoverState();
}

class _LinhaFornecedorHoverState extends State<_LinhaFornecedorHover> {
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
