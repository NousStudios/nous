import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'estoque/ficha_kardex_dialog.dart';
import 'estoque/linha_movimento_widget.dart';

class EstoqueContainer extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itens;
  final List<MovimentoEstoque> movimentos;
  final bool podeEditar;
  final VoidCallback onNovoMovimento;
  final ValueChanged<MovimentoEstoque> onRemoverMovimento;
  final VoidCallback onAvisarSemPermissao;
  final bool emDialog;
  final VoidCallback? onAbrirFornecedores;

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
    this.onAbrirFornecedores,
  });

  @override
  State<EstoqueContainer> createState() => _EstoqueContainerState();
}

class _EstoqueContainerState extends State<EstoqueContainer> {
  static const int _passoPaginacao = 50;
  final _pesquisaController = TextEditingController();
  int _limiteExibicao = _passoPaginacao;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  /// Calcula o mapa de saldos em O(M) uma única vez, blindando contra engasgos de CPU.
  Map<String, double> _calcularMapaSaldos() {
    final mapa = <String, double>{};
    for (final m in widget.movimentos) {
      mapa[m.itemId] = (mapa[m.itemId] ?? 0.0) + m.quantidadeComSinal;
    }
    return mapa;
  }

  double _estoqueMinimoDe(ItemLoja item) {
    final texto = item.estoqueMinimo.trim().replaceAll(',', '.');
    if (texto.isEmpty) return 0;
    return double.tryParse(texto) ?? 0;
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

  void _abrirHistorico(ItemLoja item, double saldo) {
    final movimentos = _movimentosDoItem(item.id);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FichaKardexDialog(
          theme: theme,
          item: item,
          saldo: saldo,
          movimentos: movimentos,
          podeEditar: widget.podeEditar,
          onRemoverMovimento: widget.onRemoverMovimento,
        );
      },
    );
  }

  Widget _botaoFornecedores() {
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
        onPressed: widget.onAbrirFornecedores,
        icon: Icon(
          Icons.storefront_outlined,
          size: 18,
          color: theme.textColor,
        ),
        label: Text(
          'Fornecedores',
          style: theme.getTextStyle(fontSize: 13),
        ),
      ),
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

  Widget _barraDePesquisa() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _pesquisaController,
        onChanged: (_) => setState(() {
          _limiteExibicao = _passoPaginacao;
        }),
        cursorColor: theme.textColor,
        style: theme.getTextStyle(fontSize: 12),
        decoration: _decoracaoPesquisa('Pesquisar itens...'),
      ),
    );
  }

  Widget _linhaDoItem(ItemLoja item, double saldo) {
    final minimo = _estoqueMinimoDe(item);
    final abaixoDoMinimo = minimo > 0 && saldo < minimo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _LinhaComHover(
        aoClicar: () => _abrirHistorico(item, saldo),
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
                        'mínimo ${formatarQuantidadeEstoque(minimo, item.unidadeBase)}',
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
                formatarQuantidadeEstoque(saldo, item.unidadeBase),
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
    final termo = _pesquisaController.text.trim();
    final filtrados = termo.isEmpty
        ? widget.itens
        : widget.itens
            .where((i) => TextoUtils.contemIgnorandoAcentos(i.nome, termo))
            .toList();

    final saldos = _calcularMapaSaldos();
    final totalFiltrados = filtrados.length;
    final exibidos = filtrados.take(_limiteExibicao).toList();

    return Column(
      children: [
        if (widget.onAbrirFornecedores != null) ...[
          _botaoFornecedores(),
          const SizedBox(height: 8),
        ],
        if (widget.podeEditar) ...[
          _botaoNovoMovimento(),
          const SizedBox(height: 12),
        ],
        if (widget.itens.isNotEmpty) _barraDePesquisa(),
        if (widget.itens.isEmpty)
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum item cadastrado ainda.',
          )
        else if (totalFiltrados == 0)
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum item encontrado.',
          )
        else ...[
          for (final item in exibidos)
            _linhaDoItem(item, saldos[item.id] ?? 0.0),
          if (_limiteExibicao < totalFiltrados)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.textColor,
                ),
                onPressed: () {
                  setState(() {
                    _limiteExibicao += _passoPaginacao;
                  });
                },
                icon: const Icon(Icons.expand_more, size: 16),
                label: Text(
                  'Carregar mais itens (${totalFiltrados - exibidos.length} restantes)',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ),
        ],
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