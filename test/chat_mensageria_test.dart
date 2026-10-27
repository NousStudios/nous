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

    test('MensagemChat suporta e serializa anexos de fotos, arquivos e comandas', () {
      final data = DateTime.now();
      final msgComanda = MensagemChat(
        id: 'msg_comanda_1',
        conversaId: 'conv_1',
        remetenteId: 'loja_1',
        remetenteNome: 'Loja Exemplo',
        texto: 'Pedido #0001 • R\$ 45.00',
        dataHora: data,
        tipo: 'comanda',
        pedidoId: 'ped_123',
        dadosPedidoJson: '{"id":"ped_123","numero":1,"total":45.0}',
      );

      final jsonComanda = msgComanda.toJson();
      final recComanda = MensagemChat.fromJson(jsonComanda);

      expect(recComanda.tipo, equals('comanda'));
      expect(recComanda.pedidoId, equals('ped_123'));
      expect(recComanda.dadosPedidoJson, contains('ped_123'));

      final msgArquivo = MensagemChat(
        id: 'msg_arq_1',
        conversaId: 'conv_1',
        remetenteId: 'user_1',
        remetenteNome: 'João',
        texto: 'Segue cardápio em PDF',
        dataHora: data,
        tipo: 'arquivo',
        caminhoAnexo: 'C:/docs/cardapio.pdf',
        nomeAnexo: 'cardapio.pdf',
        tamanhoAnexo: 1048576,
      );

      final jsonArquivo = msgArquivo.toJson();
      final recArquivo = MensagemChat.fromJson(jsonArquivo);

      expect(recArquivo.tipo, equals('arquivo'));
      expect(recArquivo.caminhoAnexo, equals('C:/docs/cardapio.pdf'));
      expect(recArquivo.nomeAnexo, equals('cardapio.pdf'));
      expect(recArquivo.tamanhoAnexo, equals(1048576));
    });

    test('MensagemChat serializa e desserializa status de edição e histórico de versões', () {
      final agora = DateTime.now();
      final msg = MensagemChat(
        id: 'msg_edit_1',
        conversaId: 'conv_1',
        remetenteId: '12345678900',
        remetenteNome: 'Maria',
        destinatarioId: '98765432100',
        texto: 'Texto corrigido e atualizado',
        dataHora: agora,
        editada: true,
        historicoEdicoes: [
          {
            'textoAnterior': 'Texto com erro de digitação',
            'dataHoraEdicao': agora.subtract(const Duration(minutes: 5)).toIso8601String(),
          }
        ],
      );

      final json = msg.toJson();
      final recuperada = MensagemChat.fromJson(json);

      expect(recuperada.editada, isTrue);
      expect(recuperada.historicoEdicoes.length, equals(1));
      expect(recuperada.historicoEdicoes.first['textoAnterior'], equals('Texto com erro de digitação'));
      expect(recuperada.texto, equals('Texto corrigido e atualizado'));
    });

    test('MensagemChat nasce como não lida (lida: false) por padrão para usuários offline', () {
      final msg = MensagemChat(
        id: 'msg_offline_1',
        conversaId: 'conv_1',
        remetenteId: '111',
        remetenteNome: 'Ana',
        texto: 'Mensagem para conta offline',
        dataHora: DateTime.now(),
      );

      expect(msg.lida, isFalse);

      final jsonSemLida = {
        'id': 'msg_offline_2',
        'conversaId': 'conv_1',
        'remetenteId': '111',
        'remetenteNome': 'Ana',
        'texto': 'Mensagem remota recebida',
      };
      final recuperada = MensagemChat.fromJson(jsonSemLida);
      expect(recuperada.lida, isFalse);
    });

    test('MensagemChat serializa e desserializa statusEnvio e flag de entregue', () {
      final msg = MensagemChat(
        id: 'msg_status_1',
        conversaId: 'conv_status',
        remetenteId: 'user_1',
        remetenteNome: 'Carlos',
        texto: 'Testando status de entrega',
        dataHora: DateTime.now(),
        statusEnvio: 'entregue',
        entregue: true,
      );

      final json = msg.toJson();
      final recuperada = MensagemChat.fromJson(json);

      expect(recuperada.statusEnvio, equals('entregue'));
      expect(recuperada.entregue, isTrue);
    });

    test('ConversaChat serializa e preserva fixada, arquivada e ordenação', () {
      final agora = DateTime.now();
      final conv1 = ConversaChat(
        id: 'c1',
        titulo: 'Conversa Normal Recente',
        identificador: 'c1',
        dataHoraUltimaMensagem: agora,
        fixada: false,
      );
      final conv2 = ConversaChat(
        id: 'c2',
        titulo: 'Conversa Fixada Mais Antiga',
        identificador: 'c2',
        dataHoraUltimaMensagem: agora.subtract(const Duration(days: 2)),
        fixada: true,
      );

      final json = conv2.toJson();
      final recuperada = ConversaChat.fromJson(json);
      expect(recuperada.fixada, isTrue);
      expect(recuperada.arquivada, isFalse);

      final lista = [conv1, conv2];
      lista.sort((a, b) {
        if (a.fixada != b.fixada) {
          return a.fixada ? -1 : 1;
        }
        return b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem);
      });

      expect(lista.first.id, equals('c2')); // Fixada vem primeiro
      expect(lista.last.id, equals('c1'));
    });

    test('MensagemChat com áudio serializa corretamente e ChatService gera resumo com microfone', () {
      final msgAudio = MensagemChat(
        id: 'msg_audio_1',
        conversaId: 'c1',
        remetenteId: 'user1',
        remetenteNome: 'Maria',
        texto: 'Mensagem de voz (0:14)',
        tipo: 'audio',
        caminhoAnexo: 'C:/audios/audio_123.m4a',
        nomeAnexo: 'audio_123.m4a',
        tamanhoAnexo: 24500,
        dataHora: DateTime.now(),
      );

      final json = msgAudio.toJson();
      final recuperada = MensagemChat.fromJson(json);

      expect(recuperada.tipo, equals('audio'));
      expect(recuperada.caminhoAnexo, equals('C:/audios/audio_123.m4a'));
      expect(recuperada.tamanhoAnexo, equals(24500));

      final resumo = ChatService.gerarResumoMensagem(recuperada);
      expect(resumo, contains('🎤'));
      expect(resumo, contains('Mensagem de voz (0:14)'));
    });
  });
}

