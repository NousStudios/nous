import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Dados de identidade resolvidos para o usuário da mensageria.
class IdentidadeMensageriaResolvida {
  final String? usuarioCpf;
  final String? usuarioNome;
  final String? usuarioFoto;
  final String? usuarioApelido;

  const IdentidadeMensageriaResolvida({
    this.usuarioCpf,
    this.usuarioNome,
    this.usuarioFoto,
    this.usuarioApelido,
  });
}

/// Parâmetros resolvidos para abertura automática da conversa inicial.
class AlvoConversaInicial {
  final String convId;
  final String titulo;
  final String subtitulo;
  final String identificador;
  final String foto;
  final bool ehLoja;

  const AlvoConversaInicial({
    required this.convId,
    required this.titulo,
    required this.subtitulo,
    required this.identificador,
    required this.foto,
    required this.ehLoja,
  });
}

/// Helper responsável pela inicialização de identidade, conversa inicial e
/// sincronização periódica com a rede local.
class MensageriaInicializacaoHelper {
  const MensageriaInicializacaoHelper._();

  static Future<String?> resolverCpfUsuario({
    required AuthProvider auth,
    required PdvProvider pdv,
    String? usuarioCpf,
    bool Function()? deveCancelar,
  }) async {
    if (usuarioCpf != null && usuarioCpf.trim().isNotEmpty) {
      return usuarioCpf;
    }
    final cpfCandidato = auth.contaAtual?.cpf ??
        (auth.cpf.trim().isNotEmpty
            ? auth.cpf.trim()
            : (pdv.cpfAtual?.trim() ?? ''));
    if (cpfCandidato.isNotEmpty) return cpfCandidato;
    final cpfLocal = await ChatService.obterCpfLogadoLocal();
    if (deveCancelar?.call() == true) return usuarioCpf;
    return cpfLocal.isNotEmpty ? cpfLocal : usuarioCpf;
  }

  static Future<IdentidadeMensageriaResolvida> resolverIdentidadeUsuario({
    required AuthProvider auth,
    required PdvProvider pdv,
    String? usuarioCpf,
    String? usuarioNome,
    String? usuarioFoto,
    String? usuarioApelido,
    bool Function()? isDisposed,
  }) async {
    final conta = auth.contaAtual;
    var cpfResolvido = usuarioCpf;
    var nomeResolvido = usuarioNome;
    var fotoResolvida = usuarioFoto;
    var apelidoResolvido = usuarioApelido;

    if (cpfResolvido == null || cpfResolvido.trim().isEmpty) {
      final cpfCandidato = conta?.cpf ??
          (auth.cpf.trim().isNotEmpty
              ? auth.cpf.trim()
              : (pdv.cpfAtual?.trim() ?? ''));
      if (cpfCandidato.isNotEmpty) {
        cpfResolvido = cpfCandidato;
      } else {
        final cpfLocal = await ChatService.obterCpfLogadoLocal();
        if (isDisposed?.call() == true) {
          return IdentidadeMensageriaResolvida(
            usuarioCpf: cpfResolvido,
            usuarioNome: nomeResolvido,
            usuarioFoto: fotoResolvida,
            usuarioApelido: apelidoResolvido,
          );
        }
        if (cpfLocal.isNotEmpty) cpfResolvido = cpfLocal;
      }
    }

    if (nomeResolvido == null || nomeResolvido.isEmpty) {
      nomeResolvido = conta?.nomeExibicao ?? conta?.nome;
      if ((nomeResolvido == null || nomeResolvido.isEmpty) &&
          cpfResolvido != null &&
          cpfResolvido.isNotEmpty) {
        final u = auth.buscarContaPorCpf(cpfResolvido);
        if (u != null) {
          nomeResolvido = u.nomeExibicao.isNotEmpty ? u.nomeExibicao : u.nome;
          fotoResolvida ??= u.fotoExibicao.isNotEmpty ? u.fotoExibicao : u.foto;
          apelidoResolvido ??=
              u.apelidoExibicao.isNotEmpty ? u.apelidoExibicao : u.apelido;
        }
      }
    }

    if (fotoResolvida == null || fotoResolvida.isEmpty) {
      fotoResolvida = conta?.fotoExibicao ?? conta?.foto;
    }
    if (apelidoResolvido == null || apelidoResolvido.isEmpty) {
      apelidoResolvido = conta?.apelidoExibicao ?? conta?.apelido;
    }

    return IdentidadeMensageriaResolvida(
      usuarioCpf: cpfResolvido,
      usuarioNome: nomeResolvido,
      usuarioFoto: fotoResolvida,
      usuarioApelido: apelidoResolvido,
    );
  }

