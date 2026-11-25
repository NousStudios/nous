import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/descoberta_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/despachante_cliente_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_pos_conexao_orquestrador.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/snapshot_loja_cliente_handler.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/envio_http_cliente_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_ws_cliente_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';

export 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';

/// Gerencia o Cliente que conecta o celular ao servidor do balcão na rede Wi-Fi.
class ClienteRedeLocal {
  static final ClienteRedeLocal _instancia = ClienteRedeLocal._interno();
  factory ClienteRedeLocal() => _instancia;
  ClienteRedeLocal._interno();

  String? _ipServidor;
  int? _portaServidor;
  PdvProvider? _pdvProvider;
  AuthProvider? _authProvider;
  Loja? _lojaSincronizada;

  final GerenciadorDispositivoLocal _dispLocal = GerenciadorDispositivoLocal();
  final GerenciadorWsClienteHelper _wsHelper = GerenciadorWsClienteHelper();
  final EnvioHttpClienteHelper _httpHelper = EnvioHttpClienteHelper();
  String get _nomeDispositivo => _dispLocal.nomeDispositivo;

  final ValueNotifier<bool> estaConectado = ValueNotifier<bool>(false);
  final ValueNotifier<String?> ultimoErro = ValueNotifier<String?>(null);
  final ValueNotifier<List<DispositivoLojaInfo>> lojasEncontradas =
      ValueNotifier<List<DispositivoLojaInfo>>([]);
  final ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  late final DescobertaRedeLocal _descoberta = DescobertaRedeLocal(
    lojasEncontradas: lojasEncontradas,
    onServidorDescoberto: (info) {
      if (!conectado && !_conectando && _pdvProvider != null) {
        conectar(ip: info.ip, porta: info.porta, pdv: _pdvProvider!, auth: _authProvider);
      }
    },
  );

  bool _aplicandoAtualizacaoRemota = false;
  bool get aplicandoAtualizacaoRemota => _aplicandoAtualizacaoRemota;
  final TransferenciaArquivosRede _transferencia = TransferenciaArquivosRede();
  late final ReconciliadorLojaRede _reconciliador =
      ReconciliadorLojaRede(transferencia: _transferencia);
  late final SincronizadorUsuariosRede _sincronizador = SincronizadorUsuariosRede(
    transferencia: _transferencia,
    reconciliador: _reconciliador,
  );
  final DespachanteClienteRede _despachante = const DespachanteClienteRede();

  bool _conectando = false;
  bool get conectando => _conectando;

  bool get conectado => _wsHelper.estaConectadoAtivo(estaConectado);
  String? get ipServidor => _ipServidor;
  int? get portaServidor => _portaServidor;
  String? get enderecoServidor =>
      _ipServidor != null && _portaServidor != null ? '$_ipServidor:$_portaServidor' : null;
  Loja? get lojaSincronizada => _lojaSincronizada;
  String get nomeDispositivo => _nomeDispositivo;

  /// Registra escuta do ciclo de vida do Flutter para reconexão imediata quando o app volta à tela no Android/iOS.
  void inicializarMonitoramentoCicloVida() {
    _wsHelper.inicializarMonitoramentoCicloVida(verificarEAutoReconectarNaRetomada);
  }

  /// Verifica a integridade da conexão ao destravar o celular ou retomar o app.
  Future<void> verificarEAutoReconectarNaRetomada() =>
      _wsHelper.verificarEAutoReconectarNaRetomada(
        conectado: conectado,
        conectando: _conectando,
        pdv: _pdvProvider,
        auth: _authProvider,
        tentarAutoConectar: tentarAutoConectarSeDisponivel,
        desconectar: desconectar,
      );

  /// Permite definir o IP/porta do servidor balcão para despachos REST sem WS ativo.
  void configurarServidorManual(String ip, int porta) {
    _ipServidor = ip.trim();
    _portaServidor = porta;
  }

  void vincularAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  /// Atualiza ativamente a identificação do terminal móvel no balcão quando o usuário faz login ou troca de conta.
  Future<void> atualizarIdentidadeUsuario({
    String? cpf,
    String? nome,
    String? apelido,
    String? foto,
  }) =>
      _wsHelper.atualizarIdentidadeUsuario(
        conectado: estaConectado.value,
        nomeDispositivo: _nomeDispositivo,
        pdvProvider: _pdvProvider,
        authProvider: _authProvider,
        cpf: cpf,
        nome: nome,
        apelido: apelido,
        foto: foto,
      );

