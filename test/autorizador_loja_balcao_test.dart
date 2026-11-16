import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/autorizador_loja_balcao.dart';

void main() {
  group('AutorizadorLojaBalcao', () {
    final lojaProvidence = Loja(
      id: 'loja_providence',
      nome: 'Marmitaria Providence',
      cnpj: '00000000000100',
      telefone: '11999999999',
      endereco: 'Rua A',
      numero: '10',
      email: 'providence@nous.app',
      categorias: 'Alimentação',
      tags: 'marmitaria',
      cpfDonoOriginal: '11122233344',
      membros: [
        MembroLoja(
          cpf: '11122233344',
          nome: 'Claudiane',
          papel: PapelMembro.dono,
          desde: DateTime(2026, 1, 1),
        ),
      ],
    );

    final lojaBerenice = Loja(
      id: 'loja_berenice',
      nome: 'Loja Berenice',
      cnpj: '00000000000200',
      telefone: '11888888888',
      endereco: 'Rua B',
      numero: '20',
      email: 'berenice@nous.app',
      categorias: 'Alimentação',
      tags: 'lanches',
      cpfDonoOriginal: '99988877766',
      membros: [
        MembroLoja(
          cpf: '99988877766',
          nome: 'Berenice',
          papel: PapelMembro.dono,
          desde: DateTime(2026, 1, 1),
        ),
      ],
    );

    test('autoriza a loja ativa do balcão', () {
      final res = AutorizadorLojaBalcao.obterLojaHospedada(
        lojaIdBruto: 'loja_providence',
        lojaAtiva: lojaProvidence,
        pdvProvider: null,
        cpfOperadorBalcao: '11122233344',
      );
      expect(res?.id, 'loja_providence');
    });

    test('rejeita loja de terceiro que não está hospedada no balcão', () {
      final res = AutorizadorLojaBalcao.obterLojaHospedada(
        lojaIdBruto: lojaBerenice.id,
        lojaAtiva: lojaProvidence,
        pdvProvider: null,
        cpfOperadorBalcao: '11122233344',
      );
      expect(res, isNull);
    });

    test('rejeita loja_nous_coletiva para eventos de PDV', () {
      final res = AutorizadorLojaBalcao.obterLojaHospedada(
        lojaIdBruto: PdvProvider.idLojaColetivaNous,
        lojaAtiva: lojaProvidence,
        pdvProvider: null,
        cpfOperadorBalcao: '11122233344',
      );
      expect(res, isNull);
    });

    test('rejeita lojaId vazio sem fazer fallback silencioso', () {
      final res = AutorizadorLojaBalcao.obterLojaHospedada(
        lojaIdBruto: '',
        lojaAtiva: lojaProvidence,
        pdvProvider: null,
        cpfOperadorBalcao: '11122233344',
      );
      expect(res, isNull);
    });
  });
}
