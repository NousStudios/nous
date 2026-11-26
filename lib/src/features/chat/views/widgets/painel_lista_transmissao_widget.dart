import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/lista_transmissao.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_recursos_extras_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Painel completo de Listas de Transmissão para envio simultâneo de imagem para vários contatos Nous.
class PainelListaTransmissaoWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final bool desktop;

  const PainelListaTransmissaoWidget({
    super.key,
    required this.controller,
    required this.theme,
    this.desktop = true,
  });

  @override
  State<PainelListaTransmissaoWidget> createState() =>
      _PainelListaTransmissaoWidgetState();
}

class _PainelListaTransmissaoWidgetState
    extends State<PainelListaTransmissaoWidget> {
  List<ListaTransmissao> _listas = [];
  ListaTransmissao? _selecionada;
  bool _carregando = true;
  bool _enviando = false;
  String? _caminhoImagemSelecionada;
  final TextEditingController _legendaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarListas();
  }

  @override
  void dispose() {
    _legendaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarListas() async {
    final listas = await ChatRecursosExtrasService.listarListasTransmissao();
    if (!mounted) return;
    setState(() {
      _listas = listas;
      if (_selecionada != null) {
        _selecionada = listas.cast<ListaTransmissao?>().firstWhere(
              (l) => l?.id == _selecionada!.id,
              orElse: () => null,
            );
      }
      _carregando = false;
    });
  }

  List<ConversaChat> _obterContatosNousDisponiveis() {
    final map = <String, ConversaChat>{};
    for (final c in [
      ...widget.controller.conversas,
      ...widget.controller.todosContatosDisponiveis,
    ]) {
      if (!c.ehGrupo && !c.ehLoja && c.identificador.isNotEmpty) {
        map[ChatService.normalizarCpf(c.identificador)] = c;
      }
    }
    return map.values.toList()
      ..sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
  }

  Future<void> _criarOuEditarLista({ListaTransmissao? existente}) async {
    final theme = widget.theme;
    final contatos = _obterContatosNousDisponiveis();
    final nomeCtrl = TextEditingController(text: existente?.nome ?? '');
    final selecionados = Set<String>.from(
      existente?.destinatariosCpfs ?? const [],
    );

    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateLocal) => Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 460,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existente == null
                        ? 'Nova Lista de Transmissão'
                        : 'Editar Lista de Transmissão',
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nomeCtrl,
                    style: theme.getTextStyle(
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nome da lista (ex.: Clientes VIP, Equipe)',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                      filled: true,
                      fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecione os contatos (${selecionados.length}):',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: contatos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nenhum contato Nous encontrado.',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 13,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: contatos.length,
                            itemBuilder: (_, i) {
                              final c = contatos[i];
                              final cpf = ChatService.normalizarCpf(
                                c.identificador,
                              );
                              final marcado = selecionados.contains(cpf);
                              return CheckboxListTile(
                                dense: true,
                                value: marcado,
                                activeColor: theme.textColor,
                                checkColor: theme.backgroundColor,
                                title: Text(
                                  c.titulo,
                                  style: theme.getTextStyle(
                                    fontSize: 13,
                                    color: theme.textColor,
                                  ),
                                ),
                                onChanged: (v) {
                                  setStateLocal(() {
                                    if (v == true) {
                                      selecionados.add(cpf);
                                    } else {
                                      selecionados.remove(cpf);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
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
                          if (nomeCtrl.text.trim().isNotEmpty &&
                              selecionados.isNotEmpty) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (salvo == true) {
      final nova = ListaTransmissao(
        id: existente?.id ?? 'transm_${DateTime.now().millisecondsSinceEpoch}',
        nome: nomeCtrl.text.trim(),
        destinatariosCpfs: selecionados.toList(),
        criadoEm: existente?.criadoEm ?? DateTime.now(),
        atualizadoEm: DateTime.now(),
      );
      await ChatRecursosExtrasService.salvarListaTransmissao(nova);
      await _carregarListas();
      if (mounted) setState(() => _selecionada = nova);
    }
  }

  Future<void> _excluirLista(ListaTransmissao lista) async {
    final theme = widget.theme;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Excluir "${lista.nome}"?',
          style: theme.getTextStyle(color: theme.textColor),
        ),
        content: Text(
          'A lista será removida, mas as conversas individuais já enviadas serão mantidas.',
          style: theme.getTextStyle(color: theme.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (confirmou == true) {
      await ChatRecursosExtrasService.excluirListaTransmissao(lista.id);
      if (_selecionada?.id == lista.id) _selecionada = null;
      await _carregarListas();
    }
  }

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final salvo = await ChatMediaService.salvarArquivoAnexo(xfile.path);
      if (!mounted || salvo == null) return;
      setState(() => _caminhoImagemSelecionada = salvo);
    }
  }

  Future<void> _dispararTransmissao() async {
    final lista = _selecionada;
    if (lista == null || _enviando) return;
    final texto = _legendaCtrl.text.trim();
    final img = _caminhoImagemSelecionada;
    if (img == null && texto.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final meuCpf = ChatService.normalizarCpf(
      widget.controller.usuarioCpf ?? conta?.cpf ?? '',
    );
    if (meuCpf.isEmpty) return;

    setState(() => _enviando = true);
    int enviados = 0;

    try {
      for (final destCpfRaw in lista.destinatariosCpfs) {
        final destCpf = ChatService.normalizarCpf(destCpfRaw);
        if (destCpf.isEmpty || destCpf == meuCpf) continue;
        final menor = meuCpf.compareTo(destCpf) <= 0 ? meuCpf : destCpf;
        final maior = meuCpf.compareTo(destCpf) <= 0 ? destCpf : meuCpf;
        final convId = 'user_${menor}_user_$maior';

        await ChatService.obterOuCriarConversa(
          id: convId,
          titulo: widget.controller.usuariosNousPorCpf[destCpf]?.nomeExibicao ??
              'Contato Nous',
          identificador: destCpf,
          participantesIds: [meuCpf, destCpf],
        );

        final msg = MensagemChat(
          id: 'transm_${DateTime.now().microsecondsSinceEpoch}_$destCpf',
          conversaId: convId,
          remetenteId: meuCpf,
          remetenteNome:
              widget.controller.usuarioNome ?? conta?.nomeExibicao ?? 'Eu',
          remetenteFoto: widget.controller.usuarioFoto ?? conta?.foto ?? '',
          destinatarioId: destCpf,
          texto: texto,
          dataHora: DateTime.now(),
          enviadaPorMim: true,
          tipo: img != null ? 'imagem' : 'texto',
          caminhoAnexo: img ?? '',
          nomeAnexo: img != null ? img.split(Platform.pathSeparator).last : '',
          statusEnvio: 'enviada',
        );

        await ChatService.enviarMensagemInstantanea(msg);
        enviados++;
      }

      if (!mounted) return;
      setState(() {
        _caminhoImagemSelecionada = null;
        _legendaCtrl.clear();
        _enviando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transmissão enviada para $enviados contato(s) com sucesso!',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar transmissão: $e')),
        );
      }
    }
  }

  Widget _buildListaTransmissoes(AppTheme theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _listas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final l = _listas[i];
        final ativa = _selecionada?.id == l.id;
        return InkWell(
          onTap: () => setState(() => _selecionada = l),
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
                Icon(Icons.campaign_outlined, color: theme.textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.nome,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        '${l.destinatariosCpfs.length} destinatário(s)',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
                  onPressed: () => _criarOuEditarLista(existente: l),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: theme.dangerColor,
                  ),
                  onPressed: () => _excluirLista(l),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormularioEnvio(AppTheme theme) {
    if (_selecionada == null) {
      return Center(
        child: Text(
          'Selecione uma lista à esquerda para enviar',
          style: theme.getTextStyle(
            fontSize: 14,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.desktop) ...[
            InkWell(
              onTap: () => setState(() => _selecionada = null),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 18, color: theme.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'Voltar para todas as listas',
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
          Text(
            'Enviar para "${_selecionada!.nome}" (${_selecionada!.destinatariosCpfs.length} contatos)',
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _escolherImagem,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: _caminhoImagemSelecionada != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_caminhoImagemSelecionada!),
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique para selecionar a imagem',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _legendaCtrl,
            maxLines: 3,
            style: theme.getTextStyle(
              fontSize: 14,
              color: theme.textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Legenda ou mensagem opcional...',
              hintStyle: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
              filled: true,
              fillColor: theme.backgroundColor.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.textColor,
              foregroundColor: theme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _enviando ? null : _dispararTransmissao,
            icon: _enviando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.backgroundColor,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _enviando ? 'Enviando...' : 'Enviar para todos da lista',
            ),
          ),
        ],
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
              Icon(Icons.campaign_rounded, size: 22, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listas de Transmissão',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Envie a mesma imagem ou aviso para vários contatos Nous',
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
                onPressed: () => _criarOuEditarLista(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nova Lista'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? Center(
                  child: CircularProgressIndicator(color: theme.textColor),
                )
              : _listas.isEmpty
                  ? EstadoVazioContainer(
                      theme: theme,
                      mensagem:
                          'Nenhuma lista de transmissão criada.\nToque em "Nova Lista" para enviar imagens para vários contatos ao mesmo tempo.',
                    )
                  : (widget.desktop
                      ? Row(
                          children: [
                            SizedBox(
                              width: 280,
                              child: _buildListaTransmissoes(theme),
                            ),
                            VerticalDivider(
                              width: 1,
                              color: theme.borderColor.withValues(alpha: 0.4),
                            ),
                            Expanded(child: _buildFormularioEnvio(theme)),
                          ],
                        )
                      : (_selecionada == null
                          ? _buildListaTransmissoes(theme)
                          : _buildFormularioEnvio(theme))),
        ),
      ],
    );
  }
}
