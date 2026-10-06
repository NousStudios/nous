import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class EditarDescricaoDialog extends StatefulWidget {
  final AppTheme theme;
  final String nomeArquivo;
  final String descricaoInicial;
  final ValueChanged<String> onSalvar;

  const EditarDescricaoDialog({
    super.key,
    required this.theme,
    required this.nomeArquivo,
    required this.descricaoInicial,
    required this.onSalvar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String nomeArquivo,
    required String descricaoInicial,
    required ValueChanged<String> onSalvar,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => EditarDescricaoDialog(
        theme: theme,
        nomeArquivo: nomeArquivo,
        descricaoInicial: descricaoInicial,
        onSalvar: onSalvar,
      ),
    );
  }

  @override
  State<EditarDescricaoDialog> createState() => _EditarDescricaoDialogState();
}

class _EditarDescricaoDialogState extends State<EditarDescricaoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.descricaoInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvar() {
    widget.onSalvar(_controller.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: theme.textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Descrição do Arquivo',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textColor, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.nomeArquivo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    autofocus: true,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                    cursorColor: theme.textColor,
                    decoration: InputDecoration(
                      hintText: 'Adicione uma legenda ou descrição para este arquivo...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        side: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 0,
                      ),
                      onPressed: _salvar,
                      child: Text(
                        'Salvar Descrição',
                        style: theme.getTextStyle(
                          fontSize: 13,
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
