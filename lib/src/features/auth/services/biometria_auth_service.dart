import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/contas_usuario_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Serviço de autenticação biométrica para celulares (Android/iOS).
/// Associa a biometria utilizada no aparelho a um CPF no `PreferenciasSoberanasService`
/// e executa login automático ao abrir o aplicativo.
class BiometriaAuthService {
  BiometriaAuthService._();

  static const String _chaveCpfVinculado = 'biometria_cpf_vinculado';
  static const String _chaveTipoBiometria = 'biometria_tipo_vinculado';
  static const String _chaveVinculadaEm = 'biometria_vinculada_em';

  static final LocalAuthentication _auth = LocalAuthentication();

  static bool get ehCelular => Platform.isAndroid || Platform.isIOS;

  static String _normalizarCpf(String cpf) =>
      cpf.replaceAll(RegExp(r'\D'), '');

  /// Verifica se o aparelho é celular e possui qualquer credencial nativa ativa
  /// (biometria, PIN, padrão ou senha do aparelho).
  static Future<bool> suportaCredencialNativa() async {
    if (!ehCelular) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o aparelho é celular e possui biometria ativa configurada.
  static Future<bool> suportaBiometria() async {
    if (!ehCelular) return false;
    try {
      final suportado = await _auth.isDeviceSupported();
      final podeChecar = await _auth.canCheckBiometrics;
      if (!suportado || !podeChecar) return false;
      final disponiveis = await _auth.getAvailableBiometrics();
      return disponiveis.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retorna o CPF (11 dígitos) vinculado à biometria neste celular, se houver.
  static Future<String?> obterCpfVinculado() async {
    if (!ehCelular) return null;
    final cpf = await PreferenciasSoberanasService.obterTexto(
      _chaveCpfVinculado,
    );
    if (cpf == null) return null;
    final limpo = _normalizarCpf(cpf);
    return limpo.length == 11 ? limpo : null;
  }

  /// Retorna o identificador da biometria salva (ex.: `fingerprint`, `face`, `strong`).
  static Future<String?> obterTipoBiometriaSalva() async {
    if (!ehCelular) return null;
    return PreferenciasSoberanasService.obterTexto(_chaveTipoBiometria);
  }

  static Future<String> _detectarTipoBiometriaPrincipal() async {
    try {
      final lista = await _auth.getAvailableBiometrics();
      if (lista.contains(BiometricType.fingerprint)) return 'fingerprint';
      if (lista.contains(BiometricType.face)) return 'face';
      if (lista.contains(BiometricType.iris)) return 'iris';
      if (lista.contains(BiometricType.strong)) return 'strong';
      if (lista.contains(BiometricType.weak)) return 'weak';
    } catch (_) {}
    return 'biometric';
  }

  /// Solicita a autenticação no aparelho (biometria ou senha/PIN direto na mesma janela).
  static Future<bool> autenticar({
    String motivo = 'Confirme sua biometria para acessar o Nous',
  }) async {
    if (!await suportaCredencialNativa()) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticação do aparelho',
            biometricHint: 'Toque no sensor de digital ou use a senha',
            biometricNotRecognized: 'Biometria não reconhecida. Tente novamente.',
            biometricRequiredTitle: 'Autenticação necessária',
            biometricSuccess: 'Autenticação confirmada',
            cancelButton: 'Voltar',
            deviceCredentialsRequiredTitle: 'Credencial do aparelho obrigatória',
            deviceCredentialsSetupDescription:
                'Configure a biometria ou senha de bloqueio nas configurações do aparelho.',
            goToSettingsButton: 'Configurações',
            goToSettingsDescription:
                'A biometria não está configurada neste aparelho. Acesse as configurações para ativá-la.',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Associa e salva a credencial utilizada no aparelho com o CPF informado.
  /// Caso já esteja vinculada exatamente a esse CPF, apenas atualiza o tipo.
  static Future<bool> vincularCpfComBiometria(
    String cpf, {
    bool jaAutenticado = false,
  }) async {
    final cpfLimpo = _normalizarCpf(cpf);
    if (cpfLimpo.length != 11 || !await suportaCredencialNativa()) return false;

    final cpfAtual = await obterCpfVinculado();
    if (cpfAtual == cpfLimpo) {
      final tipo = await _detectarTipoBiometriaPrincipal();
      await PreferenciasSoberanasService.salvarTexto(_chaveTipoBiometria, tipo);
      return true;
    }

    if (!jaAutenticado) {
      final ok = await autenticar(
        motivo: 'Use sua biometria ou senha para ativar o login automático neste CPF',
      );
      if (!ok) return false;
    }

    final tipo = await _detectarTipoBiometriaPrincipal();
    await PreferenciasSoberanasService.salvarTexto(_chaveCpfVinculado, cpfLimpo);
    await PreferenciasSoberanasService.salvarTexto(_chaveTipoBiometria, tipo);
    await PreferenciasSoberanasService.salvarTexto(
      _chaveVinculadaEm,
      DateTime.now().toIso8601String(),
    );
    return true;
  }

  /// Tenta autenticar via biometria no celular e entrar automaticamente na conta
  /// do CPF vinculado. Retorna `true` se o login foi concluído.
  static Future<bool> tentarLoginAutomatico(BuildContext context) async {
    if (!ehCelular) return false;
    final cpfVinculado = await obterCpfVinculado();
    if (cpfVinculado == null) return false;
    if (!await suportaCredencialNativa()) return false;

    final autenticado = await autenticar(
      motivo: 'Use sua biometria para entrar no Nous',
    );
    if (!autenticado || !context.mounted) return false;

    final authProvider = context.read<AuthProvider>();
    final notificacoesProvider = context.read<NotificacoesProvider>();
    final pdvProvider = context.read<PdvProvider>();

    authProvider.updateCpf(cpfVinculado);
    final contaEncontrada = await authProvider.buscarConta();
    if (!contaEncontrada || !context.mounted) return false;

    await authProvider.salvarUltimoCpf(cpfVinculado);
    await notificacoesProvider.carregarParaCpf(cpfVinculado);
    await pdvProvider.entrarComCpf(cpfVinculado);

    if (!context.mounted) return false;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ContasUsuarioView(),
      ),
      (route) => false,
    );
    return true;
  }
}
