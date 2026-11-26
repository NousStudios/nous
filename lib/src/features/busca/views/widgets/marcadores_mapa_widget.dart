import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class MarcadoresMapaWidget {
  MarcadoresMapaWidget._();

  static List<Marker> construir({
    required BuscaMapaController controller,
    required AppTheme theme,
    UsuarioNous? usuarioLogado,
  }) {
    final marcadores = <Marker>[];
    final meuCpfNorm =
        (usuarioLogado?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfsOnline = ClienteRedeLocal()
        .presencasAtivas
        .value
        .map((p) => (p.cpf ?? '').replaceAll(RegExp(r'\D'), ''))
        .where((c) => c.length == 11)
        .toSet();

    // 1. Outros usuários: somente se estiverem Online E compartilhando localização em tempo real
    for (final usuario in controller.usuarios) {
      final cpfNorm = usuario.cpf.replaceAll(RegExp(r'\D'), '');
      if (cpfNorm == meuCpfNorm) continue;
      if (!cpfsOnline.contains(cpfNorm)) continue;
      final coord = controller.coordenadasUsuariosTempoReal[cpfNorm];
      if (coord == null) continue;
      final selecionado = controller.perfilSelecionado?.cpf == usuario.cpf;
      final fotoResolvida =
          ImagemService.resolverCaminhoExistente(usuario.fotoExibicao);
      final temFoto = fotoResolvida != null;

      marcadores.add(
        Marker(
          point: coord,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => controller.selecionarPerfil(usuario),
            child: AnimatedScale(
              scale: selecionado ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selecionado
                      ? theme.buttonColor
                      : theme.cardBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selecionado ? theme.textColor : theme.borderColor,
                    width: selecionado ? 2 : 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: temFoto
                    ? ClipOval(
                        child: Image.file(
                          File(fotoResolvida),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: selecionado
                            ? theme.buttonTextColor
                            : theme.textColor,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Projetos Comunitários (Autogestão Social)
    for (final projeto in controller.projetos) {
      final selecionado = controller.projetoSelecionado?.id == projeto.id;
      final icone = projeto.status == StatusProjetoComunitario.concluido
          ? Icons.check_circle_rounded
          : (projeto.status == StatusProjetoComunitario.emAndamento
              ? Icons.engineering_rounded
              : Icons.warning_amber_rounded);
      final corPin = projeto.status == StatusProjetoComunitario.concluido
          ? theme.buttonColor
          : (projeto.status == StatusProjetoComunitario.emAndamento
              ? theme.textColor
              : theme.dangerColor);

      marcadores.add(
        Marker(
          point: LatLng(projeto.latitude, projeto.longitude),
          width: 96,
          height: 56,
          child: GestureDetector(
            onTap: () => controller.selecionarProjeto(projeto),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selecionado ? theme.textColor : corPin,
                      width: selecionado ? 2.2 : 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icone, size: 17, color: corPin),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    projeto.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Lojas com miniatura da Logo (ou cluster numérico quando o zoom está afastado)
    double zoomAtual = 15.0;
    try {
      zoomAtual = controller.mapController.camera.zoom;
    } catch (_) {}

    final lojasComCoord = <(Loja loja, LatLng coord)>[];
    for (final loja in controller.lojas) {
      final coord = controller.coordenadasLojas[loja.id];
      if (coord != null) lojasComCoord.add((loja, coord));
    }

    final usarCluster = zoomAtual < 13.2 && lojasComCoord.length > 2;
    if (usarCluster) {
      final celula = zoomAtual < 10.5 ? 0.06 : 0.018;
      final grupos = <String, List<(Loja, LatLng)>>{};
      for (final par in lojasComCoord) {
        final gx = (par.$2.latitude / celula).floor();
        final gy = (par.$2.longitude / celula).floor();
        grupos.putIfAbsent('$gx:$gy', () => []).add(par);
      }
      for (final grupo in grupos.values) {
        if (grupo.length == 1) {
          marcadores.add(_construirMarcadorLoja(
            controller: controller,
            theme: theme,
            loja: grupo.first.$1,
            coord: grupo.first.$2,
          ));
          continue;
        }
        final latMedia =
            grupo.map((e) => e.$2.latitude).reduce((a, b) => a + b) /
                grupo.length;
        final lngMedia =
            grupo.map((e) => e.$2.longitude).reduce((a, b) => a + b) /
                grupo.length;
        final centro = LatLng(latMedia, lngMedia);
        marcadores.add(
          Marker(
            point: centro,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () {
                try {
                  controller.mapController.move(centro, zoomAtual + 2.2);
                } catch (_) {}
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.textColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${grupo.length}',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      for (final par in lojasComCoord) {
        marcadores.add(_construirMarcadorLoja(
          controller: controller,
          theme: theme,
          loja: par.$1,
          coord: par.$2,
        ));
      }
    }

    // 4. Ícone do próprio usuário logado no mapa (triângulo direcional em navegação ou avatar)
    final pontoMeu = controller.posicaoUsuario ?? controller.centroReferencia;
    final minhaFoto = usuarioLogado != null
        ? ImagemService.resolverCaminhoExistente(usuarioLogado.fotoExibicao)
        : null;
    marcadores.add(
      Marker(
        point: pontoMeu,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            if (usuarioLogado != null) {
              controller.selecionarPerfil(usuarioLogado);
            }
          },
          child: controller.navegandoAoVivo
              ? Transform.rotate(
                  angle: controller.rumoUsuarioGraus * math.pi / 180.0,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(30, 34),
                      painter: _TrianguloDirecaoPainter(
                        corPreenchimento: theme.buttonColor,
                        corBorda: theme.borderColor,
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: theme.buttonColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.buttonColor, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: minhaFoto != null
                        ? ClipOval(
                            child: Image.file(
                              File(minhaFoto),
                              fit: BoxFit.cover,
                              cacheWidth: 96,
                              cacheHeight: 96,
                              filterQuality: FilterQuality.low,
                            ),
                          )
                        : Icon(
                            Icons.person_pin_circle_rounded,
                            size: 20,
                            color: theme.textColor,
                          ),
                  ),
                ),
        ),
      ),
    );

    // 5. Pinos de Origem e Destino da Rota
    if (controller.origemRota != null && controller.rotaAtual != null) {
      marcadores.add(
        Marker(
          point: controller.origemRota!,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.buttonColor, width: 3),
            ),
          ),
        ),
      );
    }
    if (controller.destinoRota != null) {
      marcadores.add(
        Marker(
          point: controller.destinoRota!,
          width: 40,
          height: 44,
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.location_on_rounded,
            size: 38,
            color: theme.dangerColor,
          ),
        ),
      );
    }

    // 6. Pino vermelho de ponto clicado no mapa
    if (controller.pontoMapaSelecionado != null) {
      marcadores.add(
        Marker(
          point: controller.pontoMapaSelecionado!,
          width: 44,
          height: 48,
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.location_on_rounded,
            size: 42,
            color: theme.dangerColor,
          ),
        ),
      );
    }

    return marcadores;
  }

  static Marker _construirMarcadorLoja({
    required BuscaMapaController controller,
    required AppTheme theme,
    required Loja loja,
    required LatLng coord,
  }) {
    final selecionada = controller.lojaSelecionada?.id == loja.id;
    final logoResolvida = ImagemService.resolverCaminhoExistente(loja.logo);
    final temLogo = logoResolvida != null;

    return Marker(
      point: coord,
      width: 112,
      height: 64,
      child: GestureDetector(
        onTap: () => controller.selecionarLoja(loja),
        child: AnimatedScale(
          scale: selecionada ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selecionada
                        ? theme.buttonColor
                        : theme.textColor.withValues(alpha: 0.85),
                    width: selecionada ? 2.4 : 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: temLogo
                    ? ClipOval(
                        child: Image.file(
                          File(logoResolvida),
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          cacheHeight: 96,
                          filterQuality: FilterQuality.low,
                        ),
                      )
                    : Icon(
                        Icons.storefront_rounded,
                        size: 20,
                        color: theme.textColor,
                      ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  loja.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianguloDirecaoPainter extends CustomPainter {
  final Color corPreenchimento;
  final Color corBorda;

  const _TrianguloDirecaoPainter({
    required this.corPreenchimento,
    required this.corBorda,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = ui.Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h * 0.74)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.6), 5, true);

    final fillPaint = Paint()
      ..color = corPreenchimento
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = corBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TrianguloDirecaoPainter oldDelegate) {
    return oldDelegate.corPreenchimento != corPreenchimento ||
        oldDelegate.corBorda != corBorda;
  }
}
