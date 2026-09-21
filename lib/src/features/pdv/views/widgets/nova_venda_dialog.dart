import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

const List<String> _formasDePagamento = ['Pix', 'Dinheiro', 'Débito', 'Crédito'];

const int _colunasComanda = 32;

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0;
}

String _valorComVirgula(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCompleta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

class NovaVendaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    required String nomeVendedor,
    required String cnpjVendedor,
    required int proximoNumero,
    required ValueChanged<PedidoLoja> onConcluir,
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _NovaVendaConteudo(
              theme: theme,
              itensDisponiveis: itensDisponiveis,
              nomeVendedor: nomeVendedor,
              cnpjVendedor: cnpjVendedor,
              proximoNumero: proximoNumero,
              onConcluir: onConcluir,
            ),
          ),
        );
      },
    );
  }
}

class _NovaVendaConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itensDisponiveis;
  final String nomeVendedor;
  final String cnpjVendedor;
  final int proximoNumero;
  final ValueChanged<PedidoLoja> onConcluir;

  const _NovaVendaConteudo({
    required this.theme,
    required this.itensDisponiveis,
    required this.nomeVendedor,
    required this.cnpjVendedor,
    required this.proximoNumero,
    required this.onConcluir,
  });

  @override
  State<_NovaVendaConteudo> createState() => _NovaVendaConteudoState();
}

class _NovaVendaConteudoState extends State<_NovaVendaConteudo> {
  final _clienteController = TextEditingController();
  final _buscaController = TextEditingController();
  final _comandaController = TextEditingController();

