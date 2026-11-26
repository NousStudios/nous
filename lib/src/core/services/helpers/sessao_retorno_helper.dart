import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/sessao_retorno_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

class SessaoRetornoHelper {
  SessaoRetornoHelper._();

  /// Tenta restaurar a sessão do usuário caso o app tenha sido reiniciado após uma atualização.
  /// Retorna true se uma sessão prévia foi restaurada com sucesso.
  static Future<bool> tentarRestaurarSessao(BuildContext context) async {
    try {
      final sessao = await SessaoRetornoService.recuperarSessao();
      if (sessao == null) return false;

      // Limpa imediatamente o arquivo para evitar loops caso ocorra algum erro na navegação
      await SessaoRetornoService.limparSessao();

      if (!context.mounted) return false;

      final auth = context.read<AuthProvider>();
      final pdv = context.read<PdvProvider>();
      final notif = context.read<NotificacoesProvider>();

      if (sessao.modoVisitante) {
        auth.entrarComoVisitante();
        await pdv.entrarComoVisitante();
        notif.limpar();

        if (!context.mounted) return true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PerfisPdvView()),
          (route) => false,
        );
        return true;
      }

      final cpf = sessao.cpf.trim();
      if (cpf.isEmpty) return false;

      // Restaura o usuário e sincroniza com o banco local
      auth.updateCpf(cpf);
      await auth.buscarConta();
      await auth.salvarUltimoCpf(cpf);
      await notif.carregarParaCpf(cpf);
      await pdv.entrarComCpf(cpf);

      if (!context.mounted) return true;

      // Se o operador estava gerenciando uma loja específica, reabre diretamente a loja
      if (sessao.lojaId != null && sessao.lojaId!.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DadosPerfilView(
              lojaId: sessao.lojaId!,
              abaInicial: AbaLoja.gestao,
            ),
          ),
          (route) => false,
        );
      } else {
        // Caso contrário, abre a central de perfis/lojas
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PerfisPdvView()),
          (route) => false,
        );
      }

      debugPrint(
        '[SessaoRetornoHelper] Sessão restaurada com sucesso para o CPF: $cpf (Loja: ${sessao.lojaId})',
      );
      return true;
    } catch (e) {
      debugPrint('[SessaoRetornoHelper] Erro ao tentar restaurar sessão: $e');
      return false;
    }
  }
}
