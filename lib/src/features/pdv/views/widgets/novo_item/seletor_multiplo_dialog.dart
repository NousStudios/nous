import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class SeletorMultiploDialog {
  static void mostrar({
    required BuildContext context,
    required AppTheme theme,
    required String titulo,
    required Map<String, String> opcoes,
    Map<String, String>? fotos,
    required Set<String> selecionados,
    required VoidCallback onCriarNovo,
    String? textoCriarNovo,
    required VoidCallback onAlterado,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                titulo,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          onCriarNovo();
                          setDialogState(() {});
                        },
                        icon: Icon(Icons.add, size: 16, color: theme.textColor),
                        label: Text(
                          textoCriarNovo ?? 'Criar novo',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (opcoes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma opção cadastrada ainda.\nClique acima para criar.',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        )
                      else
                        ...opcoes.entries.map((entrada) {
                          final foto = fotos?[entrada.key] ?? '';
                          final fotoResolvida =
                              ImagemService.resolverCaminhoExistente(foto);
                          final temFoto = fotoResolvida != null;
                          return CheckboxListTile(
                            value: selecionados.contains(entrada.key),
                            secondary: temFoto
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      File(fotoResolvida),
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            title: TextoRolante(
                              texto: entrada.value,
                              textAlign: TextAlign.start,
                              style: theme.getTextStyle(fontSize: 14),
                            ),
                            activeColor: theme.buttonColor,
                            checkColor: theme.buttonTextColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (marcado) {
                              setDialogState(() {
                                if (marcado == true) {
                                  selecionados.add(entrada.key);
                                } else {
                                  selecionados.remove(entrada.key);
                                }
                              });
                              onAlterado();
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Concluir',
                    style: theme.getTextStyle(color: theme.textColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
