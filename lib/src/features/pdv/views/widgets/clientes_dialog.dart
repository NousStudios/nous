import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

class ClientesDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<Cliente> clientes,
    required List<PedidoLoja> pedidos,
    required ValueChanged<Cliente> onSalvar,
    required void Function(String clienteId, double valor) onPagar,
    required ValueChanged<String> onExcluir,
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
              onPagar: onPagar,
              onExcluir: onExcluir,
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
  final void Function(String clienteId, double valor) onPagar;
  final ValueChanged<String> onExcluir;

  const _ClientesConteudo({
    required this.theme,
    required this.clientes,
    required this.pedidos,
    required this.onSalvar,
    required this.onPagar,
    required this.onExcluir,
  });

  @override
  State<_ClientesConteudo> createState() => _ClientesConteudoState();
}

class _ClientesConteudoState extends State<_ClientesConteudo> {
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _pagamentoController = TextEditingController();

  late List<Cliente> _clientes;
  late List<PedidoLoja> _pedidos;
  Cliente? _editando;
  String? _aviso;
  String? _avisoPagamento;

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
    _pagamentoController.dispose();
    super.dispose();
  }

  void _limparCampos() {
    _nomeController.clear();
    _enderecoController.clear();
    _telefoneController.clear();
    _cnpjController.clear();
    _pagamentoController.clear();
    _avisoPagamento = null;
  }

  void _abrirEdicao(Cliente cliente) {
    setState(() {
      _editando = cliente;
      _aviso = null;
      _avisoPagamento = null;
      _pagamentoController.clear();
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

  void _aplicarPagamento(String clienteId, double valor) {
    widget.onPagar(clienteId, valor);
    setState(() {
      _pedidos = aplicarPagamentoAPrazo(_pedidos, clienteId, valor);
      _pagamentoController.clear();
      _avisoPagamento = null;
    });
  }

  void _quitarTudo() {
    final id = _editando?.id;
    if (id == null) return;
    final devido = _devido(id);
    if (devido <= 0) return;
    _aplicarPagamento(id, devido);
  }

  void _quitarValor() {
    final id = _editando?.id;
    if (id == null) return;

    final texto = _pagamentoController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0) {
      setState(() => _avisoPagamento = 'Informe um valor válido.');
      return;
    }

    final devido = _devido(id);
    if (valor > devido + 0.005) {
      setState(() => _avisoPagamento = 'Valor maior que o devido.');
      return;
    }

    _aplicarPagamento(id, valor);
  }

  Future<void> _confirmarExclusao(Cliente cliente) async {
    final devido = _devido(cliente.id);
    final aviso = devido > 0
        ? 'Este cliente tem ${_valor(devido)} em aberto. '
            'Deseja excluir mesmo assim? Essa ação não pode ser desfeita.'
        : 'Tem certeza que deseja excluir este cliente? Essa ação não '
            'pode ser desfeita.';

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Cliente',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              aviso,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 14),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;

    widget.onExcluir(cliente.id);

    if (!mounted) return;
    setState(() {
      _clientes.removeWhere((c) => c.id == cliente.id);
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  double _devido(String clienteId) {
    var soma = 0.0;
    for (final p in _pedidos) {
      if (p.clienteId == clienteId && p.aPrazoEmAberto) {
        soma += p.valorRestante;
      }
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
    final editando = _editando;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco(editando != null ? 'Editar Cliente' : 'Novo Cliente'),
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
              if (editando != null) ...[
                _botao('Cancelar', _cancelarEdicao),
                const SizedBox(width: 8),
              ],
              _botao(editando != null ? 'Salvar' : 'Cadastrar', _salvar,
                  destaque: true),
            ],
          ),
          if (editando != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _confirmarExclusao(editando),
              child: Text(
                'Excluir Cliente',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _painelPagamento() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pagamentoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
          ],
          cursorColor: theme.textColor,
          style: theme.getTextStyle(fontSize: 12),
          decoration: _decoracaoCampo('Valor (R\$)'),
        ),
        if (_avisoPagamento != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _avisoPagamento!,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 10),
            ),
          ),
        const SizedBox(height: 8),
        _botao('Quitar valor', _quitarValor),
        const SizedBox(height: 6),
        _botao('Quitar tudo', _quitarTudo, destaque: true),
      ],
    );
  }

  Widget _informacaoDivida(double devido) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 400;
              if (!largo) {
                return Column(
                  children: [
                    _informacaoDivida(devido),
                    if (devido > 0) ...[
                      const SizedBox(height: 12),
                      SizedBox(width: 160, child: _painelPagamento()),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: devido > 0
                          ? SizedBox(width: 140, child: _painelPagamento())
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _informacaoDivida(devido),
                  const Expanded(child: SizedBox.shrink()),
                ],
              );
            },
          ),
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
            for (final pedido in historico)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BarraVenda(theme: theme, pedido: pedido),
              ),
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