  static AlvoConversaInicial? resolverAlvoConversaInicial({
    required String idAlvo,
    required List<ConversaChat> conversas,
    required List<ConversaChat> todosContatosDisponiveis,
    required AuthProvider auth,
    required PdvProvider pdv,
    String? usuarioCpf,
  }) {
    final encontrada = conversas.cast<ConversaChat?>().firstWhere(
      (c) => c?.id == idAlvo || c?.identificador == idAlvo,
      orElse: () => todosContatosDisponiveis.cast<ConversaChat?>().firstWhere(
        (c) => c?.id == idAlvo || c?.identificador == idAlvo,
        orElse: () => null,
      ),
    );
    if (encontrada != null) {
      return AlvoConversaInicial(
        convId: encontrada.id,
        titulo: encontrada.titulo,
        subtitulo: encontrada.subtitulo,
        identificador: encontrada.identificador,
        foto: encontrada.foto,
        ehLoja: encontrada.ehLoja,
      );
    }

    if (idAlvo.startsWith('user_')) {
      final meuCpfLimpo = ChatService.normalizarCpf(
        usuarioCpf ?? auth.contaAtual?.cpf ?? '',
      );
      final outroCpfLimpo = ChatService.extrairOutroCpf(idAlvo, meuCpfLimpo);
      final contaAlvo = auth.buscarContaPorCpf(outroCpfLimpo);
      final tituloAlvo = contaAlvo?.nomeExibicao.isNotEmpty == true
          ? contaAlvo!.nomeExibicao
          : (contaAlvo?.nome.isNotEmpty == true
              ? contaAlvo!.nome
              : 'Usuário Nous');
      return AlvoConversaInicial(
        convId: idAlvo,
        titulo: tituloAlvo,
        subtitulo: contaAlvo?.usernameExibicao ?? '',
        identificador: outroCpfLimpo,
        foto: contaAlvo?.fotoExibicao ?? (contaAlvo?.foto ?? ''),
        ehLoja: false,
      );
    }

    if (idAlvo.startsWith('loja_')) {
      final idLojaExtraido = idAlvo.contains('_usuario_')
          ? idAlvo.substring(5, idAlvo.indexOf('_usuario_'))
          : idAlvo.substring(5);
      final lojaAlvo = pdv.buscarPorId(idLojaExtraido) ??
          (ClienteRedeLocal().lojaSincronizada?.id == idLojaExtraido
              ? ClienteRedeLocal().lojaSincronizada
              : null);
      return AlvoConversaInicial(
        convId: idAlvo,
        titulo: lojaAlvo?.nome ?? 'Loja',
        subtitulo: 'Loja',
        identificador: lojaAlvo?.id ?? idLojaExtraido,
        foto: lojaAlvo?.logo ?? '',
        ehLoja: true,
      );
    }

    return null;
  }

  static Future<void> abrirConversaInicialSeHouver({
    required String? conversaInicialId,
    required List<ConversaChat> conversas,
    required List<ConversaChat> todosContatosDisponiveis,
    required AuthProvider auth,
    required PdvProvider pdv,
    String? usuarioCpf,
    required Future<void> Function({
      required String convId,
      required String titulo,
      required String subtitulo,
      required String identificador,
      required String foto,
      required bool ehLoja,
    }) onAbrir,
  }) async {
    if (conversaInicialId == null || conversaInicialId.isEmpty) return;
    final alvo = resolverAlvoConversaInicial(
      idAlvo: conversaInicialId,
      conversas: conversas,
      todosContatosDisponiveis: todosContatosDisponiveis,
      auth: auth,
      pdv: pdv,
      usuarioCpf: usuarioCpf,
    );
    if (alvo != null) {
      await onAbrir(
        convId: alvo.convId,
        titulo: alvo.titulo,
        subtitulo: alvo.subtitulo,
        identificador: alvo.identificador,
        foto: alvo.foto,
        ehLoja: alvo.ehLoja,
      );
    }
  }

  static void executarTickPolling({
    required AuthProvider auth,
    required bool modoLoja,
    String? lojaId,
    String? usuarioCpf,
  }) {
    ChatService.drenarFilaDeSaida();
    final cliente = ClienteRedeLocal();
    if (cliente.conectado &&
        cliente.ipServidor != null &&
        cliente.portaServidor != null) {
      final meuCpf = modoLoja ? null : (usuarioCpf ?? auth.contaAtual?.cpf);
      ChatService.sincronizarMensagensComBalcao(
        ipServidor: cliente.ipServidor!,
        portaServidor: cliente.portaServidor!,
        cpfUsuario: meuCpf,
        lojaId: modoLoja ? lojaId : null,
      );
    }
  }

  static void sincronizarComRedeLocal({
    required AuthProvider auth,
    required PdvProvider pdv,
    required bool modoLoja,
    String? lojaId,
    String? usuarioCpf,
    required bool Function() isDisposed,
    required VoidCallback onSincronizado,
  }) {
    if (isDisposed() || ServidorRedeLocal().ativo) return;
    final cliente = ClienteRedeLocal();
    final meuCpf = modoLoja ? null : (usuarioCpf ?? auth.contaAtual?.cpf);

    cliente.tentarAutoConectarSeDisponivel(pdv, auth).then((_) {
      if (isDisposed()) return;
      if (cliente.ipServidor != null && cliente.portaServidor != null) {
        cliente.reconciliarContasComServidor();
        ChatService.drenarFilaDeSaida();
        ChatService.sincronizarMensagensComBalcao(
          ipServidor: cliente.ipServidor!,
          portaServidor: cliente.portaServidor!,
          cpfUsuario: meuCpf,
          lojaId: modoLoja ? lojaId : null,
        ).then((_) {
          if (isDisposed()) return;
          onSincronizado();
        });
      }
    });
  }

  static void executarManutencaoSessao() {
    unawaited(() async {
      await ChatService.curarTimestampsAnomalosDoPassado();
      await ChatService.consolidarConversasDuplicadas();
    }());
  }
}
