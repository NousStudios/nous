import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Gaveta expansível que exibe o último registro de ponto e a escala de trabalho de um membro.
class SecaoPontoEscalaMembroWidget extends StatelessWidget {
  final String lojaId;
  final MembroLoja membro;
  final String cpfLogado;
  final AppTheme theme;

  const SecaoPontoEscalaMembroWidget({
    super.key,
    required this.lojaId,
    required this.membro,
    required this.cpfLogado,
    required this.theme,
  });

  String _formatarHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)} às ${dois(d.hour)}:${dois(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    final auth = context.watch<AuthProvider>();
    final contaMembro = auth.buscarContaPorCpf(membro.cpf);
    final ehEuMesmo = cpfLogado.replaceAll(RegExp(r'\D'), '') ==
        membro.cpf.replaceAll(RegExp(r'\D'), '');

    // Permissões da Conta Nous
    final pontoPrivado = !ehEuMesmo &&
        (contaMembro?.dadoEstaPrivado('registroPonto') ?? false) &&
        !(contaMembro?.dadoAutorizadoPara('registroPonto', cpfLogado) ?? false);
    final escalaPrivada = !ehEuMesmo &&
        (contaMembro?.dadoEstaPrivado('escalaTrabalho') ?? false) &&
        !(contaMembro?.dadoAutorizadoPara('escalaTrabalho', cpfLogado) ?? false);

    final pontos = (loja?.registrosPonto ?? const <RegistroPontoMembro>[])
        .where((p) => p.cpf == membro.cpf)
        .toList()
      ..sort((a, b) => b.dataHoraEntrada.compareTo(a.dataHoraEntrada));
    final ultimoPonto = pontos.firstOrNull;

    final escala = (loja?.escalasTrabalho ?? const <EscalaTrabalhoMembro>[])
        .where((e) => e.cpf == membro.cpf)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Registro de Ponto:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pontoPrivado
                      ? 'Informação privada pelo colaborador'
                      : (ultimoPonto != null
                          ? '${ultimoPonto.estaEmAberto ? "Em jornada desde" : "Última saída em"} ${_formatarHora(ultimoPonto.estaEmAberto ? ultimoPonto.dataHoraEntrada : (ultimoPonto.dataHoraSaida ?? ultimoPonto.dataHoraEntrada))}'
                          : 'Nenhum ponto registrado hoje'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: pontoPrivado
                        ? theme.secondaryTextColor
                        : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 13,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Escala de Trabalho:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  escalaPrivada
                      ? 'Informação privada pelo colaborador'
                      : (escala != null && escala.horarioEntrada.isNotEmpty
                          ? '${escala.resumoDias()}: ${escala.horarioEntrada} às ${escala.horarioSaida}'
                          : 'Escala flexível / Não definida'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: escalaPrivada
                        ? theme.secondaryTextColor
                        : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
