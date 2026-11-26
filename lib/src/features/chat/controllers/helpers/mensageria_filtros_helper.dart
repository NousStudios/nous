import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';

/// Abas principais da barra lateral vertical da Mensageria.
enum AbaNavegacaoMensageria {
  conversas,
  ligacoes,
  comunidades,
  transmissao,
}

/// Filtros rápidos exibidos acima da lista de conversas.
enum TipoFiltroChat {
  tudo,
  naoLidas,
  grupos,
  favoritas,
  personalizado,
}

/// Helper puro para aplicar filtros padrão e personalizados na lista de conversas.
class MensageriaFiltrosHelper {
  MensageriaFiltrosHelper._();

  static List<ConversaChat> aplicarFiltro({
    required List<ConversaChat> conversas,
    required TipoFiltroChat tipoFiltro,
    required String? filtroPersonalizadoId,
    required List<FiltroChatPersonalizado> filtrosPersonalizados,
  }) {
    switch (tipoFiltro) {
      case TipoFiltroChat.tudo:
        return conversas;
      case TipoFiltroChat.naoLidas:
        return conversas.where((c) => c.naoLidasCount > 0).toList();
      case TipoFiltroChat.grupos:
        return conversas.where((c) => c.ehGrupo).toList();
      case TipoFiltroChat.favoritas:
        return conversas.where((c) => c.favorita).toList();
      case TipoFiltroChat.personalizado:
        if (filtroPersonalizadoId == null || filtroPersonalizadoId.isEmpty) {
          return conversas;
        }
        final filtro = filtrosPersonalizados.cast<FiltroChatPersonalizado?>().firstWhere(
          (f) => f?.id == filtroPersonalizadoId,
          orElse: () => null,
        );
        if (filtro == null) return conversas;
        final ids = filtro.conversasIds.toSet();
        return conversas.where((c) => ids.contains(c.id)).toList();
    }
  }
}
