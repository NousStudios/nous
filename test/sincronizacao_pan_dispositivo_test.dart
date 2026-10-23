import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

void main() {
  group('Sincronização Pan-Dispositivo por CPF', () {
    test('Mesclagem de UsuarioNous preserva dados de ambas as pontas', () {
      const local = UsuarioNous(
        cpf: '12345678900',
        nome: 'João da Silva',
        apelido: 'joaozinho',
        nomeDeUsuario: '',
        dataNascimento: '01/01/1990',
        emails: ['joao@gmail.com'],
        foto: 'caminho/foto/local.jpg',
        nomeMae: 'Maria da Silva',
        nomePai: '',
        localNascimento: 'São Paulo - SP',
        tipoSanguineo: 'O+',
        estadoCivil: 'Solteiro',
      );

      const remoto = UsuarioNous(
        cpf: '12345678900',
        nome: 'João da Silva',
        apelido: 'joao',
        nomeDeUsuario: 'joaonous',
        dataNascimento: '01/01/1990',
        emails: ['joao@trabalho.com'],
        foto: '',
        nomeMae: '',
        nomePai: 'José da Silva',
        localNascimento: '',
        tipoSanguineo: '',
        estadoCivil: '',
      );

      final mesclado = UsuarioNous(
        cpf: local.cpf.isNotEmpty ? local.cpf : remoto.cpf,
        nome: local.nome.isNotEmpty ? local.nome : remoto.nome,
        apelido: local.apelido.isNotEmpty ? local.apelido : remoto.apelido,
        nomeDeUsuario: local.nomeDeUsuario.isNotEmpty
            ? local.nomeDeUsuario
            : remoto.nomeDeUsuario,
        dataNascimento: local.dataNascimento.isNotEmpty
            ? local.dataNascimento
            : remoto.dataNascimento,
        emails: {...local.emails, ...remoto.emails}.toList(),
        foto: local.foto.isNotEmpty ? local.foto : remoto.foto,
        nomePai: local.nomePai.isNotEmpty ? local.nomePai : remoto.nomePai,
        nomeMae: local.nomeMae.isNotEmpty ? local.nomeMae : remoto.nomeMae,
        localNascimento: local.localNascimento.isNotEmpty
            ? local.localNascimento
            : remoto.localNascimento,
        tipoSanguineo: local.tipoSanguineo.isNotEmpty
            ? local.tipoSanguineo
            : remoto.tipoSanguineo,
        estadoCivil: local.estadoCivil.isNotEmpty
            ? local.estadoCivil
            : remoto.estadoCivil,
      );

      expect(mesclado.cpf, equals('12345678900'));
      expect(mesclado.nome, equals('João da Silva'));
      expect(mesclado.nomeDeUsuario, equals('joaonous'));
      expect(mesclado.nomeMae, equals('Maria da Silva'));
      expect(mesclado.nomePai, equals('José da Silva'));
      expect(mesclado.localNascimento, equals('São Paulo - SP'));
      expect(mesclado.tipoSanguineo, equals('O+'));
      expect(mesclado.estadoCivil, equals('Solteiro'));
      expect(mesclado.emails, containsAll(['joao@gmail.com', 'joao@trabalho.com']));
      expect(mesclado.foto, equals('caminho/foto/local.jpg'));
    });

    test('ReferenciaLoja serializa e desserializa perfeitamente', () {
      const ref = ReferenciaLoja(
        lojaId: 'loja_empresa_123',
        cpfDonoOriginal: '98765432100',
      );

      final json = ref.toJson();
      final restaurada = ReferenciaLoja.fromJson(json);

      expect(restaurada.lojaId, equals('loja_empresa_123'));
      expect(restaurada.cpfDonoOriginal, equals('98765432100'));
    });

    test(
        'consolidarLojaComImagensLocais preserva fotos locais quando remota traz caminhos de outra plataforma',
        () {
      // 1. Simula arquivo físico existente localmente
      final tempDir = Directory.systemTemp.createTempSync('nous_test_imgs_');
      final logoLocalFile = File('${tempDir.path}/minha_logo.png')..writeAsStringSync('dummy');
      final catLocalFile = File('${tempDir.path}/minha_cat.png')..writeAsStringSync('dummy');
      final itemLocalFile = File('${tempDir.path}/meu_item.png')..writeAsStringSync('dummy');

      final lojaLocal = Loja(
        id: 'loja_1',
        cpfDonoOriginal: '11111111111',
        nome: 'Loja Local',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: '',
        tags: '',
        logo: logoLocalFile.path,
        categoriasLoja: [
          CategoriaLoja(
            id: 'cat_1',
            nome: 'Bebidas',
            foto: catLocalFile.path,
          ),
        ],
        itensLoja: [
          ItemLoja(
            id: 'item_1',
            nome: 'Suco Natural',
            preco: '10.00',
            imagens: [itemLocalFile.path],
          ),
        ],
      );

      // 2. Loja remota recebida com caminhos do Android que não existem neste dispositivo
      const lojaRemota = Loja(
        id: 'loja_1',
        cpfDonoOriginal: '11111111111',
        nome: 'Loja Local Atualizada',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: '',
        tags: '',
        logo: '/data/user/0/com.example.nous/files/Nous/imagens/remota_99999999.png',
        categoriasLoja: [
          CategoriaLoja(
            id: 'cat_1',
            nome: 'Bebidas Geladas',
            foto: '/data/user/0/com.example.nous/files/Nous/imagens/remota_88888888.png',
          ),
        ],
        itensLoja: [
          ItemLoja(
            id: 'item_1',
            nome: 'Suco Natural de Laranja',
            preco: '12.00',
            imagens: ['/data/user/0/com.example.nous/files/Nous/imagens/remota_77777777.png'],
          ),
        ],
      );

      final consolidada = LojasService.consolidarLojaComImagensLocais(lojaRemota, lojaLocal);

      // Nome e preço foram atualizados
      expect(consolidada.nome, equals('Loja Local Atualizada'));
      expect(consolidada.itensLoja.first.nome, equals('Suco Natural de Laranja'));
      expect(consolidada.itensLoja.first.preco, equals('12.00'));

      // Imagens locais válidas foram 100% preservadas e não foram sobrescritas pelos caminhos do Android
      expect(consolidada.logo, equals(logoLocalFile.path));
      expect(consolidada.categoriasLoja.first.foto, equals(catLocalFile.path));
      expect(consolidada.itensLoja.first.imagens.first, equals(itemLocalFile.path));

      tempDir.deleteSync(recursive: true);
    });

    test('consolidarLojaComImagensLocais mescla mesas e auditoria sem perda', () {
      final lojaLocal = Loja(
        id: 'loja_1',
        cpfDonoOriginal: '11111111111',
        nome: 'Loja Local',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: '',
        tags: '',
        mesas: const [MesaLoja(id: 'm1', numero: '1')],
        acoes: [
          RegistroAcao(
            id: 'a1',
            tipo: TipoAcao.dadosLojaAtualizados,
            nomeAutor: 'Alice',
            cpfAutor: '11111111111',
            emailAutor: 'alice@email.com',
            descricao: 'Criou mesa',
            dataHora: DateTime.now(),
          ),
        ],
      );

      final lojaRemota = Loja(
        id: 'loja_1',
        cpfDonoOriginal: '11111111111',
        nome: 'Loja Local',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: '',
        tags: '',
        mesas: const [MesaLoja(id: 'm2', numero: '2')],
        acoes: [
          RegistroAcao(
            id: 'a2',
            tipo: TipoAcao.dadosLojaAtualizados,
            nomeAutor: 'Bob',
            cpfAutor: '22222222222',
            emailAutor: 'bob@email.com',
            descricao: 'Atualizou item',
            dataHora: DateTime.now(),
          ),
        ],
      );

      final consolidada = LojasService.consolidarLojaComImagensLocais(lojaRemota, lojaLocal);

      expect(consolidada.mesas.length, equals(2));
      expect(consolidada.mesas.map((m) => m.id), containsAll(['m1', 'm2']));
      expect(consolidada.acoes.length, equals(2));
      expect(consolidada.acoes.map((a) => a.id), containsAll(['a1', 'a2']));
    });

    test('UsuarioNous separa Identidade civil de Perfil Social público', () {
      const usuario = UsuarioNous(
        cpf: '12345678900',
        nome: 'Carlos Eduardo Souza',
        apelido: 'cadu',
        dataNascimento: '15/05/1992',
        foto: 'caminho/identidade.jpg',
        biografia: 'Bio padrão',
        nomePublico: 'Dudu Souza',
        apelidoPublico: 'duduzin',
        fotoPublica: 'caminho/publico.jpg',
      );

      // Getters retornam dados customizados do perfil público
      expect(usuario.nomeExibicao, equals('Dudu Souza'));
      expect(usuario.apelidoExibicao, equals('duduzin'));
      expect(usuario.fotoExibicao, equals('caminho/publico.jpg'));

      // Dados de Identidade do Usuário permanecem intactos
      expect(usuario.nome, equals('Carlos Eduardo Souza'));
      expect(usuario.apelido, equals('cadu'));
      expect(usuario.foto, equals('caminho/identidade.jpg'));

      // Serialização JSON preserva ambos
      final json = usuario.toJson();
      final reconstruido = UsuarioNous.fromJson(json);

      expect(reconstruido.nome, equals('Carlos Eduardo Souza'));
      expect(reconstruido.nomePublico, equals('Dudu Souza'));
      expect(reconstruido.apelido, equals('cadu'));
      expect(reconstruido.apelidoPublico, equals('duduzin'));
      expect(reconstruido.foto, equals('caminho/identidade.jpg'));
      expect(reconstruido.fotoPublica, equals('caminho/publico.jpg'));

      // Fallback quando campos públicos estão vazios
      final usuarioSemPublico = usuario.copyWith(
        nomePublico: '',
        apelidoPublico: '',
        fotoPublica: '',
      );
      expect(usuarioSemPublico.nomeExibicao, equals('Carlos Eduardo Souza'));
      expect(usuarioSemPublico.apelidoExibicao, equals('cadu'));
      expect(usuarioSemPublico.fotoExibicao, equals('caminho/identidade.jpg'));
    });
  });
}
