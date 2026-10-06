import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

const double _larguraBloco = 320;

class VendaRegistradaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String lojaId,
    required PedidoLoja pedido,
    required String autorCpf,
    required String autorNome,
    required String autorEmail,
    ValueChanged<DadosComentario>? onSalvarComentario,
    VoidCallback? onExcluir,
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
            child: _VendaConteudo(
              theme: theme,
              lojaId: lojaId,
              pedido: pedido,
              autorCpf: autorCpf,
              autorNome: autorNome,
              autorEmail: autorEmail,
              onSalvarComentario: onSalvarComentario,
              onExcluir: onExcluir,
            ),
          ),
        );
      },
    );
  }
}

class _VendaConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<DadosComentario>? onSalvarComentario;
  final VoidCallback? onExcluir;

  const _VendaConteudo({
    required this.theme,
    required this.lojaId,
    required this.pedido,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onSalvarComentario,
    this.onExcluir,
  });

  @override
  State<_VendaConteudo> createState() => _VendaConteudoState();
}

class _VendaConteudoState extends State<_VendaConteudo> {
  late final TextEditingController _comentarioController;
  late String _comentarioSalvo;
  late DateTime? _comentarioDataHoraSalvo;
  late String _comentarioAutorNomeSalvo;
  late String _comentarioAutorCpfSalvo;
  late String _comentarioAutorEmailSalvo;

  bool _imprimindo = false;
  bool _exportando = false;

  AppTheme get theme => widget.theme;
  PedidoLoja get pedido => widget.pedido;

  @override
  void initState() {
    super.initState();
    _comentarioSalvo = widget.pedido.comentario;
    _comentarioDataHoraSalvo = widget.pedido.comentarioDataHora;
    _comentarioAutorNomeSalvo = widget.pedido.comentarioAutorNome;
    _comentarioAutorCpfSalvo = widget.pedido.comentarioAutorCpf;
    _comentarioAutorEmailSalvo = widget.pedido.comentarioAutorEmail;
    _comentarioController = TextEditingController(text: _comentarioSalvo);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  ConfiguracoesImpressora _lerConfiguracoesDaLoja() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    return loja?.configuracoesImpressora ?? const ConfiguracoesImpressora();
  }

