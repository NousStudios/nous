import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';

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

  static Loja removerPedidoProgramado(Loja loja, String pedidoId) {
    return loja.copyWith(
      pedidosProgramados:
          loja.pedidosProgramados.where((p) => p.id != pedidoId).toList(),
    );
  }

  static Loja alternarAtivoPedidoProgramado(Loja loja, String pedidoId) {
    return loja.copyWith(
      pedidosProgramados: loja.pedidosProgramados.map((p) {
        if (p.id == pedidoId) {
          return p.copyWith(ativo: !p.ativo);
        }
        return p;
      }).toList(),
    );
  }

  static ({bool alterou, Loja loja}) verificarEGerar(Loja loja) {
    final agora = DateTime.now();

    bool mesmoDia(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    var alterou = false;
    final novosPedidosLoja = List<PedidoLoja>.from(loja.pedidosLoja);
    final novosProgramados = <PedidoProgramado>[];

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
          return false;
        });

        if (!jaExisteHoje &&
            (prog.ultimaDataGerado == null || !mesmoDia(prog.ultimaDataGerado, agora))) {
          maiorNumero++;
          final novoPedido = prog.toPedidoLoja(
            numero: maiorNumero,
            dataHora: agora,
            nomeVendedor: loja.nome,
            cnpjVendedor: loja.cnpj,
          );
          novosPedidosLoja.insert(0, novoPedido);
          novosProgramados.add(prog.copyWith(ultimaDataGerado: agora));
          alterou = true;
          continue;
        } else if (jaExisteHoje &&
            (prog.ultimaDataGerado == null || !mesmoDia(prog.ultimaDataGerado, agora))) {
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
      return (alterou: true, loja: atualizada);
    }

    return (alterou: false, loja: loja);
  }
}
