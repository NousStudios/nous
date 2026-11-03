import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios/filtros_relatorio_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios/pendencias_relatorio_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios/pedidos_programados_relatorio_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/relatorios/auditoria_relatorio_widget.dart';

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
      return TextoUtils.contemIgnorandoAcentos(p.clienteNome, termo) ||
          TextoUtils.contemIgnorandoAcentos(p.produtoNome, termo) ||
          TextoUtils.contemIgnorandoAcentos(formas, termo) ||
          TextoUtils.contemIgnorandoAcentos(p.comanda, termo) ||
          numero.contains(termo);
    }).toList();

    if (desde != null) {
      lista.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    } else {
      lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    }
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

  void _clicarPendenciaAgrupada(PendenciaClienteAgrupada item) {
    final abrirClientes = widget.aoAbrirClientes;
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);

    // 1. Se tem clienteId e o callback existe, abre a ficha do cliente
    if (abrirClientes != null &&
        item.clienteId != null &&
        item.clienteId!.isNotEmpty) {
      Navigator.of(context).pop();
      abrirClientes(item.clienteId!);
      return;
    }

    // 2. Se não tem clienteId, tenta encontrar o cliente cadastrado pelo nome
    if (abrirClientes != null && loja != null) {
      final clienteNomeLimpo = item.clienteNome.trim().toLowerCase();
      final clienteEncontrado = loja.clientesLoja.where((c) =>
          c.nome.trim().toLowerCase() == clienteNomeLimpo).firstOrNull;
      if (clienteEncontrado != null) {
        Navigator.of(context).pop();
        abrirClientes(clienteEncontrado.id);
        return;
      }
    }

    // 3. Se for pedido avulso ou sem cliente cadastrado, abre diretamente a comanda
    VendaRegistradaDialog.mostrar(
      context,
      theme: theme,
      lojaId: widget.lojaId,
      pedido: item.ultimoPedido,
      autorCpf: widget.autorCpf,
      autorNome: widget.autorNome,
      autorEmail: widget.autorEmail,
      onSalvarComentario: widget.onSalvarComentario != null
          ? (dados) => widget.onSalvarComentario!(
                item.ultimoPedido.id,
                dados,
              )
          : null,
      onExcluir: widget.onExcluirPedido != null
          ? () => widget.onExcluirPedido!(item.ultimoPedido.id)
          : null,
    );
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

  Widget _blocoRelatorios() {
    final vendas = _filtrados;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Relatórios',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          TextField(
            controller: _buscaController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Pesquisar vendas'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          FiltrosRelatorioWidget(
            theme: theme,
            formaSelecionada: _forma,
            onFormaChanged: (novaForma) => setState(() => _forma = novaForma),
            dataController: _dataController,
            scrollController: _filtrosScrollController,
            onDataChanged: () => setState(() {}),
            dataInicial: _dataInicial,
          ),
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

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final acoes = loja?.acoes ?? const <RegistroAcao>[];
    final pendencias = PendenciaClienteAgrupada.agrupar(_pedidos);

    final blocoRelatorios = _blocoRelatorios();
    final blocoPedidosProgramados = PedidosProgramadosRelatorioWidget(
      theme: theme,
      lojaId: widget.lojaId,
      dataInicial: _dataInicial,
    );
    final blocoPendencias = PendenciasRelatorioWidget(
      theme: theme,
      lojaId: widget.lojaId,
      pendencias: pendencias,
      onClicarPendencia: _clicarPendenciaAgrupada,
    );
    final blocoAcoes = AuditoriaRelatorioWidget(
      theme: theme,
      lojaId: widget.lojaId,
      acoesOrigem: acoes,
      pedidos: _pedidos,
      autorCpf: widget.autorCpf,
      autorNome: widget.autorNome,
      autorEmail: widget.autorEmail,
      onExcluirPedido: _excluirPedido,
      onSalvarComentario: _salvarComentarioPedido,
      aoAbrirClientes: widget.aoAbrirClientes,
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
                            blocoRelatorios,
                            const SizedBox(height: 12),
                            blocoPedidosProgramados,
                            const SizedBox(height: 12),
                            blocoPendencias,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            blocoAcoes,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      blocoRelatorios,
                      const SizedBox(height: 12),
                      blocoPedidosProgramados,
                      const SizedBox(height: 12),
                      blocoPendencias,
                      const SizedBox(height: 12),
                      blocoAcoes,
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}