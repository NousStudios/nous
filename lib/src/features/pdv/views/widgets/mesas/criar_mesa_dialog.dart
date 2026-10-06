import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';

class CriarMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja? mesaExistente;
  final ValueChanged<MesaLoja> aoSalvar;
  final VoidCallback? aoExcluir;

  const CriarMesaDialog({
    super.key,
    required this.theme,
    this.mesaExistente,
    required this.aoSalvar,
    this.aoExcluir,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    MesaLoja? mesaExistente,
    required ValueChanged<MesaLoja> aoSalvar,
    VoidCallback? aoExcluir,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: CriarMesaDialog(
              theme: theme,
              mesaExistente: mesaExistente,
              aoSalvar: (mesa) {
                Navigator.of(dialogContext).pop();
                aoSalvar(mesa);
              },
              aoExcluir: aoExcluir == null
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      aoExcluir();
                    },
            ),
          ),
        );
      },
    );
  }

  @override
  State<CriarMesaDialog> createState() => _CriarMesaDialogState();
}

class _CriarMesaDialogState extends State<CriarMesaDialog> {
  late final TextEditingController _numeroController;
  late final TextEditingController _descricaoController;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _numeroController =
        TextEditingController(text: widget.mesaExistente?.numero ?? '');
    _descricaoController =
        TextEditingController(text: widget.mesaExistente?.descricao ?? '');
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _submeter() {
    final numero = _numeroController.text.trim();
    if (numero.isEmpty) {
      setState(() => _erro = 'Informe a identificação da mesa (ex: 01, Balcão 2).');
      return;
    }

    final mesa = widget.mesaExistente != null
        ? widget.mesaExistente!.copyWith(
            numero: numero,
            descricao: _descricaoController.text.trim(),
          )
        : MesaLoja(
            id: gerarIdUnico(),
            numero: numero,
            descricao: _descricaoController.text.trim(),
          );

    widget.aoSalvar(mesa);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.mesaExistente != null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  isEdicao ? 'Editar Mesa' : 'Nova Mesa',
                  textAlign: TextAlign.center,
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          ThemedTextField(
            theme: widget.theme,
            controller: _numeroController,
            label: 'Identificação da Mesa (ex: 01, VIP, Balcão 1) *',
            obrigatorio: true,
          ),
          const SizedBox(height: 12),
          ThemedTextField(
            theme: widget.theme,
            controller: _descricaoController,
            label: 'Descrição / Localização (ex: Salão, Varanda)',
          ),
          if (_erro.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _erro,
              textAlign: TextAlign.center,
              style: widget.theme.getTextStyle(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (isEdicao && widget.aoExcluir != null) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.aoExcluir,
                    child: Text(
                      'Excluir',
                      style: widget.theme.getTextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: widget.theme.buttonColor,
                    foregroundColor: widget.theme.buttonTextColor,
                    side: BorderSide(color: widget.theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submeter,
                  child: Text(
                    isEdicao ? 'Salvar' : 'Criar Mesa',
                    style: widget.theme.getTextStyle(
                      fontSize: 14,
                      color: widget.theme.buttonTextColor,
                    ),
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
