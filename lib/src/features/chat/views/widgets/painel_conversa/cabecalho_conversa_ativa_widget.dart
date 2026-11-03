import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/chamada_ativa_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Cabeçalho da conversa ativa com visualização do contato, status,
/// chamadas WebRTC de vídeo/voz e ações rápidas.
class CabecalhoConversaAtivaWidget extends StatelessWidget {
  final ConversaChat conversa;
  final AppTheme theme;
  final bool desktop;
  final VoidCallback onVoltarMobile;
  final void Function(ConversaChat) onAbrirDetalhes;
  final void Function(ConversaChat) onRenomearConversa;

  const CabecalhoConversaAtivaWidget({
    super.key,
    required this.conversa,
    required this.theme,
    required this.desktop,
    required this.onVoltarMobile,
    required this.onAbrirDetalhes,
    required this.onRenomearConversa,
  });

  void _iniciarChamada(BuildContext context, ConversaChat conversa, TipoChamada tipo) async {
    final auth = context.read<AuthProvider>();
    final meuCpf = auth.cpf.replaceAll(RegExp(r'\D'), '');
    final meuNome = auth.contaAtual?.nomeExibicao.isNotEmpty == true
        ? auth.contaAtual!.nomeExibicao
        : (auth.contaAtual?.nome.isNotEmpty == true
            ? auth.contaAtual!.nome
            : 'Usuário Nous');
    final minhaFoto = auth.contaAtual?.foto ?? '';

    String destId = '';
    String destNome = conversa.titulo;
    String destFoto = conversa.foto;

    if (conversa.ehGrupo) {
      destId = conversa.id;
    } else {
      destId = conversa.identificador.replaceAll(RegExp(r'\D'), '');
      if (destId.isEmpty) {
        destId = ChatService.extrairOutroCpf(conversa.id, meuCpf);
      }
    }

    final sessao = await ChamadaWebRtcService.instancia.iniciarChamada(
      conversaId: conversa.id,
      tipo: tipo,
      meuCpf: meuCpf,
      meuNome: meuNome,
      minhaFoto: minhaFoto,
      destinatarioId: destId,
      destinatarioNome: destNome,
      destinatarioFoto: destFoto,
      ehGrupo: conversa.ehGrupo,
      participantesIds: conversa.participantesIds,
    );

    if (sessao != null && context.mounted) {
      ChamadaAtivaView.abrir(context, sessao);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!desktop)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: theme.textColor,
              ),
              tooltip: 'Voltar',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              onPressed: onVoltarMobile,
            ),
          if (!desktop) const SizedBox(width: 2),

          // Bloco do Contato (Avatar + Nome e Status/Username) com toque para abrir detalhes
          Expanded(
            child: InkWell(
              onTap: () => onAbrirDetalhes(conversa),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    ResolvedorFotoChat.instancia.buildAvatar(
                      context,
                      theme: theme,
                      conversa: conversa,
                      raio: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversa.ehGrupo
                                ? (conversa.nomeGrupo.isNotEmpty
                                      ? conversa.nomeGrupo
                                      : conversa.titulo)
                                : (conversa.titulo.isNotEmpty &&
                                          conversa.titulo != 'Conversa' &&
                                          conversa.titulo != 'Nova Conversa' &&
                                          conversa.titulo != 'Contato' &&
                                          conversa.titulo != 'Contato Nous'
                                      ? conversa.titulo
                                      : (conversa.subtitulo.isNotEmpty &&
                                                conversa.subtitulo != 'Conversa' &&
                                                conversa.subtitulo != 'Contato Nous'
                                            ? conversa.subtitulo
                                            : 'Contato Nous')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conversa.ehGrupo
                                ? 'Grupo • ${conversa.participantesIds.length} participantes'
                                : (conversa.subtitulo.isNotEmpty &&
                                          conversa.subtitulo != conversa.titulo &&
                                          conversa.subtitulo != 'Conversa' &&
                                          conversa.subtitulo != 'Contato Nous'
                                      ? conversa.subtitulo
                                      : (conversa.ehLoja
                                            ? 'Loja Nous'
                                            : 'Usuário Nous')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botões de Ação do Lado Direito (Ligações de vídeo/voz, edição e 3 pontos)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!conversa.id.startsWith('loja_nous_coletiva_') &&
                  conversa.id != PdvProvider.idLojaColetivaNous &&
                  !(conversa.ehLoja &&
                      conversa.lojaId ==
                          PdvProvider.idLojaColetivaNous)) ...[
                IconButton(
                  icon: Icon(
                    Icons.videocam_rounded,
                    size: 22,
                    color: theme.textColor,
                  ),
                  tooltip: 'Chamada de Vídeo',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _iniciarChamada(context, conversa, TipoChamada.video),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.call_rounded,
                    size: 20,
                    color: theme.textColor,
                  ),
                  tooltip: 'Chamada de Voz',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _iniciarChamada(context, conversa, TipoChamada.voz),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: theme.secondaryTextColor,
                ),
                tooltip: 'Renomear conversa',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => onRenomearConversa(conversa),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 21,
                  color: theme.secondaryTextColor,
                ),
                tooltip: 'Mais opções / Detalhes',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => onAbrirDetalhes(conversa),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
