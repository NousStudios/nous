import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

/// Lista modularizada das interações do usuário na rede, agrupadas por
/// publicação, com sub-abas "Todos" e "Denúncias", expansão inline e janela de log.
class ListaInteracoesPerfilWidget extends StatefulWidget {
  final AppTheme theme;
  final List<RegistroInteracaoUsuario> interacoes;
  final List<DenunciaSocial> denuncias;
  final String cpfPerfil;
  final String nomePerfil;
  final String fotoPerfil;
  final UsuarioNous? usuarioLogado;

  const ListaInteracoesPerfilWidget({
    super.key,
    required this.theme,
    required this.interacoes,
    this.denuncias = const [],
    this.cpfPerfil = '',
    this.nomePerfil = '',
    this.fotoPerfil = '',
    required this.usuarioLogado,
  });

  @override
  State<ListaInteracoesPerfilWidget> createState() =>
      _ListaInteracoesPerfilWidgetState();
}

class _GrupoInteracoesPost {
  final String chave;
  final PublicacaoSocial? publicacao;
  final String alvoCpf;
  final String alvoNome;
  final String alvoFoto;
  final List<RegistroInteracaoUsuario> eventos;

  _GrupoInteracoesPost({
    required this.chave,
    required this.publicacao,
    required this.alvoCpf,
    required this.alvoNome,
    required this.alvoFoto,
    required this.eventos,
  });

  DateTime get ultimaData => eventos.first.dataHora;
}

