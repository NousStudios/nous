import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Helper especialista para filtros e buscas de conversas na Mensageria.
class MensageriaBuscaHelper {
  MensageriaBuscaHelper._();

  static bool combinaBusca({
    required ConversaChat c,
    required String termo,
    required bool modoLoja,
    required String? operadorCpf,
    required String? usuarioCpf,
    required Map<String, UsuarioNous> usuariosNousPorCpf,
  }) {
    if (termo.isEmpty) return true;
    final tLimpo = termo.trim().toLowerCase();
    final termoSemArroba = tLimpo.startsWith('@') ? tLimpo.substring(1) : tLimpo;
    final termoDigitos = tLimpo.replaceAll(RegExp(r'\D'), '');

    if (TextoUtils.contemIgnorandoAcentos(c.titulo, tLimpo) ||
        TextoUtils.contemIgnorandoAcentos(c.titulo, termoSemArroba)) {
      return true;
    }
    if (c.ehGrupo &&
        (TextoUtils.contemIgnorandoAcentos(c.nomeGrupo, tLimpo) ||
            TextoUtils.contemIgnorandoAcentos(c.nomeGrupo, termoSemArroba))) {
      return true;
    }
    if (!c.ehLoja || (c.subtitulo != 'Loja' && c.subtitulo != 'Loja Nous')) {
      if (TextoUtils.contemIgnorandoAcentos(c.subtitulo, tLimpo) ||
          TextoUtils.contemIgnorandoAcentos(c.subtitulo, termoSemArroba)) {
        return true;
      }
    } else if (tLimpo == 'loja' || tLimpo == 'lojas') {
      return true;
    }

    if (c.identificador.isNotEmpty && !c.ehLoja) {
      if (TextoUtils.contemIgnorandoAcentos(c.identificador, tLimpo)) {
        return true;
      }
      if (termoDigitos.isNotEmpty) {
        final idDigitos = c.identificador.replaceAll(RegExp(r'\D'), '');
        if (idDigitos.length >= 3 && idDigitos.contains(termoDigitos)) {
          return true;
        }
      }
    }
    if (TextoUtils.contemIgnorandoAcentos(c.ultimaMensagem, tLimpo)) {
      return true;
    }

    if (!c.ehLoja) {
      final meuCpfAtual = modoLoja ? (operadorCpf ?? '') : (usuarioCpf ?? '');
      final meuNorm = ChatService.normalizarCpf(meuCpfAtual);
      var cpfNorm = ChatService.normalizarCpf(c.identificador);
      if (cpfNorm.length != 11 || (meuNorm.isNotEmpty && cpfNorm == meuNorm)) {
        cpfNorm = ChatService.extrairOutroCpf(c.id, meuNorm);
      }
      if (cpfNorm.length == 11 && usuariosNousPorCpf.containsKey(cpfNorm)) {
        final u = usuariosNousPorCpf[cpfNorm]!;
        final campos = [
          u.nome,
          u.nomeExibicao,
          u.nomePublico,
          u.apelido,
          u.apelidoExibicao,
          u.apelidoPublico,
        ];
        if (campos.any((campo) => TextoUtils.contemIgnorandoAcentos(campo, tLimpo))) {
          return true;
        }
        if (TextoUtils.contemIgnorandoAcentos(u.nomeDeUsuario, termoSemArroba) ||
            TextoUtils.contemIgnorandoAcentos(u.usernameExibicao, termoSemArroba)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<ConversaChat> filtrarConversas({
    required List<ConversaChat> conversas,
    required List<ConversaChat> todosContatosDisponiveis,
    required String termoBusca,
    required bool modoLoja,
    required String? operadorCpf,
    required String? usuarioCpf,
    required Map<String, UsuarioNous> usuariosNousPorCpf,
  }) {
    if (termoBusca.isEmpty) {
      return conversas;
    }
    final List<ConversaChat> filtradas = [];
    final Set<String> idsJaAdicionados = {};

    for (final c in conversas) {
      if (combinaBusca(
        c: c,
        termo: termoBusca,
        modoLoja: modoLoja,
        operadorCpf: operadorCpf,
        usuarioCpf: usuarioCpf,
        usuariosNousPorCpf: usuariosNousPorCpf,
      )) {
        filtradas.add(c);
        idsJaAdicionados.add(c.id);
      }
    }

    for (final c in todosContatosDisponiveis) {
      if (!idsJaAdicionados.contains(c.id)) {
        if (combinaBusca(
          c: c,
          termo: termoBusca,
          modoLoja: modoLoja,
          operadorCpf: operadorCpf,
          usuarioCpf: usuarioCpf,
          usuariosNousPorCpf: usuariosNousPorCpf,
        )) {
          filtradas.add(c);
          idsJaAdicionados.add(c.id);
        }
      }
    }

    return filtradas;
  }
}
