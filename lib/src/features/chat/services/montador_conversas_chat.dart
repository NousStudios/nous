import 'dart:async';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/montador/curador_conversas_chat.dart';
import 'package:nous/src/features/chat/services/montador/montador_conversas_modo_loja.dart';
import 'package:nous/src/features/chat/services/montador/montador_conversas_modo_social.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Serviço especializado na montagem, resolução soberana de identidades,
/// autocura e consolidação de conversas da Mensageria Nous.
class MontadorConversasChat {
  static String resumoMensagem(MensagemChat msg) {
    if (msg.tipo == 'imagem') {
      return msg.texto.isNotEmpty ? '📷 ${msg.texto}' : '📷 Foto';
    } else if (msg.tipo == 'arquivo') {
      return msg.texto.isNotEmpty
          ? '📎 ${msg.texto}'
          : '📎 ${msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : "Arquivo"}';
    } else if (msg.tipo == 'audio') {
      return msg.texto.isNotEmpty ? '🎤 ${msg.texto}' : '🎤 Mensagem de Voz';
    } else if (msg.tipo == 'comanda') {
      return msg.texto.isNotEmpty ? '🧾 ${msg.texto}' : '🧾 Comanda de Pedido';
    }
    return msg.texto;
  }

  /// Monta e higieniza todas as conversas e contatos disponíveis
  static Future<({
    List<ConversaChat> conversas,
    List<ConversaChat> todosDisponiveis,
    Map<String, UsuarioNous> usuariosNousPorCpf,
    Map<String, String> titulosCustomizados,
  })> montarConversas({
    required AuthProvider auth,
    required PdvProvider pdv,
    required bool modoLoja,
    required String? lojaId,
    required String? operadorCpf,
    required String? usuarioCpf,
    required ConversaChat? conversaSelecionada,
  }) async {
    final contaLogada = auth.contaAtual;
    var userCpf = usuarioCpf;
    if (userCpf == null || userCpf.isEmpty) {
      userCpf = contaLogada?.cpf;
    }
    if (userCpf == null || userCpf.isEmpty) {
      final cpfLocal = await ChatService.obterCpfLogadoLocal();
      if (cpfLocal.isNotEmpty) userCpf = cpfLocal;
    }

    final List<ConversaChat> lista = [];
    final List<ConversaChat> todosDisponiveis = [];
    final cpfLogadoNorm = ChatService.normalizarCpf(
      modoLoja
          ? (operadorCpf ?? contaLogada?.cpf ?? userCpf ?? '')
          : (userCpf ?? contaLogada?.cpf ?? ''),
    );

    final titulosCustomizados =
        await ChatService.obterTitulosCustomizados(cpfLogadoNorm);

    final usuariosNousPorCpf = <String, UsuarioNous>{};
    List<UsuarioNous> todosUsuariosNous = [];
    try {
      todosUsuariosNous = await ContasNousService.carregarTodas();
      ResolvedorFotoChat.instancia.registrarContas(todosUsuariosNous);
      for (final u in todosUsuariosNous) {
        final cU = ChatService.normalizarCpf(u.cpf);
        if (cU.length == 11) {
          usuariosNousPorCpf[cU] = u;
        }
      }
    } catch (_) {}

    final conversasPersistidas = await ChatService.obterTodasConversas(
      cpfUsuario: modoLoja ? null : cpfLogadoNorm,
      lojaId: modoLoja ? lojaId : null,
    );
    final Map<String, ConversaChat> persistidasMap = {
      for (final c in conversasPersistidas) c.id: c,
    };

    final idVisualizador = modoLoja ? lojaId : cpfLogadoNorm;

    // Nomes do usuário logado para evitar que sejam mostrados no card do contato
    final nomesPropriosLogado = contaLogada != null
        ? [
            contaLogada.nome,
            contaLogada.nomeExibicao,
            contaLogada.nomePublico,
            contaLogada.apelido,
            contaLogada.apelidoExibicao,
            contaLogada.apelidoPublico,
          ]
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim().toLowerCase())
            .toSet()
        : <String>{};

    bool ehNomeDoUsuarioLogado(String? nome) {
      if (nome == null || nome.trim().isEmpty) return false;
      return nomesPropriosLogado.contains(nome.trim().toLowerCase());
    }

    bool ehFotoDoUsuarioLogado(String? foto) {
      if (foto == null || foto.trim().isEmpty || contaLogada == null) return false;
      if (contaLogada.foto.isNotEmpty && foto == contaLogada.foto) return true;
      if (contaLogada.fotoExibicao.isNotEmpty && foto == contaLogada.fotoExibicao) {
        return true;
      }
      return false;
    }

    if (modoLoja && lojaId != null) {
      await MontadorConversasModoLoja.processar(
        lojaId: lojaId,
        pdv: pdv,
        auth: auth,
        cpfLogadoNorm: cpfLogadoNorm,
        usuariosNousPorCpf: usuariosNousPorCpf,
        todosUsuariosNous: todosUsuariosNous,
        persistidasMap: persistidasMap,
        titulosCustomizados: titulosCustomizados,
        conversaSelecionada: conversaSelecionada,
        idVisualizador: idVisualizador,
        lista: lista,
        todosDisponiveis: todosDisponiveis,
      );
    } else {
      await MontadorConversasModoSocial.processar(
        pdv: pdv,
        auth: auth,
        cpfLogado: cpfLogadoNorm,
        usuariosNousPorCpf: usuariosNousPorCpf,
        todosUsuariosNous: todosUsuariosNous,
        persistidasMap: persistidasMap,
        titulosCustomizados: titulosCustomizados,
        conversaSelecionada: conversaSelecionada,
        idVisualizador: idVisualizador,
        ehNomeDoUsuarioLogado: ehNomeDoUsuarioLogado,
        ehFotoDoUsuarioLogado: ehFotoDoUsuarioLogado,
        lista: lista,
        todosDisponiveis: todosDisponiveis,
      );
    }

    // Carregar Grupos
    final grupos = await ChatService.carregarGrupos(
      cpfParticipante: modoLoja ? null : contaLogada?.cpf,
      lojaId: modoLoja ? lojaId : null,
    );
    lista.addAll(grupos);
    todosDisponiveis.addAll(grupos);

    // Cura preventiva, inclusão de persistidas restantes, desduplicação e ordenação
    await CuradorConversasChat.curarEOrdenar(
      modoLoja: modoLoja,
      cpfLogadoNorm: cpfLogadoNorm,
      usuariosNousPorCpf: usuariosNousPorCpf,
      persistidasMap: persistidasMap,
      titulosCustomizados: titulosCustomizados,
      conversaSelecionada: conversaSelecionada,
      idVisualizador: idVisualizador,
      ehNomeDoUsuarioLogado: ehNomeDoUsuarioLogado,
      ehFotoDoUsuarioLogado: ehFotoDoUsuarioLogado,
      lista: lista,
      todosDisponiveis: todosDisponiveis,
    );

    return (
      conversas: lista,
      todosDisponiveis: todosDisponiveis,
      usuariosNousPorCpf: usuariosNousPorCpf,
      titulosCustomizados: titulosCustomizados,
    );
  }
}
