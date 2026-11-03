import 'package:flutter/material.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/views/chamada_ativa_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class DialogChamadaRecebida extends StatefulWidget {
  final ChamadaSessao sessao;
  final Map<String, dynamic> sdpOferta;

  const DialogChamadaRecebida({
    super.key,
    required this.sessao,
    required this.sdpOferta,
  });

  static Future<void> exibir(
    BuildContext context, {
    required ChamadaSessao sessao,
    required Map<String, dynamic> sdpOferta,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogChamadaRecebida(
        sessao: sessao,
        sdpOferta: sdpOferta,
      ),
    );
  }

  @override
  State<DialogChamadaRecebida> createState() => _DialogChamadaRecebidaState();
}

class _DialogChamadaRecebidaState extends State<DialogChamadaRecebida> {
  final _service = ChamadaWebRtcService.instancia;

  @override
  void initState() {
    super.initState();
    SomService.tocarEvento(SomService.eventoNovoPedido);

    _service.onChamadaEncerrada = () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final ehVideo = widget.sessao.tipo == TipoChamada.video;
    final imageProvider =
        ImagemService.obterImageProvider(widget.sessao.remetenteFoto);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFF2A3649),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Colors.white70,
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ehVideo ? Colors.blueAccent : Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF161E2E), width: 2),
                  ),
                  child: Icon(
                    ehVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nome do remetente
            Text(
              widget.sessao.remetenteNome.isNotEmpty
                  ? widget.sessao.remetenteNome
                  : 'Usuário Nous',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Subtítulo
            Text(
              ehVideo
                  ? 'Chamada de Vídeo Recebida...'
                  : 'Chamada de Voz Recebida...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),

            // Botões Atender / Recusar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Recusar
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _service.rejeitarChamada();
                        if (context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recusar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Atender
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final ok =
                            await _service.aceitarChamada(widget.sdpOferta);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        if (ok) {
                          ChamadaAtivaView.abrir(context, widget.sessao);
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          ehVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          color: Colors.black87,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Atender',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
