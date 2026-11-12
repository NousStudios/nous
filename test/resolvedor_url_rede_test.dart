import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';

void main() {
  group('ResolvedorUrlRede — Suporte a Rede Local e Nuvem (Cloudflare)', () {
    test('Identifica hosts locais vs nuvem', () {
      expect(ResolvedorUrlRede.ehHostNuvem('192.168.1.100'), isFalse);
      expect(ResolvedorUrlRede.ehHostNuvem('10.0.0.5'), isFalse);
      expect(ResolvedorUrlRede.ehHostNuvem('localhost'), isFalse);
      expect(ResolvedorUrlRede.ehHostNuvem('127.0.0.1'), isFalse);

      expect(ResolvedorUrlRede.ehHostNuvem('marmitaria.trycloudflare.com'), isTrue);
      expect(ResolvedorUrlRede.ehHostNuvem('nous.app.br'), isTrue);
      expect(ResolvedorUrlRede.ehHostNuvem('meuservidor.com'), isTrue);
      expect(ResolvedorUrlRede.ehHostNuvem('https://meuservidor.com'), isTrue);
      expect(ResolvedorUrlRede.ehHostNuvem('wss://meuservidor.com'), isTrue);
    });

    test('Monta URI HTTP para IP local com porta', () {
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: '192.168.1.25',
        porta: 8080,
        path: '/api/pedido',
      );
      expect(uri.toString(), equals('http://192.168.1.25:8080/api/pedido'));
    });

    test('Monta URI HTTPS para domínio Cloudflare sem expor porta interna', () {
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: 'marmitaria.trycloudflare.com',
        porta: 8080,
        path: '/api/cardapio',
      );
      expect(uri.toString(), equals('https://marmitaria.trycloudflare.com/api/cardapio'));
    });

    test('Monta URL WebSocket para IP local (ws://)', () {
      final ws = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: '192.168.1.50',
        porta: 8080,
      );
      expect(ws, equals('ws://192.168.1.50:8080/api/ws'));
    });

    test('Monta URL WebSocket para Cloudflare seguro (wss://)', () {
      final wss = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: 'marmitaria.trycloudflare.com',
        porta: 8080,
      );
      expect(wss, equals('wss://marmitaria.trycloudflare.com/api/ws'));
    });

    test('Lida com URLs já completas com protocolo', () {
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: 'https://nous.meusite.com.br',
        path: 'api/versao',
      );
      expect(uri.toString(), equals('https://nous.meusite.com.br/api/versao'));

      final wss = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: 'https://nous.meusite.com.br',
      );
      expect(wss, equals('wss://nous.meusite.com.br/api/ws'));
    });
  });
}
