import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';

void main() {
  group('Busca Universal de Clientes e Fornecedores', () {
    final cliente = Cliente(
      id: 'cli_1',
      nome: 'Maria da Silva',
      cnpj: '123.456.789-00',
      telefone: '(11) 98765-4321',
      endereco: 'Rua das Flores',
      numero: '123B',
      email: 'maria@email.com',
      redesSociais: '@mariadasilva',
      descricao: 'Cliente preferencial de doces',
    );

    final fornecedor = Fornecedor(
      id: 'forn_1',
      nome: 'Distribuidora Central Ltda',
      dataCriacao: DateTime(2026, 10, 9),
      cnpj: '12.345.678/0001-90',
      telefone: '(11) 3333-4444',
      endereco: 'Avenida Brasil',
      numero: '1000',
      email: 'contato@distribuidora.com',
      redesSociais: '@distribuidoracentral',
      descricao: 'Fornecedor de embalagens',
    );

    test('Busca de cliente por rua/logradouro', () {
      expect(cliente.correspondeABusca('Flores'), isTrue);
      expect(cliente.correspondeABusca('rua das flores'), isTrue);
      expect(cliente.correspondeABusca('Avenida'), isFalse);
    });

    test('Busca de cliente por número da casa', () {
      expect(cliente.correspondeABusca('123B'), isTrue);
      expect(cliente.correspondeABusca('123b'), isTrue);
      expect(cliente.correspondeABusca('999'), isFalse);
    });

    test('Busca de cliente por CPF com e sem formatação', () {
      expect(cliente.correspondeABusca('123.456.789-00'), isTrue);
      expect(cliente.correspondeABusca('12345678900'), isTrue);
      expect(cliente.correspondeABusca('456789'), isTrue);
      expect(cliente.correspondeABusca('999888'), isFalse);
    });

    test('Busca de cliente por telefone com e sem formatação', () {
      expect(cliente.correspondeABusca('(11) 98765-4321'), isTrue);
      expect(cliente.correspondeABusca('987654321'), isTrue);
      expect(cliente.correspondeABusca('1198765'), isTrue);
    });

    test('Busca de cliente por email, rede social ou descrição', () {
      expect(cliente.correspondeABusca('maria@email.com'), isTrue);
      expect(cliente.correspondeABusca('@mariadasilva'), isTrue);
      expect(cliente.correspondeABusca('preferencial'), isTrue);
    });

    test('Busca de fornecedor por rua, cnpj ou número', () {
      expect(fornecedor.correspondeABusca('Brasil'), isTrue);
      expect(fornecedor.correspondeABusca('1000'), isTrue);
      expect(fornecedor.correspondeABusca('12345678000190'), isTrue);
      expect(fornecedor.correspondeABusca('embalagens'), isTrue);
    });
  });
}
