import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'detalhes_acao_dialog.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// Tile com suporte a hover para exibir uma ação individual na lista de auditoria.
class BarraAcaoWidget extends StatefulWidget {
  final AppTheme theme;
  final RegistroAcao acao;
  final VoidCallback onTap;

  const BarraAcaoWidget({
    super.key,
    required this.theme,
    required this.acao,
    required this.onTap,
  });

  @override
  State<BarraAcaoWidget> createState() => _BarraAcaoWidgetState();
}

class _BarraAcaoWidgetState extends State<BarraAcaoWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final acao = widget.acao;
    final autorPartes = <String>[
      if (acao.nomeAutor.isNotEmpty) acao.nomeAutor,
      if (acao.cpfAutor.isNotEmpty) formatarCpfAuditoria(acao.cpfAutor),
      if (acao.emailAutor.isNotEmpty) acao.emailAutor,
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: acao.descricao,
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dataHoraCurta(acao.dataHora),
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    if (autorPartes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextoRolante(
                        texto: 'por ${autorPartes.join(' • ')}',
                        textAlign: TextAlign.start,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
