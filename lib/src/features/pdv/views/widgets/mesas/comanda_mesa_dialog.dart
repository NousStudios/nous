import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/adicionar_item_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/transferir_mesa_dialog.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _horaFormatada(DateTime d) =>
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class ComandaMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja mesa;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<ItemLoja> itensDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final String autorCpf;
  final String autorNome;
  final ValueChanged<MesaLoja> aoAtualizarMesa;
  final ValueChanged<MesaLoja> aoFecharConta;
  final ValueChanged<MesaLoja>? aoImprimirConferencia;
  final List<MesaLoja> todasMesas;
  final void Function(MesaLoja mesaOrigem, MesaLoja mesaDestino)? aoTransferirMesa;
  final VoidCallback? aoEditarMesa;

  const ComandaMesaDialog({
    super.key,
    required this.theme,
    required this.mesa,
    this.categoriasDisponiveis = const [],
    required this.itensDisponiveis,
    this.gruposDisponiveis = const [],
    this.todasMesas = const [],
    required this.autorCpf,
    required this.autorNome,
    required this.aoAtualizarMesa,
    required this.aoFecharConta,
    this.aoImprimirConferencia,
    this.aoTransferirMesa,
    this.aoEditarMesa,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MesaLoja mesa,
    List<CategoriaLoja> categoriasDisponiveis = const [],
    required List<ItemLoja> itensDisponiveis,
    List<GrupoComponentesLoja> gruposDisponiveis = const [],
    List<MesaLoja> todasMesas = const [],
    required String autorCpf,
    required String autorNome,
    required ValueChanged<MesaLoja> aoAtualizarMesa,
    required ValueChanged<MesaLoja> aoFecharConta,
    ValueChanged<MesaLoja>? aoImprimirConferencia,
    void Function(MesaLoja mesaOrigem, MesaLoja mesaDestino)? aoTransferirMesa,
    VoidCallback? aoEditarMesa,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
            child: ComandaMesaDialog(
              theme: theme,
              mesa: mesa,
              categoriasDisponiveis: categoriasDisponiveis,
              itensDisponiveis: itensDisponiveis,
              gruposDisponiveis: gruposDisponiveis,
              todasMesas: todasMesas,
              autorCpf: autorCpf,
              autorNome: autorNome,
              aoAtualizarMesa: (m) {
                aoAtualizarMesa(m);
              },
              aoFecharConta: (m) {
                Navigator.of(dialogContext).pop();
                aoFecharConta(m);
              },
              aoImprimirConferencia: aoImprimirConferencia,
              aoTransferirMesa: aoTransferirMesa,
              aoEditarMesa: aoEditarMesa == null
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      aoEditarMesa();
                    },
            ),
          ),
        );
      },
    );
  }

  @override
  State<ComandaMesaDialog> createState() => _ComandaMesaDialogState();
}

