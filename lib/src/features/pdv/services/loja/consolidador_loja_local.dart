import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/loja/sanitizador_imagens_loja.dart';

/// Responsável pela consolidação e merge de dados de uma Loja recebida
/// com a Loja local existente, preservando integridade de anexos e mídias físicas locais.
class ConsolidadorLojaLocal {
  ConsolidadorLojaLocal._();

  static Loja consolidar(
    Loja lojaNova,
    Loja? lojaLocal, {
    bool manterItensAusentes = false,
    bool mesclarColecoesRemotas = true,
  }) {
    if (lojaLocal == null) {
      return SanitizadorImagensLoja.sanitizar(lojaNova);
    }

    // 1. Logo da loja
    String logoFinal = lojaNova.logo;
    if (ImagemService.ehAsset(lojaNova.logo)) {
      logoFinal = lojaNova.logo;
    } else {
      final logoResolvida = ImagemService.resolverCaminhoExistente(lojaNova.logo);
      if (logoResolvida != null) {
        logoFinal = logoResolvida;
      } else if (lojaLocal.logo.isNotEmpty && ImagemService.existe(lojaLocal.logo)) {
        logoFinal = ImagemService.ehAsset(lojaLocal.logo)
            ? lojaLocal.logo
            : (ImagemService.resolverCaminhoExistente(lojaLocal.logo) ?? lojaLocal.logo);
      }
    }

    // 2. Categorias
    final categoriasConsolidadas = <CategoriaLoja>[];
    for (final catNova in lojaNova.categoriasLoja) {
      CategoriaLoja? catLocal;
      for (final c in lojaLocal.categoriasLoja) {
        if (c.id == catNova.id) {
          catLocal = c;
          break;
        }
      }

      String fotoFinal = catNova.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(catNova.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (catLocal != null &&
          catLocal.foto.isNotEmpty &&
          ImagemService.existe(catLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(catLocal.foto) ?? catLocal.foto;
      }

      categoriasConsolidadas.add(catNova.copyWith(foto: fotoFinal));
    }
    if (manterItensAusentes) {
      for (final cLocal in lojaLocal.categoriasLoja) {
        if (!categoriasConsolidadas.any((c) => c.id == cLocal.id)) {
          categoriasConsolidadas.add(cLocal);
        }
      }
    }

    // 3. Itens
    final itensConsolidados = <ItemLoja>[];
    for (final itemNovo in lojaNova.itensLoja) {
      ItemLoja? itemLocal;
      for (final i in lojaLocal.itensLoja) {
        if (i.id == itemNovo.id) {
          itemLocal = i;
          break;
        }
      }

      final novasImagens = <String>[];
      for (final img in itemNovo.imagens) {
        final imgResolvida = ImagemService.resolverCaminhoExistente(img);
        if (imgResolvida != null) {
          novasImagens.add(imgResolvida);
        }
      }

      if (novasImagens.isEmpty && itemLocal != null && itemLocal.imagens.isNotEmpty) {
        for (final imgLocal in itemLocal.imagens) {
          final imgLocalResolvida = ImagemService.resolverCaminhoExistente(imgLocal);
          if (imgLocalResolvida != null) {
            novasImagens.add(imgLocalResolvida);
          }
        }
      }

      itensConsolidados.add(itemNovo.copyWith(
        imagens: novasImagens.isNotEmpty ? novasImagens : itemNovo.imagens,
      ));
    }
    if (manterItensAusentes) {
      for (final iLocal in lojaLocal.itensLoja) {
        if (!itensConsolidados.any((i) => i.id == iLocal.id)) {
          itensConsolidados.add(iLocal);
        }
      }
    }

    // 4. Clientes
    final clientesConsolidados = <Cliente>[];
    for (final cliNovo in lojaNova.clientesLoja) {
      Cliente? cliLocal;
      for (final c in lojaLocal.clientesLoja) {
        if (c.id == cliNovo.id) {
          cliLocal = c;
          break;
        }
      }

      String fotoFinal = cliNovo.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cliNovo.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (cliLocal != null &&
          cliLocal.foto.isNotEmpty &&
          ImagemService.existe(cliLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(cliLocal.foto) ?? cliLocal.foto;
      }

      clientesConsolidados.add(cliNovo.copyWith(foto: fotoFinal));
    }
    if (manterItensAusentes) {
      for (final cLocal in lojaLocal.clientesLoja) {
        if (!clientesConsolidados.any((c) => c.id == cLocal.id)) {
          clientesConsolidados.add(cLocal);
        }
      }
    }

    // 5. Fornecedores
    final fornecedoresConsolidados = <Fornecedor>[];
    for (final fornNovo in lojaNova.fornecedoresLoja) {
      Fornecedor? fornLocal;
      for (final f in lojaLocal.fornecedoresLoja) {
        if (f.id == fornNovo.id) {
          fornLocal = f;
          break;
        }
      }

      String fotoFinal = fornNovo.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(fornNovo.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (fornLocal != null &&
          fornLocal.foto.isNotEmpty &&
          ImagemService.existe(fornLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(fornLocal.foto) ?? fornLocal.foto;
      }

      fornecedoresConsolidados.add(fornNovo.copyWith(foto: fotoFinal));
    }
    if (manterItensAusentes) {
      for (final fLocal in lojaLocal.fornecedoresLoja) {
        if (!fornecedoresConsolidados.any((f) => f.id == fLocal.id)) {
          fornecedoresConsolidados.add(fLocal);
        }
      }
    }

    // 6. Galeria
    final galeriaConsolidada = <String>[];
    for (final g in lojaNova.galeria) {
      final gResolvido = ImagemService.resolverCaminhoExistente(g);
      if (gResolvido != null) {
        galeriaConsolidada.add(gResolvido);
      } else {
        final baseNovo = p.basename(g);
        String? localEncontrado;
        for (final gLocal in lojaLocal.galeria) {
          if (p.basename(gLocal) == baseNovo && ImagemService.existe(gLocal)) {
            localEncontrado = ImagemService.resolverCaminhoExistente(gLocal);
            break;
          }
        }
        galeriaConsolidada.add(localEncontrado ?? g);
      }
    }
    if (manterItensAusentes && galeriaConsolidada.isEmpty && lojaLocal.galeria.isNotEmpty) {
      for (final g in lojaLocal.galeria) {
        final gResolvido = ImagemService.resolverCaminhoExistente(g);
        if (gResolvido != null) {
          galeriaConsolidada.add(gResolvido);
        }
      }
    }

    // 7. Mesas da loja
    final mesasConsolidadas = List<MesaLoja>.from(lojaNova.mesas);
    if (mesclarColecoesRemotas) {
      for (final mLocal in lojaLocal.mesas) {
        if (!mesasConsolidadas.any((m) => m.id == mLocal.id)) {
          mesasConsolidadas.add(mLocal);
        }
      }
    }

    // 8. Anexos
    List<String> consolidarAnexos(List<String> novaLista, List<String> localLista) {
      final resultado = <String>[];
      for (final itemNovo in novaLista) {
        final resolvido = ImagemService.resolverCaminhoExistente(itemNovo);
        if (resolvido != null && File(resolvido).existsSync()) {
          resultado.add(resolvido);
        } else {
          final baseNovo = p.basename(itemNovo);
          String? localEncontrado;
          for (final itemLocal in localLista) {
            if (p.basename(itemLocal) == baseNovo && File(itemLocal).existsSync()) {
              localEncontrado = itemLocal;
              break;
            }
          }
          resultado.add(localEncontrado ?? itemNovo);
        }
      }
      return resultado;
    }

    final musicasConsolidadas = consolidarAnexos(lojaNova.musicas, lojaLocal.musicas);
    final audiosConsolidados = consolidarAnexos(lojaNova.arquivosAudio, lojaLocal.arquivosAudio);
    final videosConsolidados = consolidarAnexos(lojaNova.videos, lojaLocal.videos);
    final arquivosConsolidados = consolidarAnexos(lojaNova.arquivos, lojaLocal.arquivos);

    if (!mesclarColecoesRemotas) {
      return SanitizadorImagensLoja.sanitizar(
        lojaNova.copyWith(
          logo: logoFinal,
          categoriasLoja: categoriasConsolidadas,
          itensLoja: itensConsolidados,
          clientesLoja: clientesConsolidados,
          fornecedoresLoja: fornecedoresConsolidados,
          galeria: galeriaConsolidada,
          musicas: musicasConsolidadas,
          arquivosAudio: audiosConsolidados,
          videos: videosConsolidados,
          arquivos: arquivosConsolidados,
          mesas: mesasConsolidadas,
        ),
      );
    }

    // 9. Histórico de Ações
    final acoesMescladas = List<RegistroAcao>.from(lojaLocal.acoes);
    for (final a in lojaNova.acoes) {
      if (!acoesMescladas.any((ex) => ex.id == a.id)) {
        acoesMescladas.add(a);
      }
    }

    // 10. Pedidos (Finanças / Vendas) - UNIÃO SOBERANA E NÃO-DESTRUTIVA
    final pedidosMesclados = <String, PedidoLoja>{};
    for (final p in lojaLocal.pedidosLoja) {
      pedidosMesclados[p.id] = p;
    }
    for (final p in lojaNova.pedidosLoja) {
      if (!pedidosMesclados.containsKey(p.id)) {
        pedidosMesclados[p.id] = p;
      } else {
        final existente = pedidosMesclados[p.id]!;
        pedidosMesclados[p.id] = mesclarDoisPedidos(existente, p);
      }
    }
    final listaPedidos = pedidosMesclados.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    // 11. Turnos de Caixa - UNIÃO SOBERANA (preserva movimentações de suprimento/sangria no turno aberto)
    final turnosMesclados = <String, TurnoCaixa>{};
    for (final t in lojaLocal.turnosCaixa) {
      turnosMesclados[t.id] = t;
    }
    for (final t in lojaNova.turnosCaixa) {
      if (!turnosMesclados.containsKey(t.id)) {
        turnosMesclados[t.id] = t;
      } else {
        final existente = turnosMesclados[t.id]!;
        turnosMesclados[t.id] = mesclarDoisTurnosCaixa(existente, t);
      }
    }
    final listaTurnos = turnosMesclados.values.toList()
      ..sort((a, b) => a.dataAbertura.compareTo(b.dataAbertura));

    // 12. Movimentos de Estoque
    final estoqueMesclado = <String, MovimentoEstoque>{};
    for (final m in lojaLocal.movimentosEstoque) {
      estoqueMesclado[m.id] = m;
    }
    for (final m in lojaNova.movimentosEstoque) {
      if (!estoqueMesclado.containsKey(m.id)) {
        estoqueMesclado[m.id] = m;
      }
    }
    final listaEstoque = estoqueMesclado.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    // 13. Pagamentos de Funcionários
    final pagamentosMesclados = <String, PagamentoFuncionario>{};
    for (final pg in lojaLocal.pagamentosFuncionarios) {
      pagamentosMesclados[pg.id] = pg;
    }
    for (final pg in lojaNova.pagamentosFuncionarios) {
      if (!pagamentosMesclados.containsKey(pg.id)) {
        pagamentosMesclados[pg.id] = pg;
      }
    }
    final listaPagamentos = pagamentosMesclados.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    // 14. Pedidos Programados (lojaNova é soberana para refletir exclusões, pausas e edições)
    final mapaProgramadosLocais = <String, PedidoProgramado>{
      for (final pp in lojaLocal.pedidosProgramados) pp.id: pp,
    };
    final listaProgramados = lojaNova.pedidosProgramados.map((ppNovo) {
      final ppLocal = mapaProgramadosLocais[ppNovo.id];
      if (ppLocal != null && ppLocal.ultimaDataGerado != null) {
        if (ppNovo.ultimaDataGerado == null ||
            ppLocal.ultimaDataGerado!.isAfter(ppNovo.ultimaDataGerado!)) {
          return ppNovo.copyWith(ultimaDataGerado: ppLocal.ultimaDataGerado);
        }
      }
      return ppNovo;
    }).toList();

    // 15. Membros da Loja
    final membrosMesclados = <String, MembroLoja>{};
    for (final m in lojaLocal.membros) {
      membrosMesclados[m.cpf.replaceAll(RegExp(r'\D'), '')] = m;
    }
    for (final m in lojaNova.membros) {
      final cpfNorm = m.cpf.replaceAll(RegExp(r'\D'), '');
      membrosMesclados[cpfNorm] = m;
    }
    final listaMembros = membrosMesclados.values.toList();

    // 16. Cargos Personalizados
    final cargosMesclados = <String, CargoLoja>{};
    for (final c in lojaLocal.cargosPersonalizados) {
      cargosMesclados[c.id] = c;
    }
    for (final c in lojaNova.cargosPersonalizados) {
      cargosMesclados[c.id] = c;
    }
    final listaCargos = cargosMesclados.values.toList();

    final impressoraNovaTemHardware =
        lojaNova.configuracoesImpressora.nomeImpressora.trim().isNotEmpty ||
            lojaNova.configuracoesImpressora.enderecoRede.trim().isNotEmpty;
    final impressoraLocalTemHardware =
        lojaLocal.configuracoesImpressora.nomeImpressora.trim().isNotEmpty ||
            lojaLocal.configuracoesImpressora.enderecoRede.trim().isNotEmpty;
    final configuracoesImpressoraFinal =
        (!impressoraNovaTemHardware && impressoraLocalTemHardware)
            ? lojaLocal.configuracoesImpressora
            : lojaNova.configuracoesImpressora;

    return lojaNova.copyWith(
      logo: logoFinal,
      categoriasLoja: categoriasConsolidadas,
      itensLoja: itensConsolidados,
      clientesLoja: clientesConsolidados,
      fornecedoresLoja: fornecedoresConsolidados,
      galeria: galeriaConsolidada,
      musicas: musicasConsolidadas,
      arquivosAudio: audiosConsolidados,
      videos: videosConsolidados,
      arquivos: arquivosConsolidados,
      mesas: mesasConsolidadas,
      acoes: acoesMescladas,
      pedidosLoja: listaPedidos,
      turnosCaixa: listaTurnos,
      movimentosEstoque: listaEstoque,
      pagamentosFuncionarios: listaPagamentos,
      pedidosProgramados: listaProgramados,
      membros: listaMembros,
      cargosPersonalizados: listaCargos,
      configuracoesImpressora: configuracoesImpressoraFinal,
      layoutExpandido: lojaLocal.layoutExpandido,
      tipoLayoutMaior: lojaLocal.tipoLayoutMaior.isNotEmpty
          ? lojaLocal.tipoLayoutMaior
          : lojaNova.tipoLayoutMaior,
    );
  }

  /// Mescla soberana de dois pedidos com o mesmo ID respeitando a máquina de estados,
  /// quitações e integridade de itens e comentários.
  static PedidoLoja mesclarDoisPedidos(PedidoLoja a, PedidoLoja b) {
    int pesoStatus(StatusPedido s) {
      switch (s) {
        case StatusPedido.novo:
          return 1;
        case StatusPedido.aceito:
          return 2;
        case StatusPedido.concluido:
          return 3;
        case StatusPedido.cancelado:
          return 4;
      }
    }

    final pesoA = pesoStatus(a.status);
    final pesoB = pesoStatus(b.status);

    final StatusPedido statusFinal;
    String motivoCancelamentoFinal = a.motivoCancelamento.isNotEmpty
        ? a.motivoCancelamento
        : b.motivoCancelamento;

    if (pesoB > pesoA) {
      statusFinal = b.status;
      if (b.motivoCancelamento.isNotEmpty) {
        motivoCancelamentoFinal = b.motivoCancelamento;
      }
    } else if (pesoA > pesoB) {
      statusFinal = a.status;
    } else {
      statusFinal = a.status;
    }

    final quitadoFinal = a.quitado || b.quitado;
    final valorPagoFinal = a.valorPago >= b.valorPago ? a.valorPago : b.valorPago;
    final comandaFinal = b.comanda.isNotEmpty ? b.comanda : a.comanda;

    String comentarioFinal = a.comentario;
    String cpfAutorFinal = a.comentarioAutorCpf;
    String nomeAutorFinal = a.comentarioAutorNome;
    String emailAutorFinal = a.comentarioAutorEmail;
    DateTime? dataHoraComentarioFinal = a.comentarioDataHora;

    if (b.comentario.isNotEmpty) {
      final dataA = a.comentarioDataHora ?? a.dataHora;
      final dataB = b.comentarioDataHora ?? b.dataHora;
      if (a.comentario.isEmpty || dataB.isAfter(dataA)) {
        comentarioFinal = b.comentario;
        cpfAutorFinal = b.comentarioAutorCpf;
        nomeAutorFinal = b.comentarioAutorNome;
        emailAutorFinal = b.comentarioAutorEmail;
        dataHoraComentarioFinal = b.comentarioDataHora;
      }
    }

    final pedidoBase = (pesoB > pesoA || b.dataHora.isAfter(a.dataHora)) ? b : a;

    return pedidoBase.copyWith(
      status: statusFinal,
      motivoCancelamento: motivoCancelamentoFinal,
      quitado: quitadoFinal,
      valorPago: valorPagoFinal,
      comanda: comandaFinal,
      comentario: comentarioFinal,
      comentarioAutorCpf: cpfAutorFinal,
      comentarioAutorNome: nomeAutorFinal,
      comentarioAutorEmail: emailAutorFinal,
      comentarioDataHora: dataHoraComentarioFinal,
    );
  }

  /// Mescla soberana de dois turnos de caixa com o mesmo ID, preservando todas as
  /// movimentações (sangrias e suprimentos) de ambos os nós e priorizando o estado fechado.
  static TurnoCaixa mesclarDoisTurnosCaixa(TurnoCaixa a, TurnoCaixa b) {
    final mapaMovs = <String, MovimentoCaixa>{
      for (final m in a.movimentacoes) m.id: m,
    };
    for (final m in b.movimentacoes) {
      mapaMovs[m.id] = m;
    }
    final movsMescladas = mapaMovs.values.toList()
      ..sort((x, y) => x.dataHora.compareTo(y.dataHora));

    final TurnoCaixa base;
    if (a.aberto && !b.aberto) {
      base = b;
    } else if (!a.aberto && b.aberto) {
      base = a;
    } else {
      base = b;
    }

    return base.copyWith(movimentacoes: movsMescladas);
  }
}
