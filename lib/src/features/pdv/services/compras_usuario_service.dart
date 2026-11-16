import 'dart:convert';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class CarrinhoPendenteLoja {
  final String lojaId;
  final Loja? loja;
  final List<ItemVendido> itens;

  const CarrinhoPendenteLoja({
    required this.lojaId,
    required this.loja,
    required this.itens,
  });

  double get total => itens.fold(0.0, (s, i) => s + i.subtotal);
  int get quantidadeTotal => itens.fold(0, (s, i) => s + i.quantidade);
}

class RegistroCompraUsuario {
  final String lojaId;
  final String nomeLoja;
  final PedidoLoja pedido;

  const RegistroCompraUsuario({
    required this.lojaId,
    required this.nomeLoja,
    required this.pedido,
  });
}

class ComprasUsuarioService {
  ComprasUsuarioService._();

  static const String prefixoCarrinho = 'vitrine_carrinho_pendente_';

  static Future<void> salvarCarrinhoPendente(
    String lojaId,
    List<ItemVendido> itens,
  ) async {
    final chave = '$prefixoCarrinho$lojaId';
    if (itens.isEmpty) {
      await PreferenciasSoberanasService.salvarTexto(chave, '');
      return;
    }
    await PreferenciasSoberanasService.salvarTexto(
      chave,
      jsonEncode(itens.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<CarrinhoPendenteLoja>> carregarCarrinhosPendentes(
    PdvProvider pdv,
  ) async {
    final resultado = <CarrinhoPendenteLoja>[];
    try {
      final db = await BancoDadosService.db;
      final rows = await db.query(
        'preferencias_usuario',
        columns: ['chave', 'valor'],
        where: 'chave LIKE ?',
        whereArgs: ['$prefixoCarrinho%'],
      );
      for (final row in rows) {
        final chave = row['chave']?.toString() ?? '';
        final raw = row['valor']?.toString() ?? '';
        if (!chave.startsWith(prefixoCarrinho) || raw.trim().isEmpty) continue;
        final lojaId = chave.substring(prefixoCarrinho.length);
        final decoded = jsonDecode(raw);
        if (decoded is! List || decoded.isEmpty) continue;
        final itens = decoded
            .whereType<Map>()
            .map((m) => ItemVendido.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        if (itens.isEmpty) continue;

        final loja = pdv.buscarPorId(lojaId) ??
            await LojasService.carregarLojaPorId(lojaId);
        resultado.add(
          CarrinhoPendenteLoja(
            lojaId: lojaId,
            loja: loja,
            itens: itens,
          ),
        );
      }
    } catch (_) {}
    return resultado;
  }

  static Future<List<RegistroCompraUsuario>> carregarHistoricoCompras({
    required String cpfUsuario,
    required PdvProvider pdv,
  }) async {
    final cpfLimpo = cpfUsuario.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return [];

    final mapaPorPedidoId = <String, RegistroCompraUsuario>{};

    // 1. Pedidos nas lojas sincronizadas onde o cliente possui este CPF
    for (final loja in pdv.lojas) {
      if (loja.id == PdvProvider.idLojaColetivaNous) continue;
      final idsClientesUsuario = loja.clientesLoja
          .where((c) => c.cnpj.replaceAll(RegExp(r'\D'), '') == cpfLimpo)
          .map((c) => c.id)
          .toSet();
      if (idsClientesUsuario.isEmpty) continue;

      for (final p in loja.pedidosLoja) {
        if (idsClientesUsuario.contains(p.clienteId)) {
          mapaPorPedidoId[p.id] = RegistroCompraUsuario(
            lojaId: loja.id,
            nomeLoja: loja.nome,
            pedido: p,
          );
        }
      }
    }

    // 2. Comandas enviadas pelo usuário nos chats com lojas
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query(
        'mensagens_chat',
        where: "tipo = 'comanda' AND dados_pedido_json IS NOT NULL AND dados_pedido_json != ''",
        orderBy: 'data_hora DESC',
        limit: 100,
      );
      for (final r in rows) {
        final remNorm = (r['remetente_id']?.toString() ?? '')
            .replaceAll(RegExp(r'\D'), '');
        final convId = r['conversa_id']?.toString() ?? '';
        final pertenceAoUsuario =
            remNorm == cpfLimpo || convId.endsWith('_usuario_$cpfLimpo');
        if (!pertenceAoUsuario) continue;

        final jsonStr = r['dados_pedido_json']?.toString() ?? '';
        if (jsonStr.isEmpty) continue;
        final map = jsonDecode(jsonStr);
        if (map is! Map<String, dynamic>) continue;
        final pedidoChat = PedidoLoja.fromJson(map);
        final lid = pedidoChat.lojaId;
        final loja = lid.isNotEmpty
            ? (pdv.buscarPorId(lid) ?? await LojasService.carregarLojaPorId(lid))
            : null;

        mapaPorPedidoId.putIfAbsent(
          pedidoChat.id,
          () => RegistroCompraUsuario(
            lojaId: lid,
            nomeLoja: pedidoChat.nomeVendedor.isNotEmpty
                ? pedidoChat.nomeVendedor
                : (loja?.nome ?? 'Loja Nous'),
            pedido: pedidoChat,
          ),
        );
      }
    } catch (_) {}

    final lista = mapaPorPedidoId.values.toList()
      ..sort((a, b) => b.pedido.dataHora.compareTo(a.pedido.dataHora));
    return lista;
  }
}
