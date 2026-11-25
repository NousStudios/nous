import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_movimento_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/card_venda_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class AbasDetalhesTurno extends StatelessWidget {
  final AppTheme theme;
  final int abaSelecionada;
  final ValueChanged<int> aoSelecionarAba;
  final List<MovimentoCaixa> movimentacoes;
  final List<PedidoLoja> pedidosDoTurno;
  final String Function(double) formatarMoeda;
  final String Function(DateTime) formatarDataHora;
  final String Function(String) formatarCpf;
  final Widget Function(String, String, {double raio}) buildAvatarUsuario;

  const AbasDetalhesTurno({
    super.key,
    required this.theme,
    required this.abaSelecionada,
    required this.aoSelecionarAba,
    required this.movimentacoes,
    required this.pedidosDoTurno,
    required this.formatarMoeda,
    required this.formatarDataHora,
    required this.formatarCpf,
    required this.buildAvatarUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              _BotaoAbaTurno(
                theme: theme,
                selecionada: abaSelecionada == 0,
                titulo: 'Retiradas e Entradas',
                contador: movimentacoes.length,
                icone: Icons.sync_alt,
                aoTocar: () => aoSelecionarAba(0),
              ),
              const SizedBox(width: 8),
              _BotaoAbaTurno(
                theme: theme,
                selecionada: abaSelecionada == 1,
                titulo: 'Vendas do Turno',
                contador: pedidosDoTurno.length,
                icone: Icons.receipt_long_outlined,
                aoTocar: () => aoSelecionarAba(1),
              ),
            ],
          ),
        ),
        if (abaSelecionada == 0)
          _buildListaMovimentacoes()
        else
          _buildListaVendas(),
      ],
    );
  }

  Widget _buildListaMovimentacoes() {
    final movs = movimentacoes.reversed.toList();

    if (movs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma retirada ou suprimento registrado neste turno.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final m = movs[index];
        final ehSangria = m.tipo == TipoMovimentoCaixa.sangria;

        return CardMovimentoTurno(
          theme: theme,
          movimento: m,
          ehSangria: ehSangria,
          formatarMoeda: formatarMoeda,
          formatarDataHora: formatarDataHora,
          formatarCpf: formatarCpf,
          buildAvatar: buildAvatarUsuario,
        );
      },
    );
  }

  Widget _buildListaVendas() {
    if (pedidosDoTurno.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma venda registrada durante o período deste turno.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pedidosDoTurno.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return CardVendaTurno(
          theme: theme,
          pedido: pedidosDoTurno[index],
          formatarMoeda: formatarMoeda,
          formatarDataHora: formatarDataHora,
        );
      },
    );
  }
}

class _BotaoAbaTurno extends StatelessWidget {
  final AppTheme theme;
  final bool selecionada;
  final String titulo;
  final int contador;
  final IconData icone;
  final VoidCallback aoTocar;

  const _BotaoAbaTurno({
    required this.theme,
    required this.selecionada,
    required this.titulo,
    required this.contador,
    required this.icone,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: aoTocar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: selecionada
                  ? theme.borderColor.withValues(alpha: 0.22)
                  : theme.backgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selecionada
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.4),
                width: selecionada ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 14,
                  color: selecionada ? theme.textColor : theme.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight:
                        selecionada ? FontWeight.bold : FontWeight.normal,
                    color: selecionada
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selecionada
                        ? theme.borderColor.withValues(alpha: 0.3)
                        : theme.borderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$contador',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selecionada
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