class _ComandaMesaDialogState extends State<ComandaMesaDialog> {
  late MesaLoja _mesa;
  final _clienteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mesa = widget.mesa;
    _clienteController.text = _mesa.clienteNome;
  }

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  void _abrirMesa() {
    final mesaAtualizada = _mesa.copyWith(
      status: StatusMesa.ocupada,
      clienteNome: _clienteController.text.trim(),
      atendenteCpf: widget.autorCpf,
      atendenteNome: widget.autorNome,
      dataHoraAbertura: DateTime.now(),
      itens: const [],
    );
    setState(() => _mesa = mesaAtualizada);
    widget.aoAtualizarMesa(mesaAtualizada);
  }

  void _liberarMesaSemConsumo() {
    final mesaLiberada = _mesa.copyWith(
      status: StatusMesa.livre,
      clienteNome: '',
      atendenteCpf: '',
      atendenteNome: '',
      dataHoraAbertura: null,
      itens: const [],
    );
    setState(() => _mesa = mesaLiberada);
    widget.aoAtualizarMesa(mesaLiberada);
    Navigator.of(context).pop();
  }

  void _abrirLancamentoItens() {
    AdicionarItemMesaDialog.mostrar(
      context,
      theme: widget.theme,
      categoriasDisponiveis: widget.categoriasDisponiveis,
      itensDisponiveis: widget.itensDisponiveis,
      gruposDisponiveis: widget.gruposDisponiveis,
      autorCpf: widget.autorCpf,
      autorNome: widget.autorNome,
      aoAdicionar: (novoItem) {
        final novaLista = [..._mesa.itens, novoItem];
        final mesaAtualizada = _mesa.copyWith(itens: novaLista);
        setState(() => _mesa = mesaAtualizada);
        widget.aoAtualizarMesa(mesaAtualizada);
      },
    );
  }

  void _removerItem(int index) {
    final itemRemovido = _mesa.itens[index];
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.theme.borderColor),
        ),
        title: Text(
          'Remover Item da Mesa?',
          textAlign: TextAlign.center,
          style: widget.theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        content: Text(
          'Deseja remover "${itemRemovido.item.nomeItem}" da mesa ${_mesa.numero}?',
          textAlign: TextAlign.center,
          style: widget.theme.getTextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancelar',
              style: widget.theme.getTextStyle(color: widget.theme.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Remover',
              style: widget.theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ).then((confirmado) {
      if (confirmado == true) {
        final novaLista = [..._mesa.itens]..removeAt(index);
        final mesaAtualizada = _mesa.copyWith(itens: novaLista);
        setState(() => _mesa = mesaAtualizada);
        widget.aoAtualizarMesa(mesaAtualizada);
      }
    });
  }

  Future<void> _abrirTransferenciaMesa() async {
    if (widget.aoTransferirMesa == null) return;
    final mesaDestino = await TransferirMesaDialog.mostrar(
      context,
      theme: widget.theme,
      mesaOrigem: _mesa,
      todasMesas: widget.todasMesas,
    );
    if (mesaDestino != null && mounted) {
      Navigator.of(context).pop();
      widget.aoTransferirMesa!(_mesa, mesaDestino);
    }
  }

  Widget _conteudoMesaLivre() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.table_restaurant_outlined,
                size: 44,
                color: widget.theme.textColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Mesa Livre',
                style: widget.theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              if (_mesa.descricao.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _mesa.descricao,
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ThemedTextField(
          theme: widget.theme,
          controller: _clienteController,
          label: 'Identificação do Cliente / Comanda (opcional)',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.person_outline,
                size: 18, color: widget.theme.secondaryTextColor),
            const SizedBox(width: 8),
            Text(
              'Atendente: ${widget.autorNome}',
              style: widget.theme.getTextStyle(
                fontSize: 13,
                color: widget.theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (widget.aoEditarMesa != null) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.theme.borderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: widget.aoEditarMesa,
                child: Text(
                  'Configurar',
                  style: widget.theme.getTextStyle(
                    fontSize: 14,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: widget.theme.buttonColor,
                  foregroundColor: widget.theme.buttonTextColor,
                  side: BorderSide(color: widget.theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _abrirMesa,
                child: Text(
                  'Abrir Mesa',
                  style: widget.theme.getTextStyle(
                    fontSize: 14,
                    color: widget.theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _conteudoMesaOcupada() {
    final horaAbertura = _mesa.dataHoraAbertura != null
        ? _horaFormatada(_mesa.dataHoraAbertura!)
        : '--:--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumo do cabeçalho da mesa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mesa.clienteNome.isNotEmpty
                        ? 'Cliente: ${_mesa.clienteNome}'
                        : 'Mesa Ocupada',
                    style: widget.theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textColor,
                    ),
                  ),
                  Text(
                    'Atendente: ${_mesa.atendenteNome} (Aberta às $horaAbertura)',
                    style: widget.theme.getTextStyle(
                      fontSize: 11,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Text(
                '${_mesa.quantidadeItensTotal} ${_mesa.quantidadeItensTotal == 1 ? "item" : "itens"}',
                style: widget.theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Lista de Itens Consumidos
        Expanded(
          child: _mesa.itens.isEmpty
              ? EstadoVazioContainer(
                  theme: widget.theme,
                  mensagem: 'Nenhum item lançado ainda. Clique em "+ Lançar Itens".',
                )
              : ListView.separated(
                  itemCount: _mesa.itens.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final itemComanda = _mesa.itens[index];
                    final item = itemComanda.item;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.backgroundColor
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              widget.theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.foto.isNotEmpty &&
                              File(item.foto).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(item.foto),
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Icon(Icons.inventory_2_outlined,
                                size: 24, color: widget.theme.textColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantidade}x ${item.nomeExibicao}',
                                  style: widget.theme.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: widget.theme.textColor,
                                  ),
                                ),
                                if (item.acompanhamentos.isNotEmpty)
                                  Text(
                                    item.acompanhamentos
                                        .map((a) =>
                                            '+ ${a.quantidadePorUnidade}x ${a.nomeItem}')
                                        .join(', '),
                                    style: widget.theme.getTextStyle(
                                      fontSize: 11,
                                      color: widget.theme.secondaryTextColor,
                                    ),
                                  ),
                                if (item.observacao.isNotEmpty)
                                  Text(
                                    'Obs: ${item.observacao}',
                                    style: widget.theme.getTextStyle(
                                      fontSize: 11,
                                      color: widget.theme.secondaryTextColor,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lançado por ${itemComanda.autorNome} (${_horaFormatada(itemComanda.dataHora)})',
                                  style: widget.theme.getTextStyle(
                                    fontSize: 9,
                                    color: widget.theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _valorFormatado(item.subtotal),
                                style: widget.theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _removerItem(index),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        // Totalizador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Acumulado:',
                style: widget.theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.theme.secondaryTextColor,
                ),
              ),
              Text(
                _valorFormatado(_mesa.totalAcumulado),
                style: widget.theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Botões de Ação da Mesa
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(Icons.add, size: 18, color: widget.theme.textColor),
                label: Text(
                  'Lançar Itens',
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    color: widget.theme.textColor,
                  ),
                ),
                onPressed: _abrirLancamentoItens,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.aoTransferirMesa != null && widget.todasMesas.length > 1) ...[
              IconButton(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: widget.theme.borderColor),
                  ),
                ),
                icon: Icon(Icons.swap_horiz_rounded,
                    size: 20, color: widget.theme.textColor),
                tooltip: 'Transferir Mesa',
                onPressed: _mesa.itens.isEmpty ? null : _abrirTransferenciaMesa,
              ),
              const SizedBox(width: 8),
            ],
            if (widget.aoImprimirConferencia != null) ...[
              IconButton(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: widget.theme.borderColor),
                  ),
                ),
                icon: Icon(Icons.print_outlined,
                    size: 20, color: widget.theme.textColor),
                tooltip: 'Imprimir Conferência (58mm)',
                onPressed: _mesa.itens.isEmpty
                    ? null
                    : () => widget.aoImprimirConferencia!(_mesa),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: widget.theme.buttonColor,
                  foregroundColor: widget.theme.buttonTextColor,
                  side: BorderSide(color: widget.theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _mesa.itens.isEmpty
                    ? null
                    : () => widget.aoFecharConta(_mesa),
                child: Text(
                  'Fechar Conta',
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    color: widget.theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_mesa.itens.isEmpty) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: _liberarMesaSemConsumo,
            child: Text(
              'Liberar Mesa sem Consumo',
              style: widget.theme.getTextStyle(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Mesa ${_mesa.numero}',
                  textAlign: TextAlign.center,
                  style: widget.theme.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _mesa.status == StatusMesa.livre
                ? _conteudoMesaLivre()
                : _conteudoMesaOcupada(),
          ),
        ],
      ),
    );
  }
}
