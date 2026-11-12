import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/contrato_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';

/// Resultado da mesclagem de entidades de negócio entre nós da rede local.
class ResultadoMesclagemEntidades {
  final Loja loja;
  final bool houveCuraNoServidor;

  const ResultadoMesclagemEntidades({
    required this.loja,
    required this.houveCuraNoServidor,
  });
}

/// Especialista em mesclagem determinística e de alta performance das entidades
/// de negócio entre o estado recebido da rede e o estado persistido localmente.
class MescladorEntidadesRede {
  /// Executa a mesclagem das coleções da loja (mesas, ações, pedidos, turnos, pontos, etc.)
  static ResultadoMesclagemEntidades mesclarEntidades({
    required Loja lojaBase,
    required Loja lojaLocal,
  }) {
    var houveCura = false;
    Loja lojaMesclada = lojaBase;

    // 1. Mesas com mesclagem aditiva granular de itens de comanda (blindagem contra concorrência)
    final mapaMesas = <String, MesaLoja>{
      for (final m in lojaMesclada.mesas) m.id: m,
    };
    for (final mLocal in lojaLocal.mesas) {
      final mExistente = mapaMesas[mLocal.id];
      if (mExistente == null) {
        mapaMesas[mLocal.id] = mLocal;
        houveCura = true;
      } else if (mExistente.status == StatusMesa.ocupada &&
          mLocal.status == StatusMesa.ocupada) {
        final aberturaMinima = mExistente.dataHoraAbertura
            ?.subtract(const Duration(seconds: 5));
        final mapaItens = <String, ItemComandaMesa>{
          for (final it in mExistente.itens) it.id: it,
        };
        var itensAdicionados = false;
        for (final itLocal in mLocal.itens) {
          if (aberturaMinima != null &&
              itLocal.dataHora.isBefore(aberturaMinima)) {
            continue;
          }
          if (!mapaItens.containsKey(itLocal.id)) {
            mapaItens[itLocal.id] = itLocal;
            itensAdicionados = true;
          }
        }
        if (itensAdicionados) {
          final todosItens = mapaItens.values.toList()
            ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
          final clienteEfetivo = mExistente.clienteNome.isNotEmpty
              ? mExistente.clienteNome
              : mLocal.clienteNome;
          final obsEfetiva = mExistente.observacoes.isNotEmpty
              ? mExistente.observacoes
              : mLocal.observacoes;

          mapaMesas[mLocal.id] = mExistente.copyWith(
            itens: todosItens,
            status: StatusMesa.ocupada,
            clienteNome: clienteEfetivo,
            observacoes: obsEfetiva,
          );
          houveCura = true;
        }
      }
    }
    lojaMesclada = lojaMesclada.copyWith(mesas: mapaMesas.values.toList());

    // 2. Histórico de Auditoria (Ações) - Com janela de retenção de 2.000 itens para evitar OOM
    final acoesMescladas = List<RegistroAcao>.from(lojaMesclada.acoes);
    final idsAcoes = acoesMescladas.map((a) => a.id).toSet();
    for (final aLocal in lojaLocal.acoes) {
      if (idsAcoes.add(aLocal.id)) {
        acoesMescladas.add(aLocal);
        houveCura = true;
      }
    }
    acoesMescladas.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final acoesLimitadas = acoesMescladas.length > 2000
        ? acoesMescladas.sublist(0, 2000)
        : acoesMescladas;
    lojaMesclada = lojaMesclada.copyWith(acoes: acoesLimitadas);

    // 3. Pedidos, Movimentos de Estoque e Pagamentos - Indexação O(1)
    final agora = DateTime.now();
    bool mesmoDia(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final mapaPedidos = <String, PedidoLoja>{
      for (final p in lojaMesclada.pedidosLoja) p.id: p,
    };
    for (final pLocal in lojaLocal.pedidosLoja) {
      if (!mapaPedidos.containsKey(pLocal.id)) {
        final ehDeHoje = mesmoDia(pLocal.dataHora, agora);
        final ehNovo = pLocal.status == StatusPedido.novo;
        if (!ehNovo && ehDeHoje) {
          mapaPedidos[pLocal.id] = pLocal;
          houveCura = true;
        }
      } else {
        final existente = mapaPedidos[pLocal.id]!;
        final mesclado =
            ConsolidadorLojaLocal.mesclarDoisPedidos(existente, pLocal);
        if (mesclado != existente) {
          mapaPedidos[pLocal.id] = mesclado;
          if (mesclado.status != existente.status ||
              mesclado.quitado != existente.quitado ||
              mesclado.valorPago != existente.valorPago) {
            houveCura = true;
          }
        }
      }
    }
    final pedidosMesclados = mapaPedidos.values.toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final movimentosMesclados =
        List<MovimentoEstoque>.from(lojaMesclada.movimentosEstoque);
    final idsMovimentos = movimentosMesclados.map((m) => m.id).toSet();
    for (final mLocal in lojaLocal.movimentosEstoque) {
      if (idsMovimentos.add(mLocal.id)) {
        movimentosMesclados.add(mLocal);
        houveCura = true;
      }
    }
    movimentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosLimitados = movimentosMesclados.length > 2000
        ? movimentosMesclados.sublist(0, 2000)
        : movimentosMesclados;

    final pagamentosMesclados = List<PagamentoFuncionario>.from(
      lojaMesclada.pagamentosFuncionarios,
    );
    final idsPagamentos = pagamentosMesclados.map((pg) => pg.id).toSet();
    for (final pgLocal in lojaLocal.pagamentosFuncionarios) {
      if (idsPagamentos.add(pgLocal.id)) {
        pagamentosMesclados.add(pgLocal);
        houveCura = true;
      }
    }
    pagamentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosLimitados = pagamentosMesclados.length > 1000
        ? pagamentosMesclados.sublist(0, 1000)
        : pagamentosMesclados;

    // 4. Turnos de Caixa (Finanças e Fechamento) - Map O(1) com união de movimentações
    final mapaTurnos = <String, TurnoCaixa>{
      for (final t in lojaMesclada.turnosCaixa) t.id: t,
    };
    for (final tLocal in lojaLocal.turnosCaixa) {
      final tExistente = mapaTurnos[tLocal.id];
      if (tExistente == null) {
        mapaTurnos[tLocal.id] = tLocal;
        houveCura = true;
      } else {
        final mesclado =
            ConsolidadorLojaLocal.mesclarDoisTurnosCaixa(tExistente, tLocal);
        if (mesclado.aberto != tExistente.aberto ||
            mesclado.movimentacoes.length != tExistente.movimentacoes.length) {
          mapaTurnos[tLocal.id] = mesclado;
          houveCura = true;
        }
      }
    }
    final turnosMesclados = mapaTurnos.values.toList()
      ..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

    // 5. Pedidos Programados - Soberania balcão preservando última execução mais recente
    final mapaProgramadosLocal = <String, PedidoProgramado>{
      for (final pp in lojaLocal.pedidosProgramados) pp.id: pp,
    };
    final programadosMesclados =
        lojaMesclada.pedidosProgramados.map((ppRemoto) {
      final ppLocal = mapaProgramadosLocal[ppRemoto.id];
      if (ppLocal != null && ppLocal.ultimaDataGerado != null) {
        if (ppRemoto.ultimaDataGerado == null ||
            ppLocal.ultimaDataGerado!.isAfter(ppRemoto.ultimaDataGerado!)) {
          houveCura = true;
          return ppRemoto.copyWith(ultimaDataGerado: ppLocal.ultimaDataGerado);
        }
      }
      return ppRemoto;
    }).toList();

    // 6. Cargos Personalizados - Set O(1)
    final cargosMesclados =
        List<CargoLoja>.from(lojaMesclada.cargosPersonalizados);
    final idsCargos = cargosMesclados.map((c) => c.id).toSet();
    for (final cLocal in lojaLocal.cargosPersonalizados) {
      if (idsCargos.add(cLocal.id)) {
        cargosMesclados.add(cLocal);
        houveCura = true;
      }
    }

    // 7. Gastos Diários Operacionais - Set O(1)
    final gastosMesclados =
        List<GastoDiario>.from(lojaMesclada.gastosDiarios);
    final idsGastos = gastosMesclados.map((g) => g.id).toSet();
    for (final gLocal in lojaLocal.gastosDiarios) {
      if (idsGastos.add(gLocal.id)) {
        gastosMesclados.add(gLocal);
        houveCura = true;
      }
    }

    // 8. Gastos Fixos Recorrentes
    final gastosFixosMesclados =
        List<GastoFixo>.from(lojaMesclada.gastosFixos);
    final idsGastosFixos = gastosFixosMesclados.map((g) => g.id).toSet();
    for (final gLocal in lojaLocal.gastosFixos) {
      if (idsGastosFixos.add(gLocal.id)) {
        gastosFixosMesclados.add(gLocal);
        houveCura = true;
      }
    }

    // 9. Contratos de Trabalho
    final contratosMesclados =
        List<ContratoTrabalhoMembro>.from(lojaMesclada.contratosTrabalho);
    final cpfsContratos = contratosMesclados.map((c) => c.cpf).toSet();
    for (final cLocal in lojaLocal.contratosTrabalho) {
      if (cpfsContratos.add(cLocal.cpf)) {
        contratosMesclados.add(cLocal);
        houveCura = true;
      }
    }

    // 10. Registros de Ponto
    final pontosMesclados =
        List<RegistroPontoMembro>.from(lojaMesclada.registrosPonto);
    final idsPontos = pontosMesclados.map((p) => p.id).toSet();
    for (final pLocal in lojaLocal.registrosPonto) {
      if (idsPontos.add(pLocal.id)) {
        pontosMesclados.add(pLocal);
        houveCura = true;
      }
    }

    // 11. Escalas de Trabalho
    final escalasMescladas =
        List<EscalaTrabalhoMembro>.from(lojaMesclada.escalasTrabalho);
    final cpfsEscalas = escalasMescladas.map((e) => e.cpf).toSet();
    for (final eLocal in lojaLocal.escalasTrabalho) {
      if (cpfsEscalas.add(eLocal.cpf)) {
        escalasMescladas.add(eLocal);
        houveCura = true;
      }
    }

    lojaMesclada = lojaMesclada.copyWith(
      pedidosLoja: pedidosMesclados,
      movimentosEstoque: movimentosLimitados,
      pagamentosFuncionarios: pagamentosLimitados,
      turnosCaixa: turnosMesclados,
      pedidosProgramados: programadosMesclados,
      cargosPersonalizados: cargosMesclados,
      gastosDiarios: gastosMesclados,
      gastosFixos: gastosFixosMesclados,
      contratosTrabalho: contratosMesclados,
      registrosPonto: pontosMesclados,
      escalasTrabalho: escalasMescladas,
    );

    return ResultadoMesclagemEntidades(
      loja: lojaMesclada,
      houveCuraNoServidor: houveCura,
    );
  }
}
