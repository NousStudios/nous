import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Helper especialista para gestão e disparo automático de pedidos programados.
class PdvPedidosProgramadosHelper {
  static List<PedidoProgramado> pedidosProgramadosDoDia(Loja? loja, [DateTime? data]) {
    if (loja == null) return const [];
    final dia = data ?? DateTime.now();
    return loja.pedidosProgramados.where((p) => p.coincideComData(dia)).toList();
  }

  static Loja adicionarPedidoProgramado(Loja loja, PedidoProgramado pedido) {
    return loja.copyWith(
      pedidosProgramados: [pedido, ...loja.pedidosProgramados],
    );
  }

  static ({Loja loja, List<String> idsPedidosRemovidos}) atualizarPedidoProgramado(
    Loja loja,
    PedidoProgramado pedido,
  ) {
    final agora = DateTime.now();
    bool mesmoDia(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final diaStr = agora.day.toString().padLeft(2, '0');
    final mesStr = agora.month.toString().padLeft(2, '0');
    final idEsperadoHoje = 'prog_${pedido.id}_${agora.year}_${mesStr}_$diaStr';

    final idsRemovidos = <String>[];
    final novosPedidosLoja = <PedidoLoja>[];
    var temPedidoHoje = false;

    for (final p in loja.pedidosLoja) {
      final ehDesteProgHoje = p.id == idEsperadoHoje ||
          (p.id.startsWith('prog_${pedido.id}_') && mesmoDia(p.dataHora, agora));
      if (ehDesteProgHoje) {
        if (!pedido.coincideComData(agora) && p.status == StatusPedido.novo) {
          idsRemovidos.add(p.id);
          continue;
        }
        temPedidoHoje = true;
        if (p.status == StatusPedido.novo) {
          novosPedidosLoja.add(
            pedido.toPedidoLoja(
              numero: p.numero,
              dataHora: p.dataHora,
              nomeVendedor: p.nomeVendedor,
              cnpjVendedor: p.cnpjVendedor,
              lojaId: p.lojaId,
            ),
          );
          continue;
        }
      }
      novosPedidosLoja.add(p);
    }

    final pedidoAjustado = (!temPedidoHoje &&
            pedido.coincideComData(agora) &&
            mesmoDia(pedido.ultimaDataGerado, agora))
        ? PedidoProgramado(
            id: pedido.id,
            lojaId: pedido.lojaId,
            clienteId: pedido.clienteId,
            clienteNome: pedido.clienteNome,
            clienteTelefone: pedido.clienteTelefone,
            clienteEndereco: pedido.clienteEndereco,
            itens: pedido.itens,
            valorTotal: pedido.valorTotal,
            formaPagamento: pedido.formaPagamento,
            horario: pedido.horario,
            recorrente: pedido.recorrente,
            modoProgramacao: pedido.modoProgramacao,
            diasSemana: pedido.diasSemana,
            datasEspecificas: pedido.datasEspecificas,
            dataProgramada: pedido.dataProgramada,
            ativo: pedido.ativo,
            dataCriacao: pedido.dataCriacao,
            ultimaDataGerado: null,
            observacao: pedido.observacao,
          )
        : pedido;

    final existe = loja.pedidosProgramados.any((p) => p.id == pedidoAjustado.id);
    final novosProgramados = existe
        ? loja.pedidosProgramados
            .map((p) => p.id == pedidoAjustado.id ? pedidoAjustado : p)
            .toList()
        : [pedidoAjustado, ...loja.pedidosProgramados];

    return (
      loja: loja.copyWith(
        pedidosProgramados: novosProgramados,
        pedidosLoja: novosPedidosLoja,
      ),
      idsPedidosRemovidos: idsRemovidos,
    );
  }

  static ({Loja loja, List<String> idsPedidosRemovidos}) removerPedidoProgramado(
    Loja loja,
    String pedidoId,
  ) {
    final idsRemovidos = <String>[];
    final novosPedidosLoja = <PedidoLoja>[];
    for (final p in loja.pedidosLoja) {
      if (p.id.startsWith('prog_${pedidoId}_') &&
          p.status == StatusPedido.novo) {
        idsRemovidos.add(p.id);
        continue;
      }
      novosPedidosLoja.add(p);
    }
    return (
      loja: loja.copyWith(
        pedidosProgramados:
            loja.pedidosProgramados.where((p) => p.id != pedidoId).toList(),
        pedidosLoja: novosPedidosLoja,
      ),
      idsPedidosRemovidos: idsRemovidos,
    );
  }

  static ({Loja loja, List<String> idsPedidosRemovidos}) alternarAtivoPedidoProgramado(
    Loja loja,
    String pedidoId,
  ) {
    final agora = DateTime.now();
    bool mesmoDia(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    var ficouAtivo = true;
    final novosProgramados = loja.pedidosProgramados.map((p) {
      if (p.id == pedidoId) {
        ficouAtivo = !p.ativo;
        final temPedidoHoje = loja.pedidosLoja.any((ped) =>
            ped.id.startsWith('prog_${p.id}_') && mesmoDia(ped.dataHora, agora));
        if (ficouAtivo && !temPedidoHoje && mesmoDia(p.ultimaDataGerado, agora)) {
          return PedidoProgramado(
            id: p.id,
            lojaId: p.lojaId,
            clienteId: p.clienteId,
            clienteNome: p.clienteNome,
            clienteTelefone: p.clienteTelefone,
            clienteEndereco: p.clienteEndereco,
            itens: p.itens,
            valorTotal: p.valorTotal,
            formaPagamento: p.formaPagamento,
            horario: p.horario,
            recorrente: p.recorrente,
            modoProgramacao: p.modoProgramacao,
            diasSemana: p.diasSemana,
            datasEspecificas: p.datasEspecificas,
            dataProgramada: p.dataProgramada,
            ativo: true,
            dataCriacao: p.dataCriacao,
            ultimaDataGerado: null,
            observacao: p.observacao,
          );
        }
        return p.copyWith(ativo: ficouAtivo);
      }
      return p;
    }).toList();

    final idsRemovidos = <String>[];
    final novosPedidosLoja = <PedidoLoja>[];
    for (final p in loja.pedidosLoja) {
      if (!ficouAtivo &&
          p.id.startsWith('prog_${pedidoId}_') &&
          p.status == StatusPedido.novo) {
        idsRemovidos.add(p.id);
        continue;
      }
      novosPedidosLoja.add(p);
    }

    return (
      loja: loja.copyWith(
        pedidosProgramados: novosProgramados,
        pedidosLoja: novosPedidosLoja,
      ),
      idsPedidosRemovidos: idsRemovidos,
    );
  }

  static ({bool alterou, Loja loja, List<PedidoLoja> pedidosGerados}) verificarEGerar(
    Loja loja,
  ) {
    final agora = DateTime.now();

    bool mesmoDia(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    var alterou = false;
    final novosPedidosLoja = List<PedidoLoja>.from(loja.pedidosLoja);
    final novosProgramados = <PedidoProgramado>[];
    final pedidosGerados = <PedidoLoja>[];

    var maiorNumero = 0;
    for (final p in novosPedidosLoja) {
      if (p.numero > maiorNumero) maiorNumero = p.numero;
    }

    for (final prog in loja.pedidosProgramados) {
      if (prog.ativo && prog.coincideComData(agora)) {
        final diaStr = agora.day.toString().padLeft(2, '0');
        final mesStr = agora.month.toString().padLeft(2, '0');
        final idEsperadoHoje = 'prog_${prog.id}_${agora.year}_${mesStr}_$diaStr';

        final jaExisteHoje = novosPedidosLoja.any((p) {
          if (p.id == idEsperadoHoje) return true;
          if (p.id.startsWith('prog_${prog.id}_') && mesmoDia(p.dataHora, agora)) return true;
          if (prog.clienteId.isNotEmpty &&
              p.clienteId == prog.clienteId &&
              mesmoDia(p.dataHora, agora) &&
              p.status != StatusPedido.cancelado) {
            return true;
          }
          return false;
        });

        final jaGeradoHoje = mesmoDia(prog.ultimaDataGerado, agora);

        if (!jaExisteHoje && !jaGeradoHoje) {
          maiorNumero++;
          final novoPedido = prog.toPedidoLoja(
            numero: maiorNumero,
            dataHora: agora,
            nomeVendedor: loja.nome,
            cnpjVendedor: loja.cnpj,
            lojaId: loja.id,
          );
          novosPedidosLoja.insert(0, novoPedido);
          pedidosGerados.add(novoPedido);
          novosProgramados.add(prog.copyWith(ultimaDataGerado: agora));
          alterou = true;
          continue;
        } else if ((jaExisteHoje || jaGeradoHoje) &&
            (prog.ultimaDataGerado == null || !jaGeradoHoje)) {
          novosProgramados.add(prog.copyWith(ultimaDataGerado: agora));
          alterou = true;
          continue;
        }
      }
      novosProgramados.add(prog);
    }

    if (alterou) {
      final atualizada = loja.copyWith(
        pedidosLoja: novosPedidosLoja,
        pedidosProgramados: novosProgramados,
      );
      return (
        alterou: true,
        loja: atualizada,
        pedidosGerados: pedidosGerados,
      );
    }

    return (
      alterou: false,
      loja: loja,
      pedidosGerados: const [],
    );
  }

  static Future<void> purgarPedidosRemovidos(List<String> ids, String lojaId) async {
    for (final pid in ids) {
      await LojasService.excluirPedidoIndividual(lojaId, pid);
    }
  }

  static void despacharPedidosGeradosNaRede(List<PedidoLoja> pedidos, String lojaId) {
    for (final novo in pedidos) {
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'pedido_adicionado',
          'lojaId': lojaId,
          'pedido': novo.toJson(),
        });
      }
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarPedido(novo);
      }
    }
  }
}
