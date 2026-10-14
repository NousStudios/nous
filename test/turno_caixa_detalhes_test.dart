import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

void main() {
  group('Turno de Caixa - Detalhes, Movimentações e Exclusão', () {
    test('Exclusão de turno de caixa remove da lista de turnos da loja e serializa', () {
      final turno1 = TurnoCaixa(
        id: 'turno_1',
        dataAbertura: DateTime.now().subtract(const Duration(hours: 5)),
        dataFechamento: DateTime.now().subtract(const Duration(hours: 1)),
        saldoInicial: 100.0,
        saldoFinalInformado: 150.0,
        status: StatusTurnoCaixa.fechado,
      );
      final turno2 = TurnoCaixa(
        id: 'turno_2',
        dataAbertura: DateTime.now().subtract(const Duration(minutes: 30)),
        saldoInicial: 200.0,
        status: StatusTurnoCaixa.aberto,
      );

      final loja = Loja(
        id: 'loja_teste',
        nome: 'Mercearia Teste',
        cnpj: '12.345.678/0001-90',
        telefone: '62988887777',
        endereco: 'Rua Principal',
        numero: '100',
        email: 'loja@teste.com',
        categorias: 'Geral',
        tags: 'geral',
        turnosCaixa: [turno1, turno2],
      );

      expect(loja.turnosCaixa.length, equals(2));

      // Simulando a lógica de exclusão aplicada pelo PdvProvider
      final novosTurnos = loja.turnosCaixa.where((t) => t.id != 'turno_1').toList();
      final lojaAtualizada = loja.copyWith(turnosCaixa: novosTurnos);

      expect(lojaAtualizada.turnosCaixa.length, equals(1));
      expect(lojaAtualizada.turnosCaixa.first.id, equals('turno_2'));

      // Testando a persistência JSON
      final json = lojaAtualizada.toJson();
      final reconstruida = Loja.fromJson(json);
      expect(reconstruida.turnosCaixa.length, equals(1));
      expect(reconstruida.turnosCaixa.first.id, equals('turno_2'));
    });

    test('Movimentações de sangria e suprimento calculam totais e identificam autor', () {
      final sangria = MovimentoCaixa(
        id: 'mov_1',
        dataHora: DateTime.now(),
        tipo: TipoMovimentoCaixa.sangria,
        valor: 50.0,
        motivo: 'Pagamento de gás',
        autorCpf: '111.222.333-44',
        autorNome: 'Carlos Silva',
      );

      final suprimento = MovimentoCaixa(
        id: 'mov_2',
        dataHora: DateTime.now(),
        tipo: TipoMovimentoCaixa.suprimento,
        valor: 100.0,
        motivo: 'Troco extra',
        autorCpf: '555.666.777-88',
        autorNome: 'Ana Souza',
      );

      final turno = TurnoCaixa(
        id: 'turno_fechado',
        dataAbertura: DateTime.now().subtract(const Duration(hours: 4)),
        dataFechamento: DateTime.now(),
        saldoInicial: 150.0,
        saldoFinalInformado: 200.0,
        status: StatusTurnoCaixa.fechado,
        movimentacoes: [sangria, suprimento],
      );

      expect(turno.totalSangrias, equals(50.0));
      expect(turno.totalSuprimentos, equals(100.0));
      expect(turno.movimentacoes.first.autorNome, equals('Carlos Silva'));
      expect(turno.movimentacoes.first.motivo, equals('Pagamento de gás'));
    });

    test('TipoAcao.turnoCaixaExcluido serializa e desserializa perfeitamente em RegistroAcao', () {
      final acao = RegistroAcao(
        id: 'acao_1',
        dataHora: DateTime.now(),
        tipo: TipoAcao.turnoCaixaExcluido,
        descricao: 'Registro de turno de caixa excluído',
        cpfAutor: '12345678901',
        nomeAutor: 'Operador Admin',
        emailAutor: 'admin@nous.local',
      );

      final json = acao.toJson();
      expect(json['tipo'], equals('turnoCaixaExcluido'));

      final reconstruida = RegistroAcao.fromJson(json);
      expect(reconstruida.tipo, equals(TipoAcao.turnoCaixaExcluido));
      expect(reconstruida.descricao, equals('Registro de turno de caixa excluído'));
    });
  });
}
