import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';

/// Controlador desacoplado para a gestão de anexos, fotos, vídeos, músicas e logotipo da loja no PDV.
class GerenciadorAnexosLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<String> Function() obterGaleria;
  final List<String> Function() obterArquivos;
  final List<String> Function() obterMusicas;
  final List<String> Function() obterVideos;
  final List<String> Function() obterArquivosAudio;
  final Map<String, String> Function() obterDescricoesAnexos;
  final void Function(String logo) definirLogo;
  final void Function(void Function()) setState;
  final VoidCallback salvarDadosLoja;
  final VoidCallback avisarSemPermissao;

  GerenciadorAnexosLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterGaleria,
    required this.obterArquivos,
    required this.obterMusicas,
    required this.obterVideos,
    required this.obterArquivosAudio,
    required this.obterDescricoesAnexos,
    required this.definirLogo,
    required this.setState,
    required this.salvarDadosLoja,
    required this.avisarSemPermissao,
  });

  void removerLogoLoja() {
    setState(() => definirLogo(''));
    salvarDadosLoja();
  }

  Future<void> selecionarNovaLogoLoja() async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return;

    final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
    if (!estaMontado()) return;

    if (salvo == null) {
      final theme = ThemeController.currentTheme.value;
      ScaffoldMessenger.maybeOf(obterContext())?.showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'A logo deve ser uma imagem válida de até meio giga (500MB).',
            style: theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    setState(() => definirLogo(salvo));
    salvarDadosLoja();
  }

  void adicionarAnexo(TipoAnexoLoja tipo, String caminho) {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    setState(() {
      switch (tipo) {
        case TipoAnexoLoja.galeria:
          obterGaleria().add(caminho);
          break;
        case TipoAnexoLoja.arquivos:
          obterArquivos().add(caminho);
          break;
        case TipoAnexoLoja.musicas:
          obterMusicas().add(caminho);
          break;
        case TipoAnexoLoja.videos:
          obterVideos().add(caminho);
          break;
        case TipoAnexoLoja.arquivosAudio:
          obterArquivosAudio().add(caminho);
          break;
      }
    });
    persistirAnexosLoja();
  }

  void removerAnexo(TipoAnexoLoja tipo, int index) {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    setState(() {
      switch (tipo) {
        case TipoAnexoLoja.galeria:
          obterGaleria().removeAt(index);
          break;
        case TipoAnexoLoja.arquivos:
          obterArquivos().removeAt(index);
          break;
        case TipoAnexoLoja.musicas:
          obterMusicas().removeAt(index);
          break;
        case TipoAnexoLoja.videos:
          obterVideos().removeAt(index);
          break;
        case TipoAnexoLoja.arquivosAudio:
          obterArquivosAudio().removeAt(index);
          break;
      }
    });
    persistirAnexosLoja();
  }

  void substituirAnexo(TipoAnexoLoja tipo, int index, String novoCaminho) {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    setState(() {
      switch (tipo) {
        case TipoAnexoLoja.galeria:
          obterGaleria()[index] = novoCaminho;
          break;
        case TipoAnexoLoja.arquivos:
          obterArquivos()[index] = novoCaminho;
          break;
        case TipoAnexoLoja.musicas:
          obterMusicas()[index] = novoCaminho;
          break;
        case TipoAnexoLoja.videos:
          obterVideos()[index] = novoCaminho;
          break;
        case TipoAnexoLoja.arquivosAudio:
          obterArquivosAudio()[index] = novoCaminho;
          break;
      }
    });
    persistirAnexosLoja();
  }

  void atualizarDescricaoAnexo(String caminho, String novaDescricao) {
    final context = obterContext();
    if (!context.read<PdvProvider>().possoEditarDadosLoja(lojaId)) {
      avisarSemPermissao();
      return;
    }

    setState(() {
      final descricoes = obterDescricoesAnexos();
      if (novaDescricao.trim().isEmpty) {
        descricoes.remove(caminho);
      } else {
        descricoes[caminho] = novaDescricao.trim();
      }
    });
    persistirAnexosLoja();
  }

  void persistirAnexosLoja() {
    final context = obterContext();
    context.read<PdvProvider>().atualizarAnexosLoja(
          lojaId,
          galeria: obterGaleria(),
          arquivos: obterArquivos(),
          musicas: obterMusicas(),
          videos: obterVideos(),
          arquivosAudio: obterArquivosAudio(),
          descricoesAnexos: obterDescricoesAnexos(),
        );
  }
}
