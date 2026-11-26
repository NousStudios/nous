import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_coordenadas_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_filtros_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_historico_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_navegacao_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_rotas_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_sessao_helper.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/busca/models/resultado_rota_mapa.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

export 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';

class BuscaMapaController extends ChangeNotifier {
  final MapController mapController = MapController();

  bool _disposed = false;
  bool carregando = true;
  bool _carregandoEmVoo = false;
  String cpfAtivo = '';
  bool modoEspelhadoRemoto = false;

  LatLng? posicaoUsuario;
  String enderecoUsuarioResumo = 'Rua, Bairro, Cidade';

  List<Loja> lojas = [];
  final Map<String, LatLng> coordenadasLojas = {};
  final Map<String, String> _assinaturaEnderecosLojas = {};

  List<UsuarioNous> usuarios = [];
  final Map<String, LatLng> coordenadasUsuariosTempoReal = {};
  bool compartilharLocalizacaoTempoReal = false;
  bool exibirLocalUsuario = true;

  List<PublicacaoSocial> publicacoes = [];
  List<ProjetoComunitario> projetos = [];
  List<EnderecoGeocodificado> enderecosEncontrados = [];
  List<ItemHistoricoBuscaMapa> historicoBusca = [];

  String termoBusca = '';
  FiltroBuscaMapa filtroAtivo = FiltroBuscaMapa.todos;
  bool painelBuscaExpandido = false;
  bool buscandoEnderecos = false;

  Loja? lojaSelecionada;
  UsuarioNous? perfilSelecionado;
  ProjetoComunitario? projetoSelecionado;
  LatLng? pontoMapaSelecionado;
  String enderecoPontoSelecionado = '';

  bool modoRota = false;
  LatLng? origemRota;
  String origemRotaLabel = 'Seu local';
  LatLng? destinoRota;
  String destinoRotaLabel = '';
  ResultadoRotaMapa? rotaAtual;
  bool calculandoRota = false;
  bool navegandoAoVivo = false;
  bool seguirCameraNaNavegacao = true;
  bool mapaFixoAoNorte = false;
  double rumoUsuarioGraus = 0.0;
  int indicePassoAtual = 0;
  double? distanciaProximoPassoMetros;

  void Function(LatLng destino, double zoom, {double? rotacaoGraus})?
      onAnimarCamera;
  VoidCallback? onRotaCalculada;

  Timer? _debounceEnderecos;
  DateTime? _ultimoRecalculoRota;

  void _moverCameraSuave(
    LatLng destino,
    double zoom, {
    double? rotacaoGraus,
  }) {
    if (_disposed) return;
    BuscaMapaNavegacaoHelper.moverCamera(
      mapController,
      destino,
      zoom,
      onAnimarCamera: onAnimarCamera,
      rotacaoGraus: rotacaoGraus,
    );
  }

  LatLng get centroReferencia {
    if (posicaoUsuario != null) return posicaoUsuario!;
    if (coordenadasLojas.isNotEmpty) return coordenadasLojas.values.first;
    return MapaGeoService.coordenadaPadraoBrasil;
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceEnderecos?.cancel();
    mapController.dispose();
    super.dispose();
  }

  Future<void> inicializar(
    PdvProvider pdv, {
    Loja? lojaDestinoInicial,
    String cpfUsuario = '',
  }) async {
    cpfAtivo = cpfUsuario;
    if (lojaDestinoInicial != null) {
      modoRota = true;
      destinoRotaLabel = lojaDestinoInicial.nome;
      calculandoRota = true;
      _notificar();
    }
    await recarregarDados(
      pdv,
      tentarCentralizar: lojaDestinoInicial == null,
      lojaDestinoInicial: lojaDestinoInicial,
    );
    final espelho = BuscaMapaNavegacaoHelper.obterEspelhoAtivo();
    if (espelho != null && lojaDestinoInicial == null) {
      aplicarEstadoEspelhado(espelho);
    }
  }

