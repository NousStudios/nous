import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

class CardMovimentoTurno extends StatefulWidget {
  final AppTheme theme;
  final MovimentoCaixa movimento;
  final bool ehSangria;
  final String Function(double) formatarMoeda;
  final String Function(DateTime) formatarDataHora;
  final String Function(String) formatarCpf;
  final Widget Function(String, String, {double raio}) buildAvatar;

  const CardMovimentoTurno({
    super.key,
    required this.theme,
    required this.movimento,
    required this.ehSangria,
    required this.formatarMoeda,
    required this.formatarDataHora,
    required this.formatarCpf,
    required this.buildAvatar,
  });

  @override
  State<CardMovimentoTurno> createState() => _CardMovimentoTurnoState();
}

class _CardMovimentoTurnoState extends State<CardMovimentoTurno> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.movimento;
    final theme = widget.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : theme.borderColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.35),
            width: _hover ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.ehSangria
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : theme.borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.ehSangria
                      ? Colors.redAccent
                      : theme.borderColor.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.ehSangria ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: widget.ehSangria ? Colors.redAccent : theme.textColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.ehSangria
                            ? 'Sangria (Retirada de Dinheiro)'
                            : 'Suprimento (Entrada de Dinheiro)',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.ehSangria
                              ? Colors.redAccent
                              : theme.textColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.ehSangria ? "-" : "+"}${widget.formatarMoeda(m.valor)}',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.ehSangria
                              ? Colors.redAccent
                              : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      widget.buildAvatar(
                        m.autorCpf,
                        m.autorNome,
                        raio: 10,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.ehSangria ? "Retirado por" : "Inserido por"}: '
                          '${m.autorNome.isNotEmpty ? m.autorNome : "Não identificado"}'
                          '${m.autorCpf.isNotEmpty ? " • CPF ${widget.formatarCpf(m.autorCpf)}" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Motivo: ${m.motivo.isNotEmpty ? m.motivo : "Sem justificativa informada"}',
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      Text(
                        widget.formatarDataHora(m.dataHora),
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
