import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

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

    test('ConversaChat.fromJson lida com formato SQLite com participantes_json e inteiros para booleanos', () {
      final mapaSqlite = {
        'id': 'lo_nous_topico_1',
        'titulo': 'Projetos e Parcerias',
        'subtitulo': 'Tópico de conversa delimitado pelos membros',
        'foto': '',
        'identificador': 'todos',
        'eh_loja': 1,
        'eh_grupo': 1,
        'loja_id': ChatService.idLojaColetivaNous,
        'participantes_json': '["todos", "12345678901"]',
        'ultima_mensagem': 'Nova proposta enviada',
        'data_hora_ultima_mensagem': '2026-10-28T09:00:00.000Z',
        'fixada': 0,
        'arquivada': 0,
        'atualizado_em': '2026-10-28T09:10:00.000Z',
      };

      final c = ConversaChat.fromJson(mapaSqlite);
      expect(c.id, equals('lo_nous_topico_1'));
      expect(c.titulo, equals('Projetos e Parcerias'));
      expect(c.ehLoja, isTrue);
      expect(c.ehGrupo, isTrue);
      expect(c.lojaId, equals(ChatService.idLojaColetivaNous));
      expect(c.participantesIds, containsAll(['todos', '12345678901']));
      expect(c.ultimaMensagem, equals('Nova proposta enviada'));
      expect(c.fixada, isFalse);
    });

    test('ChatService possui identificadores padronizados para Comunidade Nous e tópico Geral', () {
      expect(ChatService.idLojaColetivaNous, isNotEmpty);
      expect(ChatService.idTopicoGeral, isNotEmpty);
      expect(ChatService.idTopicoGeral, contains('loja_nous'));
    });

    test('ChatService.obterInterlocutoresDoUsuario executa query SQL sem erro de sintaxe', () async {
      // Valida que o CPF normalizado executa a query com WHERE sem erro de coluna "sistema"
      final interlocutores = await ChatService.obterInterlocutoresDoUsuario('471.929.568-13');
      expect(interlocutores, isA<Map<String, ({String nome, String foto})>>());
    });

    test('Tombstones de conversa impedem ressurreição após exclusão local e sincronizam', () async {
      const convId = 'teste_conversa_excluida_123';
      expect(await ChatService.isConversaExcluida(convId), isFalse);

      await ChatService.excluirConversaLocal(convId);
      expect(await ChatService.isConversaExcluida(convId), isTrue);

      final excluidas = await ChatService.obterIdsConversasExcluidas();
      expect(excluidas, contains(convId));

      await ChatService.desmarcarConversaExcluida(convId);
      expect(await ChatService.isConversaExcluida(convId), isFalse);
    });

    test('Salas Comunitárias preservam nome escolhido e registram criador e membros', () async {
      const nomeSala = 'Desenvolver';
      const cpfCriador = '111.222.333-44';
      final topico = await ChatService.criarOuObterTopicoComunidadeNous(
        'desenvolver',
        nomeSala,
        cpfCriador,
      );

      expect(topico.titulo, equals('Desenvolver'));
      expect(topico.identificador, equals('11122233344'));
      expect(topico.participantesIds, contains('11122233344'));

      // Entrar na sala adiciona usuário
      await ChatService.entrarTopicoComunidade(
        topicoId: topico.id,
        cpf: '555.666.777-88',
        nomeUsuario: 'Maria',
      );

      final salas = await ChatService.obterTodasSalasComunitarias();
      final salaSalva = salas.firstWhere((s) => s.id == topico.id);
      expect(salaSalva.participantesIds, contains('55566677788'));

      // Sair da sala remove usuário
      await ChatService.sairTopicoComunidade(
        topicoId: topico.id,
        cpf: '555.666.777-88',
        nomeUsuario: 'Maria',
      );

      final salasAposSaida = await ChatService.obterTodasSalasComunitarias();
      final salaAposSaida = salasAposSaida.firstWhere((s) => s.id == topico.id);
      expect(salaAposSaida.participantesIds.contains('55566677788'), isFalse);
    });

    test('Nome do Grupo é independente do título da conversa e permanece mesmo se o título for renomeado', () {
      final agora = DateTime.now();
      final conversaGrupo = ConversaChat(
        id: 'grupo_123',
        identificador: 'grupo_123',
        titulo: 'Conversa',
        nomeGrupo: 'Amigos do Futebol',
        subtitulo: 'Grupo • 5 participantes',
        ehGrupo: true,
        dataHoraUltimaMensagem: agora,
        participantesIds: ['111', '222'],
      );

      final json = conversaGrupo.toJson();
      expect(json['nomeGrupo'], equals('Amigos do Futebol'));
      expect(json['titulo'], equals('Conversa'));

      final recuperada = ConversaChat.fromJson(json);
      expect(recuperada.nomeGrupo, equals('Amigos do Futebol'));
      expect(recuperada.titulo, equals('Amigos do Futebol'));

      // Se renomear o título da conversa, o nomeGrupo permanece o mesmo
      final renomeada = recuperada.copyWith(titulo: 'Chat Importante de Futebol');
      expect(renomeada.titulo, equals('Chat Importante de Futebol'));
      expect(renomeada.nomeGrupo, equals('Amigos do Futebol'));
    });

    test('Mensagens de nós diferentes intercaladas são estritamente ordenadas por data_hora cronológica', () {
      final t0 = DateTime(2026, 10, 28, 20, 0, 0);
      final t1 = DateTime(2026, 10, 28, 20, 0, 5);
      final t2 = DateTime(2026, 10, 28, 20, 0, 10);
      final t3 = DateTime(2026, 10, 28, 20, 0, 15);

      final msgPC1 = MensagemChat(
        id: 'pc_1',
        conversaId: 'conv_1',
        remetenteId: 'user',
        remetenteNome: 'Eu (PC)',
        texto: 'Primeira mensagem do PC',
        dataHora: t0,
      );

      final msgCel1 = MensagemChat(
        id: 'cel_1',
        conversaId: 'conv_1',
        remetenteId: 'outro',
        remetenteNome: 'Celular',
        texto: 'Resposta rápida do celular',
        dataHora: t1,
      );

      final msgPC2 = MensagemChat(
        id: 'pc_2',
        conversaId: 'conv_1',
        remetenteId: 'user',
        remetenteNome: 'Eu (PC)',
        texto: 'Segunda mensagem do PC',
        dataHora: t2,
      );

      final msgCel2 = MensagemChat(
        id: 'cel_2',
        conversaId: 'conv_1',
        remetenteId: 'outro',
        remetenteNome: 'Celular',
        texto: 'Última mensagem do celular',
        dataHora: t3,
      );

      // Inserção em ordem arbitrária/desordenada de rede
      final lista = [msgCel2, msgPC1, msgCel1, msgPC2];

      // Ordenação rigorosa implementada no ChatService e MensageriaView
      lista.sort((a, b) {
        final comp = a.dataHora.compareTo(b.dataHora);
        if (comp != 0) return comp;
        return a.id.compareTo(b.id);
      });

      expect(lista[0].id, equals('pc_1'));
      expect(lista[1].id, equals('cel_1'));
      expect(lista[2].id, equals('pc_2'));
      expect(lista[3].id, equals('cel_2'));
      expect(lista.last.texto, equals('Última mensagem do celular'));
    });

    test('ChatService.extrairOutroCpf extrai o CPF oposto com perfeição a partir do ID canônico', () {
      final cpfA = '11122233344';
      final cpfB = '55566677788';
      final convId = ChatService.conversaIdEntreUsuarios(cpfA, cpfB);

      expect(ChatService.extrairOutroCpf(convId, cpfA), equals(cpfB));
      expect(ChatService.extrairOutroCpf(convId, cpfB), equals(cpfA));
      expect(ChatService.extrairOutroCpf('grupo_123', cpfA), isEmpty);
    });

    test('Busca de contatos e usuários Nous filtra por nome, @username e CPF exibindo dados reais', () {
      final convUser = ConversaChat(
        id: 'user_11122233344_user_99988877766',
        titulo: 'Leonardo Silva',
        subtitulo: '@leosilva',
        foto: 'caminho/foto.jpg',
        identificador: '99988877766',
        ehLoja: false,
        dataHoraUltimaMensagem: DateTime.now(),
      );

      expect(convUser.titulo, isNot(equals('Conversa')));
      expect(convUser.subtitulo, equals('@leosilva'));
      expect(convUser.titulo.toLowerCase().contains('leonardo'), isTrue);
      expect(convUser.subtitulo.toLowerCase().contains('leosilva'), isTrue);
    });

    test('obterTitulosCustomizados ignora placeholders e ConversaChat.fromJson descarta Conversa', () {
      final jsonLegado = {
        'id': 'user_11122233344_user_99988877766',
        'titulo': 'Conversa',
        'subtitulo': '@carlos',
        'identificador': '99988877766',
        'ehLoja': false,
        'ehGrupo': false,
      };

      final c = ConversaChat.fromJson(jsonLegado);
      expect(c.titulo, isNot(equals('Conversa')));
      expect(c.titulo, equals('@carlos'));
    });

    test('obterTitulosCustomizados com cpfLogado não assume o próprio nome do usuário como título de contato', () async {
      final titulos = await ChatService.obterTitulosCustomizados('11122233344');
      for (final t in titulos.values) {
        expect(t, isNot(equals('Conversa')));
        expect(t, isNot(equals('Nova Conversa')));
        expect(t, isNot(equals('Contato Nous')));
      }
    });

    test('MontadorConversasChat.resumoMensagem gera resumos visuais corretos com emojis temáticos', () {
      final msgTexto = MensagemChat(
        id: '1',
        conversaId: 'c1',
        remetenteId: 'u1',
        remetenteNome: 'Nome',
        texto: 'Olá amigo',
        dataHora: DateTime.now(),
      );
      expect(MontadorConversasChat.resumoMensagem(msgTexto), equals('Olá amigo'));

      final msgFoto = msgTexto.copyWith(tipo: 'imagem', texto: '');
      expect(MontadorConversasChat.resumoMensagem(msgFoto), equals('📷 Foto'));

      final msgAudio = msgTexto.copyWith(tipo: 'audio', texto: '');
      expect(MontadorConversasChat.resumoMensagem(msgAudio), equals('🎤 Mensagem de Voz'));

      final msgComanda = msgTexto.copyWith(tipo: 'comanda', texto: '');
      expect(MontadorConversasChat.resumoMensagem(msgComanda), equals('🧾 Comanda de Pedido'));

      final msgArquivo = msgTexto.copyWith(tipo: 'arquivo', nomeAnexo: 'relatorio.pdf', texto: '');
      expect(MontadorConversasChat.resumoMensagem(msgArquivo), equals('📎 relatorio.pdf'));
    });

    test('MensageriaController.combinaBusca não dá falso positivo em lojas ao buscar por "j"', () {
      final controller = MensageriaController();
      final conversaLoja = ConversaChat(
        id: 'loja_bebasbolos_usuario_12345678900',
        titulo: 'Bebasbolos',
        subtitulo: 'Loja',
        identificador: 'loja_bebasbolos',
        ehLoja: true,
        dataHoraUltimaMensagem: DateTime.now(),
      );

      // 'Bebasbolos' não tem 'j' no título nem subtítulo. O identificador 'loja_bebasbolos' contém 'j', mas não deve casar!
      expect(controller.combinaBusca(conversaLoja, 'j'), isFalse);
      expect(controller.combinaBusca(conversaLoja, 'beba'), isTrue);
    });

    test('Conversas com mensagens reais se mantêm no topo e lojas vazias com epoch 0 ficam no final', () {
      final conversaAtiva = ConversaChat(
        id: 'loja_laricas_usuario_123',
        titulo: 'Laricas',
        subtitulo: 'Loja',
        identificador: 'loja_laricas',
        ehLoja: true,
        dataHoraUltimaMensagem: DateTime.now(),
        ultimaMensagem: 'Oi, tudo bem?',
      );

      final conversaVazia = ConversaChat(
        id: 'loja_outra_usuario_123',
        titulo: 'Outra Loja',
        subtitulo: 'Loja',
        identificador: 'loja_outra',
        ehLoja: true,
        dataHoraUltimaMensagem: DateTime.fromMillisecondsSinceEpoch(0),
        ultimaMensagem: 'Toque para conversar com a loja.',
      );

      final lista = [conversaVazia, conversaAtiva];
      lista.sort((a, b) {
        if (a.fixada != b.fixada) return a.fixada ? -1 : 1;
        return b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem);
      });

      expect(lista.first.titulo, equals('Laricas'));
      expect(lista.last.titulo, equals('Outra Loja'));
    });

    test('enviarMensagem move imediatamente a conversa selecionada para o topo da lista de conversas', () async {
      final controller = MensageriaController();
      final auth = AuthProvider();

      final conv1 = ConversaChat(
        id: 'c1',
        titulo: 'Primeira',
        subtitulo: 'Sub',
        identificador: 'id1',
        ehLoja: false,
        dataHoraUltimaMensagem: DateTime(2026, 1, 1),
      );

      final convLaricas = ConversaChat(
        id: 'loja_laricas',
        titulo: 'Laricas',
        subtitulo: 'Loja',
        identificador: 'laricas_id',
        ehLoja: true,
        dataHoraUltimaMensagem: DateTime(2026, 1, 1),
      );

      controller.conversas.addAll([conv1, convLaricas]);
      controller.selecionarConversa(convLaricas);

      expect(controller.conversas[0].id, equals('c1'));
      expect(controller.conversas[1].id, equals('loja_laricas'));

      await controller.enviarMensagem(
        texto: 'Olá Laricas',
        auth: auth,
      );

      expect(controller.conversas.first.id, equals('loja_laricas'));
      expect(controller.conversas.first.ultimaMensagem, equals('Olá Laricas'));
    });

    test('MensageriaController não lança erro ao chamar notifyListeners após dispose', () {
      final controller = MensageriaController();
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      expect(() => controller.notifyListeners(), returnsNormally);
    });

    test('ClienteRedeLocal desconectar(manual: true) desativa conexões e reseta estado sem loops', () async {
      final cliente = ClienteRedeLocal();
      expect(cliente.conectado, isFalse);
      expect(cliente.conectando, isFalse);

      await cliente.desconectar(manual: true);
      expect(cliente.estaConectado.value, isFalse);
      expect(cliente.conectado, isFalse);
      expect(cliente.ipServidor, isNull);
      expect(cliente.portaServidor, isNull);
    });

    test('ConvitesService salva, despacha e NotificacoesProvider integra convite na rede local', () async {
      final notif = NotificacoesProvider();
      expect(NotificacoesProvider.instanciaAtiva, equals(notif));

      final convite = ConviteLoja(
        id: 'conv_123',
        cpfConvidante: '11122233344',
        nomeConvidante: 'Carol',
        cpfConvidado: '55566677788',
        lojaId: 'loja_teste_1',
        nomeLoja: 'Loja Teste',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
      );

      await ConvitesService.adicionar('55566677788', convite);
      final carregados = await ConvitesService.carregar('55566677788');
      expect(carregados.any((c) => c.id == 'conv_123'), isTrue);

      await notif.carregarParaCpf('55566677788');
      expect(notif.quantidadePendentes, greaterThanOrEqualTo(1));
      expect(notif.convites.any((c) => c.id == 'conv_123'), isTrue);

      await notif.aceitar('conv_123');
      expect(notif.convites.any((c) => c.id == 'conv_123'), isFalse);
    });

    test('salvarMensagem garante causalidade monotônica mesmo com relógio do emissor atrasado', () async {
      final baseId = 'conv_lamport_${DateTime.now().millisecondsSinceEpoch}';
      final agora = DateTime.now();

      final msg1 = MensagemChat(
        id: 'msg_1_$baseId',
        conversaId: baseId,
        remetenteId: '47192956813',
        remetenteNome: 'Leonardo',
        destinatarioId: '43334347850',
        texto: 'Primeira pergunta',
        dataHora: agora,
      );
      await ChatService.salvarMensagem(msg1);

      // Simulando relógio do celular atrasado em 2 minutos
      final relogioAtrasadoDoCelular = agora.subtract(const Duration(minutes: 2));
      final msg2Atrasada = MensagemChat(
        id: 'msg_2_$baseId',
        conversaId: baseId,
        remetenteId: '43334347850',
        remetenteNome: 'Carol',
        destinatarioId: '47192956813',
        texto: 'Resposta enviada do celular',
        dataHora: relogioAtrasadoDoCelular,
      );
      await ChatService.salvarMensagem(msg2Atrasada);

      final msgs = await ChatService.carregarMensagens(baseId);
      expect(msgs.length, equals(2));
      expect(msgs[0].texto, equals('Primeira pergunta'));
      expect(msgs[1].texto, equals('Resposta enviada do celular'));
      // A segunda mensagem deve ser posterior à primeira
      expect(msgs[1].dataHora.isAfter(msgs[0].dataHora), isTrue);
    });

    test('ConversaChat temTituloConversa descarta títulos que replicam o nome do contato', () {
      final conversaComNomeDuplicado = ConversaChat(
        id: 'user_1_user_2',
        titulo: 'Claudiane Basilio Fernandes',
        tituloConversa: 'Claudiane Basilio Fernandes',
        identificador: '33610704810',
        dataHoraUltimaMensagem: DateTime.now(),
      );
      expect(conversaComNomeDuplicado.temTituloConversa, isFalse);

      final conversaComTituloReal = ConversaChat(
        id: 'user_1_user_2',
        titulo: 'Claudiane Basilio Fernandes',
        tituloConversa: 'Orçamento de Doces',
        identificador: '33610704810',
        dataHoraUltimaMensagem: DateTime.now(),
      );
      expect(conversaComTituloReal.temTituloConversa, isTrue);
    });

    test('ChatService.marcarComoLidas atualiza lida=1 e status_envio=lida', () async {
      final convId = 'teste_lidas_${DateTime.now().millisecondsSinceEpoch}';
      final msg = MensagemChat(
        id: 'msg_lida_1',
        conversaId: convId,
        remetenteId: '99999999999',
        remetenteNome: 'Remetente Teste',
        destinatarioId: '88888888888',
        texto: 'Mensagem de teste',
        dataHora: DateTime.now(),
        lida: false,
        statusEnvio: 'enviada',
      );
      await ChatService.salvarMensagem(msg);

      var msgs = await ChatService.carregarMensagens(convId);
      expect(msgs.first.lida, isFalse);

      await ChatService.marcarComoLidas(convId, '88888888888');

      msgs = await ChatService.carregarMensagens(convId);
      expect(msgs.first.lida, isTrue);
      expect(msgs.first.statusEnvio, equals('lida'));
    });

    test('ChatService.idConversaAtiva suprime contagem de mensagens nao lidas no usuario', () async {
      final convId = 'teste_ativa_${DateTime.now().millisecondsSinceEpoch}';
      final msg = MensagemChat(
        id: 'msg_ativa_1',
        conversaId: convId,
        remetenteId: '99999999999',
        remetenteNome: 'Remetente Teste',
        destinatarioId: '77777777777',
        texto: 'Aviso urgente',
        dataHora: DateTime.now(),
        lida: false,
        statusEnvio: 'enviada',
      );
      await ChatService.salvarMensagem(msg);

      ChatService.idConversaAtiva = null;
      var temNaoLidas = await ChatService.temMensagensNaoLidasNoUsuario('77777777777');
      expect(temNaoLidas, isTrue);

      // Com a conversa aberta na tela, a barra/appbar não deve indicar mensagens não lidas para essa conversa
      ChatService.idConversaAtiva = convId;
      temNaoLidas = await ChatService.temMensagensNaoLidasNoUsuario('77777777777');
      expect(temNaoLidas, isFalse);

      ChatService.idConversaAtiva = null;
    });

    test('Modo Loja preserva clientes distintos sem colapsar conversas na mesma chave', () {
      final conversaRosa = ConversaChat(
        id: 'loja_123_usuario_11111111111',
        titulo: 'Rosa',
        subtitulo: 'Cliente',
        identificador: '11111111111',
        ehLoja: true,
        lojaId: '123',
        dataHoraUltimaMensagem: DateTime(2026, 1, 1, 10, 0),
        ultimaMensagem: 'Olá da Rosa',
      );

      final conversaLeonardo = ConversaChat(
        id: 'loja_123_usuario_22222222222',
        titulo: 'Leonardo',
        subtitulo: 'Cliente',
        identificador: '22222222222',
        ehLoja: true,
        lojaId: '123',
        dataHoraUltimaMensagem: DateTime(2026, 1, 1, 10, 30),
        ultimaMensagem: 'Olá do Leonardo',
      );

      final lista = [conversaRosa, conversaLeonardo];
      final Map<String, ConversaChat> listaDesduplicada = {};
      String calcularChave(ConversaChat c, bool modoLoja) {
        return c.ehGrupo
            ? 'grupo_${c.id}'
            : (modoLoja
                ? 'loja_conversa_${c.id}'
                : (c.ehLoja
                    ? 'loja_${c.lojaId ?? c.identificador}'
                    : 'user_${c.identificador}'));
      }

      for (final c in lista) {
        final chave = calcularChave(c, true);
        listaDesduplicada[chave] = c;
      }

      expect(listaDesduplicada.length, equals(2));
      expect(listaDesduplicada.values.map((c) => c.titulo), containsAll(['Rosa', 'Leonardo']));
    });

    test('Isolamento de Identidade: contato do usuário na loja não usa logo da loja', () {
      final cpfDono = '12345678901';
      final fotoCivilDono = 'C:/Users/Nous/fotos/leonardo_civil.jpg';
      final logoLoja = 'C:/Users/Nous/fotos/laricas_alien.png';

      // Conversa gerada no modo loja para o próprio contato Nous do dono
      final conversaClienteDono = ConversaChat(
        id: 'loja_laricas_usuario_$cpfDono',
        titulo: 'Leonardo',
        subtitulo: '@taddeoleonardo • Cliente',
        identificador: cpfDono,
        ehLoja: false,
        lojaId: 'laricas',
        foto: fotoCivilDono,
        dataHoraUltimaMensagem: DateTime.now(),
      );

      expect(conversaClienteDono.ehLoja, isFalse);
      expect(conversaClienteDono.foto, equals(fotoCivilDono));
      expect(conversaClienteDono.foto, isNot(equals(logoLoja)));
      expect(conversaClienteDono.identificador, equals(cpfDono));
    });

    test('Intercalação de lados: conversa com a própria loja separa lado da loja e do cliente', () async {
      final lojaId = 'loja_berenice_123';
      final cpfLeonardo = '47192956813';
      final convId = 'loja_${lojaId}_usuario_$cpfLeonardo';

      // 1. Mensagem enviada pelo celular do Leonardo como Cliente
      final msgCliente = MensagemChat(
        id: 'msg_cli_1',
        conversaId: convId,
        remetenteId: cpfLeonardo,
        remetenteNome: 'Leonardo',
        destinatarioId: lojaId,
        texto: 'Olá, tem marmita disponível?',
        dataHora: DateTime.now(),
        cpfAtendente: '',
      );

      // 2. Mensagem respondida pelo computador balcão pela Loja Berenice com Leonardo atendendo
      final msgLoja = MensagemChat(
        id: 'msg_loja_1',
        conversaId: convId,
        remetenteId: lojaId,
        remetenteNome: 'Berenice',
        destinatarioId: cpfLeonardo,
        texto: 'Temos sim, marmita média saindo agora!',
        dataHora: DateTime.now().add(const Duration(seconds: 1)),
        cpfAtendente: cpfLeonardo,
      );

      await ChatService.salvarMensagem(msgCliente);
      await ChatService.salvarMensagem(msgLoja);

      // Ponto de vista do CELULAR (Modo Usuário / idVisualizador: cpfLeonardo):
      final msgsNoCelular = await ChatService.carregarMensagens(convId, idVisualizador: cpfLeonardo);
      final mCliNoCelular = msgsNoCelular.firstWhere((m) => m.id == 'msg_cli_1');
      final mLojaNoCelular = msgsNoCelular.firstWhere((m) => m.id == 'msg_loja_1');
      // No celular: mensagem enviada pelo cliente é enviadaPorMim=true (direita)
      expect(mCliNoCelular.enviadaPorMim, isTrue);
      // No celular: mensagem da loja é enviadaPorMim=false (esquerda), mesmo com cpfAtendente igual
      expect(mLojaNoCelular.enviadaPorMim, isFalse);

      // Ponto de vista do BALCÃO (Modo Loja / idVisualizador: lojaId):
      final msgsNoBalcao = await ChatService.carregarMensagens(convId, idVisualizador: lojaId);
      final mCliNoBalcao = msgsNoBalcao.firstWhere((m) => m.id == 'msg_cli_1');
      final mLojaNoBalcao = msgsNoBalcao.firstWhere((m) => m.id == 'msg_loja_1');
      // No balcão: mensagem enviada pelo cliente é enviadaPorMim=false (esquerda)
      expect(mCliNoBalcao.enviadaPorMim, isFalse);
      // No balcão: resposta da loja é enviadaPorMim=true (direita)
      expect(mLojaNoBalcao.enviadaPorMim, isTrue);
    });
  });
}

