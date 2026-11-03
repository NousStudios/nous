import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/texto_utils.dart';
import '../../../chat/models/conversa_chat.dart';
import '../../../chat/services/chat_service.dart';

/// Diálogo modal para pesquisa, adesão e gerenciamento de salas comunitárias do Nous.
class DialogExplorarSalasComunitarias extends StatefulWidget {
  final AppTheme theme;
  final String cpfLogado;
  final String nomeLogado;
  final String salaAtivaId;
  final Future<void> Function(ConversaChat topico) aoSelecionarOuAlterar;
  final Future<void> Function(String topicoId) aoExcluirSala;

  const DialogExplorarSalasComunitarias({
    super.key,
    required this.theme,
    required this.cpfLogado,
    required this.nomeLogado,
    required this.salaAtivaId,
    required this.aoSelecionarOuAlterar,
    required this.aoExcluirSala,
  });

  @override
  State<DialogExplorarSalasComunitarias> createState() => _DialogExplorarSalasComunitariasState();
}

class _DialogExplorarSalasComunitariasState extends State<DialogExplorarSalasComunitarias> {
  final TextEditingController _buscaCtrl = TextEditingController();
  List<ConversaChat> _todasSalas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarSalas();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarSalas() async {
    try {
      final salas = await ChatService.obterTodasSalasComunitarias();
      if (mounted) {
        setState(() {
          _todasSalas = salas;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarNaSala(ConversaChat sala) async {
    await ChatService.entrarTopicoComunidade(
      topicoId: sala.id,
      cpf: widget.cpfLogado,
      nomeUsuario: widget.nomeLogado,
    );
    if (mounted) {
      Navigator.pop(context);
      await widget.aoSelecionarOuAlterar(sala);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você entrou na sala "#${sala.titulo}"!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  Future<void> _sairDaSala(ConversaChat sala) async {
    await ChatService.sairTopicoComunidade(
      topicoId: sala.id,
      cpf: widget.cpfLogado,
      nomeUsuario: widget.nomeLogado,
    );
    await _carregarSalas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você saiu da sala "#${sala.titulo}".')),
      );
    }
  }

  void _confirmarExcluirSala(ConversaChat sala) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.theme.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: widget.theme.dangerColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Apagar Sala',
              style: widget.theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.theme.textColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja apagar permanentemente a sala "#${sala.titulo}" criada por você? Essa ação não pode ser desfeita.',
          style: widget.theme.getTextStyle(fontSize: 13, color: widget.theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: widget.theme.getTextStyle(color: widget.theme.secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.dangerColor),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.aoExcluirSala(sala.id);
              await _carregarSalas();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sala "#${sala.titulo}" apagada com sucesso.')),
                );
              }
            },
            child: Text(
              'Apagar',
              style: widget.theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
    final termo = _buscaCtrl.text.trim();
    final cpfNorm = ChatService.normalizarCpf(widget.cpfLogado);

    final filtradas = _todasSalas.where((s) {
      if (termo.isEmpty) return true;
      return TextoUtils.contemIgnorandoAcentos(s.titulo, termo) ||
          TextoUtils.contemIgnorandoAcentos(s.subtitulo, termo);
    }).toList();

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Icon(Icons.explore_outlined, color: theme.textColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Explorar Salas Comunitárias',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pesquise e participe de salas criadas por outros usuários. A sala #Geral é padrão.',
              style: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buscaCtrl,
              onChanged: (_) => setState(() {}),
              style: theme.getTextStyle(color: theme.textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Pesquisar pelo nome da sala...',
                hintStyle: theme.getTextStyle(color: theme.secondaryTextColor, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 18, color: theme.secondaryTextColor),
                filled: true,
                fillColor: theme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            if (_carregando)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (filtradas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma sala comunitária encontrada.',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtradas.length,
                  separatorBuilder: (_, _) => Divider(
                    color: theme.borderColor.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  itemBuilder: (ctx, index) {
                    final sala = filtradas[index];
                    final ehGeral = sala.id == ChatService.idTopicoGeral;
                    final participa = ehGeral ||
                        sala.participantesIds.contains('todos') ||
                        sala.participantesIds.any((p) => ChatService.normalizarCpf(p) == cpfNorm) ||
                        ChatService.normalizarCpf(sala.identificador) == cpfNorm;
                    final ehCriador = !ehGeral &&
                        ChatService.normalizarCpf(sala.identificador) == cpfNorm;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.buttonColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ehGeral ? Icons.home_filled : Icons.tag_rounded,
                              size: 18,
                              color: theme.buttonColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (!participa) {
                                  await _entrarNaSala(sala);
                                } else {
                                  Navigator.pop(context);
                                  await widget.aoSelecionarOuAlterar(sala);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          ehGeral ? '#Geral' : '#${sala.titulo}',
                                          style: theme.getTextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: theme.textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (ehGeral) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Padrão',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (ehCriador) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: theme.buttonColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Criador',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: theme.buttonColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sala.mensagens.isNotEmpty
                                        ? '${sala.mensagens.length} mensagens'
                                        : 'Nenhuma mensagem ainda',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botão Apagar para o Criador da sala
                          if (ehCriador)
                            IconButton(
                              tooltip: 'Apagar sala comunitária',
                              icon: Icon(Icons.delete_outline_rounded, color: theme.dangerColor, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _confirmarExcluirSala(sala),
                            ),

                          // Botão Participar / Sair
                          if (!ehGeral)
                            if (participa)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: theme.borderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _sairDaSala(sala),
                                child: Text('Sair', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.buttonColor,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _entrarNaSala(sala),
                                child: Text(
                                  'Entrar',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.buttonTextColor,
                                  ),
                                ),
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
    );
  }
}