class _ListaInteracoesPerfilWidgetState
    extends State<ListaInteracoesPerfilWidget> {
  int _subAba = 0; // 0 = Todos, 1 = Denúncias
  final Set<String> _expandidos = {};

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

  IconData _iconePorTipo(String tipo) {
    return switch (tipo) {
      'like' => Icons.thumb_up_alt_rounded,
      'deslike' => Icons.thumb_down_alt_rounded,
      'comentario' => Icons.chat_bubble_outline_rounded,
      'comentario_excluido' => Icons.speaker_notes_off_outlined,
      'salvo' => Icons.bookmark_rounded,
      'denuncia' => Icons.shield_outlined,
      'publicacao' => Icons.post_add_rounded,
      'publicacao_excluida' => Icons.delete_outline_rounded,
      _ => Icons.repeat_rounded,
    };
  }

  List<_GrupoInteracoesPost> _agruparPorPost() {
    final mapa = <String, List<RegistroInteracaoUsuario>>{};
    for (final item in widget.interacoes) {
      final chave =
          item.publicacaoId.isNotEmpty ? item.publicacaoId : item.id;
      mapa.putIfAbsent(chave, () => []).add(item);
    }

    final grupos = <_GrupoInteracoesPost>[];
    for (final entry in mapa.entries) {
      final eventos = entry.value
        ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
      final ref = eventos.first;
      grupos.add(
        _GrupoInteracoesPost(
          chave: entry.key,
          publicacao: ref.publicacao,
          alvoCpf: ref.alvoCpf,
          alvoNome: ref.alvoNome.isNotEmpty
              ? ref.alvoNome
              : 'Publicação na rede',
          alvoFoto: ref.alvoFoto,
          eventos: eventos,
        ),
      );
    }
    grupos.sort((a, b) => b.ultimaData.compareTo(a.ultimaData));
    return grupos;
  }

  Widget _buildMiniaturaPost(PublicacaoSocial? pub, IconData iconeFallback) {
    final theme = widget.theme;
    if (pub == null) return const SizedBox.shrink();
    final temMidia = pub.midias.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: temMidia
          ? FutureBuilder<String?>(
              future: TimelineService.resolverCaminhoMidia(
                pub.midias.first.caminhoRelativo,
              ),
              builder: (_, snap) {
                final caminho = snap.data;
                if (caminho != null && File(caminho).existsSync()) {
                  return Image.file(
                    File(caminho),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      iconeFallback,
                      size: 18,
                      color: theme.secondaryTextColor,
                    ),
                  );
                }
                return Icon(
                  iconeFallback,
                  size: 18,
                  color: theme.secondaryTextColor,
                );
              },
            )
          : Center(
              child: Icon(
                pub.texto.isNotEmpty
                    ? Icons.article_outlined
                    : iconeFallback,
                size: 20,
                color: theme.secondaryTextColor,
              ),
            ),
    );
  }

  Future<void> _abrirJanelaEventos(_GrupoInteracoesPost grupo) async {
    final theme = widget.theme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (grupo.publicacao != null) ...[
                      _buildMiniaturaPost(
                        grupo.publicacao,
                        _iconePorTipo(grupo.eventos.first.tipoAcao),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomePerfil.isNotEmpty
                                ? widget.nomePerfil
                                : grupo.alvoNome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            '${grupo.eventos.length} ${grupo.eventos.length == 1 ? 'evento registrado' : 'eventos registrados'}',
                            style: theme.getTextStyle(
                              fontSize: 11.5,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textColor),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: grupo.eventos.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 12,
                      color: theme.borderColor.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (_, idx) {
                      final ev = grupo.eventos[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _iconePorTipo(ev.tipoAcao),
                            size: 16,
                            color: ev.tipoAcao == 'comentario_excluido' ||
                                    ev.tipoAcao == 'publicacao_excluida'
                                ? theme.dangerColor
                                : theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ev.resumo,
                              style: theme.getTextStyle(
                                fontSize: 12.5,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatarDataHora(ev.dataHora),
                            style: theme.getTextStyle(
                              fontSize: 10.5,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (grupo.publicacao != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      DialogDetalhesPublicacao.mostrar(
                        context,
                        theme: theme,
                        publicacao: grupo.publicacao!,
                        usuarioLogado: widget.usuarioLogado,
                      );
                    },
                    child: const Text('Abrir publicação'),
                  ),
                ],
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
    final grupos = _agruparPorPost();
    final cpfPerfilLimpo = widget.cpfPerfil.replaceAll(RegExp(r'\D'), '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-abas minimalistas: Todos | Denúncias
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              _buildSubAbaMinimalista(
                theme: theme,
                titulo: 'Todos (${grupos.length})',
                selecionada: _subAba == 0,
                onTap: () => setState(() => _subAba = 0),
              ),
              const SizedBox(width: 16),
              _buildSubAbaMinimalista(
                theme: theme,
                titulo: 'Denúncias (${widget.denuncias.length})',
                selecionada: _subAba == 1,
                onTap: () => setState(() => _subAba = 1),
              ),
            ],
          ),
        ),

        if (_subAba == 1) ...[
          if (widget.denuncias.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma denúncia registrada para este perfil.',
            )
          else
            for (final d in widget.denuncias)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: theme.dangerColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.denuncianteCpf.replaceAll(
                                            RegExp(r'\D'),
                                            '',
                                          ) ==
                                          cpfPerfilLimpo
                                      ? 'Denúncia feita contra ${d.alvoNome}'
                                      : 'Denúncia recebida de ${d.denuncianteNome}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatarDataHora(d.criadaEm),
                                style: theme.getTextStyle(
                                  fontSize: 10.5,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.motivo,
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
        ] else if (grupos.isEmpty) ...[
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhuma interação pública registrada na rede ainda.',
          ),
        ] else ...[
          for (final grupo in grupos) _buildCardGrupo(grupo),
        ],
      ],
    );
  }

  Widget _buildCardGrupo(_GrupoInteracoesPost grupo) {
    final theme = widget.theme;
    final expandido = _expandidos.contains(grupo.chave);
    final eventosVisiveis =
        expandido ? grupo.eventos : grupo.eventos.take(2).toList();
    final temMais = grupo.eventos.length > 2;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _abrirJanelaEventos(grupo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (grupo.publicacao != null) ...[
              _buildMiniaturaPost(
                grupo.publicacao,
                _iconePorTipo(grupo.eventos.first.tipoAcao),
              ),
              const SizedBox(width: 10),
            ],
            if (widget.cpfPerfil.isNotEmpty || grupo.alvoCpf.isNotEmpty)
              AvatarComStoryWidget(
                theme: theme,
                cpf: widget.cpfPerfil.isNotEmpty
                    ? widget.cpfPerfil
                    : grupo.alvoCpf,
                nome: widget.nomePerfil.isNotEmpty
                    ? widget.nomePerfil
                    : grupo.alvoNome,
                foto: widget.fotoPerfil.isNotEmpty
                    ? widget.fotoPerfil
                    : grupo.alvoFoto,
                radius: 18,
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.borderColor.withValues(alpha: 0.25),
                child: Icon(
                  _iconePorTipo(grupo.eventos.first.tipoAcao),
                  color: theme.textColor,
                  size: 16,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.nomePerfil.isNotEmpty
                              ? widget.nomePerfil
                              : grupo.alvoNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatarDataHora(grupo.ultimaData),
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  for (final ev in eventosVisiveis)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              _iconePorTipo(ev.tipoAcao),
                              size: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ev.resumo,
                              maxLines: expandido ? null : 2,
                              overflow: expandido
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          if (ev.tipoAcao == 'marcacao' &&
                              ev.alvoCpf.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            AvatarComStoryWidget(
                              theme: theme,
                              cpf: ev.alvoCpf,
                              nome: ev.alvoNome,
                              foto: ev.alvoFoto,
                              radius: 9,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (temMais)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (expandido) {
                              _expandidos.remove(grupo.chave);
                            } else {
                              _expandidos.add(grupo.chave);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            expandido
                                ? 'Recolher eventos'
                                : 'Expandir log (+${grupo.eventos.length - 2})',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubAbaMinimalista({
    required AppTheme theme,
    required String titulo,
    required bool selecionada,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selecionada ? theme.textColor : Colors.transparent,
              width: 1.8,
            ),
          ),
        ),
        child: Text(
          titulo,
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: selecionada ? FontWeight.w600 : FontWeight.normal,
            color: selecionada ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
