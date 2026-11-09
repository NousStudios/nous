import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class NotificacoesProvider extends ChangeNotifier {
  static NotificacoesProvider? _instanciaAtiva;
  static NotificacoesProvider? get instanciaAtiva => _instanciaAtiva;

  String? _cpfAtual;
  List<ConviteLoja> _convites = [];

  final Set<String> _notificacoesDispensadasSessao = {};
  final Map<String, Set<String>> _notificacoesDispensadasPorLoja = {};

  NotificacoesProvider() {
    _instanciaAtiva = this;
  }

  @override
  void dispose() {
    if (_instanciaAtiva == this) {
      _instanciaAtiva = null;
    }
    super.dispose();
  }

  String? get cpfAtual => _cpfAtual;

  List<ConviteLoja> get convites => List.unmodifiable(_convites);

  int get quantidadePendentes => _convites.length;

  int get quantidadeConvitesAtivos => _convites
      .where((c) => !estaDispensadaNaSessao('convite_${c.id}'))
      .length;

  bool get temConvitesPendentes => _convites.isNotEmpty;

  bool estaDispensadaNaSessao(String id) =>
      _notificacoesDispensadasSessao.contains(id);

  bool estaDispensadaNaLoja(String lojaId, String id) {
    if (_notificacoesDispensadasSessao.contains(id)) return true;
    final setLoja = _notificacoesDispensadasPorLoja[lojaId];
    return setLoja != null && setLoja.contains(id);
  }

  Set<String> obterDispensadasPorLoja(String lojaId) {
    return _notificacoesDispensadasPorLoja[lojaId] ?? const <String>{};
  }

  Future<void> carregarDispensadasLoja(String lojaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList('nous_notificacoes_dispensadas_loja_$lojaId');
      if (lista != null && lista.isNotEmpty) {
        _notificacoesDispensadasPorLoja.putIfAbsent(lojaId, () => <String>{}).addAll(lista);
        _notificacoesDispensadasSessao.addAll(lista);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> dispensarNotificacoesLoja(
    String lojaId,
    Iterable<String> ids, {
    bool originadoDaRede = false,
  }) async {
    if (ids.isEmpty) return;
    final setLoja = _notificacoesDispensadasPorLoja.putIfAbsent(
      lojaId,
      () => <String>{},
    );
    setLoja.addAll(ids);
    _notificacoesDispensadasSessao.addAll(ids);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'nous_notificacoes_dispensadas_loja_$lojaId',
        setLoja.toList(),
      );
    } catch (_) {}

    if (!originadoDaRede) {
      final payload = {
        'tipo': 'notificacoes_loja_limpas',
        'lojaId': lojaId,
        'ids': ids.toList(),
      };
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(payload);
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarEventoWs(payload);
      }
    }

    notifyListeners();
  }

  void dispensarNaSessao(String id) {
    _notificacoesDispensadasSessao.add(id);
    notifyListeners();
  }

  void dispensarTodasNaSessao(Iterable<String> ids) {
    _notificacoesDispensadasSessao.addAll(ids);
    notifyListeners();
  }

  void restaurarDispensadasSessao() {
    _notificacoesDispensadasSessao.clear();
    _notificacoesDispensadasPorLoja.clear();
    notifyListeners();
  }

  Future<void> carregarParaCpf(String cpf) async {
    _cpfAtual = cpf;
    _convites = await ConvitesService.carregar(cpf);
    notifyListeners();
  }

  Future<void> recarregarSeuCpf() async {
    if (_cpfAtual != null && _cpfAtual!.isNotEmpty) {
      await carregarParaCpf(_cpfAtual!);
    }
  }

  Future<void> limpar() async {
    _cpfAtual = null;
    _convites = [];
    notifyListeners();
  }

  Future<void> enviarConvite(ConviteLoja convite, {Loja? loja}) async {
    await ConvitesService.adicionar(convite.cpfConvidado, convite, loja: loja);
    if (_cpfAtual != null &&
        _cpfAtual!.replaceAll(RegExp(r'\D'), '') ==
            convite.cpfConvidado.replaceAll(RegExp(r'\D'), '')) {
      await carregarParaCpf(_cpfAtual!);
    }
  }

  Future<void> adicionarNotificacao(ConviteLoja notificacao, {Loja? loja}) async {
    await enviarConvite(notificacao, loja: loja);
  }

  Future<void> aceitar(String conviteId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    await ConvitesService.remover(cpf, conviteId);
    _convites = _convites.where((c) => c.id != conviteId).toList();
    notifyListeners();
  }

  Future<void> recusar(String conviteId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    await ConvitesService.remover(cpf, conviteId);
    _convites = _convites.where((c) => c.id != conviteId).toList();
    notifyListeners();
  }
}