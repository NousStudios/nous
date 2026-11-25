import 'dart:convert';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

/// Helper para mapeamento de registros SQLite em [MensagemChat] e resolução de remetente/status.
class ChatSqliteMensagemMapper {
  ChatSqliteMensagemMapper._();

  static String normalizarCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'\D'), '');
  }

  static bool ehVisualizadorLoja(String conversaId, String idVisualizador) {
    final visDigits = normalizarCpf(idVisualizador);
    return idVisualizador.startsWith('loja_') ||
        (conversaId.startsWith('loja_') && visDigits.length != 11);
  }

  static MensagemChat mapearRowParaMensagem(
    Map<String, dynamic> r,
    String conversaId,
    String? idVisualizador,
  ) {
    final remetente = r['remetente_id'] as String? ?? '';
    final enviadaPorMim = _resolverEnviadaPorMim(
      conversaId: conversaId,
      remetente: remetente,
      idVisualizador: idVisualizador,
    );
    final lida = (r['lida'] as int? ?? 0) == 1;
    final entregue = (r['entregue'] as int? ?? 0) == 1;
    final stBruto = r['status_envio'] as String? ?? '';
    final convIdMsg = r['conversa_id'] as String? ?? '';

    return MensagemChat(
      id: r['id'] as String? ?? '',
      conversaId: convIdMsg,
      remetenteId: remetente,
      remetenteNome: r['remetente_nome'] as String? ?? '',
      remetenteFoto: r['remetente_foto'] as String? ?? '',
      destinatarioId: r['destinatario_id'] as String? ?? '',
      texto: r['texto'] as String? ?? '',
      dataHora:
          DateTime.tryParse(r['data_hora'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      enviadaPorMim: enviadaPorMim,
      nomeAtendente: r['nome_atendente'] as String? ?? '',
      cpfAtendente: r['cpf_atendente'] as String? ?? '',
      lida: lida,
      tipo: r['tipo'] as String? ?? 'texto',
      caminhoAnexo: r['caminho_anexo'] as String? ?? '',
      nomeAnexo: r['nome_anexo'] as String? ?? '',
      tamanhoAnexo: r['tamanho_anexo'] as int? ?? 0,
      pedidoId: r['pedido_id'] as String? ?? '',
      dadosPedidoJson: r['dados_pedido_json'] as String? ?? '',
      editada: (r['editada'] as int? ?? 0) == 1,
      historicoEdicoes: _decodificarHistoricoEdicoes(
        r['historico_edicoes'] as String?,
      ),
      statusEnvio: _resolverStatusEnvio(
        convIdMsg: convIdMsg,
        stBruto: stBruto,
        lida: lida,
        entregue: entregue,
      ),
      entregue: entregue,
      favorita: (r['favorita'] as int? ?? 0) == 1,
      fixada: (r['fixada'] as int? ?? 0) == 1,
      reacoes: _decodificarReacoes(r['reacoes_json'] as String?),
      assinatura: r['assinatura'] as String? ?? '',
      respostaAId: r['resposta_a_id'] as String? ?? '',
      respostaATexto: r['resposta_a_texto'] as String? ?? '',
      respostaAAutor: r['resposta_a_autor'] as String? ?? '',
    );
  }

  static bool _resolverEnviadaPorMim({
    required String conversaId,
    required String remetente,
    required String? idVisualizador,
  }) {
    if (idVisualizador == null || idVisualizador.isEmpty) return false;
    if (ehVisualizadorLoja(conversaId, idVisualizador)) {
      final idLimpo = idVisualizador.startsWith('loja_')
          ? idVisualizador.substring(5)
          : idVisualizador;
      final remLimpo = remetente.startsWith('loja_')
          ? remetente.substring(5)
          : remetente;
      return idLimpo.isNotEmpty
          ? remLimpo == idLimpo
          : remetente.startsWith('loja_');
    }

    final remLimpo = remetente.startsWith('loja_')
        ? remetente.substring(5)
        : remetente;
    var lojaIdConv = '';
    if (conversaId.startsWith('loja_') && conversaId.contains('_usuario_')) {
      lojaIdConv = conversaId.substring(5, conversaId.indexOf('_usuario_'));
    }
    final ehMsgLoja = remetente.startsWith('loja_') ||
        (lojaIdConv.isNotEmpty && remLimpo == lojaIdConv);
    final visNorm = normalizarCpf(idVisualizador);
    final remNorm = normalizarCpf(remetente);
    return !ehMsgLoja && visNorm.isNotEmpty && remNorm == visNorm;
  }

  static String _resolverStatusEnvio({
    required String convIdMsg,
    required String stBruto,
    required bool lida,
    required bool entregue,
  }) {
    final ehColetiva = convIdMsg.startsWith('grupo_') ||
        convIdMsg.startsWith('topico_') ||
        convIdMsg.startsWith('comunidade_') ||
        convIdMsg.startsWith('loja_nous_coletiva_');

    if (!ehColetiva && stBruto == 'lida') return 'lida';
    if (entregue ||
        stBruto == 'entregue' ||
        (ehColetiva && (lida || stBruto == 'lida'))) {
      return 'entregue';
    }
    if (stBruto.isEmpty || stBruto == 'pendente') return 'enviada';
    return stBruto;
  }

  static List<Map<String, dynamic>> _decodificarHistoricoEdicoes(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') {
      return const <Map<String, dynamic>>[];
    }
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Map<String, String> _decodificarReacoes(String? raw) {
    if (raw == null || raw.isEmpty || raw == '{}') {
      return const <String, String>{};
    }
    try {
      final dec = jsonDecode(raw);
      if (dec is Map) {
        return dec.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return const <String, String>{};
  }
}
