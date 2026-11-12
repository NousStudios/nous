import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/contrato_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_permissoes_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_caixa_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_membros_cargos_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_estoque_financeiro_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_lojas_cofre_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_gastos_ponto_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_layout_impressora_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_sincronizacao_dados_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_gestao_loja_helper.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];
  String? _cpfAtual;
  bool _layoutDesktopGlobal = false;
  String _tipoLayoutDesktopGlobal = 'balcao_operacional';

  String? get cpfAtual => _cpfAtual;
  List<Loja> get lojas => List.unmodifiable(_lojas);
  bool get layoutDesktopGlobal => _layoutDesktopGlobal;
  String get tipoLayoutDesktopGlobal => _tipoLayoutDesktopGlobal;

  void notificarMudanca() => notifyListeners();

  bool layoutDesktopAtivo([String? lojaId, double? larguraTela]) =>
      PdvLayoutImpressoraHelper.layoutDesktopAtivo(
        loja: lojaId != null ? buscarPorId(lojaId) : null,
        larguraTela: larguraTela,
        layoutDesktopGlobal: _layoutDesktopGlobal,
      );

  String tipoLayoutAtivo([String? lojaId]) =>
      PdvLayoutImpressoraHelper.tipoLayoutAtivo(
        loja: lojaId != null ? buscarPorId(lojaId) : null,
        tipoLayoutDesktopGlobal: _tipoLayoutDesktopGlobal,
      );

  bool get temLojaSalva => _lojas.isNotEmpty;

  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  List<Loja> get lojasQueAdministro =>
      PdvGestaoLojaHelper.lojasQueAdministro(_lojas, _cpfAtual, idLojaColetivaNous);

  List<Loja> get lojasQueParticipo =>
      PdvGestaoLojaHelper.lojasQueParticipo(_lojas, _cpfAtual, idLojaColetivaNous);

  List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      get todosItensEstoqueBaixo =>
          PdvSincronizacaoDadosHelper.itensEstoqueBaixo(_lojas);

  /// Retorna os itens com estoque baixo ou esgotado restritos a uma loja específica
  List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      itensEstoqueBaixoPorLoja(String lojaId) =>
          PdvSincronizacaoDadosHelper.itensEstoqueBaixo(_lojas, lojaId: lojaId);

  int get totalItensEstoqueBaixo => todosItensEstoqueBaixo.length;

  String? buscarFotoClientePorCpf(String cpf) =>
      PdvSincronizacaoDadosHelper.buscarFotoClientePorCpf(_lojas, cpf);

  Cliente? buscarClientePorCpf(String cpf) =>
      PdvSincronizacaoDadosHelper.buscarClientePorCpf(_lojas, cpf);

  void sincronizarFotoUsuarioEmClientes(String cpf, String novaFoto) {
    unawaited(PdvSincronizacaoDadosHelper.sincronizarFotoUsuarioEmClientes(
      lojas: _lojas,
      cpf: cpf,
      novaFoto: novaFoto,
      salvarNoCofre: _salvarLojaNoCofreCorreto,
    ).then((alterou) {
      if (alterou) notifyListeners();
    }));
  }

  void sincronizarDadosUsuarioEmLojas(UsuarioNous usuario) {
    unawaited(PdvSincronizacaoDadosHelper.sincronizarDadosUsuarioEmLojas(
      lojas: _lojas,
      usuario: usuario,
      salvarNoCofre: _salvarLojaNoCofreCorreto,
    ).then((alterou) {
      if (alterou) notifyListeners();
    }));
  }

  MembroLoja? meuMembro(String lojaId) =>
      PdvPermissoesHelper.resolverMeuMembro(buscarPorId(lojaId), _cpfAtual);

  PapelMembro? meuPapel(String lojaId) => meuMembro(lojaId)?.papel;

  CargoLoja? meuCargoPersonalizado(String lojaId) {
    final loja = buscarPorId(lojaId);
    final m = PdvPermissoesHelper.resolverMeuMembro(loja, _cpfAtual);
    return PdvPermissoesHelper.resolverMeuCargoPersonalizado(loja, m);
  }

  bool possoEditarAbaLoja(String lojaId) =>
      PdvPermissoesHelper.podeEditarAbaLoja(buscarPorId(lojaId), _cpfAtual);

  bool possoUsarImpressora(String lojaId) =>
      PdvPermissoesHelper.podeUsarImpressora(buscarPorId(lojaId), _cpfAtual);

  bool possoEditarDadosLoja(String lojaId) =>
      PdvPermissoesHelper.podeEditarDadosLoja(buscarPorId(lojaId), _cpfAtual);

  bool possoUsarFinanceiro(String lojaId) =>
      PdvPermissoesHelper.podeUsarFinanceiro(buscarPorId(lojaId), _cpfAtual);

  bool possoRegistrarPagamento(String lojaId) =>
      PdvPermissoesHelper.podeRegistrarPagamento(buscarPorId(lojaId), _cpfAtual);

  bool possoGerenciarMembros(String lojaId) =>
      PdvPermissoesHelper.podeGerenciarMembros(buscarPorId(lojaId), _cpfAtual);

  bool possoResetarTransacoes(String lojaId) =>
      PdvPermissoesHelper.podeResetarTransacoes(buscarPorId(lojaId), _cpfAtual);

  bool possoExcluirLoja(String lojaId) =>
      PdvPermissoesHelper.podeExcluirLoja(buscarPorId(lojaId), _cpfAtual);

  Future<void> entrarComCpf(String cpf) async {
    _cpfAtual = cpf;
    final lojasCompletas = await PdvLojasCofreHelper.carregarLojasCompletas(cpf);
    _lojas
      ..clear()
      ..addAll(lojasCompletas);
    await _herdarCalibracaoImpressoraEntreLojasLocais();
    notifyListeners();

    unawaited(() async {
      try {
        if (!ServidorRedeLocal().ativo) {
          final prefs = await SharedPreferences.getInstance();
          final ultimoIp = prefs.getString('nous_ultimo_ip_balcao');
          if (ultimoIp != null && ultimoIp.isNotEmpty) {
            await ClienteRedeLocal().tentarAutoConectarSeDisponivel(this);
          }
        }
      } catch (_) {}
    }());
  }

  Future<void> _herdarCalibracaoImpressoraEntreLojasLocais() =>
      PdvLayoutImpressoraHelper.herdarCalibracaoImpressoraEntreLojasLocais(
        lojas: _lojas,
        idLojaColetivaNous: idLojaColetivaNous,
        salvarNoCofre: _salvarLojaNoCofreCorreto,
      );

  /// Alterna a função de Desenvolvedor para um membro na Loja Coletiva Nous
  Future<void> alternarFuncaoDesenvolvedorNous(String cpf) async {
    final idxLoja = _lojas.indexWhere((l) => l.id == idLojaColetivaNous);
    if (idxLoja == -1) return;

    final lojaAtualizada = PdvMembrosCargosHelper.alternarFuncaoDesenvolvedor(_lojas[idxLoja], cpf);
    _lojas[idxLoja] = lojaAtualizada;
    await LojasService.salvarLojaIndividual(lojaAtualizada);
    notifyListeners();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarLojaAtualizada(lojaAtualizada, imediato: true);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': lojaAtualizada.toJson(),
      });
    }
  }

  void entrarComoVisitante() => limparSessao();

  void limparSessao() {
    _cpfAtual = null;
    _lojas.clear();
    notifyListeners();
  }

  Future<void> _salvarLojaNoCofreCorreto(Loja loja) =>
      PdvLojasCofreHelper.salvarLojaNoCofreCorreto(loja, _cpfAtual);

  Future<void> _salvarEAtualizar(Loja atualizada) async {
    final indice = _lojas.indexWhere((l) => l.id == atualizada.id);
    if (indice != -1) {
      _lojas[indice] = atualizada;
      notifyListeners();
      await _salvarLojaNoCofreCorreto(atualizada);
    }
  }

  void _mutarLoja(String lojaId, Loja? Function(Loja) mutador) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = mutador(loja);
    if (atualizada != null) _salvarEAtualizar(atualizada);
  }

  Future<void> _mutarLojaAsync(String lojaId, FutureOr<Loja?> Function(Loja) mutador) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = await mutador(loja);
    if (atualizada != null) await _salvarEAtualizar(atualizada);
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
    final novaLoja = PdvGestaoLojaHelper.criarNovaLoja(
      cpf: _cpfAtual ?? '',
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
    _herdarCalibracaoImpressoraEntreLojasLocais();
    notifyListeners();
    _salvarLojaNoCofreCorreto(_lojas.last);
  }

  Future<void> adicionarOuAtualizarLoja(Loja loja) async {
    final lojaConsolidada = PdvGestaoLojaHelper.consolidarEAtualizarLojaNaLista(_lojas, loja);
    if (lojaConsolidada == null) return;
    notifyListeners();
    await _salvarLojaNoCofreCorreto(lojaConsolidada);
  }

  static String normalizarIdLoja(String id) =>
      PdvGestaoLojaHelper.normalizarIdLoja(id, idLojaColetivaNous);

  Loja? buscarPorId(String id) =>
      PdvGestaoLojaHelper.buscarPorId(_lojas, id, idLojaColetivaNous);

  Future<void> excluirLoja(String id, {bool originadaDaRede = false}) async {
    final loja = buscarPorId(id);
    _lojas.removeWhere((l) => l.id == id);
    notifyListeners();

    await PdvLojasCofreHelper.excluirLoja(
      loja: loja,
      id: id,
      cpfAtual: _cpfAtual,
      originadaDaRede: originadaDaRede,
    );
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

    final atualizada = PdvGestaoLojaHelper.atualizarDadosLoja(
      _lojas[indice],
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
  }) =>
      _mutarLoja(
        id,
        (l) => PdvLayoutImpressoraHelper.atualizarAnexosLoja(
          l,
          galeria: galeria,
          arquivos: arquivos,
          musicas: musicas,
          videos: videos,
          arquivosAudio: arquivosAudio,
          descricoesAnexos: descricoesAnexos,
        ),
      );

  void atualizarTempoConclusao(String id, int minutos) =>
      _mutarLoja(id, (l) => PdvLayoutImpressoraHelper.atualizarTempoConclusao(l, minutos));

  void atualizarDescricaoAnexo(String id, String caminho, String descricao) =>
      _mutarLoja(id, (l) => PdvLayoutImpressoraHelper.atualizarDescricaoAnexo(l, caminho, descricao));

  void atualizarSomAlerta(String id, String evento, String som) =>
      _mutarLoja(id, (l) => PdvLayoutImpressoraHelper.atualizarSomAlerta(l, evento, som));

  void atualizarAtalhoTeclado(String id, String tecla, String acao) =>
      _mutarLoja(id, (l) => PdvLayoutImpressoraHelper.atualizarAtalhoTeclado(l, tecla, acao));

  void alternarLayoutExpandido([String? id]) {
    final res = PdvLayoutImpressoraHelper.alternarLayoutExpandido(
      lojas: _lojas,
      id: id,
      layoutDesktopGlobal: _layoutDesktopGlobal,
    );
    _layoutDesktopGlobal = res.novoGlobal;
    if (res.lojaAtualizada != null) {
      final idx = _lojas.indexWhere((l) => l.id == res.lojaAtualizada!.id);
      if (idx != -1) _lojas[idx] = res.lojaAtualizada!;
      _salvarLojaNoCofreCorreto(res.lojaAtualizada!);
    }
    notifyListeners();
  }

  void definirLayoutExpandido(bool ativo, [String? id]) {
    _layoutDesktopGlobal = ativo;
    final atualizada = PdvLayoutImpressoraHelper.definirLayoutExpandido(
      lojas: _lojas,
      id: id,
      ativo: ativo,
    );
    if (atualizada != null) {
      final idx = _lojas.indexWhere((l) => l.id == atualizada.id);
      if (idx != -1) _lojas[idx] = atualizada;
      _salvarLojaNoCofreCorreto(atualizada);
    }
    notifyListeners();
  }

  void definirTipoLayoutMaior(String tipo, [String? id]) {
    _tipoLayoutDesktopGlobal = tipo;
    final atualizada = PdvLayoutImpressoraHelper.definirTipoLayoutMaior(
      lojas: _lojas,
      id: id,
      tipo: tipo,
    );
    if (atualizada != null) {
      final idx = _lojas.indexWhere((l) => l.id == atualizada.id);
      if (idx != -1) _lojas[idx] = atualizada;
      _salvarLojaNoCofreCorreto(atualizada);
    }
    notifyListeners();
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

    final atualizada = PdvGestaoLojaHelper.atualizarColecoesLoja(
      _lojas[indice],
      categorias: categorias,
      itens: itens,
      gruposComponentes: gruposComponentes,
      clientes: clientes,
      fornecedores: fornecedores,
      pedidos: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
      pagamentosFuncionarios: pagamentosFuncionarios,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  /// Consulta pedidos da loja sob demanda de forma paginada para relatórios e análises sem sobrecarregar a memória
  Future<List<PedidoLoja>> obterHistoricoPedidosPaginado({
    required String lojaId,
    int limite = 100,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      LojasService.carregarPedidosPaginados(
        lojaId: lojaId,
        limite: limite,
        offset: offset,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );

  /// Retorna a contagem total de pedidos da loja no SQLite
  Future<int> obterTotalPedidos({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      LojasService.contarTotalPedidos(
        lojaId: lojaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );

  Future<void> resetarTransacoesLoja(
    String lojaId, {
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    await PdvEstoqueFinanceiroHelper.executarResetTransacoes(
      loja: loja,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorEmail: autorEmail,
      salvarEAtualizar: _salvarEAtualizar,
    );
  }

  void quitarPedidoLoja(
    String lojaId,
    String pedidoId, {
    String formaRecebimento = 'Dinheiro',
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
  }) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    PdvEstoqueFinanceiroHelper.executarQuitarPedido(
      loja: loja,
      pedidoId: pedidoId,
      formaRecebimento: formaRecebimento,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorEmail: autorEmail,
      salvarEAtualizar: _salvarEAtualizar,
      registrarSuprimentoCaixa: (valor, motivo) => registrarMovimentoCaixa(
        lojaId,
        tipo: TipoMovimentoCaixa.suprimento,
        valor: valor,
        motivo: motivo,
        cpf: autorCpf,
        nome: autorNome,
      ),
      registrarAcao: (acao) => registrarAcao(lojaId, acao),
    );
  }

  void atualizarMesasLoja(String id, List<MesaLoja> mesas) =>
      _mutarLoja(id, (l) => l.copyWith(mesas: mesas));

  Future<void> alternarLojaAberta(String id, bool aberta) =>
      _mutarLojaAsync(id, (l) => l.copyWith(aberta: aberta));

  void atualizarAcoes(String id, List<RegistroAcao> acoes) =>
      _mutarLoja(id, (l) => l.copyWith(acoes: acoes));

  void registrarAcao(String lojaId, RegistroAcao acao) =>
      _mutarLoja(lojaId, (l) => l.copyWith(acoes: [acao, ...l.acoes]));

  void atualizarConfiguracoesImpressora(
    String id,
    ConfiguracoesImpressora configuracoes,
  ) {
    unawaited(PdvLayoutImpressoraHelper.atualizarConfiguracoesImpressora(
      lojas: _lojas,
      id: id,
      configuracoes: configuracoes,
      idLojaColetivaNous: idLojaColetivaNous,
      salvarNoCofre: _salvarLojaNoCofreCorreto,
    ).then((_) => notifyListeners()));
  }

  void adicionarGastoDiario(String lojaId, GastoDiario gasto) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.adicionarGastoDiario(l, gasto));

  void removerGastoDiario(String lojaId, String gastoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.removerGastoDiario(l, gastoId));

  void quitarGastoDiario(String lojaId, String gastoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.quitarGastoDiario(l, gastoId));

  void adicionarGastoFixo(String lojaId, GastoFixo gasto) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.adicionarGastoFixo(l, gasto));

  void removerGastoFixo(String lojaId, String gastoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.removerGastoFixo(l, gastoId));

  void alternarAtivoGastoFixo(String lojaId, String gastoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.alternarAtivoGastoFixo(l, gastoId));

  void salvarContratoTrabalho(String lojaId, ContratoTrabalhoMembro contrato) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.salvarContratoTrabalho(l, contrato));

  void registrarPonto(String lojaId, RegistroPontoMembro ponto) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.registrarPonto(l, ponto));

  void finalizarPonto(String lojaId, String pontoId, DateTime dataHoraSaida) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.finalizarPonto(l, pontoId, dataHoraSaida));

  void salvarEscalaTrabalho(String lojaId, EscalaTrabalhoMembro escala) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.salvarEscalaTrabalho(l, escala));

  void quitarPagamentoFuncionario(String lojaId, String pagamentoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.quitarPagamentoFuncionario(l, pagamentoId));

  void quitarCompraEstoque(String lojaId, String movimentoId) =>
      _mutarLoja(lojaId, (l) => PdvGastosPontoHelper.quitarCompraEstoque(l, movimentoId));

  void adicionarMovimentoEstoque(String lojaId, MovimentoEstoque movimento) =>
      _mutarLoja(lojaId, (l) => PdvEstoqueFinanceiroHelper.adicionarMovimentoEstoque(l, movimento));

  void removerMovimentoEstoque(String lojaId, String movimentoId) {
    LojasService.excluirMovimentoEstoqueIndividual(lojaId, movimentoId);
    _mutarLoja(lojaId, (l) => PdvEstoqueFinanceiroHelper.removerMovimentoEstoque(l, movimentoId));
  }

  void adicionarPagamentoFuncionario(String lojaId, PagamentoFuncionario pagamento) =>
      _mutarLoja(lojaId, (l) => PdvEstoqueFinanceiroHelper.adicionarPagamentoFuncionario(l, pagamento));

  void removerPagamentoFuncionario(String lojaId, String pagamentoId) {
    LojasService.excluirPagamentoFuncionarioIndividual(lojaId, pagamentoId);
    _mutarLoja(lojaId, (l) => PdvEstoqueFinanceiroHelper.removerPagamentoFuncionario(l, pagamentoId));
  }

  void garantirDono(
    String lojaId, {
    required String cpf,
    required String nome,
  }) =>
      _mutarLoja(lojaId, (l) => PdvMembrosCargosHelper.garantirDono(l, cpf: cpf, nome: nome));

  void adicionarMembro(String lojaId, MembroLoja membro) =>
      _mutarLoja(lojaId, (l) => PdvMembrosCargosHelper.adicionarMembro(l, membro));

  Future<void> removerMembro(String lojaId, String cpfMembro) async {
    await _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.removerMembro(l, cpfMembro));
    await LojasService.removerReferencia(cpfMembro, lojaId);
  }

  Future<void> atualizarPapelMembro(
    String lojaId,
    String cpf,
    PapelMembro papel,
  ) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.atualizarPapelMembro(l, cpf, papel));

  Future<void> adicionarCargoLoja(String lojaId, CargoLoja cargo) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.adicionarCargoLoja(l, cargo));

  Future<void> atualizarCargoLoja(String lojaId, CargoLoja cargo) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.atualizarCargoLoja(l, cargo));

  Future<void> removerCargoLoja(String lojaId, String cargoId) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.removerCargoLoja(l, cargoId));

  Future<void> vincularCargoAoMembro(
    String lojaId,
    String cpf,
    String? cargoId,
  ) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.vincularCargoAoMembro(l, cpf, cargoId));

  Future<void> atualizarPermissoesCargoNativo(
    String lojaId,
    String papel,
    Map<String, bool> permissoes,
  ) =>
      _mutarLojaAsync(lojaId, (l) => PdvMembrosCargosHelper.atualizarPermissoesCargoNativo(l, papel, permissoes));

  Future<void> sairDaLoja(String lojaId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;

    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    _lojas.removeAt(indice);
    notifyListeners();

    await PdvLojasCofreHelper.processarSaidaLoja(loja: loja, cpfUsuario: cpf);
  }

  TurnoCaixa? turnoCaixaAberto(String lojaId) =>
      buscarPorId(lojaId)?.turnoCaixaAberto;

  Future<void> abrirCaixa(
    String lojaId,
    double saldoInicial, {
    required String cpf,
    required String nome,
  }) =>
      _mutarLojaAsync(
        lojaId,
        (l) => PdvCaixaHelper.abrirCaixa(
          l,
          saldoInicial: saldoInicial,
          cpf: cpf,
          nome: nome,
        ),
      );

  Future<void> registrarMovimentoCaixa(
    String lojaId, {
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required String cpf,
    required String nome,
  }) =>
      _mutarLojaAsync(
        lojaId,
        (l) => PdvCaixaHelper.registrarMovimentoCaixa(
          l,
          tipo: tipo,
          valor: valor,
          motivo: motivo,
          cpf: cpf,
          nome: nome,
        ),
      );

  Future<void> fecharCaixa(
    String lojaId,
    double saldoInformado, {
    required String cpf,
    required String nome,
    String observacao = '',
  }) =>
      _mutarLojaAsync(
        lojaId,
        (l) => PdvCaixaHelper.fecharCaixa(
          l,
          saldoInformado: saldoInformado,
          cpf: cpf,
          nome: nome,
          observacao: observacao,
        ),
      );

  Future<void> excluirTurnoCaixa(String lojaId, String turnoId) =>
      _mutarLojaAsync(
        lojaId,
        (l) => PdvCaixaHelper.excluirTurnoCaixa(l, turnoId),
      );

  List<PedidoProgramado> pedidosProgramadosDoDia(String lojaId, [DateTime? data]) =>
      PdvPedidosProgramadosHelper.pedidosProgramadosDoDia(buscarPorId(lojaId), data);

  Future<void> adicionarPedidoProgramado(
    String lojaId,
    PedidoProgramado pedido,
  ) async {
    await _mutarLojaAsync(lojaId, (l) => PdvPedidosProgramadosHelper.adicionarPedidoProgramado(l, pedido));
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<void> atualizarPedidoProgramado(
    String lojaId,
    PedidoProgramado pedido,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.atualizarPedidoProgramado(loja, pedido);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, lojaId);
    await _salvarEAtualizar(res.loja);
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<void> removerPedidoProgramado(String lojaId, String pedidoId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.removerPedidoProgramado(loja, pedidoId);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, lojaId);
    await _salvarEAtualizar(res.loja);
  }

  Future<void> alternarAtivoPedidoProgramado(
    String lojaId,
    String pedidoId,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.alternarAtivoPedidoProgramado(loja, pedidoId);
    await PdvPedidosProgramadosHelper.purgarPedidosRemovidos(res.idsPedidosRemovidos, lojaId);
    await _salvarEAtualizar(res.loja);
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<bool> verificarEGerarPedidosProgramados(String lojaId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return false;
    final res = PdvPedidosProgramadosHelper.verificarEGerar(loja);
    if (res.alterou) {
      await _salvarEAtualizar(res.loja);
      PdvPedidosProgramadosHelper.despacharPedidosGeradosNaRede(res.pedidosGerados, lojaId);
      return res.pedidosGerados.isNotEmpty;
    }
    return false;
  }
}