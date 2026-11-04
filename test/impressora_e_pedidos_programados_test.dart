import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart';

void main() {
  group('Impressora Térmica - Bobina Contínua sem corte em 200mm', () {
    test('Comanda longa (> 200mm) mantém todos os itens e resolve altura finita exata', () async {
      final doc = pw.Document();
      final pageFormat = ImpressaoUtils.formatoPapel(
        const ConfiguracoesImpressora(larguraPapelMm: 58),
      );
      expect(pageFormat.height.isInfinite, isTrue);

      final itens = List.generate(
        12,
        (i) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('1x Marmitex Completa #${i + 1} - R\$ 25,00'),
              pw.Text('  + Arroz, Feijão, Farofa, Salada, Carne Assada'),
              pw.Text('  Obs: Bem passado, sem cebola'),
            ],
          ),
        ),
      );

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('MARMITARIA PROVIDENCE'),
              pw.Divider(height: 6, thickness: 0.5),
              ...itens,
              pw.Divider(height: 6, thickness: 0.5),
              pw.Text('TOTAL: R\$ 300,00'),
              pw.Text('RODAPE FINAL DA COMANDA'),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);

      final resolvido = ImpressaoUtils.formatoResolvidoDoDocumento(doc, pageFormat);
      expect(resolvido.height.isFinite, isTrue);
      // Deve ultrapassar os antigos 200mm (566pt) sem truncar o layout
      expect(resolvido.height, greaterThan(200 * PdfPageFormat.mm));
      expect(resolvido.height, greaterThan(resolvido.width));
    });
  });

  group('Pedidos Programados - Ciclo de Vida, Edição, Pausa, Exclusão e Sincronização', () {
    PedidoProgramado criarProgramado({
      String id = 'prog_1',
      String clienteId = 'cli_1',
      String clienteNome = 'Maria Silva',
      String horario = '11:30',
      List<int> diasSemana = const [1, 2, 3, 4, 5],
      bool ativo = true,
      String observacao = 'Entregar na portaria',
    }) {
      return PedidoProgramado(
        id: id,
        lojaId: 'loja_1',
        clienteId: clienteId,
        clienteNome: clienteNome,
        clienteTelefone: '(11) 99999-0000',
        clienteEndereco: 'Rua das Flores, 123',
        itens: const [
          ItemVendido(
            itemId: 'item_1',
            nomeItem: 'Marmita Média',
            precoItem: 22.0,
            quantidade: 2,
          ),
        ],
        valorTotal: 44.0,
        formaPagamento: 'Pix',
        horario: horario,
        recorrente: true,
        modoProgramacao: 'dias_semana',
        diasSemana: diasSemana,
        ativo: ativo,
        dataCriacao: DateTime(2026, 1, 1),
        observacao: observacao,
      );
    }

    test('descricaoFrequenciaCurta não duplica horário e formata Seg a Sex', () {
      final prog = criarProgramado();
      expect(prog.descricaoFrequenciaCurta, equals('Seg a Sex'));
      expect(prog.descricaoFrequencia, equals('Seg a Sex às 11:30'));
    });

    test('toPedidoLoja copia observacao para comentario, nao injeta Ref Programado na comanda e resolverCliente preserva endereço/telefone', () {
      final prog = criarProgramado();
      final pedido = prog.toPedidoLoja(numero: 7);
      expect(pedido.comentario, equals('Entregar na portaria'));
      expect(pedido.comanda, isEmpty);
      expect(pedido.numero, equals(7));

      final clienteSemCadastro = prog.resolverCliente(const []);
      expect(clienteSemCadastro.nome, equals('Maria Silva'));
      expect(clienteSemCadastro.telefone, equals('(11) 99999-0000'));
      expect(clienteSemCadastro.endereco, equals('Rua das Flores, 123'));

      final clienteCadastradoIncompleto = prog.resolverCliente(const [
        Cliente(
          id: 'cli_1',
          nome: 'Maria Silva',
          cnpj: '',
          telefone: '',
          endereco: '',
          numero: '',
          email: '',
        ),
      ]);
      expect(clienteCadastradoIncompleto.telefone, equals('(11) 99999-0000'));
      expect(clienteCadastradoIncompleto.endereco, equals('Rua das Flores, 123'));
    });

    test('ConsolidadorLojaLocal e ReconciliadorLojaRede permitem editar, pausar e excluir PedidoProgramado', () {
      final progOriginal = criarProgramado();
      final lojaLocal = Loja(
        id: 'loja_1',
        nome: 'Providence',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: 'Restaurante',
        tags: '',
        pedidosProgramados: [progOriginal],
        configuracoesImpressora: const ConfiguracoesImpressora(
          nomeImpressora: 'POS-58',
          larguraPapelMm: 58,
        ),
      );

      // 1. Pausar e editar horário
      final progEditado = progOriginal.copyWith(ativo: false, horario: '12:15');
      final lojaEditada = lojaLocal.copyWith(pedidosProgramados: [progEditado]);
      final consolidada1 = ConsolidadorLojaLocal.consolidar(lojaEditada, lojaLocal);
      expect(consolidada1.pedidosProgramados.single.ativo, isFalse);
      expect(consolidada1.pedidosProgramados.single.horario, equals('12:15'));
      expect(consolidada1.configuracoesImpressora.nomeImpressora, equals('POS-58'));

      // 2. Excluir programação
      final lojaSemProg = lojaLocal.copyWith(pedidosProgramados: const []);
      final consolidada2 = ConsolidadorLojaLocal.consolidar(lojaSemProg, lojaLocal);
      expect(consolidada2.pedidosProgramados, isEmpty);

      // 3. Mesclagem remota também respeita a lista autoritativa de pedidosProgramados
      final reconciliada = ConsolidadorLojaLocal.consolidar(
        lojaSemProg,
        lojaLocal,
        mesclarColecoesRemotas: true,
      );
      expect(reconciliada.pedidosProgramados, isEmpty);
    });

    test('PdvPedidosProgramadosHelper gera pedido do dia, atualiza e limpa pendente ao pausar/excluir', () {
      final hoje = DateTime.now();
      final prog = criarProgramado(diasSemana: [hoje.weekday]);
      final lojaInicial = Loja(
        id: 'loja_1',
        nome: 'Providence',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: 'Restaurante',
        tags: '',
        pedidosProgramados: [prog],
      );

      final geracao = PdvPedidosProgramadosHelper.verificarEGerar(lojaInicial);
      expect(geracao.alterou, isTrue);
      expect(geracao.pedidosGerados.length, equals(1));
      expect(geracao.loja.pedidosLoja.length, equals(1));
      expect(geracao.loja.pedidosLoja.first.comentario, equals('Entregar na portaria'));

      // Segunda verificação no mesmo dia não deve duplicar
      final geracao2 = PdvPedidosProgramadosHelper.verificarEGerar(geracao.loja);
      expect(geracao2.alterou, isFalse);
      expect(geracao2.pedidosGerados, isEmpty);

      // Editar observação e valor enquanto pedido ainda está em StatusPedido.novo reflete na comanda
      final progAtualizado = geracao.loja.pedidosProgramados.first.copyWith(
        valorTotal: 55.0,
        observacao: 'Troco para 100',
      );
      final resEdicao = PdvPedidosProgramadosHelper.atualizarPedidoProgramado(
        geracao.loja,
        progAtualizado,
      );
      expect(resEdicao.loja.pedidosLoja.first.valor, equals(55.0));
      expect(resEdicao.loja.pedidosLoja.first.comentario, equals('Troco para 100'));

      // Pausar pedido programado remove o pedido ainda não aceito (StatusPedido.novo)
      final resPausa = PdvPedidosProgramadosHelper.alternarAtivoPedidoProgramado(
        resEdicao.loja,
        prog.id,
      );
      expect(resPausa.loja.pedidosProgramados.first.ativo, isFalse);
      expect(resPausa.loja.pedidosLoja, isEmpty);
      expect(resPausa.idsPedidosRemovidos.length, equals(1));
    });
  });

  group('NovaVendaController - Busca Instantânea, Endereço + Telefone e Dívida do Cliente', () {
    test('Digitar no campo de cliente notifica imediatamente e filtra clientes com endereço, telefone e dívida', () {
      final clientes = [
        const Cliente(
          id: 'c1',
          nome: 'Berenice Silva',
          cnpj: '11122233344',
          telefone: '(11) 98888-7777',
          endereco: 'Rua das Flores',
          numero: '120',
          email: '',
        ),
        const Cliente(
          id: 'c2',
          nome: 'Carlos Souza',
          cnpj: '55566677788',
          telefone: '(11) 91111-2222',
          endereco: 'Av. Brasil',
          numero: '45',
          email: '',
        ),
      ];

      final pedidos = [
        PedidoLoja(
          id: 'ped_1',
          numero: 1,
          clienteId: 'c1',
          clienteNome: 'Berenice Silva',
          produtoNome: '2x Marmita',
          valor: 50.0,
          valorPago: 15.0,
          formaPagamento: 'À Prazo',
          quitado: false,
          status: StatusPedido.concluido,
          dataHora: DateTime(2026, 4, 10, 12, 0),
        ),
      ];

      final controller = NovaVendaController(
        theme: AppTheme(),
        itensDisponiveis: const [],
        categoriasDisponiveis: const [],
        gruposDisponiveis: const [],
        obterClientes: () => clientes,
        obterPedidos: () => pedidos,
        aoAbrirClientes: () async {},
        nomeVendedor: 'Providence',
        cnpjVendedor: '',
        proximoNumero: 2,
        cpfAutor: '12345678900',
        nomeAutor: 'Operador',
        onConcluir: (_, _) {},
        aoCriarItem: (_, _, _, [_]) async {},
        configuracoesImpressora: const ConfiguracoesImpressora(),
      );
      addTearDown(controller.dispose);

      var notificacoes = 0;
      controller.addListener(() => notificacoes++);

      controller.clienteController.text = 'bere';
      controller.aoDigitarCliente('bere');

      expect(notificacoes, greaterThanOrEqualTo(1));
      expect(controller.clienteFocado, isTrue);
      expect(controller.sugestoesDeCliente.length, equals(1));
      expect(controller.sugestoesDeCliente.single.nome, equals('Berenice Silva'));

      // Mostra tanto endereço com número quanto telefone na barra do cliente
      expect(
        controller.obterDadoPrioritarioCliente(clientes[0]),
        equals('Rua das Flores, 120 • (11) 98888-7777'),
      );

      // Calcula dívida aberta do cliente (50 - 15 = 35)
      expect(controller.dividaDoCliente(clientes[0]), equals(35.0));
      expect(controller.dividaDoCliente(clientes[1]), equals(0.0));
    });

    test('mesclarDoisTurnosCaixa preserva suprimentos/sangrias no turno aberto e MesaLoja.copyWith limpa abertura ao liberar', () {
      final abertura = DateTime(2026, 4, 11, 8, 0);
      final turnoSemMov = TurnoCaixa(
        id: 't1',
        dataAbertura: abertura,
        saldoInicial: 100.0,
        status: StatusTurnoCaixa.aberto,
        movimentacoes: const [],
      );
      final turnoComSuprimento = TurnoCaixa(
        id: 't1',
        dataAbertura: abertura,
        saldoInicial: 100.0,
        status: StatusTurnoCaixa.aberto,
        movimentacoes: [
          MovimentoCaixa(
            id: 'mov_1',
            dataHora: DateTime(2026, 4, 11, 10, 30),
            tipo: TipoMovimentoCaixa.suprimento,
            valor: 45.0,
            motivo: 'Recebimento de fiado - Berenice',
          ),
        ],
      );

      final mesclado = ConsolidadorLojaLocal.mesclarDoisTurnosCaixa(
        turnoSemMov,
        turnoComSuprimento,
      );
      expect(mesclado.movimentacoes.length, equals(1));
      expect(mesclado.totalSuprimentos, equals(45.0));

      final mesaOcupada = MesaLoja(
        id: 'm1',
        numero: '01',
        status: StatusMesa.ocupada,
        dataHoraAbertura: abertura,
      );
      final mesaLiberada = mesaOcupada.copyWith(status: StatusMesa.livre);
      expect(mesaLiberada.dataHoraAbertura, isNull);
    });
  });
}
