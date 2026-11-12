import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Solicitações de Mensagens & Identidade Soberana Nous', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      MensageriaSolicitacoesHelper.limpar();
    });

    test('UsuarioNous serializa e deserializa novos campos de verificação', () {
      final usuario = const UsuarioNous(
        cpf: '12345678900',
        nome: 'Leonardo da Silva',
        apelido: 'Leo',
        nomeDeUsuario: 'leo.nous',
        dataNascimento: '1995-05-10',
        criadoEm: '2026-11-12T10:00:00.000Z',
        validadoPorCpf: '98765432100',
        validadoPorNome: 'Comunidade Nous Central',
        validadoEm: '2026-11-12T10:05:00.000Z',
        verificado: true,
      );

      final json = usuario.toJson();
      expect(json['criadoEm'], '2026-11-12T10:00:00.000Z');
      expect(json['validadoPorCpf'], '98765432100');
      expect(json['validadoPorNome'], 'Comunidade Nous Central');
      expect(json['verificado'], true);

      final reconstrudo = UsuarioNous.fromJson(json);
      expect(reconstrudo.cpf, '12345678900');
      expect(reconstrudo.verificado, true);
      expect(reconstrudo.validadoPorNome, 'Comunidade Nous Central');
      expect(reconstrudo.criadoEmFormatado, isNotEmpty);
      expect(reconstrudo.validadoEmFormatado, isNotEmpty);
    });

    test('MensageriaSolicitacoesHelper identifica contatos não seguidos como solicitação', () {
      final usuarioEu = const UsuarioNous(
        cpf: '11111111111',
        nome: 'Eu',
        dataNascimento: '',
        seguindo: ['22222222222'], // Eu sigo apenas o CPF 222
      );

      final msgAmigo = MensagemChat(
        id: 'msg_1',
        conversaId: 'user_11111111111_user_22222222222',
        remetenteId: '22222222222',
        remetenteNome: 'Amigo',
        destinatarioId: '11111111111',
        texto: 'Olá amigo!',
        dataHora: DateTime.now(),
      );

      final conversaAmigo = ConversaChat(
        id: 'user_11111111111_user_22222222222',
        titulo: 'Amigo Seguido',
        identificador: '22222222222',
        dataHoraUltimaMensagem: DateTime.now(),
        ultimaMensagem: 'Olá amigo!',
        mensagens: [msgAmigo],
      );

      // Como eu sigo 22222222222, NÃO deve ser solicitação
      final ehSolicitacaoAmigo = MensageriaSolicitacoesHelper.ehSolicitacao(
        conversa: conversaAmigo,
        modoLoja: false,
        meuCpf: '11111111111',
        contaLogada: usuarioEu,
      );
      expect(ehSolicitacaoAmigo, false);

      // Conversa com desconhecido (CPF 33333333333, que eu NÃO sigo)
      final msgDesconhecido = MensagemChat(
        id: 'msg_2',
        conversaId: 'user_11111111111_user_33333333333',
        remetenteId: '33333333333',
        remetenteNome: 'Desconhecido',
        destinatarioId: '11111111111',
        texto: 'Oi, tudo bem?',
        dataHora: DateTime.now(),
      );

      final conversaDesconhecido = ConversaChat(
        id: 'user_11111111111_user_33333333333',
        titulo: 'Desconhecido',
        identificador: '33333333333',
        dataHoraUltimaMensagem: DateTime.now(),
        ultimaMensagem: 'Oi, tudo bem?',
        mensagens: [msgDesconhecido],
      );

      // Como eu NÃO sigo 33333333333, DEVE ser solicitação!
      final ehSolicitacaoDesconhecido = MensageriaSolicitacoesHelper.ehSolicitacao(
        conversa: conversaDesconhecido,
        modoLoja: false,
        meuCpf: '11111111111',
        contaLogada: usuarioEu,
      );
      expect(ehSolicitacaoDesconhecido, true);
    });

    test('Ao aceitar uma solicitação, ela deixa de ser solicitação e passa para diretas', () async {
      final usuarioEu = const UsuarioNous(
        cpf: '11111111111',
        nome: 'Eu',
        dataNascimento: '',
        seguindo: [],
      );

      final msg = MensagemChat(
        id: 'msg_x',
        conversaId: 'user_11111111111_user_44444444444',
        remetenteId: '44444444444',
        remetenteNome: 'Novo Contato',
        destinatarioId: '11111111111',
        texto: 'Teste solicitação',
        dataHora: DateTime.now(),
      );

      final conversa = ConversaChat(
        id: 'user_11111111111_user_44444444444',
        titulo: 'Novo Contato',
        identificador: '44444444444',
        dataHoraUltimaMensagem: DateTime.now(),
        ultimaMensagem: 'Teste solicitação',
        mensagens: [msg],
      );

      expect(
        MensageriaSolicitacoesHelper.ehSolicitacao(
          conversa: conversa,
          modoLoja: false,
          meuCpf: '11111111111',
          contaLogada: usuarioEu,
        ),
        true,
      );

      // Aceita a solicitação
      await MensageriaSolicitacoesHelper.aceitarSolicitacao(
        conversaId: conversa.id,
        meuCpf: '11111111111',
      );

      // Agora NÃO deve mais ser solicitação
      expect(
        MensageriaSolicitacoesHelper.ehSolicitacao(
          conversa: conversa,
          modoLoja: false,
          meuCpf: '11111111111',
          contaLogada: usuarioEu,
        ),
        false,
      );
    });
  });
}
