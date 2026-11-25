import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Barra interativa que exibe o status da sincronização em rede Wi-Fi nas configurações.
class BarraSincronizacaoWifiSettings extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback onTap;

  const BarraSincronizacaoWifiSettings({
    super.key,
    required this.theme,
    required this.onTap,
  });

  @override
  State<BarraSincronizacaoWifiSettings> createState() =>
      _BarraSincronizacaoWifiSettingsState();
}

class _BarraSincronizacaoWifiSettingsState
    extends State<BarraSincronizacaoWifiSettings> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();

    return ValueListenableBuilder<bool>(
      valueListenable: servidor.estaAtivo,
      builder: (context, servidorAtivo, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: cliente.estaConectado,
          builder: (context, clienteConectado, _) {
            final bool conectado = servidorAtivo || clienteConectado;
            const corConectado = Color(0xFF22C55E);

            String statusTexto;
            if (servidorAtivo) {
              final ip = servidor.ipServidor ?? 'Local';
              statusTexto = 'Servidor Balcão Ativo ($ip:${servidor.porta})';
            } else if (clienteConectado) {
              final end = cliente.enderecoServidor ?? 'Wi-Fi Local';
              statusTexto = 'Conectado ao Balcão ($end)';
            } else {
              statusTexto = 'Desconectado — Toque para conectar ou gerenciar';
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _hover
                        ? theme.borderColor.withValues(alpha: 0.18)
                        : theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hover
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.6),
                      width: _hover ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: conectado
                              ? corConectado.withValues(alpha: 0.16)
                              : theme.borderColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: conectado
                                ? corConectado.withValues(alpha: 0.65)
                                : theme.borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          conectado
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          size: 18,
                          color: conectado
                              ? corConectado
                              : theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sincronização em Rede Wi-Fi',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusTexto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: conectado
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: _hover
                            ? theme.textColor
                            : theme.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
