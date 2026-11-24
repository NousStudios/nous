import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

class CabecalhoCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final int etapa;
  final TipoFeedSocial tipoAtivo;
  final VoidCallback onVoltarEtapa;
  final VoidCallback onFechar;
  final ValueChanged<TipoFeedSocial> onSelecionarTipo;

  const CabecalhoCriarPubWidget({
    super.key,
    required this.theme,
    required this.etapa,
    required this.tipoAtivo,
    required this.onVoltarEtapa,
    required this.onFechar,
    required this.onSelecionarTipo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (etapa == 1 && tipoAtivo != TipoFeedSocial.escritos)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Voltar',
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.textColor,
                    ),
                    onPressed: onVoltarEtapa,
                  ),
                ),
              Center(
                child: Text(
                  'Nova Publicação',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.secondaryTextColor),
                  onPressed: onFechar,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
        if (etapa == 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _abaCategoria(TipoFeedSocial.fotos, Icons.grid_on_sharp, 'Fotos'),
                _abaCategoria(
                  TipoFeedSocial.videos,
                  Icons.play_circle_outline_rounded,
                  'Vídeos',
                ),
                _abaCategoria(
                  TipoFeedSocial.documentos,
                  Icons.description_outlined,
                  'Docs',
                ),
                _abaCategoria(
                  TipoFeedSocial.livros,
                  Icons.menu_book_outlined,
                  'Livros',
                ),
                _abaCategoria(
                  TipoFeedSocial.musicas,
                  Icons.music_note_outlined,
                  'Músicas',
                ),
                _abaCategoria(
                  TipoFeedSocial.escritos,
                  Icons.article_outlined,
                  'Escrito',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.25)),
        ],
      ],
    );
  }

  Widget _abaCategoria(TipoFeedSocial tipo, IconData icone, String tooltip) {
    final ativo = tipoAtivo == tipo;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelecionarTipo(tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: ativo ? theme.textColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icone,
            size: 21,
            color: ativo ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
