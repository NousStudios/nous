import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/services/voz_busca_service.dart';

/// Diálogo centralizado com layout circular animado que indica ao usuário
/// que o aplicativo está ouvindo e permite cancelar ou enviar para transcrever.
class DialogEscutaVozMapa extends StatefulWidget {
  final AppTheme theme;

  const DialogEscutaVozMapa({
    super.key,
    required this.theme,
  });

  static Future<ResultadoVozBusca?> mostrar(
    BuildContext context, {
    required AppTheme theme,
  }) {
    return showDialog<ResultadoVozBusca>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogEscutaVozMapa(theme: theme),
    );
  }

  @override
  State<DialogEscutaVozMapa> createState() => _DialogEscutaVozMapaState();
}

class _DialogEscutaVozMapaState extends State<DialogEscutaVozMapa>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulsoCtrl;
  Timer? _cronometro;
  int _segundos = 0;
  bool _iniciando = true;
  bool _transcrevendo = false;
  bool _encerrado = false;

  @override
  void initState() {
    super.initState();
    _pulsoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    unawaited(_iniciar());
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _pulsoCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final erro = await VozBuscaService.iniciarGravacaoWindows();
    if (!mounted || _encerrado) return;
    if (erro != null) {
      _encerrado = true;
      Navigator.of(context).pop(ResultadoVozBusca(mensagemErro: erro));
      return;
    }

    setState(() => _iniciando = false);
    _cronometro = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _transcrevendo || _encerrado) {
        t.cancel();
        return;
      }
      setState(() => _segundos++);
      if (_segundos >= 15) {
        t.cancel();
        unawaited(_enviar());
      }
    });
  }

  Future<void> _enviar() async {
    if (_iniciando || _transcrevendo || _encerrado) return;
    _cronometro?.cancel();
    _pulsoCtrl.stop();
    setState(() => _transcrevendo = true);

    final res = await VozBuscaService.pararETranscreverWindows();
    if (!mounted || _encerrado) return;
    _encerrado = true;
    Navigator.of(context).pop(res);
  }

  void _cancelar() {
    if (_encerrado) return;
    _encerrado = true;
    _cronometro?.cancel();
    VozBuscaService.cancelarEscutaAtiva();
    Navigator.of(context).pop(const ResultadoVozBusca(cancelado: true));
  }

  String _formatarTempo(int seg) {
    final mm = (seg ~/ 60).toString().padLeft(2, '0');
    final ss = (seg % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _transcrevendo
                    ? 'Transcrevendo fala...'
                    : (_iniciando ? 'Abrindo microfone...' : 'Estou ouvindo'),
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _pulsoCtrl,
                builder: (context, _) {
                  final escala = _transcrevendo
                      ? 1.0
                      : (1.0 + _pulsoCtrl.value * 0.16);
                  return SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: escala,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_transcrevendo
                                      ? theme.buttonColor
                                      : theme.dangerColor)
                                  .withValues(alpha: 0.14),
                              border: Border.all(
                                color: (_transcrevendo
                                        ? theme.buttonColor
                                        : theme.dangerColor)
                                    .withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _transcrevendo
                                ? theme.buttonColor
                                : theme.dangerColor,
                            boxShadow: [
                              BoxShadow(
                                color: (_transcrevendo
                                        ? theme.buttonColor
                                        : theme.dangerColor)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _transcrevendo
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.8,
                                    color: theme.buttonTextColor,
                                  ),
                                )
                              : Icon(
                                  Icons.mic_rounded,
                                  size: 36,
                                  color: theme.buttonTextColor,
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                _transcrevendo
                    ? 'Processando em Português...'
                    : 'Fale o que deseja buscar (${_formatarTempo(_segundos)})',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _transcrevendo ? null : _cancelar,
                    child: Text(
                      'Cancelar',
                      style: theme.getTextStyle(
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_iniciando || _transcrevendo) ? null : _enviar,
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: const Text('Enviar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
