import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class BlocoBotoesGestaoWidget extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracaoBloco;
  final bool lojaOnline;
  final ValueChanged<bool> aoAlterarOnline;
  final VoidCallback aoNovaVenda;
  final VoidCallback aoClientes;
  final VoidCallback? aoImpressora;
  final VoidCallback aoRelatorios;
  final VoidCallback? aoCaixa;
  final bool caixaAberto;
  final VoidCallback? aoFinanceiro;
  final VoidCallback? aoMensagens;
  final bool temNovasMensagens;
  final VoidCallback? aoStatus;

  const BlocoBotoesGestaoWidget({
    super.key,
    required this.theme,
    required this.decoracaoBloco,
    required this.lojaOnline,
    required this.aoAlterarOnline,
    required this.aoNovaVenda,
    required this.aoClientes,
    this.aoImpressora,
    required this.aoRelatorios,
    this.aoCaixa,
    this.caixaAberto = false,
    this.aoFinanceiro,
    this.aoMensagens,
    this.temNovasMensagens = false,
    this.aoStatus,
  });

  void _emConstrucao(BuildContext context, String rotulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$rotulo: em construção')),
    );
  }

  Widget _botaoDeGestao(
    BuildContext context,
    String rotulo, {
    VoidCallback? aoPressionar,
    bool temPontoVermelho = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: aoPressionar ?? () => _emConstrucao(context, rotulo),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
                ),
              ),
            ),
            if (temPontoVermelho)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.dangerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _blocoStatus(BuildContext context) {
    return Expanded(
      flex: 2,
      child: _ComHoverWidget(
        cursor: SystemMouseCursors.click,
        aoClicar: aoStatus,
        builder: (hover) => Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status da Loja', style: theme.getTextStyle(fontSize: 12)),
                const SizedBox(width: 8),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(width: 8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracaoBloco,
      child: Column(
        children: [
          Row(
            children: [
              _botaoDeGestao(context, 'Nova Venda', aoPressionar: aoNovaVenda),
              espaco,
              _botaoDeGestao(context, 'Clientes', aoPressionar: aoClientes),
              espaco,
              _botaoDeGestao(
                context,
                'Impressora',
                aoPressionar: aoImpressora,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _botaoDeGestao(context, 'Relatórios', aoPressionar: aoRelatorios),
              espaco,
              _botaoDeGestao(
                context,
                caixaAberto ? 'Caixa (Aberto)' : 'Caixa',
                aoPressionar: aoCaixa,
              ),
              espaco,
              _botaoDeGestao(
                context,
                'Financeiro',
                aoPressionar: aoFinanceiro,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _botaoDeGestao(
                context,
                'Mensagens',
                aoPressionar: aoMensagens,
                temPontoVermelho: temNovasMensagens,
              ),
              espaco,
              _blocoStatus(context),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComHoverWidget extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? aoClicar;
  final MouseCursor cursor;

  const _ComHoverWidget({
    required this.builder,
    this.aoClicar,
    this.cursor = SystemMouseCursors.basic,
  });

  @override
  State<_ComHoverWidget> createState() => _ComHoverWidgetState();
}

class _ComHoverWidgetState extends State<_ComHoverWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
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
