import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

class LojasService {
  LojasService._();

  static String _chave(String cpf) => 'nous_lojas_$cpf';

  static Future<List<Loja>> carregar(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave(cpf));
    if (texto == null || texto.isEmpty) return [];

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) => Loja.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> salvar(String cpf, List<Loja> lojas) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(lojas.map((l) => l.toJson()).toList());
    await prefs.setString(_chave(cpf), texto);
  }
}