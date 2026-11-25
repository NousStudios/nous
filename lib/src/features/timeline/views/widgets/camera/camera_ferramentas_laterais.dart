import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Coluna lateral de ferramentas rápidas da câmera (texto, figurinhas, desenho e música).
class CameraFerramentasLaterais extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onCriarStoryTexto;

  const CameraFerramentasLaterais({
    super.key,
    required this.theme,
    required this.onCriarStoryTexto,
  });

  void _mostrarEmBreve(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Widget _botaoLateral({
    required IconData icone,
    required String tooltip,
    required VoidCallback onTap,
    bool ativo = true,
  }) {
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
              color: theme.textColor.withValues(alpha: ativo ? 0.45 : 0.18),
            ),
          ),
          child: Icon(
            icone,
            size: 20,
            color: ativo
                ? theme.textColor
                : theme.secondaryTextColor.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _botaoLateral(
          icone: Icons.title_rounded,
          tooltip: 'Criar Story com texto (Aa)',
          onTap: onCriarStoryTexto,
        ),
        _botaoLateral(
          icone: Icons.emoji_emotions_outlined,
          tooltip: 'Figurinhas (em breve)',
          ativo: false,
          onTap: () => _mostrarEmBreve(
            context,
            'Figurinhas chegarão em breve!',
          ),
        ),
        _botaoLateral(
          icone: Icons.brush_outlined,
          tooltip: 'Desenho (em breve)',
          ativo: false,
          onTap: () => _mostrarEmBreve(
            context,
            'Ferramenta de desenho em breve!',
          ),
        ),
        _botaoLateral(
          icone: Icons.music_note_outlined,
          tooltip: 'Música (em breve)',
          ativo: false,
          onTap: () => _mostrarEmBreve(
            context,
            'Músicas no Story em breve!',
          ),
        ),
      ],
    );
  }
}