  Future<void> recarregarDados(
    PdvProvider pdv, {
    bool tentarCentralizar = false,
    Loja? lojaDestinoInicial,
  }) async {
    if (_carregandoEmVoo) return;
    _carregandoEmVoo = true;
    try {
      await BuscaMapaSessaoHelper.recarregarDados(
        this,
        pdv,
        tentarCentralizar: tentarCentralizar,
        lojaDestinoInicial: lojaDestinoInicial,
        assinaturasEnderecos: _assinaturaEnderecosLojas,
        estaDisposto: () => _disposed,
        notificar: _notificar,
        onMoverCamera: _moverCameraSuave,
      );
    } finally {
      _carregandoEmVoo = false;
    }
  }

  Future<void> registrarHistoricoBusca(ItemHistoricoBuscaMapa item) async {
    historicoBusca =
        await BuscaMapaHistoricoHelper.registrarItem(historicoBusca, item);
    _notificar();
  }

  Future<void> removerHistoricoBusca(String titulo) async {
    historicoBusca =
        await BuscaMapaHistoricoHelper.removerPorTitulo(historicoBusca, titulo);
    _notificar();
  }

  Future<void> limparHistoricoBusca() async {
    historicoBusca.clear();
    _notificar();
    await BuscaMapaHistoricoHelper.limparHistorico();
  }

  Future<void> alternarCompartilhamentoLocalizacao() async {
    compartilharLocalizacaoTempoReal = !compartilharLocalizacaoTempoReal;
    await BuscaMapaHistoricoHelper.salvarCompartilharLocalizacao(
      compartilharLocalizacaoTempoReal,
    );
    _notificar();
  }

  Future<void> alternarExibirLocalUsuario() async {
    exibirLocalUsuario = !exibirLocalUsuario;
    await BuscaMapaHistoricoHelper.salvarExibirLocalUsuario(
      exibirLocalUsuario,
    );
    _notificar();
  }

  /// Somente lojas físicas reais devidamente configuradas em Dados da Loja
  /// devem aparecer no mapa (exclui a loja coletiva Nous e cadastros incompletos).
  static bool lojaAptaParaMapa(Loja loja) =>
      BuscaMapaCoordenadasHelper.lojaAptaParaMapa(loja);

  void _moverCameraNavegacao(LatLng alvo) {
    _moverCameraSuave(
      alvo,
      18.6,
      rotacaoGraus: mapaFixoAoNorte ? 0.0 : -rumoUsuarioGraus,
    );
  }

  void _resetarSelecoes({bool limparEndereco = false}) {
    lojaSelecionada = null;
    perfilSelecionado = null;
    projetoSelecionado = null;
    pontoMapaSelecionado = null;
    if (limparEndereco) enderecoPontoSelecionado = '';
  }

  Future<void> centralizarNoUsuario() async {
    final pos = await MapaGeoService.obterPosicaoAtual();
    if (pos != null) {
      posicaoUsuario = pos;
      _moverCameraSuave(pos, 18.2);
      enderecoUsuarioResumo = await MapaGeoService.obterEnderecoResumo(pos);
      _notificar();
      return;
    }
    _moverCameraSuave(centroReferencia, 18.0);
  }

  void pausarSeguirCamera() {
    if (!navegandoAoVivo || !seguirCameraNaNavegacao) return;
    seguirCameraNaNavegacao = false;
    _notificar();
  }

  void retomarSeguirCamera() {
    seguirCameraNaNavegacao = true;
    if (navegandoAoVivo) {
      _moverCameraNavegacao(posicaoUsuario ?? centroReferencia);
    } else {
      _moverCameraSuave(posicaoUsuario ?? centroReferencia, 18.0);
    }
    _notificar();
  }

  void alterarZoom(double delta) {
    try {
      final zoomAtual = mapController.camera.zoom;
      final novoZoom = (zoomAtual + delta).clamp(3.0, 20.0);
      _moverCameraSuave(
        mapController.camera.center,
        novoZoom,
        rotacaoGraus: mapController.camera.rotation,
      );
    } catch (_) {}
  }

