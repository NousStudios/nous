import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';

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
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.add_comment_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Criar Novo Tópico',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Defina um tópico para delimitar a conversa e não atrapalhar outros grupos.',
                style: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: theme.getTextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Ex: Projetos, Suporte, Anúncios...',
                  hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () async {
                final titulo = controller.text.trim();
                if (titulo.isEmpty) return;
                Navigator.pop(ctx);
                final novoTopico = await ChatService.criarOuObterTopicoComunidadeNous(
                  titulo,
                  null,
                  widget.cpfLogado,
                );
                await _carregarTopicosEMensagens();
                _selecionarTopico(novoTopico);
              },
              child: Text(
                'Criar Tópico',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _dialogApagarTopicoAtivo(AppTheme theme) {
    if (_conversaIdAtiva == ChatService.idTopicoGeral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A sala #Geral é padrão e não pode ser apagada.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: theme.dangerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Apagar Sala Comunitária',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja apagar permanentemente a sala "$_tituloTopicoAtivo" para todos os usuários da comunidade?',
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
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
              child: Text(
                'Apagar Sala',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _dialogSairTopicoAtivo(AppTheme theme) {
    if (_conversaIdAtiva == ChatService.idTopicoGeral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A sala #Geral é padrão da comunidade.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: theme.dangerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sair da Sala',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja sair da sala "$_tituloTopicoAtivo"? Ela será removida da sua barra de tópicos.',
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
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
              child: Text(
                'Sair da Sala',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _dialogExplorarSalas(AppTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => _DialogExplorarSalasComunitarias(
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
    if (_conversaIdAtiva == ChatService.idTopicoGeral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O tópico "Geral" é fixo da comunidade e não pode ser renomeado.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: _tituloTopicoAtivo);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Renomear Tópico',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: theme.getTextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Novo nome do tópico...',
              hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
              filled: true,
              fillColor: theme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () async {
                final novoNome = controller.text.trim();
                if (novoNome.isEmpty || novoNome == _tituloTopicoAtivo) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                await ChatService.renomearTopicoComunidadeNous(_conversaIdAtiva, novoNome);
                await _carregarTopicosEMensagens(manterTopicoAtual: true);
              },
              child: Text(
                'Salvar Nome',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
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

        // Barra de Tópicos Paralelos
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._topicos.map((topico) {
                  final ehAtivo = topico.id == _conversaIdAtiva;
                  final nome = topico.titulo.isNotEmpty ? topico.titulo : 'Geral';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _selecionarTopico(topico),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: ehAtivo
                              ? theme.buttonColor
                              : theme.cardBackgroundColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: ehAtivo
                                ? theme.buttonColor
                                : theme.borderColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              size: 14,
                              color: ehAtivo ? theme.buttonTextColor : theme.secondaryTextColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              nome,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: ehAtivo ? FontWeight.bold : FontWeight.w500,
                                color: ehAtivo ? theme.buttonTextColor : theme.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  onTap: () => _dialogCriarNovoTopico(theme),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.7),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 15, color: theme.textColor),
                        const SizedBox(width: 4),
                        Text(
                          'Novo Tópico',
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
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _dialogExplorarSalas(theme),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_outlined, size: 15, color: theme.textColor),
                        const SizedBox(width: 4),
                        Text(
                          'Explorar Salas',
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
              ],
            ),
          ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      size: 20,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 8),

                    // Título centralizado no meio do espaço do chat, editável
                    Expanded(
                      child: Center(
                        child: InkWell(
                          onTap: () => _dialogRenomearTopicoAtivo(theme),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _tituloTopicoAtivo,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 15,
                                  color: theme.secondaryTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botão Apagar ou Sair da Sala Comunitária ativa se não for #Geral
                    if (_conversaIdAtiva != ChatService.idTopicoGeral) ...[
                      Builder(
                        builder: (context) {
                          final topicoAtivo = _topicos.firstWhere(
                            (t) => t.id == _conversaIdAtiva,
                            orElse: () => ConversaChat(
                              id: _conversaIdAtiva,
                              titulo: _tituloTopicoAtivo,
                              identificador: 'todos',
                              dataHoraUltimaMensagem: DateTime.now(),
                            ),
                          );
                          final ehCriador = ChatService.normalizarCpf(topicoAtivo.identificador) ==
                              ChatService.normalizarCpf(widget.cpfLogado);

                          if (ehCriador) {
                            return IconButton(
                              tooltip: 'Apagar esta sala comunitária',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.dangerColor,
                                size: 20,
                              ),
                              onPressed: () => _dialogApagarTopicoAtivo(theme),
                            );
                          } else {
                            return IconButton(
                              tooltip: 'Sair desta sala comunitária',
                              icon: Icon(
                                Icons.logout_rounded,
                                color: theme.secondaryTextColor,
                                size: 20,
                              ),
                              onPressed: () => _dialogSairTopicoAtivo(theme),
                            );
                          }
                        },
                      ),
                    ],

                    // Ícone para ativar/desativar notificação deste tópico
                    IconButton(
                      tooltip: _notificarTopicoAtivo
                          ? 'Notificações ativadas para este tópico (clique para silenciar)'
                          : 'Notificações silenciadas para este tópico (clique para ativar)',
                      icon: Icon(
                        _notificarTopicoAtivo
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        color: _notificarTopicoAtivo
                            ? const Color(0xFF4CAF50)
                            : theme.secondaryTextColor,
                        size: 20,
                      ),
                      onPressed: _alternarNotificacaoTopico,
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
                              return _buildBolhaMensagem(theme, msg, ehMinha);
                            },
                          ),
              ),

              // Painel de Gravação de Voz ou Barra de Envio
              ValueListenableBuilder<bool>(
                valueListenable: GravadorAudioService.instancia.gravandoNotifier,
                builder: (context, gravando, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: gravando
                        ? Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: theme.dangerColor,
                                  size: 24,
                                ),
                                tooltip: 'Cancelar gravação',
                                onPressed: _cancelarGravacaoVoz,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Gravando áudio...',
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        color: theme.textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    ValueListenableBuilder<Duration>(
                                      valueListenable:
                                          GravadorAudioService.instancia.duracaoNotifier,
                                      builder: (context, duracao, _) {
                                        final min = duracao.inMinutes;
                                        final seg = duracao.inSeconds % 60;
                                        return Text(
                                          '$min:${seg.toString().padLeft(2, '0')}',
                                          style: theme.getTextStyle(
                                            fontSize: 13,
                                            color: theme.secondaryTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _finalizarEEnviarGravacaoVoz,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.buttonColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: theme.buttonTextColor,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Câmera / Tirar foto',
                                icon: Icon(
                                  Icons.camera_alt_rounded,
                                  color: theme.textColor,
                                  size: 22,
                                ),
                                onPressed: _capturarFotoCamera,
                              ),
                              IconButton(
                                tooltip: 'Anexar imagem ou arquivo',
                                icon: Icon(
                                  Icons.attach_file_rounded,
                                  color: theme.textColor,
                                  size: 22,
                                ),
                                onPressed: () => _abrirMenuAnexo(theme),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 42,
                                    maxHeight: 110,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: theme.backgroundColor.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(21),
                                    border: Border.all(
                                      color: theme.borderColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _mensagemController,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    minLines: 1,
                                    maxLines: 4,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.textColor,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (Platform.isAndroid || Platform.isIOS)
                                        ? null
                                        : (_) => _enviarTexto(),
                                    decoration: InputDecoration(
                                      hintText: 'Escreva uma mensagem...',
                                      hintStyle: theme.getTextStyle(
                                        fontSize: 12,
                                        color: theme.secondaryTextColor,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _mensagemController.text.trim().isNotEmpty
                                    ? _enviarTexto
                                    : _iniciarGravacaoVoz,
                                borderRadius: BorderRadius.circular(21),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: theme.buttonColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _mensagemController.text.trim().isNotEmpty
                                        ? Icons.send_rounded
                                        : Icons.mic_rounded,
                                    size: 19,
                                    color: theme.buttonTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarMenuMensagem(AppTheme theme, MensagemChat msg) {
    final agora = DateTime.now();
    final diferencaSegundos = agora.difference(msg.dataHora).inSeconds;
    final ehMinha = msg.enviadaPorMim ||
        ChatService.normalizarCpf(msg.remetenteId) == ChatService.normalizarCpf(widget.cpfLogado);
    final podeExcluir = ehMinha && diferencaSegundos <= 60;
    final podeEditar = ehMinha && msg.tipo == 'texto';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Opções da Mensagem',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.texto.isNotEmpty) ...[
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: theme.textColor, size: 20),
                    title: Text('Copiar Texto', style: theme.getTextStyle(color: theme.textColor)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: msg.texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Texto copiado para a área de transferência.')),
                      );
                    },
                  ),
                  Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ],
                if (podeEditar) ...[
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: theme.textColor, size: 20),
                    title: Text('Editar', style: theme.getTextStyle(color: theme.textColor)),
                    subtitle: Text(
                      'Mantém o histórico de versões visível',
                      style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _dialogEditarMensagem(theme, msg);
                    },
                  ),
                  Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ],
                if (ehMinha) ...[
                  ListTile(
                    enabled: podeExcluir,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: podeExcluir
                          ? theme.dangerColor
                          : theme.secondaryTextColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    title: Text(
                      'Excluir para todos',
                      style: theme.getTextStyle(
                        color: podeExcluir
                            ? theme.dangerColor
                            : theme.secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                    subtitle: Text(
                      podeExcluir
                          ? 'Disponível por mais ${60 - diferencaSegundos}s'
                          : 'Exclusão permitida apenas até 1 minuto após o envio',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    onTap: podeExcluir
                        ? () {
                            Navigator.pop(ctx);
                            _confirmarExclusaoMensagem(theme, msg);
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _dialogEditarMensagem(AppTheme theme, MensagemChat msg) {
    final controller = TextEditingController(text: msg.texto);

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
            'Editar Mensagem',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            style: theme.getTextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Digite o novo texto...',
              hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
              filled: true,
              fillColor: theme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () async {
                final novoTexto = controller.text.trim();
                if (novoTexto.isEmpty || novoTexto == msg.texto) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                await ChatService.editarMensagem(msg.id, novoTexto);
                _carregarTopicosEMensagens(manterTopicoAtual: true);
              },
              child: Text(
                'Salvar Alteração',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarExclusaoMensagem(AppTheme theme, MensagemChat msg) {
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
            'Excluir para todos?',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Esta mensagem será apagada para todos os participantes do tópico.',
            style: theme.getTextStyle(fontSize: 13, color: theme.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                await ChatService.excluirMensagem(msg.id);
                _carregarTopicosEMensagens(manterTopicoAtual: true);
              },
              child: Text(
                'Excluir',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBolhaMensagem(AppTheme theme, MensagemChat msg, bool ehMinha) {
    final fotoResolvida = ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();
    final ehMinhaMsg = ehMinha ||
        ChatService.normalizarCpf(msg.remetenteId) == ChatService.normalizarCpf(widget.cpfLogado);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: ehMinhaMsg ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!ehMinhaMsg) ...[
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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onLongPress: () => _mostrarMenuMensagem(theme, msg),
              onSecondaryTap: () => _mostrarMenuMensagem(theme, msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ehMinhaMsg
                      ? theme.textColor.withValues(alpha: 0.15)
                      : theme.cardBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(ehMinhaMsg ? 12 : 2),
                    bottomRight: Radius.circular(ehMinhaMsg ? 2 : 12),
                  ),
                  border: Border.all(
                    color: ehMinhaMsg
                        ? theme.textColor.withValues(alpha: 0.4)
                        : theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      ehMinhaMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!ehMinhaMsg)
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
                    ] else if (msg.tipo == 'audio' && msg.caminhoAnexo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _CardAudioMensagem(
                        msg: msg,
                        theme: theme,
                        enviadaPorMim: ehMinhaMsg,
                      ),
                    ] else if (msg.tipo == 'arquivo' && msg.caminhoAnexo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildArquivoAnexo(theme, msg),
                    ],
                    if (msg.texto.isNotEmpty &&
                        msg.tipo != 'audio' &&
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
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.editada) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              '(editada)',
                              style: theme.getTextStyle(
                                fontSize: 9,
                                color: theme.secondaryTextColor.withValues(alpha: 0.9),
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatarHora(msg.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 9,
                            color: theme.secondaryTextColor.withValues(alpha: 0.7),
                          ),
                        ),
                        if (ehMinhaMsg) ...[
                          const SizedBox(width: 4),
                          if (msg.statusEnvio == 'pendente')
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: theme.secondaryTextColor.withValues(alpha: 0.7),
                            )
                          else if (msg.lida || msg.statusEnvio == 'lida')
                            const Icon(
                              Icons.done_all,
                              size: 13,
                              color: Color(0xFF34B7F1),
                            )
                          else if (msg.entregue || msg.statusEnvio == 'entregue')
                            Icon(
                              Icons.done_all,
                              size: 13,
                              color: theme.secondaryTextColor.withValues(alpha: 0.85),
                            )
                          else
                            Icon(
                              Icons.check,
                              size: 13,
                              color: theme.secondaryTextColor.withValues(alpha: 0.8),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ehMinhaMsg) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildImagemAnexo(AppTheme theme, String caminho) {
    final resolvido = ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
    final file = File(resolvido);

    if (!file.existsSync() && caminho.isNotEmpty && ClienteRedeLocal().conectado) {
      ClienteRedeLocal().baixarImagemRemota(caminho).then((baixado) {
        if (baixado.isNotEmpty && mounted) setState(() {});
      });
    }

    if (file.existsSync()) {
      return GestureDetector(
        onTap: () => VisualizadorImagemChatDialog.abrir(
          context,
          caminho: resolvido,
          theme: theme,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            height: 160,
            fit: BoxFit.cover,
          ),
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
            'Foto anexada (baixando...)',
            style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildArquivoAnexo(AppTheme theme, MensagemChat msg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, size: 20, color: theme.textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : 'Arquivo anexado',
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAudioMensagem extends StatelessWidget {
  final MensagemChat msg;
  final AppTheme theme;
  final bool enviadaPorMim;

  const _CardAudioMensagem({
    required this.msg,
    required this.theme,
    required this.enviadaPorMim,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DadosPlayerAudio>(
      valueListenable: PlayerAudioService.instancia.estadoNotifier,
      builder: (context, estado, _) {
        final ehEsteAudio = PlayerAudioService.instancia.ehMesmoAudio(
          msg.caminhoAnexo,
          estado.caminhoOriginal ?? estado.caminho,
        );

        final reproduzindo =
            ehEsteAudio && estado.estado == EstadoPlayerAudio.reproduzindo;
        final pausado =
            ehEsteAudio && estado.estado == EstadoPlayerAudio.pausado;

        final posicao = ehEsteAudio ? estado.posicao : Duration.zero;
        final duracao = ehEsteAudio && estado.duracaoEstimada > Duration.zero
            ? estado.duracaoEstimada
            : Duration.zero;

        String duracaoExibicao = '0:00';
        if (duracao > Duration.zero) {
          final m = duracao.inMinutes;
          final s = duracao.inSeconds % 60;
          duracaoExibicao = '$m:${s.toString().padLeft(2, '0')}';
        } else if (msg.texto.contains('(') && msg.texto.contains(')')) {
          duracaoExibicao =
              msg.texto.split('(').last.replaceAll(')', '').trim();
        }

        final posFormatada =
            '${posicao.inMinutes}:${(posicao.inSeconds % 60).toString().padLeft(2, '0')}';

        final maxMs =
            duracao.inMilliseconds > 0 ? duracao.inMilliseconds.toDouble() : 1.0;
        final valMs = posicao.inMilliseconds.toDouble().clamp(0.0, maxMs);

        return Container(
          constraints: const BoxConstraints(maxWidth: 275),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (reproduzindo) {
                    PlayerAudioService.instancia.pausar();
                  } else if (pausado) {
                    PlayerAudioService.instancia.retomar();
                  } else {
                    PlayerAudioService.instancia.tocar(msg.caminhoAnexo);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reproduzindo
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.buttonTextColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: theme.buttonColor,
                        inactiveTrackColor:
                            theme.borderColor.withValues(alpha: 0.6),
                        thumbColor: theme.buttonColor,
                      ),
                      child: Slider(
                        value: valMs,
                        min: 0.0,
                        max: maxMs,
                        onChanged: duracao.inMilliseconds > 0
                            ? (val) {
                                PlayerAudioService.instancia.buscarPosicao(
                                  Duration(milliseconds: val.toInt()),
                                );
                              }
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ehEsteAudio && (reproduzindo || pausado)
                                ? posFormatada
                                : duracaoExibicao,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 12,
                                color: enviadaPorMim
                                    ? const Color(0xFF34B7F1)
                                    : theme.buttonColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                duracaoExibicao,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialogExplorarSalasComunitarias extends StatefulWidget {
  final AppTheme theme;
  final String cpfLogado;
  final String nomeLogado;
  final String salaAtivaId;
  final Future<void> Function(ConversaChat topico) aoSelecionarOuAlterar;
  final Future<void> Function(String topicoId) aoExcluirSala;

  const _DialogExplorarSalasComunitarias({
    required this.theme,
    required this.cpfLogado,
    required this.nomeLogado,
    required this.salaAtivaId,
    required this.aoSelecionarOuAlterar,
    required this.aoExcluirSala,
  });

  @override
  State<_DialogExplorarSalasComunitarias> createState() => _DialogExplorarSalasComunitariasState();
}

class _DialogExplorarSalasComunitariasState extends State<_DialogExplorarSalasComunitarias> {
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
