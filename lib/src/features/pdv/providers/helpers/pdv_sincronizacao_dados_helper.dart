import 'dart:io';

import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

/// Helper desacoplado para busca, sincronização pan-lojas de dados de usuários/clientes
/// e cálculo de alertas de estoque baixo no PDV.
class PdvSincronizacaoDadosHelper {
  PdvSincronizacaoDadosHelper._();

  /// Calcula lista de itens com estoque baixo (< 10) em todas as lojas ou em uma específica
  static List<({ItemLoja item, double saldo, String lojaNome, String lojaId})> itensEstoqueBaixo(
    List<Loja> lojas, {
    String? lojaId,
  }) {
    final alertas = <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[];
    final lojasAlvo = lojaId != null ? lojas.where((l) => l.id == lojaId) : lojas;

    for (final loja in lojasAlvo) {
      for (final item in loja.itensLoja) {
        if (item.tipo == TipoItemLoja.servico) continue;
        var saldo = 0.0;
        var temMovimento = false;
        for (final m in loja.movimentosEstoque) {
          if (m.itemId == item.id) {
            saldo += m.quantidadeComSinal;
            temMovimento = true;
          }
        }
        if (temMovimento && saldo < 10) {
          alertas.add((
            item: item,
            saldo: saldo,
            lojaNome: loja.nome,
            lojaId: loja.id,
          ));
        }
      }
    }
    return alertas;
  }

  /// Busca a foto física do cliente pelo CPF em todas as lojas carregadas
  static String? buscarFotoClientePorCpf(List<Loja> lojas, String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos &&
            cliente.foto.isNotEmpty &&
            (loja.logo.isEmpty || cliente.foto != loja.logo) &&
            File(cliente.foto).existsSync()) {
          return cliente.foto;
        }
      }
    }
    return null;
  }

  /// Busca o cliente pelo CPF em todas as lojas carregadas
  static Cliente? buscarClientePorCpf(List<Loja> lojas, String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos) {
          return cliente;
        }
      }
    }
    return null;
  }

  /// Atualiza a foto do usuário em todos os cadastros de clientes/fornecedores nas lojas
  static Future<bool> sincronizarFotoUsuarioEmClientes({
    required List<Loja> lojas,
    required String cpf,
    required String novaFoto,
    required Future<void> Function(Loja) salvarNoCofre,
  }) async {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return false;
    var houveAlteracaoGeral = false;

    for (int i = 0; i < lojas.length; i++) {
      final loja = lojas[i];
      var alterou = false;
      final novosClientes = loja.clientesLoja.map((c) {
        final cDigits = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos && c.foto != novaFoto) {
          alterou = true;
          return c.copyWith(foto: novaFoto);
        }
        return c;
      }).toList();

      final novosFornecedores = loja.fornecedoresLoja.map((f) {
        final fDigits = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (fDigits == digitos && f.foto != novaFoto) {
          alterou = true;
          return f.copyWith(foto: novaFoto);
        }
        return f;
      }).toList();

      if (alterou) {
        houveAlteracaoGeral = true;
        final atualizada = loja.copyWith(
          clientesLoja: novosClientes,
          fornecedoresLoja: novosFornecedores,
        );
        lojas[i] = atualizada;
        await salvarNoCofre(atualizada);
      }
    }
    return houveAlteracaoGeral;
  }

  /// Atualiza o nome e foto do usuário em membros, clientes e fornecedores de todas as lojas
  static Future<bool> sincronizarDadosUsuarioEmLojas({
    required List<Loja> lojas,
    required UsuarioNous usuario,
    required Future<void> Function(Loja) salvarNoCofre,
  }) async {
    final digitos = usuario.cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return false;
    final nomeValido = usuario.nome.trim();
    final ehNomeSpurio = nomeValido.isEmpty ||
        nomeValido.toLowerCase() == 'blackview' ||
        nomeValido.toLowerCase() == 'celular';

    var houveAlteracaoGeral = false;

    for (int i = 0; i < lojas.length; i++) {
      final loja = lojas[i];
      var alterou = false;

      final novosMembros = loja.membros.map((m) {
        final mDigits = m.cpf.replaceAll(RegExp(r'[^0-9]'), '');
        if (mDigits == digitos) {
          if (!ehNomeSpurio && m.nome != nomeValido) {
            alterou = true;
            return m.copyWith(nome: nomeValido);
          }
        }
        return m;
      }).toList();

      final novosClientes = loja.clientesLoja.map((c) {
        final cDigits = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos) {
          var clienteAtualizado = c;
          if (usuario.foto.isNotEmpty && c.foto != usuario.foto) {
            alterou = true;
            clienteAtualizado = clienteAtualizado.copyWith(foto: usuario.foto);
          }
          if (!ehNomeSpurio && c.nome != nomeValido) {
            alterou = true;
            clienteAtualizado = clienteAtualizado.copyWith(nome: nomeValido);
          }
          return clienteAtualizado;
        }
        return c;
      }).toList();

      final novosFornecedores = loja.fornecedoresLoja.map((f) {
        final fDigits = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (fDigits == digitos &&
            usuario.foto.isNotEmpty &&
            f.foto != usuario.foto) {
          alterou = true;
          return f.copyWith(foto: usuario.foto);
        }
        return f;
      }).toList();

      if (alterou) {
        houveAlteracaoGeral = true;
        final atualizada = loja.copyWith(
          membros: novosMembros,
          clientesLoja: novosClientes,
          fornecedoresLoja: novosFornecedores,
        );
        lojas[i] = atualizada;
        await salvarNoCofre(atualizada);
      }
    }
    return houveAlteracaoGeral;
  }
}
