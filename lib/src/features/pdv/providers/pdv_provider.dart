import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];
  String? _cpfAtual;

  String? get cpfAtual => _cpfAtual;
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

  List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      get todosItensEstoqueBaixo {
    final alertas =
        <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[];
    for (final loja in _lojas) {
      for (final item in loja.itensLoja) {
        if (item.tipo == TipoItemLoja.servico) continue;
        var saldo = 0.0;
        var temMovimento = false;
        for (final m in loja.movimentosEstoque) {
          if (m.itemId == item.id) {
            saldo += m.quantidadeComSinal;
            temMovimento = true;
          }
        }
        if (temMovimento && saldo < 10) {
          alertas.add((
            item: item,
            saldo: saldo,
            lojaNome: loja.nome,
            lojaId: loja.id,
          ));
        }
      }
    }
    return alertas;
  }

  int get totalItensEstoqueBaixo => todosItensEstoqueBaixo.length;

  String? buscarFotoClientePorCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in _lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos &&
            cliente.foto.isNotEmpty &&
            File(cliente.foto).existsSync()) {
          return cliente.foto;
        }
      }
    }
    return null;
  }

  Cliente? buscarClientePorCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in _lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos) {
          return cliente;
        }
      }
    }
    return null;
  }

  void sincronizarFotoUsuarioEmClientes(String cpf, String novaFoto) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return;
    for (int i = 0; i < _lojas.length; i++) {
      final loja = _lojas[i];
      var alterou = false;
      final novosClientes = loja.clientesLoja.map((c) {
        final cDigits = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos && c.foto != novaFoto) {
          alterou = true;
          return c.copyWith(foto: novaFoto);
        }
        return c;
      }).toList();

      if (alterou) {
        final atualizada = loja.copyWith(clientesLoja: novosClientes);
        _lojas[i] = atualizada;
        _salvarLojaNoCofreCorreto(atualizada);
      }
    }
    notifyListeners();
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
    return meuPapel(lojaId) != null;
  }

  bool possoRegistrarPagamento(String lojaId) {
    final p = meuPapel(lojaId);
    return p == PapelMembro.dono ||
        p == PapelMembro.socio ||
        p == PapelMembro.admin;
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
    final minhasLojasDesduplicadas =
        BackupService.desduplicarLojas(minhasLojasBrutas);
    final minhasLojas = minhasLojasDesduplicadas
        .map((l) => l.cpfDonoOriginal.isEmpty
            ? l.copyWith(cpfDonoOriginal: cpf)
            : l)
        .toList();
    if (minhasLojas.length != minhasLojasBrutas.length) {
      await LojasService.salvar(cpf, minhasLojas);
    }

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
    String redesSociais = '',
    required String categorias,
    required String tags,
    String logo = '',
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
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo,
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
    required String redesSociais,
    required String categorias,
    required String tags,
    String? logo,
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
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo ?? _lojas[indice].logo,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarAnexosLoja(
    String id, {
    List<String>? galeria,
    List<String>? arquivos,
    List<String>? musicas,
    List<String>? videos,
    List<String>? arquivosAudio,
    Map<String, String>? descricoesAnexos,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(
      galeria: galeria ?? _lojas[indice].galeria,
      arquivos: arquivos ?? _lojas[indice].arquivos,
      musicas: musicas ?? _lojas[indice].musicas,
      videos: videos ?? _lojas[indice].videos,
      arquivosAudio: arquivosAudio ?? _lojas[indice].arquivosAudio,
      descricoesAnexos: descricoesAnexos ?? _lojas[indice].descricoesAnexos,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarTempoConclusao(String id, int minutos) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(
      tempoConclusaoMinutos: minutos,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarDescricaoAnexo(String id, String caminho, String descricao) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final mapa = Map<String, String>.from(_lojas[indice].descricoesAnexos);
    if (descricao.trim().isEmpty) {
      mapa.remove(caminho);
    } else {
      mapa[caminho] = descricao.trim();
    }

    final atualizada = _lojas[indice].copyWith(descricoesAnexos: mapa);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarSomAlerta(String id, String evento, String som) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final mapa = Map<String, String>.from(_lojas[indice].sonsAlertas);
    if (som.isEmpty || som == 'padrao') {
      mapa.remove(evento);
    } else {
      mapa[evento] = som;
    }

    final atualizada = _lojas[indice].copyWith(sonsAlertas: mapa);
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
    List<Fornecedor>? fornecedores,
    List<PedidoLoja>? pedidos,
    List<MesaLoja>? mesas,
    List<MovimentoEstoque>? movimentosEstoque,
    List<PagamentoFuncionario>? pagamentosFuncionarios,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      fornecedoresLoja: fornecedores,
      pedidosLoja: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
      pagamentosFuncionarios: pagamentosFuncionarios,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarMesasLoja(String id, List<MesaLoja> mesas) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(mesas: mesas);
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

  void adicionarMovimentoEstoque(
    String lojaId,
    MovimentoEstoque movimento,
  ) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].movimentosEstoque;
    final atualizada = _lojas[indice].copyWith(
      movimentosEstoque: [movimento, ...atual],
    );
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void removerMovimentoEstoque(String lojaId, String movimentoId) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].movimentosEstoque;
    final atualizada = _lojas[indice].copyWith(
      movimentosEstoque:
          atual.where((m) => m.id != movimentoId).toList(),
    );
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void adicionarPagamentoFuncionario(
    String lojaId,
    PagamentoFuncionario pagamento,
  ) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].pagamentosFuncionarios;
    final atualizada = _lojas[indice].copyWith(
      pagamentosFuncionarios: [pagamento, ...atual],
    );
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void removerPagamentoFuncionario(String lojaId, String pagamentoId) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].pagamentosFuncionarios;
    final atualizada = _lojas[indice].copyWith(
      pagamentosFuncionarios:
          atual.where((p) => p.id != pagamentoId).toList(),
    );
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

  TurnoCaixa? turnoCaixaAberto(String lojaId) {
    final loja = buscarPorId(lojaId);
    return loja?.turnoCaixaAberto;
  }

  Future<void> abrirCaixa(
    String lojaId,
    double saldoInicial, {
    required String cpf,
    required String nome,
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;

    final novoTurno = TurnoCaixa.abrir(
      saldoInicial: saldoInicial,
      abertoPorCpf: cpf,
      abertoPorNome: nome,
    );

    final novosTurnos = [...loja.turnosCaixa, novoTurno];
    final atualizada = loja.copyWith(turnosCaixa: novosTurnos);

    final indice = _lojas.indexWhere((l) => l.id == lojaId);
    if (indice != -1) {
      _lojas[indice] = atualizada;
      await _salvarLojaNoCofreCorreto(atualizada);
      notifyListeners();
    }
  }

  Future<void> registrarMovimentoCaixa(
    String lojaId, {
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required String cpf,
    required String nome,
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final aberto = loja.turnoCaixaAberto;
    if (aberto == null) return;

    final mov = MovimentoCaixa.novo(
      tipo: tipo,
      valor: valor,
      motivo: motivo,
      autorCpf: cpf,
      autorNome: nome,
    );

    final turnoAtualizado = aberto.copyWith(
      movimentacoes: [...aberto.movimentacoes, mov],
    );

    final novosTurnos = loja.turnosCaixa
        .map((t) => t.id == turnoAtualizado.id ? turnoAtualizado : t)
        .toList();

    final atualizada = loja.copyWith(turnosCaixa: novosTurnos);
    final indice = _lojas.indexWhere((l) => l.id == lojaId);
    if (indice != -1) {
      _lojas[indice] = atualizada;
      await _salvarLojaNoCofreCorreto(atualizada);
      notifyListeners();
    }
  }

  Future<void> fecharCaixa(
    String lojaId,
    double saldoInformado, {
    required String cpf,
    required String nome,
    String observacao = '',
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final aberto = loja.turnoCaixaAberto;
    if (aberto == null) return;

    final turnoFechado = aberto.copyWith(
      status: StatusTurnoCaixa.fechado,
      dataFechamento: DateTime.now(),
      fechadoPorCpf: cpf,
      fechadoPorNome: nome,
      saldoFinalInformado: saldoInformado,
      observacao: observacao,
    );

    final novosTurnos = loja.turnosCaixa
        .map((t) => t.id == turnoFechado.id ? turnoFechado : t)
        .toList();

    final atualizada = loja.copyWith(turnosCaixa: novosTurnos);
    final indice = _lojas.indexWhere((l) => l.id == lojaId);
    if (indice != -1) {
      _lojas[indice] = atualizada;
      await _salvarLojaNoCofreCorreto(atualizada);
      notifyListeners();
    }
  }
}