  /// Notifica o servidor do balcão que o usuário deslogou deste terminal.
  void notificarLogout() => _wsHelper.notificarLogout(
        estaConectado: estaConectado.value,
        nomeDispositivo: _nomeDispositivo,
      );

  Future<String> obterNomeDispositivo() => _dispLocal.obterNomeDispositivo();

  Future<void> salvarNomeDispositivo(String novoNome) =>
      _dispLocal.salvarNomeDispositivo(
        novoNome,
        ws: _wsHelper.socket,
        estaConectado: estaConectado.value,
        cpfLogado: _pdvProvider?.cpfAtual,
      );

  /// Inicia escuta UDP para encontrar servidores de lojas transmitindo no Wi-Fi
  /// acompanhada de radar ativo HTTP pela sub-rede local.
  Future<void> iniciarDescoberta({PdvProvider? pdv, AuthProvider? auth}) async {
    if (pdv != null) _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    await _descoberta.iniciarDescoberta();
  }

  void pararDescoberta() {
    _descoberta.pararDescoberta();
  }

  /// Inicia escuta contínua e tenta reconectar automaticamente ao servidor balcão.
  Future<void> tentarAutoConectarSeDisponivel(PdvProvider pdv, [AuthProvider? auth]) async {
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    await _wsHelper.tentarAutoConectar(
      pdv: pdv,
      auth: auth,
      conectado: () => conectado,
      conectando: () => _conectando,
      obterLojasEncontradas: () => lojasEncontradas.value,
      iniciarDescoberta: iniciarDescoberta,
      conectar: conectar,
    );
  }

