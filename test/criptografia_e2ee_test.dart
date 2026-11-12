import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/seguranca_servidor_relay.dart';

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

  group('Criptografia Soberana E2EE (X25519 + AES-GCM)', () {
    const cpfAlice = '11122233344';
    const cpfBob = '55566677788';
    const cpfEve = '99988877766';

    test('Gera e recupera chaves X25519 persistidas no cofre SQLite', () async {
      final pubAlice1 = await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);
      final pubAlice2 = await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);

      expect(pubAlice1.isNotEmpty, true);
      expect(pubAlice1, equals(pubAlice2), reason: 'A chave deve ser persistida e idempotente');

      final pubBob = await CriptografiaService.obterOuGerarChaveTroca(cpfBob);
      expect(pubBob.isNotEmpty, true);
      expect(pubBob, isNot(equals(pubAlice1)));
    });

    test('Alice cifra mensagem para Bob, Bob decifra com sucesso', () async {
      final pubAlice = await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);
      final pubBob = await CriptografiaService.obterOuGerarChaveTroca(cpfBob);

      const mensagemOriginal = 'Olá Bob! Esta é uma mensagem confidencial soberana.';

      final textoCifrado = await CriptografiaService.cifrarTextoPara(
        texto: mensagemOriginal,
        meuCpf: cpfAlice,
        chavePublicaDestinatarioHex: pubBob,
      );

      expect(CriptografiaService.ehTextoCifrado(textoCifrado), true);
      expect(textoCifrado, isNot(contains(mensagemOriginal)));

      final textoDecifradoPorBob = await CriptografiaService.decifrarTextoDe(
        textoCifrado: textoCifrado,
        meuCpf: cpfBob,
        chavePublicaRemetenteHex: pubAlice,
      );

      expect(textoDecifradoPorBob, equals(mensagemOriginal));
    });

    test('Bob responde Alice e Alice decifra com sucesso (Bidirecional)', () async {
      final pubAlice = await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);
      final pubBob = await CriptografiaService.obterOuGerarChaveTroca(cpfBob);

      const respostaOriginal = 'Recebido em alto e bom som, Alice!';

      final respostaCifrada = await CriptografiaService.cifrarTextoPara(
        texto: respostaOriginal,
        meuCpf: cpfBob,
        chavePublicaDestinatarioHex: pubAlice,
      );

      expect(CriptografiaService.ehTextoCifrado(respostaCifrada), true);

      final respostaDecifradaPorAlice = await CriptografiaService.decifrarTextoDe(
        textoCifrado: respostaCifrada,
        meuCpf: cpfAlice,
        chavePublicaRemetenteHex: pubBob,
      );

      expect(respostaDecifradaPorAlice, equals(respostaOriginal));
    });

    test('Terceiro intrometido (Eve) não consegue decifrar mensagem entre Alice e Bob', () async {
      final pubAlice = await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);
      final pubBob = await CriptografiaService.obterOuGerarChaveTroca(cpfBob);
      await CriptografiaService.obterOuGerarChaveTroca(cpfEve);

      const mensagemSecreta = 'Segredo que apenas Alice e Bob devem saber.';

      final textoCifrado = await CriptografiaService.cifrarTextoPara(
        texto: mensagemSecreta,
        meuCpf: cpfAlice,
        chavePublicaDestinatarioHex: pubBob,
      );

      // Eve tenta decifrar usando sua própria chave
      final tentativaEve = await CriptografiaService.decifrarTextoDe(
        textoCifrado: textoCifrado,
        meuCpf: cpfEve,
        chavePublicaRemetenteHex: pubAlice,
      );

      expect(tentativaEve, equals('[Mensagem Cifrada Protegida]'));
      expect(tentativaEve, isNot(contains(mensagemSecreta)));
    });

    test('Retrocompatibilidade graciosa: mensagem não cifrada retorna texto intacto', () async {
      const textoComum = 'Mensagem antiga ou de sistema sem criptografia.';
      final resultado = await CriptografiaService.decifrarTextoDe(
        textoCifrado: textoComum,
        meuCpf: cpfAlice,
        chavePublicaRemetenteHex: 'qualquer_chave',
      );

      expect(resultado, equals(textoComum));
    });

    test('Cifragem simétrica de arquivos/mídias com AES-GCM 256-bit', () async {
      final bytesOriginais = Uint8List.fromList(utf8.encode('Bytes de imagem JPEG ou audio confidencial'));
      final chaveMidia = await CriptografiaService.gerarChaveSimetricaMidia();
      final chaveHex = await CriptografiaService.exportarChaveHex(chaveMidia);

      expect(chaveHex.length, 64); // 32 bytes em hexadecimal

      final bytesCifrados = await CriptografiaService.cifrarBytesComChave(bytesOriginais, chaveMidia);
      expect(bytesCifrados, isNot(equals(bytesOriginais)));

      final chaveImportada = CriptografiaService.importarChaveHex(chaveHex);
      final bytesDecifrados = await CriptografiaService.decifrarBytesComChave(bytesCifrados, chaveImportada);

      expect(bytesDecifrados, isNotNull);
      expect(bytesDecifrados, equals(bytesOriginais));

      // Tentativa de decifrar com chave errada falha com retorno nulo
      final chaveErrada = await CriptografiaService.gerarChaveSimetricaMidia();
      final falhaDecifragem = await CriptografiaService.decifrarBytesComChave(bytesCifrados, chaveErrada);
      expect(falhaDecifragem, isNull);
    });

    test('Fluxo completo de anexo e mídia no ChatE2eeService', () async {
      await CriptografiaService.obterOuGerarChaveTroca(cpfBob);
      await CriptografiaService.obterOuGerarChaveTroca(cpfAlice);

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/foto_teste_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final bytesImagem = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04]);
      await tempFile.writeAsBytes(bytesImagem);

      final conversaId = 'user_${cpfAlice}_user_$cpfBob';
      final msgComAnexo = MensagemChat(
        id: 'msg_anexo_e2ee',
        conversaId: conversaId,
        remetenteId: cpfAlice,
        remetenteNome: 'Alice',
        destinatarioId: cpfBob,
        texto: 'Olha o comprovante da compra',
        tipo: 'imagem',
        caminhoAnexo: tempFile.path,
        nomeAnexo: 'comprovante.jpg',
        dataHora: DateTime.now(),
      );

      final msgCifrada = await ChatE2eeService.cifrarMensagemSeAplicavel(msgComAnexo);
      expect(CriptografiaService.ehTextoCifrado(msgCifrada.texto), true);

      // Verifica se a versão .enc foi gerada
      final arqEnc = File('${tempFile.path}.enc');
      expect(arqEnc.existsSync(), true);

      // Simula o recebimento do arquivo cifrado por Bob
      final arquivoBob = File('${tempDir.path}/recebido_bob_${DateTime.now().millisecondsSinceEpoch}.enc');
      await arquivoBob.writeAsBytes(await arqEnc.readAsBytes());

      final msgRecebidaBob = msgCifrada.copyWith(
        caminhoAnexo: arquivoBob.path,
      );

      final msgDecifradaBob = await ChatE2eeService.decifrarMensagemSeAplicavel(
        msgRecebidaBob,
        cpfVisualizador: cpfBob,
      );

      expect(msgDecifradaBob.texto, equals('Olha o comprovante da compra'));
      expect(File(msgDecifradaBob.caminhoAnexo).existsSync(), true);
      final bytesBob = await File(msgDecifradaBob.caminhoAnexo).readAsBytes();
      expect(bytesBob, equals(bytesImagem));

      // Limpeza dos arquivos temporários
      try { await tempFile.delete(); } catch (_) {}
      try { await arqEnc.delete(); } catch (_) {}
      try { await File(msgDecifradaBob.caminhoAnexo).delete(); } catch (_) {}
    });

    test('Fluxo completo no ChatService: Mensagem P2P é gravada cifrada no SQLite e decifrada na leitura', () async {
      final conversaId = 'user_${cpfAlice}_user_$cpfBob';
      final msg = MensagemChat(
        id: 'msg_e2ee_1',
        conversaId: conversaId,
        remetenteId: cpfAlice,
        remetenteNome: 'Alice Cidadã',
        destinatarioId: cpfBob,
        texto: 'Olá Bob, este dado pessoal não pode vazar!',
        dataHora: DateTime.now(),
      );

      // Alice envia a mensagem instantânea
      await ChatService.enviarMensagemInstantanea(msg);

      // 1. Verificação direta no banco SQLite: o texto GRAVADO está cifrado com 'e2ee:v1:'
      final db = await BancoDadosService.db;
      final rows = await db.query(
        'mensagens_chat',
        where: 'id = ?',
        whereArgs: ['msg_e2ee_1'],
      );

      expect(rows.isNotEmpty, true);
      final textoGravadoNoBanco = rows.first['texto'] as String;
      expect(CriptografiaService.ehTextoCifrado(textoGravadoNoBanco), true);
      expect(textoGravadoNoBanco, isNot(contains('não pode vazar')));

      // 2. Leitura por Bob (destinatário legítimo): mensagem decifrada com sucesso
      final msgsBob = await ChatService.carregarMensagens(
        conversaId,
        idVisualizador: cpfBob,
      );
      final msgDecifradaBob = msgsBob.firstWhere((m) => m.id == 'msg_e2ee_1');
      expect(msgDecifradaBob.texto, equals('Olá Bob, este dado pessoal não pode vazar!'));

      // 3. Leitura por Alice (remetente): decifra o que ela mesma enviou
      final msgsAlice = await ChatService.carregarMensagens(
        conversaId,
        idVisualizador: cpfAlice,
      );
      final msgDecifradaAlice = msgsAlice.firstWhere((m) => m.id == 'msg_e2ee_1');
      expect(msgDecifradaAlice.texto, equals('Olá Bob, este dado pessoal não pode vazar!'));

      // 4. Leitura por Eve (terceiro): vê apenas a mensagem protegida
      final msgsEve = await ChatService.carregarMensagens(
        conversaId,
        idVisualizador: cpfEve,
      );
      final msgEve = msgsEve.firstWhere((m) => m.id == 'msg_e2ee_1');
      expect(msgEve.texto, equals('[Mensagem Cifrada Protegida]'));
    });
  });

  group('Segurança e Blindagem do Servidor Relay (Pilar 2)', () {
    test('Validação de tamanho de pacotes WebSocket pelo SegurancaServidorRelay', () {
      final pacoteGigante = Uint8List(SegurancaServidorRelay.limiteBytesMensagemWs + 100);
      final permitido = SegurancaServidorRelay.verificarMensagemWsPermitida(
        null,
        '192.168.1.100',
        pacoteGigante,
      );
      expect(permitido, false, reason: 'Pacote que excede 2 MB deve ser bloqueado imediatamente');

      final pacoteLeve = Uint8List(1024);
      final permitidoLeve = SegurancaServidorRelay.verificarMensagemWsPermitida(
        null,
        '192.168.1.100',
        pacoteLeve,
      );
      expect(permitidoLeve, true);
    });

    test('Rate Limiter de mensagens WebSocket bloqueia floods', () {
      const ip = '192.168.1.200';
      var todasAceitas = true;
      for (var i = 0; i < 40; i++) {
        final ok = SegurancaServidorRelay.verificarMensagemWsPermitida(
          null,
          ip,
          'msg_$i',
        );
        if (!ok) {
          todasAceitas = false;
          break;
        }
      }
      expect(todasAceitas, false, reason: 'Disparo de mais de 35 msgs/s deve acionar o rate limiter');
    });

    test('Exportação e importação do cofre de chaves soberanas protegido por senha', () async {
      const cpfTeste = '77788899900';
      const senhaCorreta = 'SenhaForte123!';
      const senhaIncorreta = 'SenhaErrada999!';

      await CriptografiaService.obterOuGerarChavePublica(cpfTeste);
      await CriptografiaService.obterOuGerarChaveTroca(cpfTeste);

      final envelopeCifrado = await CriptografiaService.exportarCofreChavesComSenha(
        cpf: cpfTeste,
        senhaMestre: senhaCorreta,
      );
      expect(envelopeCifrado.contains('nous_cofre_chaves_v1'), true);

      // Tentativa com senha errada deve falhar com segurança
      final falhou = await CriptografiaService.importarCofreChavesComSenha(
        payloadCifrado: envelopeCifrado,
        senhaMestre: senhaIncorreta,
      );
      expect(falhou, false);

      // Tentativa com senha certa deve restaurar perfeitamente
      final sucesso = await CriptografiaService.importarCofreChavesComSenha(
        payloadCifrado: envelopeCifrado,
        senhaMestre: senhaCorreta,
      );
      expect(sucesso, true);
    });
  });
}
