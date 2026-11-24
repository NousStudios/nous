import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_story_view.dart';

/// Seletor de contatos e conversas estilo WhatsApp para encaminhar/compartilhar
/// uma publicação diretamente no Chat com fotos e nomes reais.
class DialogEnviarPublicacaoChat extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous remetente;

  const DialogEnviarPublicacaoChat({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.remetente,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required UsuarioNous remetente,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DialogEnviarPublicacaoChat(
        theme: theme,
        publicacao: publicacao,
        remetente: remetente,
      ),
    );
  }

  @override
  State<DialogEnviarPublicacaoChat> createState() =>
      _DialogEnviarPublicacaoChatState();
}

class _DestinoChatItem {
  final String conversaId;
  final String destinatarioId;
  final String nome;
  final String subtitulo;
  final String foto;
  final bool ehGrupo;

  const _DestinoChatItem({
    required this.conversaId,
    required this.destinatarioId,
    required this.nome,
    required this.subtitulo,
    required this.foto,
    this.ehGrupo = false,
  });
}

class _DialogEnviarPublicacaoChatState
    extends State<DialogEnviarPublicacaoChat> {
  final TextEditingController _buscaCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<_DestinoChatItem> _destinos = [];
  final Set<String> _enviadosIds = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDestinos();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDestinos() async {
    final meuCpf = widget.remetente.cpf.replaceAll(RegExp(r'\D'), '');
    final conversas = await ChatService.obterTodasConversas(cpfUsuario: meuCpf);
    final contas = await ContasNousService.carregarTodas();

    final mapaPorConversa = <String, _DestinoChatItem>{};

    for (final ConversaChat c in conversas) {
      if (c.ehGrupo) {
        final titulo = c.nomeGrupo.isNotEmpty ? c.nomeGrupo : c.titulo;
        mapaPorConversa[c.id] = _DestinoChatItem(
          conversaId: c.id,
          destinatarioId: c.id,
          nome: titulo.isNotEmpty ? titulo : 'Grupo Nous',
          subtitulo: 'Grupo • ${c.participantesIds.length} participantes',
          foto: c.foto,
          ehGrupo: true,
        );
      } else if (!c.ehLoja) {
        var outroCpf = c.identificador.replaceAll(RegExp(r'\D'), '');
        if (outroCpf.length != 11) {
          outroCpf = ChatService.extrairOutroCpf(c.id, meuCpf);
        }
        if (outroCpf.length == 11 && outroCpf != meuCpf) {
          final conta = contas
              .where((u) => u.cpf.replaceAll(RegExp(r'\D'), '') == outroCpf)
              .firstOrNull;
          final idCanonica =
              ChatService.conversaIdEntreUsuarios(meuCpf, outroCpf);
          mapaPorConversa[idCanonica] = _DestinoChatItem(
            conversaId: idCanonica,
            destinatarioId: outroCpf,
            nome: conta?.nomeExibicao.isNotEmpty == true
                ? conta!.nomeExibicao
                : (c.titulo.isNotEmpty ? c.titulo : 'Cidadão Nous'),
            subtitulo: conta?.usernameExibicao.isNotEmpty == true
                ? conta!.usernameExibicao
                : 'Conversa recente',
            foto: conta?.fotoExibicao.isNotEmpty == true
                ? conta!.fotoExibicao
                : c.foto,
          );
        }
      }
    }

    for (final u in contas) {
      final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.length != 11 || cpfLimpo == meuCpf) continue;
      final idCanonica = ChatService.conversaIdEntreUsuarios(meuCpf, cpfLimpo);
      mapaPorConversa.putIfAbsent(
        idCanonica,
        () => _DestinoChatItem(
          conversaId: idCanonica,
          destinatarioId: cpfLimpo,
          nome: u.nomeExibicao,
          subtitulo: u.usernameExibicao.isNotEmpty
              ? u.usernameExibicao
              : 'Cidadão Nous',
          foto: u.fotoExibicao,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _destinos = mapaPorConversa.values.toList();
      _carregando = false;
    });
  }

  Future<void> _enviarPara(_DestinoChatItem item) async {
    if (_enviadosIds.contains(item.conversaId)) return;
    setState(() => _enviadosIds.add(item.conversaId));

    await TimelineService.enviarPublicacaoNoChat(
      pub: widget.publicacao,
      conversaId: item.conversaId,
      meuCpf: widget.remetente.cpf,
      meuNome: widget.remetente.nomeExibicao,
      minhaFoto: widget.remetente.fotoExibicao,
      destinatarioId: item.destinatarioId,
    );
  }

  Future<void> _postarNoStory() async {
    final nav = Navigator.of(context);
    final pub = widget.publicacao;
    String caminho = '';
    var ehVideo = false;
    if (pub.midias.isNotEmpty) {
      final primeira = pub.midias.first;
      ehVideo = PlayerUniversalController.possuiVideo(pub);
      caminho =
          (await TimelineService.resolverCaminhoMidia(primeira.caminhoRelativo)) ??
              '';
    }
    if (!mounted) return;
    nav.pop(true);
    await EditorStoryView.mostrar(
      nav.context,
      theme: widget.theme,
      autor: widget.remetente,
      caminhoArquivo: caminho,
      ehVideo: ehVideo,
      abrirTextoAoEntrar: caminho.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final termo = _buscaCtrl.text.trim().toLowerCase();
    final filtrados = termo.isEmpty
        ? _destinos
        : _destinos
              .where(
                (d) =>
                    d.nome.toLowerCase().contains(termo) ||
                    d.subtitulo.toLowerCase().contains(termo),
              )
              .toList();

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Enviar pelo Chat',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () =>
                          Navigator.of(context).pop(_enviadosIds.isNotEmpty),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ThemedTextField(
                theme: theme,
                controller: _buscaCtrl,
                label: 'Pesquisar contato ou grupo...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: _carregando
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : filtrados.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Nenhum contato encontrado.',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollCtrl,
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          shrinkWrap: true,
                          itemCount: filtrados.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: theme.borderColor.withValues(alpha: 0.25),
                          ),
                          itemBuilder: (_, i) {
                            final d = filtrados[i];
                            final enviado =
                                _enviadosIds.contains(d.conversaId);
                            final prov =
                                ImagemService.obterImageProvider(d.foto);
                            final inicial = d.nome.trim().isNotEmpty
                                ? d.nome.trim()[0].toUpperCase()
                                : '?';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                radius: 21,
                                backgroundColor: theme.borderColor.withValues(
                                  alpha: 0.35,
                                ),
                                backgroundImage: prov,
                                child: prov == null
                                    ? (d.ehGrupo
                                          ? Icon(
                                              Icons.groups_outlined,
                                              color: theme.textColor,
                                            )
                                          : Text(
                                              inicial,
                                              style: theme.getTextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: theme.textColor,
                                              ),
                                            ))
                                    : null,
                              ),
                              title: Text(
                                d.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              subtitle: Text(
                                d.subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11.5,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: enviado
                                      ? Colors.transparent
                                      : theme.buttonColor,
                                  foregroundColor: enviado
                                      ? theme.secondaryTextColor
                                      : theme.buttonTextColor,
                                  elevation: 0,
                                  side: BorderSide(color: theme.borderColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed:
                                    enviado ? null : () => _enviarPara(d),
                                child: Text(
                                  enviado ? 'Enviado ✓' : 'Enviar',
                                  style: theme.getTextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: enviado
                                        ? theme.secondaryTextColor
                                        : theme.buttonTextColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _postarNoStory,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 19,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Publicar no seu Story',
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
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
