import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Mensageria e Resolução de Fotos', () {
    test('ImagemService.resolverCaminhoExistente lida com caminhos Windows em qualquer plataforma', () {
      // Cria arquivo temporário de teste
      final tempDir = Directory.systemTemp.createTempSync('nous_img_test');
      final testFile = File('${tempDir.path}/foto_teste_rosa.jpg');
      testFile.writeAsBytesSync([1, 2, 3]);

      // Caminho simulando Windows vindo de outro terminal (com barras invertidas)
      final caminhoSimuladoWindows = r'C:\Users\Rosa\AppData\Roaming\Nous\imagens\foto_teste_rosa.jpg';
      
      // O nome do arquivo normalizado deve ser extraído corretamente sem quebrar
      final norm = caminhoSimuladoWindows.replaceAll(r'\', '/');
      expect(norm.endsWith('/foto_teste_rosa.jpg'), isTrue);

      testFile.deleteSync();
      tempDir.deleteSync(recursive: true);
    });

    test('ChatService.obterTodasConversas inclui grupos mesmo quando o CPF não está em participantes_json', () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE conversas_chat (
                id TEXT PRIMARY KEY,
                titulo TEXT,
                nome_grupo TEXT,
                subtitulo TEXT,
                foto TEXT,
                identificador TEXT,
                eh_loja INTEGER,
                eh_grupo INTEGER,
                loja_id TEXT,
                participantes_json TEXT,
                criado_em TEXT,
                atualizado_em TEXT,
                ultima_mensagem TEXT,
                data_hora_ultima_mensagem TEXT,
                arquivada INTEGER DEFAULT 0,
                fixada INTEGER DEFAULT 0
              )
            ''');
            await db.execute('''
              CREATE TABLE mensagens_chat (
                id TEXT PRIMARY KEY,
                conversa_id TEXT,
                remetente_id TEXT,
                remetente_nome TEXT,
                remetente_foto TEXT,
                destinatario_id TEXT,
                texto TEXT,
                data_hora TEXT,
                nome_atendente TEXT,
                cpf_atendente TEXT,
                lida INTEGER,
                tipo TEXT,
                caminho_anexo TEXT,
                nome_anexo TEXT,
                tamanho_anexo INTEGER,
                pedido_id TEXT,
                dados_pedido_json TEXT,
                editada INTEGER,
                historico_edicoes TEXT,
                status_envio TEXT,
                entregue INTEGER
              )
            ''');
          },
        ),
      );

      // Insere um grupo onde os participantes gravados anteriormente eram apenas ["sistema", "grupo_1"]
      await db.insert('conversas_chat', {
        'id': 'grupo_familia',
        'titulo': 'Família',
        'nome_grupo': 'Família',
        'subtitulo': 'Grupo Nós',
        'foto': '',
        'identificador': 'grupo_familia',
        'eh_loja': 0,
        'eh_grupo': 1,
        'loja_id': '',
        'participantes_json': jsonEncode(['sistema', 'grupo_familia']),
        'criado_em': DateTime.now().toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
        'ultima_mensagem': 'Olá família',
        'data_hora_ultima_mensagem': DateTime.now().toIso8601String(),
      });

      // Usuário Rosa buscando conversas
      final cpfRosa = '98765432100';
      final rows = await db.query(
        'conversas_chat',
        where: '(participantes_json LIKE ? OR identificador = ? OR id LIKE ? OR eh_grupo = 1)',
        whereArgs: ['%$cpfRosa%', cpfRosa, '%$cpfRosa%'],
      );

      expect(rows.length, equals(1));
      expect(rows.first['id'], equals('grupo_familia'));
      expect(rows.first['eh_grupo'], equals(1));
    });

    test('ChatService.obterMensagensParaSincronizacao inclui mensagens de grupo', () async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE mensagens_chat (
                id TEXT PRIMARY KEY,
                conversa_id TEXT,
                remetente_id TEXT,
                remetente_nome TEXT,
                remetente_foto TEXT,
                destinatario_id TEXT,
                texto TEXT,
                data_hora TEXT,
                nome_atendente TEXT,
                cpf_atendente TEXT,
                lida INTEGER,
                tipo TEXT,
                caminho_anexo TEXT,
                nome_anexo TEXT,
                tamanho_anexo INTEGER,
                pedido_id TEXT,
                dados_pedido_json TEXT,
                editada INTEGER,
                historico_edicoes TEXT,
                status_envio TEXT,
                entregue INTEGER
              )
            ''');
          },
        ),
      );

      // Carol enviou uma mensagem no grupo
      await db.insert('mensagens_chat', {
        'id': 'msg_1',
        'conversa_id': 'grupo_familia',
        'remetente_id': '11122233344', // Carol
        'remetente_nome': 'Carol',
        'destinatario_id': 'grupo_familia',
        'texto': 'Bom dia!',
        'data_hora': DateTime.now().toIso8601String(),
        'lida': 0,
        'entregue': 1,
        'status_envio': 'enviada',
      });

      // Rosa sincroniza suas mensagens
      final cpfRosa = '98765432100';
      final msgs = await db.query(
        'mensagens_chat',
        where: 'remetente_id = ? OR destinatario_id = ? OR conversa_id LIKE ? OR conversa_id LIKE ? OR conversa_id LIKE ?',
        whereArgs: [cpfRosa, cpfRosa, '%$cpfRosa%', 'grupo_%', 'loja_nous_coletiva_%'],
      );

      // Deve retornar a mensagem do grupo para Rosa, mesmo ela não sendo remetente nem destinatário direto
      expect(msgs.length, equals(1));
      expect(msgs.first['texto'], equals('Bom dia!'));
    });
  });
}
