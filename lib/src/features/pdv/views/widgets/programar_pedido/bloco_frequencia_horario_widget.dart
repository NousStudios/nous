import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_digitar_horario.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido/calendario_programacao_widget.dart';

class BlocoFrequenciaHorarioWidget extends StatelessWidget {
  final AppTheme theme;
  final String modoProgramacao;
  final ValueChanged<String> onModoProgramacaoChanged;
  final Set<int> diasSemanaSelecionados;
  final ValueChanged<int> onAlternarDiaSemana;
  final void Function(List<int> dias) onDefinirDiasSemana;
  final DateTime mesCalendario;
  final ValueChanged<DateTime> onMesCalendarioChanged;
  final Set<DateTime> datasEspecificasSelecionadas;
  final ValueChanged<DateTime> onAlternarDataEspecifica;
  final TimeOfDay horarioSelecionado;
  final TextEditingController horarioController;
  final FocusNode horarioFocusNode;
  final ValueChanged<bool> onMouseSobreHorarioChanged;
  final ValueChanged<String> onDigitarHorario;
  final void Function(int deltaMinutos) onAjustarMinutos;
  final ValueChanged<TimeOfDay> onHorarioSelecionado;

  const BlocoFrequenciaHorarioWidget({
    super.key,
    required this.theme,
    required this.modoProgramacao,
    required this.onModoProgramacaoChanged,
    required this.diasSemanaSelecionados,
    required this.onAlternarDiaSemana,
    required this.onDefinirDiasSemana,
    required this.mesCalendario,
    required this.onMesCalendarioChanged,
    required this.datasEspecificasSelecionadas,
    required this.onAlternarDataEspecifica,
    required this.horarioSelecionado,
    required this.horarioController,
    required this.horarioFocusNode,
    required this.onMouseSobreHorarioChanged,
    required this.onDigitarHorario,
    required this.onAjustarMinutos,
    required this.onHorarioSelecionado,
  });

  String _formatarHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _abrirSeletorHora(BuildContext context) async {
    final picked = await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DialogDigitarHorario(
        horarioInicial: horarioSelecionado,
        theme: theme,
      ),
    );
    if (picked != null) {
      onHorarioSelecionado(picked);
    }
  }

  Widget _abaFrequencia({
    required String label,
    required IconData icon,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor,
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                  color: theme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipDiaSemana({
    required int numero,
    required String label,
  }) {
    final ativo = diasSemanaSelecionados.contains(numero);
    return InkWell(
      onTap: () => onAlternarDiaSemana(numero),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ativo ? theme.textColor : theme.borderColor,
            width: ativo ? 1.6 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _atalhoDiaSemana({
    required String label,
    required List<int> dias,
  }) {
    final bateExatamente = diasSemanaSelecionados.length == dias.length &&
        dias.every((d) => diasSemanaSelecionados.contains(d));

    return InkWell(
      onTap: () => onDefinirDiasSemana(dias),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bateExatamente
              ? theme.textColor.withValues(alpha: 0.15)
              : theme.borderColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: bateExatamente ? theme.textColor : theme.borderColor,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: bateExatamente ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _botaoAjusteMinuto(int deltaMinutos, String label) {
    return InkWell(
      onTap: () => onAjustarMinutos(deltaMinutos),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _chipHorarioRapido(TimeOfDay hora) {
    final selecionado = horarioSelecionado.hour == hora.hour &&
        horarioSelecionado.minute == hora.minute;
    return InkWell(
      onTap: () => onHorarioSelecionado(hora),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor,
            width: selecionado ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          _formatarHora(hora),
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_repeat, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Frequência e Horário do Pedido',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _abaFrequencia(
                  label: 'Contrato / Dias da Semana',
                  icon: Icons.date_range,
                  selecionado: modoProgramacao == 'dias_semana',
                  onTap: () => onModoProgramacaoChanged('dias_semana'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _abaFrequencia(
                  label: 'Calendário de Datas',
                  icon: Icons.calendar_month,
                  selecionado: modoProgramacao == 'calendario',
                  onTap: () => onModoProgramacaoChanged('calendario'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (modoProgramacao == 'dias_semana') ...[
            Center(
              child: Text(
                'Selecione os dias em que o pedido deve ser produzido:',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chipDiaSemana(numero: 1, label: 'Seg'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 2, label: 'Ter'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 3, label: 'Qua'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 4, label: 'Qui'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 5, label: 'Sex'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 6, label: 'Sáb'),
                const SizedBox(width: 6),
                _chipDiaSemana(numero: 7, label: 'Dom'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _atalhoDiaSemana(label: 'Dias Úteis (Seg-Sex)', dias: [1, 2, 3, 4, 5]),
                const SizedBox(width: 6),
                _atalhoDiaSemana(label: 'Fim de Semana', dias: [6, 7]),
                const SizedBox(width: 6),
                _atalhoDiaSemana(label: 'Todos os Dias', dias: [1, 2, 3, 4, 5, 6, 7]),
              ],
            ),
          ] else ...[
            CalendarioProgramacaoWidget(
              theme: theme,
              mesCalendario: mesCalendario,
              datasSelecionadas: datasEspecificasSelecionadas,
              onMesAlterado: onMesCalendarioChanged,
              onDataAlternada: onAlternarDataEspecifica,
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${datasEspecificasSelecionadas.length} data(s) marcada(s) no calendário',
                style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: theme.borderColor.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horário de Entrega/Retirada:',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        MouseRegion(
                          onEnter: (_) => onMouseSobreHorarioChanged(true),
                          onExit: (_) => onMouseSobreHorarioChanged(false),
                          child: Listener(
                            onPointerSignal: (event) {},
                            child: Container(
                              width: 82,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.textColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: horarioFocusNode.hasFocus
                                      ? theme.textColor
                                      : theme.borderColor,
                                  width: horarioFocusNode.hasFocus ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: horarioController,
                                      focusNode: horarioFocusNode,
                                      cursorColor: theme.textColor,
                                      textAlign: TextAlign.center,
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        border: InputBorder.none,
                                      ),
                                      onTap: () {
                                        horarioController.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: horarioController.text.length,
                                        );
                                      },
                                      onChanged: onDigitarHorario,
                                      onSubmitted: (_) => horarioFocusNode.unfocus(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: theme.secondaryTextColor,
                                    tooltip: 'Abrir seletor de horário',
                                    onPressed: () => _abrirSeletorHora(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          _botaoAjusteMinuto(-1, '-1m'),
                          const SizedBox(width: 4),
                          _botaoAjusteMinuto(1, '+1m'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    _chipHorarioRapido(const TimeOfDay(hour: 11, minute: 30)),
                    _chipHorarioRapido(const TimeOfDay(hour: 12, minute: 0)),
                    _chipHorarioRapido(const TimeOfDay(hour: 12, minute: 30)),
                    _chipHorarioRapido(const TimeOfDay(hour: 18, minute: 0)),
                    _chipHorarioRapido(const TimeOfDay(hour: 19, minute: 30)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