  /// Conecta ao servidor no IP e porta especificados (manual ou descoberto).
  Future<bool> conectar({
    required String ip,
    required int porta,
    required PdvProvider pdv,
    AuthProvider? auth,
    bool forcar = false,
  }) async {
    if (ServidorRedeLocal().ativo) {
      debugPrint(
        '[ClienteRedeLocal] Esta máquina já é o Servidor Balcão ativo. Conexão cliente ignorada.',
      );
      return false;
    }
    final ipAlvo = ip.trim();
    if (conectado && _ipServidor == ipAlvo && _portaServidor == porta && !forcar) {
      debugPrint('[ClienteRedeLocal] Conexão já ativa em $ipAlvo:$porta.');
      return true;
    }
    if (_conectando && !forcar) {
      debugPrint(
        '[ClienteRedeLocal] Conexão já em andamento para $ipAlvo:$porta. Ignorando chamada concorrente.',
      );
      return false;
    }

    _conectando = true;
    _wsHelper.marcarDesconexaoManual(false);
    _wsHelper.cancelarTimerReconexao();
    await desconectar(manual: false);

    _ipServidor = ipAlvo;
    _portaServidor = porta;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;

    try {
      ultimoErro.value = null;
      await obterNomeDispositivo();

      final usuario = await _wsHelper.resolverDadosUsuarioLogado(
        pdvProvider: _pdvProvider,
        authProvider: _authProvider,
      );

      // 1. Baixa e consolida o snapshot atualizado da Loja via REST
      final resultadoSnapshot = await SnapshotLojaClienteHandler.obterEConsolidarSnapshot(
        ipServidor: _ipServidor!,
        portaServidor: _portaServidor!,
        cpfLogado: usuario.cpf,
        nomeUsuario: usuario.nome,
        apelidoUsuario: usuario.apelido,
        nomeDispositivo: _nomeDispositivo,
        pdvProvider: _pdvProvider!,
        vincularLojaSeNecessario: _vincularLojaSeNecessario,
      );

      if (!resultadoSnapshot.sucesso) {
        ultimoErro.value = resultadoSnapshot.erro;
        return false;
      }

      _lojaSincronizada = resultadoSnapshot.lojaConsolidada;
      if (resultadoSnapshot.presencas != null) {
        presencasAtivas.value = resultadoSnapshot.presencas!;
      }

      // 2. Conecta ao WebSocket para atualizações em tempo real
      await _wsHelper.conectarWebSocket(
        ipServidor: _ipServidor!,
        portaServidor: _portaServidor!,
        nomeDispositivo: _nomeDispositivo,
        usuario: usuario,
        estaConectado: estaConectado,
        onMensagem: _processarMensagemWs,
        onDesconectar: _aoDesconectar,
      );

      // 3. Orquestração sequencial e resiliente em background pós-conexão
      unawaited(
        ClientePosConexaoOrquestrador.executar(
          ipServidor: _ipServidor!,
          portaServidor: _portaServidor!,
          cpfLogado: usuario.cpf,
          lojaBrutaParaReconciliar: resultadoSnapshot.lojaBrutaParaReconciliar,
          imagensAusentesParaReconciliar: resultadoSnapshot.imagensAusentes,
          fotosUsuariosAusentesParaReconciliar: resultadoSnapshot.fotosUsuariosAusentes,
          pdvProvider: _pdvProvider,
          reconciliarLojaMutua: _reconciliarLojaMutua,
          onLojaSincronizada: (l) => _lojaSincronizada = l,
          curarFotosUsuariosAusentesNoServidor: _curarFotosUsuariosAusentesNoServidor,
          verificarAtualizacaoLocal: verificarAtualizacaoLocal,
          sincronizarIdentidadeUsuario: sincronizarIdentidadeUsuario,
          reconciliarContasComServidor: reconciliarContasComServidor,
          sincronizarPerfisLojasComServidor: sincronizarPerfisLojasComServidor,
          idLojaSincronizada: _lojaSincronizada?.id,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao conectar ao servidor: $e');
      estaConectado.value = false;
      if (ultimoErro.value == null) {
        ultimoErro.value = 'Não foi possível conectar ao balcão.';
      }
      return false;
    } finally {
      _conectando = false;
    }
  }

  Future<void> _processarMensagemWs(dynamic msg) async {
    final ctx = ClienteWsContext(
      pdvProvider: _pdvProvider,
      authProvider: _authProvider,
      presencasAtivas: presencasAtivas,
      obterLojaSincronizada: () => _lojaSincronizada,
      definirLojaSincronizada: (l) => _lojaSincronizada = l,
      definirAplicandoAtualizacaoRemota: (v) => _aplicandoAtualizacaoRemota = v,
      sincronizarImagensRemotas: _sincronizarImagensRemotas,
      vincularLojaSeNecessario: _vincularLojaSeNecessario,
      enviarLojaCuradaParaServidor: _enviarLojaCuradaParaServidor,
      curarFotosUsuariosAusentesNoServidor: _curarFotosUsuariosAusentesNoServidor,
      sincronizarPerfisLojasComServidor: sincronizarPerfisLojasComServidor,
      processarSinalChamada: _processarSinalChamada,
      baixarImagemRemota: baixarImagemRemota,
      reconciliarPedidosNoServidor: reconciliarPedidosNoServidor,
    );
    await ClienteWsMessageHandler.processarMensagem(msg, ctx);
  }

  void _processarSinalChamada(Map<String, dynamic> dados) {
    final meuCpf =
        (_authProvider?.cpf ?? _pdvProvider?.cpfAtual ?? '').replaceAll(RegExp(r'\D'), '');
    ClienteWsMessageHandler.processarSinalChamada(
      dados: dados,
      meuCpf: meuCpf,
      lojasLocal: _pdvProvider?.lojas,
    );
  }

  void _aoDesconectar() {
    _wsHelper.tratarDesconexao(
      estaConectado: estaConectado,
      presencasAtivas: presencasAtivas,
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      podeReconectar: () =>
          !conectado &&
          !_conectando &&
          _ipServidor != null &&
          _portaServidor != null &&
          _pdvProvider != null,
      onReconectar: () => conectar(
        ip: _ipServidor!,
        porta: _portaServidor!,
        pdv: _pdvProvider!,
        auth: _authProvider,
      ),
    );
  }

  Future<void> _vincularLojaSeNecessario(Loja loja) =>
      ClientePosConexaoOrquestrador.vincularLojaSeNecessario(
        loja: loja,
        cpfLogado: _pdvProvider?.cpfAtual ?? _authProvider?.contaAtual?.cpf ?? _authProvider?.cpf,
        pdvProvider: _pdvProvider,
      );

  /// Envia mensagem de chat em tempo real via WebSocket para o servidor (com fallback REST).
  Future<bool> enviarMensagemChat(
    MensagemChat msg, {
    Map<String, dynamic>? payloadCustomizado,
  }) =>
      _despachante.enviarMensagemChat(
        ws: _wsHelper.socket,
        estaConectado: estaConectado.value,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojasEncontradas: lojasEncontradas.value,
        msg: msg,
        payloadCustomizado: payloadCustomizado,
        uploadImagem: _enviarUploadImagemParaServidor,
        uploadAnexo: (caminho, subpasta) => _transferencia.enviarUploadAnexoParaServidor(
          ipServidor: _ipServidor,
          portaServidor: _portaServidor,
          caminhoLocal: caminho,
          subpasta: subpasta,
        ),
      );

  /// Envia um evento de controle ou confirmação via WebSocket (ex: mensagem_entregue, mensagem_lida).
  void enviarEventoWs(Map<String, dynamic> payload) => enviarMensagemRaw(payload);

  /// Envia um pedido (novo ou atualizado) realizado no celular para o servidor central da loja.
  Future<bool> enviarPedido(PedidoLoja pedido) async {
    enviarMensagemRaw({
      'tipo': 'pedido_atualizado',
      'pedido': pedido.toJson(),
    });

    return _despachante.enviarPedido(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      pedido: pedido,
    );
  }

  /// Envia uma movimentação de estoque realizada no celular para o servidor.
  Future<bool> enviarMovimentoEstoque(
    MovimentoEstoque mov, {
    String? lojaId,
  }) =>
      _despachante.enviarMovimentoEstoque(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        mov: mov,
        lojaId: lojaId ?? _lojaSincronizada?.id,
      );

  /// Envia atualização de mesa para o servidor central.
  Future<bool> enviarMesa(
    MesaLoja mesa, {
    String? lojaId,
  }) =>
      _despachante.enviarMesa(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        mesa: mesa,
        lojaId: lojaId ?? _lojaSincronizada?.id,
      );

  Future<String> enviarUploadImagem(String caminhoLocal) =>
      _enviarUploadImagemParaServidor(caminhoLocal);

  Future<String> enviarUploadAnexo(
    String caminhoLocal, {
    String subpasta = 'timeline_midias',
  }) async {
    if (!conectado || _ipServidor == null || _portaServidor == null) return '';
    return _transferencia.enviarUploadAnexoParaServidor(
      ipServidor: _ipServidor!,
      portaServidor: _portaServidor!,
      caminhoLocal: caminhoLocal,
      subpasta: subpasta,
    );
  }

  Future<String> _enviarUploadImagemParaServidor(String caminhoLocal) =>
      _transferencia.enviarUploadImagemParaServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        caminhoLocal: caminhoLocal,
      );

  Future<bool> _enviarLojaCuradaParaServidor(Loja lojaCurada) =>
      _reconciliador.enviarLojaCuradaParaServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaCurada: lojaCurada,
      );

