import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

/// Helper especialista para operações de turno e movimentação de caixa no PDV.
class PdvCaixaHelper {
  static Loja abrirCaixa(
    Loja loja, {
    required double saldoInicial,
    required String cpf,
    required String nome,
  }) {
    final novoTurno = TurnoCaixa.abrir(
      saldoInicial: saldoInicial,
      abertoPorCpf: cpf,
      abertoPorNome: nome,
    );

    final novosTurnos = [...loja.turnosCaixa, novoTurno];
    return loja.copyWith(turnosCaixa: novosTurnos);
  }

  static Loja? registrarMovimentoCaixa(
    Loja loja, {
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required String cpf,
    required String nome,
  }) {
    final aberto = loja.turnoCaixaAberto;
    if (aberto == null) return null;

    final mov = MovimentoCaixa.novo(
      tipo: tipo,
      valor: valor,
      motivo: motivo,
      autorCpf: cpf,
      autorNome: nome,
    );

    final turnoAtualizado = aberto.copyWith(
      movimentacoes: [...aberto.movimentacoes, mov],
    );

    final novosTurnos = loja.turnosCaixa
        .map((t) => t.id == turnoAtualizado.id ? turnoAtualizado : t)
        .toList();

    return loja.copyWith(turnosCaixa: novosTurnos);
  }

  static Loja? fecharCaixa(
    Loja loja, {
    required double saldoInformado,
    required String cpf,
    required String nome,
    String observacao = '',
  }) {
    final aberto = loja.turnoCaixaAberto;
    if (aberto == null) return null;

    final turnoFechado = aberto.copyWith(
      status: StatusTurnoCaixa.fechado,
      dataFechamento: DateTime.now(),
      fechadoPorCpf: cpf,
      fechadoPorNome: nome,
      saldoFinalInformado: saldoInformado,
      observacao: observacao,
    );

    final novosTurnos = loja.turnosCaixa
        .map((t) => t.id == turnoFechado.id ? turnoFechado : t)
        .toList();

    return loja.copyWith(turnosCaixa: novosTurnos);
  }

  static Loja excluirTurnoCaixa(Loja loja, String turnoId) {
    final novosTurnos = loja.turnosCaixa.where((t) => t.id != turnoId).toList();
    return loja.copyWith(turnosCaixa: novosTurnos);
  }
}
