import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('nous_dados_locais_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
    BancoDadosService.resetDbInstanciaParaTestes();
  });

  tearDownAll(() async {
    try {
      final db = await BancoDadosService.db;
      await db.close();
    } catch (_) {}
    BancoDadosService.resetDbInstanciaParaTestes();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('Autopreenchimento recupera dados unificados de conta e cadastros locais',
      () async {
    final contasJson = '''
[
  {
    "cpf": "47192956813",
    "nome": "Leonardo Tadeu Dalosa",
    "dataNascimento": "24/03/1998",
    "emails": ["leonardotadeudalosa@gmail.com"],
    "foto": "C:\\\\Users\\\\Leona\\\\AppData\\\\Roaming/Nous/imagens/img_1791237728099.jpg",
    "nomePai": "Ademir Dalosa",
    "nomeMae": "Rosa Aparecida Dalosa",
    "localNascimento": "Osasco-SP",
    "tipoSanguineo": "A",
    "estadoCivil": "Casado"
  }
]
''';

    final lojasJson = '''
[
  {
    "id": "1",
    "cpfDonoOriginal": "47192956813",
    "nome": "Laricas",
    "cnpj": "40.922.918/0001-02",
    "telefone": "(17) 98195-7287",
    "endereco": "Nuno Álvares Pereira",
    "numero": "1182",
    "email": "laricasculinaria@gmail.com",
    "redesSociais": "",
    "categorias": "",
    "tags": "",
    "logo": "",
    "clientesLoja": [
      {
        "id": "10",
        "nome": "Leonardo Tadeu Dalosa",
        "cnpj": "",
        "telefone": "(17) 99106-4762",
        "endereco": "Duarte Pacheco",
        "numero": "340",
        "email": "leonardotadeudalosa@gmail.com",
        "redesSociais": "@taddeoleonardo",
        "descricao": "anarquismo plataformista",
        "foto": ""
      }
    ],
    "fornecedoresLoja": []
  }
]
''';

    SharedPreferences.setMockInitialValues({
      'nous_contas_cpf': contasJson,
      'nous_lojas_47192956813': lojasJson,
    });

    final contaObj = UsuarioNous.fromJson(jsonDecode(contasJson)[0] as Map<String, dynamic>);
    await ContasNousService.salvar(contaObj);

    final lojaObj = Loja.fromJson(jsonDecode(lojasJson)[0] as Map<String, dynamic>);
    await LojasService.salvar('47192956813', [lojaObj]);

    final resultado =
        await DadosLocaisService.buscarPorDocumento('47192956813');

    expect(resultado, isNotNull);
    expect(resultado!.nome, equals('Leonardo Tadeu Dalosa'));
    expect(resultado.email, equals('leonardotadeudalosa@gmail.com'));
    expect(resultado.telefone, equals('(17) 99106-4762'));
    expect(resultado.endereco, equals('Duarte Pacheco'));
    expect(resultado.numero, equals('340'));
    expect(resultado.redesSociais, equals('@taddeoleonardo'));
    expect(resultado.descricao, equals('anarquismo plataformista'));
  });

  test('Busca por CPF (11 dígitos) não contamina foto do usuário com a logo da loja', () async {
    const cpfDono = '12345678901';
    final lojaComLogo = Loja(
      id: 'loja_teste_logo',
      cpfDonoOriginal: cpfDono,
      nome: 'Loja com Logo',
      cnpj: '11.222.333/0001-44',
      telefone: '11999999999',
      endereco: 'Rua Teste',
      numero: '100',
      email: 'loja@teste.com',
      categorias: 'Geral',
      tags: 'teste',
      logo: '/caminhos/logo_da_loja.png',
    );
    await LojasService.salvar(cpfDono, [lojaComLogo]);

    final resultado = await DadosLocaisService.buscarPorDocumento(cpfDono);
    expect(resultado, isNotNull);
    // Foto deve permanecer vazia, sem herdar a logo da loja quando o documento é CPF
    expect(resultado!.foto, isEmpty);

    // Já a busca pelo CNPJ da loja herda a logo normalmente
    final resultadoCnpj = await DadosLocaisService.buscarPorDocumento('11.222.333/0001-44');
    expect(resultadoCnpj, isNotNull);
    expect(resultadoCnpj!.foto, equals('/caminhos/logo_da_loja.png'));
  });
}

