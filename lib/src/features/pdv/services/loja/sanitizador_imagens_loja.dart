import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Responsável pela sanitização de referências de imagens físicas locais da Loja.
class SanitizadorImagensLoja {
  SanitizadorImagensLoja._();

  static Loja sanitizar(Loja loja) {
    String logoFinal = loja.logo;
    if (logoFinal.isNotEmpty && !ImagemService.ehAsset(logoFinal)) {
      logoFinal = ImagemService.resolverCaminhoExistente(logoFinal) ?? logoFinal;
    }

    final novasCategorias = loja.categoriasLoja.map((cat) {
      if (cat.foto.isEmpty || ImagemService.ehAsset(cat.foto)) return cat;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cat.foto) ?? cat.foto;
      return fotoResolvida != cat.foto ? cat.copyWith(foto: fotoResolvida) : cat;
    }).toList();

    final novosItens = loja.itensLoja.map((item) {
      if (item.imagens.isEmpty) return item;
      final novasImagens = item.imagens.map((img) {
        return ImagemService.resolverCaminhoExistente(img) ?? img;
      }).toList();
      return item.copyWith(imagens: novasImagens);
    }).toList();

    final novosClientes = loja.clientesLoja.map((cli) {
      if (cli.foto.isEmpty) return cli;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cli.foto) ?? cli.foto;
      return fotoResolvida != cli.foto ? cli.copyWith(foto: fotoResolvida) : cli;
    }).toList();

    final novosFornecedores = loja.fornecedoresLoja.map((forn) {
      if (forn.foto.isEmpty) return forn;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(forn.foto) ?? forn.foto;
      return fotoResolvida != forn.foto ? forn.copyWith(foto: fotoResolvida) : forn;
    }).toList();

    final novaGaleria = loja.galeria.map((g) {
      return ImagemService.resolverCaminhoExistente(g) ?? g;
    }).toList();

    final novasMusicas = loja.musicas.map((m) {
      return ImagemService.resolverCaminhoExistente(m) ?? m;
    }).toList();

    final novosAudios = loja.arquivosAudio.map((a) {
      return ImagemService.resolverCaminhoExistente(a) ?? a;
    }).toList();

    final novosVideos = loja.videos.map((v) {
      return ImagemService.resolverCaminhoExistente(v) ?? v;
    }).toList();

    final novosArquivos = loja.arquivos.map((arq) {
      return ImagemService.resolverCaminhoExistente(arq) ?? arq;
    }).toList();

    return loja.copyWith(
      logo: logoFinal,
      categoriasLoja: novasCategorias,
      itensLoja: novosItens,
      clientesLoja: novosClientes,
      fornecedoresLoja: novosFornecedores,
      galeria: novaGaleria,
      musicas: novasMusicas,
      arquivosAudio: novosAudios,
      videos: novosVideos,
      arquivos: novosArquivos,
    );
  }
}
