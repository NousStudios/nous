import 'package:flutter/material.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/services/chamada_historico_service.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/views/chamada_ativa_view.dart';

/// Barra flutuante exibida no topo do app quando o usuário minimiza uma chamada ativa,
/// permitindo continuar navegando pelo PDV ou chat sem desligar a ligação.
class BarraChamadaMinimizada extends StatelessWidget {
  const BarraChamadaMinimizada({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ChamadaWebRtcService.instancia;

    return ValueListenableBuilder<ChamadaSessao?>(
      valueListenable: service.sessaoAtiva,
      builder: (context, sessao, _) {
        if (sessao == null) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: service.chamadaMinimizada,
          builder: (context, minimizada, _) {
            if (!minimizada) return const SizedBox.shrink();

            return ValueListenableBuilder<AppTheme>(
              valueListenable: ThemeController.currentTheme,
              builder: (context, theme, _) {
                final nome = sessao.destinatarioNome.isNotEmpty
                    ? sessao.destinatarioNome
                    : sessao.remetenteNome;

                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Material(
                        color: theme.cardBackgroundColor,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            service.chamadaMinimizada.value = false;
                            final navCtx = NavigatorKeyService.currentContext;
                            if (navCtx != null && navCtx.mounted) {
                              ChamadaAtivaView.abrir(navCtx, sessao);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sessao.tipo == TipoChamada.video
                                      ? Icons.videocam_rounded
                                      : Icons.call_rounded,
                                  color: theme.buttonColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        nome,
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      ValueListenableBuilder<String>(
                                        valueListenable: service.statusConexao,
                                        builder: (context, status, _) {
                                          if (status == 'reconectando') {
                                            return Text(
                                              'Reconectando Wi-Fi...',
                                              style: TextStyle(
                                                color: theme.secondaryTextColor,
                                                fontSize: 11,
                                              ),
                                            );
                                          }
                                          return ValueListenableBuilder<int>(
                                            valueListenable:
                                                service.segundosChamada,
                                            builder: (context, segundos, _) {
                                              final textoTempo = sessao.estado ==
                                                      EstadoChamada.conectada
                                                  ? 'Em chamada • ${ChamadaHistoricoService.formatarDuracao(segundos)}'
                                                  : 'Chamando...';
                                              return Text(
                                                textoTempo,
                                                style: TextStyle(
                                                  color:
                                                      theme.secondaryTextColor,
                                                  fontSize: 11,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: service.microfoneMutado
                                      ? 'Ativar Microfone'
                                      : 'Silenciar Microfone',
                                  icon: Icon(
                                    service.microfoneMutado
                                        ? Icons.mic_off_rounded
                                        : Icons.mic_rounded,
                                    color: theme.textColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    service.alternarMicrofone();
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Encerrar Chamada',
                                  icon: Icon(
                                    Icons.call_end_rounded,
                                    color: theme.dangerColor,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    service.encerrarChamada(notificarRede: true);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
