import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_filtros_helper.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/models/comunidade_usuario.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_recursos_extras_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/chamada_ativa_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Painel de Comunidades da Mensageria Pessoal (estilo WhatsApp + Discord),
/// mantendo isolamento estrito da Ágora Digital do Nous e da mensageria das Lojas.
class PainelComunidadesWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final bool desktop;

  const PainelComunidadesWidget({
    super.key,
    required this.controller,
    required this.theme,
    this.desktop = true,
  });

  @override
  State<PainelComunidadesWidget> createState() =>
      _PainelComunidadesWidgetState();
}

class _PainelComunidadesWidgetState extends State<PainelComunidadesWidget> {
  List<ComunidadeUsuario> _comunidades = [];
  ComunidadeUsuario? _selecionada;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarComunidades();
  }

  Future<void> _carregarComunidades() async {
    final lista = await ChatRecursosExtrasService.listarComunidadesUsuario();
    if (!mounted) return;
    setState(() {
      _comunidades = lista;
      if (_selecionada != null) {
        _selecionada = lista.cast<ComunidadeUsuario?>().firstWhere(
              (c) => c?.id == _selecionada!.id,
              orElse: () => null,
            );
      } else if (lista.isNotEmpty) {
        _selecionada = lista.first;
      }
      _carregando = false;
    });
  }

  Future<void> _criarComunidade() async {
    final theme = widget.theme;
    final nomeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
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
                  'Nova Comunidade',
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Organize grupos com canais de texto e salas de voz para sua rede.',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomeCtrl,
                  autofocus: true,
                  style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Nome da comunidade',
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Descrição ou propósito (opcional)',
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.textColor,
                        foregroundColor: theme.backgroundColor,
                      ),
                      onPressed: () {
                        if (nomeCtrl.text.trim().isNotEmpty) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: const Text('Criar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final cpf = ChatService.normalizarCpf(
      widget.controller.usuarioCpf ?? auth.contaAtual?.cpf ?? '',
    );
    final nome = nomeCtrl.text.trim();

    // Cria automaticamente o canal de texto #geral e a sala de voz #Sala Geral
    final canalGeral = await ChatService.criarGrupo(
      nome: '$nome • #geral',
      membrosCpfs: [cpf],
      autorCpf: cpf,
      autorNome: auth.contaAtual?.nomeExibicao ?? 'Criador',
    );

    final nova = ComunidadeUsuario(
      id: 'com_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome,
      descricao: descCtrl.text.trim(),
      criadorCpf: cpf,
      membrosIds: [cpf],
      canaisTextoIds: [canalGeral.id],
      canaisVoz: [
        CanalVozComunidade(
          id: 'voz_${DateTime.now().millisecondsSinceEpoch}',
          nome: 'Sala de Voz Geral',
        ),
      ],
      criadoEm: DateTime.now(),
    );

    await ChatRecursosExtrasService.salvarComunidadeUsuario(nova);
    await _carregarComunidades();
    if (mounted) setState(() => _selecionada = nova);
  }

  Future<void> _adicionarCanalTexto(ComunidadeUsuario com) async {
    final theme = widget.theme;
    final ctrl = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Novo Canal de Texto',
          style: theme.getTextStyle(color: theme.textColor),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: theme.getTextStyle(color: theme.textColor),
          decoration: const InputDecoration(hintText: 'Ex.: avisos, entregas'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: Text(
              'Criar',
              style: theme.getTextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (nome == null || nome.isEmpty || !mounted) return;
    final auth = context.read<AuthProvider>();
    final cpf = ChatService.normalizarCpf(
      widget.controller.usuarioCpf ?? auth.contaAtual?.cpf ?? '',
    );
    final grupo = await ChatService.criarGrupo(
      nome: '${com.nome} • #$nome',
      membrosCpfs: com.membrosIds.isNotEmpty ? com.membrosIds : [cpf],
      autorCpf: cpf,
      autorNome: auth.contaAtual?.nomeExibicao ?? 'Membro',
    );
    final atualizada = com.copyWith(
      canaisTextoIds: [...com.canaisTextoIds, grupo.id],
    );
    await ChatRecursosExtrasService.salvarComunidadeUsuario(atualizada);
    await _carregarComunidades();
  }

  Future<void> _entrarCanalVoz(
    ComunidadeUsuario com,
    CanalVozComunidade canal,
  ) async {
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final cpf = ChatService.normalizarCpf(
      widget.controller.usuarioCpf ?? conta?.cpf ?? '',
    );
    if (cpf.isEmpty) return;

    final sessao = await ChamadaWebRtcService.instancia.iniciarChamada(
      conversaId: '${com.id}_${canal.id}',
      meuCpf: cpf,
      meuNome: conta?.nomeExibicao ?? 'Usuário Nous',
      minhaFoto: conta?.foto ?? '',
      destinatarioId: '',
      destinatarioNome: '${com.nome} • ${canal.nome}',
      destinatarioFoto: com.foto,
      tipo: TipoChamada.voz,
      ehGrupo: true,
      participantesIds: com.membrosIds,
    );
    if (sessao != null && mounted) {
      await ChamadaAtivaView.abrir(context, sessao);
    }
  }

  Widget _buildListaComunidades(AppTheme theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _comunidades.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _comunidades[i];
        final ativa = _selecionada?.id == c.id;
        return InkWell(
          onTap: () => setState(() => _selecionada = c),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ativa
                  ? theme.textColor.withValues(alpha: 0.12)
                  : theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ativa
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nome,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      if (c.descricao.isNotEmpty)
                        Text(
                          c.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.desktop)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalheComunidade(AppTheme theme) {
    if (_selecionada == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!widget.desktop) ...[
          InkWell(
            onTap: () => setState(() => _selecionada = null),
            child: Row(
              children: [
                Icon(Icons.arrow_back, size: 18, color: theme.textColor),
                const SizedBox(width: 8),
                Text(
                  'Voltar para todas as comunidades',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CANAIS DE TEXTO',
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.secondaryTextColor,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                size: 18,
                color: theme.textColor,
              ),
              onPressed: () => _adicionarCanalTexto(_selecionada!),
            ),
          ],
        ),
        ..._selecionada!.canaisTextoIds.map((id) {
          final conv = widget.controller.conversas
              .cast()
              .firstWhere(
                (c) => c?.id == id,
                orElse: () => null,
              );
          final nomeCanal = conv?.titulo ?? 'Canal #$id';
          return ListTile(
            leading: Icon(
              Icons.tag_rounded,
              color: theme.secondaryTextColor,
            ),
            title: Text(
              nomeCanal,
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.textColor,
              ),
            ),
            onTap: () {
              widget.controller.selecionarAba(
                AbaNavegacaoMensageria.conversas,
              );
              if (conv != null) {
                widget.controller.selecionarConversa(conv);
              }
            },
          );
        }),
        const SizedBox(height: 16),
        Text(
          'CANAIS DE VOZ',
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._selecionada!.canaisVoz.map(
          (voz) => ListTile(
            leading: Icon(
              Icons.volume_up_rounded,
              color: theme.textColor,
            ),
            title: Text(
              voz.nome,
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.textColor,
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.textColor,
                foregroundColor: theme.backgroundColor,
              ),
              onPressed: () => _entrarCanalVoz(_selecionada!, voz),
              child: const Text('Conectar'),
            ),
          ),
        ),
      ],
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
              Icon(Icons.groups_rounded, size: 22, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comunidades da Mensageria',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Canais de texto e voz da sua rede pessoal',
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
                onPressed: _criarComunidade,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nova Comunidade'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? Center(
                  child: CircularProgressIndicator(color: theme.textColor),
                )
              : _comunidades.isEmpty
                  ? EstadoVazioContainer(
                      theme: theme,
                      mensagem:
                          'Você ainda não criou nenhuma comunidade.\nCrie uma comunidade para reunir canais de texto e salas de voz estilo Discord.',
                    )
                  : (widget.desktop
                      ? Row(
                          children: [
                            SizedBox(
                              width: 240,
                              child: _buildListaComunidades(theme),
                            ),
                            VerticalDivider(
                              width: 1,
                              color: theme.borderColor.withValues(alpha: 0.4),
                            ),
                            Expanded(child: _buildDetalheComunidade(theme)),
                          ],
                        )
                      : (_selecionada == null
                          ? _buildListaComunidades(theme)
                          : _buildDetalheComunidade(theme))),
        ),
      ],
    );
  }
}
