import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class ComprasUsuarioView extends StatefulWidget {
  const ComprasUsuarioView({super.key});

  @override
  State<ComprasUsuarioView> createState() => _ComprasUsuarioViewState();
}

class _ComprasUsuarioViewState extends State<ComprasUsuarioView> {
  bool _carregando = true;
  List<CarrinhoPendenteLoja> _carrinhos = [];
  List<RegistroCompraUsuario> _historico = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final cpf = auth.contaAtual?.cpf ?? auth.cpf;

    final carrinhos = await ComprasUsuarioService.carregarCarrinhosPendentes(pdv);
    final historico = auth.modoVisitante
        ? <RegistroCompraUsuario>[]
        : await ComprasUsuarioService.carregarHistoricoCompras(
            cpfUsuario: cpf,
            pdv: pdv,
          );

    if (!mounted) return;
    setState(() {
      _carrinhos = carrinhos;
      _historico = historico;
      _carregando = false;
    });
  }

  String _rotuloStatus(StatusPedido status) {
    switch (status) {
      case StatusPedido.novo:
        return 'Novo • Aguardando';
      case StatusPedido.aceito:
        return 'Aceito • Em Preparo';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  String _formatarDataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  Future<void> _mostrarDetalhesCompra(
    AppTheme theme,
    RegistroCompraUsuario registro,
  ) async {
    final p = registro.pedido;
    final auth = context.read<AuthProvider>();
    final cpfLimpo = (auth.contaAtual?.cpf ?? auth.cpf)
        .replaceAll(RegExp(r'\D'), '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Pedido #${p.numero.toString().padLeft(4, '0')} • ${registro.nomeLoja}',
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.65,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status: ${_rotuloStatus(p.status)}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.status == StatusPedido.cancelado
                        ? theme.dangerColor
                        : theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data: ${_formatarDataHora(p.dataHora)} • ${p.formaPagamento}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                if (p.comanda.trim().isNotEmpty)
                  Text(
                    p.comanda,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  )
                else ...[
                  for (final item in p.itens)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantidade}x ${item.nomeExibicao} — R\$ ${item.subtotal.toStringAsFixed(2)}',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  const Divider(),
                  Text(
                    'Total: R\$ ${p.valor.toStringAsFixed(2)}',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          if (registro.lojaId.isNotEmpty &&
              cpfLimpo.length == 11 &&
              !auth.modoVisitante &&
              !auth.perfilIsolado)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                final convId = ChatService.conversaIdLojaUsuario(
                  registro.lojaId,
                  cpfLimpo,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MensageriaView(
                      modoLoja: false,
                      conversaInicialId: convId,
                    ),
                  ),
                );
              },
              child: Text(
                'Abrir Chat da Loja',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContainerGenerico({
    required AppTheme theme,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required Widget conteudo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 22, color: theme.buttonColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: titulo,
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: subtitulo,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          conteudo,
        ],
      ),
    );
  }

  Widget _buildEmConstrucao(AppTheme theme, String detalhe) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.construction_rounded,
            size: 16,
            color: theme.secondaryTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextoRolante(
              texto: detalhe,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudoCarrinho(AppTheme theme) {
    if (_carregando) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.textColor,
          ),
        ),
      );
    }
    if (_carrinhos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum item pendente no carrinho no momento.',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BuscaMapaView()),
              );
            },
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(
              'Explorar vitrines de lojas',
              style: theme.getTextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (final c in _carrinhos)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.loja?.nome ?? 'Loja (${c.lojaId})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    Text(
                      'R\$ ${c.total.toStringAsFixed(2)}',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.quantidadeTotal} ${c.quantidadeTotal == 1 ? "item" : "itens"}: ${c.itens.map((i) => "${i.quantidade}x ${i.nomeExibicao}").join(", ")}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ComprasUsuarioService.salvarCarrinhoPendente(
                          c.lojaId,
                          const [],
                        );
                        await _carregarDados();
                      },
                      child: Text(
                        'Limpar',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.dangerColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VitrineLojaView(
                              lojaId: c.lojaId,
                              lojaFallback: c.loja,
                            ),
                          ),
                        );
                        await _carregarDados();
                      },
                      child: Text(
                        'Abrir Vitrine',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConteudoHistorico(AppTheme theme) {
    final auth = context.watch<AuthProvider>();
    if (_carregando) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.textColor,
          ),
        ),
      );
    }
    if (auth.modoVisitante) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Entre com sua Conta Nous para acompanhar seu histórico de compras.',
      );
    }
    if (_historico.isEmpty) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Nenhuma compra registrada para o seu CPF ainda.',
      );
    }

    return Column(
      children: [
        for (final r in _historico)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _mostrarDetalhesCompra(theme, r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${r.pedido.numero.toString().padLeft(4, '0')} • ${r.nomeLoja}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      Text(
                        'R\$ ${r.pedido.valor.toStringAsFixed(2)}',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_rotuloStatus(r.pedido.status)} • ${_formatarDataHora(r.pedido.dataHora)}',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: r.pedido.status == StatusPedido.cancelado
                          ? theme.dangerColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                  if (r.pedido.produtoNome.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.pedido.produtoNome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Compras e Carteira',
            showBackButton: false,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: RefreshIndicator(
                  color: theme.textColor,
                  onRefresh: _carregarDados,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      _buildContainerGenerico(
                        theme: theme,
                        icone: Icons.account_balance_wallet_outlined,
                        titulo: 'Carteira Soberana',
                        subtitulo: 'Saldos, moedas locais e meios de pagamento',
                        conteudo: _buildEmConstrucao(
                          theme,
                          'Em construção • Gestão financeira soberana',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildContainerGenerico(
                        theme: theme,
                        icone: Icons.shopping_cart_outlined,
                        titulo: 'Carrinho de Compras',
                        subtitulo: 'Itens selecionados nas vitrines das lojas',
                        conteudo: _buildConteudoCarrinho(theme),
                      ),
                      const SizedBox(height: 16),
                      _buildContainerGenerico(
                        theme: theme,
                        icone: Icons.receipt_long_outlined,
                        titulo: 'Histórico de Compras',
                        subtitulo: 'Pedidos enviados e comandas registradas',
                        conteudo: _buildConteudoHistorico(theme),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: const FloatingBottomNavBar(
            maxWidth: 600,
            slotSelecionado: 0,
            subIndiceSelecionado: 0,
          ),
        );
      },
    );
  }
}
