import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes/divida_cliente_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes/formulario_cliente_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes/historico_compras_cliente_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes/lista_pesquisa_clientes_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/clientes/pedidos_programados_cliente_widget.dart';
import 'package:provider/provider.dart';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

class ClientesDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String lojaId,
    required List<Cliente> clientes,
    required List<PedidoLoja> pedidos,
    required ValueChanged<Cliente> onSalvar,
    required void Function(
            String clienteId, double valor, String formaPagamento)
        onPagar,
    required ValueChanged<String> onExcluir,
    String? clienteInicialId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f11): () {
              JanelaWindowsService.alternarTelaCheia();
            },
          },
          child: Consumer<PdvProvider>(
            builder: (ctx, pdv, child) {
              final expandido = pdv.layoutDesktopAtivo(lojaId);
              final larguraTela = MediaQuery.sizeOf(ctx).width;
              final maxWidth = expandido
                  ? (larguraTela > 1150 ? 1050.0 : larguraTela * 0.92)
                  : 500.0;

              return Dialog(
                backgroundColor: theme.cardBackgroundColor,
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.borderColor),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _ClientesConteudo(
                    theme: theme,
                    lojaId: lojaId,
                    expandido: expandido,
                    clientes: clientes,
                    pedidos: pedidos,
                    onSalvar: onSalvar,
                    onPagar: onPagar,
                    onExcluir: onExcluir,
                    clienteInicialId: clienteInicialId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ClientesConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final bool expandido;
  final List<Cliente> clientes;
  final List<PedidoLoja> pedidos;
  final ValueChanged<Cliente> onSalvar;
  final void Function(
      String clienteId, double valor, String formaPagamento) onPagar;
  final ValueChanged<String> onExcluir;
  final String? clienteInicialId;

  const _ClientesConteudo({
    required this.theme,
    required this.lojaId,
    this.expandido = false,
    required this.clientes,
    required this.pedidos,
    required this.onSalvar,
    required this.onPagar,
    required this.onExcluir,
    this.clienteInicialId,
  });

  @override
  State<_ClientesConteudo> createState() => _ClientesConteudoState();
}

class _ClientesConteudoState extends State<_ClientesConteudo> {
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _emailController = TextEditingController();
  final _redesSociaisController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _pagamentoController = TextEditingController();
  final _pesquisaController = TextEditingController();

  late List<Cliente> _clientes;
  late List<PedidoLoja> _pedidos;
  Cliente? _editando;
  String _foto = '';
  String? _aviso;
  String? _avisoPagamento;
  String _ultimoDocConsultado = '';

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _clientes = List.of(widget.clientes);
    _pedidos = List.of(widget.pedidos);

    final id = widget.clienteInicialId;
    if (id != null && id.isNotEmpty) {
      final indice = _clientes.indexWhere((c) => c.id == id);
      if (indice != -1) {
        _editando = _clientes[indice];
        final c = _clientes[indice];
        _foto = c.foto;
        _nomeController.text = c.nome;
        _cnpjController.text = c.cnpj;
        _telefoneController.text = c.telefone;
        _enderecoController.text = c.endereco;
        _numeroController.text = c.numero;
        _emailController.text = c.email;
        _redesSociaisController.text = c.redesSociais;
        _descricaoController.text = c.descricao;
        _ultimoDocConsultado = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
      }
    }

    _cnpjController.addListener(_aoAlterarDocumento);
  }

  @override
  void dispose() {
    _cnpjController.removeListener(_aoAlterarDocumento);
    _nomeController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _emailController.dispose();
    _redesSociaisController.dispose();
    _descricaoController.dispose();
    _pagamentoController.dispose();
    _pesquisaController.dispose();
    super.dispose();
  }

  void _aoAlterarDocumento() {
    final digitos = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 11 && digitos.length != 14) {
      if (digitos.isEmpty) {
        _ultimoDocConsultado = '';
      }
      return;
    }

    if (digitos == _ultimoDocConsultado) return;
    _ultimoDocConsultado = digitos;

    _consultarEAutopreencher(digitos);
  }

  Future<void> _consultarEAutopreencher(String digitos) async {
    final dados = await DadosLocaisService.buscarPorDocumento(digitos);
    if (!mounted || dados == null) return;

    final digitosAtuais =
        _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitosAtuais != digitos) return;

    setState(() {
      if (dados.nome.isNotEmpty) _nomeController.text = dados.nome;
      if (dados.telefone.isNotEmpty) _telefoneController.text = dados.telefone;
      if (dados.endereco.isNotEmpty) _enderecoController.text = dados.endereco;
      if (dados.numero.isNotEmpty) _numeroController.text = dados.numero;
      if (dados.email.isNotEmpty) _emailController.text = dados.email;
      if (dados.redesSociais.isNotEmpty) {
        _redesSociaisController.text = dados.redesSociais;
      }
      if (dados.descricao.isNotEmpty && _descricaoController.text.isEmpty) {
        _descricaoController.text = dados.descricao;
      }
      if (dados.foto.isNotEmpty && File(dados.foto).existsSync()) {
        _foto = dados.foto;
      }
      _aviso = 'Dados preenchidos a partir de ${dados.origem}.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Dados encontrados e preenchidos a partir de ${dados.origem}.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _limparCampos() {
    _foto = '';
    _ultimoDocConsultado = '';
    _nomeController.clear();
    _cnpjController.clear();
    _telefoneController.clear();
    _enderecoController.clear();
    _numeroController.clear();
    _emailController.clear();
    _redesSociaisController.clear();
    _descricaoController.clear();
    _pagamentoController.clear();
    _avisoPagamento = null;
  }

  void _abrirEdicao(Cliente cliente) {
    setState(() {
      _editando = cliente;
      _foto = cliente.foto;
      _aviso = null;
      _avisoPagamento = null;
      _ultimoDocConsultado = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
      _pagamentoController.clear();
      _nomeController.text = cliente.nome;
      _cnpjController.text = cliente.cnpj;
      _telefoneController.text = cliente.telefone;
      _enderecoController.text = cliente.endereco;
      _numeroController.text = cliente.numero;
      _emailController.text = cliente.email;
      _redesSociaisController.text = cliente.redesSociais;
      _descricaoController.text = cliente.descricao;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  String _capitalizarPalavras(String texto) {
    if (texto.trim().isEmpty) return '';
    return texto.split(' ').map((palavra) {
      if (palavra.isEmpty) return '';
      if (palavra.length == 1) return palavra.toUpperCase();
      return palavra[0].toUpperCase() + palavra.substring(1);
    }).join(' ');
  }

  void _salvar() {
    final nome = _capitalizarPalavras(_nomeController.text.trim());
    if (nome.isEmpty) {
      setState(() => _aviso = 'Informe o nome do cliente.');
      return;
    }

    final cliente = Cliente(
      id: _editando?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      cnpj: _cnpjController.text.trim(),
      telefone: _telefoneController.text.trim(),
      endereco: _enderecoController.text.trim(),
      numero: _numeroController.text.trim(),
      email: _emailController.text.trim(),
      redesSociais: _redesSociaisController.text.trim(),
      descricao: _descricaoController.text.trim(),
      foto: _foto,
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

  void _aplicarPagamento(
      String clienteId, double valor, String formaPagamento) {
    widget.onPagar(clienteId, valor, formaPagamento);
    setState(() {
      _pedidos = aplicarPagamentoAPrazo(
        _pedidos,
        clienteId,
        valor,
        clienteNome: _editando?.nome,
      );
      _pagamentoController.clear();
      _avisoPagamento = null;
    });
  }

  Future<void> _quitarTudo() async {
    final cliente = _editando;
    if (cliente == null) return;
    final devido = _devido(cliente.id, nome: cliente.nome);
    if (devido <= 0) return;

    final forma = await DividaClienteWidget.confirmarAbateDivida(
      context: context,
      theme: theme,
      cliente: cliente,
      valorAbate: devido,
      devido: devido,
    );
    if (forma == null) return;

    _aplicarPagamento(cliente.id, devido, forma);
  }

  Future<void> _quitarValor() async {
    final cliente = _editando;
    if (cliente == null) return;

    final texto = _pagamentoController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0) {
      setState(() => _avisoPagamento = 'Informe um valor válido.');
      return;
    }

    final devido = _devido(cliente.id, nome: cliente.nome);
    if (valor > devido + 0.005) {
      setState(() => _avisoPagamento = 'Valor maior que o devido.');
      return;
    }

    final forma = await DividaClienteWidget.confirmarAbateDivida(
      context: context,
      theme: theme,
      cliente: cliente,
      valorAbate: valor,
      devido: devido,
    );
    if (forma == null) return;

    _aplicarPagamento(cliente.id, valor, forma);
  }

  Future<void> _confirmarExclusao(Cliente cliente) async {
    final devido = _devido(cliente.id, nome: cliente.nome);
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
                style: theme.getTextStyle(color: theme.dangerColor),
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

  double _devido(String clienteId, {String? nome}) {
    var soma = 0.0;
    final nomeAlvo = nome?.trim().toLowerCase() ?? '';
    for (final p in _pedidos) {
      final ehDesteCliente = p.clienteId == clienteId ||
          (nomeAlvo.isNotEmpty &&
              p.clienteNome.trim().toLowerCase() == nomeAlvo);
      if (ehDesteCliente && p.aPrazoEmAberto) {
        soma += p.valorRestante;
      }
    }
    return soma;
  }

  List<PedidoLoja> _historico(String clienteId, {String? nome}) {
    final nomeAlvo = nome?.trim().toLowerCase() ?? '';
    final lista = _pedidos.where((p) {
      if (p.clienteId == clienteId) return true;
      if (nomeAlvo.isNotEmpty &&
          p.clienteNome.trim().toLowerCase() == nomeAlvo) {
        return true;
      }
      return false;
    }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final editando = _editando;

    final widgetFormulario = FormularioClienteWidget(
      theme: theme,
      editando: editando,
      foto: _foto,
      aviso: _aviso,
      nomeController: _nomeController,
      cnpjController: _cnpjController,
      telefoneController: _telefoneController,
      enderecoController: _enderecoController,
      numeroController: _numeroController,
      emailController: _emailController,
      redesSociaisController: _redesSociaisController,
      descricaoController: _descricaoController,
      onFotoAlterada: (novaFoto) => setState(() => _foto = novaFoto),
      onSalvar: _salvar,
      onCancelar: _cancelarEdicao,
      onExcluir: () {
        if (editando != null) _confirmarExclusao(editando);
      },
    );

    final widgetLista = ListaPesquisaClientesWidget(
      theme: theme,
      expandido: widget.expandido,
      clientes: _clientes,
      pesquisaController: _pesquisaController,
      onSelecionarCliente: _abrirEdicao,
      onPesquisaAlterada: () => setState(() {}),
      obterDividaCliente: (c) => _devido(c.id, nome: c.nome),
    );

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
            child: widget.expandido
                ? (editando != null
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                widgetFormulario,
                                const SizedBox(height: 12),
                                DividaClienteWidget(
                                  theme: theme,
                                  cliente: editando,
                                  devido: _devido(editando.id,
                                      nome: editando.nome),
                                  pagamentoController: _pagamentoController,
                                  avisoPagamento: _avisoPagamento,
                                  onQuitarValor: _quitarValor,
                                  onQuitarTudo: _quitarTudo,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                PedidosProgramadosClienteWidget(
                                  theme: theme,
                                  lojaId: widget.lojaId,
                                  cliente: editando,
                                ),
                                const SizedBox(height: 12),
                                HistoricoComprasClienteWidget(
                                  theme: theme,
                                  lojaId: widget.lojaId,
                                  cliente: editando,
                                  historico: _historico(editando.id,
                                      nome: editando.nome),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                widgetLista,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                widgetFormulario,
                              ],
                            ),
                          ),
                        ],
                      ))
                : Column(
                    children: [
                      if (editando != null) ...[
                        widgetFormulario,
                        const SizedBox(height: 12),
                        DividaClienteWidget(
                          theme: theme,
                          cliente: editando,
                          devido:
                              _devido(editando.id, nome: editando.nome),
                          pagamentoController: _pagamentoController,
                          avisoPagamento: _avisoPagamento,
                          onQuitarValor: _quitarValor,
                          onQuitarTudo: _quitarTudo,
                        ),
                        const SizedBox(height: 12),
                        PedidosProgramadosClienteWidget(
                          theme: theme,
                          lojaId: widget.lojaId,
                          cliente: editando,
                        ),
                        const SizedBox(height: 12),
                        HistoricoComprasClienteWidget(
                          theme: theme,
                          lojaId: widget.lojaId,
                          cliente: editando,
                          historico: _historico(editando.id,
                              nome: editando.nome),
                        ),
                      ] else ...[
                        widgetLista,
                        const SizedBox(height: 12),
                        widgetFormulario,
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}