  final Map<String, int> _quantidades = {};
  String? _formaPagamento;
  String? _aviso;
  late final DateTime _dataHora;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _dataHora = DateTime.now();
    _atualizarComanda();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _buscaController.dispose();
    _comandaController.dispose();
    super.dispose();
  }

  ItemLoja? _buscarItem(String id) {
    for (final item in widget.itensDisponiveis) {
      if (item.id == id) return item;
    }
    return null;
  }

  double get _total {
    var soma = 0.0;
    _quantidades.forEach((id, quantidade) {
      final item = _buscarItem(id);
      if (item != null) soma += _precoComoNumero(item.preco) * quantidade;
    });
    return soma;
  }

  List<ItemLoja> get _resultadosDaBusca {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return [];
    return widget.itensDisponiveis
        .where((item) => item.nome.toLowerCase().contains(termo))
        .take(4)
        .toList();
  }

  String _linhaComValor(String esquerda, String direita) {
    final limite = _colunasComanda - direita.length - 1;
    final texto =
        esquerda.length > limite ? esquerda.substring(0, limite) : esquerda;
    return texto.padRight(_colunasComanda - direita.length) + direita;
  }

  String _montarComanda() {
    final duplo = '=' * _colunasComanda;
    final simples = '-' * _colunasComanda;
    final buffer = StringBuffer();

    buffer.writeln(duplo);
    buffer.writeln(
      widget.nomeVendedor.isEmpty ? 'Nome do vendedor' : widget.nomeVendedor,
    );
    buffer.writeln('CNPJ: ${widget.cnpjVendedor}');
    buffer.writeln(duplo);
    buffer.writeln('Pedido #${widget.proximoNumero.toString().padLeft(4, '0')}');
    buffer.writeln('Data: ${_dataHoraCompleta(_dataHora)}');
    buffer.writeln(simples);
    buffer.writeln('Cliente: ${_clienteController.text.trim()}');
    buffer.writeln('Endereço: ');
    buffer.writeln(simples);
    buffer.writeln('ITENS');

    _quantidades.forEach((id, quantidade) {
      final item = _buscarItem(id);
      if (item == null) return;
      final subtotal = _precoComoNumero(item.preco) * quantidade;
      buffer.writeln(
        _linhaComValor('${quantidade}x ${item.nome}', _valorComVirgula(subtotal)),
      );
      buffer.writeln('   Obs: ');
    });

    buffer.writeln(simples);
    buffer.writeln('Frete: R\$ ${_valorComVirgula(0)}');
    buffer.writeln('TOTAL: R\$ ${_valorComVirgula(_total)}');
    buffer.writeln('Pagamento: ${_formaPagamento ?? ''}');
    buffer.write(duplo);

    return buffer.toString();
  }

  void _atualizarComanda() {
    _comandaController.text = _montarComanda();
  }

  void _alterarQuantidade(String id, int variacao) {
    setState(() {
      final nova = (_quantidades[id] ?? 0) + variacao;
      if (nova <= 0) {
        _quantidades.remove(id);
      } else {
        _quantidades[id] = nova;
      }
      _aviso = null;
      _atualizarComanda();
    });
  }

  void _escolherPagamento(String forma) {
    setState(() {
      _formaPagamento = _formaPagamento == forma ? null : forma;
      _atualizarComanda();
    });
  }

  void _mostrarAviso(String texto) {
    setState(() => _aviso = texto);
  }

  void _concluir() {
    if (_quantidades.isEmpty) {
      _mostrarAviso('Adicione ao menos um produto.');
      return;
    }

    final nomes = _quantidades.keys
        .map((id) => _buscarItem(id)?.nome ?? '')
        .where((nome) => nome.isNotEmpty)
        .toList();
    final resumo = nomes.length > 1
        ? '${nomes.first} +${nomes.length - 1}'
        : (nomes.isEmpty ? 'Venda' : nomes.first);
    final cliente = _clienteController.text.trim();

    final pedido = PedidoLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      numero: widget.proximoNumero,
      clienteNome: cliente.isEmpty ? 'Cliente' : cliente,
      produtoNome: resumo,
      dataHora: _dataHora,
      valor: _total,
      status: StatusPedido.aceito,
      comanda: _comandaController.text,
    );

    Navigator.of(context).pop();
    widget.onConcluir(pedido);
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  InputDecoration _decoracaoCampo(String dica) {
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

  Widget _botaoPequeno(String rotulo, VoidCallback aoPressionar) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: aoPressionar,
      child: Text(rotulo, style: theme.getTextStyle(fontSize: 11)),
    );
  }

  Widget _blocoCliente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Nome do Cliente'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clienteController,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Nome do cliente'),
                  onChanged: (_) => setState(_atualizarComanda),
                ),
              ),
              const SizedBox(width: 8),
              _botaoPequeno(
                'Novo Cliente',
                () => _mostrarAviso('Cadastro de clientes: em construção.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaDeResultado(ItemLoja item) {
    return InkWell(
      onTap: () {
        _buscaController.clear();
        _alterarQuantidade(item.id, 1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
            Text(
              'R\$ ${_valorComVirgula(_precoComoNumero(item.preco))}',
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDoItemSelecionado(ItemLoja item, int quantidade) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.remove, size: 18, color: theme.textColor),
          onPressed: () => _alterarQuantidade(item.id, -1),
        ),
        Text('$quantidade', style: theme.getTextStyle(fontSize: 12)),
        IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.add, size: 18, color: theme.textColor),
          onPressed: () => _alterarQuantidade(item.id, 1),
        ),
      ],
    );
  }

  Widget _blocoProduto() {
    final resultados = _resultadosDaBusca;
    final buscando = _buscaController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Produto Solicitado'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Pesquisar produtos cadastrados'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              _botaoPequeno(
                'Novo Produto',
                () => _mostrarAviso('Novo produto por aqui: em construção.'),
              ),
            ],
          ),
          if (buscando) ...[
            const SizedBox(height: 8),
            if (resultados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  widget.itensDisponiveis.isEmpty
                      ? 'Nenhum item criado na aba Loja ainda.'
                      : 'Nenhum resultado.',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              )
            else
              for (final item in resultados) _linhaDeResultado(item),
          ],
          if (_quantidades.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: theme.borderColor.withValues(alpha: 0.6)),
            for (final entrada in _quantidades.entries)
              if (_buscarItem(entrada.key) != null)
                _linhaDoItemSelecionado(
                  _buscarItem(entrada.key)!,
                  entrada.value,
                ),
          ],
        ],
      ),
    );
  }

  Widget _blocoComanda() {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cor),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Comanda'),
          TextField(
            controller: _comandaController,
            minLines: 14,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            cursorColor: theme.textColor,
            style: theme
                .getTextStyle(fontSize: 12)
                .copyWith(fontFamily: 'monospace', height: 1.3),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: borda(theme.borderColor),
              focusedBorder: borda(theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoPagamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Forma de Pagamento'),
          Row(
            children: [
              for (final forma in _formasDePagamento)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _botaoDePagamento(forma),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoDePagamento(String forma) {
    final selecionada = _formaPagamento == forma;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionada ? theme.buttonColor : Colors.transparent,
        foregroundColor: selecionada ? theme.buttonTextColor : theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _escolherPagamento(forma),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          forma,
          style: theme.getTextStyle(
            fontSize: 11,
            color: selecionada ? theme.buttonTextColor : theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _botaoConcluir() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.buttonColor,
          foregroundColor: theme.buttonTextColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _concluir,
        child: Text(
          'Concluir',
          style: theme.getTextStyle(
            fontSize: 14,
            color: theme.buttonTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Nova Venda',
                  textAlign: TextAlign.center,
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _blocoCliente(),
                const SizedBox(height: 12),
                _blocoProduto(),
                const SizedBox(height: 12),
                _blocoComanda(),
                const SizedBox(height: 12),
                _blocoPagamento(),
                const SizedBox(height: 12),
                if (_aviso != null) ...[
                  Text(
                    _aviso!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                _botaoConcluir(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}