import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Funções de diálogo para gestão de tópicos e salas comunitárias Nous.
class DialogsTopicosGestao {
  DialogsTopicosGestao._();

  static void dialogCriarNovoTopico({
    required BuildContext context,
    required AppTheme theme,
    required String cpfLogado,
    required void Function(ConversaChat novoTopico) aoCriar,
  }) {
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
                  cpfLogado,
                );
                aoCriar(novoTopico);
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

  static void dialogApagarTopicoAtivo({
    required BuildContext context,
    required AppTheme theme,
    required String conversaIdAtiva,
    required String tituloTopicoAtivo,
    required Future<void> Function() aoConfirmarApagar,
  }) {
    if (conversaIdAtiva == ChatService.idTopicoGeral) {
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
            'Deseja apagar permanentemente a sala "$tituloTopicoAtivo" para todos os usuários da comunidade?',
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
                await aoConfirmarApagar();
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

  static void dialogSairTopicoAtivo({
    required BuildContext context,
    required AppTheme theme,
    required String conversaIdAtiva,
    required String tituloTopicoAtivo,
    required String cpfLogado,
    required String nomeLogado,
    required Future<void> Function() aoConfirmarSair,
  }) {
    if (conversaIdAtiva == ChatService.idTopicoGeral) {
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
            'Deseja sair da sala "$tituloTopicoAtivo"? Ela será removida da sua barra de tópicos.',
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
                await aoConfirmarSair();
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

  static void dialogRenomearTopicoAtivo({
    required BuildContext context,
    required AppTheme theme,
    required String conversaIdAtiva,
    required String tituloTopicoAtivo,
    required Future<void> Function(String novoNome) aoConfirmarRenomear,
  }) {
    if (conversaIdAtiva == ChatService.idTopicoGeral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O tópico "Geral" é fixo da comunidade e não pode ser renomeado.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: tituloTopicoAtivo);
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
                if (novoNome.isEmpty || novoNome == tituloTopicoAtivo) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                await aoConfirmarRenomear(novoNome);
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

  static void dialogMenuAnexos({
    required BuildContext context,
    required AppTheme theme,
    required VoidCallback onCapturarFotoCamera,
    required VoidCallback onSelecionarImagemGaleria,
    required VoidCallback onAnexarArquivo,
  }) {
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
                    onCapturarFotoCamera();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: theme.textColor, size: 22),
                  title: Text('Galeria de Imagens', style: theme.getTextStyle(color: theme.textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelecionarImagemGaleria();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file_outlined, color: theme.textColor, size: 22),
                  title: Text('Documento / Arquivo', style: theme.getTextStyle(color: theme.textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAnexarArquivo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
