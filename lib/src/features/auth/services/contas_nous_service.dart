import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

class ContasNousService {
  ContasNousService._();

  static const String _chave = 'nous_contas_cpf';

  static Future<List<UsuarioNous>> _carregarTodas() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null || texto.isEmpty) return [];

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) => UsuarioNous.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _salvarTodas(List<UsuarioNous> contas) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(contas.map((c) => c.toJson()).toList());
    await prefs.setString(_chave, texto);
  }

  static Future<UsuarioNous?> buscarPorCpf(String cpf) async {
    final contas = await _carregarTodas();
    for (final conta in contas) {
      if (conta.cpf == cpf) return conta;
    }
    return null;
  }

  static Future<String?> buscarCpfDoEmail(String email) async {
    final contas = await _carregarTodas();
    for (final conta in contas) {
      if (conta.emails.contains(email)) return conta.cpf;
    }
    return null;
  }

  static Future<void> salvar(UsuarioNous conta) async {
    final contas = await _carregarTodas();
    final indice = contas.indexWhere((c) => c.cpf == conta.cpf);
    if (indice == -1) {
      contas.add(conta);
    } else {
      contas[indice] = conta;
    }
    await _salvarTodas(contas);
  }

  static Future<void> excluir(String cpf) async {
    final contas = await _carregarTodas();
    contas.removeWhere((c) => c.cpf == cpf);
    await _salvarTodas(contas);
  }
}