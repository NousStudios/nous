import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra superior do editor de Story: botão fechar e selo opcional de repostagem.
class EditorStoryBarraTopo extends StatelessWidget {
  final AppTheme theme;
  final String? autorRepostNome;
  final VoidCallback onFechar;

  const EditorStoryBarraTopo({
    super.key,
    required this.theme,
    required this.onFechar,
    this.autorRepostNome,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: onFechar,
        ),
        if (autorRepostNome != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Repostando de $autorRepostNome',
              style: theme.getTextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Barra lateral esquerda minimalista com as ferramentas do editor de Story.
class EditorStoryBarraLateral extends StatelessWidget {
  final AppTheme theme;
  final bool mostrarBotaoCorFundo;
  final VoidCallback onAdicionarTexto;
  final VoidCallback onSelecionarMidia;
  final VoidCallback onAlternarCorFundo;
  final ValueChanged<String> onRecursoEmBreve;

  const EditorStoryBarraLateral({
    super.key,
    required this.theme,
    required this.mostrarBotaoCorFundo,
    required this.onAdicionarTexto,
    required this.onSelecionarMidia,
    required this.onAlternarCorFundo,
    required this.onRecursoEmBreve,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BotaoFerramentaLateral(
          theme: theme,
          icone: Icons.title_rounded,
          tooltip: 'Adicionar texto (Aa)',
          onTap: onAdicionarTexto,
        ),
        _BotaoFerramentaLateral(
          theme: theme,
          icone: Icons.photo_library_outlined,
          tooltip: 'Escolher foto da pasta',
          onTap: onSelecionarMidia,
        ),
        if (mostrarBotaoCorFundo)
          _BotaoFerramentaLateral(
            theme: theme,
            icone: Icons.palette_outlined,
            tooltip: 'Trocar cor de fundo',
            onTap: onAlternarCorFundo,
          ),
        _BotaoFerramentaLateral(
          theme: theme,
          icone: Icons.emoji_emotions_outlined,
          tooltip: 'Figurinhas (em breve)',
          ativo: false,
          onTap: () => onRecursoEmBreve('Figurinhas chegarão em breve!'),
        ),
        _BotaoFerramentaLateral(
          theme: theme,
          icone: Icons.brush_outlined,
          tooltip: 'Desenho (em breve)',
          ativo: false,
          onTap: () => onRecursoEmBreve('Ferramenta de desenho em breve!'),
        ),
        _BotaoFerramentaLateral(
          theme: theme,
          icone: Icons.music_note_outlined,
          tooltip: 'Música (em breve)',
          ativo: false,
          onTap: () => onRecursoEmBreve('Músicas no Story em breve!'),
        ),
      ],
    );
  }
}

class _BotaoFerramentaLateral extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final String tooltip;
  final VoidCallback onTap;
  final bool ativo;

  const _BotaoFerramentaLateral({
    required this.theme,
    required this.icone,
    required this.tooltip,
    required this.onTap,
    this.ativo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: ativo ? 0.58 : 0.32),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.borderColor.withValues(alpha: ativo ? 0.45 : 0.18),
            ),
          ),
          child: Icon(
            icone,
            size: 20,
            color: ativo
                ? theme.textColor
                : theme.secondaryTextColor.withValues(alpha: 0.54),
          ),
        ),
      ),
    );
  }
}

/// Barra inferior do editor de Story: fixar nos destaques e botão de publicar.
class EditorStoryBarraInferior extends StatelessWidget {
  final AppTheme theme;
  final bool destaquePermanente;
  final bool publicando;
  final VoidCallback onConfigurarDestaque;
  final VoidCallback onPublicar;

  const EditorStoryBarraInferior({
    super.key,
    required this.theme,
    required this.destaquePermanente,
    required this.publicando,
    required this.onConfigurarDestaque,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onConfigurarDestaque,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: destaquePermanente
                    ? theme.borderColor
                    : theme.borderColor.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  destaquePermanente
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 6),
                Text(
                  destaquePermanente ? 'Destacado' : 'Destacar',
                  style: theme.getTextStyle(
                    color: theme.textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.textColor,
              foregroundColor: theme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: publicando ? null : onPublicar,
            icon: publicando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              publicando ? 'Publicando...' : 'Compartilhar no Story',
              style: theme.getTextStyle(
                color: theme.backgroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
