import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/services/cripto_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';

void main() {
  group('Criptografia e Encadeamento Blockchain (RegistroAcao)', () {
    test('CriptoService calcula SHA-256 nativo com precisão determinística', () {
      final hash1 = CriptoService.sha256('nous-superapp-soberano');
      final hash2 = CriptoService.sha256('nous-superapp-soberano');
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
    });

    test('RegistroAcao encadeia hash com o registro anterior', () {
      final acao1 = RegistroAcao(
        id: 'acao_1',
        tipo: TipoAcao.novaVenda,
        descricao: 'Venda criada',
        cpfAutor: '12345678900',
        nomeAutor: 'Trabalhador 1',
        emailAutor: 'trab1@nous.local',
        dataHora: DateTime.parse('2026-10-22T10:00:00Z'),
        hashAnterior: '0' * 64,
      );
      final hashCalculado1 = acao1.calcularHash('0' * 64);
      final acao1Selada = acao1.copyWith(hash: hashCalculado1);

      expect(acao1Selada.hash.length, equals(64));
      expect(acao1Selada.hashAnterior, equals('0' * 64));

      final acao2 = RegistroAcao(
        id: 'acao_2',
        tipo: TipoAcao.sangriaRegistrada,
        descricao: 'Sangria de R\$ 50',
        cpfAutor: '12345678900',
        nomeAutor: 'Trabalhador 1',
        emailAutor: 'trab1@nous.local',
        dataHora: DateTime.parse('2026-10-22T10:05:00Z'),
        hashAnterior: acao1Selada.hash,
      );
      final hashCalculado2 = acao2.calcularHash(acao1Selada.hash);
      final acao2Selada = acao2.copyWith(hash: hashCalculado2);

      expect(acao2Selada.hashAnterior, equals(acao1Selada.hash));
      expect(acao2Selada.hash, isNot(equals(acao1Selada.hash)));

      // Valida serialização e desserialização com integridade
      final json = acao2Selada.toJson();
      final restaurada = RegistroAcao.fromJson(json);
      expect(restaurada.hash, equals(acao2Selada.hash));
      expect(restaurada.hashAnterior, equals(acao2Selada.hashAnterior));
    });
  });

  group('Identidade Soberana, Nome de Usuário e Privacidade (UsuarioNous)', () {
    test('UsuarioNous armazena nome de usuário único e getters de exibição', () {
      const usuario = UsuarioNous(
        cpf: '123.456.789-00',
        nome: 'Leonardo Silva',
        apelido: 'Leo',
        dataNascimento: '01/01/1990',
        nomeDeUsuario: 'leonardo.nous',
      );

      expect(usuario.usernameExibicao, equals('@leonardo.nous'));
      expect(usuario.nomeDeUsuario, equals('leonardo.nous'));
      expect(usuario.cpf.replaceAll(RegExp(r'\D'), ''), equals('12345678900'));
    });

    test('Controle de privacidade e autorização deliberativa por CPF', () {
      const usuario = UsuarioNous(
        cpf: '123.456.789-00',
        nome: 'Maria Silva',
        apelido: 'Maria',
        dataNascimento: '02/02/1992',
        dadosPrivados: ['cpf', 'dataNascimento', 'telefone'],
        dadosAutorizadosPorCpf: ['98765432100:cpf'],
      );

      // Dado está privado para o público
      expect(usuario.dadoEstaPrivado('cpf'), isTrue);
      expect(usuario.dadoEstaPrivado('nome'), isFalse);

      // CPF autorizado para o visualizador 98765432100
      expect(usuario.dadoAutorizadoPara('cpf', '987.654.321-00'), isTrue);
      // Data de nascimento NÃO foi autorizada
      expect(usuario.dadoAutorizadoPara('dataNascimento', '987.654.321-00'), isFalse);
    });

    test('Sistema social Seguir / Seguindo', () {
      const usuario = UsuarioNous(
        cpf: '11111111111',
        nome: 'Conta 1',
        apelido: 'C1',
        dataNascimento: '',
        seguindo: ['22222222222'],
        seguidores: ['33333333333'],
      );

      expect(usuario.estaSeguindo('222.222.222-22'), isTrue);
      expect(usuario.estaSeguindo('444.444.444-44'), isFalse);
    });

    test('Notificação deliberativa de solicitação de dados (ConviteLoja)', () {
      final notificacao = ConviteLoja(
        id: 'notif_1',
        cpfConvidante: '11111111111',
        nomeConvidante: 'Cidadão Solicitante',
        cpfConvidado: '22222222222',
        lojaId: '',
        nomeLoja: 'Conta Pessoal',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoDadoUsuario,
        dadoSolicitado: 'cpf',
      );

      final json = notificacao.toJson();
      final recuperado = ConviteLoja.fromJson(json);

      expect(recuperado.tipo, equals(TipoNotificacao.solicitacaoDadoUsuario));
      expect(recuperado.dadoSolicitado, equals('cpf'));
      expect(recuperado.cpfConvidado, equals('22222222222'));
    });
  });
}
