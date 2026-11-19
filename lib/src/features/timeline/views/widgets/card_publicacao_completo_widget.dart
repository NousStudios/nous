import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/insights_publicacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/carrossel_fotos_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/widget_midia_publicacao.dart';

/// Card completo de publicação no mesmo padrão visual e interativo da tela de detalhes:
/// cabeçalho (autor + colaboradores com nomes), carrossel horizontal arrastável,
/// legenda/#tags, pílulas Like/Deslike, contagem de comentários, republicar, chat, salvar e opções (...).
class CardPublicacaoCompletoWidget extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;
  final ValueChanged<String>? onTapTag;

  const CardPublicacaoCompletoWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioLogado,
    this.onTapTag,
  });

  @override
  State<CardPublicacaoCompletoWidget> createState() =>
      _CardPublicacaoCompletoWidgetState();
}

class _CardPublicacaoCompletoWidgetState
    extends State<CardPublicacaoCompletoWidget> {
  late PublicacaoSocial _pub;
  List<ReacaoSocial> _reacoes = [];
  int _totalComentarios = 0;

  @override
  void initState() {
    super.initState();
    _pub = widget.publicacao;
    _carregarInteracoes();
    TimelineService.alteracoesTimelineNotifier.addListener(_onTimelineMudou);
  }

  @override
  void didUpdateWidget(covariant CardPublicacaoCompletoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicacao.id != widget.publicacao.id ||
        oldWidget.publicacao.atualizadaEm != widget.publicacao.atualizadaEm) {
      _pub = widget.publicacao;
      _carregarInteracoes();
    }
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_onTimelineMudou);
    super.dispose();
  }

  void _onTimelineMudou() {
    if (mounted) _carregarInteracoes();
  }

  UsuarioNous? _obterUsuarioEfetivo() {
    if (widget.usuarioLogado != null) return widget.usuarioLogado;
    try {
      final auth = context.read<AuthProvider>();
      if (auth.contaAtual != null) return auth.contaAtual;
      if (auth.cpf.isNotEmpty) {
        return UsuarioNous(
          cpf: auth.cpf,
          nome: 'Cidadão Nous',
          dataNascimento: '',
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _carregarInteracoes() async {
    final pubIdAlvo = _pub.id;
    final reacoes = await TimelineService.listarReacoes(pubIdAlvo);
    final comentarios = await TimelineService.listarComentarios(pubIdAlvo);
    if (!mounted || _pub.id != pubIdAlvo) return;
    setState(() {
      _reacoes = reacoes;
      _totalComentarios = comentarios.where((c) => !c.excluido).length;
    });
  }

  Future<void> _reagir(TipoReacaoSocial tipo) async {
    final u = _obterUsuarioEfetivo();
    if (u == null) return;
    await TimelineService.alternarReacao(
      publicacaoId: _pub.id,
      usuarioCpf: u.cpf,
      usuarioNome: u.nomeExibicao,
      usuarioFoto: u.fotoExibicao,
      tipo: tipo,
    );
    await _carregarInteracoes();
  }

  void _abrirDetalhes() {
    DialogDetalhesPublicacao.mostrar(
      context,
      theme: widget.theme,
      publicacao: _pub,
      usuarioLogado: _obterUsuarioEfetivo(),
    );
  }

  Future<void> _abrirMenuOpcoes(bool ehAutor) async {
    final theme = widget.theme;
    final u = _obterUsuarioEfetivo();
    final acao = await DialogOpcoesPublicacao.mostrarMenuOpcoes(
      context,
      theme: theme,
      publicacao: _pub,
      ehAutor: ehAutor,
      podeDenunciar: u != null,
    );
    if (!mounted || acao == null) return;

    if (acao == 'fixar') {
      final atualizada = await TimelineService.alternarFixarPublicacao(_pub);
      if (mounted) {
        setState(() => _pub = atualizada);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              atualizada.fixada
                  ? 'Publicação fixada no topo!'
                  : 'Publicação desafixada.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (acao == 'editar') {
      final editCtrl = TextEditingController(text: _pub.texto);
      final novoTexto = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          title: Text(
            'Editar Publicação',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ThemedTextField(
            theme: theme,
            controller: editCtrl,
            linhas: 4,
            label: 'Legenda ou texto',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(editCtrl.text),
              child: Text(
                'Salvar',
                style: theme.getTextStyle(
                  color: theme.buttonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      editCtrl.dispose();
      if (novoTexto != null) {
        final atualizada = await TimelineService.editarPublicacao(
          _pub,
          novoTexto: novoTexto,
        );
        if (mounted) setState(() => _pub = atualizada);
      }
    } else if (acao == 'arquivar') {
      await TimelineService.arquivarPublicacao(
        _pub,
        arquivar: !_pub.arquivada,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pub.arquivada
                  ? 'Publicação restaurada para o perfil.'
                  : 'Publicação arquivada em Arquivos da Conta.',
            ),
          ),
        );
      }
    } else if (acao == 'excluir') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          title: Text(
            'Excluir Publicação',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir esta publicação?',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(
                  color: theme.dangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmar == true) {
        await TimelineService.excluirPublicacao(_pub);
      }
    } else if (acao == 'baixar' && _pub.midias.isNotEmpty) {
      final salvo = await TimelineService.baixarMidia(_pub.midias.first);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              salvo != null
                  ? 'Arquivo salvo em: $salvo'
                  : 'Não foi possível baixar o arquivo.',
            ),
          ),
        );
      }
    } else if (acao == 'denunciar' && u != null) {
      final ok = await DialogDenunciaSocial.mostrar(
        context,
        theme: theme,
        denunciante: u,
        alvoCpf: _pub.autorCpf,
        alvoNome: _pub.autorNome,
        publicacaoId: _pub.id,
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia registrada.')),
        );
      }
    }
  }

  String _formatarDataHora(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    if (l.year != DateTime.now().year) {
      return '$d/$m/${l.year} • $h:$min';
    }
    return '$d/$m • $h:$min';
  }

  Widget _buildPilulaReacao({
    required AppTheme theme,
    required IconData icone,
    required int contagem,
    required VoidCallback onTapIcone,
    required VoidCallback onTapContagem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTapIcone,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(icone, size: 18, color: theme.textColor),
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTapContagem,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                '$contagem',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = _pub;
    final u = _obterUsuarioEfetivo();
    final meuCpf = (u?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final ehAutor =
        meuCpf.isNotEmpty &&
        meuCpf == pub.autorCpf.replaceAll(RegExp(r'\D'), '');

    final likes = _reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length;
    final deslikes =
        _reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length;
    final minhaReacao = _reacoes
        .where((r) => r.usuarioCpf.replaceAll(RegExp(r'\D'), '') == meuCpf)
        .firstOrNull;

    return Card(
      color: theme.cardBackgroundColor,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabeçalho completo com foto do autor + colaboradores + botão (...) à direita
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 6),
            child: CabecalhoAutorColaboradoresWidget(
              theme: theme,
              publicacao: pub,
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                tooltip: 'Mais opções',
                icon: Icon(Icons.more_horiz_rounded, color: theme.textColor),
                onPressed: () => _abrirMenuOpcoes(ehAutor),
              ),
            ),
          ),

          // 2. Carrossel / Mídia interativa com altura controlada (fotos vs vídeo/áudio/doc)
          if (pub.midias.isNotEmpty)
            if (pub.midias.every((m) {
              final ext = m.mimeTipo.toLowerCase();
              return ext == 'jpg' ||
                  ext == 'jpeg' ||
                  ext == 'png' ||
                  ext == 'webp' ||
                  (ext.isEmpty && pub.tipo == TipoFeedSocial.fotos);
            }))
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).width < 600 ? 310 : 440,
                ),
                child: CarrosselFotosPublicacao(
                  theme: theme,
                  midias: pub.midias,
                  aspectRatio: pub.aspectRatioEfetivo,
                  alignment: Alignment(pub.alinhamentoX, pub.alinhamentoY),
                  escalaZoomPadrao: pub.escalaZoom,
                  onTapFoto: _abrirDetalhes,
                  onDoubleTapLike: () => _reagir(TipoReacaoSocial.like),
                ),
              )
            else
              WidgetMidiaPublicacao(theme: theme, publicacao: pub),

          // 3. Barra de interações unificada na mesma linha + data à direita
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 2),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPilulaReacao(
                          theme: theme,
                          icone: minhaReacao?.tipo == TipoReacaoSocial.like
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_off_alt_rounded,
                          contagem: likes,
                          onTapIcone: () => _reagir(TipoReacaoSocial.like),
                          onTapContagem: () =>
                              DialogOpcoesPublicacao.mostrarListaReacoes(
                            context,
                            theme: theme,
                            reacoes: _reacoes,
                            tipo: TipoReacaoSocial.like,
                          ),
                        ),
                        const SizedBox(width: 2),
                        _buildPilulaReacao(
                          theme: theme,
                          icone: minhaReacao?.tipo == TipoReacaoSocial.deslike
                              ? Icons.thumb_down_alt_rounded
                              : Icons.thumb_down_off_alt_rounded,
                          contagem: deslikes,
                          onTapIcone: () => _reagir(TipoReacaoSocial.deslike),
                          onTapContagem: () =>
                              DialogOpcoesPublicacao.mostrarListaReacoes(
                            context,
                            theme: theme,
                            reacoes: _reacoes,
                            tipo: TipoReacaoSocial.deslike,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _abrirDetalhes,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mode_comment_outlined,
                                  size: 17,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$_totalComentarios',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          tooltip: 'Republicar',
                          icon: Icon(
                            Icons.repeat_rounded,
                            size: 18,
                            color: theme.textColor,
                          ),
                          onPressed: u == null
                              ? null
                              : () async {
                                  await TimelineService.republicar(
                                    original: pub,
                                    meuCpf: u.cpf,
                                    meuNome: u.nomeExibicao,
                                    minhaFoto: u.fotoExibicao,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Publicação republicada no seu perfil!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                        if (u != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            tooltip: 'Salvar',
                            icon: Icon(
                              Icons.bookmark_border_rounded,
                              size: 18,
                              color: theme.textColor,
                            ),
                            onPressed: () async {
                              final salvo =
                                  await DialogSalvarPublicacao.mostrar(
                                context,
                                theme: theme,
                                usuarioCpf: u.cpf,
                                publicacaoId: pub.id,
                              );
                              if (salvo == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Conteúdo salvo!'),
                                  ),
                                );
                              }
                            },
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          tooltip: 'Enviar pelo chat',
                          icon: Icon(
                            Icons.send_rounded,
                            size: 17,
                            color: theme.textColor,
                          ),
                          onPressed: u == null
                              ? null
                              : () async {
                                  final enviou =
                                      await DialogEnviarPublicacaoChat.mostrar(
                                    context,
                                    theme: theme,
                                    publicacao: pub,
                                    remetente: u,
                                  );
                                  if (enviou == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Publicação enviada pelo chat!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => InsightsPublicacaoView.abrir(
                    context,
                    theme: theme,
                    publicacao: pub,
                    totalCurtidas: likes,
                    totalDeslikes: deslikes,
                    totalComentarios: _totalComentarios,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${pub.visualizacoes}',
                          style: theme.getTextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatarDataHora(pub.criadaEm),
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // 4. Legenda com #tags em azul clicáveis
          if (pub.texto.isNotEmpty)
            InkWell(
              onTap: _abrirDetalhes,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: TextoComHashtagsWidget(
                  theme: theme,
                  texto: pub.texto,
                  fontSize: 13.5,
                  onTapTag: widget.onTapTag,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
