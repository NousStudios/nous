import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';

class LojasService {
  LojasService._();

  static String _chave(String cpf) => 'nous_lojas_$cpf';

  static String _chaveReferencias(String cpf) => 'nous_referencias_$cpf';

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

  static Future<void> excluirTodas(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave(cpf));
  }

  static Future<List<ReferenciaLoja>> carregarReferencias(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveReferencias(cpf));
    if (texto == null || texto.isEmpty) return [];

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) =>
            ReferenciaLoja.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> salvarReferencias(
    String cpf,
    List<ReferenciaLoja> referencias,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final texto =
        jsonEncode(referencias.map((r) => r.toJson()).toList());
    await prefs.setString(_chaveReferencias(cpf), texto);
  }

  static Future<void> adicionarReferencia(
    String cpf,
    ReferenciaLoja referencia,
  ) async {
    final atuais = await carregarReferencias(cpf);
    final jaTem = atuais.any((r) => r.lojaId == referencia.lojaId);
    if (jaTem) return;
    await salvarReferencias(cpf, [...atuais, referencia]);
  }

  static Future<void> removerReferencia(String cpf, String lojaId) async {
    final atuais = await carregarReferencias(cpf);
    final restantes = atuais.where((r) => r.lojaId != lojaId).toList();
    await salvarReferencias(cpf, restantes);
  }
}