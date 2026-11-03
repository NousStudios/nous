import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço soberano para sincronização de relógio da rede local (Uníssono).
/// 
/// Permite que todos os dispositivos conectados à mesma rede local Nous (Servidor Balcão
/// e Terminais Móveis) operem com o mesmo referencial temporal estrito em milissegundos,
/// prevenindo inversão de mensagens no chat, divergência de timestamps e perdas
/// por ordenação monotônica incorreta.
class RelogioRedeService extends ChangeNotifier {
  RelogioRedeService._() {
    _carregarConfiguracao();
  }

  static final RelogioRedeService instancia = RelogioRedeService._();

  static const String _chavePrefHabilitado = 'nous_relogio_rede_habilitado';
  static const String _chavePrefOffsetMs = 'nous_relogio_rede_offset_ms';

  bool _habilitado = true;
  bool _sincronizado = false;
  Duration _diferencaRelogio = Duration.zero;
  int _latenciaMs = 0;
  DateTime? _ultimoAjuste;
  String? _servidorReferencia;

  bool get habilitado => _habilitado;
  bool get estaSincronizado => _sincronizado;
  Duration get diferencaRelogio => _diferencaRelogio;
  int get latenciaMs => _latenciaMs;
  DateTime? get ultimoAjuste => _ultimoAjuste;
  String? get servidorReferencia => _servidorReferencia;

  /// Retorna a data e hora atual sincronizada com a rede local.
  /// Se a sincronização estiver ativa e calibrada, aplica a compensação de milissegundos.
  static DateTime agora() {
    return instancia.obterAgora();
  }

  DateTime obterAgora() {
    final agoraLocal = DateTime.now();
    if (!_habilitado || !_sincronizado) {
      return agoraLocal;
    }
    return agoraLocal.add(_diferencaRelogio);
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _habilitado = prefs.getBool(_chavePrefHabilitado) ?? true;
      final offsetMsSalvo = prefs.getInt(_chavePrefOffsetMs);
      if (offsetMsSalvo != null && offsetMsSalvo != 0) {
        _diferencaRelogio = Duration(milliseconds: offsetMsSalvo);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> alternarHabilitado(bool valor) async {
    _habilitado = valor;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chavePrefHabilitado, valor);
    } catch (_) {}
  }

  /// Define o relógio como mestre (usado pelo nó hospedeiro ServidorRedeLocal)
  void definirComoServidorMestre() {
    _diferencaRelogio = Duration.zero;
    _sincronizado = true;
    _latenciaMs = 0;
    _ultimoAjuste = DateTime.now();
    _servidorReferencia = 'Host Local (Mestre de Tempo)';
    notifyListeners();
  }

  /// Sincroniza o relógio deste terminal móvel com o balcão usando o Algoritmo de Cristian.
  Future<bool> sincronizarComServidor({
    required String ip,
    required int porta,
  }) async {
    if (!_habilitado) return false;

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 3);

      int melhorRtt = 999999;
      int melhorOffset = 0;
      bool obteveAoMenosUma = false;

      // Executa até 3 medições rápidas para descartar jitter de rede Wi-Fi e selecionar a de menor RTT
      for (int i = 0; i < 3; i++) {
        try {
          final t0 = DateTime.now().millisecondsSinceEpoch;
          final uri = Uri.http('$ip:$porta', '/api/relogio');
          final req = await client.getUrl(uri);
          final resp = await req.close();

          if (resp.statusCode == HttpStatus.ok) {
            final t1 = DateTime.now().millisecondsSinceEpoch;
            final rtt = t1 - t0;

            final body = await utf8.decodeStream(resp);
            final dados = jsonDecode(body) as Map<String, dynamic>;
            final servidorTimestampMs = dados['timestampMs'] as int?;

            if (servidorTimestampMs != null) {
              obteveAoMenosUma = true;
              // Algoritmo de Cristian: tempo no servidor estimado no instante t1 = servidorTimestamp + (rtt / 2)
              final tempoEstimadoServidor = servidorTimestampMs + (rtt ~/ 2);
              final offset = tempoEstimadoServidor - t1;

              if (rtt < melhorRtt) {
                melhorRtt = rtt;
                melhorOffset = offset;
              }
            }
          }
        } catch (_) {}
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 60));
        }
      }

      if (obteveAoMenosUma) {
        _diferencaRelogio = Duration(milliseconds: melhorOffset);
        _latenciaMs = melhorRtt;
        _sincronizado = true;
        _ultimoAjuste = DateTime.now();
        _servidorReferencia = '$ip:$porta';

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_chavePrefOffsetMs, melhorOffset);
        } catch (_) {}

        notifyListeners();
        debugPrint(
          '[RelogioRedeService] Relógio sincronizado com $ip:$porta. Offset: ${melhorOffset}ms (RTT: ${melhorRtt}ms)',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[RelogioRedeService] Erro ao sincronizar relógio com balcão: $e');
    } finally {
      client?.close(force: true);
    }
    return false;
  }

  /// Limpa a calibragem temporária ao desconectar
  void desmarcarSincronizado() {
    _sincronizado = false;
    notifyListeners();
  }
}
