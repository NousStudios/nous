import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_filtros_helper.dart';

/// Barra lateral vertical de ícones da Mensageria (inspirada no WhatsApp Web).
class BarraNavegacaoMensageriaWidget extends StatelessWidget {
  final AppTheme theme;
  final AbaNavegacaoMensageria abaAtiva;
  final int totalNaoLidas;
  final void Function(AbaNavegacaoMensageria) onSelecionarAba;

  const BarraNavegacaoMensageriaWidget({
    super.key,
    required this.theme,
    required this.abaAtiva,
    required this.totalNaoLidas,
    required this.onSelecionarAba,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.75),
        border: Border(
          right: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _BotaoNavVertical(
            theme: theme,
            icone: Icons.chat_bubble_outline_rounded,
            iconeAtivo: Icons.chat_bubble_rounded,
            tooltip: 'Conversas',
            ativo: abaAtiva == AbaNavegacaoMensageria.conversas,
            badgeCount: totalNaoLidas,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.conversas),
          ),
          const SizedBox(height: 6),
          _BotaoNavVertical(
            theme: theme,
            icone: Icons.call_outlined,
            iconeAtivo: Icons.call_rounded,
            tooltip: 'Ligações',
            ativo: abaAtiva == AbaNavegacaoMensageria.ligacoes,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.ligacoes),
          ),
          const SizedBox(height: 6),
          _BotaoNavVertical(
            theme: theme,
            icone: Icons.groups_outlined,
            iconeAtivo: Icons.groups_rounded,
            tooltip: 'Comunidades',
            ativo: abaAtiva == AbaNavegacaoMensageria.comunidades,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.comunidades),
          ),
          const SizedBox(height: 6),
          _BotaoNavVertical(
            theme: theme,
            icone: Icons.campaign_outlined,
            iconeAtivo: Icons.campaign_rounded,
            tooltip: 'Lista de Transmissão',
            ativo: abaAtiva == AbaNavegacaoMensageria.transmissao,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.transmissao),
          ),
        ],
      ),
    );
  }
}

class _BotaoNavVertical extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final IconData iconeAtivo;
  final String tooltip;
  final bool ativo;
  final int badgeCount;
  final VoidCallback onTap;

  const _BotaoNavVertical({
    required this.theme,
    required this.icone,
    required this.iconeAtivo,
    required this.tooltip,
    required this.ativo,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ativo
                ? theme.textColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: ativo
                ? Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                ativo ? iconeAtivo : icone,
                size: 22,
                color: ativo ? theme.textColor : theme.secondaryTextColor,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dangerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 15),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.backgroundColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de navegação inferior estilo WhatsApp Mobile.
/// Exibida no modo compacto (celular) apenas enquanto visualiza as listas/abas principais.
class BarraNavegacaoInferiorMensageriaWidget extends StatelessWidget {
  final AppTheme theme;
  final AbaNavegacaoMensageria abaAtiva;
  final int totalNaoLidas;
  final void Function(AbaNavegacaoMensageria) onSelecionarAba;

  const BarraNavegacaoInferiorMensageriaWidget({
    super.key,
    required this.theme,
    required this.abaAtiva,
    required this.totalNaoLidas,
    required this.onSelecionarAba,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      height: 62 + bottomPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ItemNavInferior(
            theme: theme,
            icone: Icons.chat_bubble_outline_rounded,
            iconeAtivo: Icons.chat_bubble_rounded,
            label: 'Conversas',
            ativo: abaAtiva == AbaNavegacaoMensageria.conversas,
            badgeCount: totalNaoLidas,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.conversas),
          ),
          _ItemNavInferior(
            theme: theme,
            icone: Icons.call_outlined,
            iconeAtivo: Icons.call_rounded,
            label: 'Ligações',
            ativo: abaAtiva == AbaNavegacaoMensageria.ligacoes,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.ligacoes),
          ),
          _ItemNavInferior(
            theme: theme,
            icone: Icons.groups_outlined,
            iconeAtivo: Icons.groups_rounded,
            label: 'Comunidades',
            ativo: abaAtiva == AbaNavegacaoMensageria.comunidades,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.comunidades),
          ),
          _ItemNavInferior(
            theme: theme,
            icone: Icons.campaign_outlined,
            iconeAtivo: Icons.campaign_rounded,
            label: 'Transmissão',
            ativo: abaAtiva == AbaNavegacaoMensageria.transmissao,
            onTap: () => onSelecionarAba(AbaNavegacaoMensageria.transmissao),
          ),
        ],
      ),
    );
  }
}

class _ItemNavInferior extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final IconData iconeAtivo;
  final String label;
  final bool ativo;
  final int badgeCount;
  final VoidCallback onTap;

  const _ItemNavInferior({
    required this.theme,
    required this.icone,
    required this.iconeAtivo,
    required this.label,
    required this.ativo,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: ativo
                      ? theme.textColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      ativo ? iconeAtivo : icone,
                      size: 22,
                      color: ativo ? theme.textColor : theme.secondaryTextColor,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -3,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dangerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 15),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.backgroundColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                      color: ativo ? theme.textColor : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
