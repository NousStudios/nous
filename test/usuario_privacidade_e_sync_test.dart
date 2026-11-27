import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

void main() {
  group('UsuarioNous - Privacidade Padrão e Mesclagem Temporal', () {
    test('dadosPrivadosPadrao oculta apenas Dados Pessoais, CPF e Nome Próprio; bio e apelido são públicos', () {
      final usuario = UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo Silva',
        apelido: 'Leo',
        biografia: 'Empreendedor na marmitaria',
        dataNascimento: '01/01/1990',
      );

      expect(usuario.dadoEstaPrivado('nome'), isTrue);
      expect(usuario.dadoEstaPrivado('cpf'), isTrue);
      expect(usuario.dadoEstaPrivado('dataNascimento'), isTrue);
      expect(usuario.dadoEstaPrivado('biografia'), isFalse);
      expect(usuario.dadoEstaPrivado('apelido'), isFalse);
      expect(usuario.dadoEstaPrivado('foto'), isFalse);

      // Outro usuário vê o apelido no lugar do nome próprio e vê a biografia
      expect(
        usuario.nomeExibicaoPara(cpfVisualizador: '99988877766'),
        equals('Leo'),
      );
      expect(
        usuario.biografiaPara('99988877766'),
        equals('Empreendedor na marmitaria'),
      );
    });

    test('mesclarCom não permite que rascunho vazio sem atualizadoEm sobrescreva perfil completo', () {
      final perfilCompleto = UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo Silva',
        apelido: 'Leo',
        biografia: 'Minha bio real',
        links: const ['https://nous.org'],
        dataNascimento: '01/01/1990',
        atualizadoEm: '2026-11-27T15:00:00.000',
      );

      final rascunhoBalcao = UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo Silva',
        apelido: 'Leo',
        biografia: '',
        dataNascimento: '',
        atualizadoEm: '',
      );

      final mesclado = perfilCompleto.mesclarCom(
        rascunhoBalcao,
        priorizarOutro: true,
      );

      expect(mesclado.biografia, equals('Minha bio real'));
      expect(mesclado.links, equals(['https://nous.org']));
    });

    test('mesclarCom usa timestamp atualizadoEm mais recente mesmo com priorizarOutro=true', () {
      final localMaisNovo = UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo Silva',
        biografia: 'Bio editada offline às 16h',
        dataNascimento: '01/01/1990',
        atualizadoEm: '2026-11-27T16:00:00.000',
      );

      final remotoAntigo = UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo Silva',
        biografia: 'Bio antiga das 14h',
        dataNascimento: '01/01/1990',
        atualizadoEm: '2026-11-27T14:00:00.000',
      );

      final resultado = localMaisNovo.mesclarCom(
        remotoAntigo,
        priorizarOutro: true,
      );
      expect(resultado.biografia, equals('Bio editada offline às 16h'));

      final remotoMaisNovo = remotoAntigo.copyWith(
        biografia: 'Bio atualizada às 17h',
        atualizadoEm: '2026-11-27T17:00:00.000',
      );
      final resultado2 = localMaisNovo.mesclarCom(
        remotoMaisNovo,
        priorizarOutro: false,
      );
      expect(resultado2.biografia, equals('Bio atualizada às 17h'));
    });
  });
}
