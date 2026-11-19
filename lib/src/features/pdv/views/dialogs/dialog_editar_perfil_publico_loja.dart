import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Diálogo modular para membros com permissão editarem a apresentação pública
/// da loja (biografia, links e cores do perfil público).
class DialogEditarPerfilPublicoLoja extends StatefulWidget {
  final AppTheme theme;
  final Loja loja;

  const DialogEditarPerfilPublicoLoja({
    super.key,
    required this.theme,
    required this.loja,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required Loja loja,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogEditarPerfilPublicoLoja(theme: theme, loja: loja),
    );
  }

  @override
  State<DialogEditarPerfilPublicoLoja> createState() =>
      _DialogEditarPerfilPublicoLojaState();
}

class _DialogEditarPerfilPublicoLojaState
    extends State<DialogEditarPerfilPublicoLoja> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _linksCtrl;
  late String _corFundoHex;
  late String _corDestaqueHex;
  bool _salvando = false;

  static const List<String> _paletaFundos = [
    '',
    '#121214',
    '#1A1D24',
    '#1E2923',
    '#241B1E',
    '#F5F5F7',
    '#FAF6F0',
  ];

  static const List<String> _paletaDestaques = [
    '',
    '#2E7D32',
    '#1D9BF0',
    '#E65100',
    '#8E24AA',
    '#C62828',
    '#00838F',
  ];

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.loja.biografiaPublica);
    _linksCtrl = TextEditingController(
      text: widget.loja.linksPublicos.join('\n'),
    );
    _corFundoHex = widget.loja.corFundoPerfilHex;
    _corDestaqueHex = widget.loja.corDestaquePerfilHex;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _linksCtrl.dispose();
    super.dispose();
  }

  Color _parseHex(String hex, Color fallback) {
    if (hex.isEmpty) return fallback;
    final limpo = hex.replaceAll('#', '').trim();
    final val = int.tryParse(limpo, radix: 16);
    if (val == null) return fallback;
    return Color(limpo.length == 6 ? (0xFF000000 | val) : val);
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final links = _linksCtrl.text
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final atualizada = widget.loja.copyWith(
      biografiaPublica: _bioCtrl.text.trim(),
      linksPublicos: links,
      corFundoPerfilHex: _corFundoHex,
      corDestaquePerfilHex: _corDestaqueHex,
    );
    await context.read<PdvProvider>().adicionarOuAtualizarLoja(atualizada);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Editar Perfil da Loja',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 14),
              ThemedTextField(
                theme: theme,
                controller: _bioCtrl,
                label: 'Biografia / Apresentação da loja',
                linhas: 3,
              ),
              const SizedBox(height: 12),
              ThemedTextField(
                theme: theme,
                controller: _linksCtrl,
                label: 'Links exibidos (um por linha)',
                linhas: 3,
              ),
              const SizedBox(height: 14),
              Text(
                'Cor de fundo da vitrine',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paletaFundos.map((hex) {
                  final sel = _corFundoHex == hex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _corFundoHex = hex),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hex.isEmpty
                            ? theme.backgroundColor
                            : _parseHex(hex, theme.backgroundColor),
                        border: Border.all(
                          color: sel ? theme.buttonColor : theme.borderColor,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      child: hex.isEmpty
                          ? Icon(
                              Icons.auto_fix_normal,
                              size: 14,
                              color: theme.secondaryTextColor,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'Cor de destaque da loja',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paletaDestaques.map((hex) {
                  final sel = _corDestaqueHex == hex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _corDestaqueHex = hex),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hex.isEmpty
                            ? theme.buttonColor
                            : _parseHex(hex, theme.buttonColor),
                        border: Border.all(
                          color: sel ? theme.textColor : theme.borderColor,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                      child: hex.isEmpty
                          ? Icon(
                              Icons.auto_fix_normal,
                              size: 14,
                              color: theme.buttonTextColor,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: theme.getTextStyle(color: theme.secondaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                    ),
                    onPressed: _salvando ? null : _salvar,
                    child: const Text('Salvar'),
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
