import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _formatarCpf(String cpf) {
  if (cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
      '${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
}

class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class RelatoriosDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<PedidoLoja> pedidos,
    required List<RegistroAcao> acoes,
    ValueChanged<String>? onExcluirPedido,
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
            child: _RelatoriosConteudo(
              theme: theme,
              pedidos: pedidos,
              acoes: acoes,
              onExcluirPedido: onExcluirPedido,
            ),
          ),
        );
      },
    );
  }
}

class _RelatoriosConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<PedidoLoja> pedidos;
  final List<RegistroAcao> acoes;
  final ValueChanged<String>? onExcluirPedido;

  const _RelatoriosConteudo({
    required this.theme,
    required this.pedidos,
    required this.acoes,
    this.onExcluirPedido,
  });

  @override
  State<_RelatoriosConteudo> createState() => _RelatoriosConteudoState();
}

class _RelatoriosConteudoState extends State<_RelatoriosConteudo> {
  final _buscaController = TextEditingController();
  final _dataController = TextEditingController();
  final _filtrosScrollController = ScrollController();

  late final List<PedidoLoja> _pedidos;
  String? _forma;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _pedidos = List.of(widget.pedidos);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _dataController.dispose();
    _filtrosScrollController.dispose();
    super.dispose();
  }

  DateTime? get _dataInicial {
    final texto = _dataController.text;
    if (texto.length != 10) return null;
    final partes = texto.split('/');
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return null;
    return data;
  }

  bool get _dataInvalida =>
      _dataController.text.length == 10 && _dataInicial == null;

  List<PedidoLoja> get _filtrados {
    final termo =
        _buscaController.text.trim().toLowerCase().replaceAll('#', '');
    final desde = _dataInicial;

    final lista = _pedidos.where((p) {
      if (_forma != null && p.formaPagamento != _forma) return false;
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (termo.isEmpty) return true;
      final numero = p.numero.toString().padLeft(4, '0');
      return p.clienteNome.toLowerCase().contains(termo) ||
          p.produtoNome.toLowerCase().contains(termo) ||
          p.formaPagamento.toLowerCase().contains(termo) ||
          p.comanda.toLowerCase().contains(termo) ||
          numero.contains(termo);
    }).toList();

    if (desde != null) {
      lista.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    } else {
      lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    }
    return lista;
  }

  List<RegistroAcao> get _acoesOrdenadas {
    final lista = List.of(widget.acoes);
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  void _excluirPedido(String id) {
    setState(() => _pedidos.removeWhere((p) => p.id == id));
    widget.onExcluirPedido?.call(id);
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

  Widget _botaoDeFiltro(String forma) {
    final selecionada = _forma == forma;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionada ? theme.buttonColor : Colors.transparent,
        foregroundColor: selecionada ? theme.buttonTextColor : theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => setState(() => _forma = selecionada ? null : forma),
      child: Text(
        forma,
        style: theme.getTextStyle(
          fontSize: 11,
          color: selecionada ? theme.buttonTextColor : theme.textColor,
        ),
      ),
    );
  }

  Widget _campoDeData() {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: _dataController,
        keyboardType: TextInputType.number,
        inputFormatters: [_DataInputFormatter()],
        cursorColor: theme.textColor,
        style: theme.getTextStyle(fontSize: 12),
        decoration: _decoracaoCampo('A partir de: dd/mm/aaaa'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _filtros() {
    return Scrollbar(
      controller: _filtrosScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _filtrosScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            for (final forma in _formasDePagamento)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _botaoDeFiltro(forma),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _campoDeData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoRelatorios() {
    final vendas = _filtrados;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Relatórios'),
          TextField(
            controller: _buscaController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Pesquisar vendas'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          _filtros(),
          if (_dataInvalida)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Data inválida.',
                style: theme.getTextStyle(fontSize: 11),
              ),
            ),
          if (vendas.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma venda encontrada.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: vendas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => BarraVenda(
                  theme: theme,
                  pedido: vendas[index],
                  mostrarCliente: true,
                  onExcluir: () => _excluirPedido(vendas[index].id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _linhaDeAcao(RegistroAcao acao) {
    final autorPartes = <String>[
      if (acao.nomeAutor.isNotEmpty) acao.nomeAutor,
      if (acao.cpfAutor.isNotEmpty) _formatarCpf(acao.cpfAutor),
      if (acao.emailAutor.isNotEmpty) acao.emailAutor,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            acao.descricao,
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            _dataHoraCurta(acao.dataHora),
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          if (autorPartes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'por ${autorPartes.join(' • ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(
                fontSize: 10,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blocoAcoes() {
    final acoes = _acoesOrdenadas;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Ações'),
          if (acoes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação registrada ainda.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: acoes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) => _linhaDeAcao(acoes[index]),
              ),
            ),
        ],
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
                  'Relatórios',
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
                _blocoRelatorios(),
                const SizedBox(height: 12),
                _blocoAcoes(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}