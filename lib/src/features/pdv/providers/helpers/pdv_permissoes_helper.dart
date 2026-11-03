import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

/// Helper especialista para validação de permissões e resolução de membros no PDV.
class PdvPermissoesHelper {
  static bool mesmoCpf(String? a, String? b) {
    if (a == null || b == null) return false;
    final aDigitos = a.replaceAll(RegExp(r'\D'), '');
    final bDigitos = b.replaceAll(RegExp(r'\D'), '');
    if (aDigitos.isEmpty || bDigitos.isEmpty) return a.trim() == b.trim();
    return aDigitos == bDigitos;
  }

  static MembroLoja? resolverMeuMembro(Loja? loja, String? cpfAtual) {
    if (cpfAtual == null || loja == null) return null;
    for (final m in loja.membros) {
      if (mesmoCpf(m.cpf, cpfAtual)) return m;
    }
    if (loja.cpfDonoOriginal.isNotEmpty && mesmoCpf(loja.cpfDonoOriginal, cpfAtual)) {
      return MembroLoja(
        cpf: cpfAtual,
        nome: 'Dono',
        papel: PapelMembro.dono,
        desde: DateTime.now(),
      );
    }
    return null;
  }

  static CargoLoja? resolverMeuCargoPersonalizado(Loja? loja, MembroLoja? membro) {
    if (loja == null || membro == null || membro.cargoPersonalizadoId == null) {
      return null;
    }
    return loja.cargosPersonalizados
        .where((c) => c.id == membro.cargoPersonalizadoId)
        .firstOrNull;
  }

  static bool podeEditarAbaLoja(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.editarAbaLoja);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.editarAbaLoja);
  }

  static bool podeUsarImpressora(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.usarImpressora);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.usarImpressora);
  }

  static bool podeEditarDadosLoja(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.editarDadosLoja);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.editarDadosLoja);
  }

  static bool podeUsarFinanceiro(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.usarFinanceiro);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.usarFinanceiro);
  }

  static bool podeRegistrarPagamento(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.registrarPagamento);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.registrarPagamento);
  }

  static bool podeGerenciarMembros(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.gerenciarMembros);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.gerenciarMembros);
  }

  static bool podeResetarTransacoes(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.resetarTransacoes);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.resetarTransacoes);
  }

  static bool podeExcluirLoja(Loja? loja, String? cpfAtual) {
    final m = resolverMeuMembro(loja, cpfAtual);
    if (m == null || loja == null) return false;
    if (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio) return true;
    final cargo = resolverMeuCargoPersonalizado(loja, m);
    if (cargo != null) {
      return cargo.temPermissao(PermissaoLojaConst.excluirLoja);
    }
    return loja.temPermissaoPapel(m.papel.name, PermissaoLojaConst.excluirLoja);
  }
}
