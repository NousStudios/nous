import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores/bloco_importar_cliente_fornecedor_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores/formulario_fornecedor_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/fornecedores/lista_fornecedores_widget.dart';

class FornecedoresDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    String? lojaId,
    required List<Cliente> clientes,
    required List<Fornecedor> fornecedores,
    required ValueChanged<Fornecedor> onSalvar,
    required ValueChanged<String> onExcluir,
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
                  child: _FornecedoresConteudo(
                    theme: theme,
                    expandido: expandido,
                    clientes: clientes,
                    fornecedores: fornecedores,
                    onSalvar: onSalvar,
                    onExcluir: onExcluir,
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

class _FornecedoresConteudo extends StatefulWidget {
  final AppTheme theme;
  final bool expandido;
  final List<Cliente> clientes;
  final List<Fornecedor> fornecedores;
  final ValueChanged<Fornecedor> onSalvar;
  final ValueChanged<String> onExcluir;

  const _FornecedoresConteudo({
    required this.theme,
    this.expandido = false,
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

  late List<Fornecedor> _fornecedores;
  late List<Cliente> _clientes;
  Fornecedor? _editando;
  String? _origemClienteId;
  String? _aviso;
  String _foto = '';

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
    _foto = '';
  }

  void _abrirEdicao(Fornecedor fornecedor) {
    setState(() {
      _editando = fornecedor;
      _origemClienteId = fornecedor.origemClienteId.isEmpty
          ? null
          : fornecedor.origemClienteId;
      _aviso = null;
      _foto = fornecedor.foto;
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
      _foto = cliente.foto;
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

  Future<void> _alterarFotoFornecedor() async {
    if (_foto.isNotEmpty) {
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto do Fornecedor',
        onEscolherNova: _selecionarNovaFotoFornecedor,
        onRemover: () => setState(() => _foto = ''),
      );
    } else {
      await _selecionarNovaFotoFornecedor();
    }
  }

  Future<void> _selecionarNovaFotoFornecedor() async {
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
      foto: _foto,
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
                style: theme.getTextStyle(color: theme.dangerColor),
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

  @override
  Widget build(BuildContext context) {
    final editando = _editando;
    final veioDeCliente = _origemClienteId != null && editando == null;

    final blocoFormulario = FormularioFornecedorWidget(
      theme: theme,
      editando: editando,
      veioDeCliente: veioDeCliente,
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
      onAlterarFoto: _alterarFotoFornecedor,
      onCancelar: _cancelarEdicao,
      onSalvar: _salvar,
      onExcluir: _confirmarExclusao,
    );

    final blocoClientes = BlocoImportarClienteFornecedorWidget(
      theme: theme,
      clientes: _clientes,
      clienteJaEhFornecedor: _clienteJaEhFornecedor,
      onCopiarCliente: _copiarClienteParaFormulario,
    );

    final blocoLista = ListaFornecedoresWidget(
      theme: theme,
      fornecedores: _fornecedores,
      onAbrirEdicao: _abrirEdicao,
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
            child: widget.expandido
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            blocoLista,
                            if (editando == null && !veioDeCliente) ...[
                              const SizedBox(height: 12),
                              blocoClientes,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            blocoFormulario,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      if (editando != null || veioDeCliente) ...[
                        blocoFormulario,
                        const SizedBox(height: 12),
                        blocoLista,
                      ] else ...[
                        blocoLista,
                        const SizedBox(height: 12),
                        blocoClientes,
                        const SizedBox(height: 12),
                        blocoFormulario,
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}