import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';

class ConvitesService {
  ConvitesService._();

  static String _chave(String cpf) => 'nous_convites_$cpf';

  static Future<List<ConviteLoja>> carregar(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave(cpf));
    if (texto == null || texto.isEmpty) return [];

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) => ConviteLoja.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> salvar(String cpf, List<ConviteLoja> convites) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(convites.map((c) => c.toJson()).toList());
    await prefs.setString(_chave(cpf), texto);
  }

  static Future<void> adicionar(String cpf, ConviteLoja convite) async {
    final atuais = await carregar(cpf);
    await salvar(cpf, [...atuais, convite]);
  }

  static Future<void> remover(String cpf, String conviteId) async {
    final atuais = await carregar(cpf);
    final restantes = atuais.where((c) => c.id != conviteId).toList();
    await salvar(cpf, restantes);
  }
}