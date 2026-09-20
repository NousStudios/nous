import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

enum AbaPedidos { novos, aceitos, concluidos }

const double _alturaListaPedidos = 260;

String _numeroFormatado(int numero) => '#${numero.toString().padLeft(4, '0')}';

String _dataHoraFormatada(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class GestaoLojaContainer extends StatelessWidget {
  final AppTheme theme;
  final bool lojaOnline;
  final ValueChanged<bool> aoAlterarOnline;
  final AbaPedidos abaPedidos;
  final ValueChanged<AbaPedidos> aoTrocarAbaPedidos;
  final List<PedidoLoja> pedidos;
  final ValueChanged<String> aoAceitar;
  final ValueChanged<String> aoRecusar;
  final ValueChanged<String> aoConcluir;

  const GestaoLojaContainer({
    super.key,
    required this.theme,
    required this.lojaOnline,
    required this.aoAlterarOnline,
    required this.abaPedidos,
    required this.aoTrocarAbaPedidos,
    required this.pedidos,
    required this.aoAceitar,
    required this.aoRecusar,
    required this.aoConcluir,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _emConstrucao(BuildContext context, String rotulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$rotulo: em construção')),
    );
  }

  Widget _botaoDeGestao(BuildContext context, String rotulo) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textColor,
            side: BorderSide(color: theme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _emConstrucao(context, rotulo),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _blocoStatus() {
    return Expanded(
      flex: 2,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status', style: theme.getTextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.only(left: 12, right: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lojaOnline ? 'Online' : 'Offline',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: lojaOnline,
                      onChanged: aoAlterarOnline,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeThumbColor: theme.textColor,
                      activeTrackColor:
                          theme.borderColor.withValues(alpha: 0.4),
                      inactiveThumbColor: theme.secondaryTextColor,
                      inactiveTrackColor: Colors.transparent,
                      trackOutlineColor:
                          WidgetStatePropertyAll(theme.borderColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocoDeBotoes(BuildContext context) {
    const espaco = SizedBox(width: 8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Row(
            children: [
              _botaoDeGestao(context, 'Nova Venda'),
              espaco,
              _botaoDeGestao(context, 'Clientes'),
              espaco,
              _botaoDeGestao(context, 'Impressora'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _botaoDeGestao(context, 'Relatórios'),
              espaco,
              _botaoDeGestao(context, 'Perfil'),
              espaco,
              _botaoDeGestao(context, 'Financeiro'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _botaoDeGestao(context, 'Mensagens'),
              espaco,
              _blocoStatus(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _abaDePedidos(String rotulo, AbaPedidos aba) {
    final selecionada = aba == abaPedidos;
    return Expanded(
      child: InkWell(
        onTap: () => aoTrocarAbaPedidos(aba),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selecionada ? theme.textColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: 13,
                  color:
                      selecionada ? theme.textColor : theme.secondaryTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirMenuDoPedido(BuildContext context, PedidoLoja pedido) {
    void agir(BuildContext dialogContext, ValueChanged<String> acao) {
      Navigator.of(dialogContext).pop();
      acao(pedido.id);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Pedido ${_numeroFormatado(pedido.numero)}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            pedido.produtoNome,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (pedido.status == StatusPedido.novo) ...[
              TextButton(
                onPressed: () => agir(dialogContext, aoRecusar),
                child: Text(
                  'Recusar',
                  style: theme.getTextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () => agir(dialogContext, aoAceitar),
                child: Text(
                  'Aceitar',
                  style: theme.getTextStyle(color: theme.textColor),
                ),
              ),
            ],
            if (pedido.status == StatusPedido.aceito)
              TextButton(
                onPressed: () => agir(dialogContext, aoConcluir),
                child: Text(
                  'Concluir',
                  style: theme.getTextStyle(color: theme.textColor),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _barraDoPedido(BuildContext context, PedidoLoja pedido) {
    final fonteMiuda = theme.getTextStyle(fontSize: 9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 26, color: theme.textColor),
                Text(
                  pedido.clienteNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: fonteMiuda,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.inventory_2_outlined, size: 22, color: theme.textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              pedido.produtoNome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pedido ${_numeroFormatado(pedido.numero)}',
                  style: fonteMiuda),
              Text(_dataHoraFormatada(pedido.dataHora), style: fonteMiuda),
              Text(_valorFormatado(pedido.valor), style: fonteMiuda),
            ],
          ),
          if (pedido.temMensagem)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 20,
                color: theme.textColor,
              ),
            ),
          if (pedido.status == StatusPedido.concluido)
            const SizedBox(width: 8)
          else
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.more_vert, size: 20, color: theme.textColor),
              onPressed: () => _abrirMenuDoPedido(context, pedido),
            ),
        ],
      ),
    );
  }

  Widget _listaDePedidos(BuildContext context) {
    final statusDaAba = switch (abaPedidos) {
      AbaPedidos.novos => StatusPedido.novo,
      AbaPedidos.aceitos => StatusPedido.aceito,
      AbaPedidos.concluidos => StatusPedido.concluido,
    };
    final pedidosDaAba =
        pedidos.where((pedido) => pedido.status == statusDaAba).toList();

    if (pedidosDaAba.isEmpty) {
      final mensagem = switch (abaPedidos) {
        AbaPedidos.novos => 'Nenhum pedido novo.',
        AbaPedidos.aceitos => 'Nenhum pedido aceito.',
        AbaPedidos.concluidos => 'Nenhum pedido concluído.',
      };
      return EstadoVazioContainer(theme: theme, mensagem: mensagem);
    }

    return SizedBox(
      height: _alturaListaPedidos,
      child: ListView.separated(
        itemCount: pedidosDaAba.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _barraDoPedido(context, pedidosDaAba[index]),
      ),
    );
  }

  Widget _blocoDePedidos(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Row(
            children: [
              _abaDePedidos('Novos', AbaPedidos.novos),
              _abaDePedidos('Aceitos', AbaPedidos.aceitos),
              _abaDePedidos('Concluídos', AbaPedidos.concluidos),
            ],
          ),
          const SizedBox(height: 12),
          _listaDePedidos(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _blocoDeBotoes(context),
        const SizedBox(height: 16),
        _blocoDePedidos(context),
      ],
    );
  }
}