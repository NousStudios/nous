import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class AbaGestaoNousWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final String cpfLogado;
  final String nomeLogado;
  final String fotoLogada;
  final List<MembroLoja> membros;
  final VoidCallback onAbrirStatusLoja;

  const AbaGestaoNousWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cpfLogado,
    required this.nomeLogado,
    this.fotoLogada = '',
    required this.membros,
    required this.onAbrirStatusLoja,
  });

  @override
  State<AbaGestaoNousWidget> createState() => _AbaGestaoNousWidgetState();
}

class _AbaGestaoNousWidgetState extends State<AbaGestaoNousWidget> {
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MensagemChat> _mensagens = [];
  bool _carregando = true;

  String get _conversaId => 'loja_${widget.lojaId}_geral';

  @override
  void initState() {
    super.initState();
    ServidorRedeLocal().terminaisConectados.addListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.addListener(_aoAtualizarPresencas);
    ChatService.alteracoesChatNotifier.addListener(_carregarMensagens);
    _carregarMensagens();
  }

  @override
  void dispose() {
    ServidorRedeLocal().terminaisConectados.removeListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.removeListener(_aoAtualizarPresencas);
    ChatService.alteracoesChatNotifier.removeListener(_carregarMensagens);
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _aoAtualizarPresencas() {
    if (mounted) setState(() {});
  }

  Future<void> _carregarMensagens() async {
    final msgs = await ChatService.carregarMensagens(
      _conversaId,
      idVisualizador: widget.cpfLogado,
    );
    if (!mounted) return;
    setState(() {
      _mensagens = msgs;
      _carregando = false;
    });
    _rolarParaFim();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _obterContagemOnline() {
    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();
    final cpfs = <String>{};

    if (servidor.ativo) {
      for (final p in servidor.obterTodasPresencas()) {
        final cpfNorm = p.cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (cpfNorm.isNotEmpty) cpfs.add(cpfNorm);
      }
    } else if (cliente.conectado) {
      for (final p in cliente.presencasAtivas.value) {
        final cpfNorm = p.cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (cpfNorm.isNotEmpty) cpfs.add(cpfNorm);
      }
    }

    final meuCpfNorm = widget.cpfLogado.replaceAll(RegExp(r'\D'), '');
    if (meuCpfNorm.isNotEmpty) {
      cpfs.add(meuCpfNorm);
    }

    return cpfs.isEmpty ? 1 : cpfs.length;
  }

  Future<void> _enviarTexto() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;

    _mensagemController.clear();

    final msg = MensagemChat(
      id: gerarIdUnico(),
      conversaId: _conversaId,
      remetenteId: widget.cpfLogado,
      remetenteNome: widget.nomeLogado.isNotEmpty ? widget.nomeLogado : 'Membro Nous',
      remetenteFoto: widget.fotoLogada,
      destinatarioId: 'todos',
      texto: texto,
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      tipo: 'texto',
    );

    await ChatService.salvarMensagem(msg);
    await _carregarMensagens();
  }

  Future<void> _enviarImagem() async {
    const typeGroup = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;

    final extensao = file.name.split('.').last.toLowerCase();
    final salvo = await ImagemService.salvarBytesImagemLocal(
      bytes,
      extensaoOriginal: extensao,
      nomeSugerido: file.name,
    );
    if (salvo == null || salvo.isEmpty) return;

    final msg = MensagemChat(
      id: gerarIdUnico(),
      conversaId: _conversaId,
      remetenteId: widget.cpfLogado,
      remetenteNome: widget.nomeLogado.isNotEmpty ? widget.nomeLogado : 'Membro Nous',
      remetenteFoto: widget.fotoLogada,
      destinatarioId: 'todos',
      texto: 'Foto compartilhada',
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      tipo: 'imagem',
      caminhoAnexo: salvo,
      nomeAnexo: file.name,
      tamanhoAnexo: bytes.length,
    );

    await ChatService.salvarMensagem(msg);
    await _carregarMensagens();
  }

  String _formatarHora(DateTime d) {
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final onlineCount = _obterContagemOnline();
    final textoOnline = onlineCount == 1 ? '1 membro online' : '$onlineCount membros online';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão Status da Loja
        InkWell(
          onTap: widget.onAbrirStatusLoja,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status da Loja',
                        style: theme.getTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            textoOnline,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Chat Geral da Comunidade Nous
        Container(
          height: 480,
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho do Chat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Geral da Comunidade',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            'Canal de comunicação aberto entre todos os membros',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de mensagens
              Expanded(
                child: _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : _mensagens.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 36,
                                    color: theme.secondaryTextColor.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Nenhuma mensagem ainda no Chat Geral.',
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Envie uma mensagem para todos os membros da comunidade Nous.',
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _mensagens.length,
                            itemBuilder: (context, index) {
                              final msg = _mensagens[index];
                              final ehMinha = msg.enviadaPorMim;
                              return _buildBolhaMensagem(theme, msg, ehMinha);
                            },
                          ),
              ),

              // Campo de entrada e botões
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Enviar imagem',
                      icon: Icon(
                        Icons.image_outlined,
                        color: theme.secondaryTextColor,
                        size: 20,
                      ),
                      onPressed: _enviarImagem,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _mensagemController,
                        style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                        decoration: InputDecoration(
                          hintText: 'Escreva uma mensagem para a comunidade...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                          filled: true,
                          fillColor: theme.backgroundColor.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.textColor),
                          ),
                        ),
                        onSubmitted: (_) => _enviarTexto(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Enviar',
                      icon: Icon(
                        Icons.send_rounded,
                        color: theme.textColor,
                        size: 20,
                      ),
                      onPressed: _enviarTexto,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBolhaMensagem(AppTheme theme, MensagemChat msg, bool ehMinha) {
    final fotoResolvida = ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: ehMinha ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!ehMinha) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.borderColor.withValues(alpha: 0.3),
              backgroundImage: temFoto ? FileImage(File(fotoResolvida)) : null,
              child: !temFoto
                  ? Icon(Icons.person, size: 16, color: theme.textColor)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ehMinha
                    ? theme.textColor.withValues(alpha: 0.15)
                    : theme.cardBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(ehMinha ? 12 : 2),
                  bottomRight: Radius.circular(ehMinha ? 2 : 12),
                ),
                border: Border.all(
                  color: ehMinha
                      ? theme.textColor.withValues(alpha: 0.4)
                      : theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    ehMinha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!ehMinha)
                    Text(
                      msg.remetenteNome.isNotEmpty ? msg.remetenteNome : 'Membro',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  if (msg.tipo == 'imagem' && msg.caminhoAnexo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildImagemAnexo(theme, msg.caminhoAnexo),
                  ],
                  if (msg.texto.isNotEmpty &&
                      (msg.tipo != 'imagem' || msg.texto != 'Foto compartilhada')) ...[
                    const SizedBox(height: 2),
                    Text(
                      msg.texto,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _formatarHora(msg.dataHora),
                    style: theme.getTextStyle(
                      fontSize: 9,
                      color: theme.secondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (ehMinha) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildImagemAnexo(AppTheme theme, String caminho) {
    final resolvido = ImagemService.resolverCaminhoExistente(caminho);
    if (resolvido != null && File(resolvido).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(resolvido),
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 16, color: theme.secondaryTextColor),
          const SizedBox(width: 6),
          Text(
            'Foto anexada',
            style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
