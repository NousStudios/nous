import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];
  String? _cpfAtual;

  List<Loja> get lojas => List.unmodifiable(_lojas);

  bool get temLojaSalva => _lojas.isNotEmpty;

  List<Loja> get lojasQueAdministro {
    final cpf = _cpfAtual;
    if (cpf == null) return [];
    return _lojas.where((l) {
      return l.membros.any((m) =>
          m.cpf == cpf &&
          (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio));
    }).toList();
  }

  List<Loja> get lojasQueParticipo {
    final cpf = _cpfAtual;
    if (cpf == null) return [];
    return _lojas.where((l) {
      return l.membros.any((m) =>
          m.cpf == cpf &&
          (m.papel == PapelMembro.admin ||
              m.papel == PapelMembro.funcionario));
    }).toList();
  }

  PapelMembro? meuPapel(String lojaId) {
    final cpf = _cpfAtual;
    if (cpf == null) return null;
    final loja = buscarPorId(lojaId);
    if (loja == null) return null;
    for (final m in loja.membros) {
      if (m.cpf == cpf) return m.papel;
    }
    return null;
  }

  bool possoEditarAbaLoja(String lojaId) {
    final p = meuPapel(lojaId);
    return p != null && p != PapelMembro.funcionario;
  }

  bool possoUsarImpressora(String lojaId) {
    final p = meuPapel(lojaId);
    return p != null && p != PapelMembro.funcionario;
  }

  bool possoEditarDadosLoja(String lojaId) {
    final p = meuPapel(lojaId);
    return p == PapelMembro.dono || p == PapelMembro.socio;
  }

  bool possoUsarFinanceiro(String lojaId) {
    final p = meuPapel(lojaId);
    return p == PapelMembro.dono || p == PapelMembro.socio;
  }

  bool possoGerenciarMembros(String lojaId) {
    final p = meuPapel(lojaId);
    return p == PapelMembro.dono || p == PapelMembro.socio;
  }

  bool possoExcluirLoja(String lojaId) {
    final p = meuPapel(lojaId);
    return p == PapelMembro.dono || p == PapelMembro.socio;
  }

  Future<void> entrarComCpf(String cpf) async {
    _cpfAtual = cpf;

    final minhasLojasBrutas = await LojasService.carregar(cpf);
    final minhasLojas = minhasLojasBrutas
        .map((l) => l.cpfDonoOriginal.isEmpty
            ? l.copyWith(cpfDonoOriginal: cpf)
            : l)
        .toList();
    await LojasService.salvar(cpf, minhasLojas);

    final referencias = await LojasService.carregarReferencias(cpf);
    final lojasReferenciadas = <Loja>[];
    final referenciasOrfas = <ReferenciaLoja>[];

    for (final ref in referencias) {
      final cofre = await LojasService.carregar(ref.cpfDonoOriginal);
      Loja? encontrada;
      for (final l in cofre) {
        if (l.id == ref.lojaId) {
          encontrada = l;
          break;
        }
      }
      if (encontrada == null ||
          !encontrada.membros.any((m) => m.cpf == cpf)) {
        referenciasOrfas.add(ref);
        continue;
      }
      lojasReferenciadas.add(encontrada);
    }

    for (final ref in referenciasOrfas) {
      await LojasService.removerReferencia(cpf, ref.lojaId);
    }

    _lojas
      ..clear()
      ..addAll(minhasLojas)
      ..addAll(lojasReferenciadas);

    notifyListeners();
  }

  void entrarComoVisitante() {
    _cpfAtual = null;
    _lojas.clear();
    notifyListeners();
  }

  Future<void> _salvarLojaNoCofreCorreto(Loja loja) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    final dono =
        loja.cpfDonoOriginal.isEmpty ? cpf : loja.cpfDonoOriginal;

    final cofre = await LojasService.carregar(dono);
    final indice = cofre.indexWhere((l) => l.id == loja.id);
    if (indice == -1) {
      cofre.add(loja);
    } else {
      cofre[indice] = loja;
    }
    await LojasService.salvar(dono, cofre);
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
    final cpf = _cpfAtual;
    final novaLoja = Loja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfDonoOriginal: cpf ?? '',
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
    _salvarLojaNoCofreCorreto(novaLoja);
  }

  Loja? buscarPorId(String id) {
    for (final loja in _lojas) {
      if (loja.id == id) return loja;
    }
    return null;
  }

  Future<void> excluirLoja(String id) async {
    final loja = buscarPorId(id);
    _lojas.removeWhere((l) => l.id == id);
    notifyListeners();

    if (loja == null) return;

    final dono = loja.cpfDonoOriginal.isEmpty
        ? (_cpfAtual ?? '')
        : loja.cpfDonoOriginal;
    if (dono.isEmpty) return;

    final cofre = await LojasService.carregar(dono);
    await LojasService.salvar(
      dono,
      cofre.where((l) => l.id != id).toList(),
    );

    for (final membro in loja.membros) {
      await LojasService.removerReferencia(membro.cpf, id);
    }
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

    final atualizada = _lojas[indice].copyWith(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      categorias: categorias,
      tags: tags,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
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

    final atualizada = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      pedidosLoja: pedidos,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarAcoes(String id, List<RegistroAcao> acoes) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(acoes: acoes);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void registrarAcao(String lojaId, RegistroAcao acao) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].acoes;
    final atualizada = _lojas[indice].copyWith(acoes: [acao, ...atual]);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarConfiguracoesImpressora(
    String id,
    ConfiguracoesImpressora configuracoes,
  ) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada =
        _lojas[indice].copyWith(configuracoesImpressora: configuracoes);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void garantirDono(
    String lojaId, {
    required String cpf,
    required String nome,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    final precisaDefinirDonoOriginal = loja.cpfDonoOriginal.isEmpty;
    final precisaAdicionarMembro = loja.membros.isEmpty;

    if (!precisaDefinirDonoOriginal && !precisaAdicionarMembro) return;

    final donoOriginal =
        precisaDefinirDonoOriginal ? cpf : loja.cpfDonoOriginal;
    final membros = precisaAdicionarMembro
        ? [
            MembroLoja(
              cpf: cpf,
              nome: nome,
              papel: PapelMembro.dono,
              desde: DateTime.now(),
            ),
          ]
        : loja.membros;

    final atualizada = loja.copyWith(
      cpfDonoOriginal: donoOriginal,
      membros: membros,
    );
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void adicionarMembro(String lojaId, MembroLoja membro) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];
    if (loja.membros.any((m) => m.cpf == membro.cpf)) return;

    final atualizada =
        loja.copyWith(membros: [...loja.membros, membro]);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  Future<void> removerMembro(String lojaId, String cpfMembro) async {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    final restantes =
        loja.membros.where((m) => m.cpf != cpfMembro).toList();
    final atualizada = loja.copyWith(membros: restantes);
    _lojas[indice] = atualizada;
    notifyListeners();

    await _salvarLojaNoCofreCorreto(atualizada);
    await LojasService.removerReferencia(cpfMembro, lojaId);
  }

  Future<void> atualizarPapelMembro(
    String lojaId,
    String cpf,
    PapelMembro papel,
  ) async {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    final novos = loja.membros
        .map((m) => m.cpf == cpf ? m.copyWith(papel: papel) : m)
        .toList();
    final atualizada = loja.copyWith(membros: novos);
    _lojas[indice] = atualizada;
    notifyListeners();

    await _salvarLojaNoCofreCorreto(atualizada);
  }

  Future<void> sairDaLoja(String lojaId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;

    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    final souDonoOriginal = loja.cpfDonoOriginal == cpf;
    final outros = loja.membros.where((m) => m.cpf != cpf).toList();

    _lojas.removeAt(indice);
    notifyListeners();

    if (outros.isEmpty) {
      if (souDonoOriginal) {
        final cofre = await LojasService.carregar(cpf);
        await LojasService.salvar(
          cpf,
          cofre.where((l) => l.id != lojaId).toList(),
        );
      } else {
        await LojasService.removerReferencia(cpf, lojaId);
      }
      return;
    }

    int peso(PapelMembro p) {
      if (p == PapelMembro.socio) return 0;
      if (p == PapelMembro.admin) return 1;
      if (p == PapelMembro.funcionario) return 2;
      return 3;
    }

    final ordenados = [...outros]
      ..sort((a, b) => peso(a.papel).compareTo(peso(b.papel)));
    final sucessor = ordenados.first;

    if (souDonoOriginal) {
      final lojaTransferida = loja.copyWith(
        cpfDonoOriginal: sucessor.cpf,
        membros: outros
            .map((m) => m.cpf == sucessor.cpf
                ? m.copyWith(papel: PapelMembro.dono)
                : m)
            .toList(),
      );

      final cofreSucessor = await LojasService.carregar(sucessor.cpf);
      final jaTem =
          cofreSucessor.any((l) => l.id == lojaTransferida.id);
      if (jaTem) {
        await LojasService.salvar(
          sucessor.cpf,
          cofreSucessor
              .map((l) =>
                  l.id == lojaTransferida.id ? lojaTransferida : l)
              .toList(),
        );
      } else {
        await LojasService.salvar(
          sucessor.cpf,
          [...cofreSucessor, lojaTransferida],
        );
      }

      final cofreAntigo = await LojasService.carregar(cpf);
      await LojasService.salvar(
        cpf,
        cofreAntigo.where((l) => l.id != lojaId).toList(),
      );
    } else {
      final lojaAtualizada = loja.copyWith(membros: outros);
      await _salvarLojaNoCofreCorreto(lojaAtualizada);
      await LojasService.removerReferencia(cpf, lojaId);
    }
  }
}