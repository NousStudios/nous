import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/dados_perfil_loja_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/sincronizador_estado_loja.dart';

class DadosPerfilLojaSyncHelper {
  static void carregarDadosIniciais(
    DadosPerfilLojaController c,
    Loja? loja,
  ) {
    c.controllers.nome.text = loja?.nome ?? '';
    c.controllers.cnpj.text = loja?.cnpj ?? '';
    c.controllers.telefone.text = loja?.telefone ?? '';
    c.controllers.endereco.text = loja?.endereco ?? '';
    c.controllers.numero.text = loja?.numero ?? '';
    c.controllers.cidade.text = loja?.cidade ?? '';
    c.controllers.cep.text = loja?.cep ?? '';
    c.controllers.latitude = loja?.latitude;
    c.controllers.longitude = loja?.longitude;
    c.controllers.email.text = loja?.email ?? '';
    c.controllers.redesSociais.text = loja?.redesSociais ?? '';
    c.controllers.categorias.text = loja?.categorias ?? '';
    c.controllers.tags.text = loja?.tags ?? '';

    c.logo = loja?.logo ?? '';
    c.galeria.addAll(loja?.galeria ?? []);
    c.arquivos.addAll(loja?.arquivos ?? []);
    c.musicas.addAll(loja?.musicas ?? []);
    c.videos.addAll(loja?.videos ?? []);
    c.arquivosAudio.addAll(loja?.arquivosAudio ?? []);
    c.descricoesAnexos.addAll(loja?.descricoesAnexos ?? {});

    c.categorias.addAll(loja?.categoriasLoja ?? []);
    c.itens.addAll(loja?.itensLoja ?? []);
    c.gruposComponentes.addAll(loja?.gruposComponentesLoja ?? []);
    c.clientes.addAll(loja?.clientesLoja ?? []);
    c.fornecedores.addAll(loja?.fornecedoresLoja ?? []);
    c.pedidos.addAll(loja?.pedidosLoja ?? []);
    c.movimentosEstoque.addAll(loja?.movimentosEstoque ?? []);
    c.mesas.addAll(loja?.mesas ?? []);
    c.membros = List.of(loja?.membros ?? []);
    c.lojaOnline = loja?.aberta ?? false;
    c.tempoConclusaoMinutos = loja?.tempoConclusaoMinutos ?? 0;
    c.sonsAlertas.addAll(loja?.sonsAlertas ?? {});
    c.atalhosTeclado.addAll(loja?.atalhosTeclado ?? {});
    c.gerenciadorPedidos.iniciarTimerVerificacaoPedidos();

    if (loja != null &&
        ServidorRedeLocal().ativo &&
        ServidorRedeLocal().lojaAtiva == null &&
        !LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) {
      ServidorRedeLocal().lojaAtiva = loja;
    }
  }

  static void sincronizarComLoja(
    DadosPerfilLojaController c,
    Loja lojaAtual,
  ) {
    SincronizadorEstadoLoja.sincronizar(
      lojaAtual: lojaAtual,
      controllers: c.controllers,
      movimentosEstoque: c.movimentosEstoque,
      pedidos: c.pedidos,
      membros: c.membros,
      mesas: c.mesas,
      itens: c.itens,
      categorias: c.categorias,
      gruposComponentes: c.gruposComponentes,
      clientes: c.clientes,
      fornecedores: c.fornecedores,
      galeria: c.galeria,
      musicas: c.musicas,
      arquivosAudio: c.arquivosAudio,
      videos: c.videos,
      arquivos: c.arquivos,
      descricoesAnexos: c.descricoesAnexos,
      logoAtual: c.logo,
      lojaOnlineAtual: c.lojaOnline,
      tempoConclusaoMinutosAtual: c.tempoConclusaoMinutos,
      aplicarMudancas: ({
        required onlineMudou,
        required logoMudou,
        required galeriaMudou,
        required musicasMudaram,
        required arquivosAudioMudaram,
        required videosMudaram,
        required arquivosMudaram,
        required descricoesMudaram,
        required tempoConclusaoMudou,
        required movsMudaram,
        required pedidosMudaram,
        required membrosMudaram,
        required mesasMudaram,
        required itensMudaram,
        required categoriasMudaram,
        required gruposMudaram,
        required clientesMudaram,
        required fornecedoresMudaram,
      }) {
        c.setState(() {
          if (onlineMudou) c.lojaOnline = lojaAtual.aberta;
          if (logoMudou) c.logo = lojaAtual.logo;
          if (galeriaMudou) {
            c.galeria
              ..clear()
              ..addAll(lojaAtual.galeria);
          }
          if (musicasMudaram) {
            c.musicas
              ..clear()
              ..addAll(lojaAtual.musicas);
          }
          if (arquivosAudioMudaram) {
            c.arquivosAudio
              ..clear()
              ..addAll(lojaAtual.arquivosAudio);
          }
          if (videosMudaram) {
            c.videos
              ..clear()
              ..addAll(lojaAtual.videos);
          }
          if (arquivosMudaram) {
            c.arquivos
              ..clear()
              ..addAll(lojaAtual.arquivos);
          }
          if (descricoesMudaram) {
            c.descricoesAnexos
              ..clear()
              ..addAll(lojaAtual.descricoesAnexos);
          }
          if (tempoConclusaoMudou) {
            c.tempoConclusaoMinutos = lojaAtual.tempoConclusaoMinutos;
          }
          if (movsMudaram) {
            c.movimentosEstoque
              ..clear()
              ..addAll(lojaAtual.movimentosEstoque);
          }
          if (pedidosMudaram) {
            c.pedidos
              ..clear()
              ..addAll(lojaAtual.pedidosLoja);
          }
          if (membrosMudaram) {
            c.membros = List.of(lojaAtual.membros);
          }
          if (mesasMudaram) {
            c.mesas
              ..clear()
              ..addAll(lojaAtual.mesas);
          }
          if (itensMudaram) {
            c.itens
              ..clear()
              ..addAll(lojaAtual.itensLoja);
          }
          if (categoriasMudaram) {
            c.categorias
              ..clear()
              ..addAll(lojaAtual.categoriasLoja);
          }
          if (gruposMudaram) {
            c.gruposComponentes
              ..clear()
              ..addAll(lojaAtual.gruposComponentesLoja);
          }
          if (clientesMudaram) {
            c.clientes
              ..clear()
              ..addAll(lojaAtual.clientesLoja);
          }
          if (fornecedoresMudaram) {
            c.fornecedores
              ..clear()
              ..addAll(lojaAtual.fornecedoresLoja);
          }
        });
      },
    );
  }
}
