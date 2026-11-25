import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class BarraEmailUsuario extends StatefulWidget {
  final AppTheme theme;
  final String email;
  final bool verificadoGoogle;
  final VoidCallback aoClicar;
  final VoidCallback aoExcluir;

  const BarraEmailUsuario({
    super.key,
    required this.theme,
    required this.email,
    required this.verificadoGoogle,
    required this.aoClicar,
    required this.aoExcluir,
  });

  @override
  State<BarraEmailUsuario> createState() => _BarraEmailUsuarioState();
}

class _BarraEmailUsuarioState extends State<BarraEmailUsuario> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline, size: 20, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    if (!widget.verificadoGoogle)
                      Text(
                        'Requer autenticação Google',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.verificadoGoogle)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.borderColor),
                ),
                onSelected: (valor) {
                  if (valor == 'excluir') widget.aoExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text(
                      'Excluir e-mail',
                      style: theme.getTextStyle(color: theme.dangerColor),
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
