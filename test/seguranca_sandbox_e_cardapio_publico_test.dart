import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/rede_local/seguranca_servidor_relay.dart';

void main() {
  group('Blindagem de Sandbox e Proteção contra Path Traversal', () {
    test('Bloqueia acesso a arquivos de banco de dados SQLite (nous.db)', () {
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/Users/Teste/AppData/Roaming/Nous/nous.db'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('d:/nous/data/nous.db-wal'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('outro_banco.sqlite'),
        isFalse,
      );
    });

    test('Bloqueia acesso a arquivos executáveis e credenciais sensíveis', () {
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/app/config.env'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/keys/private.key'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('malware.exe'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('script.ps1'),
        isFalse,
      );
    });

    test('Bloqueia acesso a diretórios de sistema do Windows e Linux', () {
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/Windows/System32/drivers/etc/hosts'),
        isFalse,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('/etc/passwd'),
        isFalse,
      );
    });

    test('Permite leitura de mídias legítimas (imagens, áudios, anexos cifrados)', () {
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/Users/Teste/AppData/Roaming/Nous/imagens/foto.jpg'),
        isTrue,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/Users/Teste/AppData/Roaming/Nous/anexos/gravacao.mp3'),
        isTrue,
      );
      expect(
        SegurancaServidorRelay.validarCaminhoLeituraPermitido('C:/Users/Teste/AppData/Roaming/Nous/anexos/midia.enc'),
        isTrue,
      );
    });

    test('Sanitização de nome de arquivo arranca Path Traversal e barras', () {
      final sanitizado1 = SegurancaServidorRelay.sanitizarNomeArquivo('../../Windows/System32/cmd.exe');
      expect(sanitizado1.contains('/'), isFalse);
      expect(sanitizado1.contains(r'\'), isFalse);
      expect(sanitizado1.contains('..'), isFalse);

      final sanitizado2 = SegurancaServidorRelay.sanitizarNomeArquivo('foto..perfil.png');
      expect(sanitizado2.contains('..'), isFalse);
    });

    test('Sanitização de subpasta restringe caracteres perigosos', () {
      expect(
        SegurancaServidorRelay.sanitizarSubpasta('../../etc/'),
        'etc',
      );
      expect(
        SegurancaServidorRelay.sanitizarSubpasta('musicas_novas-2026'),
        'musicas_novas-2026',
      );
      expect(
        SegurancaServidorRelay.sanitizarSubpasta('???###'),
        'geral',
      );
    });
  });

  group('Isolamento de Cardápio Público vs Dados Sigilosos da Loja', () {
    test('Loja.toVisaoPublica() oculta clientes, fornecedores, caixa e pedidos', () {
      final lojaCompleta = Loja(
        id: 'loja_teste_123',
        nome: 'Restaurante Sabor Nous',
        cnpj: '12.345.678/0001-99',
        telefone: '11999998888',
        endereco: 'Rua das Flores',
        numero: '100',
        email: 'contato@sabornous.com',
        categorias: 'Restaurante',
        tags: 'Lanches, Porções',
        categoriasLoja: const [
          CategoriaLoja(id: 'cat_1', nome: 'Lanches'),
        ],
        itensLoja: const [
          ItemLoja(id: 'item_1', nome: 'X-Burger', preco: '25,00'),
        ],
        clientesLoja: const [
          Cliente(id: 'cli_1', nome: 'Cliente Secreto', telefone: '11988887777'),
        ],
        fornecedoresLoja: [
          Fornecedor(id: 'forn_1', nome: 'Distribuidora Carnes', dataCriacao: DateTime(2026, 11, 11)),
        ],
        pedidosLoja: [
          PedidoLoja(
            id: 'ped_1',
            numero: 1,
            clienteNome: 'Cliente Secreto',
            produtoNome: 'X-Burger',
            dataHora: DateTime(2026, 11, 11),
            valor: 25.0,
          ),
        ],
        acoes: [
          RegistroAcao(
            id: 'act_1',
            dataHora: DateTime(2026, 11, 11),
            tipo: TipoAcao.dadosLojaAtualizados,
            descricao: 'Alterou caixa',
            cpfAutor: '12345678901',
            nomeAutor: 'Admin',
            emailAutor: '',
          ),
        ],
        movimentosEstoque: [
          MovimentoEstoque(id: 'mov_1', itemId: 'item_1', quantidade: 10, tipo: TipoMovimentoEstoque.entrada, dataHora: DateTime(2026, 11, 11)),
        ],
        turnosCaixa: [
          TurnoCaixa(id: 'caixa_1', dataAbertura: DateTime(2026, 11, 11), abertoPorNome: 'Caixa 1', saldoInicial: 200.0),
        ],
        membros: [
          MembroLoja(cpf: '12345678901', nome: 'Gerente', papel: PapelMembro.admin, desde: DateTime(2026, 1, 1)),
        ],
      );

      final visaoPublica = lojaCompleta.toVisaoPublica();

      // Cardápio público e identidade da loja preservados
      expect(visaoPublica.id, 'loja_teste_123');
      expect(visaoPublica.nome, 'Restaurante Sabor Nous');
      expect(visaoPublica.categoriasLoja.length, 1);
      expect(visaoPublica.itensLoja.length, 1);
      expect(visaoPublica.itensLoja.first.nome, 'X-Burger');
      expect(visaoPublica.itensLoja.first.preco, '25,00');

      // Dados sigilosos e de gestão estritamente apagados da visão pública
      expect(visaoPublica.clientesLoja, isEmpty);
      expect(visaoPublica.fornecedoresLoja, isEmpty);
      expect(visaoPublica.pedidosLoja, isEmpty);
      expect(visaoPublica.acoes, isEmpty);
      expect(visaoPublica.movimentosEstoque, isEmpty);
      expect(visaoPublica.turnosCaixa, isEmpty);
      expect(visaoPublica.membros, isEmpty);
      expect(visaoPublica.pagamentosFuncionarios, isEmpty);
      expect(visaoPublica.pedidosProgramados, isEmpty);
    });
  });
}
