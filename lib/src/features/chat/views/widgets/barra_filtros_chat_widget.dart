import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_filtros_helper.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';

/// Barra horizontal de filtros de chats (Tudo, Não lidas, Grupos, Favoritas e personalizados).
class BarraFiltrosChatWidget extends StatelessWidget {
  final AppTheme theme;
  final TipoFiltroChat filtroAtivo;
  final String? filtroPersonalizadoId;
  final List<FiltroChatPersonalizado> filtrosPersonalizados;
  final int totalNaoLidas;
  final void Function(TipoFiltroChat tipo, {String? personalizadoId})
      onSelecionarFiltro;
  final VoidCallback onCriarFiltro;
  final void Function(FiltroChatPersonalizado) onGerenciarFiltro;

  const BarraFiltrosChatWidget({
    super.key,
    required this.theme,
    required this.filtroAtivo,
    required this.filtroPersonalizadoId,
    required this.filtrosPersonalizados,
    required this.totalNaoLidas,
    required this.onSelecionarFiltro,
    required this.onCriarFiltro,
    required this.onGerenciarFiltro,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _ChipFiltro(
            theme: theme,
            label: 'Tudo',
            selecionado: filtroAtivo == TipoFiltroChat.tudo,
            onTap: () => onSelecionarFiltro(TipoFiltroChat.tudo),
          ),
          const SizedBox(width: 6),
          _ChipFiltro(
            theme: theme,
            label: totalNaoLidas > 0 ? 'Não lidas ($totalNaoLidas)' : 'Não lidas',
            selecionado: filtroAtivo == TipoFiltroChat.naoLidas,
            onTap: () => onSelecionarFiltro(TipoFiltroChat.naoLidas),
          ),
          const SizedBox(width: 6),
          _ChipFiltro(
            theme: theme,
            label: 'Grupos',
            selecionado: filtroAtivo == TipoFiltroChat.grupos,
            onTap: () => onSelecionarFiltro(TipoFiltroChat.grupos),
          ),
          const SizedBox(width: 6),
          _ChipFiltro(
            theme: theme,
            label: 'Favoritas',
            selecionado: filtroAtivo == TipoFiltroChat.favoritas,
            onTap: () => onSelecionarFiltro(TipoFiltroChat.favoritas),
          ),
          for (final filtro in filtrosPersonalizados) ...[
            const SizedBox(width: 6),
            _ChipFiltro(
              theme: theme,
              label: filtro.nome,
              selecionado:
                  filtroAtivo == TipoFiltroChat.personalizado &&
                  filtroPersonalizadoId == filtro.id,
              onTap: () => onSelecionarFiltro(
                TipoFiltroChat.personalizado,
                personalizadoId: filtro.id,
              ),
              onLongPress: () => onGerenciarFiltro(filtro),
            ),
          ],
          const SizedBox(width: 6),
          Tooltip(
            message: 'Criar filtro personalizado',
            child: InkWell(
              onTap: onCriarFiltro,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final bool selecionado;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChipFiltro({
    required this.theme,
    required this.label,
    required this.selecionado,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor
              : theme.cardBackgroundColor.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
            color: selecionado ? theme.backgroundColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
