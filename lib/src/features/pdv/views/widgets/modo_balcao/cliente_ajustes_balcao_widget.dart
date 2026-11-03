import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class ClienteAjustesBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final List<Cliente> clientes;
  final List<Cliente> sugestoesClientes;
  final Cliente? clienteSelecionado;
  final bool mostrarSugestoesCliente;
  final TextEditingController clienteController;
  final FocusNode clienteFocusNode;
  final TextEditingController descontoController;
  final TextEditingController freteController;
  final TextEditingController acrescimoController;
  final ValueChanged<Cliente> onSelecionarCliente;
  final VoidCallback onRemoverCliente;
  final ValueChanged<bool> onAlterarVisibilidadeSugestoes;
  final VoidCallback onGarantirFocoBipador;
  final VoidCallback onAjusteAlterado;

  const ClienteAjustesBalcaoWidget({
    super.key,
    required this.theme,
    required this.clientes,
    required this.sugestoesClientes,
    required this.clienteSelecionado,
    required this.mostrarSugestoesCliente,
    required this.clienteController,
    required this.clienteFocusNode,
    required this.descontoController,
    required this.freteController,
    required this.acrescimoController,
    required this.onSelecionarCliente,
    required this.onRemoverCliente,
    required this.onAlterarVisibilidadeSugestoes,
    required this.onGarantirFocoBipador,
    required this.onAjusteAlterado,
  });

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: 'balcao_cliente_busca',
      onTapOutside: (_) {
        if (mostrarSugestoesCliente) {
          onAlterarVisibilidadeSugestoes(false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarSugestoesCliente && clienteSelecionado == null)
            _buildPainelSugestoesCliente(),
          _buildLinhaClienteEAjustes(),
        ],
      ),
    );
  }

  Widget _buildPainelSugestoesCliente() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: sugestoesClientes.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                clientes.isEmpty
                    ? 'Nenhum cliente cadastrado no sistema.'
                    : 'Nenhum cliente encontrado para este termo.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: sugestoesClientes.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final c = sugestoesClientes[index];
                final fotoResolvida =
                    ImagemService.resolverCaminhoExistente(c.foto);
                final temFoto = fotoResolvida != null;
                final doc = c.cnpj.isNotEmpty ? c.cnpj : '';
                final tel = c.telefone.isNotEmpty ? c.telefone : '';
                final end = c.endereco.isNotEmpty
                    ? '${c.endereco}${c.numero.isNotEmpty ? ', nº ${c.numero}' : ''}'
                    : '';

                return InkWell(
                  onTap: () {
                    onSelecionarCliente(c);
                    onGarantirFocoBipador();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage:
                              temFoto ? FileImage(File(fotoResolvida)) : null,
                          child: !temFoto
                              ? Icon(Icons.person,
                                  size: 18, color: theme.textColor)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nome,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              if (doc.isNotEmpty || tel.isNotEmpty)
                                Text(
                                  [
                                    if (doc.isNotEmpty) doc,
                                    if (tel.isNotEmpty) tel
                                  ].join(' • '),
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              if (end.isNotEmpty)
                                Text(
                                  end,
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
                        Icon(Icons.add_circle_outline,
                            size: 18, color: theme.secondaryTextColor),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLinhaClienteEAjustes() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline,
              size: 18, color: theme.secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: clienteSelecionado != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage: () {
                            final f = ImagemService.resolverCaminhoExistente(
                                clienteSelecionado!.foto);
                            return f != null ? FileImage(File(f)) : null;
                          }(),
                          child:
                              !ImagemService.existe(clienteSelecionado!.foto)
                                  ? Icon(Icons.person,
                                      size: 14, color: theme.textColor)
                                  : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clienteSelecionado!.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            onRemoverCliente();
                            onGarantirFocoBipador();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close,
                                size: 14, color: theme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  )
                : TextField(
                    controller: clienteController,
                    focusNode: clienteFocusNode,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Cliente (clique ou digite p/ buscar)',
                      hintStyle: theme.getTextStyle(
                          fontSize: 11, color: theme.secondaryTextColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onTap: () {
                      onAlterarVisibilidadeSugestoes(true);
                    },
                    onChanged: (v) {
                      onAlterarVisibilidadeSugestoes(true);
                    },
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: descontoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Desc: 0,00',
                hintStyle: theme.getTextStyle(
                    fontSize: 11, color: theme.secondaryTextColor),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (_) => onAjusteAlterado(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: freteController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Frete: 0,00',
                    hintStyle: theme.getTextStyle(
                        fontSize: 11, color: theme.secondaryTextColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => onAjusteAlterado(),
                ),
                Container(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.25),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                TextField(
                  controller: acrescimoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Acrésc: 0,00',
                    hintStyle: theme.getTextStyle(
                        fontSize: 11, color: theme.secondaryTextColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => onAjusteAlterado(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
