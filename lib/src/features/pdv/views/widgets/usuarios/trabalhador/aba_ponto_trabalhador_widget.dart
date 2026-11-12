import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';

/// Aba de Ponto Eletrônico do Trabalhador: status do turno, bater entrada/saída e histórico.
class AbaPontoTrabalhadorWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final List<RegistroPontoMembro> pontos;
  final bool temPontoAberto;
  final VoidCallback onBaterPonto;

  const AbaPontoTrabalhadorWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.pontos,
    required this.temPontoAberto,
    required this.onBaterPonto,
  });

  String _formatarDataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (loja == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: temPontoAberto
                ? theme.textColor.withValues(alpha: 0.08)
                : theme.backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: temPontoAberto ? theme.textColor : theme.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: temPontoAberto
                          ? 'Ponto Ativo (Trabalhando)'
                          : 'Ponto Fechado (Fora do Turno)',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    TextoRolante(
                      texto: temPontoAberto
                          ? 'Entrada registrada. Clique para registrar saída.'
                          : 'Clique para registrar início de jornada.',
                      style: theme.getTextStyle(fontSize: 10.5, color: theme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: temPontoAberto
                      ? theme.dangerColor.withValues(alpha: 0.85)
                      : theme.buttonColor,
                  foregroundColor: temPontoAberto ? theme.textColor : theme.buttonTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onBaterPonto,
                icon: Icon(temPontoAberto ? Icons.logout : Icons.login, size: 16),
                label: Text(
                  temPontoAberto ? 'Bater Saída' : 'Bater Entrada',
                  style: theme.getTextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: temPontoAberto ? theme.textColor : theme.buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextoRolante(
          texto: 'Histórico de Ponto (${pontos.length}):',
          style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 6),
        if (pontos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum registro de ponto registrado.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pontos.length,
            separatorBuilder: (_, _) => Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
            itemBuilder: (context, idx) {
              final p = pontos[idx];
              final duracao = p.duracaoTrabalhada;
              final horas = duracao.inHours;
              final minutos = duracao.inMinutes % 60;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      p.estaEmAberto ? Icons.timelapse : Icons.check_circle_outline,
                      size: 14,
                      color: p.estaEmAberto ? theme.secondaryTextColor : theme.textColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextoRolante(
                            texto: 'Entrada: ${_formatarDataHora(p.dataHoraEntrada)}',
                            style: theme.getTextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          TextoRolante(
                            texto: p.dataHoraSaida != null
                                ? 'Saída: ${_formatarDataHora(p.dataHoraSaida!)} • Duração: ${horas}h ${minutos}min'
                                : 'Em andamento...',
                            style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
