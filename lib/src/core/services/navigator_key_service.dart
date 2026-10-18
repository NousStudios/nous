import 'package:flutter/material.dart';

/// Chave global do navegador para exibição de diálogos e popups
/// acionados por eventos de rede ou serviços sem depender de contexto específico.
class NavigatorKeyService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;
}
