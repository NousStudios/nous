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
    for (final mLocal in lojaLocal.mesas) {
      if (!mesasConsolidadas.any((m) => m.id == mLocal.id)) {
        mesasConsolidadas.add(mLocal);
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
        if (p.dataHora.isAfter(existente.dataHora) ||
            (existente.status == StatusPedido.novo && p.status != StatusPedido.novo)) {
          pedidosMesclados[p.id] = p;
        }
      }
    }
    final listaPedidos = pedidosMesclados.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    // 11. Turnos de Caixa - UNIÃO SOBERANA
    final turnosMesclados = <String, TurnoCaixa>{};
    for (final t in lojaLocal.turnosCaixa) {
      turnosMesclados[t.id] = t;
    }
    for (final t in lojaNova.turnosCaixa) {
      if (!turnosMesclados.containsKey(t.id)) {
        turnosMesclados[t.id] = t;
      } else {
        final existente = turnosMesclados[t.id]!;
        if (existente.aberto && !t.aberto) {
          turnosMesclados[t.id] = t;
        } else if (!existente.aberto && t.aberto) {
          // Mantém o fechado
        } else if (t.dataAbertura.isAfter(existente.dataAbertura)) {
          turnosMesclados[t.id] = t;
        }
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

    // 14. Pedidos Programados
    final programadosMesclados = <String, PedidoProgramado>{};
    for (final pp in lojaLocal.pedidosProgramados) {
      programadosMesclados[pp.id] = pp;
    }
    for (final pp in lojaNova.pedidosProgramados) {
      if (!programadosMesclados.containsKey(pp.id)) {
        programadosMesclados[pp.id] = pp;
      }
    }
    final listaProgramados = programadosMesclados.values.toList();

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
      layoutExpandido: lojaLocal.layoutExpandido,
      tipoLayoutMaior: lojaLocal.tipoLayoutMaior.isNotEmpty
          ? lojaLocal.tipoLayoutMaior
          : lojaNova.tipoLayoutMaior,
    );
  }
}
