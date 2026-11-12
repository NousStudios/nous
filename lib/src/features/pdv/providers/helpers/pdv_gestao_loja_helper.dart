import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Helper especializado em filtragem de lojas (administração/participação)
/// e atualização dos campos cadastrais e coleções de uma Loja.
class PdvGestaoLojaHelper {
  PdvGestaoLojaHelper._();

  static bool mesmoCpf(String? a, String? b) {
    if (a == null || b == null) return false;
    final aDigitos = a.replaceAll(RegExp(r'\D'), '');
    final bDigitos = b.replaceAll(RegExp(r'\D'), '');
    if (aDigitos.isEmpty || bDigitos.isEmpty) return a.trim() == b.trim();
    return aDigitos == bDigitos;
  }

  static List<Loja> lojasQueAdministro(
    List<Loja> lojas,
    String? cpf,
    String idLojaColetivaNous,
  ) {
    if (cpf == null) return [];
    return lojas.where((l) {
      if (l.id == idLojaColetivaNous) return false;
      return l.membros.any((m) =>
          mesmoCpf(m.cpf, cpf) &&
          (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio));
    }).toList();
  }

  static List<Loja> lojasQueParticipo(
    List<Loja> lojas,
    String? cpf,
    String idLojaColetivaNous,
  ) {
    if (cpf == null) return [];
    final lista = lojas.where((l) {
      if (l.id == idLojaColetivaNous) {
        return l.membros.any((m) => mesmoCpf(m.cpf, cpf));
      }
      return l.membros.any((m) =>
          mesmoCpf(m.cpf, cpf) &&
          (m.papel == PapelMembro.admin ||
              m.papel == PapelMembro.funcionario));
    }).toList();

    final lojaNous =
        lojas.where((l) => l.id == idLojaColetivaNous).firstOrNull;
    if (lojaNous != null && !lista.any((l) => l.id == idLojaColetivaNous)) {
      lista.insert(0, lojaNous);
    }
    return lista;
  }

  static Loja atualizarDadosLoja(
    Loja loja, {
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    required String redesSociais,
    required String categorias,
    required String tags,
    String? logo,
  }) {
    return loja.copyWith(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo ?? loja.logo,
    );
  }

  static Loja atualizarColecoesLoja(
    Loja loja, {
    List<CategoriaLoja>? categorias,
    List<ItemLoja>? itens,
    List<GrupoComponentesLoja>? gruposComponentes,
    List<Cliente>? clientes,
    List<Fornecedor>? fornecedores,
    List<PedidoLoja>? pedidos,
    List<MesaLoja>? mesas,
    List<MovimentoEstoque>? movimentosEstoque,
    List<PagamentoFuncionario>? pagamentosFuncionarios,
  }) {
    return loja.copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      fornecedoresLoja: fornecedores,
      pedidosLoja: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
      pagamentosFuncionarios: pagamentosFuncionarios,
    );
  }

  static Loja criarNovaLoja({
    required String cpf,
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    String redesSociais = '',
    required String categorias,
    required String tags,
    String logo = '',
  }) {
    return Loja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfDonoOriginal: cpf,
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo,
    );
  }

  static String normalizarIdLoja(String id, String idLojaColetivaNous) {
    var limpo = id.trim();
    if (limpo.startsWith('loja_') && limpo != idLojaColetivaNous) {
      limpo = limpo.substring(5);
    }
    if (limpo.contains('_usuario_')) {
      limpo = limpo.split('_usuario_').first;
    }
    return limpo;
  }

  static Loja? buscarPorId(List<Loja> lojas, String id, String idLojaColetivaNous) {
    final idLimpo = normalizarIdLoja(id, idLojaColetivaNous);
    for (final loja in lojas) {
      if (normalizarIdLoja(loja.id, idLojaColetivaNous) == idLimpo || loja.id == id || loja.id == idLimpo) {
        return loja;
      }
    }
    return null;
  }

  static Loja? consolidarEAtualizarLojaNaLista(List<Loja> lojas, Loja loja) {
    if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) return null;
    final indice = lojas.indexWhere((l) => l.id == loja.id);
    final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(
      loja,
      indice != -1 ? lojas[indice] : null,
    );
    if (indice != -1) {
      lojas[indice] = lojaConsolidada;
    } else {
      lojas.add(lojaConsolidada);
    }
    return lojaConsolidada;
  }
}
