import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

/// Diálogo centralizado para escrever, editar ou remover a nota de pensamento
/// de 24h exibida na nuvem acima do avatar na tela Mensagens.
class DialogNotaPensamento extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final String fraseSugerida;

  const DialogNotaPensamento({
    super.key,
    required this.theme,
    required this.usuario,
    required this.fraseSugerida,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous usuario,
    required String fraseSugerida,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogNotaPensamento(
        theme: theme,
        usuario: usuario,
        fraseSugerida: fraseSugerida,
      ),
    );
  }

  @override
  State<DialogNotaPensamento> createState() => _DialogNotaPensamentoState();
}

class _DialogNotaPensamentoState extends State<DialogNotaPensamento> {
  late final TextEditingController _ctrl;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.usuario.temNotaPensamentoAtiva
          ? widget.usuario.notaPensamento
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _salvar(String texto) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    await context.read<AuthProvider>().atualizarNotaPensamento(texto);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final temAtiva = widget.usuario.temNotaPensamentoAtiva;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 20,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seu pensamento (24h)',
                        style: theme.getTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Fica visível para seus contatos na barra de mensagens por 24 horas.',
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ctrl,
                  maxLength: 60,
                  maxLines: 2,
                  autofocus: true,
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.fraseSugerida,
                    hintStyle: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor.withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.buttonColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adicionar música (em breve)',
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (temAtiva)
                      TextButton(
                        onPressed: _salvando ? null : () => _salvar(''),
                        child: Text(
                          'Remover',
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            color: theme.dangerColor,
                          ),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          _salvando ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvando ? null : () => _salvar(_ctrl.text),
                      child: Text(
                        _salvando ? 'Salvando...' : 'Compartilhar',
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: theme.buttonTextColor,
                        ),
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
}
