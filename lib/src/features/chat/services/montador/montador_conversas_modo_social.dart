import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Montador especializado no fluxo de montagem de conversas para o Modo Usuário / Social.
class MontadorConversasModoSocial {
  static Future<void> processar({
    required PdvProvider pdv,
    required AuthProvider auth,
    required String cpfLogado,
    required Map<String, UsuarioNous> usuariosNousPorCpf,
    required List<UsuarioNous> todosUsuariosNous,
    required Map<String, ConversaChat> persistidasMap,
    required Map<String, String> titulosCustomizados,
    required ConversaChat? conversaSelecionada,
    required String? idVisualizador,
    required bool Function(String?) ehNomeDoUsuarioLogado,
    required bool Function(String?) ehFotoDoUsuarioLogado,
    required List<ConversaChat> lista,
    required List<ConversaChat> todosDisponiveis,
  }) async {
    final todasLojas = pdv.lojas;

    // 1. Conversas com as lojas (exceto a Loja Coletiva Nous)
    for (final loja in todasLojas) {
      if (loja.id == PdvProvider.idLojaColetivaNous ||
          loja.id == ChatService.idLojaColetivaNous ||
          loja.id.toLowerCase() == 'nous' ||
          loja.id.toLowerCase().contains('nous_coletiva') ||
          loja.nome.trim().toLowerCase() == 'nous') {
        continue;
      }
      final convId = ChatService.conversaIdLojaUsuario(loja.id, cpfLogado);
      final persistida = persistidasMap[convId];
      final estaSelecionada = conversaSelecionada?.id == convId;

      List<MensagemChat> msgs = [];
      if (estaSelecionada) {
        msgs = await ChatService.carregarMensagens(
          convId,
          idVisualizador: idVisualizador,
        );
      } else if (persistida != null && persistida.mensagens.isNotEmpty) {
        msgs = persistida.mensagens;
      }

      final estaAtiva = estaSelecionada ||
          (ChatService.idConversaAtiva != null &&
              ChatService.idConversaAtiva == convId);
      final naoLidas = estaAtiva ? 0 : (persistida?.naoLidasCount ?? 0);
      final fixada = persistida?.fixada ?? false;
      final arquivada = persistida?.arquivada ?? false;

      var fotoLoja = (loja.logo.isNotEmpty && ImagemService.existe(loja.logo))
          ? loja.logo
          : '';
      if (fotoLoja.isEmpty && persistida != null && persistida.foto.isNotEmpty) {
        if (!ehFotoDoUsuarioLogado(persistida.foto) &&
            ImagemService.existe(persistida.foto)) {
          fotoLoja = persistida.foto;
        }
      }
      if (ehFotoDoUsuarioLogado(fotoLoja)) {
        fotoLoja = '';
      }

      final conversaLoja = ConversaChat(
        id: convId,
        titulo: titulosCustomizados[convId] ?? loja.nome,
        subtitulo: 'Loja',
        foto: fotoLoja,
        identificador: loja.id,
        ehLoja: true,
        lojaId: loja.id,
        ultimaMensagem: msgs.isNotEmpty
            ? MontadorConversasChat.resumoMensagem(msgs.last)
            : ((persistida != null && persistida.ultimaMensagem.isNotEmpty)
                  ? persistida.ultimaMensagem
                  : 'Toque para conversar com a loja.'),
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : (persistida?.dataHoraUltimaMensagem ??
                DateTime.fromMillisecondsSinceEpoch(0)),
        naoLidasCount: naoLidas,
        mensagens: msgs,
        fixada: fixada,
        arquivada: arquivada,
      );

      todosDisponiveis.add(conversaLoja);
      persistidasMap.remove(convId);

      if (msgs.isNotEmpty || persistida != null || estaSelecionada) {
        lista.add(conversaLoja);
      }
    }

    // 2. Conversas com outros membros e clientes conhecidos
    final Map<String, ({String nome, String foto})> contatosUnicos = {};

    for (final loja in todasLojas) {
      final usuarioEhMembroDestaLoja = loja.membros.any(
        (m) => ChatService.normalizarCpf(m.cpf) == cpfLogado,
      ) || ChatService.normalizarCpf(loja.cpfDonoOriginal) == cpfLogado;

      if (usuarioEhMembroDestaLoja) {
        for (final m in loja.membros) {
          final cMembro = ChatService.normalizarCpf(m.cpf);
          if (cMembro.isNotEmpty && cMembro != cpfLogado) {
            final uMembro = usuariosNousPorCpf[cMembro];
            final fotoM = ResolvedorFotoChat.instancia.resolverFotoSincrona(
              identificador: m.cpf,
              auth: auth,
              pdv: pdv,
              mapaUsuarios: usuariosNousPorCpf,
            );
            final nomeM = uMembro?.nomeExibicao.isNotEmpty == true
                ? uMembro!.nomeExibicao
                : m.nome;
            contatosUnicos.putIfAbsent(
              cMembro,
              () => (nome: nomeM, foto: fotoM),
            );
          }
        }
      }
    }

    // 3. Interlocutores históricos no banco
    final interlocutores = await ChatService.obterInterlocutoresDoUsuario(
      cpfLogado,
    );
    for (final inter in interlocutores.entries) {
      final uConta = usuariosNousPorCpf[inter.key];
      final nomeInter = uConta?.nomeExibicao.isNotEmpty == true
          ? uConta!.nomeExibicao
          : ((inter.value.nome.isNotEmpty &&
                  inter.value.nome != 'Conversa' &&
                  inter.value.nome != 'Contato Nous' &&
                  !ehNomeDoUsuarioLogado(inter.value.nome))
              ? inter.value.nome
              : 'Contato Nous');
      final fotoInter = (uConta?.fotoExibicao.isNotEmpty == true)
          ? uConta!.fotoExibicao
          : (!ehFotoDoUsuarioLogado(inter.value.foto) && inter.value.foto.isNotEmpty
              ? inter.value.foto
              : '');

      if (!contatosUnicos.containsKey(inter.key)) {
        contatosUnicos[inter.key] = (nome: nomeInter, foto: fotoInter);
      } else {
        final ant = contatosUnicos[inter.key]!;
        contatosUnicos[inter.key] = (
          nome: uConta?.nomeExibicao.isNotEmpty == true
              ? uConta!.nomeExibicao
              : (ant.nome.isNotEmpty &&
                      ant.nome != 'Conversa' &&
                      ant.nome != 'Contato Nous' &&
                      !ehNomeDoUsuarioLogado(ant.nome)
                  ? ant.nome
                  : nomeInter),
          foto: uConta?.fotoExibicao.isNotEmpty == true
              ? uConta!.fotoExibicao
              : (ant.foto.isNotEmpty && !ehFotoDoUsuarioLogado(ant.foto)
                  ? ant.foto
                  : fotoInter),
        );
      }
    }

    // 4. Todas as contas e usuários da rede Nous (soberania absoluta)
    for (final u in todosUsuariosNous) {
      final cUser = ChatService.normalizarCpf(u.cpf);
      if (cUser.isEmpty || cUser == cpfLogado || cUser.length != 11) continue;
      final nomeUser = u.nomeExibicao.isNotEmpty
          ? u.nomeExibicao
          : (u.apelidoExibicao.isNotEmpty
                ? u.apelidoExibicao
                : (u.nome.isNotEmpty ? u.nome : 'Usuário Nous'));
      final fotoUser = u.fotoExibicao.isNotEmpty ? u.fotoExibicao : u.foto;

      contatosUnicos[cUser] = (nome: nomeUser, foto: fotoUser);
    }

    for (final entry in contatosUnicos.entries) {
      final convId = ChatService.conversaIdEntreUsuarios(
        cpfLogado,
        entry.key,
      );
      final persistida = persistidasMap[convId];
      final estaSelecionada = conversaSelecionada?.id == convId;

      List<MensagemChat> msgs = [];
      if (estaSelecionada) {
        msgs = await ChatService.carregarMensagens(
          convId,
          idVisualizador: idVisualizador,
        );
      } else if (persistida != null && persistida.mensagens.isNotEmpty) {
        msgs = persistida.mensagens;
      }

      final estaAtiva = estaSelecionada ||
          (ChatService.idConversaAtiva != null &&
              ChatService.idConversaAtiva == convId);
      final naoLidas = estaAtiva ? 0 : (persistida?.naoLidasCount ?? 0);
      final fixada = persistida?.fixada ?? false;
      final arquivada = persistida?.arquivada ?? false;
      final uConta = usuariosNousPorCpf[entry.key];

      final nomeExibicao = uConta?.nomeExibicao.isNotEmpty == true
          ? uConta!.nomeExibicao
          : ((entry.value.nome.isNotEmpty &&
                  entry.value.nome != 'Conversa' &&
                  !ehNomeDoUsuarioLogado(entry.value.nome))
              ? entry.value.nome
              : 'Contato Nous');

      final subtituloExibicao = uConta?.usernameExibicao.isNotEmpty == true
          ? uConta!.usernameExibicao
          : (uConta?.apelidoExibicao.isNotEmpty == true
                ? uConta!.apelidoExibicao
                : 'Contato Nous');

      final tituloFinal = (uConta?.nomeExibicao.isNotEmpty == true)
          ? uConta!.nomeExibicao
          : nomeExibicao;
      final tituloConversaFinal = titulosCustomizados[convId] ??
          (persistida?.tituloConversa ?? '');

      var fotoFinal = uConta?.fotoExibicao.isNotEmpty == true
          ? uConta!.fotoExibicao
          : entry.value.foto;
      if (ehFotoDoUsuarioLogado(fotoFinal)) {
        fotoFinal = uConta?.fotoExibicao ?? '';
      }

      final conversaUsuario = ConversaChat(
        id: convId,
        titulo: tituloFinal,
        subtitulo: subtituloExibicao,
        tituloConversa: tituloConversaFinal,
        foto: fotoFinal,
        identificador: entry.key,
        ehLoja: false,
        ultimaMensagem: msgs.isNotEmpty
            ? MontadorConversasChat.resumoMensagem(msgs.last)
            : ((persistida != null && persistida.ultimaMensagem.isNotEmpty)
                  ? persistida.ultimaMensagem
                  : 'Toque para conversar.'),
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : (persistida?.dataHoraUltimaMensagem ??
                DateTime.fromMillisecondsSinceEpoch(0)),
        naoLidasCount: naoLidas,
        mensagens: msgs,
        fixada: fixada,
        arquivada: arquivada,
      );

      todosDisponiveis.add(conversaUsuario);
      persistidasMap.remove(convId);

      if (msgs.isNotEmpty || persistida != null || estaSelecionada) {
        lista.add(conversaUsuario);
      }
    }
  }
}