  Future<Loja> _prepararLojaComUploadsParaServidor(Loja loja) =>
      _reconciliador.prepararLojaComUploadsParaServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        loja: loja,
      );

  /// Envia a atualização completa da loja realizada neste terminal móvel para o servidor central (balcão).
  Future<bool> enviarLojaAtualizada(Loja loja, {bool imediato = false}) =>
      _httpHelper.enviarLojaAtualizada(
        loja: loja,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        conectado: conectado,
        aplicandoAtualizacaoRemota: _aplicandoAtualizacaoRemota,
        pdvProvider: _pdvProvider,
        prepararLojaComUploads: _prepararLojaComUploadsParaServidor,
        imediato: imediato,
      );

  /// Desconecta do servidor e encerra todas as conexões e sessões pendentes.
  Future<void> desconectar({bool manual = false}) async {
    _httpHelper.cancelarDebounceEnvioLoja();
    await _wsHelper.fecharConexao(manual: manual);

    _ipServidor = null;
    _portaServidor = null;
    _lojaSincronizada = null;
    estaConectado.value = false;
    presencasAtivas.value = [];
    pararDescoberta();
  }

  Future<Loja> _reconciliarLojaMutua(
    Loja lojaRemota,
    List<String> imagensAusentesNoServidor,
  ) =>
      _reconciliador.reconciliarLojaMutua(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaRemota: lojaRemota,
        imagensAusentesNoServidor: imagensAusentesNoServidor,
        pdvProvider: _pdvProvider,
        lojaSincronizada: _lojaSincronizada,
      );

  Future<Loja> _sincronizarImagensRemotas(Loja lojaRemota) =>
      _reconciliador.sincronizarImagensRemotas(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaRemota: lojaRemota,
        pdvProvider: _pdvProvider,
        lojaSincronizada: _lojaSincronizada,
      );

  /// Sincroniza a Identidade do Usuário (dados cadastrais e foto) a partir do balcão (autocura mútua).
  Future<void> sincronizarIdentidadeUsuario({AuthProvider? auth}) =>
      _sincronizador.sincronizarIdentidadeUsuario(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        auth: auth ?? _authProvider,
        pdvProvider: _pdvProvider,
      );

  /// Consulta o servidor balcão na rede Wi-Fi local para obter a ficha unificada da conta pelo CPF.
  Future<UsuarioNous?> buscarUsuarioRemoto(String cpf) =>
      _httpHelper.buscarUsuarioRemoto(
        cpf: cpf,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojasEncontradas: lojasEncontradas.value,
        iniciarDescoberta: iniciarDescoberta,
        pararDescoberta: pararDescoberta,
        sincronizador: _sincronizador,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
      );

  /// Verifica se o balcão possui atualizações do sistema ou APK disponível para download.
  Future<void> verificarAtualizacaoLocal() =>
      _despachante.verificarAtualizacaoLocal(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
      );

  /// Consulta no servidor balcão o status atualizado de pedidos locais ausentes no snapshot.
  Future<List<PedidoLoja>> reconciliarPedidosNoServidor(
    String lojaId,
    List<String> ids,
  ) =>
      _httpHelper.reconciliarPedidosNoServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaId: lojaId,
        ids: ids,
      );

  /// Baixa uma imagem remota individual do balcão e salva no armazenamento local.
  Future<String> baixarImagemRemota(String caminhoRemoto, {String? cpf}) =>
      _transferencia.baixarImagemRemota(
        caminhoRemoto: caminhoRemoto,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        cpf: cpf,
        onFotoUsuarioBaixada: (cpfLimpo, pathFinal) => _httpHelper.onFotoUsuarioBaixada(
          cpfLimpo: cpfLimpo,
          pathFinal: pathFinal,
          authProvider: _authProvider,
          pdvProvider: _pdvProvider,
        ),
      );

  /// Baixa um arquivo de áudio/música remoto do balcão e salva no armazenamento local.
  Future<String> baixarAudioRemoto(String caminhoRemoto) =>
      _transferencia.baixarAudioRemoto(
        caminhoRemoto: caminhoRemoto,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
      );

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão.
  Future<bool> enviarUsuario(UsuarioNous usuario) => _sincronizador.enviarUsuario(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        usuario: usuario,
      );

  Future<void> _curarFotosUsuariosAusentesNoServidor(List<String> cpfsAusentes) =>
      _sincronizador.curarFotosUsuariosAusentesNoServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        cpfsAusentes: cpfsAusentes,
        pdvProvider: _pdvProvider,
      );

  /// Método público para forçar a sincronização e reconciliação mútua de contas e usuários com o balcão.
  Future<void> reconciliarContasComServidor() =>
      _sincronizador.reconciliarTodasContasLocaisComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
      );

  /// Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF ativo.
  Future<void> sincronizarPerfisLojasComServidor() =>
      _sincronizador.sincronizarPerfisLojasComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
        lojaSincronizada: _lojaSincronizada,
      );

  /// Notifica o servidor balcão que o membro saiu da loja para desvinculação imediata.
  Future<void> notificarSaidaLoja(String lojaId, String cpf) =>
      _despachante.notificarSaidaLoja(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaId: lojaId,
        cpf: cpf,
      );

  /// Envia payload genérico JSON pelo WebSocket ativo para o servidor balcão.
  void enviarMensagemRaw(Map<String, dynamic> payload) =>
      _wsHelper.enviarMensagemRaw(
        estaConectado: estaConectado.value,
        payload: payload,
      );

  /// Sincroniza bidirecionalmente a Timeline Social com o servidor balcão.
  Future<bool> sincronizarTimelineComServidor() =>
      _httpHelper.sincronizarTimelineComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojasEncontradas: lojasEncontradas.value,
      );

  /// Sincroniza o relógio deste dispositivo com o balcão da rede local sob demanda.
  Future<bool> sincronizarRelogio() => _httpHelper.sincronizarRelogio(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojasEncontradas: lojasEncontradas.value,
      );
}
