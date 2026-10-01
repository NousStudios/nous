import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';
import 'package:nous/src/features/pdv/services/telefone_input_formatter.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class FornecedoresDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<Cliente> clientes,
    required List<Fornecedor> fornecedores,
    required ValueChanged<Fornecedor> onSalvar,
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
            child: _FornecedoresConteudo(
              theme: theme,
              clientes: clientes,
              fornecedores: fornecedores,
              onSalvar: onSalvar,
              onExcluir: onExcluir,
            ),
          ),
        );
      },
    );
  }
}

class _FornecedoresConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<Cliente> clientes;
  final List<Fornecedor> fornecedores;
  final ValueChanged<Fornecedor> onSalvar;
  final ValueChanged<String> onExcluir;

  const _FornecedoresConteudo({
    required this.theme,
    required this.clientes,
    required this.fornecedores,
    required this.onSalvar,
    required this.onExcluir,
  });

  @override
  State<_FornecedoresConteudo> createState() =>
      _FornecedoresConteudoState();
}

class _FornecedoresConteudoState extends State<_FornecedoresConteudo> {
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _emailController = TextEditingController();
  final _redesSociaisController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _pesquisaController = TextEditingController();
  final _pesquisaClientesController = TextEditingController();

  late List<Fornecedor> _fornecedores;
  late List<Cliente> _clientes;
  Fornecedor? _editando;
  String? _origemClienteId;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _fornecedores = List.of(widget.fornecedores);
    _clientes = List.of(widget.clientes);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _emailController.dispose();
    _redesSociaisController.dispose();
    _descricaoController.dispose();
    _pesquisaController.dispose();
    _pesquisaClientesController.dispose();
    super.dispose();
  }

  void _limparCampos() {
    _nomeController.clear();
    _cnpjController.clear();
    _telefoneController.clear();
    _enderecoController.clear();
    _numeroController.clear();
    _emailController.clear();
    _redesSociaisController.clear();
    _descricaoController.clear();
    _origemClienteId = null;
  }

  void _abrirEdicao(Fornecedor fornecedor) {
    setState(() {
      _editando = fornecedor;
      _origemClienteId = fornecedor.origemClienteId.isEmpty
          ? null
          : fornecedor.origemClienteId;
      _aviso = null;
      _nomeController.text = fornecedor.nome;
      _cnpjController.text = fornecedor.cnpj;
      _telefoneController.text = fornecedor.telefone;
      _enderecoController.text = fornecedor.endereco;
      _numeroController.text = fornecedor.numero;
      _emailController.text = fornecedor.email;
      _redesSociaisController.text = fornecedor.redesSociais;
      _descricaoController.text = fornecedor.descricao;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  void _copiarClienteParaFormulario(Cliente cliente) {
    setState(() {
      _editando = null;
      _aviso = null;
      _origemClienteId = cliente.id;
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

  void _salvar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _aviso = 'Informe o nome do fornecedor.');
      return;
    }

    final fornecedor = Fornecedor(
      id: _editando?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      cnpj: _cnpjController.text.trim(),
      telefone: _telefoneController.text.trim(),
      endereco: _enderecoController.text.trim(),
      numero: _numeroController.text.trim(),
      email: _emailController.text.trim(),
      redesSociais: _redesSociaisController.text.trim(),
      descricao: _descricaoController.text.trim(),
      origemClienteId: _origemClienteId ?? '',
      dataCriacao: _editando?.dataCriacao ?? DateTime.now(),
    );

    widget.onSalvar(fornecedor);

    setState(() {
      final indice = _fornecedores.indexWhere((f) => f.id == fornecedor.id);
      if (indice == -1) {
        _fornecedores.add(fornecedor);
      } else {
        _fornecedores[indice] = fornecedor;
      }
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  Future<void> _confirmarExclusao(Fornecedor fornecedor) async {
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
            'Excluir Fornecedor',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir este fornecedor? '
            'Os movimentos de estoque já registrados continuam guardando '
            'o nome dele.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
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

    widget.onExcluir(fornecedor.id);

    if (!mounted) return;
    setState(() {
      _fornecedores.removeWhere((f) => f.id == fornecedor.id);
      _editando = null;
      _aviso = null;
      _limparCampos();
    });
  }

  bool _clienteJaEhFornecedor(Cliente cliente) {
    return _fornecedores.any((f) => f.origemClienteId == cliente.id);
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
    final veioDeCliente = _origemClienteId != null && editando == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco(
            editando != null
                ? 'Editar Fornecedor'
                : (veioDeCliente
                    ? 'Novo Fornecedor (dados do cliente)'
                    : 'Novo Fornecedor'),
          ),

          InkWell(
            onTap: () {},
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.cardBackgroundColor,
              child: Icon(
                Icons.storefront_outlined,
                size: 44,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          ThemedTextField(
            theme: theme,
            controller: _nomeController,
            label: 'Nome do Fornecedor',
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
                  label: 'CNPJ',
                  tipoDeTeclado: TextInputType.number,
                  formatadores: [CnpjInputFormatter()],
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
              if (editando != null || veioDeCliente) ...[
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
                'Excluir Fornecedor',
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

  Widget _blocoClientes() {
    final termo = _pesquisaClientesController.text.trim().toLowerCase();
    final disponiveis = termo.isEmpty
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
          _tituloDoBloco('Usar cliente como fornecedor'),
          Text(
            'Clique em um cliente para preencher o formulário com os '
            'dados dele. Você pode ajustar antes de salvar.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pesquisaClientesController,
            onChanged: (_) => setState(() {}),
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoPesquisa('Pesquisar clientes...'),
          ),
          const SizedBox(height: 10),
          if (_clientes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente cadastrado ainda.',
            )
          else if (disponiveis.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum cliente encontrado.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: disponiveis.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cliente = disponiveis[index];
                  final jaEh = _clienteJaEhFornecedor(cliente);
                  return _LinhaComHover(
                    aoClicar: jaEh
                        ? () {}
                        : () => _copiarClienteParaFormulario(cliente),
                    builder: (hover) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: hover && !jaEh
                            ? theme.borderColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: hover && !jaEh
                              ? theme.textColor
                              : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 22,
                            color: jaEh
                                ? theme.secondaryTextColor
                                : theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cliente.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: jaEh
                                    ? theme.secondaryTextColor
                                    : theme.textColor,
                              ),
                            ),
                          ),
                          if (jaEh)
                            Text(
                              'Já é fornecedor',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          else if (cliente.telefone.isNotEmpty)
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

  Widget _blocoLista() {
    final termo = _pesquisaController.text.trim().toLowerCase();
    final filtrados = termo.isEmpty
        ? _fornecedores
        : _fornecedores
            .where((f) => f.nome.toLowerCase().contains(termo))
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Fornecedores Cadastrados'),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _pesquisaController,
              onChanged: (_) => setState(() {}),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              decoration: _decoracaoPesquisa('Pesquisar fornecedores...'),
            ),
          ),
          if (_fornecedores.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum fornecedor cadastrado ainda.',
            )
          else if (filtrados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum fornecedor encontrado.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final fornecedor = filtrados[index];
                  return _LinhaComHover(
                    aoClicar: () => _abrirEdicao(fornecedor),
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
                          color:
                              hover ? theme.textColor : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 22,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fornecedor.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          if (fornecedor.telefone.isNotEmpty)
                            Text(
                              fornecedor.telefone,
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
    final veioDeCliente = _origemClienteId != null && editando == null;

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
                  'Fornecedores',
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
                if (editando != null || veioDeCliente) ...[
                  _blocoFormulario(),
                  const SizedBox(height: 12),
                  _blocoLista(),
                ] else ...[
                  _blocoLista(),
                  const SizedBox(height: 12),
                  _blocoClientes(),
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