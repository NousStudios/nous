import 'dart:async';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Curador responsável por higienizar conversas persistidas restantes,
/// aplicar autocura de nomes/fotos, eliminar duplicatas e ordenar por fixadas/recentes.
class CuradorConversasChat {
  static Future<void> curarEOrdenar({
    required bool modoLoja,
    required String cpfLogadoNorm,
    required Map<String, UsuarioNous> usuariosNousPorCpf,
    required Map<String, ConversaChat> persistidasMap,
    required Map<String, String> titulosCustomizados,
    required ConversaChat? conversaSelecionada,
    required String? idVisualizador,
    required bool Function(String?) ehNomeDoUsuarioLogado,
    required bool Function(String?) ehFotoDoUsuarioLogado,
    required List<ConversaChat> lista,
    required List<ConversaChat> todosDisponiveis,
  }) async {
    // 1. Incluir conversas persistidas restantes
    for (final rem in persistidasMap.values) {
      if (rem.ehGrupo) continue;
      if (!modoLoja && rem.ehLoja) continue;
      if (rem.id.contains('loja_nous_coletiva') ||
          rem.id.contains('loja_nous') ||
          (rem.lojaId != null &&
              (rem.lojaId == PdvProvider.idLojaColetivaNous ||
                  rem.lojaId!.toLowerCase() == 'nous')) ||
          rem.titulo.trim().toLowerCase() == 'nous') {
        continue;
      }

      final estaSelecionada = conversaSelecionada?.id == rem.id;
      List<MensagemChat> msgs = [];
      if (estaSelecionada) {
        msgs = await ChatService.carregarMensagens(
          rem.id,
          idVisualizador: idVisualizador,
        );
      } else if (rem.mensagens.isNotEmpty) {
        msgs = rem.mensagens;
      }

      String tituloRem = rem.titulo;
      String fotoRem = rem.foto;
      String subtituloRem = rem.subtitulo;

      String outroCpfNorm = ChatService.normalizarCpf(rem.identificador);
      if (outroCpfNorm.length != 11) {
        outroCpfNorm = ChatService.extrairOutroCpf(rem.id, cpfLogadoNorm);
      }
      if (outroCpfNorm.length == 11 &&
          usuariosNousPorCpf.containsKey(outroCpfNorm)) {
        final uConta = usuariosNousPorCpf[outroCpfNorm]!;
        if (tituloRem.isEmpty ||
            tituloRem == 'Conversa' ||
            tituloRem == 'Nova Conversa' ||
            tituloRem == 'Contato' ||
            tituloRem == 'Contato Nous' ||
            ehNomeDoUsuarioLogado(tituloRem)) {
          tituloRem = titulosCustomizados[rem.id] ?? uConta.nomeExibicao;
        }
        if (fotoRem.isEmpty || !ImagemService.existe(fotoRem) || ehFotoDoUsuarioLogado(fotoRem)) {
          fotoRem = uConta.fotoExibicao;
        }
        if (subtituloRem.isEmpty ||
            subtituloRem == 'Conversa' ||
            subtituloRem == 'Contato Nous' ||
            !subtituloRem.contains('@')) {
          subtituloRem = uConta.usernameExibicao.isNotEmpty
              ? uConta.usernameExibicao
              : (uConta.apelidoExibicao.isNotEmpty
                    ? uConta.apelidoExibicao
                    : 'Contato Nous');
        }
      }

      if (tituloRem.isEmpty ||
          tituloRem == 'Conversa' ||
          tituloRem == 'Nova Conversa' ||
          tituloRem == 'Contato' ||
          tituloRem == 'Contato Nous' ||
          ehNomeDoUsuarioLogado(tituloRem)) {
        tituloRem = subtituloRem.isNotEmpty &&
                subtituloRem != 'Conversa' &&
                subtituloRem != 'Contato Nous'
            ? subtituloRem
            : 'Contato Nous';
      }

      final conversaRestante = rem.copyWith(
        titulo: tituloRem,
        foto: fotoRem,
        subtitulo: subtituloRem,
        tituloConversa: titulosCustomizados[rem.id] ?? rem.tituloConversa,
        mensagens: msgs,
        identificador: outroCpfNorm.isNotEmpty ? outroCpfNorm : rem.identificador,
        ultimaMensagem: msgs.isNotEmpty
            ? MontadorConversasChat.resumoMensagem(msgs.last)
            : rem.ultimaMensagem,
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : rem.dataHoraUltimaMensagem,
      );

      todosDisponiveis.add(conversaRestante);
      lista.add(conversaRestante);
    }

    // 2. Incluir todos os usuários Nous conhecidos para busca instantânea
    for (final u in usuariosNousPorCpf.values) {
      final cU = ChatService.normalizarCpf(u.cpf);
      if (cU.length == 11 && cU != cpfLogadoNorm) {
        final convId = modoLoja && idVisualizador != null
            ? ChatService.conversaIdLojaUsuario(idVisualizador, cU)
            : ChatService.conversaIdEntreUsuarios(cpfLogadoNorm, cU);

        final nomeContato = u.nomeExibicao.isNotEmpty
            ? u.nomeExibicao
            : (u.nomeDeUsuario.isNotEmpty
                  ? '@${u.nomeDeUsuario}'
                  : 'Contato Nous');
        final subtituloContato = u.usernameExibicao.isNotEmpty
            ? u.usernameExibicao
            : (u.apelidoExibicao.isNotEmpty
                  ? u.apelidoExibicao
                  : 'Usuário Nous');

        final indexDisponivel = todosDisponiveis.indexWhere(
          (c) =>
              ChatService.normalizarCpf(c.identificador) == cU ||
              c.id == convId,
        );

        if (indexDisponivel == -1) {
          todosDisponiveis.add(
            ConversaChat(
              id: convId,
              titulo: titulosCustomizados[convId] ?? nomeContato,
              subtitulo: subtituloContato,
              identificador: u.cpf,
              foto: u.fotoExibicao,
              ehLoja: false,
              dataHoraUltimaMensagem: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
        } else {
          final ant = todosDisponiveis[indexDisponivel];
          final titAnt = ant.titulo;
          final ehNomeProprio = ehNomeDoUsuarioLogado(titAnt);
          final ehFotoPropria = ehFotoDoUsuarioLogado(ant.foto);

          final precisaAtualizarTitulo = titAnt.isEmpty ||
              titAnt == 'Conversa' ||
              titAnt == 'Nova Conversa' ||
              titAnt == 'Contato' ||
              titAnt == 'Contato Nous' ||
              titAnt == 'Cliente' ||
              ehNomeProprio;
          final precisaAtualizarFoto =
              (ant.foto.isEmpty || !ImagemService.existe(ant.foto) || ehFotoPropria) &&
                  u.fotoExibicao.isNotEmpty;
          final precisaAtualizarSub = ant.subtitulo.isEmpty ||
              ant.subtitulo == 'Conversa' ||
              ant.subtitulo == 'Contato Nous' ||
              (!ant.subtitulo.contains('@') && u.usernameExibicao.isNotEmpty);

          if (precisaAtualizarTitulo ||
              precisaAtualizarFoto ||
              precisaAtualizarSub) {
            todosDisponiveis[indexDisponivel] = ant.copyWith(
              titulo: precisaAtualizarTitulo
                  ? (titulosCustomizados[convId] ?? nomeContato)
                  : ant.titulo,
              foto: precisaAtualizarFoto ? u.fotoExibicao : ant.foto,
              subtitulo: precisaAtualizarSub ? subtituloContato : ant.subtitulo,
              identificador:
                  ant.identificador.isEmpty ? u.cpf : ant.identificador,
            );
          }
        }
      }
    }

    // 3. Remover conversas excluídas
    final excluidas = await ChatService.obterIdsConversasExcluidas();
    if (excluidas.isNotEmpty) {
      lista.removeWhere((c) {
        if (!excluidas.contains(c.id)) return false;
        if (conversaSelecionada?.id == c.id) return false;
        if (c.mensagens.isNotEmpty) return false;
        return true;
      });
      todosDisponiveis.removeWhere((c) => c.ehGrupo && excluidas.contains(c.id));
    }

    // 4. Cura preventiva de títulos, fotos e identificadores na lista ativa
    for (int i = 0; i < lista.length; i++) {
      final c = lista[i];
      if (c.ehGrupo || (!modoLoja && c.ehLoja)) continue;
      var cNorm = ChatService.normalizarCpf(c.identificador);
      if (cNorm.length != 11 && c.id.contains('_usuario_')) {
        cNorm = ChatService.normalizarCpf(c.id.split('_usuario_').last);
      } else if (cNorm.length != 11 ||
          (!modoLoja && cpfLogadoNorm.isNotEmpty && cNorm == cpfLogadoNorm)) {
        cNorm = ChatService.extrairOutroCpf(c.id, cpfLogadoNorm);
      }
      if (cNorm.length == 11 && usuariosNousPorCpf.containsKey(cNorm)) {
        final u = usuariosNousPorCpf[cNorm]!;
        final titAnt = c.titulo;
        final ehNomeProprio = !modoLoja && ehNomeDoUsuarioLogado(titAnt);
        final ehFotoPropria = !modoLoja && ehFotoDoUsuarioLogado(c.foto);

        final titGenerico = titAnt.isEmpty ||
            titAnt == 'Conversa' ||
            titAnt == 'Nova Conversa' ||
            titAnt == 'Contato' ||
            titAnt == 'Contato Nous' ||
            titAnt == 'Cliente' ||
            ehNomeProprio;
        final subGenerico = c.subtitulo.isEmpty ||
            c.subtitulo == 'Conversa' ||
            c.subtitulo == 'Contato Nous' ||
            (!c.subtitulo.contains('@') && u.usernameExibicao.isNotEmpty);
        final fotoVazia =
            c.foto.isEmpty || !ImagemService.existe(c.foto) || ehFotoPropria;

        final novoNome = u.nomeExibicao;
        final novoTituloConversa = titulosCustomizados[c.id] ?? c.tituloConversa;

        if (titGenerico || subGenerico || fotoVazia || c.titulo != novoNome) {
          final novoSub = u.usernameExibicao.isNotEmpty
              ? (c.subtitulo.isNotEmpty && !subGenerico
                    ? '${u.usernameExibicao} • ${c.subtitulo}'
                    : u.usernameExibicao)
              : (u.apelidoExibicao.isNotEmpty
                    ? u.apelidoExibicao
                    : 'Usuário Nous');
          final novaFoto = u.fotoExibicao;
          final fotoFinalSalvar =
              fotoVazia && novaFoto.isNotEmpty ? novaFoto : c.foto;
          final subFinalSalvar = subGenerico ? novoSub : c.subtitulo;

          lista[i] = c.copyWith(
            titulo: novoNome,
            subtitulo: subFinalSalvar,
            tituloConversa: novoTituloConversa,
            foto: fotoFinalSalvar,
            identificador: cNorm,
          );

          unawaited(
            ChatService.atualizarMetadadosContatoConversa(
              conversaId: c.id,
              titulo: novoNome,
              subtitulo: subFinalSalvar,
              foto: fotoFinalSalvar,
            ),
          );
        }
      }
    }

    // 5. Desduplicação canônica rigorosa
    final Map<String, ConversaChat> listaDesduplicada = {};
    for (final c in lista) {
      var idNorm = ChatService.normalizarCpf(c.identificador);
      if (idNorm.length != 11 ||
          (cpfLogadoNorm.isNotEmpty && idNorm == cpfLogadoNorm && !modoLoja)) {
        idNorm = ChatService.extrairOutroCpf(c.id, cpfLogadoNorm);
      }
      final chave = c.ehGrupo
          ? 'grupo_${c.id}'
          : (modoLoja
                ? 'loja_conversa_${c.id}'
                : (c.ehLoja
                      ? 'loja_${c.lojaId ?? c.identificador}'
                      : 'user_${idNorm.isNotEmpty ? idNorm : c.id}'));

      if (!listaDesduplicada.containsKey(chave)) {
        listaDesduplicada[chave] = c;
      } else {
        final existente = listaDesduplicada[chave]!;
        final melhorTitulo =
            (c.titulo.isNotEmpty &&
                c.titulo != 'Conversa' &&
                c.titulo != 'Nova Conversa' &&
                c.titulo != 'Contato' &&
                c.titulo != 'Contato Nous' &&
                (modoLoja || !ehNomeDoUsuarioLogado(c.titulo)))
            ? c.titulo
            : existente.titulo;
        final melhorFoto = c.foto.isNotEmpty && (modoLoja || !ehFotoDoUsuarioLogado(c.foto))
            ? c.foto
            : existente.foto;
        final melhorSubtitulo =
            (c.subtitulo.isNotEmpty &&
                c.subtitulo != 'Conversa' &&
                c.subtitulo != 'Contato Nous')
            ? c.subtitulo
            : existente.subtitulo;

        final maisRecente =
            c.dataHoraUltimaMensagem.isAfter(existente.dataHoraUltimaMensagem)
            ? c
            : existente;
        listaDesduplicada[chave] = maisRecente.copyWith(
          titulo: melhorTitulo,
          foto: melhorFoto,
          subtitulo: melhorSubtitulo,
          identificador: idNorm.isNotEmpty ? idNorm : maisRecente.identificador,
          mensagens: [...existente.mensagens, ...c.mensagens],
        );
      }
    }
    lista.clear();
    lista.addAll(listaDesduplicada.values);

    // 6. Ordenar: fixadas primeiro, depois mais recentes
    lista.sort((a, b) {
      if (a.fixada != b.fixada) {
        return a.fixada ? -1 : 1;
      }
      return b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem);
    });
  }
}
