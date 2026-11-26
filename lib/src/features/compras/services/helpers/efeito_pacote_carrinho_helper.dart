import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class EfeitoPacoteCarrinhoHelper {
  EfeitoPacoteCarrinhoHelper._();

  /// Chave global opcional registrada no primeiro ícone (slot 0) da FloatingBottomNavBar
  /// para que o pacote voe exatamente até a posição real do ícone na tela.
  static GlobalKey? chaveSlotCompras;

  /// Executa a animação da janela/card do item se "empacotando" (fechando em formato de pacote)
  /// e voando em arco suave até o primeiro ícone da barra de navegação universal ("Compras e Carteira").
  static void dispararAnimacaoPacote({
    required BuildContext context,
    required Offset origemGlobal,
    required AppTheme theme,
    String? fotoUrl,
    String? nomeItem,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final media = MediaQuery.sizeOf(context);
    Offset destinoGlobal = Offset(
      media.width > 600 ? (media.width / 2 - 200) : 52,
      media.height - 46,
    );

    // Se a FloatingBottomNavBar estiver montada, usa a posição exata do slot 0
    final boxAlvo =
        chaveSlotCompras?.currentContext?.findRenderObject() as RenderBox?;
    if (boxAlvo != null && boxAlvo.hasSize) {
      final pos = boxAlvo.localToGlobal(
        Offset(boxAlvo.size.width / 2, boxAlvo.size.height / 2),
      );
      if (pos.dx > 0 && pos.dy > 0) {
        destinoGlobal = pos;
      }
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AnimacaoPacoteVoando(
        origem: origemGlobal,
        destino: destinoGlobal,
        theme: theme,
        fotoUrl: fotoUrl,
        aoConcluir: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _AnimacaoPacoteVoando extends StatefulWidget {
  final Offset origem;
  final Offset destino;
  final AppTheme theme;
  final String? fotoUrl;
  final VoidCallback aoConcluir;

  const _AnimacaoPacoteVoando({
    required this.origem,
    required this.destino,
    required this.theme,
    this.fotoUrl,
    required this.aoConcluir,
  });

  @override
  State<_AnimacaoPacoteVoando> createState() => _AnimacaoPacoteVoandoState();
}

class _AnimacaoPacoteVoandoState extends State<_AnimacaoPacoteVoando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressoVoo;
  late final Animation<double> _escala;
  late final Animation<double> _rotacao;
  late final Animation<double> _opacidade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    // Fase 1 (0..25%): card se "empacota" (encolhe e gira levemente no lugar)
    // Fase 2 (25..100%): pacote voa em arco até o ícone Compras e Carteira
    _progressoVoo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 1.0, curve: Curves.easeInOutCubic),
    );

    _escala = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.22)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_controller);

    _rotacao = Tween<double>(begin: 0.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 1.0, curve: Curves.easeInOut),
      ),
    );

    _opacidade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.aoConcluir();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final temFoto = widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _progressoVoo.value;
        final dx = widget.origem.dx + (widget.destino.dx - widget.origem.dx) * t;
        final dyLinear =
            widget.origem.dy + (widget.destino.dy - widget.origem.dy) * t;
        final arco = -72 * (4 * t * (1 - t));
        final dy = dyLinear + arco;
        final empacotado = _controller.value > 0.22;

        return Positioned(
          left: dx - 28,
          top: dy - 28,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacidade.value,
              child: Transform.rotate(
                angle: _rotacao.value,
                child: Transform.scale(
                  scale: _escala.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: empacotado
                          ? theme.buttonColor
                          : theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(empacotado ? 14 : 10),
                      border: Border.all(
                        color: theme.borderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.textColor.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: !empacotado && temFoto
                        ? ImagemService.construirImagem(
                            widget.fotoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: theme.buttonTextColor,
                              size: 28,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
