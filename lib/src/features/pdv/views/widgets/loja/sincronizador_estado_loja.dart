import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';

/// Utilitário especialista responsável por calcular diferenças e sincronizar
/// em lote o estado de uma loja ativa com os controladores da view.
class SincronizadorEstadoLoja {
  static bool sincronizar({
    required Loja lojaAtual,
    required ControllersDadosLoja controllers,
    required List<MovimentoEstoque> movimentosEstoque,
    required List<PedidoLoja> pedidos,
    required List<MembroLoja> membros,
    required List<MesaLoja> mesas,
    required List<ItemLoja> itens,
    required List<CategoriaLoja> categorias,
    required List<GrupoComponentesLoja> gruposComponentes,
    required List<Cliente> clientes,
    required List<Fornecedor> fornecedores,
    required List<String> galeria,
    required List<String> musicas,
    required List<String> arquivosAudio,
    required List<String> videos,
    required List<String> arquivos,
    required Map<String, String> descricoesAnexos,
    required String logoAtual,
    required bool lojaOnlineAtual,
    required int tempoConclusaoMinutosAtual,
    required void Function({
      required bool onlineMudou,
      required bool logoMudou,
      required bool galeriaMudou,
      required bool musicasMudaram,
      required bool arquivosAudioMudaram,
      required bool videosMudaram,
      required bool arquivosMudaram,
      required bool descricoesMudaram,
      required bool tempoConclusaoMudou,
      required bool movsMudaram,
      required bool pedidosMudaram,
      required bool membrosMudaram,
      required bool mesasMudaram,
      required bool itensMudaram,
      required bool categoriasMudaram,
      required bool gruposMudaram,
      required bool clientesMudaram,
      required bool fornecedoresMudaram,
    }) aplicarMudancas,
  }) {
    final novosMovs = lojaAtual.movimentosEstoque;
    final movsMudaram = movimentosEstoque.length != novosMovs.length ||
        !listEquals(
          movimentosEstoque.map((m) => m.id).toList(),
          novosMovs.map((m) => m.id).toList(),
        );

    final novosPedidos = lojaAtual.pedidosLoja;
    final pedidosMudaram = pedidos.length != novosPedidos.length ||
        !listEquals(
          pedidos
              .map((p) =>
                  '${p.id}_${p.status.name}_${p.quitado}_${p.valorPago}_${p.motivoCancelamento}_${p.comentario}')
              .toList(),
          novosPedidos
              .map((p) =>
                  '${p.id}_${p.status.name}_${p.quitado}_${p.valorPago}_${p.motivoCancelamento}_${p.comentario}')
              .toList(),
        );

    final membrosMudaram = membros.length != lojaAtual.membros.length ||
        !listEquals(
          membros
              .map((m) => '${m.cpf}_${m.papel.name}_${m.cargoPersonalizadoId}')
              .toList(),
          lojaAtual.membros
              .map((m) => '${m.cpf}_${m.papel.name}_${m.cargoPersonalizadoId}')
              .toList(),
        );

    final novasMesas = lojaAtual.mesas;
    final mesasMudaram = mesas.length != novasMesas.length ||
        !listEquals(
          mesas
              .map((m) =>
                  '${m.id}_${m.status.name}_${m.itens.length}_${m.totalAcumulado}_${m.clienteNome}')
              .toList(),
          novasMesas
              .map((m) =>
                  '${m.id}_${m.status.name}_${m.itens.length}_${m.totalAcumulado}_${m.clienteNome}')
              .toList(),
        );

    final novosItens = lojaAtual.itensLoja;
    final itensMudaram = itens.length != novosItens.length ||
        !listEquals(
          itens
              .map((i) =>
                  '${i.id}_${i.nome}_${i.preco}_${i.precoCusto}_${i.imagens.join(",")}')
              .toList(),
          novosItens
              .map((i) =>
                  '${i.id}_${i.nome}_${i.preco}_${i.precoCusto}_${i.imagens.join(",")}')
              .toList(),
        );

    final novasCategorias = lojaAtual.categoriasLoja;
    final categoriasMudaram = categorias.length != novasCategorias.length ||
        !listEquals(
          categorias.map((c) => '${c.id}_${c.nome}_${c.foto}').toList(),
          novasCategorias.map((c) => '${c.id}_${c.nome}_${c.foto}').toList(),
        );

    final novosGrupos = lojaAtual.gruposComponentesLoja;
    final gruposMudaram = gruposComponentes.length != novosGrupos.length ||
        !listEquals(
          gruposComponentes
              .map((g) => '${g.id}_${g.nome}_${g.itemIds.length}')
              .toList(),
          novosGrupos
              .map((g) => '${g.id}_${g.nome}_${g.itemIds.length}')
              .toList(),
        );

    final novosClientes = lojaAtual.clientesLoja;
    final clientesMudaram = clientes.length != novosClientes.length ||
        !listEquals(
          clientes.map((c) => '${c.id}_${c.nome}_${c.cnpj}_${c.telefone}_${c.foto}').toList(),
          novosClientes.map((c) => '${c.id}_${c.nome}_${c.cnpj}_${c.telefone}_${c.foto}').toList(),
        );

    final novosFornecedores = lojaAtual.fornecedoresLoja;
    final fornecedoresMudaram = fornecedores.length != novosFornecedores.length ||
        !listEquals(
          fornecedores.map((f) => '${f.id}_${f.nome}_${f.cnpj}_${f.telefone}_${f.foto}').toList(),
          novosFornecedores.map((f) => '${f.id}_${f.nome}_${f.cnpj}_${f.telefone}_${f.foto}').toList(),
        );

    final logoMudou = lojaAtual.logo.isNotEmpty && logoAtual != lojaAtual.logo;
    final onlineMudou = lojaAtual.aberta != lojaOnlineAtual;
    final galeriaMudou = !listEquals(galeria, lojaAtual.galeria);
    final musicasMudaram = !listEquals(musicas, lojaAtual.musicas);
    final arquivosAudioMudaram = !listEquals(arquivosAudio, lojaAtual.arquivosAudio);
    final videosMudaram = !listEquals(videos, lojaAtual.videos);
    final arquivosMudaram = !listEquals(arquivos, lojaAtual.arquivos);
    final descricoesMudaram = !mapEquals(descricoesAnexos, lojaAtual.descricoesAnexos);
    final tempoConclusaoMudou = tempoConclusaoMinutosAtual != lojaAtual.tempoConclusaoMinutos;

    final houveMudanca = movsMudaram ||
        pedidosMudaram ||
        membrosMudaram ||
        mesasMudaram ||
        itensMudaram ||
        categoriasMudaram ||
        gruposMudaram ||
        clientesMudaram ||
        fornecedoresMudaram ||
        logoMudou ||
        onlineMudou ||
        galeriaMudou ||
        musicasMudaram ||
        arquivosAudioMudaram ||
        videosMudaram ||
        arquivosMudaram ||
        descricoesMudaram ||
        tempoConclusaoMudou;

    if (houveMudanca) {
      if (controllers.nome.text != lojaAtual.nome) {
        controllers.nome.text = lojaAtual.nome;
      }
      if (controllers.cnpj.text != lojaAtual.cnpj) {
        controllers.cnpj.text = lojaAtual.cnpj;
      }
      if (controllers.telefone.text != lojaAtual.telefone) {
        controllers.telefone.text = lojaAtual.telefone;
      }
      if (controllers.endereco.text != lojaAtual.endereco) {
        controllers.endereco.text = lojaAtual.endereco;
      }
      if (controllers.numero.text != lojaAtual.numero) {
        controllers.numero.text = lojaAtual.numero;
      }
      if (controllers.email.text != lojaAtual.email) {
        controllers.email.text = lojaAtual.email;
      }
      if (controllers.redesSociais.text != lojaAtual.redesSociais) {
        controllers.redesSociais.text = lojaAtual.redesSociais;
      }
      if (controllers.categorias.text != lojaAtual.categorias) {
        controllers.categorias.text = lojaAtual.categorias;
      }
      if (controllers.tags.text != lojaAtual.tags) {
        controllers.tags.text = lojaAtual.tags;
      }

      aplicarMudancas(
        onlineMudou: onlineMudou,
        logoMudou: logoMudou,
        galeriaMudou: galeriaMudou,
        musicasMudaram: musicasMudaram,
        arquivosAudioMudaram: arquivosAudioMudaram,
        videosMudaram: videosMudaram,
        arquivosMudaram: arquivosMudaram,
        descricoesMudaram: descricoesMudaram,
        tempoConclusaoMudou: tempoConclusaoMudou,
        movsMudaram: movsMudaram,
        pedidosMudaram: pedidosMudaram,
        membrosMudaram: membrosMudaram,
        mesasMudaram: mesasMudaram,
        itensMudaram: itensMudaram,
        categoriasMudaram: categoriasMudaram,
        gruposMudaram: gruposMudaram,
        clientesMudaram: clientesMudaram,
        fornecedoresMudaram: fornecedoresMudaram,
      );
      return true;
    }

    return false;
  }
}
