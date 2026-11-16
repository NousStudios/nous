import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/delta_loja_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';

void main() {
  group('DeltaLojaHelper', () {
    test('compactarParaRede preserva pedidos ativos e limita histórico antigo', () {
      final base = DateTime(2026, 11, 13, 12, 0);
      final pedidos = <PedidoLoja>[
        PedidoLoja(
          id: 'ativo_1',
          numero: 1,
          clienteNome: 'Cliente A',
          produtoNome: 'Produto 1',
          valor: 10.0,
          dataHora: base.subtract(const Duration(days: 10)),
          itens: const [],
          status: StatusPedido.novo,
        ),
        for (int i = 0; i < 45; i++)
          PedidoLoja(
            id: 'concluido_$i',
            numero: i + 2,
            clienteNome: 'Cliente $i',
            produtoNome: 'Produto $i',
            valor: 20.0,
            dataHora: base.add(Duration(minutes: i)),
            itens: const [],
            status: StatusPedido.concluido,
          ),
      ];

      final loja = Loja(
        id: 'loja_teste',
        nome: 'Loja Teste',
        cnpj: '00.000.000/0001-00',
        telefone: '11999999999',
        endereco: 'Rua Teste',
        numero: '100',
        email: 'teste@nous.app',
        categorias: 'Alimentação',
        tags: '',
        pedidosLoja: pedidos,
      );

      final compactada = DeltaLojaHelper.compactarParaRede(loja);

      expect(
        compactada.pedidosLoja.any((p) => p.id == 'ativo_1'),
        isTrue,
        reason: 'Pedidos ativos nunca devem ser descartados na compactação',
      );
      expect(
        compactada.pedidosLoja.length,
        equals(1 + DeltaLojaHelper.limitePedidosRecentes),
      );
      expect(
        compactada.pedidosLoja.any((p) => p.id == 'concluido_44'),
        isTrue,
        reason: 'Os pedidos mais recentes devem permanecer no pacote',
      );
    });
  });

  group('ResolvedorUrlRede', () {
    test('converte wss:// para https:// ao montar URI HTTP', () {
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: 'wss://meu-servidor.trycloudflare.com',
        caminho: '/api/loja',
      );
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('meu-servidor.trycloudflare.com'));
      expect(uri.path, equals('/api/loja'));
    });

    test('montarUrlWs gera wss:// para domínio https e ws:// para IP local', () {
      final wsNuvem = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: 'https://meu-servidor.trycloudflare.com',
      );
      expect(wsNuvem, equals('wss://meu-servidor.trycloudflare.com/api/ws'));

      final wsLocal = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: '192.168.0.15',
        porta: 8080,
      );
      expect(wsLocal, equals('ws://192.168.0.15:8080/api/ws'));
    });
  });
}
