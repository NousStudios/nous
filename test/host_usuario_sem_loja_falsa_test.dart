import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Host Usuário Nous sem criação de loja falsa', () {
    test('LojasService.ehLojaHostFalsa detecta e isola corretamente lojas host artificiais', () {
      expect(LojasService.ehLojaHostFalsa('host_12345678901'), isTrue);
      expect(LojasService.ehLojaHostFalsa('temp_host_999'), isTrue);
      expect(LojasService.ehLojaHostFalsa('loja_real_1', 'host_pessoal', 'Minha Loja'), isTrue);
      expect(LojasService.ehLojaHostFalsa('loja_real_2', 'padaria', 'Host: Usuário Nous'), isTrue);
      expect(LojasService.ehLojaHostFalsa('loja_real_3', 'padaria', 'Host Leonardo'), isTrue);

      // Lojas legítimas criadas pelos usuários
      expect(LojasService.ehLojaHostFalsa('loja_marmitaria_123', 'restaurante', 'Marmitaria da Vovó'), isFalse);
      expect(LojasService.ehLojaHostFalsa(PdvProvider.idLojaColetivaNous, 'comunidade', 'Nous'), isFalse);
      expect(LojasService.ehLojaHostFalsa('loja_informatica', 'servicos', 'Hostnet Soluções'), isFalse);
    });

    test('PdvProvider bloqueia adição de loja host falsa em adicionarOuAtualizarLoja', () async {
      final pdv = PdvProvider();
      expect(pdv.lojas.isEmpty, isTrue);

      final lojaFalsa = Loja(
        id: 'host_12345678901',
        nome: 'Host: Usuário Nous',
        cnpj: '12345678901',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: 'Host Pessoal',
        tags: 'host_pessoal',
        cpfDonoOriginal: '12345678901',
      );

      await pdv.adicionarOuAtualizarLoja(lojaFalsa);
      expect(pdv.lojas.any((l) => l.id == lojaFalsa.id), isFalse);

      final lojaReal = Loja(
        id: 'loja_real_mercado',
        nome: 'Mercadinho do Bairro',
        cnpj: '00.000.000/0001-00',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: 'Mercado',
        tags: 'mercado',
        cpfDonoOriginal: '12345678901',
      );

      await pdv.adicionarOuAtualizarLoja(lojaReal);
      expect(pdv.lojas.any((l) => l.id == 'loja_real_mercado'), isTrue);
    });

    test('DispositivoLojaInfo identifica corretamente hosts de Usuário vs Loja Comercial', () {
      final hostUsuario = DispositivoLojaInfo(
        lojaId: '',
        lojaNome: 'Leonardo Taddeo',
        ip: '192.168.1.50',
        porta: 8080,
        vistoEm: DateTime.now(),
        tipoHost: 'usuario',
      );
      expect(hostUsuario.ehUsuario, isTrue);

      final hostLoja = DispositivoLojaInfo(
        lojaId: 'loja_123',
        lojaNome: 'Marmitaria Gourmet',
        ip: '192.168.1.50',
        porta: 8080,
        vistoEm: DateTime.now(),
        tipoHost: 'loja',
      );
      expect(hostLoja.ehUsuario, isFalse);
    });

    test('ServidorRedeLocal aceita loja nula para iniciar em Modo Usuário Nous', () {
      final servidor = ServidorRedeLocal();
      expect(servidor.lojaAtiva, isNull);
    });
  });
}
