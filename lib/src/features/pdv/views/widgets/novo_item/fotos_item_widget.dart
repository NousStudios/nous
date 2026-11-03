import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/ajustar_imagem_dialog.dart';

class FotosItemWidget extends StatelessWidget {
  final AppTheme theme;
  final List<String> imagens;
  final VoidCallback onImagensAlteradas;

  const FotosItemWidget({
    super.key,
    required this.theme,
    required this.imagens,
    required this.onImagensAlteradas,
  });

  Future<void> _selecionarFotos(BuildContext context) async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    final arquivos = await openFiles(acceptedTypeGroups: const [grupo]);
    if (arquivos.isEmpty) return;

    var ignorados = 0;

    for (final arquivo in arquivos) {
      final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
      if (salvo != null) {
        if (!imagens.contains(salvo)) {
          imagens.add(salvo);
        }
      } else {
        ignorados++;
      }
    }

    if (context.mounted) {
      onImagensAlteradas();
      if (ignorados > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              '$ignorados imagem(ns) foram ignoradas por tamanho superior a meio giga (500MB) ou formato inválido.',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  Future<void> _ajustarFoto(BuildContext context, int index) async {
    final caminhoAtual = imagens[index];
    final novoCaminho = await AjustarImagemDialog.mostrar(
      context,
      theme: theme,
      caminhoImagem: caminhoAtual,
    );

    if (novoCaminho != null && context.mounted) {
      imagens[index] = novoCaminho;
      onImagensAlteradas();
    }
  }

  Future<void> _confirmarRemoverFoto(BuildContext context, int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Remover Imagem',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Tem certeza de que deseja retirar esta imagem do item?',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Remover',
              style: theme.getTextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      imagens.removeAt(index);
      onImagensAlteradas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: imagens.isEmpty
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selecionarFotos(context),
                child: Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.secondaryTextColor,
                    size: 42,
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagens.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == imagens.length) {
                    return Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _selecionarFotos(context),
                        child: Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: theme.textColor,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }

                  final caminho = imagens[index];
                  final caminhoResolvido =
                      ImagemService.resolverCaminhoExistente(caminho) ??
                          caminho;
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _ajustarFoto(context, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 110,
                            height: double.infinity,
                            color: theme.cardBackgroundColor,
                            child: Image.file(
                              File(caminhoResolvido),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: theme.secondaryTextColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Tooltip(
                          message: 'Ajustar / Recortar imagem',
                          child: GestureDetector(
                            onTap: () => _ajustarFoto(context, index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.crop,
                                color: theme.textColor,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Tooltip(
                          message: 'Remover imagem',
                          child: GestureDetector(
                            onTap: () => _confirmarRemoverFoto(context, index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
