import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/agora_digital_view.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_fila_validacao_identidades.dart';
import 'package:nous/src/features/pdv/views/gestao_financeira_nous_view.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/cards_atalhos_gestao_widget.dart';

/// Aba principal de Gestão do Perfil Profissional Nous.
/// Reúne os eixos de autogestão soberana: Status da Loja, Gestão Financeira,
/// Ágora Digital e Validação Popular de Identidades.
class AbaGestaoNousWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final String cpfLogado;
  final String nomeLogado;
  final String fotoLogada;
  final List<MembroLoja> membros;
  final VoidCallback onAbrirStatusLoja;

  const AbaGestaoNousWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cpfLogado,
    required this.nomeLogado,
    this.fotoLogada = '',
    required this.membros,
    required this.onAbrirStatusLoja,
  });

  @override
  State<AbaGestaoNousWidget> createState() => _AbaGestaoNousWidgetState();
}

class _AbaGestaoNousWidgetState extends State<AbaGestaoNousWidget> {
  @override
  void initState() {
    super.initState();
    ServidorRedeLocal().terminaisConectados.addListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.addListener(_aoAtualizarPresencas);
  }

  @override
  void dispose() {
    ServidorRedeLocal().terminaisConectados.removeListener(_aoAtualizarPresencas);
    ClienteRedeLocal().presencasAtivas.removeListener(_aoAtualizarPresencas);
    super.dispose();
  }

  void _aoAtualizarPresencas() {
    if (mounted) setState(() {});
  }

  int _obterContagemOnline() {
    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();
    final cpfs = <String>{};

    if (servidor.ativo) {
      for (final p in servidor.obterTodasPresencas()) {
        final cpfNorm = p.cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (cpfNorm.isNotEmpty) cpfs.add(cpfNorm);
      }
    } else if (cliente.conectado) {
      for (final p in cliente.presencasAtivas.value) {
        final cpfNorm = p.cpf?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (cpfNorm.isNotEmpty) cpfs.add(cpfNorm);
      }
    }

    final meuCpfNorm = widget.cpfLogado.replaceAll(RegExp(r'\D'), '');
    if (meuCpfNorm.isNotEmpty) {
      cpfs.add(meuCpfNorm);
    }

    return cpfs.isEmpty ? 1 : cpfs.length;
  }

  void _abrirGestaoFinanceira() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GestaoFinanceiraNousView(theme: widget.theme),
      ),
    );
  }

  void _abrirAgoraDigital() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgoraDigitalView(
          theme: widget.theme,
          cpfLogado: widget.cpfLogado,
          nomeLogado: widget.nomeLogado,
          fotoLogada: widget.fotoLogada,
        ),
      ),
    );
  }

  void _dialogFilaValidacaoIdentidades(AppTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => DialogFilaValidacaoIdentidades(
        theme: theme,
        cpfValidador: widget.cpfLogado,
        nomeValidador: widget.nomeLogado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final onlineCount = _obterContagemOnline();
    final textoOnline = onlineCount == 1 ? '1 membro online' : '$onlineCount membros online';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardsAtalhosGestaoWidget(
            theme: theme,
            textoOnline: textoOnline,
            onAbrirStatusLoja: widget.onAbrirStatusLoja,
            onAbrirGestao: _abrirGestaoFinanceira,
            onAbrirAgoraDigital: _abrirAgoraDigital,
            onAbrirFilaValidacao: () => _dialogFilaValidacaoIdentidades(theme),
          ),

          const SizedBox(height: 24),

          // Painel informativo sobre a Autogestão Nous
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: theme.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextoRolante(
                        texto: 'Perfil Coletivo & Autogestão Soberana',
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Este espaço é comum a todos os usuários do Nous. '
                  'Aqui organizamos o fundo coletivo do aplicativo, deliberamos melhorias na Ágora Digital '
                  'e fortalecemos a confiança da rede através da validação entre pares.',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
