import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

class DialogDenunciaSocial extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous denunciante;
  final String alvoCpf;
  final String alvoNome;
  final String publicacaoId;

  const DialogDenunciaSocial({
    super.key,
    required this.theme,
    required this.denunciante,
    required this.alvoCpf,
    required this.alvoNome,
    this.publicacaoId = '',
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous denunciante,
    required String alvoCpf,
    required String alvoNome,
    String publicacaoId = '',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DialogDenunciaSocial(
        theme: theme,
        denunciante: denunciante,
        alvoCpf: alvoCpf,
        alvoNome: alvoNome,
        publicacaoId: publicacaoId,
      ),
    );
  }

  @override
  State<DialogDenunciaSocial> createState() => _DialogDenunciaSocialState();
}

class _DialogDenunciaSocialState extends State<DialogDenunciaSocial> {
  final TextEditingController _motivoCtrl = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      setState(() => _erro = 'Descreva o motivo da denúncia.');
      return;
    }
    setState(() => _enviando = true);
    await TimelineService.registrarDenuncia(
      denuncianteCpf: widget.denunciante.cpf,
      denuncianteNome: widget.denunciante.nomeExibicao,
      alvoCpf: widget.alvoCpf,
      alvoNome: widget.alvoNome,
      publicacaoId: widget.publicacaoId,
      motivo: motivo,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar Denúncia',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.publicacaoId.isNotEmpty
                    ? 'Denunciar publicação de ${widget.alvoNome}'
                    : 'Denunciar perfil de ${widget.alvoNome}',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 14),
              ThemedTextField(
                theme: theme,
                controller: _motivoCtrl,
                linhas: 3,
                label: 'Motivo da denúncia',
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.dangerColor,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.dangerColor,
                  foregroundColor: theme.buttonTextColor,
                ),
                onPressed: _enviando ? null : _enviar,
                child: Text(_enviando ? 'Enviando...' : 'Enviar Denúncia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
