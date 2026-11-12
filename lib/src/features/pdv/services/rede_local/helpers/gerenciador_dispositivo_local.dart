import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';

/// Helper desacoplado para gerenciar nome do terminal móvel e cache do último IP/Porta do balcão.
class GerenciadorDispositivoLocal {
  String _nomeDispositivo = 'Celular';
  bool _nomeCarregado = false;

  String get nomeDispositivo => _nomeDispositivo;
  bool get nomeCarregado => _nomeCarregado;

  Future<String> obterNomeDispositivo() async {
    if (_nomeCarregado) return _nomeDispositivo;
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString('terminal_nome_dispositivo');
      if (salvo != null && salvo.trim().isNotEmpty) {
        _nomeDispositivo = salvo.trim();
      } else {
        _nomeDispositivo = Platform.isAndroid ? 'Celular' : 'Terminal Móvel';
      }
      _nomeCarregado = true;
    } catch (_) {}
    return _nomeDispositivo;
  }

  Future<void> salvarNomeDispositivo(
    String novoNome, {
    WebSocket? ws,
    bool estaConectado = false,
    String? cpfLogado,
  }) async {
    final nomeLimpo = novoNome.trim();
    if (nomeLimpo.isEmpty) return;
    _nomeDispositivo = nomeLimpo;
    _nomeCarregado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('terminal_nome_dispositivo', _nomeDispositivo);
    } catch (_) {}

    if (ws != null && estaConectado) {
      try {
        String? nomeUsuario;
        if (cpfLogado != null && cpfLogado.isNotEmpty) {
          final conta = await ContasNousService.buscarPorCpf(cpfLogado);
          nomeUsuario = conta?.nome;
        }
        ws.add(jsonEncode({
          'tipo': 'identificacao',
          'nomeDispositivo': _nomeDispositivo,
          'cpf': cpfLogado,
          'nomeUsuario': nomeUsuario,
        }));
      } catch (_) {}
    }
  }

  static Future<void> salvarUltimoBalcao(String ip, int porta) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nous_ultimo_ip_balcao', ip);
      await prefs.setInt('nous_ultima_porta_balcao', porta);
    } catch (_) {}
  }

  static Future<({String? ip, int? porta})> obterUltimoBalcao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('nous_ultimo_ip_balcao');
      final porta = prefs.getInt('nous_ultima_porta_balcao');
      return (ip: ip, porta: porta);
    } catch (_) {
      return (ip: null, porta: null);
    }
  }

  static Future<void> salvarServidorExterno(String urlOuDominio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nous_servidor_externo_nuvem', urlOuDominio.trim());
    } catch (_) {}
  }

  static Future<String?> obterServidorExterno() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString('nous_servidor_externo_nuvem');
      return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
    } catch (_) {
      return null;
    }
  }
}
