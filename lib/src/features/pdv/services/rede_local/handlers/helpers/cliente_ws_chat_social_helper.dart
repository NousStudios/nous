import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Processa eventos WebSocket de mensageria, criptografia, mapa e timeline no cliente.
class ClienteWsChatSocialHelper {
  static const _eventosChatPassivos = <String>{
    'grupo_criado',
    'grupo_atualizado',
    'mensagem_editada',
    'mensagem_excluida',
    'mensagem_reacao',
    'mensagem_fixada',
    'comanda_atualizada',
  };

  /// Tenta processar a mensagem caso pertença ao domínio de chat, mapa ou timeline.
  /// Retorna `true` se o tipo de evento foi tratado por este helper.
  static Future<bool> tentarProcessar(
    String? tipo,
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    if (tipo == 'solicitacao_aceita') {
      final conversaId = dados['conversaId'] as String? ?? '';
      final cpf = dados['cpf'] as String? ?? '';
      await MensageriaSolicitacoesHelper.processarAceiteRemoto(
        conversaId: conversaId,
        meuCpf: cpf,
      );
      return true;
    }

    if (tipo == 'mensagem_chat') {
      if (dados['mensagem'] != null) {
        final msgJson = dados['mensagem'] as Map<String, dynamic>;
        await ChatService.processarMensagemRecebidaDaRede(msgJson);
      }
      return true;
    }

    if (tipo == 'mensagem_entregue') {
      final msgId = dados['id'] as String? ?? dados['mensagemId'] as String? ?? '';
      final convId = dados['conversaId'] as String?;
      await ChatService.processarMensagemEntregueDaRede(msgId, conversaId: convId);
      return true;
    }

    if (tipo == 'mensagens_lidas') {
      final convId = dados['conversaId'] as String? ?? '';
      final idLeitor = dados['idLeitor'] as String? ?? '';
      await ChatService.processarMensagensLidasDaRede(convId, idLeitor);
      return true;
    }

    if (tipo == 'mensagens_lidas_loja') {
      final lojaId = dados['lojaId'] as String? ?? '';
      final idLeitor = dados['idLeitor'] as String? ?? '';
      await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, idLeitor);
      return true;
    }

    if (tipo == 'notificacoes_loja_limpas') {
      final lojaId = dados['lojaId'] as String? ?? '';
      final ids = (dados['ids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      if (lojaId.isNotEmpty && ids.isNotEmpty) {
        NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
          lojaId,
          ids,
          originadoDaRede: true,
        );
        await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, '');
      }
      return true;
    }

    if (tipo == 'conversa_atualizada') {
      if (dados['conversa'] != null) {
        final cMap = dados['conversa'] as Map<String, dynamic>;
        await ChatService.salvarConversaLocal(cMap);
      }
      return true;
    }

    if (tipo == 'conversa_renomeada') {
      final convId = dados['conversaId'] as String?;
      final novoTit = dados['novoTitulo'] as String?;
      if (convId != null && novoTit != null) {
        await ChatService.renomearConversa(convId, novoTit, originadoDaRede: true);
      }
      return true;
    }

    if (tipo == 'conversa_excluida') {
      final convId = dados['conversaId'] as String?;
      if (convId != null) {
        await ChatService.excluirConversaLocal(
          convId,
          originadoDaRede: true,
        );
      }
      return true;
    }

    if (tipo != null && _eventosChatPassivos.contains(tipo)) {
      await ChatService.processarMensagemRecebidaDaRede(
        dados,
        emitirAlertaSonoro: false,
      );
      return true;
    }

    if (tipo == 'chaves_proprias_cpf') {
      final cpfRecebido = ChatService.normalizarCpf(dados['cpf']?.toString() ?? '');
      final cpfLocal = ChatService.normalizarCpf(
        ctx.authProvider?.contaAtual?.cpf ?? ctx.authProvider?.cpf ?? '',
      );
      final pacote = dados['pacote'];
      if (cpfRecebido.isNotEmpty && cpfRecebido == cpfLocal && pacote is Map) {
        await CriptografiaService.importarChavesDoCpf(
          Map<String, dynamic>.from(pacote),
        );
      }
      return true;
    }

    if (tipo != null && tipo.startsWith('timeline_')) {
      await TimelineService.processarEventoRemoto(dados);
      return true;
    }

    return false;
  }
}
