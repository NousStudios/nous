import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Helper especialista para gerenciar Solicitações de Mensagens estilo Instagram na Mensageria
class MensageriaSolicitacoesHelper {
  MensageriaSolicitacoesHelper._();

  static final Set<String> _aceitas = {};
  static bool _carregado = false;
  static String _ultimoCpf = '';

  static Future<void> carregarAceitas(String meuCpf) async {
    final meuNorm = ChatService.normalizarCpf(meuCpf);
    if (meuNorm.isEmpty) return;
    if (_carregado && _ultimoCpf == meuNorm) return;

    try {
      final lista = await PreferenciasSoberanasService.obterLista(
        'chat_solicitacoes_aceitas_$meuNorm',
      );
      _aceitas.clear();
      _aceitas.addAll(lista);
      _carregado = true;
      _ultimoCpf = meuNorm;
    } catch (_) {}
  }

  static bool ehSolicitacao({
    required ConversaChat conversa,
    required bool modoLoja,
    required String meuCpf,
    UsuarioNous? contaLogada,
  }) {
    if (modoLoja) return false;
    if (conversa.ehLoja || conversa.ehGrupo) return false;
    if (_aceitas.contains(conversa.id)) return false;

    final meuNorm = ChatService.normalizarCpf(meuCpf);
    if (meuNorm.isEmpty) return false;

    final outroCpf = ChatService.extrairOutroCpf(conversa.id, meuNorm);
    if (outroCpf.isEmpty || outroCpf == meuNorm) return false;

    // Se o usuário segue o interlocutor, mensagens caem direto na caixa principal
    if (contaLogada != null && contaLogada.estaSeguindo(outroCpf)) {
      return false;
    }

    // Se o próprio usuário enviou ou já respondeu na conversa, foi consentida/iniciada
    if (conversa.ultimaMensagemEnviadaPorMim) {
      return false;
    }
    final enviouMensagem = conversa.mensagens.any(
      (m) => ChatService.normalizarCpf(m.remetenteId) == meuNorm,
    );
    if (enviouMensagem) {
      return false;
    }

    // Só é solicitação se existir pelo menos uma mensagem recebida do outro usuário.
    // Conversa vazia (aberta agora para enviar a 1ª mensagem) não é solicitação.
    if (conversa.mensagens.isEmpty) {
      return false;
    }
    return conversa.mensagens.any(
      (m) => ChatService.normalizarCpf(m.remetenteId) == outroCpf,
    );
  }

  static Future<void> aceitarSolicitacao({
    required String conversaId,
    required String meuCpf,
  }) async {
    final meuNorm = ChatService.normalizarCpf(meuCpf);
    _aceitas.add(conversaId);
    if (meuNorm.isNotEmpty) {
      try {
        await PreferenciasSoberanasService.salvarLista(
          'chat_solicitacoes_aceitas_$meuNorm',
          _aceitas.toList(),
        );
      } catch (_) {}
      final evento = {
        'tipo': 'solicitacao_aceita',
        'conversaId': conversaId,
        'cpf': meuNorm,
      };
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarEventoWs(evento);
      } else if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(evento);
      }
    }
  }

  static Future<void> processarAceiteRemoto({
    required String conversaId,
    required String meuCpf,
  }) async {
    final meuNorm = ChatService.normalizarCpf(meuCpf);
    if (conversaId.isEmpty || meuNorm.isEmpty) return;
    try {
      final chave = 'chat_solicitacoes_aceitas_$meuNorm';
      final lista =
          (await PreferenciasSoberanasService.obterLista(chave)).toSet()
            ..add(conversaId);
      await PreferenciasSoberanasService.salvarLista(chave, lista.toList());
      if (_ultimoCpf == meuNorm) {
        _aceitas.add(conversaId);
      }
    } catch (_) {}
  }

  static Future<void> recusarSolicitacao(String conversaId) async {
    _aceitas.remove(conversaId);
    await ChatService.excluirConversaLocal(conversaId);
  }

  static void limpar() {
    _aceitas.clear();
    _carregado = false;
    _ultimoCpf = '';
  }
}
