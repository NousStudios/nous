import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic> _decodificarMapaJsonIsolate(String s) {
  return jsonDecode(s) as Map<String, dynamic>;
}

List<dynamic> _decodificarListaJsonIsolate(String s) {
  return jsonDecode(s) as List<dynamic>;
}

/// Decodifica JSON de forma segura sem travar a UI Thread caso o payload seja grande (>20KB).
Future<Map<String, dynamic>> decodificarJsonMapaSeguro(String texto) async {
  if (texto.length > 20000) {
    try {
      return await compute(_decodificarMapaJsonIsolate, texto);
    } catch (_) {
      return jsonDecode(texto) as Map<String, dynamic>;
    }
  }
  return jsonDecode(texto) as Map<String, dynamic>;
}

/// Decodifica lista JSON de forma segura em Isolate para payloads grandes.
Future<List<dynamic>> decodificarJsonListaSegura(String texto) async {
  if (texto.length > 20000) {
    try {
      return await compute(_decodificarListaJsonIsolate, texto);
    } catch (_) {
      return jsonDecode(texto) as List<dynamic>;
    }
  }
  return jsonDecode(texto) as List<dynamic>;
}
