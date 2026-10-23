import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Username Soberano e Loja Coletiva Nous', () {
    test('usernameExibicao garante rigorosamente um único @ mesmo se cadastrado com arrobas repetidas', () {
      final u1 = UsuarioNous(
        cpf: '12345678901',
        nome: 'Leonardo',
        dataNascimento: '01/01/1990',
        nomeDeUsuario: 'taddeoleonardo',
      );
      expect(u1.usernameExibicao, '@taddeoleonardo');

      final u2 = UsuarioNous(
        cpf: '12345678901',
        nome: 'Leonardo',
        dataNascimento: '01/01/1990',
        nomeDeUsuario: '@taddeoleonardo',
      );
      expect(u2.usernameExibicao, '@taddeoleonardo');

      final u3 = UsuarioNous(
        cpf: '12345678901',
        nome: 'Leonardo',
        dataNascimento: '01/01/1990',
        nomeDeUsuario: '@@@taddeoleonardo',
      );
      expect(u3.usernameExibicao, '@taddeoleonardo');

      final u4 = UsuarioNous(
        cpf: '12345678901',
        nome: 'Leonardo',
        dataNascimento: '01/01/1990',
        nomeDeUsuario: '',
      );
      expect(u4.usernameExibicao, '');
    });

    test('Loja Coletiva Nous possui ID canônico e suporta alternância da função Desenvolvedor', () {
      final pdv = PdvProvider();
      final lojaNous = Loja(
        id: PdvProvider.idLojaColetivaNous,
        nome: 'Nous',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: 'nousstudios72@gmail.com',
        categorias: 'Autogestão, Comunidade, Software Livre',
        tags: 'Autogestão, Comunidade, Software Livre',
        membros: [
          MembroLoja(
            cpf: '12345678901',
            nome: 'Leonardo',
            papel: PapelMembro.socio,
            desde: DateTime.now(),
            cargoPersonalizadoId: null,
          ),
        ],
      );

      // Adiciona loja ao provider
      pdv.adicionarOuAtualizarLoja(lojaNous);

      // Alterna para desenvolvedor
      pdv.alternarFuncaoDesenvolvedorNous('12345678901');
      final lojaDepois = pdv.buscarPorId(PdvProvider.idLojaColetivaNous);
      expect(lojaDepois, isNotNull);
      final membroDev = lojaDepois!.membros.first;
      expect(membroDev.cargoPersonalizadoId, 'desenvolvedor');

      // Alterna novamente para deixar de ser desenvolvedor
      pdv.alternarFuncaoDesenvolvedorNous('12345678901');
      final lojaDepois2 = pdv.buscarPorId(PdvProvider.idLojaColetivaNous);
      final membroComum = lojaDepois2!.membros.first;
      expect(membroComum.cargoPersonalizadoId, isNull);
    });
  });
}
