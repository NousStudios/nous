import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_explorar_salas_comunitarias.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/barra_envio_mensagem_gestao.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/barra_topicos_comunitarios_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/bolha_mensagem_gestao.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/cabecalho_chat_gestao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/dialogs_topicos_gestao.dart';

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
  final ImagePicker _picker = ImagePicker();

  List<ConversaChat> _topicos = [];
  String _conversaIdAtiva = ChatService.idTopicoGeral;
  String _tituloTopicoAtivo = 'Geral';
  bool _notificarTopicoAtivo = true;

  List<MensagemChat> _mensagens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    ServidorRedeLocal().terminaisConectados.addListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.addListener(_aoAtualizarPresencas);
    ChatService.alteracoesChatNotifier.addListener(_aoAlterarChat);
    _carregarTopicosEMensagens();
  }

  @override
  void dispose() {
    ServidorRedeLocal().terminaisConectados.removeListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.removeListener(_aoAtualizarPresencas);
    ChatService.alteracoesChatNotifier.removeListener(_aoAlterarChat);
    GravadorAudioService.instancia.cancelarGravacao();
    PlayerAudioService.instancia.parar();
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _aoAtualizarPresencas() {
    if (mounted) setState(() {});
  }

  void _aoAlterarChat() {
    _carregarTopicosEMensagens(manterTopicoAtual: true);
  }

  Future<void> _carregarTopicosEMensagens({bool manterTopicoAtual = false}) async {
    final topicos = await ChatService.obterTopicosComunidadeNous(cpfUsuario: widget.cpfLogado);
    if (!mounted) return;

    String topicoSelecionado = _conversaIdAtiva;
    if (!manterTopicoAtual || !topicos.any((t) => t.id == topicoSelecionado)) {
      topicoSelecionado = topicos.isNotEmpty ? topicos.first.id : ChatService.idTopicoGeral;
    }

    final topicoAtual = topicos.firstWhere(
      (t) => t.id == topicoSelecionado,
      orElse: () => ConversaChat(
        id: ChatService.idTopicoGeral,
        titulo: 'Geral',
        identificador: 'comunidade_nous_geral',
        dataHoraUltimaMensagem: DateTime.now(),
        lojaId: ChatService.idLojaColetivaNous,
        ehGrupo: true,
      ),
    );

    final deveNotif = await ChatService.deveNotificarConversa(topicoSelecionado);

    final msgs = await ChatService.carregarMensagens(
      topicoSelecionado,
      idVisualizador: widget.cpfLogado,
    );
    await ChatService.marcarMensagensDaLojaComoLidas(
      ChatService.idLojaColetivaNous,
      widget.cpfLogado,
    );

    if (!mounted) return;
    setState(() {
      _topicos = topicos;
      _conversaIdAtiva = topicoSelecionado;
      _tituloTopicoAtivo = topicoAtual.titulo.isNotEmpty ? topicoAtual.titulo : 'Geral';
      _notificarTopicoAtivo = deveNotif;
      _mensagens = msgs;
      _carregando = false;
    });
    _rolarParaFim();
  }

  Future<void> _selecionarTopico(ConversaChat topico) async {
    if (_conversaIdAtiva == topico.id) return;
    setState(() {
      _conversaIdAtiva = topico.id;
      _tituloTopicoAtivo = topico.titulo.isNotEmpty ? topico.titulo : 'Geral';
      _carregando = true;
    });

    final deveNotif = await ChatService.deveNotificarConversa(topico.id);
    final msgs = await ChatService.carregarMensagens(
      topico.id,
      idVisualizador: widget.cpfLogado,
    );
    await ChatService.marcarMensagensDaLojaComoLidas(
      ChatService.idLojaColetivaNous,
      widget.cpfLogado,
    );

    if (!mounted) return;
    setState(() {
      _notificarTopicoAtivo = deveNotif;
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
      conversaId: _conversaIdAtiva,
      remetenteId: widget.cpfLogado,
      remetenteNome: widget.nomeLogado.isNotEmpty ? widget.nomeLogado : 'Membro Nous',
      remetenteFoto: widget.fotoLogada,
      destinatarioId: 'todos',
      texto: texto,
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      tipo: 'texto',
      statusEnvio: 'pendente',
    );

    setState(() {
      _mensagens.add(msg);
    });
    _rolarParaFim();

    ChatService.enviarMensagemInstantanea(msg).then((msgSalva) {
      if (mounted) {
        setState(() {
          final idx = _mensagens.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _mensagens[idx] = msgSalva;
          }
        });
      }
    });
  }

  Future<void> _capturarFotoCamera() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return;

      final ext = xfile.name.split('.').last.toLowerCase();
      final salvo = await ImagemService.salvarBytesImagemLocal(
        bytes,
        extensaoOriginal: ext.isEmpty ? 'jpg' : ext,
        nomeSugerido: xfile.name,
      );
      if (salvo == null || salvo.isEmpty) return;

      await _enviarMensagemAnexo(
        tipo: 'imagem',
        caminho: salvo,
        nome: xfile.name,
        tamanho: bytes.length,
        texto: 'Foto compartilhada',
      );
    } catch (e) {
      debugPrint('[AbaGestaoNous] Erro ao capturar foto da câmera: $e');
    }
  }

  Future<void> _selecionarImagemGaleria() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      if (bytes.isEmpty) return;

      final ext = xfile.name.split('.').last.toLowerCase();
      final salvo = await ImagemService.salvarBytesImagemLocal(
        bytes,
        extensaoOriginal: ext.isEmpty ? 'jpg' : ext,
        nomeSugerido: xfile.name,
      );
      if (salvo == null || salvo.isEmpty) return;

      await _enviarMensagemAnexo(
        tipo: 'imagem',
        caminho: salvo,
        nome: xfile.name,
        tamanho: bytes.length,
        texto: 'Foto compartilhada',
      );
    } catch (e) {
      debugPrint('[AbaGestaoNous] Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _anexarArquivo() async {
    try {
      final file = await openFile();
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final ext = file.name.split('.').last.toLowerCase();
      final salvo = await ImagemService.salvarBytesImagemLocal(
        bytes,
        extensaoOriginal: ext,
        nomeSugerido: file.name,
      );
      if (salvo == null || salvo.isEmpty) return;

      final ehImg = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
      await _enviarMensagemAnexo(
        tipo: ehImg ? 'imagem' : 'arquivo',
        caminho: salvo,
        nome: file.name,
        tamanho: bytes.length,
        texto: ehImg ? 'Foto compartilhada' : file.name,
      );
    } catch (e) {
      debugPrint('[AbaGestaoNous] Erro ao anexar arquivo: $e');
    }
  }

  Future<void> _enviarMensagemAnexo({
    required String tipo,
    required String caminho,
    required String nome,
    required int tamanho,
    required String texto,
  }) async {
    final msg = MensagemChat(
      id: gerarIdUnico(),
      conversaId: _conversaIdAtiva,
      remetenteId: widget.cpfLogado,
      remetenteNome: widget.nomeLogado.isNotEmpty ? widget.nomeLogado : 'Membro Nous',
      remetenteFoto: widget.fotoLogada,
      destinatarioId: 'todos',
      texto: texto,
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      tipo: tipo,
      caminhoAnexo: caminho,
      nomeAnexo: nome,
      tamanhoAnexo: tamanho,
      statusEnvio: 'pendente',
    );

    setState(() {
      _mensagens.add(msg);
    });
    _rolarParaFim();

    ChatService.enviarMensagemInstantanea(msg).then((msgSalva) {
      if (mounted) {
        setState(() {
          final idx = _mensagens.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _mensagens[idx] = msgSalva;
          }
        });
      }
    });
  }

  Future<void> _iniciarGravacaoVoz() async {
    final sucesso = await GravadorAudioService.instancia.iniciarGravacao();
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de microfone não concedida ou dispositivo de áudio indisponível.',
          ),
        ),
      );
    }
  }

  Future<void> _cancelarGravacaoVoz() async {
    await GravadorAudioService.instancia.cancelarGravacao();
  }

  Future<void> _finalizarEEnviarGravacaoVoz() async {
    final gravado = await GravadorAudioService.instancia.finalizarGravacao();
    if (gravado == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gravação muito curta ou descartada.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final tamanho = await File(gravado.caminho).length();
    final duracaoSegundos = gravado.duracao.inSeconds;
    final minutos = duracaoSegundos ~/ 60;
    final segundos = duracaoSegundos % 60;
    final duracaoTexto = '$minutos:${segundos.toString().padLeft(2, '0')}';

    await _enviarMensagemAnexo(
      tipo: 'audio',
      caminho: gravado.caminho,
      nome: p.basename(gravado.caminho),
      tamanho: tamanho,
      texto: 'Mensagem de voz ($duracaoTexto)',
    );
  }

  void _abrirMenuAnexo(AppTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Compartilhar na Comunidade',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt_rounded, color: theme.textColor, size: 22),
                  title: Text('Câmera (Tirar Foto)', style: theme.getTextStyle(color: theme.textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturarFotoCamera();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: theme.textColor, size: 22),
                  title: Text('Galeria de Imagens', style: theme.getTextStyle(color: theme.textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _selecionarImagemGaleria();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file_outlined, color: theme.textColor, size: 22),
                  title: Text('Documento / Arquivo', style: theme.getTextStyle(color: theme.textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _anexarArquivo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dialogCriarNovoTopico(AppTheme theme) {
    DialogsTopicosGestao.dialogCriarNovoTopico(
      context: context,
      theme: theme,
      cpfLogado: widget.cpfLogado,
      aoCriar: (novoTopico) async {
        await _carregarTopicosEMensagens();
        _selecionarTopico(novoTopico);
      },
    );
  }

  void _dialogApagarTopicoAtivo(AppTheme theme) {
    DialogsTopicosGestao.dialogApagarTopicoAtivo(
      context: context,
      theme: theme,
      conversaIdAtiva: _conversaIdAtiva,
      tituloTopicoAtivo: _tituloTopicoAtivo,
      aoConfirmarApagar: () async {
        final idApagar = _conversaIdAtiva;
        await ChatService.excluirConversaLocal(idApagar);
        _conversaIdAtiva = ChatService.idTopicoGeral;
        await _carregarTopicosEMensagens(manterTopicoAtual: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sala "$_tituloTopicoAtivo" apagada com sucesso.')),
          );
        }
      },
    );
  }

  void _dialogSairTopicoAtivo(AppTheme theme) {
    DialogsTopicosGestao.dialogSairTopicoAtivo(
      context: context,
      theme: theme,
      conversaIdAtiva: _conversaIdAtiva,
      tituloTopicoAtivo: _tituloTopicoAtivo,
      cpfLogado: widget.cpfLogado,
      nomeLogado: widget.nomeLogado,
      aoConfirmarSair: () async {
        final idSair = _conversaIdAtiva;
        await ChatService.sairTopicoComunidade(
          topicoId: idSair,
          cpf: widget.cpfLogado,
          nomeUsuario: widget.nomeLogado,
        );
        _conversaIdAtiva = ChatService.idTopicoGeral;
        await _carregarTopicosEMensagens(manterTopicoAtual: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Você saiu da sala "$_tituloTopicoAtivo".')),
          );
        }
      },
    );
  }

  void _dialogExplorarSalas(AppTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => DialogExplorarSalasComunitarias(
        theme: theme,
        cpfLogado: widget.cpfLogado,
        nomeLogado: widget.nomeLogado,
        salaAtivaId: _conversaIdAtiva,
        aoSelecionarOuAlterar: (topico) async {
          await _carregarTopicosEMensagens(manterTopicoAtual: false);
          _selecionarTopico(topico);
        },
        aoExcluirSala: (topicoId) async {
          await ChatService.excluirConversaLocal(topicoId);
          if (_conversaIdAtiva == topicoId) {
            _conversaIdAtiva = ChatService.idTopicoGeral;
          }
          await _carregarTopicosEMensagens(manterTopicoAtual: false);
        },
      ),
    );
  }

  void _dialogRenomearTopicoAtivo(AppTheme theme) {
    DialogsTopicosGestao.dialogRenomearTopicoAtivo(
      context: context,
      theme: theme,
      conversaIdAtiva: _conversaIdAtiva,
      tituloTopicoAtivo: _tituloTopicoAtivo,
      aoConfirmarRenomear: (novoNome) async {
        await ChatService.renomearTopicoComunidadeNous(_conversaIdAtiva, novoNome);
        await _carregarTopicosEMensagens(manterTopicoAtual: true);
      },
    );
  }

  Future<void> _alternarNotificacaoTopico() async {
    final novoEstado = !_notificarTopicoAtivo;
    await ChatService.alternarNotificacaoConversa(_conversaIdAtiva, novoEstado);
    setState(() {
      _notificarTopicoAtivo = novoEstado;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoEstado
                ? 'Notificações ativadas para o tópico "$_tituloTopicoAtivo".'
                : 'Notificações silenciadas para o tópico "$_tituloTopicoAtivo".',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

        // Barra de Tópicos Paralelos
        BarraTopicosComunitariosWidget(
          theme: theme,
          topicos: _topicos,
          conversaIdAtiva: _conversaIdAtiva,
          onSelecionarTopico: _selecionarTopico,
          onCriarNovoTopico: () => _dialogCriarNovoTopico(theme),
          onExplorarSalas: () => _dialogExplorarSalas(theme),
        ),

        const SizedBox(height: 10),

        // Chat da Comunidade Nous com Tópico Selecionado
        Container(
          height: 520,
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho do Chat: Título do Tópico Centralizado e Editável + Sino de Notificação + Sair/Apagar
              CabecalhoChatGestaoWidget(
                theme: theme,
                conversaIdAtiva: _conversaIdAtiva,
                tituloTopicoAtivo: _tituloTopicoAtivo,
                topicos: _topicos,
                cpfLogado: widget.cpfLogado,
                notificarTopicoAtivo: _notificarTopicoAtivo,
                onRenomearTopico: () => _dialogRenomearTopicoAtivo(theme),
                onApagarTopico: () => _dialogApagarTopicoAtivo(theme),
                onSairTopico: () => _dialogSairTopicoAtivo(theme),
                onAlternarNotificacao: _alternarNotificacaoTopico,
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
                                    'Nenhuma mensagem ainda no tópico "$_tituloTopicoAtivo".',
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Inicie a conversa enviando uma mensagem, foto ou áudio.',
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
                              return BolhaMensagemGestao(
                                theme: theme,
                                msg: msg,
                                ehMinha: ehMinha,
                                cpfLogado: widget.cpfLogado,
                                onAtualizarChat: () =>
                                    _carregarTopicosEMensagens(manterTopicoAtual: true),
                              );
                            },
                          ),
              ),

              // Painel de Gravação de Voz ou Barra de Envio
              BarraEnvioMensagemGestao(
                theme: theme,
                controller: _mensagemController,
                onEnviarTexto: _enviarTexto,
                onIniciarGravacaoVoz: _iniciarGravacaoVoz,
                onFinalizarEEnviarGravacaoVoz: _finalizarEEnviarGravacaoVoz,
                onCancelarGravacaoVoz: _cancelarGravacaoVoz,
                onCapturarFotoCamera: _capturarFotoCamera,
                onAbrirMenuAnexo: () => _abrirMenuAnexo(theme),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
