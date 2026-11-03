import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja/bloco_botoes_gestao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja/bloco_pedidos_gestao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/mesas_container.dart';

enum AbaPedidos { novos, aceitos, concluidos, cancelados }

class GestaoLojaContainer extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final bool lojaOnline;
  final ValueChanged<bool> aoAlterarOnline;
  final AbaPedidos abaPedidos;
  final ValueChanged<AbaPedidos> aoTrocarAbaPedidos;
  final List<PedidoLoja> pedidos;
  final ValueChanged<String> aoAceitar;
  final ValueChanged<String> aoRecusar;
  final ValueChanged<String> aoConcluir;
  final ValueChanged<String>? aoCancelarPedido;
  final void Function(String pedidoId, DadosComentario dados)?
      aoSalvarComentario;
  final ValueChanged<String>? aoExcluirPedido;
  final List<Cliente> clientes;
  final List<ItemLoja> itensDisponiveis;
  final VoidCallback aoNovaVenda;
  final VoidCallback aoClientes;
  final VoidCallback? aoMensagens;
  final VoidCallback aoRelatorios;
  final VoidCallback? aoImpressora;
  final VoidCallback? aoFinanceiro;
  final VoidCallback? aoCaixa;
  final bool caixaAberto;
  final VoidCallback? aoStatus;
  final bool ehRestaurante;
  final List<MesaLoja> mesas;
  final VoidCallback? aoCriarMesa;
  final ValueChanged<MesaLoja>? aoClicarMesa;
  final bool ocultarBotoesTopo;
  final bool temNovasMensagens;

  const GestaoLojaContainer({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    required this.lojaOnline,
    required this.aoAlterarOnline,
    required this.abaPedidos,
    required this.aoTrocarAbaPedidos,
    required this.pedidos,
    this.clientes = const [],
    this.itensDisponiveis = const [],
    required this.aoAceitar,
    required this.aoRecusar,
    required this.aoConcluir,
    this.aoCancelarPedido,
    this.aoSalvarComentario,
    this.aoExcluirPedido,
    required this.aoNovaVenda,
    required this.aoClientes,
    this.aoMensagens,
    required this.aoRelatorios,
    this.aoImpressora,
    this.aoFinanceiro,
    this.aoCaixa,
    this.caixaAberto = false,
    this.aoStatus,
    this.ehRestaurante = false,
    this.mesas = const [],
    this.aoCriarMesa,
    this.aoClicarMesa,
    this.ocultarBotoesTopo = false,
    this.temNovasMensagens = false,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!ocultarBotoesTopo) ...[
          BlocoBotoesGestaoWidget(
            theme: theme,
            decoracaoBloco: _decoracaoDoBloco,
            lojaOnline: lojaOnline,
            aoAlterarOnline: aoAlterarOnline,
            aoNovaVenda: aoNovaVenda,
            aoClientes: aoClientes,
            aoImpressora: aoImpressora,
            aoRelatorios: aoRelatorios,
            aoCaixa: aoCaixa,
            caixaAberto: caixaAberto,
            aoFinanceiro: aoFinanceiro,
            aoMensagens: aoMensagens,
            temNovasMensagens: temNovasMensagens,
            aoStatus: aoStatus,
          ),
          const SizedBox(height: 16),
        ],
        if (ehRestaurante && aoCriarMesa != null && aoClicarMesa != null) ...[
          MesasContainer(
            theme: theme,
            mesas: mesas,
            aoCriarMesa: aoCriarMesa!,
            aoClicarMesa: aoClicarMesa!,
          ),
          const SizedBox(height: 16),
        ],
        BlocoPedidosGestaoWidget(
          theme: theme,
          lojaId: lojaId,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorEmail: autorEmail,
          decoracaoBloco: _decoracaoDoBloco,
          abaPedidos: abaPedidos,
          aoTrocarAbaPedidos: aoTrocarAbaPedidos,
          pedidos: pedidos,
          clientes: clientes,
          itensDisponiveis: itensDisponiveis,
          aoAceitar: aoAceitar,
          aoRecusar: aoRecusar,
          aoConcluir: aoConcluir,
          aoCancelarPedido: aoCancelarPedido,
          aoSalvarComentario: aoSalvarComentario,
          aoExcluirPedido: aoExcluirPedido,
        ),
      ],
    );
  }
}