import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_mensagens_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );

    await BancoDadosService.db;
  });

  group('Ponto Cego 1 & 2 — Backup Completo do Chat e Mídias Físicas', () {
    test('BackupService exporta e restaura conversas, mensagens e mídias em Base64', () async {
      await ChatRepositorioSqlite.obterDb();

      // 1. Cria uma conversa e mensagem de teste
      const convId = 'user_11111111111_user_22222222222';
      final agora = DateTime.now();

      final msg = MensagemChat(
        id: 'msg_backup_teste_${agora.millisecondsSinceEpoch}',
        conversaId: convId,
        remetenteId: '11111111111',
        remetenteNome: 'Alice',
        destinatarioId: '22222222222',
        texto: 'Mensagem de teste para backup soberano',
        dataHora: agora,
        statusEnvio: 'enviada',
      );

      await ChatMensagensService.salvarMensagem(
        msg,
        obterCpfLogadoLocal: () async => '11111111111',
        aoNotificar: () {},
      );

      // 2. Cria arquivo de mídia física de teste na pasta de imagens
      final pastaBase = await ImagemService.obterDiretorioBase();
      final pastaImagens = Directory('${pastaBase.path}/imagens');
      if (!pastaImagens.existsSync()) {
        await pastaImagens.create(recursive: true);
      }
      final arquivoMidia = File('${pastaImagens.path}/foto_teste_backup.jpg');
      final bytesOriginais = Uint8List.fromList([1, 2, 3, 4, 5, 42, 99]);
      await arquivoMidia.writeAsBytes(bytesOriginais);

      // 3. Gera o backup JSON completo
      final jsonBackup = await BackupService.gerarJson();

      expect(jsonBackup.containsKey('conversas'), true);
      expect(jsonBackup.containsKey('mensagens'), true);
      expect(jsonBackup.containsKey('midias'), true);

      final conversas = jsonBackup['conversas'] as List;
      final mensagens = jsonBackup['mensagens'] as List;
      final midias = jsonBackup['midias'] as Map<String, dynamic>;

      expect(conversas.any((c) => c['id'] == convId), true);
      expect(mensagens.any((m) => m['id'] == msg.id), true);
      expect(midias.containsKey('foto_teste_backup.jpg'), true);

      // 4. Apaga o arquivo de mídia para testar a autocura e restauração
      if (arquivoMidia.existsSync()) {
        await arquivoMidia.delete();
      }
      expect(arquivoMidia.existsSync(), false);

      // 5. Restaura a partir do JSON de backup
      final resultado = await BackupService.aplicarJson(jsonBackup, substituir: false);

      expect(resultado.midiasImportadas >= 1, true);
      expect(arquivoMidia.existsSync(), true, reason: 'A mídia deve ser restaurada a partir do Base64');
      final bytesRestaurados = await arquivoMidia.readAsBytes();
      expect(bytesRestaurados, equals(bytesOriginais));

      // Limpeza
      if (arquivoMidia.existsSync()) {
        await arquivoMidia.delete();
      }
    });
  });
}
