import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';

/// Serviço soberano de criptografia assimétrica e assinaturas digitais do Nous.
/// Implementa o padrão Ed25519 para assinaturas infalsificáveis (identidade/atestados)
/// e X25519 para troca segura de segredos entre dispositivos.
class CriptografiaService {
  CriptografiaService._();

  static final Ed25519 _ed25519 = Ed25519();
  static final X25519 _x25519 = X25519();
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static bool _tabelaChavesCriada = false;

  /// Prefixo identificador de mensagens cifradas de ponta a ponta
  static const String prefixoE2ee = 'e2ee:v1:';

  /// Garante a criação da tabela do cofre seguro de chaves no SQLite local.
  /// As chaves privadas NUNCA saem do dispositivo e são salvas exclusivamente nesta tabela.
  static Future<void> _garantirTabela(Database db) async {
    if (_tabelaChavesCriada) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cofre_chaves_seguras (
        cpf TEXT PRIMARY KEY,
        chave_publica_hex TEXT NOT NULL,
        chave_privada_hex TEXT NOT NULL,
        criado_em TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cofre_chaves_troca (
        cpf TEXT PRIMARY KEY,
        chave_publica_hex TEXT NOT NULL,
        chave_privada_hex TEXT NOT NULL,
        criado_em TEXT NOT NULL
      );
    ''');
    _tabelaChavesCriada = true;
  }

  /// Retorna ou gera o par de chaves Ed25519 soberano vinculado ao CPF.
  /// Se já existir no cofre, recupera a chave pública.
  /// Se for o primeiro acesso, cria um par novo com entropia criptográfica nativa.
  static Future<String> obterOuGerarChavePublica(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return '';

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final registros = await db.query(
      'cofre_chaves_seguras',
      columns: ['chave_publica_hex'],
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
      limit: 1,
    );

    if (registros.isNotEmpty) {
      return registros.first['chave_publica_hex']?.toString() ?? '';
    }

    // Gera um novo par de chaves Ed25519
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    final pubHex = _bytesParaHex(publicKey.bytes);
    final privHex = _bytesParaHex(privateKeyBytes);

    await db.insert(
      'cofre_chaves_seguras',
      {
        'cpf': cpfLimpo,
        'chave_publica_hex': pubHex,
        'chave_privada_hex': privHex,
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('[CriptografiaService] Par de chaves soberanas Ed25519 gerado com sucesso para CPF $cpfLimpo');
    return pubHex;
  }

  /// Assina digitalmente uma mensagem ou carga JSON com a chave privada soberana do CPF.
  /// Retorna a assinatura em formato hexadecimal.
  static Future<String?> assinarDados({
    required String cpf,
    required String mensagem,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty || mensagem.isEmpty) return null;

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final registros = await db.query(
      'cofre_chaves_seguras',
      columns: ['chave_privada_hex', 'chave_publica_hex'],
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
      limit: 1,
    );

    if (registros.isEmpty) return null;

    final privHex = registros.first['chave_privada_hex']?.toString() ?? '';
    final pubHex = registros.first['chave_publica_hex']?.toString() ?? '';
    if (privHex.isEmpty || pubHex.isEmpty) return null;

    final privBytes = _hexParaBytes(privHex);
    final pubBytes = _hexParaBytes(pubHex);

    final keyPair = SimpleKeyPairData(
      privBytes,
      publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );

    final dadosBytes = utf8.encode(mensagem);
    final signature = await _ed25519.sign(dadosBytes, keyPair: keyPair);
    return _bytesParaHex(signature.bytes);
  }

  /// Verifica se uma assinatura digital é válida para uma dada mensagem e chave pública.
  static Future<bool> verificarAssinatura({
    required String mensagem,
    required String assinaturaHex,
    required String chavePublicaHex,
  }) async {
    try {
      if (mensagem.isEmpty || assinaturaHex.isEmpty || chavePublicaHex.isEmpty) {
        return false;
      }

      final pubBytes = _hexParaBytes(chavePublicaHex);
      final sigBytes = _hexParaBytes(assinaturaHex);
      final dadosBytes = utf8.encode(mensagem);

      final publicKey = SimplePublicKey(pubBytes, type: KeyPairType.ed25519);
      final signature = Signature(sigBytes, publicKey: publicKey);

      return await _ed25519.verify(dadosBytes, signature: signature);
    } catch (e) {
      debugPrint('[CriptografiaService] Falha ao verificar assinatura: $e');
      return false;
    }
  }

  /// Verifica se um determinado texto possui o formato cifrado de ponta a ponta (E2EE)
  static bool ehTextoCifrado(String texto) {
    return texto.startsWith(prefixoE2ee);
  }

  /// Retorna ou gera o par de chaves X25519 (Diffie-Hellman) para troca soberana de segredos E2EE.
  static Future<String> obterOuGerarChaveTroca(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return '';

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final registros = await db.query(
      'cofre_chaves_troca',
      columns: ['chave_publica_hex'],
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
      limit: 1,
    );

    if (registros.isNotEmpty) {
      return registros.first['chave_publica_hex']?.toString() ?? '';
    }

    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    final pubHex = _bytesParaHex(publicKey.bytes);
    final privHex = _bytesParaHex(privateKeyBytes);

    await db.insert(
      'cofre_chaves_troca',
      {
        'cpf': cpfLimpo,
        'chave_publica_hex': pubHex,
        'chave_privada_hex': privHex,
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('[CriptografiaService] Par de chaves de troca X25519 gerado para CPF $cpfLimpo');
    return pubHex;
  }

  /// Cifra um texto de ponta a ponta para o destinatário usando X25519 + AES-GCM (256-bit).
  /// Retorna o pacote empacotado com prefixo `e2ee:v1:`.
  static Future<String> cifrarTextoPara({
    required String texto,
    required String meuCpf,
    required String chavePublicaDestinatarioHex,
  }) async {
    if (texto.isEmpty || chavePublicaDestinatarioHex.isEmpty) return texto;

    try {
      final cpfLimpo = meuCpf.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isEmpty) return texto;

      final db = await BancoDadosService.db;
      await _garantirTabela(db);

      // Garante que minha chave de troca existe
      await obterOuGerarChaveTroca(cpfLimpo);

      final registros = await db.query(
        'cofre_chaves_troca',
        columns: ['chave_privada_hex', 'chave_publica_hex'],
        where: 'cpf = ?',
        whereArgs: [cpfLimpo],
        limit: 1,
      );

      if (registros.isEmpty) return texto;

      final minhavPrivHex = registros.first['chave_privada_hex']?.toString() ?? '';
      final minhaPubHex = registros.first['chave_publica_hex']?.toString() ?? '';
      if (minhavPrivHex.isEmpty || minhaPubHex.isEmpty) return texto;

      final meuKeyPair = SimpleKeyPairData(
        _hexParaBytes(minhavPrivHex),
        publicKey: SimplePublicKey(_hexParaBytes(minhaPubHex), type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

      final remotePublicKey = SimplePublicKey(
        _hexParaBytes(chavePublicaDestinatarioHex),
        type: KeyPairType.x25519,
      );

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: meuKeyPair,
        remotePublicKey: remotePublicKey,
      );

      final dadosBytes = utf8.encode(texto);
      final secretBox = await _aesGcm.encrypt(
        dadosBytes,
        secretKey: sharedSecret,
      );

      final concatenado = secretBox.concatenation();
      return '$prefixoE2ee${base64Encode(concatenado)}';
    } catch (e) {
      debugPrint('[CriptografiaService] Erro ao cifrar texto E2EE: $e');
      return texto;
    }
  }

  /// Decifra um texto de ponta a ponta recebido do remetente usando X25519 + AES-GCM (256-bit).
  /// Se o texto não estiver cifrado, retorna o próprio texto (retrocompatibilidade transparente).
  static Future<String> decifrarTextoDe({
    required String textoCifrado,
    required String meuCpf,
    required String chavePublicaRemetenteHex,
  }) async {
    if (!ehTextoCifrado(textoCifrado)) return textoCifrado;
    if (chavePublicaRemetenteHex.isEmpty) return '[Mensagem Cifrada Protegida]';

    try {
      final cpfLimpo = meuCpf.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isEmpty) return '[Mensagem Cifrada Protegida]';

      final db = await BancoDadosService.db;
      await _garantirTabela(db);

      await obterOuGerarChaveTroca(cpfLimpo);

      final registros = await db.query(
        'cofre_chaves_troca',
        columns: ['chave_privada_hex', 'chave_publica_hex'],
        where: 'cpf = ?',
        whereArgs: [cpfLimpo],
        limit: 1,
      );

      if (registros.isEmpty) return '[Mensagem Cifrada Protegida]';

      final minhavPrivHex = registros.first['chave_privada_hex']?.toString() ?? '';
      final minhaPubHex = registros.first['chave_publica_hex']?.toString() ?? '';
      if (minhavPrivHex.isEmpty || minhaPubHex.isEmpty) return '[Mensagem Cifrada Protegida]';

      final meuKeyPair = SimpleKeyPairData(
        _hexParaBytes(minhavPrivHex),
        publicKey: SimplePublicKey(_hexParaBytes(minhaPubHex), type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

      final remotePublicKey = SimplePublicKey(
        _hexParaBytes(chavePublicaRemetenteHex),
        type: KeyPairType.x25519,
      );

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: meuKeyPair,
        remotePublicKey: remotePublicKey,
      );

      final base64Payload = textoCifrado.substring(prefixoE2ee.length);
      final bytesConcatenados = base64Decode(base64Payload);

      final secretBox = SecretBox.fromConcatenation(
        bytesConcatenados,
        nonceLength: _aesGcm.nonceLength,
        macLength: _aesGcm.macAlgorithm.macLength,
      );

      final clearBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: sharedSecret,
      );

      return utf8.decode(clearBytes);
    } catch (e) {
      debugPrint('[CriptografiaService] Falha ao decifrar texto E2EE: $e');
      return '[Mensagem Cifrada Protegida]';
    }
  }

  /// Gera uma chave simétrica de 256 bits exclusiva para cifrar uma mídia/arquivo anexo.
  static Future<SecretKey> gerarChaveSimetricaMidia() async {
    return await _aesGcm.newSecretKey();
  }

  /// Converte uma SecretKey para representação hexadecimal de 32 bytes.
  static Future<String> exportarChaveHex(SecretKey chave) async {
    final bytes = await chave.extractBytes();
    return _bytesParaHex(bytes);
  }

  /// Importa uma chave simétrica de 256 bits a partir de uma string hexadecimal.
  static SecretKey importarChaveHex(String hex) {
    final bytes = _hexParaBytes(hex);
    return SecretKey(bytes);
  }

  /// Cifra os bytes de um arquivo/mídia com AES-GCM (256-bit).
  /// Retorna o pacote concatenado (nonce + ciphertext + mac) pronto para salvar ou transmitir.
  static Future<Uint8List> cifrarBytesComChave(
    Uint8List bytes,
    SecretKey chave,
  ) async {
    final secretBox = await _aesGcm.encrypt(
      bytes,
      secretKey: chave,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Exporta o cofre de chaves assimétricas soberanas (Ed25519 e X25519) cifrado com senha mestre.
  static Future<String> exportarCofreChavesComSenha({
    required String cpf,
    required String senhaMestre,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty || senhaMestre.isEmpty) {
      throw ArgumentError('CPF e senha mestre são obrigatórios para exportação');
    }

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final chavesAssinatura = await db.query(
      'cofre_chaves_seguras',
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
      limit: 1,
    );
    final chavesTroca = await db.query(
      'cofre_chaves_troca',
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
      limit: 1,
    );

    if (chavesAssinatura.isEmpty && chavesTroca.isEmpty) {
      throw StateError('Nenhuma chave encontrada no cofre para este CPF');
    }

    final pacoteClaro = {
      'versao': 1,
      'cpf': cpfLimpo,
      'exportado_em': DateTime.now().toIso8601String(),
      'chaves_seguras': chavesAssinatura.isNotEmpty ? chavesAssinatura.first : null,
      'chaves_troca': chavesTroca.isNotEmpty ? chavesTroca.first : null,
    };

    final jsonBytes = utf8.encode(jsonEncode(pacoteClaro));

    // Deriva chave de 256 bits a partir da senha mestre usando PBKDF2 com HMAC-SHA256
    final salt = List<int>.generate(
      16,
      (i) => (DateTime.now().microsecondsSinceEpoch + i * 37) % 256,
    );
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 20000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: senhaMestre,
      nonce: salt,
    );

    final secretBox = await _aesGcm.encrypt(
      jsonBytes,
      secretKey: secretKey,
    );

    final envelope = {
      'tipo': 'nous_cofre_chaves_v1',
      'cpf': cpfLimpo,
      'salt_hex': _bytesParaHex(salt),
      'nonce_hex': _bytesParaHex(secretBox.nonce),
      'mac_hex': _bytesParaHex(secretBox.mac.bytes),
      'ciphertext_hex': _bytesParaHex(secretBox.cipherText),
    };

    return jsonEncode(envelope);
  }

  /// Importa o cofre de chaves assimétricas soberanas decifrando com a senha mestre.
  static Future<bool> importarCofreChavesComSenha({
    required String payloadCifrado,
    required String senhaMestre,
  }) async {
    try {
      final envelope = jsonDecode(payloadCifrado) as Map<String, dynamic>;
      final salt = _hexParaBytes(envelope['salt_hex'] as String);
      final nonce = _hexParaBytes(envelope['nonce_hex'] as String);
      final mac = _hexParaBytes(envelope['mac_hex'] as String);
      final ciphertext = _hexParaBytes(envelope['ciphertext_hex'] as String);

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 20000,
        bits: 256,
      );
      final secretKey = await pbkdf2.deriveKeyFromPassword(
        password: senhaMestre,
        nonce: salt,
      );

      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(mac),
      );

      final clearBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final pacote = jsonDecode(utf8.decode(clearBytes)) as Map<String, dynamic>;
      final cpf = pacote['cpf']?.toString() ?? '';
      if (cpf.isEmpty) return false;

      final db = await BancoDadosService.db;
      await _garantirTabela(db);

      final chavesSeguras = pacote['chaves_seguras'] as Map<String, dynamic>?;
      if (chavesSeguras != null) {
        await db.insert(
          'cofre_chaves_seguras',
          Map<String, dynamic>.from(chavesSeguras),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final chavesTroca = pacote['chaves_troca'] as Map<String, dynamic>?;
      if (chavesTroca != null) {
        await db.insert(
          'cofre_chaves_troca',
          Map<String, dynamic>.from(chavesTroca),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      debugPrint('[CriptografiaService] Cofre de chaves importado com sucesso para CPF $cpf');
      return true;
    } catch (e) {
      debugPrint('[CriptografiaService] Falha ao importar cofre de chaves (senha incorreta ou dados corrompidos): $e');
      return false;
    }
  }

  /// Decifra os bytes de um arquivo/mídia cifrado com AES-GCM (256-bit).
  /// Retorna os bytes claros originais ou null se a autenticação falhar / corrompido.
  static Future<Uint8List?> decifrarBytesComChave(
    Uint8List bytesCifrados,
    SecretKey chave,
  ) async {
    try {
      final secretBox = SecretBox.fromConcatenation(
        bytesCifrados,
        nonceLength: _aesGcm.nonceLength,
        macLength: _aesGcm.macAlgorithm.macLength,
      );
      final clearBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: chave,
      );
      return Uint8List.fromList(clearBytes);
    } catch (e) {
      debugPrint('[CriptografiaService] Falha ao decifrar bytes de mídia: $e');
      return null;
    }
  }

  static String _bytesParaHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static List<int> _hexParaBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final sub = hex.substring(i, i + 2);
      bytes.add(int.parse(sub, radix: 16));
    }
    return bytes;
  }
}
