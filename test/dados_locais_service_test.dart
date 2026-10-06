import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
