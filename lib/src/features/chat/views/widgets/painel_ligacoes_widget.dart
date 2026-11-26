import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/registro_chamada.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_recursos_extras_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/chamada_ativa_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Painel dedicado de Ligações (histórico, chamada ativa estilo Discord e discagem rápida).
class PainelLigacoesWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;

  const PainelLigacoesWidget({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  State<PainelLigacoesWidget> createState() => _PainelLigacoesWidgetState();
}

class _PainelLigacoesWidgetState extends State<PainelLigacoesWidget> {
  List<RegistroChamada> _historico = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final lista = await ChatRecursosExtrasService.listarHistoricoChamadas();
    if (!mounted) return;
    setState(() {
      _historico = lista;
      _carregando = false;
    });
  }

  String _formatarDuracao(int seg) {
    final m = (seg ~/ 60).toString().padLeft(2, '0');
    final s = (seg % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatarDataHora(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  Future<void> _iniciarChamada({
    required String conversaId,
    required String titulo,
    required String foto,
    required TipoChamada tipo,
    bool ehGrupo = false,
    List<String> participantesIds = const [],
  }) async {
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final meuCpf = ChatService.normalizarCpf(
      widget.controller.usuarioCpf ?? conta?.cpf ?? '',
    );
    if (meuCpf.isEmpty) return;

    final sessao = await ChamadaWebRtcService.instancia.iniciarChamada(
      conversaId: conversaId,
      meuCpf: meuCpf,
      meuNome: widget.controller.usuarioNome ?? conta?.nomeExibicao ?? 'Eu',
      minhaFoto: widget.controller.usuarioFoto ?? conta?.foto ?? '',
      destinatarioId: ehGrupo ? '' : ChatService.extrairOutroCpf(conversaId, meuCpf),
      destinatarioNome: titulo,
      destinatarioFoto: foto,
      tipo: tipo,
      ehGrupo: ehGrupo,
      participantesIds: participantesIds,
    );
    if (sessao != null && mounted) {
      await ChamadaAtivaView.abrir(context, sessao);
    }
  }

  Future<void> _abrirNovaLigacao() async {
    final theme = widget.theme;
    final contatos = widget.controller.conversas
        .where((c) => !c.ehLoja)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nova Ligação',
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: contatos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Nenhum contato disponível.',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: contatos.length,
                          itemBuilder: (_, i) {
                            final ConversaChat c = contatos[i];
                            return ListTile(
                              title: Text(
                                c.titulo,
                                style: theme.getTextStyle(
                                  fontSize: 14,
                                  color: theme.textColor,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.call_outlined,
                                      color: theme.textColor,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _iniciarChamada(
                                        conversaId: c.id,
                                        titulo: c.titulo,
                                        foto: c.foto,
                                        tipo: TipoChamada.voz,
                                        ehGrupo: c.ehGrupo,
                                        participantesIds: c.participantesIds,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.videocam_outlined,
                                      color: theme.textColor,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _iniciarChamada(
                                        conversaId: c.id,
                                        titulo: c.titulo,
                                        foto: c.foto,
                                        tipo: TipoChamada.video,
                                        ehGrupo: c.ehGrupo,
                                        participantesIds: c.participantesIds,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.call_rounded, size: 22, color: theme.textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ligações',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        'Chamadas de voz, vídeo e transmissão de tela estilo Discord',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.textColor,
                    foregroundColor: theme.backgroundColor,
                  ),
                  onPressed: _abrirNovaLigacao,
                  icon: const Icon(Icons.add_call, size: 18),
                  label: const Text('Nova Ligação'),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<ChamadaSessao?>(
            valueListenable: ChamadaWebRtcService.instancia.sessaoAtiva,
            builder: (_, sessao, _) {
              if (sessao == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.textColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: theme.textColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chamada em andamento: ${sessao.destinatarioNome}',
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.textColor,
                        foregroundColor: theme.backgroundColor,
                      ),
                      onPressed: () {
                        ChamadaAtivaView.abrir(context, sessao);
                      },
                      child: const Text('Abrir Chamada'),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _carregando
                ? Center(
                    child: CircularProgressIndicator(color: theme.textColor),
                  )
                : _historico.isEmpty
                    ? EstadoVazioContainer(
                        theme: theme,
                        mensagem:
                            'Nenhuma ligação registrada ainda.\nToque em "Nova Ligação" para iniciar uma chamada de voz ou vídeo.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _historico.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: theme.borderColor.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (_, i) {
                          final r = _historico[i];
                          final perdida = r.recebida && !r.atendida;
                          return ListTile(
                            leading: Icon(
                              r.recebida
                                  ? (perdida
                                      ? Icons.call_missed_rounded
                                      : Icons.call_received_rounded)
                                  : Icons.call_made_rounded,
                              color: perdida
                                  ? theme.dangerColor
                                  : theme.textColor,
                            ),
                            title: Text(
                              r.tituloContato,
                              style: theme.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: perdida
                                    ? theme.dangerColor
                                    : theme.textColor,
                              ),
                            ),
                            subtitle: Text(
                              '${r.tipo == TipoChamada.video ? "Vídeo" : "Voz"} • ${_formatarDataHora(r.dataHora)}${r.duracaoSegundos > 0 ? " • ${_formatarDuracao(r.duracaoSegundos)}" : ""}',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.call_outlined,
                                    color: theme.textColor,
                                  ),
                                  onPressed: () => _iniciarChamada(
                                    conversaId: r.conversaId,
                                    titulo: r.tituloContato,
                                    foto: r.fotoContato,
                                    tipo: TipoChamada.voz,
                                    ehGrupo: r.ehGrupo,
                                    participantesIds: r.participantesIds,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.videocam_outlined,
                                    color: theme.textColor,
                                  ),
                                  onPressed: () => _iniciarChamada(
                                    conversaId: r.conversaId,
                                    titulo: r.tituloContato,
                                    foto: r.fotoContato,
                                    tipo: TipoChamada.video,
                                    ehGrupo: r.ehGrupo,
                                    participantesIds: r.participantesIds,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
  }
}
