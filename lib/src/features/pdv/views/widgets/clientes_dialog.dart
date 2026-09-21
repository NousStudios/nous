import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

class ClientesDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<Cliente> clientes,
    required List<PedidoLoja> pedidos,
    required ValueChanged<Cliente> onSalvar,
    required ValueChanged<String> onQuitar,
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
            child: _ClientesConteudo(
              theme: theme,
              clientes: clientes,
              pedidos: pedidos,
              onSalvar: onSalvar,
              onQuitar: onQuitar,
            ),
          ),
        );
      },
    );
  }
}

class _ClientesConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<Cliente> clientes;
  final List<PedidoLoja> pedidos;
  final ValueChanged<Cliente> onSalvar;
  final ValueChanged<String> onQuitar;

  const _ClientesConteudo({
    required this.theme,
    required this.clientes,
    required this.pedidos,
    required this.onSalvar,
    required this.onQuitar,
  });

  @override
  State<_ClientesConteudo> createState() => _ClientesConteudoState();
}

class _ClientesConteudoState extends State<_ClientesConteudo> {
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cnpjController = TextEditingController();

  late List<Cliente> _clientes;
  late List<PedidoLoja> _pedidos;
  Cliente? _editando;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _clientes = List.of(widget.clientes);
    _pedidos = List.of(widget.pedidos);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  void _limparCampos() {
    _nomeController.clear();
    _enderecoController.clear();
    _telefoneController.clear();
    _cnpjController.clear();
  }

  void _abrirEdicao(Cliente cliente) {
    setState(() {
      _editando = cliente;
      _aviso = null;
      _nomeController.text = cliente.nome;
      _enderecoController.text = cliente.endereco;
      _telefoneController.text = cliente.telefone;
      _cnpjController.text = cliente.cnpj;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  void _salvar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _aviso = 'Informe o nome do cliente.');
      return;
    }

    final cliente = Cliente(
      id: _editando?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      endereco: _enderecoController.text.trim(),
      telefone: _telefoneController.text.trim(),
      cnpj: _cnpjController.text.trim(),
    );

    widget.onSalvar(cliente);

    setState(() {
      final indice = _clientes.indexWhere((c) => c.id == cliente.id);
      if (indice == -1) {
        _clientes.add(cliente);
      } else {
        _clientes[indice] = cliente;
      }
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  void _quitar() {
    final id = _editando?.id;
    if (id == null) return;
    widget.onQuitar(id);
    setState(() {
      _pedidos = _pedidos
          .map((p) =>
              p.clienteId == id && p.aPrazoEmAberto
                  ? p.copyWith(quitado: true)
                  : p)
          .toList();
    });
  }

  double _devido(String clienteId) {
    var soma = 0.0;
    for (final p in _pedidos) {
      if (p.clienteId == clienteId && p.aPrazoEmAberto) soma += p.valor;
    }
    return soma;
  }

  List<PedidoLoja> _historico(String clienteId) {
    final lista = _pedidos.where((p) => p.clienteId == clienteId).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
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

  Widget _campo(
    TextEditingController controller,
    String dica, {
    TextInputType? teclado,
    List<TextInputFormatter>? formatadores,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        inputFormatters: formatadores,
        cursorColor: theme.textColor,
        style: theme.getTextStyle(fontSize: 12),
        decoration: _decoracaoCampo(dica),
      ),
    );
  }

  Widget _botao(String rotulo, VoidCallback aoPressionar,
      {bool destaque = false}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: destaque ? theme.buttonColor : Colors.transparent,
        foregroundColor: destaque ? theme.buttonTextColor : theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: aoPressionar,
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 12,
          color: destaque ? theme.buttonTextColor : theme.textColor,
        ),
      ),
    );
  }

  Widget _blocoFormulario() {
    final editando = _editando != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco(editando ? 'Editar Cliente' : 'Novo Cliente'),
          _campo(_nomeController, 'Nome'),
          _campo(_enderecoController, 'Endereço (Rua, número e cidade)'),
          _campo(
            _telefoneController,
            'Telefone',
            teclado: TextInputType.phone,
          ),
          _campo(
            _cnpjController,
            'CNPJ',
            teclado: TextInputType.number,
            formatadores: [CnpjInputFormatter()],
          ),
          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_aviso!, style: theme.getTextStyle(fontSize: 12)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (editando) ...[
                _botao('Cancelar', _cancelarEdicao),
                const SizedBox(width: 8),
              ],
              _botao(editando ? 'Salvar' : 'Cadastrar', _salvar,
                  destaque: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoDivida(Cliente cliente) {
    final devido = _devido(cliente.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('A Prazo'),
          Text('Valor em aberto', style: theme.getTextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            _valor(devido),
            style: theme.getTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          if (devido > 0) ...[
            const SizedBox(height: 10),
            _botao('Quitar', _quitar),
          ],
        ],
      ),
    );
  }

  Widget _linhaHistorico(PedidoLoja pedido) {
    final fonte = theme.getTextStyle(fontSize: 11);
    final detalhe = [
      _dataHora(pedido.dataHora),
      if (pedido.formaPagamento.isNotEmpty) pedido.formaPagamento,
      if (pedido.aPrazoEmAberto) 'em aberto',
      if (pedido.formaPagamento == 'À Prazo' && pedido.quitado) 'quitado',
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_numero(pedido.numero)}  ${pedido.produtoNome}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
                Text(detalhe, style: fonte),
              ],
            ),
          ),
          Text(_valor(pedido.valor), style: fonte),
        ],
      ),
    );
  }

  Widget _blocoHistorico(Cliente cliente) {
    final historico = _historico(cliente.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Histórico de Compras'),
          if (historico.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra registrada.',
            )
          else
            for (final pedido in historico) _linhaHistorico(pedido),
        ],
      ),
    );
  }

  Widget _blocoLista() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Clientes Cadastrados'),
          if (_clientes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente cadastrado ainda.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _clientes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cliente = _clientes[index];
                  return _LinhaComHover(
                    aoClicar: () => _abrirEdicao(cliente),
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
                          Icon(
                            Icons.account_circle,
                            size: 22,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cliente.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          if (cliente.telefone.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    final editando = _editando;
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
                  'Clientes',
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
                _blocoFormulario(),
                const SizedBox(height: 12),
                if (editando != null) ...[
                  _blocoDivida(editando),
                  const SizedBox(height: 12),
                  _blocoHistorico(editando),
                ] else
                  _blocoLista(),
              ],
            ),
          ),
        ),
      ],
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