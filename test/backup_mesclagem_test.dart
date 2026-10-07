import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BackupService.mesmoDocumento compara CNPJs e CPFs ignorando pontuação', () {
    expect(
      BackupService.mesmoDocumento('40.922.918/0001-02', '40922918000102'),
      isTrue,
    );
    expect(
      BackupService.mesmoDocumento('123.456.789-00', '12345678900'),
      isTrue,
    );
    expect(
      BackupService.mesmoDocumento('40.922.918/0001-02', '11.222.333/0001-44'),
      isFalse,
    );
    expect(BackupService.mesmoDocumento('', ''), isFalse);
  });

  test('Mesclagem de loja preserva categoria Restaurante e mescla produtos, clientes e ações', () {
    final lojaAntigaBackup = Loja(
      id: 'loja-antiga-1',
      nome: 'Cantina do Leo',
      cnpj: '40.922.918/0001-02',
      telefone: '17981957287',
      endereco: 'Rua das Flores',
      numero: '100',
      email: 'contato@cantina.com',
      categorias: 'Loja Padrão',
      tags: 'comida, lanche',
      itensLoja: [
        ItemLoja(
          id: 'item-1',
          nome: 'X-Burger Artesanal',
          preco: '25.00',
          descricao: 'Delicioso hambúrguer artesanal',
        ),
        ItemLoja(
          id: 'item-2',
          nome: 'Refrigerante 350ml',
          preco: '6.00',
        ),
      ],
      clientesLoja: [
        Cliente(
          id: 'cli-1',
          nome: 'Carlos Silva',
          cnpj: '111.222.333-44',
          telefone: '17999991111',
        ),
      ],
      acoes: [
        RegistroAcao(
          id: 'act-1',
          tipo: TipoAcao.itemCriado,
          descricao: 'Criou X-Burger Artesanal',
          nomeAutor: 'Leonardo',
          cpfAutor: '47192956813',
          emailAutor: 'leo@email.com',
          dataHora: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    );

    final lojaAtualRestaurante = Loja(
      id: 'loja-atual-2',
      nome: 'Cantina do Leo',
      cnpj: '40922918000102',
      telefone: '17981957287',
      endereco: 'Rua das Flores',
      numero: '100',
      email: 'contato@cantina.com',
      categorias: 'Restaurante',
      tags: 'comida, lanche',
      mesas: [
        MesaLoja(id: 'm-1', numero: '01', status: StatusMesa.livre),
        MesaLoja(id: 'm-2', numero: '02', status: StatusMesa.ocupada),
      ],
      itensLoja: [
        ItemLoja(
          id: 'item-3',
          nome: 'Suco Natural',
          preco: '8.00',
        ),
      ],
      clientesLoja: [
        Cliente(
          id: 'cli-2',
          nome: 'Mariana Souza',
          cnpj: '555.666.777-88',
          telefone: '17999992222',
        ),
      ],
      acoes: [
        RegistroAcao(
          id: 'act-2',
          tipo: TipoAcao.mesaAberta,
          descricao: 'Abriu comanda da Mesa 02',
          nomeAutor: 'Leonardo',
          cpfAutor: '47192956813',
          emailAutor: 'leo@email.com',
          dataHora: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    final lojaMesclada = BackupService.mesclarLojas(
      existente: lojaAtualRestaurante,
      importada: lojaAntigaBackup,
    );

    // 1. Deve preservar a categoria "Restaurante"
    expect(lojaMesclada.categorias, 'Restaurante');

    // 2. Deve preservar as mesas cadastradas na loja atual
    expect(lojaMesclada.mesas.length, 2);
    expect(lojaMesclada.mesas.map((m) => m.numero), containsAll(['01', '02']));

    // 3. Deve mesclar os produtos (1 da atual + 2 do backup = 3)
    expect(lojaMesclada.itensLoja.length, 3);
    final nomesProdutos = lojaMesclada.itensLoja.map((i) => i.nome).toList();
    expect(
      nomesProdutos,
      containsAll(['Suco Natural', 'X-Burger Artesanal', 'Refrigerante 350ml']),
    );

    // 4. Deve mesclar os clientes (1 da atual + 1 do backup = 2)
    expect(lojaMesclada.clientesLoja.length, 2);
    final nomesClientes = lojaMesclada.clientesLoja.map((c) => c.nome).toList();
    expect(nomesClientes, containsAll(['Mariana Souza', 'Carlos Silva']));

    // 5. Deve mesclar as ações de auditoria (1 da atual + 1 do backup = 2)
    expect(lojaMesclada.acoes.length, 2);
  });

  test('desduplicarLojas unifica lojas com mesmo CNPJ dando preferência a Restaurante', () {
    final lojaAntiga = Loja(
      id: 'id-antigo',
      nome: 'Cantina Gourmet',
      cnpj: '12.345.678/0001-99',
      telefone: '',
      endereco: '',
      numero: '',
      email: '',
      categorias: 'Loja Padrão',
      tags: '',
      itensLoja: [
        ItemLoja(id: 'i-1', nome: 'Pizza Broto'),
      ],
    );

    final lojaAtual = Loja(
      id: 'id-atual',
      nome: 'Cantina Gourmet',
      cnpj: '12345678000199',
      telefone: '17999990000',
      endereco: 'Av Central',
      numero: '500',
      email: 'contato@cantinagourmet.com',
      categorias: 'Restaurante',
      tags: '',
      itensLoja: [
        ItemLoja(id: 'i-2', nome: 'Calzone Especial'),
      ],
    );

    // Suponha que ambas estejam no cofre devido a uma importação prévia
    final cofreComDuplicatas = [lojaAntiga, lojaAtual];

    final cofreSaneado = BackupService.desduplicarLojas(cofreComDuplicatas);

    // Deve restar apenas 1 loja no cofre
    expect(cofreSaneado.length, 1);

    final lojaFinal = cofreSaneado.first;
    expect(lojaFinal.categorias, 'Restaurante');
    expect(lojaFinal.itensLoja.length, 2);
    expect(lojaFinal.telefone, '17999990000');
    expect(lojaFinal.endereco, 'Av Central');
  });
}
