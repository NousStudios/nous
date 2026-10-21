import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

void main() {
  group('Mensageria e Chat Nous', () {
    test('MensagemChat serializa e desserializa preservando atendente', () {
      final data = DateTime.now();
      final msg = MensagemChat(
        id: 'msg_1',
        conversaId: 'conv_loja_1',
        remetenteId: 'loja_123',
        remetenteNome: 'Laricas',
        destinatarioId: '12345678900',
        texto: 'Olá! Seu pedido já está sendo preparado.',
        dataHora: data,
        enviadaPorMim: true,
        nomeAtendente: 'Léo',
        cpfAtendente: '12345678900',
        lida: true,
      );

      final json = msg.toJson();
      final recuperada = MensagemChat.fromJson(json);

      expect(recuperada.id, equals('msg_1'));
      expect(recuperada.remetenteNome, equals('Laricas'));
      expect(recuperada.destinatarioId, equals('12345678900'));
      expect(recuperada.nomeAtendente, equals('Léo'));
      expect(recuperada.cpfAtendente, equals('12345678900'));
      expect(recuperada.texto, equals('Olá! Seu pedido já está sendo preparado.'));
      expect(recuperada.enviadaPorMim, isTrue);
    });

    test('ConversaChat serializa e agrupa histórico de mensagens e suporta grupos', () {
      final data = DateTime.now();
      final msg = MensagemChat(
        id: 'msg_2',
        conversaId: 'grupo_1',
        remetenteId: 'user_1',
        remetenteNome: 'Maria',
        texto: 'Estoque de farinha reposto.',
        dataHora: data,
      );

      final conversa = ConversaChat(
        id: 'grupo_1',
        titulo: 'Equipe Padaria',
        subtitulo: 'Grupo • 3 participantes',
        identificador: 'grupo_1',
        ehLoja: false,
        ehGrupo: true,
        participantesIds: ['111', '222', '333'],
        ultimaMensagem: 'Estoque de farinha reposto.',
        dataHoraUltimaMensagem: data,
        naoLidasCount: 1,
        mensagens: [msg],
      );

      final json = conversa.toJson();
      final recuperada = ConversaChat.fromJson(json);

      expect(recuperada.id, equals('grupo_1'));
      expect(recuperada.titulo, equals('Equipe Padaria'));
      expect(recuperada.ehGrupo, isTrue);
      expect(recuperada.participantesIds, containsAll(['111', '222', '333']));
      expect(recuperada.mensagens.length, equals(1));
      expect(recuperada.mensagens.first.texto, equals('Estoque de farinha reposto.'));
    });

    test('ChatService gera IDs canônicos idênticos para os dois lados da conversa', () {
      final idLojaUsuarioA = ChatService.conversaIdLojaUsuario('loja_42', '123.456.789-00');
      final idLojaUsuarioB = ChatService.conversaIdLojaUsuario('loja_42', '12345678900');
      expect(idLojaUsuarioA, equals(idLojaUsuarioB));
      expect(idLojaUsuarioA, equals('loja_42_usuario_12345678900'));

      final idUser1 = ChatService.conversaIdEntreUsuarios('99988877766', '11122233344');
      final idUser2 = ChatService.conversaIdEntreUsuarios('111.222.333-44', '999.888.777-66');
      expect(idUser1, equals(idUser2));
    });
  });
}
