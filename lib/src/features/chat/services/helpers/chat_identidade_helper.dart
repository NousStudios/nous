import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';

/// Helper para identidade local do cidadão, IDs canônicos de conversa e decifração E2EE.
class ChatIdentidadeHelper {
  ChatIdentidadeHelper._();

  static Future<String> obterCpfLogadoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cpf = prefs.getString('ultimo_cpf_login') ?? '';
      return ChatRepositorioSqlite.normalizarCpf(cpf);
    } catch (_) {
      return '';
    }
  }

  static String conversaIdLojaUsuario(String lojaId, String usuarioCpf) {
    final prefixo = lojaId.startsWith('loja_') ? lojaId : 'loja_$lojaId';
    return '${prefixo}_usuario_${ChatRepositorioSqlite.normalizarCpf(usuarioCpf)}';
  }

  static String conversaIdEntreUsuarios(String cpfA, String cpfB) {
    final c1 = ChatRepositorioSqlite.normalizarCpf(cpfA);
    final c2 = ChatRepositorioSqlite.normalizarCpf(cpfB);
    final lista = [c1, c2]..sort();
    return 'user_${lista[0]}_user_${lista[1]}';
  }

  static Future<List<MensagemChat>> carregarMensagens(
    String conversaId, {
    String? idVisualizador,
    int? limite,
    int? offset,
  }) async {
    final msgs = await ChatRepositorioSqlite.carregarMensagens(
      conversaId,
      idVisualizador: idVisualizador,
      limite: limite,
      offset: offset,
    );
    var cpfVis = ChatRepositorioSqlite.normalizarCpf(idVisualizador ?? '');
    if (cpfVis.length != 11) {
      cpfVis = ChatRepositorioSqlite.normalizarCpf(await obterCpfLogadoLocal());
    }
    if (cpfVis.length != 11) {
      return msgs;
    }
    return ChatE2eeService.decifrarListaMensagens(
      msgs,
      cpfVisualizador: cpfVis,
    );
  }
}
