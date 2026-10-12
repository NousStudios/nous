import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
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

String _valorCurto(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numeroCurto(int n) => '#${n.toString().padLeft(4, '0')}';

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
    required String lojaId,
    required List<PedidoLoja> pedidos,
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
    ValueChanged<String>? onExcluirPedido,
    void Function(String pedidoId, DadosComentario dados)?
        onSalvarComentario,
    void Function(String clienteId)? aoAbrirClientes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f11): () {
              dialogContext
                  .read<PdvProvider>()
                  .alternarLayoutExpandido(lojaId);
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
                  child: _RelatoriosConteudo(
                    theme: theme,
                    lojaId: lojaId,
                    expandido: expandido,
                    pedidos: pedidos,
                    autorCpf: autorCpf,
                    autorNome: autorNome,
                    autorEmail: autorEmail,
                    onExcluirPedido: onExcluirPedido,
                    onSalvarComentario: onSalvarComentario,
                    aoAbrirClientes: aoAbrirClientes,
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

class _RelatoriosConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final bool expandido;
  final List<PedidoLoja> pedidos;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<String>? onExcluirPedido;
  final void Function(String pedidoId, DadosComentario dados)?
      onSalvarComentario;
  final void Function(String clienteId)? aoAbrirClientes;

  const _RelatoriosConteudo({
    required this.theme,
    required this.lojaId,
    this.expandido = false,
    required this.pedidos,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onExcluirPedido,
    this.onSalvarComentario,
    this.aoAbrirClientes,
  });

  @override
  State<_RelatoriosConteudo> createState() => _RelatoriosConteudoState();
}

class _RelatoriosConteudoState extends State<_RelatoriosConteudo> {
  final _buscaController = TextEditingController();
  final _buscaAcoesController = TextEditingController();
  final _dataController = TextEditingController();
  final _filtrosScrollController = ScrollController();
  final _acoesScrollController = ScrollController();

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
    _buscaAcoesController.dispose();
    _dataController.dispose();
    _filtrosScrollController.dispose();
    _acoesScrollController.dispose();
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
      if (p.status == StatusPedido.cancelado) return false;
      if (_forma != null &&
          !p.todosPagamentos.any((pag) => pag.forma == _forma)) {
        return false;
      }
      if (desde != null && p.dataHora.isBefore(desde)) return false;
      if (termo.isEmpty) return true;
      final numero = p.numero.toString().padLeft(4, '0');
      final formas = p.todosPagamentos
          .map((pag) => pag.forma.toLowerCase())
          .join(' ');
      return p.clienteNome.toLowerCase().contains(termo) ||
          p.produtoNome.toLowerCase().contains(termo) ||
          formas.contains(termo) ||
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

  List<PedidoLoja> get _pendencias {
    final lista =
        _pedidos.where((p) => p.aPrazoEmAberto).toList();
    lista.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return lista;
  }

  List<RegistroAcao> _acoesFiltradas(List<RegistroAcao> origem) {
    final termo = _buscaAcoesController.text.trim().toLowerCase();
    final lista = termo.isEmpty
        ? List.of(origem)
        : origem.where((a) {
            if (a.descricao.toLowerCase().contains(termo)) return true;
            if (a.nomeAutor.toLowerCase().contains(termo)) return true;
            if (a.emailAutor.toLowerCase().contains(termo)) return true;
            if (a.cpfAutor.contains(termo)) return true;
            if (_formatarCpf(a.cpfAutor).toLowerCase().contains(termo)) {
              return true;
            }
            if (_dataHoraCurta(a.dataHora).toLowerCase().contains(termo)) {
              return true;
            }
            return false;
          }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  void _excluirPedido(String id) {
    setState(() => _pedidos.removeWhere((p) => p.id == id));
    widget.onExcluirPedido?.call(id);
  }

  void _salvarComentarioPedido(String id, DadosComentario dados) {
    final indice = _pedidos.indexWhere((p) => p.id == id);
    if (indice != -1) {
      setState(() {
        _pedidos[indice] = _pedidos[indice].copyWith(
          comentario: dados.texto,
          comentarioAutorCpf: dados.cpfAutor,
          comentarioAutorNome: dados.nomeAutor,
          comentarioAutorEmail: dados.emailAutor,
          comentarioDataHora: dados.dataHora,
        );
      });
    }
    widget.onSalvarComentario?.call(id, dados);
  }

  void _clicarPendencia(PedidoLoja pedido) {
    final abrir = widget.aoAbrirClientes;
    final clienteId = pedido.clienteId;
    if (abrir == null || clienteId == null || clienteId.isEmpty) return;
    Navigator.of(context).pop();
    abrir(clienteId);
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
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return _LinhaComHover(
      aoClicar: () => setState(() => _forma = selecionada ? null : forma),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionada
              ? (hover
                  ? (theme.buttonColor != Colors.transparent
                      ? theme.buttonColor.withValues(alpha: 0.85)
                      : theme.borderColor.withValues(alpha: 0.35))
                  : fundoAtivo)
              : (hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionada || hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionada ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          forma,
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
            color: selecionada
                ? textoAtivo
                : (hover ? theme.textColor : theme.secondaryTextColor),
          ),
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
    return SingleChildScrollView(
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
                  lojaId: widget.lojaId,
                  pedido: vendas[index],
                  mostrarCliente: true,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onSalvarComentario: widget.onSalvarComentario == null
                      ? null
                      : (dados) =>
                          _salvarComentarioPedido(vendas[index].id, dados),
                  onExcluir: () => _excluirPedido(vendas[index].id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardPendencia(PedidoLoja pedido) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    Cliente? cliente;
    if (pedido.clienteId != null && loja != null) {
      for (final c in loja.clientesLoja) {
        if (c.id == pedido.clienteId) {
          cliente = c;
          break;
        }
      }
    }
    String foto = '';
    if (cliente != null) {
      foto = cliente.foto.trim();
      if (foto.isEmpty && cliente.cnpj.isNotEmpty) {
        foto = auth.buscarFotoPorCpf(cliente.cnpj);
        if (foto.isEmpty) {
          foto = pdv.buscarFotoClientePorCpf(cliente.cnpj) ?? '';
        }
      }
    }
    final temFoto = foto.isNotEmpty && File(foto).existsSync();

    return _LinhaComHover(
      aoClicar: () => _clicarPendencia(pedido),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            temFoto
                ? CircleAvatar(
                    radius: 12,
                    backgroundImage: FileImage(File(foto)),
                    backgroundColor: theme.borderColor.withValues(alpha: 0.2),
                  )
                : CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.borderColor.withValues(alpha: 0.2),
                    child: Icon(Icons.person, size: 14, color: theme.textColor),
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.clienteNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    'Pedido ${_numeroCurto(pedido.numero)} • '
                    '${_dataHoraCurta(pedido.dataHora)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              _valorCurto(pedido.valorRestante),
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoPendencias() {
    final pendencias = _pendencias;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Pendências'),
          if (pendencias.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma venda a prazo em aberto.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pendencias.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _cardPendencia(pendencias[index]),
              ),
            ),
        ],
      ),
    );
  }

  void _abrirDetalhesAcao(RegistroAcao acao) {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final clientes = loja?.clientesLoja ?? const <Cliente>[];

    Cliente? clienteEncontrado;
    final matchAspas = RegExp(r'"([^"]+)"').firstMatch(acao.descricao);
    if (matchAspas != null) {
      final nome = matchAspas.group(1)?.trim().toLowerCase() ?? '';
      clienteEncontrado = clientes
          .where((c) => c.nome.trim().toLowerCase() == nome)
          .firstOrNull;
    }

    PedidoLoja? pedidoEncontrado;
    final matchPedido = RegExp(r'#(\d+)').firstMatch(acao.descricao);
    if (matchPedido != null) {
      final numPed = int.tryParse(matchPedido.group(1)!);
      if (numPed != null) {
        pedidoEncontrado =
            widget.pedidos.where((p) => p.numero == numPed).firstOrNull;
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => _DetalhesAcaoDialog(
        theme: theme,
        acao: acao,
        clienteVinculado: clienteEncontrado,
        pedidoVinculado: pedidoEncontrado,
        onAbrirPerfilCliente:
            clienteEncontrado != null && widget.aoAbrirClientes != null
                ? () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    widget.aoAbrirClientes!(clienteEncontrado!.id);
                  }
                : null,
        onAbrirPedido: pedidoEncontrado != null
            ? () {
                Navigator.of(ctx).pop();
                VendaRegistradaDialog.mostrar(
                  context,
                  theme: theme,
                  lojaId: widget.lojaId,
                  pedido: pedidoEncontrado!,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onSalvarComentario: widget.onSalvarComentario != null
                      ? (dados) => widget.onSalvarComentario!(
                            pedidoEncontrado!.id,
                            dados,
                          )
                      : null,
                  onExcluir: widget.onExcluirPedido != null
                      ? () => widget.onExcluirPedido!(pedidoEncontrado!.id)
                      : null,
                );
              }
            : null,
      ),
    );
  }

  Widget _blocoAcoes(List<RegistroAcao> acoesOrigem) {
    final acoes = _acoesFiltradas(acoesOrigem);
    final nadaRegistrado = acoesOrigem.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Ações'),
          TextField(
            controller: _buscaAcoesController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Pesquisar ações (texto ou data)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (nadaRegistrado)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação registrada ainda.',
            )
          else if (acoes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação encontrada.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                controller: _acoesScrollController,
                shrinkWrap: true,
                itemCount: acoes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) => _BarraAcao(
                  theme: theme,
                  acao: acoes[index],
                  onTap: () => _abrirDetalhesAcao(acoes[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final acoes = loja?.acoes ?? const <RegistroAcao>[];

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
            child: widget.expandido
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _blocoRelatorios(),
                            const SizedBox(height: 12),
                            _blocoPendencias(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _blocoAcoes(acoes),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _blocoRelatorios(),
                      const SizedBox(height: 12),
                      _blocoPendencias(),
                      const SizedBox(height: 12),
                      _blocoAcoes(acoes),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _BarraAcao extends StatefulWidget {
  final AppTheme theme;
  final RegistroAcao acao;
  final VoidCallback onTap;

  const _BarraAcao({
    required this.theme,
    required this.acao,
    required this.onTap,
  });

  @override
  State<_BarraAcao> createState() => _BarraAcaoState();
}

class _BarraAcaoState extends State<_BarraAcao> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final acao = widget.acao;
    final autorPartes = <String>[
      if (acao.nomeAutor.isNotEmpty) acao.nomeAutor,
      if (acao.cpfAutor.isNotEmpty) _formatarCpf(acao.cpfAutor),
      if (acao.emailAutor.isNotEmpty) acao.emailAutor,
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acao.descricao,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
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
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalhesAcaoDialog extends StatelessWidget {
  final AppTheme theme;
  final RegistroAcao acao;
  final Cliente? clienteVinculado;
  final PedidoLoja? pedidoVinculado;
  final VoidCallback? onAbrirPerfilCliente;
  final VoidCallback? onAbrirPedido;

  const _DetalhesAcaoDialog({
    required this.theme,
    required this.acao,
    this.clienteVinculado,
    this.pedidoVinculado,
    this.onAbrirPerfilCliente,
    this.onAbrirPedido,
  });

  String _rotuloTipo(TipoAcao tipo) {
    return switch (tipo) {
      TipoAcao.dadosLojaAtualizados => 'Dados da Loja Atualizados',
      TipoAcao.novaVenda => 'Nova Venda Registrada',
      TipoAcao.pedidoAceito => 'Pedido Aceito',
      TipoAcao.pedidoRecusado => 'Pedido Recusado',
      TipoAcao.pedidoConcluido => 'Pedido Concluído',
      TipoAcao.pedidoCancelado => 'Pedido Cancelado',
      TipoAcao.pedidoExcluido => 'Pedido Excluído',
      TipoAcao.comentarioSalvo => 'Comentário em Pedido',
      TipoAcao.clienteCriado => 'Cliente Cadastrado',
      TipoAcao.clienteAtualizado => 'Cliente Atualizado',
      TipoAcao.clienteExcluido => 'Cliente Excluído',
      TipoAcao.itemCriado => 'Item Criado',
      TipoAcao.itemAtualizado => 'Item Atualizado',
      TipoAcao.itemExcluido => 'Item Excluído',
      TipoAcao.categoriaCriada => 'Categoria Criada',
      TipoAcao.categoriaAtualizada => 'Categoria Atualizada',
      TipoAcao.categoriaExcluida => 'Categoria Excluída',
      TipoAcao.grupoCriado => 'Grupo de Componentes Criado',
      TipoAcao.grupoAtualizado => 'Grupo Atualizado',
      TipoAcao.grupoExcluido => 'Grupo Excluído',
      TipoAcao.lojaExcluida => 'Perfil / Loja Excluída',
      TipoAcao.membroAdicionado => 'Membro Adicionado',
      TipoAcao.membroRemovido => 'Membro Removido',
      TipoAcao.papelAlterado => 'Papel de Membro Alterado',
      TipoAcao.conviteEnviado => 'Convite Enviado',
      TipoAcao.pagamentoPrazoRecebido => 'Pagamento de Fiado Recebido',
      TipoAcao.itemVinculadoCategoria => 'Item Vinculado à Categoria',
      TipoAcao.itemDesvinculadoCategoria => 'Item Desvinculado',
      TipoAcao.itemVinculadoGrupo => 'Item Vinculado ao Grupo',
      TipoAcao.itemDesvinculadoGrupo => 'Item Desvinculado',
      TipoAcao.movimentoEstoqueRegistrado => 'Movimento de Estoque',
      TipoAcao.movimentoEstoqueRemovido => 'Estorno de Estoque',
      TipoAcao.pagamentoFuncionarioRegistrado => 'Pagamento Registrado',
      TipoAcao.pagamentoFuncionarioRemovido => 'Pagamento Removido',
      TipoAcao.mesaCriada => 'Mesa Criada',
      TipoAcao.mesaExcluida => 'Mesa Excluída',
      TipoAcao.mesaAberta => 'Mesa Aberta',
      TipoAcao.itemAdicionadoMesa => 'Item Adicionado à Mesa',
      TipoAcao.itemRemovidoMesa => 'Item Removido da Mesa',
      TipoAcao.mesaFechada => 'Mesa Fechada',
      TipoAcao.mesaLiberada => 'Mesa Liberada',
      TipoAcao.mesaTransferida => 'Mesa Transferida',
      TipoAcao.caixaAberto => 'Abertura de Caixa',
      TipoAcao.caixaFechado => 'Fechamento de Caixa',
      TipoAcao.sangriaRegistrada => 'Sangria de Caixa',
      TipoAcao.suprimentoRegistrado => 'Suprimento de Caixa',
    };
  }

  IconData _iconeTipo(TipoAcao tipo) {
    return switch (tipo) {
      TipoAcao.clienteCriado ||
      TipoAcao.clienteAtualizado ||
      TipoAcao.clienteExcluido ||
      TipoAcao.pagamentoPrazoRecebido =>
        Icons.person_outline,
      TipoAcao.novaVenda ||
      TipoAcao.pedidoAceito ||
      TipoAcao.pedidoConcluido ||
      TipoAcao.pedidoCancelado ||
      TipoAcao.pedidoExcluido ||
      TipoAcao.pedidoRecusado ||
      TipoAcao.comentarioSalvo =>
        Icons.receipt_long_outlined,
      TipoAcao.caixaAberto ||
      TipoAcao.caixaFechado ||
      TipoAcao.sangriaRegistrada ||
      TipoAcao.suprimentoRegistrado =>
        Icons.point_of_sale_outlined,
      TipoAcao.itemCriado ||
      TipoAcao.itemAtualizado ||
      TipoAcao.itemExcluido ||
      TipoAcao.movimentoEstoqueRegistrado ||
      TipoAcao.movimentoEstoqueRemovido =>
        Icons.inventory_2_outlined,
      TipoAcao.mesaCriada ||
      TipoAcao.mesaAberta ||
      TipoAcao.itemAdicionadoMesa ||
      TipoAcao.itemRemovidoMesa ||
      TipoAcao.mesaFechada ||
      TipoAcao.mesaLiberada ||
      TipoAcao.mesaTransferida ||
      TipoAcao.mesaExcluida =>
        Icons.table_restaurant_outlined,
      _ => Icons.history_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconeTipo(acao.tipo), color: theme.textColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Detalhes da Ação',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            _rotuloTipo(acao.tipo),
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _dataHoraCurta(acao.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Descrição:',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acao.descricao,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'Autor do Registro:',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acao.nomeAutor.isNotEmpty
                          ? acao.nomeAutor
                          : 'Usuário do Sistema',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (acao.cpfAutor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'CPF: ${_formatarCpf(acao.cpfAutor)}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                    if (acao.emailAutor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'E-mail: ${acao.emailAutor}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (onAbrirPerfilCliente != null && clienteVinculado != null) ...[
                OutlinedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.borderColor.withValues(alpha: 0.18);
                      }
                      return theme.buttonColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    iconColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: theme.textColor, width: 1.4);
                      }
                      return BorderSide(color: theme.borderColor, width: 1.0);
                    }),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    mouseCursor: const WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                  ),
                  onPressed: onAbrirPerfilCliente,
                  icon: const Icon(Icons.person, size: 16),
                  label: Text(
                    'Ver Perfil de "${clienteVinculado!.nome}"',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (onAbrirPedido != null && pedidoVinculado != null) ...[
                OutlinedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.borderColor.withValues(alpha: 0.18);
                      }
                      return theme.buttonColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    iconColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: theme.textColor, width: 1.4);
                      }
                      return BorderSide(color: theme.borderColor, width: 1.0);
                    }),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    mouseCursor: const WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                  ),
                  onPressed: onAbrirPedido,
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(
                    'Ver Comanda do Pedido #${_numeroCurto(pedidoVinculado!.numero)}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (acao.tipo == TipoAcao.pedidoExcluido ||
                  acao.tipo == TipoAcao.clienteExcluido ||
                  acao.tipo == TipoAcao.itemExcluido) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registro original arquivado no log histórico da autogestão.',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return theme.borderColor.withValues(alpha: 0.18);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return theme.textColor;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return BorderSide(color: theme.textColor, width: 1.4);
                    }
                    return BorderSide(color: theme.borderColor, width: 1.0);
                  }),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 11),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  mouseCursor: const WidgetStatePropertyAll(
                    SystemMouseCursors.click,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fechar', style: theme.getTextStyle(fontSize: 12)),
              ),
            ],
          ),
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