  void atualizarPosicaoTempoReal(LatLng pos, {double? headingGraus}) {
    BuscaMapaRotasHelper.atualizarPosicaoTempoReal(
      this,
      pos,
      headingGraus: headingGraus,
      estaDisposto: () => _disposed,
      notificar: _notificar,
      ultimoRecalculoRota: _ultimoRecalculoRota,
      onAtualizarUltimoRecalculo: (dt) => _ultimoRecalculoRota = dt,
    );
  }

  void alternarMapaFixoAoNorte() {
    mapaFixoAoNorte = !mapaFixoAoNorte;
    if (navegandoAoVivo) {
      _moverCameraNavegacao(posicaoUsuario ?? centroReferencia);
    } else if (mapaFixoAoNorte) {
      _moverCameraSuave(
        mapController.camera.center,
        mapController.camera.zoom,
        rotacaoGraus: 0.0,
      );
    }
    _notificar();
  }

  void alternarNavegacaoAoVivo() {
    BuscaMapaRotasHelper.alternarNavegacaoAoVivo(
      this,
      estaDisposto: () => _disposed,
      notificar: _notificar,
    );
  }

  void aplicarEstadoEspelhado(EstadoNavegacaoEspelhada estado) {
    BuscaMapaRotasHelper.aplicarEstadoEspelhado(
      this,
      estado,
      estaDisposto: () => _disposed,
      notificar: _notificar,
    );
  }

  void selecionarLoja(Loja? loja) {
    _resetarSelecoes();
    lojaSelecionada = loja;
    if (loja != null) {
      final coord = coordenadasLojas[loja.id];
      if (coord != null) _moverCameraSuave(coord, 16.0);
    }
    _notificar();
  }

  void selecionarPerfil(UsuarioNous? perfil) {
    _resetarSelecoes();
    perfilSelecionado = perfil;
    if (perfil != null) {
      final cpfNorm = perfil.cpf.replaceAll(RegExp(r'\D'), '');
      final meuCpfNorm = cpfAtivo.replaceAll(RegExp(r'\D'), '');
      final coord = coordenadasUsuariosTempoReal[cpfNorm] ??
          (cpfNorm == meuCpfNorm ? posicaoUsuario : null);
      if (coord != null) _moverCameraSuave(coord, 16.0);
    }
    _notificar();
  }

  void selecionarProjeto(ProjetoComunitario? projeto) {
    _resetarSelecoes();
    projetoSelecionado = projeto;
    if (projeto != null) {
      _moverCameraSuave(LatLng(projeto.latitude, projeto.longitude), 16.2);
    }
    _notificar();
  }

  Future<void> selecionarPontoMapa(LatLng ponto) async {
    _resetarSelecoes();
    pontoMapaSelecionado = ponto;
    enderecoPontoSelecionado = 'Carregando endereço...';
    _notificar();

    final resumo = await MapaGeoService.obterEnderecoResumo(ponto);
    if (_disposed || pontoMapaSelecionado != ponto) return;
    enderecoPontoSelecionado = resumo;
    _notificar();
  }

  void limparSelecaoEntidade() {
    _resetarSelecoes(limparEndereco: true);
    _notificar();
  }

  void definirFiltro(FiltroBuscaMapa filtro) {
    filtroAtivo = filtro;
    painelBuscaExpandido =
        termoBusca.trim().isNotEmpty || filtro != FiltroBuscaMapa.todos;
    if (filtro == FiltroBuscaMapa.todos ||
        filtro == FiltroBuscaMapa.enderecos) {
      if (termoBusca.trim().length >= 2) {
        atualizarBusca(termoBusca);
        return;
      }
    } else {
      _debounceEnderecos?.cancel();
      buscandoEnderecos = false;
    }
    _notificar();
  }

  void definirPainelBusca(bool expandido) {
    painelBuscaExpandido = expandido;
    _notificar();
  }

