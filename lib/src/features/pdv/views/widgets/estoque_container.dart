import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class EstoqueContainer extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itens;
  final List<MovimentoEstoque> movimentos;
  final bool podeEditar;
  final VoidCallback onNovoMovimento;
  final ValueChanged<MovimentoEstoque> onRemoverMovimento;
  final VoidCallback onAvisarSemPermissao;
  final bool emDialog;

  const EstoqueContainer({
    super.key,
    required this.theme,
    required this.itens,
    required this.movimentos,
    required this.podeEditar,
    required this.onNovoMovimento,
    required this.onRemoverMovimento,
    required this.onAvisarSemPermissao,
    this.emDialog = false,
  });

  @override
  State<EstoqueContainer> createState() => _EstoqueContainerState();
}

class _EstoqueContainerState extends State<EstoqueContainer> {
  AppTheme get theme => widget.theme;

  int _saldoDoItem(String itemId) {
    var saldo = 0;
    for (final m in widget.movimentos) {
      if (m.itemId != itemId) continue;
      saldo += m.quantidadeComSinal;
    }
    return saldo;
  }

  int _estoqueMinimoDe(ItemLoja item) {
    final texto = item.estoqueMinimo.trim();
    if (texto.isEmpty) return 0;
    return int.tryParse(texto) ?? 0;
  }

  List<MovimentoEstoque> _movimentosDoItem(String itemId) {
    final lista =
        widget.movimentos.where((m) => m.itemId == itemId).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _abrirHistorico(ItemLoja item) {
    final movimentos = _movimentosDoItem(item.id);
    final saldo = _saldoDoItem(item.id);

    showDialog<void>(
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.textColor),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      Expanded(
                        child: Text(
                          item.nome.isEmpty ? 'Item' : item.nome,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            'Saldo atual: $saldo',
                            style: theme.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (movimentos.isEmpty)
                          EstadoVazioContainer(
                            theme: theme,
                            mensagem: 'Nenhum movimento registrado ainda.',
                          )
                        else
                          for (final m in movimentos)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LinhaMovimento(
                                theme: theme,
                                movimento: m,
                                podeExcluir: widget.podeEditar,
                                onExcluir: () {
                                  widget.onRemoverMovimento(m);
                                },
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _botaoNovoMovimento() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          if (!widget.podeEditar) {
            widget.onAvisarSemPermissao();
            return;
          }
          widget.onNovoMovimento();
        },
        icon: Icon(Icons.add, size: 18, color: theme.textColor),
        label: Text(
          'Novo movimento',
          style: theme.getTextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _linhaDoItem(ItemLoja item) {
    final saldo = _saldoDoItem(item.id);
    final minimo = _estoqueMinimoDe(item);
    final abaixoDoMinimo = minimo > 0 && saldo < minimo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _LinhaComHover(
        aoClicar: () => _abrirHistorico(item),
        builder: (hover) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Icon(
                item.tipo == TipoItemLoja.servico
                    ? Icons.handyman_outlined
                    : Icons.inventory_2_outlined,
                size: 20,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome.isEmpty ? 'Item sem nome' : item.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    if (minimo > 0)
                      Text(
                        'mínimo $minimo',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$saldo',
                style: theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: abaixoDoMinimo ? Colors.redAccent : theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Column(
      children: [
        if (widget.podeEditar) ...[
          _botaoNovoMovimento(),
          const SizedBox(height: 12),
        ],
        if (widget.itens.isEmpty)
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum item cadastrado ainda.',
          )
        else
          for (final item in widget.itens) _linhaDoItem(item),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emDialog) {
      return _conteudo();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Estoque',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          _conteudo(),
        ],
      ),
    );
  }
}

class _LinhaMovimento extends StatefulWidget {
  final AppTheme theme;
  final MovimentoEstoque movimento;
  final bool podeExcluir;
  final VoidCallback onExcluir;

  const _LinhaMovimento({
    required this.theme,
    required this.movimento,
    required this.podeExcluir,
    required this.onExcluir,
  });

  @override
  State<_LinhaMovimento> createState() => _LinhaMovimentoState();
}

class _LinhaMovimentoState extends State<_LinhaMovimento> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final m = widget.movimento;
    final ehEntrada = m.ehEntrada;

    final sinal = ehEntrada ? '+' : '-';
    final sufixoCusto =
        m.custoUnitario > 0 ? ' • ${_valor(m.custoUnitario)}/un' : '';
    final linha1 = '$sinal${m.quantidade}$sufixoCusto';

    final sufixoAutor =
        m.nomeAutor.isNotEmpty ? ' • ${m.nomeAutor}' : '';
    final linha2 = '${_dataHora(m.dataHora)}$sufixoAutor';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              ehEntrada ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: ehEntrada ? theme.textColor : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linha1,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    linha2,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  if (m.motivo.trim().isNotEmpty)
                    Text(
                      m.motivo.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.podeExcluir)
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.secondaryTextColor),
                onPressed: widget.onExcluir,
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaComHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaComHover> createState() => _LinhaComHoverState();
}

class _LinhaComHoverState extends State<_LinhaComHover> {
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