import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Metadados consolidados e validados de uma conversa para exibição e persistência.
class MetadadosConversaInfo {
  final String titulo;
  final String subtitulo;
  final String foto;
  final String identificador;
  final bool ehLoja;
  final bool ehGrupo;
  final String? lojaId;

  const MetadadosConversaInfo({
    required this.titulo,
    required this.subtitulo,
    required this.foto,
    required this.identificador,
    required this.ehLoja,
    required this.ehGrupo,
    this.lojaId,
  });
}

/// Serviço especialista na resolução de metadados de conversas, garantindo fidelidade
/// na identificação de perfis sociais (@username, foto e nome), lojas e grupos.
class ResolvedorConversaInfoService {
  /// Resolve com segurança os metadados cadastrais de uma conversa a partir de uma mensagem.
  static Future<MetadadosConversaInfo> resolverMetadadosParaMensagem(
    MensagemChat mensagem, {
    String? cpfLogado,
  }) async {
    final ehLoja = mensagem.conversaId.startsWith('loja_');
    final ehGrupo = mensagem.conversaId.startsWith('grupo_');
    String? lojaId;

    if (ehLoja) {
      final partes = mensagem.conversaId.split('_');
      if (partes.length >= 2) {
        lojaId = partes[1];
      }
    }

    String tituloConversa = ehGrupo ? 'Grupo' : '';
    String subtituloConversa = ehLoja ? 'Loja Nous' : 'Contato Nous';
    String fotoConversa = '';
    String identificadorConversa = mensagem.destinatarioId;
    String cpfUsuario = '';

    if (!ehGrupo && !ehLoja) {
      // Conversa direta entre dois usuários Nous (Rede Social / P2P)
      final cpfLogadoNorm = cpfLogado != null
          ? ChatRepositorioSqlite.normalizarCpf(cpfLogado)
          : '';
      var outroCpf =
          ChatRepositorioSqlite.normalizarCpf(mensagem.destinatarioId);
      if (outroCpf.length != 11 ||
          (cpfLogadoNorm.isNotEmpty && outroCpf == cpfLogadoNorm)) {
        outroCpf = ChatRepositorioSqlite.extrairOutroCpf(
          mensagem.conversaId,
          cpfLogadoNorm.isNotEmpty ? cpfLogadoNorm : mensagem.remetenteId,
        );
      }

      if (outroCpf.length == 11) {
        identificadorConversa = outroCpf;
        final conta = await ContasNousService.buscarPorCpf(outroCpf);
        if (conta != null) {
          tituloConversa = conta.nomeExibicao;
          subtituloConversa = conta.usernameExibicao.isNotEmpty
              ? conta.usernameExibicao
              : 'Usuário Nous';
          fotoConversa = conta.fotoExibicao;
        } else if (mensagem.remetenteNome.isNotEmpty &&
            mensagem.remetenteId == outroCpf) {
          tituloConversa = mensagem.remetenteNome;
          fotoConversa = mensagem.remetenteFoto;
        }
      }
    } else if (ehLoja) {
      // Conversa comercial de Loja com Usuário/Cliente
      if (mensagem.conversaId.contains('_usuario_')) {
        cpfUsuario = ChatRepositorioSqlite.normalizarCpf(
          mensagem.conversaId.split('_usuario_').last,
        );
      }

      final meuCpfNorm = cpfLogado != null
          ? ChatRepositorioSqlite.normalizarCpf(cpfLogado)
          : '';
      final usuarioLogadoEhOCliente =
          meuCpfNorm.isNotEmpty && meuCpfNorm == cpfUsuario;

      if (usuarioLogadoEhOCliente && lojaId != null) {
        // O usuário logado é o CLIENTE falando com a Loja: o interlocutor exibido é a LOJA!
        final loja = await LojasService.carregarLojaPorId(lojaId);
        if (loja != null) {
          tituloConversa = loja.nome;
          subtituloConversa = 'Loja';
          fotoConversa = loja.logo;
          identificadorConversa = loja.id;
        }
      } else if (cpfUsuario.length == 11) {
        // O usuário logado é o lojista/atendente falando com o CLIENTE: o interlocutor exibido é o CLIENTE!
        identificadorConversa = cpfUsuario;
        final conta = await ContasNousService.buscarPorCpf(cpfUsuario);
        if (conta != null) {
          tituloConversa = conta.nomeExibicao;
          subtituloConversa = conta.usernameExibicao.isNotEmpty
              ? conta.usernameExibicao
              : 'Cliente Nous';
          fotoConversa = conta.fotoExibicao;
        }
      }

      if (tituloConversa.isEmpty && mensagem.remetenteId != lojaId) {
        tituloConversa = mensagem.remetenteNome;
        identificadorConversa = mensagem.remetenteId;
      }
    }

    if (tituloConversa.isEmpty) {
      tituloConversa = ehGrupo ? 'Grupo' : 'Contato Nous';
    }

    final ehContatoLoja = ehLoja && cpfUsuario.isEmpty;

    return MetadadosConversaInfo(
      titulo: tituloConversa,
      subtitulo: subtituloConversa,
      foto: fotoConversa,
      identificador: identificadorConversa,
      ehLoja: ehContatoLoja,
      ehGrupo: ehGrupo,
      lojaId: lojaId,
    );
  }
}
