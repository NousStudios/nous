import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Auxilia na consolidação e unificação da ficha de Identidade do Usuário
/// no banco de contas local do balcão para novos terminais conectados.
class ConsolidadorContaTerminal {
  ConsolidadorContaTerminal._();

  static Future<void> consolidar({
    required TerminalConectadoInfo terminal,
    required Map<String, TerminalConectadoInfo> historicoTerminais,
    required ValueNotifier<List<TerminalConectadoInfo>> terminaisHistorico,
  }) async {
    if (terminal.ip.isNotEmpty) {
      historicoTerminais[terminal.ip] = terminal;
      terminaisHistorico.value = historicoTerminais.values.toList();
    }
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty) return;

    try {
      final contaExistente =
          await ContasNousService.buscarPorCpf(terminal.cpf!);
      final dadosAuto =
          await DadosLocaisService.buscarPorDocumento(terminal.cpf!);

      String nome = (terminal.nomeUsuario != null &&
              terminal.nomeUsuario!.trim().isNotEmpty)
          ? terminal.nomeUsuario!.trim()
          : '';
      // Hardware NUNCA é identidade do cidadão: ignora nomes de aparelhos
      if (nome.isEmpty ||
          nome.toLowerCase() == 'blackview' ||
          nome.toLowerCase() == 'celular') {
        nome = (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty)
            ? dadosAuto.nome.trim()
            : 'Usuário Nous';
      }

      final apelido = (terminal.apelido != null &&
              terminal.apelido!.trim().isNotEmpty &&
              terminal.apelido!.toLowerCase() != 'blackview')
          ? terminal.apelido!.trim()
          : '';

      if (contaExistente == null) {
        final novaConta = UsuarioNous(
          cpf: terminal.cpf!,
          nome: nome,
          apelido: apelido.isNotEmpty
              ? apelido
              : (dadosAuto?.apelido ?? (dadosAuto?.nome ?? nome)),
          dataNascimento: dadosAuto?.dataNascimento ?? '',
          foto: dadosAuto?.foto ?? '',
        );
        await ContasNousService.salvar(novaConta);
        debugPrint(
          '[ConsolidadorContaTerminal] Ficha de conta unificada no balcão para CPF $cpfLimpo (${novaConta.nome})',
        );
      } else {
        var atualizada = contaExistente;
        // Corrige se a conta no banco estava com nome espúrio de aparelho
        if (contaExistente.nome.isEmpty ||
            contaExistente.nome.toLowerCase() == 'blackview') {
          atualizada = atualizada.copyWith(nome: nome);
        }
        if (apelido.isNotEmpty &&
            contaExistente.apelido != apelido &&
            contaExistente.apelido.toLowerCase() != 'blackview') {
          atualizada = atualizada.copyWith(apelido: apelido);
        }
        if (contaExistente.foto.isEmpty &&
            dadosAuto != null &&
            dadosAuto.foto.isNotEmpty &&
            ImagemService.existe(dadosAuto.foto)) {
          atualizada = atualizada.copyWith(foto: dadosAuto.foto);
        }
        if (atualizada != contaExistente) {
          await ContasNousService.salvar(atualizada);
        }
      }
    } catch (e) {
      debugPrint('[ConsolidadorContaTerminal] Erro ao consolidar conta de terminal: $e');
    }
  }
}
