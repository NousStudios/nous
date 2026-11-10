import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_conversa_info_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('nous_test_prog_');

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

  group('Horário Preservado em Pedidos Programados', () {
    test('calcularDataHoraDoPedido extrai horario programado matutino (08:30)', () {
      final prog = PedidoProgramado(
        id: 'prog_teste_1',
        lojaId: 'loja_1',
        clienteNome: 'Cliente Matutino',
        itens: const [],
        valorTotal: 50.0,
        horario: '08:30',
        dataCriacao: DateTime(2026, 11, 10, 8, 0),
      );

      // Simula sincronização ocorrendo à tarde (15:45)
      final momentoSincronizacao = DateTime(2026, 11, 10, 15, 45, 30);
      final dataPedido = prog.calcularDataHoraDoPedido(momentoSincronizacao);

      expect(dataPedido.year, 2026);
      expect(dataPedido.month, 11);
      expect(dataPedido.day, 10);
      expect(dataPedido.hour, 8);
      expect(dataPedido.minute, 30);

      final pedidoLoja = prog.toPedidoLoja(
        numero: 1,
        dataHora: momentoSincronizacao,
      );
      expect(pedidoLoja.dataHora.hour, 8);
      expect(pedidoLoja.dataHora.minute, 30);
    });

    test('calcularDataHoraDoPedido usa dataCriacao matutina quando horario vazio', () {
      final prog = PedidoProgramado(
        id: 'prog_teste_2',
        lojaId: 'loja_1',
        clienteNome: 'Cliente Sem Hora',
        itens: const [],
        valorTotal: 30.0,
        horario: '',
        dataCriacao: DateTime(2026, 11, 10, 9, 15),
      );

      final momentoSincronizacao = DateTime(2026, 11, 10, 16, 0);
      final dataPedido = prog.calcularDataHoraDoPedido(momentoSincronizacao);

      expect(dataPedido.hour, 9);
      expect(dataPedido.minute, 15);
    });
  });

  group('PdvProvider normalização e busca de loja', () {
    test('buscarPorId encontra loja com ou sem prefixo loja_', () {
      final pdv = PdvProvider();
      final loja = Loja(
        id: 'loja_restaurante_central',
        nome: 'Restaurante Central',
        cnpj: '12345678000199',
        telefone: '11999998888',
        endereco: 'Rua das Flores',
        numero: '123',
        email: 'contato@central.com',
        categorias: 'Restaurante',
        tags: 'lanches',
        cpfDonoOriginal: '11122233344',
      );
      pdv.adicionarOuAtualizarLoja(loja);

      expect(pdv.buscarPorId('loja_restaurante_central')?.nome, 'Restaurante Central');
      expect(pdv.buscarPorId('restaurante_central')?.nome, 'Restaurante Central');
    });
  });

  group('Resolvedor de Metadados de Conversa com Loja', () {
    test('Perspectiva do Cliente: interlocutor é a Loja (nome e logo)', () async {
      final msg = MensagemChat(
        id: 'msg_1',
        conversaId: 'loja_123_usuario_11122233344',
        remetenteId: '123',
        remetenteNome: 'Super Lanches',
        destinatarioId: '11122233344',
        texto: 'Olá, seu pedido está pronto!',
        dataHora: DateTime.now(),
      );

      // Usuário logado é o cliente (11122233344)
      final info = await ResolvedorConversaInfoService.resolverMetadadosParaMensagem(
        msg,
        cpfLogado: '111.222.333-44',
      );

      expect(info.ehLoja, true);
      expect(info.titulo, 'Super Lanches');
      expect(info.subtitulo, 'Loja');
    });

    test('Perspectiva do Lojista: interlocutor é o Cliente', () async {
      final msg = MensagemChat(
        id: 'msg_2',
        conversaId: 'loja_123_usuario_11122233344',
        remetenteId: '11122233344',
        remetenteNome: 'João Silva',
        destinatarioId: '123',
        texto: 'Quero um x-salada por favor',
        dataHora: DateTime.now(),
      );

      // Usuário logado é o lojista/atendente (CPF diferente do cliente)
      final info = await ResolvedorConversaInfoService.resolverMetadadosParaMensagem(
        msg,
        cpfLogado: '99988877766',
      );

      expect(info.ehLoja, false);
      expect(info.identificador, '11122233344');
      expect(info.titulo, 'João Silva');
    });
  });
}
