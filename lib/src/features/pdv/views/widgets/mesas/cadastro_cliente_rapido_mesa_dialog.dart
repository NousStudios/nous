import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';

/// Diálogo modal ágil para cadastro imediato de cliente durante o fechamento de conta
/// de mesa com modalidade À Prazo.
class CadastroClienteRapidoMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final String nomeInicial;
  final String numeroMesa;

  const CadastroClienteRapidoMesaDialog({
    super.key,
    required this.theme,
    required this.nomeInicial,
    required this.numeroMesa,
  });

  @override
  State<CadastroClienteRapidoMesaDialog> createState() =>
      _CadastroClienteRapidoMesaDialogState();
}

class _CadastroClienteRapidoMesaDialogState
    extends State<CadastroClienteRapidoMesaDialog> {
  late final TextEditingController _nomeController;
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do cliente.');
      return;
    }

    final cliente = Cliente(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      endereco: _enderecoController.text.trim(),
      telefone: _telefoneController.text.trim(),
    );

    Navigator.of(context).pop(cliente);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      color: theme.textColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cadastro Rápido de Cliente',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Venda à prazo na Mesa ${widget.numeroMesa}: informe os dados básicos do cliente para registro no sistema.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ThemedTextField(
                theme: theme,
                controller: _nomeController,
                label: 'Nome do Cliente',
                obrigatorio: true,
              ),
              const SizedBox(height: 12),
              ThemedTextField(
                theme: theme,
                controller: _enderecoController,
                label: 'Endereço (Rua, Número, Bairro)',
              ),
              const SizedBox(height: 12),
              ThemedTextField(
                theme: theme,
                controller: _telefoneController,
                label: 'Telefone / WhatsApp',
                tipoDeTeclado: TextInputType.phone,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(
                  _erro!,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Cancelar',
                      style: theme.getTextStyle(
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return theme.borderColor.withValues(alpha: 0.18);
                        }
                        return theme.buttonColor != Colors.transparent
                            ? theme.buttonColor
                            : Colors.transparent;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        return theme.buttonColor != Colors.transparent
                            ? theme.buttonTextColor
                            : theme.textColor;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return BorderSide(color: theme.textColor, width: 1.4);
                        }
                        return BorderSide(color: theme.borderColor, width: 1.0);
                      }),
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    onPressed: _confirmar,
                    child: Text(
                      'Cadastrar e Continuar',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonColor != Colors.transparent
                            ? theme.buttonTextColor
                            : theme.textColor,
                      ),
                    ),
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
