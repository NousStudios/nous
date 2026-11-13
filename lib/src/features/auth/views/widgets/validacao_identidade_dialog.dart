import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

/// Diálogo com Termo de Responsabilidade para validar a identidade de outro usuário Nous.
/// Exige que o validador digite exatamente "Compreendo e Aceito" para concluir.
class ValidacaoIdentidadeDialog {
  ValidacaoIdentidadeDialog._();

  static const String fraseConfirmacao = 'Compreendo e Aceito';

  static Future<UsuarioNous?> mostrar({
    required BuildContext context,
    required UsuarioNous alvo,
    required AppTheme theme,
  }) async {
    final ctrl = TextEditingController();
    bool processando = false;

    final resultado = await showDialog<UsuarioNous?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textoValido = ctrl.text.trim() == fraseConfirmacao;
            final cpfLimpo = alvo.cpf.replaceAll(RegExp(r'\D'), '');
            final cpfParcial = cpfLimpo.length >= 3
                ? '${cpfLimpo.substring(0, 3)}.***.***-**'
                : '***';

            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Validar Identidade',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alvo.nome.isNotEmpty
                                  ? alvo.nome
                                  : alvo.nomeExibicao,
                              style: theme.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CPF: $cpfParcial',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            if (alvo.localNascimento.isNotEmpty)
                              Text(
                                'Naturalidade: ${alvo.localNascimento}',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Termo de Responsabilidade',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ao validar esta identidade, você atesta pessoalmente que conhece este cidadão e confirma que os dados apresentados pertencem a uma pessoa real. '
                        'Seu nome, CPF e assinatura criptográfica ficarão registrados em ordem cronológica nesta conta como prova de confiança comunitária no Nous.',
                        textAlign: TextAlign.justify,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Digite "$fraseConfirmacao" abaixo para confirmar:',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ctrl,
                        enabled: !processando,
                        onChanged: (_) => setModalState(() {}),
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.backgroundColor,
                          hintText: fraseConfirmacao,
                          hintStyle: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor
                                .withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.textColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: processando ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: (!textoValido || processando)
                      ? null
                      : () async {
                          setModalState(() => processando = true);
                          final atualizado = await context
                              .read<AuthProvider>()
                              .validarIdentidadeUsuario(alvo);
                          if (ctx.mounted) {
                            Navigator.pop(ctx, atualizado);
                          }
                        },
                  child: processando
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.buttonTextColor,
                          ),
                        )
                      : Text(
                          'Confirmar Validação',
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    ctrl.dispose();
    return resultado;
  }
}
