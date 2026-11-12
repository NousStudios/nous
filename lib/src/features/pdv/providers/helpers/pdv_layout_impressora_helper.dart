import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

/// Helper especializado em gestão de layout da UI, atalhos de teclado,
/// sons de alerta e sincronização de calibração de impressoras térmicas locais.
class PdvLayoutImpressoraHelper {
  PdvLayoutImpressoraHelper._();

  static bool layoutDesktopAtivo({
    required Loja? loja,
    required double? larguraTela,
    required bool layoutDesktopGlobal,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return false;
    }
    if (larguraTela != null && larguraTela <= 850) {
      return false;
    }
    if (loja != null) return loja.layoutExpandidoEfetivo;
    return layoutDesktopGlobal;
  }

  static String tipoLayoutAtivo({
    required Loja? loja,
    required String tipoLayoutDesktopGlobal,
  }) {
    if (loja != null && loja.tipoLayoutMaior.isNotEmpty) {
      return loja.tipoLayoutMaior;
    }
    return tipoLayoutDesktopGlobal;
  }

  static ({bool novoGlobal, Loja? lojaAtualizada}) alternarLayoutExpandido({
    required List<Loja> lojas,
    required String? id,
    required bool layoutDesktopGlobal,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return (novoGlobal: layoutDesktopGlobal, lojaAtualizada: null);
    }
    bool novoValor = !layoutDesktopGlobal;
    if (id != null && id.isNotEmpty) {
      final indice = lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        novoValor = !lojas[indice].layoutExpandido;
        final atualizada = lojas[indice].copyWith(layoutExpandido: novoValor);
        return (novoGlobal: novoValor, lojaAtualizada: atualizada);
      }
    }
    return (novoGlobal: novoValor, lojaAtualizada: null);
  }

  static Loja? definirLayoutExpandido({
    required List<Loja> lojas,
    required String? id,
    required bool ativo,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }
    if (id != null && id.isNotEmpty) {
      final indice = lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        return lojas[indice].copyWith(layoutExpandido: ativo);
      }
    }
    return null;
  }

  static Loja? definirTipoLayoutMaior({
    required List<Loja> lojas,
    required String? id,
    required String tipo,
  }) {
    if (id != null && id.isNotEmpty) {
      final indice = lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        return lojas[indice].copyWith(tipoLayoutMaior: tipo);
      }
    }
    return null;
  }

  /// Propaga calibração da impressora física para a loja indicada e todas as outras lojas da estação
  static Future<void> atualizarConfiguracoesImpressora({
    required List<Loja> lojas,
    required String id,
    required ConfiguracoesImpressora configuracoes,
    required String idLojaColetivaNous,
    required Future<void> Function(Loja) salvarNoCofre,
  }) async {
    final indice = lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada =
        lojas[indice].copyWith(configuracoesImpressora: configuracoes);
    lojas[indice] = atualizada;
    await salvarNoCofre(atualizada);

    for (int i = 0; i < lojas.length; i++) {
      final outra = lojas[i];
      if (outra.id == id || outra.id == idLojaColetivaNous) continue;
      final outraAtualizada = propagarConfiguracoesImpressora(
        outra,
        configuracoes,
      );
      lojas[i] = outraAtualizada;
      await salvarNoCofre(outraAtualizada);
    }
  }

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

  /// Propaga calibração tipográfica e de impressora térmica da loja de referência para lojas locais
  static Future<void> herdarCalibracaoImpressoraEntreLojasLocais({
    required List<Loja> lojas,
    required String idLojaColetivaNous,
    required Future<void> Function(Loja) salvarNoCofre,
  }) async {
    Loja? referenciaCalibrada;
    for (final l in lojas) {
      if (l.id == idLojaColetivaNous) continue;
      final c = l.configuracoesImpressora;
      if (temCalibracaoTipografiaOuMargem(c) || c.camposClientePersonalizados) {
        referenciaCalibrada = l;
        break;
      }
    }
    referenciaCalibrada ??= lojas
        .where((l) =>
            l.id != idLojaColetivaNous &&
            l.configuracoesImpressora.nomeImpressora.isNotEmpty)
        .firstOrNull;

    if (referenciaCalibrada == null) return;
    final ref = referenciaCalibrada.configuracoesImpressora;

    for (int i = 0; i < lojas.length; i++) {
      final loja = lojas[i];
      if (loja.id == idLojaColetivaNous || loja.id == referenciaCalibrada.id) {
        continue;
      }
      final atual = loja.configuracoesImpressora;
      final semCalibracaoFisica = !temCalibracaoTipografiaOuMargem(atual);
      final semImpressoraDefinida =
          atual.nomeImpressora.isEmpty && ref.nomeImpressora.isNotEmpty;
      final semCamposPersonalizados =
          !atual.camposClientePersonalizados && ref.camposClientePersonalizados;

      if (semCalibracaoFisica ||
          semImpressoraDefinida ||
          semCamposPersonalizados) {
        final novaConfig = atual.copyWith(
          larguraPapelMm:
              semCalibracaoFisica ? ref.larguraPapelMm : atual.larguraPapelMm,
          tamanhoFonte:
              semCalibracaoFisica ? ref.tamanhoFonte : atual.tamanhoFonte,
          modeloFonte:
              semCalibracaoFisica ? ref.modeloFonte : atual.modeloFonte,
          margemEsquerdaMm: semCalibracaoFisica
              ? ref.margemEsquerdaMm
              : atual.margemEsquerdaMm,
          margemDireitaMm:
              semCalibracaoFisica ? ref.margemDireitaMm : atual.margemDireitaMm,
          nomeImpressora:
              atual.nomeImpressora.isEmpty ? ref.nomeImpressora : atual.nomeImpressora,
          tipoConexao:
              atual.nomeImpressora.isEmpty ? ref.tipoConexao : atual.tipoConexao,
          enderecoRede:
              atual.enderecoRede.isEmpty ? ref.enderecoRede : atual.enderecoRede,
          camposClienteComanda: semCamposPersonalizados
              ? List<String>.from(ref.camposClienteComanda)
              : atual.camposClienteComanda,
          camposClientePersonalizados: semCamposPersonalizados
              ? ref.camposClientePersonalizados
              : atual.camposClientePersonalizados,
        );
        final lojaAtualizada =
            loja.copyWith(configuracoesImpressora: novaConfig);
        lojas[i] = lojaAtualizada;
        await salvarNoCofre(lojaAtualizada);
      }
    }
  }
}
