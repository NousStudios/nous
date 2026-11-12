import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

/// Helper especialista para gerenciamento de membros e cargos no PDV.
class PdvMembrosCargosHelper {
  static Loja? garantirDono(
    Loja loja, {
    required String cpf,
    required String nome,
  }) {
    final precisaDefinirDonoOriginal = loja.cpfDonoOriginal.isEmpty;
    final precisaAdicionarMembro = loja.membros.isEmpty;

    if (!precisaDefinirDonoOriginal && !precisaAdicionarMembro) return null;

    final donoOriginal =
        precisaDefinirDonoOriginal ? cpf : loja.cpfDonoOriginal;
    final membros = precisaAdicionarMembro
        ? [
            MembroLoja(
              cpf: cpf,
              nome: nome,
              papel: PapelMembro.dono,
              desde: DateTime.now(),
            ),
          ]
        : loja.membros;

    return loja.copyWith(
      cpfDonoOriginal: donoOriginal,
      membros: membros,
    );
  }

  static Loja? adicionarMembro(Loja loja, MembroLoja membro) {
    if (loja.membros.any((m) => m.cpf == membro.cpf)) return null;
    return loja.copyWith(membros: [...loja.membros, membro]);
  }

  static Loja removerMembro(Loja loja, String cpfMembro) {
    final restantes =
        loja.membros.where((m) => m.cpf != cpfMembro).toList();
    return loja.copyWith(membros: restantes);
  }

  static Loja atualizarPapelMembro(
    Loja loja,
    String cpf,
    PapelMembro papel,
  ) {
    final novos = loja.membros
        .map((m) => m.cpf == cpf ? m.copyWith(papel: papel) : m)
        .toList();
    return loja.copyWith(membros: novos);
  }

  static Loja adicionarCargoLoja(Loja loja, CargoLoja cargo) {
    final novos = [...loja.cargosPersonalizados, cargo];
    return loja.copyWith(cargosPersonalizados: novos);
  }

  static Loja atualizarCargoLoja(Loja loja, CargoLoja cargo) {
    final novos = loja.cargosPersonalizados
        .map((c) => c.id == cargo.id ? cargo : c)
        .toList();
    return loja.copyWith(cargosPersonalizados: novos);
  }

  static Loja removerCargoLoja(Loja loja, String cargoId) {
    final novos =
        loja.cargosPersonalizados.where((c) => c.id != cargoId).toList();
    final membrosAtualizados = loja.membros.map((m) {
      if (m.cargoPersonalizadoId == cargoId) {
        return m.copyWith(cargoPersonalizadoId: null);
      }
      return m;
    }).toList();
    return loja.copyWith(
      cargosPersonalizados: novos,
      membros: membrosAtualizados,
    );
  }

  static Loja vincularCargoAoMembro(
    Loja loja,
    String cpf,
    String? cargoId,
  ) {
    final novos = loja.membros
        .map((m) => m.cpf == cpf
            ? m.copyWith(
                cargoPersonalizadoId: cargoId,
                limparCargoPersonalizado: cargoId == null || cargoId.isEmpty,
              )
            : m)
        .toList();
    return loja.copyWith(membros: novos);
  }

  static Loja atualizarPermissoesCargoNativo(
    Loja loja,
    String papel,
    Map<String, bool> permissoes,
  ) {
    final novoMapa =
        Map<String, Map<String, bool>>.from(loja.permissoesCargosNativos);
    novoMapa[papel] = permissoes;
    return loja.copyWith(permissoesCargosNativos: novoMapa);
  }

  static int pesoPapel(PapelMembro p) {
    if (p == PapelMembro.socio) return 0;
    if (p == PapelMembro.admin) return 1;
    if (p == PapelMembro.funcionario) return 2;
    return 3;
  }

  static Loja alternarFuncaoDesenvolvedor(Loja loja, String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    final novosMembros = loja.membros.map((m) {
      if (m.cpf.replaceAll(RegExp(r'\D'), '') == digitos) {
        final ehDev = m.cargoPersonalizadoId == 'desenvolvedor';
        return m.copyWith(
          cargoPersonalizadoId: ehDev ? null : 'desenvolvedor',
          limparCargoPersonalizado: ehDev,
        );
      }
      return m;
    }).toList();
    return loja.copyWith(membros: novosMembros);
  }
}
