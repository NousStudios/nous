import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';

class DividaClienteWidget extends StatelessWidget {
  final AppTheme theme;
  final Cliente cliente;
  final double devido;
  final TextEditingController pagamentoController;
  final String? avisoPagamento;
  final VoidCallback onQuitarValor;
  final VoidCallback onQuitarTudo;

  const DividaClienteWidget({
    super.key,
    required this.theme,
    required this.cliente,
    required this.devido,
    required this.pagamentoController,
    required this.avisoPagamento,
    required this.onQuitarValor,
    required this.onQuitarTudo,
  });

  static String formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static Future<String?> confirmarAbateDivida({
    required BuildContext context,
    required AppTheme theme,
    required Cliente cliente,
    required double valorAbate,
    required double devido,
  }) async {
    final restante = (devido - valorAbate).clamp(0.0, double.infinity);
    String formaEscolhida = 'Dinheiro';
    const formas = [
      'Dinheiro',
      'Pix',
      'Cartão de Débito',
      'Cartão de Crédito',
      'Outro',
    ];

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Confirmar Quitação',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Deseja abater o valor abaixo da dívida de ${cliente.nome}?',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Valor a abater:',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                formatarMoeda(valorAbate),
                                style: theme.getTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dívida atual:',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                formatarMoeda(devido),
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo restante:',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                formatarMoeda(restante),
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: restante <= 0
                                      ? theme.textColor
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: theme.borderColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Forma recebida:',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: formaEscolhida,
                                  dropdownColor: theme.cardBackgroundColor,
                                  items: formas.map((f) {
                                    return DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f,
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (novo) {
                                    if (novo != null) {
                                      setModalState(
                                          () => formaEscolhida = novo);
                                    }
                                  },
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
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
                OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.borderColor.withValues(alpha: 0.18);
                      }
                      return theme.buttonColor != Colors.transparent
                          ? theme.buttonColor
                          : Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
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
                  ),
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(formaEscolhida),
                  child: Text(
                    'Confirmar Abate',
                    style: theme.getTextStyle(
                      color: theme.buttonColor != Colors.transparent
                          ? theme.buttonTextColor
                          : theme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _botao(String rotulo, VoidCallback aoPressionar,
      {bool destaque = false}) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return theme.borderColor.withValues(alpha: 0.18);
          }
          return (destaque && theme.buttonColor != Colors.transparent)
              ? theme.buttonColor
              : Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (destaque && theme.buttonColor != Colors.transparent) {
            return theme.buttonTextColor;
          }
          return theme.textColor;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return BorderSide(color: theme.textColor, width: 1.4);
          }
          return BorderSide(color: theme.borderColor, width: 1.0);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      onPressed: aoPressionar,
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 12,
          fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
          color: (destaque && theme.buttonColor != Colors.transparent)
              ? theme.buttonTextColor
              : theme.textColor,
        ),
      ),
    );
  }

  Widget _painelPagamento() {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: pagamentoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
          ],
          cursorColor: theme.textColor,
          style: theme.getTextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Valor (R\$)',
            hintStyle: theme.getTextStyle(
                fontSize: 12, color: theme.secondaryTextColor),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: borda(theme.borderColor),
            focusedBorder: borda(theme.textColor),
          ),
        ),
        if (avisoPagamento != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              avisoPagamento!,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 10),
            ),
          ),
        const SizedBox(height: 8),
        _botao('Quitar valor', onQuitarValor),
        const SizedBox(height: 6),
        _botao('Quitar tudo', onQuitarTudo, destaque: true),
      ],
    );
  }

  Widget _informacaoDivida(double valorDevido) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Valor em aberto', style: theme.getTextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          formatarMoeda(valorDevido),
          style: theme.getTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'A Prazo',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 400;
              if (!largo) {
                return Column(
                  children: [
                    _informacaoDivida(devido),
                    if (devido > 0) ...[
                      const SizedBox(height: 12),
                      SizedBox(width: 160, child: _painelPagamento()),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: devido > 0
                          ? SizedBox(width: 140, child: _painelPagamento())
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _informacaoDivida(devido),
                  const Expanded(child: SizedBox.shrink()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
