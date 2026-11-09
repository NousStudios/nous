import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

/// Helper especializado em gestão de layout da UI, atalhos de teclado,
/// sons de alerta e sincronização de calibração de impressoras térmicas locais.
class PdvLayoutImpressoraHelper {
  PdvLayoutImpressoraHelper._();

  static bool temCalibracaoTipografiaOuMargem(ConfiguracoesImpressora c) {
    return c.modeloFonte != 'belleza' ||
        c.margemEsquerdaMm != 5.0 ||
        c.margemDireitaMm != 3.0 ||
        c.tamanhoFonte != 'normal' ||
        c.larguraPapelMm != 58.0;
  }

  static Loja atualizarSomAlerta(Loja loja, String evento, String som) {
    final mapa = Map<String, String>.from(loja.sonsAlertas);
    if (som.isEmpty || som == 'padrao') {
      mapa.remove(evento);
    } else {
      mapa[evento] = som;
    }
    return loja.copyWith(sonsAlertas: mapa);
  }

  static Loja atualizarAtalhoTeclado(Loja loja, String tecla, String acao) {
    final mapa = Map<String, String>.from(loja.atalhosTeclado);
    mapa[tecla] = acao;
    return loja.copyWith(atalhosTeclado: mapa);
  }

  static Loja atualizarTempoConclusao(Loja loja, int minutos) {
    return loja.copyWith(tempoConclusaoMinutos: minutos);
  }

  static Loja atualizarDescricaoAnexo(Loja loja, String caminho, String descricao) {
    final mapa = Map<String, String>.from(loja.descricoesAnexos);
    if (descricao.trim().isEmpty) {
      mapa.remove(caminho);
    } else {
      mapa[caminho] = descricao.trim();
    }
    return loja.copyWith(descricoesAnexos: mapa);
  }

  static Loja atualizarAnexosLoja(
    Loja loja, {
    List<String>? galeria,
    List<String>? arquivos,
    List<String>? musicas,
    List<String>? videos,
    List<String>? arquivosAudio,
    Map<String, String>? descricoesAnexos,
  }) {
    return loja.copyWith(
      galeria: galeria ?? loja.galeria,
      arquivos: arquivos ?? loja.arquivos,
      musicas: musicas ?? loja.musicas,
      videos: videos ?? loja.videos,
      arquivosAudio: arquivosAudio ?? loja.arquivosAudio,
      descricoesAnexos: descricoesAnexos ?? loja.descricoesAnexos,
    );
  }

  static Loja propagarConfiguracoesImpressora(
    Loja alvo,
    ConfiguracoesImpressora novas,
  ) {
    final configAtual = alvo.configuracoesImpressora;
    final configPropagada = configAtual.copyWith(
      larguraPapelMm: novas.larguraPapelMm,
      tamanhoFonte: novas.tamanhoFonte,
      modeloFonte: novas.modeloFonte,
      margemEsquerdaMm: novas.margemEsquerdaMm,
      margemDireitaMm: novas.margemDireitaMm,
      tipoConexao: novas.tipoConexao,
      enderecoRede: novas.enderecoRede,
      nomeImpressora: novas.nomeImpressora,
      camposClienteComanda: !configAtual.camposClientePersonalizados
          ? List<String>.from(novas.camposClienteComanda)
          : configAtual.camposClienteComanda,
      camposClientePersonalizados:
          configAtual.camposClientePersonalizados || novas.camposClientePersonalizados,
    );
    return alvo.copyWith(configuracoesImpressora: configPropagada);
  }
}
