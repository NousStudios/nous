import 'package:flutter/material.dart';

/// Widget que exibe um texto e, caso o texto ultrapasse a largura disponível,
/// aplica um efeito de esmaecimento suave nas bordas e desliza lentamente da direita
/// para a esquerda (efeito Marquee), permitindo ao usuário ler o texto completo.
class TextoRolante extends StatefulWidget {
  final String texto;
  final TextStyle style;
  final TextAlign textAlign;
  final double velocidadePxPorSegundo;
  final Duration pausaBordas;

  const TextoRolante({
    super.key,
    required this.texto,
    required this.style,
    this.textAlign = TextAlign.center,
    this.velocidadePxPorSegundo = 28.0,
    this.pausaBordas = const Duration(milliseconds: 1400),
  });

  @override
  State<TextoRolante> createState() => _TextoRolanteState();
}

class _TextoRolanteState extends State<TextoRolante> {
  late final ScrollController _scrollController;
  bool _animando = false;
  int _cicloId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant TextoRolante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texto != widget.texto ||
        oldWidget.style != widget.style ||
        oldWidget.velocidadePxPorSegundo != widget.velocidadePxPorSegundo) {
      _cicloId++;
      _animando = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _cicloId++;
    _scrollController.dispose();
    super.dispose();
  }

  void _iniciarAnimacaoSeNecessario(double maxScroll) {
    if (_animando || maxScroll <= 0) return;
    _animando = true;
    final cicloAtual = ++_cicloId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted && cicloAtual == _cicloId) {
        // Pausa no início para o usuário ler o começo
        await Future.delayed(widget.pausaBordas);
        if (!mounted || cicloAtual != _cicloId || !_scrollController.hasClients) break;

        final currentMax = _scrollController.position.maxScrollExtent;
        if (currentMax <= 0) break;

        final duracaoIda = Duration(
          milliseconds: ((currentMax / widget.velocidadePxPorSegundo) * 1000).toInt(),
        );

        // Desliza lentamente da direita para a esquerda
        await _scrollController.animateTo(
          currentMax,
          duration: duracaoIda,
          curve: Curves.linear,
        );

        if (!mounted || cicloAtual != _cicloId || !_scrollController.hasClients) break;

        // Pausa no final para ler o término
        await Future.delayed(widget.pausaBordas);
        if (!mounted || cicloAtual != _cicloId || !_scrollController.hasClients) break;

        // Retorna suavemente para o início
        final duracaoVolta = Duration(
          milliseconds: ((currentMax / (widget.velocidadePxPorSegundo * 1.5)) * 1000).toInt().clamp(400, 1500),
        );

        await _scrollController.animateTo(
          0.0,
          duration: duracaoVolta,
          curve: Curves.easeInOut,
        );
      }
      _animando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.texto, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        )..layout();

        final textWidth = textPainter.size.width;
        final maxWidth = constraints.maxWidth;

        // Se o texto couber completamente, exibe sem animação ou máscara
        if (maxWidth.isFinite && textWidth <= maxWidth) {
          return SizedBox(
            width: double.infinity,
            child: Text(
              widget.texto,
              style: widget.style,
              textAlign: widget.textAlign,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          );
        }

        final maxScroll = (textWidth - maxWidth).clamp(0.0, double.infinity);
        if (maxScroll > 0) {
          _iniciarAnimacaoSeNecessario(maxScroll);
        }

        return ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.92, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                widget.texto,
                style: widget.style,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
