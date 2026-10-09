import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/cnpj_ou_cpf_input_formatter.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/telefone_input_formatter.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';
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
    required void Function(String clienteId, double valor) onPagar,
    required ValueChanged<String> onExcluir,
    String? clienteInicialId,
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
              lojaId: lojaId,
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
    );
  }
}

class _ClientesConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final List<Cliente> clientes;
  final List<PedidoLoja> pedidos;
  final ValueChanged<Cliente> onSalvar;
  final void Function(String clienteId, double valor) onPagar;
  final ValueChanged<String> onExcluir;
  final String? clienteInicialId;

  const _ClientesConteudo({
    required this.theme,
    required this.lojaId,
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

  Future<void> _alterarFotoCliente() async {
    if (_foto.isNotEmpty) {
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto do Cliente',
        onEscolherNova: _selecionarNovaFotoCliente,
        onRemover: () => setState(() => _foto = ''),
      );
    } else {
      await _selecionarNovaFotoCliente();
    }
  }

  Future<void> _selecionarNovaFotoCliente() async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return;

    final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
    if (salvo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'A foto deve ser uma imagem válida de até meio giga (500MB).',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _foto = salvo);
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

  void _aplicarPagamento(String clienteId, double valor) {
    widget.onPagar(clienteId, valor);
    setState(() {
      _pedidos = aplicarPagamentoAPrazo(_pedidos, clienteId, valor);
      _pagamentoController.clear();
      _avisoPagamento = null;
    });
  }

  Future<bool> _confirmarAbateDivida(Cliente cliente, double valorAbate) async {
    final devido = _devido(cliente.id, nome: cliente.nome);
    final restante = (devido - valorAbate).clamp(0.0, double.infinity);

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
            'Confirmar Quitação',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Deseja abater o valor abaixo da dívida de ${cliente.nome}?',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valor a abater:',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _valor(valorAbate),
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dívida atual:',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _valor(devido),
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saldo restante:',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _valor(restante),
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: restante <= 0
                                  ? theme.textColor
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Confirmar Abate',
                style: theme.getTextStyle(
                  color: theme.buttonTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmou == true;
  }

  Future<void> _quitarTudo() async {
    final cliente = _editando;
    if (cliente == null) return;
    final devido = _devido(cliente.id, nome: cliente.nome);
    if (devido <= 0) return;

    final confirmou = await _confirmarAbateDivida(cliente, devido);
    if (!confirmou) return;

    _aplicarPagamento(cliente.id, devido);
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

    final confirmou = await _confirmarAbateDivida(cliente, valor);
    if (!confirmou) return;

    _aplicarPagamento(cliente.id, valor);
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

          InkWell(
            onTap: _alterarFotoCliente,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.cardBackgroundColor,
              backgroundImage: (_foto.isNotEmpty && File(_foto).existsSync())
                  ? FileImage(File(_foto))
                  : null,
              child: (_foto.isEmpty || !File(_foto).existsSync())
                  ? Icon(
                      Icons.person,
                      size: 44,
                      color: theme.secondaryTextColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          ThemedTextField(
            theme: theme,
            controller: _nomeController,
            label: 'Nome do Cliente',
            obrigatorio: true,
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: _cnpjController,
                  label: 'CNPJ ou CPF',
                  tipoDeTeclado: TextInputType.number,
                  formatadores: [CpfOuCnpjInputFormatter()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: _telefoneController,
                  label: 'Telefone',
                  tipoDeTeclado: TextInputType.phone,
                  formatadores: [TelefoneInputFormatter()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ThemedTextField(
                  theme: theme,
                  controller: _enderecoController,
                  label: 'Endereço',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ThemedTextField(
                  theme: theme,
                  controller: _numeroController,
                  label: 'Nº',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: _emailController,
            label: 'Email',
            tipoDeTeclado: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: _redesSociaisController,
            label: 'Redes Sociais',
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: _descricaoController,
            label: 'Descrição',
            linhas: 4,
          ),

          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_aviso!, style: theme.getTextStyle(fontSize: 12)),
            ),

          const SizedBox(height: 16),
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
    final devido = _devido(cliente.id, nome: cliente.nome);
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
    final historico = _historico(cliente.id, nome: cliente.nome);
    final totalGasto = historico
        .where((p) => p.status != StatusPedido.cancelado)
        .fold<double>(0, (s, p) => s + p.valor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Compras',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (historico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${historico.length} ${historico.length == 1 ? "compra" : "compras"} • Total: ${_valor(totalGasto)}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (historico.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 16,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Exportar Extrato PDF',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  onPressed: () => _exportarExtratoPDF(cliente, historico),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (historico.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra registrada para este cliente.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: historico.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BarraVenda(
                    theme: theme,
                    lojaId: widget.lojaId,
                    pedido: historico[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportarExtratoPDF(
    Cliente cliente,
    List<PedidoLoja> historico,
  ) async {
    try {
      final pdv = context.read<PdvProvider>();
      final loja = pdv.buscarPorId(widget.lojaId) ??
          (pdv.lojas.isNotEmpty ? pdv.lojas.first : null);

      if (loja == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Loja não encontrada para gerar o extrato.',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }
        return;
      }

      final caminho = await ImpressaoService.exportarExtratoClientePDF(
        loja: loja,
        cliente: cliente,
        pedidos: historico,
      );

      if (caminho != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Extrato do cliente exportado com sucesso em $caminho',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Falha ao exportar extrato: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  Widget _blocoLista() {
    final termo = _pesquisaController.text.trim().toLowerCase();
    final filtrados = termo.isEmpty
        ? _clientes
        : _clientes
            .where((c) => c.nome.toLowerCase().contains(termo))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Clientes Cadastrados'),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _pesquisaController,
              onChanged: (_) => setState(() {}),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              decoration: _decoracaoPesquisa('Pesquisar clientes...'),
            ),
          ),
          if (_clientes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente cadastrado ainda.',
            )
          else if (filtrados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente encontrado.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cliente = filtrados[index];
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
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.transparent,
                            backgroundImage: (cliente.foto.isNotEmpty &&
                                    File(cliente.foto).existsSync())
                                ? FileImage(File(cliente.foto))
                                : null,
                            child: (cliente.foto.isEmpty ||
                                    !File(cliente.foto).existsSync())
                                ? Icon(
                                    Icons.account_circle,
                                    size: 22,
                                    color: theme.textColor,
                                  )
                                : null,
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
                if (editando != null) ...[
                  _blocoFormulario(),
                  const SizedBox(height: 12),
                  _blocoDivida(editando),
                  const SizedBox(height: 12),
                  _blocoHistorico(editando),
                ] else ...[
                  _blocoLista(),
                  const SizedBox(height: 12),
                  _blocoFormulario(),
                ],
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