  void atualizarBusca(String texto) {
    termoBusca = texto;
    painelBuscaExpandido =
        texto.trim().isNotEmpty || filtroAtivo != FiltroBuscaMapa.todos;
    _notificar();

    _debounceEnderecos?.cancel();
    final limpo = texto.trim();
    if (limpo.length < 2) {
      enderecosEncontrados = const [];
      buscandoEnderecos = false;
      _notificar();
      return;
    }

    if (filtroAtivo == FiltroBuscaMapa.todos ||
        filtroAtivo == FiltroBuscaMapa.enderecos) {
      buscandoEnderecos = true;
      _notificar();
      _debounceEnderecos = Timer(const Duration(milliseconds: 380), () async {
        final lista = await BuscaMapaCoordenadasHelper.buscarEnderecos(
          limpo,
          referencia: centroReferencia,
          enderecoUsuarioResumo: enderecoUsuarioResumo,
        );
        if (_disposed) return;
        enderecosEncontrados = lista;
        buscandoEnderecos = false;
        _notificar();
      });
    } else {
      buscandoEnderecos = false;
      _notificar();
    }
  }

  void focarEndereco(EnderecoGeocodificado end) {
    painelBuscaExpandido = false;
    limparSelecaoEntidade();
    _moverCameraSuave(end.coordenada, 16.2);
    _notificar();
  }

  void abrirModoRota() =>
      BuscaMapaRotasHelper.abrirModoRota(this, notificar: _notificar);

  void fecharModoRota() =>
      BuscaMapaRotasHelper.fecharModoRota(this, notificar: _notificar);

  Future<void> tracarRotaPara({
    required LatLng destino,
    required String destinoLabel,
    bool manterNavegacaoAtiva = false,
  }) =>
      BuscaMapaRotasHelper.tracarRotaPara(
        this,
        destino: destino,
        destinoLabel: destinoLabel,
        manterNavegacaoAtiva: manterNavegacaoAtiva,
        estaDisposto: () => _disposed,
        notificar: _notificar,
      );

  Future<void> inverterOrigemDestino() =>
      BuscaMapaRotasHelper.inverterOrigemDestino(
        this,
        estaDisposto: () => _disposed,
        notificar: _notificar,
      );

  Future<void> criarProjeto(ProjetoComunitario projeto) =>
      BuscaMapaRotasHelper.criarProjeto(this, projeto);

  Future<void> alternarApoioProjeto(
    ProjetoComunitario projeto,
    String cpfUsuario,
  ) =>
      BuscaMapaRotasHelper.alternarApoioProjeto(
        this,
        projeto,
        cpfUsuario,
        notificar: _notificar,
      );

  Future<void> assumirProjeto(
    ProjetoComunitario projeto,
    String cpfUsuario,
    String nomeUsuario,
  ) =>
      BuscaMapaRotasHelper.assumirProjeto(
        this,
        projeto,
        cpfUsuario,
        nomeUsuario,
        notificar: _notificar,
      );

  Future<void> concluirProjeto(ProjetoComunitario projeto) =>
      BuscaMapaRotasHelper.concluirProjeto(
        this,
        projeto,
        notificar: _notificar,
      );

  // --- Listas filtradas para a Barra Universal ---

  List<Loja> get lojasFiltradas =>
      BuscaMapaFiltrosHelper.filtrarLojas(lojas, termoBusca);

  List<UsuarioNous> get perfisFiltrados =>
      BuscaMapaFiltrosHelper.filtrarPerfis(usuarios, termoBusca);

  List<ProdutoMapaItem> get produtosFiltrados =>
      BuscaMapaFiltrosHelper.filtrarProdutos(lojas, termoBusca, filtroAtivo);

  List<ProjetoComunitario> get projetosFiltrados =>
      BuscaMapaFiltrosHelper.filtrarProjetos(projetos, termoBusca);

  List<PublicacaoSocial> get publicacoesFiltradas =>
      BuscaMapaFiltrosHelper.filtrarPublicacoes(publicacoes, termoBusca);
}
