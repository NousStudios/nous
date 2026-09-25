import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];

  String? _cpfAtual;

  List<Loja> get lojas => List.unmodifiable(_lojas);

  bool get temLojaSalva => _lojas.isNotEmpty;

  Future<void> entrarComCpf(String cpf) async {
    _cpfAtual = cpf;
    final lojasSalvas = await LojasService.carregar(cpf);
    _lojas
      ..clear()
      ..addAll(lojasSalvas);
    notifyListeners();
  }

  void entrarComoVisitante() {
    _cpfAtual = null;
    _lojas.clear();
    notifyListeners();
  }

  void _persistir() {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    LojasService.salvar(cpf, _lojas);
  }

  void salvarLoja({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    required String categorias,
    required String tags,
  }) {
    final novaLoja = Loja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      categorias: categorias,
      tags: tags,
    );

    _lojas.add(novaLoja);
    notifyListeners();
    _persistir();
  }

  Loja? buscarPorId(String id) {
    for (final loja in _lojas) {
      if (loja.id == id) return loja;
    }
    return null;
  }

  void excluirLoja(String id) {
    _lojas.removeWhere((loja) => loja.id == id);
    notifyListeners();
    _persistir();
  }

  Future<void> excluirDadosDoCpf(String cpf) async {
    await LojasService.excluirTodas(cpf);
    if (_cpfAtual == cpf) {
      _cpfAtual = null;
      _lojas.clear();
      notifyListeners();
    }
  }

  void atualizarDadosLoja(
    String id, {
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    required String categorias,
    required String tags,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      categorias: categorias,
      tags: tags,
    );

    notifyListeners();
    _persistir();
  }

  void atualizarListasLoja(
    String id, {
    List<CategoriaLoja>? categorias,
    List<ItemLoja>? itens,
    List<GrupoComponentesLoja>? gruposComponentes,
    List<Cliente>? clientes,
    List<PedidoLoja>? pedidos,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      pedidosLoja: pedidos,
    );

    notifyListeners();
    _persistir();
  }

  void atualizarAcoes(String id, List<RegistroAcao> acoes) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(acoes: acoes);

    notifyListeners();
    _persistir();
  }

  void registrarAcao(String lojaId, RegistroAcao acao) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atuais = _lojas[indice].acoes;
    _lojas[indice] = _lojas[indice].copyWith(
      acoes: [acao, ...atuais],
    );

    notifyListeners();
    _persistir();
  }

  void atualizarConfiguracoesImpressora(
    String id,
    ConfiguracoesImpressora configuracoes,
  ) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    _lojas[indice] = _lojas[indice].copyWith(
      configuracoesImpressora: configuracoes,
    );

    notifyListeners();
    _persistir();
  }

  void garantirDono(String lojaId, {required String cpf, required String nome}) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final loja = _lojas[indice];
    if (loja.membros.isNotEmpty) return;
    if (cpf.isEmpty) return;

    final membro = MembroLoja(
      cpf: cpf,
      nome: nome,
      papel: PapelMembro.dono,
      desde: DateTime.now(),
    );

    _lojas[indice] = loja.copyWith(membros: [membro]);
    notifyListeners();
    _persistir();
  }

  void adicionarMembro(String lojaId, MembroLoja membro) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final loja = _lojas[indice];
    if (loja.membros.any((m) => m.cpf == membro.cpf)) return;

    _lojas[indice] = loja.copyWith(membros: [...loja.membros, membro]);
    notifyListeners();
    _persistir();
  }

  void removerMembro(String lojaId, String cpf) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final loja = _lojas[indice];
    final restantes = loja.membros.where((m) => m.cpf != cpf).toList();
    _lojas[indice] = loja.copyWith(membros: restantes);
    notifyListeners();
    _persistir();
  }

  void atualizarPapelMembro(String lojaId, String cpf, PapelMembro papel) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final loja = _lojas[indice];
    final novos = loja.membros
        .map((m) => m.cpf == cpf ? m.copyWith(papel: papel) : m)
        .toList();
    _lojas[indice] = loja.copyWith(membros: novos);
    notifyListeners();
    _persistir();
  }
}