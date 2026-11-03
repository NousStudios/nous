import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

/// Card que exibe dados operacionais do turno (abertura, fechamento, operadores e observações).
class CardOperacionalTurno extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TurnoCaixa turno;
  final String Function(DateTime, DateTime?) duracaoTurno;
  final String Function(DateTime) formatarDataHora;
  final String Function(String) formatarCpf;
  final Widget Function(String, String, {double raio}) buildAvatarUsuario;

  const CardOperacionalTurno({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.turno,
    required this.duracaoTurno,
    required this.formatarDataHora,
    required this.formatarCpf,
    required this.buildAvatarUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final t = turno;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Dados do Turno',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        size: 13, color: theme.secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      'Duração: ${duracaoTurno(t.dataAbertura, t.dataFechamento)}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Abertura
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline,
                              size: 14, color: theme.textColor),
                          const SizedBox(width: 4),
                          Text(
                            'Abertura',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatarDataHora(t.dataAbertura),
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          buildAvatarUsuario(
                            t.abertoPorCpf,
                            t.abertoPorNome,
                            raio: 13,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.abertoPorNome.isNotEmpty
                                      ? t.abertoPorNome
                                      : 'Operador não identificado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (t.abertoPorCpf.isNotEmpty)
                                  Text(
                                    'CPF: ${formatarCpf(t.abertoPorCpf)}',
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Fechamento
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: theme.textColor),
                          const SizedBox(width: 4),
                          Text(
                            'Fechamento',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.dataFechamento != null
                            ? formatarDataHora(t.dataFechamento!)
                            : 'Em aberto',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          buildAvatarUsuario(
                            t.fechadoPorCpf,
                            t.fechadoPorNome,
                            raio: 13,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.fechadoPorNome.isNotEmpty
                                      ? t.fechadoPorNome
                                      : 'Operador não identificado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (t.fechadoPorCpf.isNotEmpty)
                                  Text(
                                    'CPF: ${formatarCpf(t.fechadoPorCpf)}',
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (t.observacao.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 14, color: theme.secondaryTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Observação do Fechamento: ${t.observacao.trim()}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