  Cliente? _buscarClienteDoPedido() {
    final clienteId = widget.pedido.clienteId;
    if (clienteId == null || clienteId.isEmpty) return null;
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    if (loja == null) return null;
    for (final c in loja.clientesLoja) {
      if (c.id == clienteId) return c;
    }
    return null;
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          texto,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
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

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  String get _situacao {
    switch (pedido.status) {
      case StatusPedido.novo:
        return 'Novo';
      case StatusPedido.aceito:
        return 'Aceito';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  void _emConstrucao(String rotulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          '$rotulo: em construção',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _imprimir() async {
    if (_imprimindo) return;
    setState(() => _imprimindo = true);
    try {
      final config = _lerConfiguracoesDaLoja();
      await ImpressaoService.imprimirComanda(
        config: config,
        pedido: pedido,
        cliente: _buscarClienteDoPedido(),
      );
      if (!mounted) return;
      _snack('Comanda enviada para a impressora.');
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao imprimir: $e');
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _exportarPDF() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final config = _lerConfiguracoesDaLoja();
      final caminho = await ImpressaoService.exportarComandaPDF(
        pedido: pedido,
        rodape: config.rodape,
        cliente: _buscarClienteDoPedido(),
        camposClienteComanda: config.camposClienteComanda,
      );
      if (!mounted) return;
      if (caminho == null) {
        _snack('Exportação cancelada.');
      } else {
        _snack('PDF salvo em: $caminho');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Widget _botaoDeAcao(
    String rotulo, {
    bool destrutivo = false,
    bool carregando = false,
    VoidCallback? aoPressionar,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: destrutivo ? Colors.redAccent : theme.textColor,
        side: BorderSide(
          color: destrutivo ? Colors.redAccent : theme.borderColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: carregando ? null : (aoPressionar ?? () => _emConstrucao(rotulo)),
      child: carregando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }

  Future<void> _confirmarExclusao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Registro',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir este registro? Essa ação não '
            'pode ser desfeita.',
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
    widget.onExcluir?.call();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _blocoAcoes() {
    final acoes = <Widget>[
      _botaoDeAcao(
        'Imprimir',
        carregando: _imprimindo,
        aoPressionar: _imprimir,
      ),
      _botaoDeAcao('Compartilhar'),
      _botaoDeAcao(
        'Exportar como PDF',
        carregando: _exportando,
        aoPressionar: _exportarPDF,
      ),
      _botaoDeAcao(
        'Excluir Registro',
        destrutivo: true,
        aoPressionar: widget.onExcluir == null ? null : _confirmarExclusao,
      ),
    ];

    final comEspacos = <Widget>[];
    for (var i = 0; i < acoes.length; i++) {
      if (i > 0) comEspacos.add(const SizedBox(width: 8));
      comEspacos.add(acoes[i]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: comEspacos,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _blocoResumo() {
    final pagamentos = pedido.todosPagamentos;
    final temAPrazo = pagamentos.any((p) => p.forma == 'À Prazo');
    final pago = pedido.quitado ? pedido.valor : pedido.valorPago;
    final restante = pedido.quitado ? 0.0 : pedido.valorRestante;

    return Center(
      child: Container(
        width: _larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Resumo'),
            _linha('Pedido', _numero(pedido.numero)),
            _linha('Data', _dataHora(pedido.dataHora)),
            _linha('Cliente', pedido.clienteNome),
            _linha('Produtos', pedido.produtoNome),
            if (pagamentos.isEmpty)
              _linha('Forma de pagamento', 'Não informada')
            else
              for (final p in pagamentos)
                _linha('Forma de pagamento', '${p.forma} (${_valor(p.valor)})'),
            _linha('Situação', _situacao),
            if (pedido.frete > 0) _linha('Frete', _valor(pedido.frete)),
            if (pedido.desconto > 0)
              _linha('Desconto', '-${_valor(pedido.desconto)}'),
            if (pedido.acrescimo > 0)
              _linha('Acréscimo', _valor(pedido.acrescimo)),
            _linha('Valor total', _valor(pedido.valor)),
            if (pedido.troco > 0) ...[
              _linha('Valor recebido', _valor(pedido.valorRecebido)),
              _linha('Troco', _valor(pedido.troco)),
            ],
            if (temAPrazo) ...[
              _linha('Pagamento à prazo',
                  pedido.quitado ? 'Quitado' : 'Em aberto'),
              _linha('Já pago', _valor(pago)),
              _linha('Restante', _valor(restante)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _blocoItens() {
    if (pedido.itens.isEmpty) {
      return Center(
        child: Container(
          width: _larguraBloco,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: _decoracaoDoBloco,
          child: Column(
            children: [
              _tituloDoBloco('Itens'),
              EstadoVazioContainer(
                theme: theme,
                mensagem: 'Sem itens detalhados nesta venda.',
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: _larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Itens'),
            for (final item in pedido.itens) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantidade}x ${item.nomeExibicao}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          _valor(item.subtotalBase),
                          style: theme.getTextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    for (final a in item.acompanhamentos)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              _valor(a.precoItem *
                                  a.quantidadePorUnidade *
                                  item.quantidade),
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.observacao.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 3),
                        child: Text(
                          'Obs: ${item.observacao.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _salvarComentario() {
    final texto = _comentarioController.text.trim();
    final agora = DateTime.now();

    final dados = DadosComentario(
      texto: texto,
      cpfAutor: widget.autorCpf,
      nomeAutor: widget.autorNome,
      emailAutor: widget.autorEmail,
      dataHora: agora,
    );

    widget.onSalvarComentario?.call(dados);
    setState(() {
      _comentarioSalvo = texto;
      _comentarioDataHoraSalvo = agora;
      _comentarioAutorNomeSalvo = widget.autorNome;
      _comentarioAutorCpfSalvo = widget.autorCpf;
      _comentarioAutorEmailSalvo = widget.autorEmail;
    });
    _snack(
      widget.onSalvarComentario != null
          ? 'Comentário salvo.'
          : 'Comentário salvo (apenas nesta sessão).',
    );
  }

  String _autorDoComentarioExibido() {
    final partes = <String>[
      if (_comentarioAutorNomeSalvo.isNotEmpty) _comentarioAutorNomeSalvo,
      if (_comentarioAutorCpfSalvo.isNotEmpty) _comentarioAutorCpfSalvo,
      if (_comentarioAutorEmailSalvo.isNotEmpty) _comentarioAutorEmailSalvo,
    ];
    return partes.join(' • ');
  }

  Widget _blocoComentario() {
    final autorAntigo = _autorDoComentarioExibido();
    final dataAntiga = _comentarioDataHoraSalvo;

    return Center(
      child: Container(
        width: _larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Comentário'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _comentarioController,
                    maxLines: 4,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário sobre esta venda...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.textColor),
                      ),
                    ),
                  ),
                  if (_comentarioSalvo.trim().isNotEmpty &&
                      autorAntigo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Por: $autorAntigo',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  if (_comentarioSalvo.trim().isNotEmpty &&
                      dataAntiga != null) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Em: ${_dataHora(dataAntiga)}',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvarComentario,
                      child: Text(
                        'Salvar Comentário',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _lerConfiguracoesDaLoja();
    final cliente = _buscarClienteDoPedido();

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
                  'Venda Registrada',
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
                _blocoAcoes(),
                const SizedBox(height: 12),
                ComandaPedido(
                  theme: theme,
                  pedido: pedido,
                  largura: _larguraBloco,
                  cliente: cliente,
                  camposClienteComanda: config.camposClienteComanda,
                ),
                const SizedBox(height: 12),
                _blocoResumo(),
                const SizedBox(height: 12),
                _blocoItens(),
                const SizedBox(height: 12),
                _blocoComentario(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BarraVenda extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final bool mostrarCliente;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<DadosComentario>? onSalvarComentario;
  final VoidCallback? onExcluir;

  const BarraVenda({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pedido,
    this.mostrarCliente = false,
    this.autorCpf = '',
    this.autorNome = '',
    this.autorEmail = '',
    this.onSalvarComentario,
    this.onExcluir,
  });

  @override
  State<BarraVenda> createState() => _BarraVendaState();
}

class _BarraVendaState extends State<BarraVenda> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String get _detalhe {
    final pedido = widget.pedido;
    final pagamentos = pedido.todosPagamentos;
    final formas = pagamentos
        .map((p) => p.forma)
        .where((f) => f.isNotEmpty)
        .join(' + ');
    final temAPrazo = pagamentos.any((p) => p.forma == 'À Prazo');
    return [
      if (widget.mostrarCliente) pedido.clienteNome,
      _dataHora(pedido.dataHora),
      if (formas.isNotEmpty) formas,
      if (pedido.aPrazoEmAberto) 'em aberto',
      if (pedido.aPrazoEmAberto && pedido.valorPago > 0)
        'pago ${_valor(pedido.valorPago)}',
      if (temAPrazo && pedido.quitado) 'quitado',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => VendaRegistradaDialog.mostrar(
          context,
          theme: theme,
          lojaId: widget.lojaId,
          pedido: pedido,
          autorCpf: widget.autorCpf,
          autorNome: widget.autorNome,
          autorEmail: widget.autorEmail,
          onSalvarComentario: widget.onSalvarComentario,
          onExcluir: widget.onExcluir,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
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
                      '${_numero(pedido.numero)}  ${pedido.produtoNome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      _detalhe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_valor(pedido.valor),
                  style: theme.getTextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}