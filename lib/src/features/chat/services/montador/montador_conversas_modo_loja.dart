import 'dart:async';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/info_contato_unificado.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/montador_conversas_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Montador especializado no fluxo de montagem de conversas para o Modo Loja.
class MontadorConversasModoLoja {
  static Future<void> processar({
    required String lojaId,
    required PdvProvider pdv,
    required AuthProvider auth,
    required String cpfLogadoNorm,
    required Map<String, UsuarioNous> usuariosNousPorCpf,
    required List<UsuarioNous> todosUsuariosNous,
    required Map<String, ConversaChat> persistidasMap,
    required Map<String, String> titulosCustomizados,
    required ConversaChat? conversaSelecionada,
    required String? idVisualizador,
    required List<ConversaChat> lista,
    required List<ConversaChat> todosDisponiveis,
  }) async {
    final loja = pdv.buscarPorId(lojaId);
    if (loja == null) return;

    final Map<String, InfoContatoUnificado> contatosUnificados = {};

    // 1. Membros da equipe
    for (final membro in loja.membros) {
      final cpfMembro = ChatService.normalizarCpf(membro.cpf);
      if (cpfMembro.isEmpty) continue;
      final ehProprioOperador = cpfMembro == cpfLogadoNorm;
      final uMembro = usuariosNousPorCpf[cpfMembro];
      final fotoMembro = ResolvedorFotoChat.instancia.resolverFotoSincrona(
        identificador: membro.cpf,
        auth: auth,
        pdv: pdv,
        mapaUsuarios: usuariosNousPorCpf,
      );
      final papelTexto = membro.papel.name.toUpperCase();
      final subMembro = uMembro?.usernameExibicao.isNotEmpty == true
          ? '${uMembro!.usernameExibicao} • Equipe ($papelTexto)'
          : 'Equipe • $papelTexto';

      final nomeMembroSoberano = uMembro?.nomeExibicao.isNotEmpty == true
          ? uMembro!.nomeExibicao
          : membro.nome;

      contatosUnificados[cpfMembro] = InfoContatoUnificado(
        identificador: membro.cpf,
        cpfNormalizado: cpfMembro,
        titulo: ehProprioOperador ? '$nomeMembroSoberano (Você)' : nomeMembroSoberano,
        subtitulo: subMembro,
        foto: fotoMembro,
        ehMembro: true,
        ehCliente: false,
      );
    }

    // 2. Clientes da loja
    for (final cliente in loja.clientesLoja) {
      final cpfCliente = ChatService.normalizarCpf(cliente.cnpj);
      if (cpfCliente.length == 11) {
        final ehProprioOperador = cpfCliente == cpfLogadoNorm;
        final uCliente = usuariosNousPorCpf[cpfCliente];
        final subCliente = uCliente?.usernameExibicao.isNotEmpty == true
            ? '${uCliente!.usernameExibicao} • Cliente'
            : (cliente.telefone.isNotEmpty
                ? '${cliente.telefone} | Cliente'
                : 'Cliente cadastrado');

        final nomeClienteSoberano = uCliente?.nomeExibicao.isNotEmpty == true
            ? uCliente!.nomeExibicao
            : cliente.nome;

        if (contatosUnificados.containsKey(cpfCliente)) {
          final existente = contatosUnificados[cpfCliente]!;
          final fotoResolvida = (existente.foto.isNotEmpty &&
                  ImagemService.existe(existente.foto))
              ? existente.foto
              : (cliente.foto.isNotEmpty ? cliente.foto : existente.foto);
          contatosUnificados[cpfCliente] = existente.copyWith(
            titulo: ehProprioOperador
                ? '$nomeClienteSoberano (Você)'
                : nomeClienteSoberano,
            foto: fotoResolvida,
            subtitulo: subCliente,
            ehCliente: true,
          );
        } else {
          var fotoCliente = cliente.foto;
          if (fotoCliente.isEmpty) {
            fotoCliente = ResolvedorFotoChat.instancia.resolverFotoSincrona(
              identificador: cliente.cnpj,
              auth: auth,
              pdv: pdv,
              mapaUsuarios: usuariosNousPorCpf,
            );
          }
          contatosUnificados[cpfCliente] = InfoContatoUnificado(
            identificador: cliente.cnpj,
            cpfNormalizado: cpfCliente,
            titulo: ehProprioOperador
                ? '$nomeClienteSoberano (Você)'
                : nomeClienteSoberano,
            subtitulo: subCliente,
            foto: fotoCliente,
            ehMembro: false,
            ehCliente: true,
          );
        }
      } else {
        final chave = 'cliente_${cliente.id}';
        contatosUnificados[chave] = InfoContatoUnificado(
          identificador: cliente.id,
          cpfNormalizado: '',
          titulo: cliente.nome,
          subtitulo: cliente.telefone.isNotEmpty
              ? cliente.telefone
              : 'Cliente cadastrado',
          foto: cliente.foto,
          ehMembro: false,
          ehCliente: true,
        );
      }
    }

    // 3. Atualizar dados soberanos dos contatos ou incluir usuários Nous com conversa aberta
    for (final u in todosUsuariosNous) {
      final cU = ChatService.normalizarCpf(u.cpf);
      if (cU.length != 11) continue;
      final convIdLoja = ChatService.conversaIdLojaUsuario(loja.id, cU);
      final idLimpo = loja.id.startsWith('loja_') ? loja.id.substring(5) : loja.id;
      final convIdAlt = 'loja_${idLimpo}_usuario_$cU';
      final temConversaAberta =
          persistidasMap.containsKey(convIdLoja) || persistidasMap.containsKey(convIdAlt);
      if (cU == cpfLogadoNorm && !temConversaAberta && !contatosUnificados.containsKey(cU)) {
        continue;
      }
      final fotoU = u.fotoExibicao.isNotEmpty ? u.fotoExibicao : u.foto;

      if (contatosUnificados.containsKey(cU)) {
        final ant = contatosUnificados[cU]!;
        final fotoMelhor = (ant.foto.isNotEmpty && ImagemService.existe(ant.foto))
            ? ant.foto
            : fotoU;
        final subMelhor = u.usernameExibicao.isNotEmpty && !ant.subtitulo.contains('@')
            ? '${u.usernameExibicao} • ${ant.subtitulo}'
            : ant.subtitulo;
        contatosUnificados[cU] = ant.copyWith(
          titulo: u.nomeExibicao.isNotEmpty ? u.nomeExibicao : ant.titulo,
          subtitulo: subMelhor,
          foto: fotoMelhor,
        );
      } else if (temConversaAberta) {
        contatosUnificados[cU] = InfoContatoUnificado(
          identificador: cU,
          cpfNormalizado: cU,
          titulo: u.nomeExibicao,
          subtitulo: u.usernameExibicao.isNotEmpty
              ? '${u.usernameExibicao} • Usuário Nous'
              : 'Usuário Nous',
          foto: fotoU,
          ehMembro: false,
          ehCliente: false,
        );
      }
    }

    // Montagem das conversas no modo Loja
    for (final c in contatosUnificados.values) {
      final convId = c.cpfNormalizado.isNotEmpty
          ? ChatService.conversaIdLojaUsuario(loja.id, c.cpfNormalizado)
          : 'loja_${loja.id}_cliente_${c.identificador}';

      var persistida = persistidasMap[convId];
      if (persistida == null && c.cpfNormalizado.isNotEmpty) {
        final idLimpo = loja.id.startsWith('loja_') ? loja.id.substring(5) : loja.id;
        final convIdAlt = 'loja_${idLimpo}_usuario_${c.cpfNormalizado}';
        persistida = persistidasMap[convIdAlt];
        if (persistida != null) {
          persistidasMap.remove(convIdAlt);
        }
      }
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

      final ultimaMsg = msgs.isNotEmpty
          ? MontadorConversasChat.resumoMensagem(msgs.last)
          : ((persistida != null && persistida.ultimaMensagem.isNotEmpty)
                ? persistida.ultimaMensagem
                : (c.ehMembro
                      ? 'Canal direto da equipe com a loja.'
                      : 'Comandas e mensagens da loja.'));

      final dataHoraUltima = msgs.isNotEmpty
          ? msgs.last.dataHora
          : (persistida?.dataHoraUltimaMensagem ??
              DateTime.fromMillisecondsSinceEpoch(0));

      final nomeResolvido = c.titulo.isNotEmpty && c.titulo != 'Conversa'
          ? c.titulo
          : (c.subtitulo.isNotEmpty && c.subtitulo != 'Conversa'
                ? c.subtitulo
                : 'Contato');

      final conversa = ConversaChat(
        id: convId,
        titulo: titulosCustomizados[convId] ?? nomeResolvido,
        subtitulo: c.subtitulo,
        foto: c.foto,
        identificador: c.identificador,
        ehLoja: true,
        lojaId: loja.id,
        ultimaMensagem: ultimaMsg,
        dataHoraUltimaMensagem: dataHoraUltima,
        naoLidasCount: naoLidas,
        mensagens: msgs,
        fixada: fixada,
        arquivada: arquivada,
      );

      todosDisponiveis.add(conversa);
      persistidasMap.remove(convId);

      if (msgs.isNotEmpty || persistida != null || estaSelecionada) {
        lista.add(conversa);
      }
    }
  }
}
