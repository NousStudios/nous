import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import '../../../pdv/services/imagem_service.dart';
import '../../models/conversa_chat.dart';
import '../../models/mensagem_chat.dart';
import '../../services/chat_service.dart';

class VisualizadorImagemChatDialog extends StatefulWidget {
  final String caminhoImagem;
  final AppTheme theme;

  const VisualizadorImagemChatDialog({
    super.key,
    required this.caminhoImagem,
    required this.theme,
  });

  static Future<void> abrir(
    BuildContext context, {
    required String caminho,
    required AppTheme theme,
  }) async {
    final resolvido = ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
    final file = File(resolvido);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de imagem não encontrado no disco local.')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => VisualizadorImagemChatDialog(
        caminhoImagem: resolvido,
        theme: theme,
      ),
    );
  }

  @override
  State<VisualizadorImagemChatDialog> createState() => _VisualizadorImagemChatDialogState();
}

class _VisualizadorImagemChatDialogState extends State<VisualizadorImagemChatDialog> {
  bool _salvando = false;

  Future<void> _baixarImagem() async {
    if (_salvando) return;
    setState(() => _salvando = true);

    try {
      final arquivoOriginal = File(widget.caminhoImagem);
      if (!await arquivoOriginal.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo de imagem não encontrado.')),
          );
        }
        return;
      }

      final ext = p.extension(widget.caminhoImagem).replaceAll('.', '');
      final extFinal = ext.isNotEmpty ? ext : 'jpg';
      final nomeSugerido = 'nous_img_${DateTime.now().millisecondsSinceEpoch}.$extFinal';

      String? caminhoSalvo;

      // 1. Tenta usar o file_selector (Desktop / navegadores)
      try {
        final grupo = XTypeGroup(label: 'Imagens', extensions: [extFinal]);
        final local = await getSaveLocation(
          suggestedName: nomeSugerido,
          acceptedTypeGroups: [grupo],
        );
        if (local != null) {
          caminhoSalvo = local.path;
        }
      } catch (_) {}

      // 2. Fallback para Android / iOS caso getSaveLocation não selecione
      if (caminhoSalvo == null) {
        Directory? dirDestino;
        if (Platform.isAndroid) {
          dirDestino = Directory('/storage/emulated/0/Download');
          if (!dirDestino.existsSync()) {
            dirDestino = await getExternalStorageDirectory();
          }
        }
        dirDestino ??= await getApplicationDocumentsDirectory();

        final pastaFinal = Directory('${dirDestino.path}/Nous_Imagens');
        if (!pastaFinal.existsSync()) {
          await pastaFinal.create(recursive: true);
        }
        caminhoSalvo = '${pastaFinal.path}/$nomeSugerido';
      }

      await arquivoOriginal.copy(caminhoSalvo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagem salva em: $caminhoSalvo'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar imagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirDialogEncaminhar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.theme.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModalEncaminharImagem(
        caminhoImagem: widget.caminhoImagem,
        theme: widget.theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final file = File(widget.caminhoImagem);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Área principal com InteractiveViewer (Zoom / Pan)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.5,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 64, color: theme.secondaryTextColor),
                        const SizedBox(height: 8),
                        Text('Não foi possível carregar a imagem', style: theme.getTextStyle(color: theme.secondaryTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra Superior com Ações: Fechar, Baixar, Encaminhar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
                    tooltip: 'Baixar imagem',
                    onPressed: _salvando ? null : _baixarImagem,
                  ),
                  IconButton(
                    icon: const Icon(Icons.reply_rounded, color: Colors.white, size: 22),
                    tooltip: 'Encaminhar imagem',
                    onPressed: _abrirDialogEncaminhar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalEncaminharImagem extends StatefulWidget {
  final String caminhoImagem;
  final AppTheme theme;

  const _ModalEncaminharImagem({
    required this.caminhoImagem,
    required this.theme,
  });

  @override
  State<_ModalEncaminharImagem> createState() => _ModalEncaminharImagemState();
}

class _ModalEncaminharImagemState extends State<_ModalEncaminharImagem> {
  final TextEditingController _buscaCtrl = TextEditingController();
  List<ConversaChat> _conversas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarConversas();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarConversas() async {
    try {
      final lista = await ChatService.obterTodasConversas();
      if (mounted) {
        setState(() {
          _conversas = lista;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _encaminharPara(ConversaChat conversa) async {
    try {
      final tamanho = await File(widget.caminhoImagem).length();
      final novaMsg = MensagemChat(
        id: 'msg_enc_${DateTime.now().millisecondsSinceEpoch}_${gerarIdUnico()}',
        conversaId: conversa.id,
        remetenteId: 'eu',
        remetenteNome: 'Você',
        destinatarioId: conversa.identificador,
        texto: '',
        tipo: 'imagem',
        caminhoAnexo: widget.caminhoImagem,
        nomeAnexo: p.basename(widget.caminhoImagem),
        tamanhoAnexo: tamanho,
        dataHora: DateTime.now(),
        statusEnvio: 'entregue',
        entregue: true,
      );

      await ChatService.salvarMensagem(novaMsg);
      ChatService.despacharConversaAtualizada(
        conversa.copyWith(
          ultimaMensagem: '📷 Foto',
          dataHoraUltimaMensagem: DateTime.now(),
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Fecha modal encaminhar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagem encaminhada para ${conversa.titulo} com sucesso!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao encaminhar imagem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final termo = _buscaCtrl.text.trim().toLowerCase();
    final filtradas = _conversas.where((c) {
      if (termo.isEmpty) return true;
      return c.titulo.toLowerCase().contains(termo) ||
          c.subtitulo.toLowerCase().contains(termo) ||
          c.identificador.toLowerCase().contains(termo);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.reply_rounded, color: theme.textColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Encaminhar para...',
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _buscaCtrl,
              onChanged: (_) => setState(() {}),
              style: theme.getTextStyle(color: theme.textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Pesquisar conversa ou contato...',
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
                    'Nenhuma conversa encontrada.',
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
                    final c = filtradas[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                        child: Icon(
                          c.ehGrupo
                              ? Icons.groups_outlined
                              : (c.ehLoja ? Icons.storefront_outlined : Icons.person_outline),
                          color: theme.textColor,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        c.titulo,
                        style: theme.getTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                      subtitle: Text(
                        c.subtitulo.isNotEmpty ? c.subtitulo : c.identificador,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      trailing: Icon(Icons.send_rounded, color: theme.buttonColor, size: 18),
                      onTap: () => _encaminharPara(c),
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
