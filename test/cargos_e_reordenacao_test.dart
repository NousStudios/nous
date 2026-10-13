import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

void main() {
  group('Cargos e Permissões Customizadas', () {
    test('Serialização e desserialização de CargoLoja', () {
      final cargo = CargoLoja(
        id: 'cargo_1',
        nome: 'Garçom',
        permissoes: {
          PermissaoLojaConst.usarFinanceiro: true,
          PermissaoLojaConst.editarAbaLoja: false,
        },
      );

      final json = cargo.toJson();
      final reconstruido = CargoLoja.fromJson(json);

      expect(reconstruido.id, 'cargo_1');
      expect(reconstruido.nome, 'Garçom');
      expect(reconstruido.temPermissao(PermissaoLojaConst.usarFinanceiro), true);
      expect(reconstruido.temPermissao(PermissaoLojaConst.editarAbaLoja), false);
      expect(reconstruido.temPermissao(PermissaoLojaConst.excluirLoja), false);
    });

    test('Loja armazena e serializa cargos personalizados e vínculo de membro', () {
      final cargo = CargoLoja(
        id: 'cargo_gerente',
        nome: 'Gerente Operacional',
        permissoes: {
          PermissaoLojaConst.editarAbaLoja: true,
          PermissaoLojaConst.usarImpressora: true,
          PermissaoLojaConst.registrarPagamento: true,
        },
      );

      final membro = MembroLoja(
        cpf: '11122233344',
        nome: 'Maria da Silva',
        papel: PapelMembro.funcionario,
        desde: DateTime(2026, 1, 1),
        cargoPersonalizadoId: 'cargo_gerente',
      );

      final loja = Loja(
        id: 'loja_1',
        nome: 'Marmitaria Popular',
        cnpj: '12345678000199',
        telefone: '62999998888',
        endereco: 'Rua das Flores',
        numero: '123',
        email: 'contato@marmitaria.com',
        categorias: 'Alimentação',
        tags: 'marmita, almoço',
        cargosPersonalizados: [cargo],
        membros: [membro],
      );

      final json = loja.toJson();
      final lojaCarregada = Loja.fromJson(json);

      expect(lojaCarregada.cargosPersonalizados.length, 1);
      expect(lojaCarregada.cargosPersonalizados.first.nome, 'Gerente Operacional');
      expect(lojaCarregada.membros.first.cargoPersonalizadoId, 'cargo_gerente');
      expect(
        lojaCarregada.cargosPersonalizados.first
            .temPermissao(PermissaoLojaConst.editarAbaLoja),
        true,
      );
    });
  });
}
