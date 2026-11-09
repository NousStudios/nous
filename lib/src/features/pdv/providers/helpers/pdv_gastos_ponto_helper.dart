import 'package:nous/src/features/pdv/models/contrato_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';

/// Helper desacoplado para gestão de gastos diários, gastos fixos,
/// registros de ponto e contratos de trabalho no PDV.
class PdvGastosPontoHelper {
  PdvGastosPontoHelper._();

  static Loja adicionarGastoDiario(Loja loja, GastoDiario gasto) {
    final novos = [gasto, ...loja.gastosDiarios];
    return loja.copyWith(gastosDiarios: novos);
  }

  static Loja removerGastoDiario(Loja loja, String gastoId) {
    final novos = loja.gastosDiarios.where((g) => g.id != gastoId).toList();
    return loja.copyWith(gastosDiarios: novos);
  }

  static Loja quitarGastoDiario(Loja loja, String gastoId) {
    final novos = loja.gastosDiarios.map((g) {
      if (g.id == gastoId) return g.copyWith(pago: true);
      return g;
    }).toList();
    return loja.copyWith(gastosDiarios: novos);
  }

  static Loja adicionarGastoFixo(Loja loja, GastoFixo gasto) {
    final novos = [gasto, ...loja.gastosFixos];
    return loja.copyWith(gastosFixos: novos);
  }

  static Loja removerGastoFixo(Loja loja, String gastoId) {
    final novos = loja.gastosFixos.where((g) => g.id != gastoId).toList();
    return loja.copyWith(gastosFixos: novos);
  }

  static Loja alternarAtivoGastoFixo(Loja loja, String gastoId) {
    final novos = loja.gastosFixos.map((g) {
      if (g.id == gastoId) return g.copyWith(ativo: !g.ativo);
      return g;
    }).toList();
    return loja.copyWith(gastosFixos: novos);
  }

  static Loja salvarContratoTrabalho(Loja loja, ContratoTrabalhoMembro contrato) {
    final outros = loja.contratosTrabalho.where((c) => c.cpf != contrato.cpf).toList();
    final novos = [contrato, ...outros];
    return loja.copyWith(contratosTrabalho: novos);
  }

  static Loja registrarPonto(Loja loja, RegistroPontoMembro ponto) {
    final novos = [ponto, ...loja.registrosPonto];
    return loja.copyWith(registrosPonto: novos);
  }

  static Loja finalizarPonto(Loja loja, String pontoId, DateTime dataHoraSaida) {
    final novos = loja.registrosPonto.map((p) {
      if (p.id == pontoId) return p.copyWith(dataHoraSaida: dataHoraSaida);
      return p;
    }).toList();
    return loja.copyWith(registrosPonto: novos);
  }

  static Loja salvarEscalaTrabalho(Loja loja, EscalaTrabalhoMembro escala) {
    final outros = loja.escalasTrabalho.where((e) => e.cpf != escala.cpf).toList();
    final novos = [escala, ...outros];
    return loja.copyWith(escalasTrabalho: novos);
  }

  static Loja quitarPagamentoFuncionario(Loja loja, String pagamentoId) {
    final novos = loja.pagamentosFuncionarios.map((p) {
      if (p.id == pagamentoId) return p.copyWith(pago: true);
      return p;
    }).toList();
    return loja.copyWith(pagamentosFuncionarios: novos);
  }

  static Loja quitarCompraEstoque(Loja loja, String movimentoId) {
    final novos = loja.movimentosEstoque.map((m) {
      if (m.id == movimentoId) return m.copyWith(pago: true);
      return m;
    }).toList();
    return loja.copyWith(movimentosEstoque: novos);
  }
}
