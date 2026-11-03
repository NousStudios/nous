import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme_controller.dart';

/// Formatador de texto com auto-preenchimento e máscara HH:mm para inserção de horários.
class HorarioInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String textoNovo = newValue.text;
    if (oldValue.text.endsWith(':') && textoNovo.length < oldValue.text.length) {
      final digitosAntigos = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitosAntigos.isNotEmpty) {
        textoNovo = digitosAntigos.substring(0, digitosAntigos.length - 1);
      }
    }

    final digitos = textoNovo.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 4 ? digitos.substring(0, 4) : digitos;

    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2) buffer.write(':');
      buffer.write(limitado[i]);
    }

    var formatado = buffer.toString();
    if (limitado.length == 2 && newValue.text.length > oldValue.text.length) {
      formatado = '$formatado:';
    }

    var digitosAntesCursor = 0;
    final fimSelecao = newValue.selection.end.clamp(0, newValue.text.length);
    for (var i = 0; i < fimSelecao; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        digitosAntesCursor++;
      }
    }
    if (digitosAntesCursor > 4) digitosAntesCursor = 4;

    var novoOffset = digitosAntesCursor;
    if (digitosAntesCursor >= 2 && formatado.contains(':')) {
      novoOffset = digitosAntesCursor + 1;
    }
    if (novoOffset > formatado.length) {
      novoOffset = formatado.length;
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: novoOffset),
    );
  }
}

/// Diálogo modal interativo para digitar ou ajustar horários com scroll do mouse e atalhos rápidos.
class DialogDigitarHorario extends StatefulWidget {
  final TimeOfDay horarioInicial;
  final AppTheme theme;

  const DialogDigitarHorario({
    super.key,
    required this.horarioInicial,
    required this.theme,
  });

  static Future<TimeOfDay?> mostrar(
    BuildContext context, {
    required TimeOfDay horarioInicial,
    required AppTheme theme,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => DialogDigitarHorario(
        horarioInicial: horarioInicial,
        theme: theme,
      ),
    );
  }

  @override
  State<DialogDigitarHorario> createState() => _DialogDigitarHorarioState();
}

class _DialogDigitarHorarioState extends State<DialogDigitarHorario> {
  late TimeOfDay _horario;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _horario = widget.horarioInicial;
    _controller = TextEditingController(text: _formatarHora(_horario));
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatarHora(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _sincronizarDoTexto() {
    final partes = _controller.text.trim().split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        _horario = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  void _ajustarMinutos(int delta) {
    _sincronizarDoTexto();
    var novoMinuto = _horario.minute + delta;
    var novaHora = _horario.hour;
    if (novoMinuto >= 60) {
      novoMinuto = novoMinuto - 60;
      novaHora = (novaHora + 1) % 24;
    } else if (novoMinuto < 0) {
      novoMinuto = novoMinuto + 60;
      novaHora = (novaHora - 1 + 24) % 24;
    }
    setState(() {
      _horario = TimeOfDay(hour: novaHora, minute: novoMinuto);
      _controller.text = _formatarHora(_horario);
    });
  }

  void _aoDigitar(String valor) {
    final partes = valor.trim().split(':');
    if (partes.length == 2 && partes[0].length == 2 && partes[1].length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        setState(() {
          _horario = TimeOfDay(hour: h, minute: m);
        });
      }
    }
  }

  void _salvar() {
    _sincronizarDoTexto();
    Navigator.of(context).pop(_horario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy < 0) {
                _ajustarMinutos(1);
              } else if (pointerSignal.scrollDelta.dy > 0) {
                _ajustarMinutos(-1);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time_filled, color: theme.textColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Digite o Horário',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Digite o horário ou role a rodinha do mouse neste painel para subir ou descer os números.',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.7),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: theme.textColor,
                            tooltip: 'Diminuir 1 minuto',
                            onPressed: () => _ajustarMinutos(-1),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              cursorColor: theme.textColor,
                              inputFormatters: [HorarioInputFormatter()],
                              style: theme.getTextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                              ),
                              onTap: () {
                                _controller.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _controller.text.length,
                                );
                              },
                              onChanged: _aoDigitar,
                              onSubmitted: (_) => _salvar(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: theme.textColor,
                            tooltip: 'Aumentar 1 minuto',
                            onPressed: () => _ajustarMinutos(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chipAjuste(theme, -10, '-10m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, -5, '-5m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, 5, '+5m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, 10, '+10m'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _chipSugerido(theme, const TimeOfDay(hour: 11, minute: 30)),
                    _chipSugerido(theme, const TimeOfDay(hour: 12, minute: 0)),
                    _chipSugerido(theme, const TimeOfDay(hour: 12, minute: 30)),
                    _chipSugerido(theme, const TimeOfDay(hour: 18, minute: 0)),
                    _chipSugerido(theme, const TimeOfDay(hour: 19, minute: 30)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          'Salvar',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        onPressed: _salvar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipAjuste(AppTheme theme, int delta, String label) {
    return InkWell(
      onTap: () => _ajustarMinutos(delta),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _chipSugerido(AppTheme theme, TimeOfDay hora) {
    final selecionado = _horario.hour == hora.hour && _horario.minute == hora.minute;
    return InkWell(
      onTap: () {
        setState(() {
          _horario = hora;
          _controller.text = _formatarHora(hora);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.22)
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
            fontSize: 11,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
}
