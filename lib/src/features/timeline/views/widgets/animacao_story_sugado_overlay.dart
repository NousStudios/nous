import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Exibe uma animação estilo Instagram onde o card do novo story é "sugado"
/// em direção à foto de perfil do usuário após a publicação.
class AnimacaoStorySugadoOverlay {
  AnimacaoStorySugadoOverlay._();

  static void disparar(
    OverlayState? overlay, {
    required AppTheme theme,
    String caminhoMidiaLocal = '',
    String fotoPerfil = '',
  }) {
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _StorySugadoWidget(
        theme: theme,
        caminhoMidiaLocal: caminhoMidiaLocal,
        fotoPerfil: fotoPerfil,
        onFinalizado: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _StorySugadoWidget extends StatefulWidget {
  final AppTheme theme;
  final String caminhoMidiaLocal;
  final String fotoPerfil;
  final VoidCallback onFinalizado;

  const _StorySugadoWidget({
    required this.theme,
    required this.caminhoMidiaLocal,
    required this.fotoPerfil,
    required this.onFinalizado,
  });

  @override
  State<_StorySugadoWidget> createState() => _StorySugadoWidgetState();
}

class _StorySugadoWidgetState extends State<_StorySugadoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progresso;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _progresso = CurvedAnimation(parent: _ctrl, curve: Curves.easeInBack);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinalizado();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fotoResolvida = ImagemService.resolverCaminhoExistente(
      widget.fotoPerfil,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _progresso,
        builder: (_, _) {
          final t = _progresso.value.clamp(0.0, 1.0);
          final escala = 1.0 - (0.86 * t);
          final opacidade = (1.0 - (t * 0.85)).clamp(0.0, 1.0);
          final dy = -size.height * 0.34 * t;
          final dx = -size.width * 0.08 * t;

          return Opacity(
            opacity: opacidade,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: escala,
                child: Center(
                  child: Container(
                    width: 170,
                    height: 270,
                    decoration: BoxDecoration(
                      color: widget.theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(24 + (60 * t)),
                      border: Border.all(
                        color: widget.theme.buttonColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.buttonColor
                              .withValues(alpha: 0.35),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.caminhoMidiaLocal.isNotEmpty &&
                            File(widget.caminhoMidiaLocal).existsSync()
                        ? Image.file(
                            File(widget.caminhoMidiaLocal),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: widget.theme.buttonColor
                                  .withValues(alpha: 0.2),
                              backgroundImage: fotoResolvida != null
                                  ? FileImage(File(fotoResolvida))
                                  : null,
                              child: fotoResolvida == null
                                  ? Icon(
                                      Icons.auto_awesome,
                                      color: widget.theme.buttonColor,
                                      size: 30,
                                    )
                                  : null,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
