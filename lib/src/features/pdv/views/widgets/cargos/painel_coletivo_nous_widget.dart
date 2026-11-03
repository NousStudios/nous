import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Painel específico de cargos e papéis para a loja coletiva Nous.
class PainelColetivoNousWidget extends StatelessWidget {
  final AppTheme theme;
  final String abaSelecionadaId;
  final bool usuarioLogadoEhDesenvolvedor;
  final VoidCallback? onAlternarDesenvolvedor;

  const PainelColetivoNousWidget({
    super.key,
    required this.theme,
    required this.abaSelecionadaId,
    required this.usuarioLogadoEhDesenvolvedor,
    this.onAlternarDesenvolvedor,
  });

  @override
  Widget build(BuildContext context) {
    final ehDesenvolvedor = abaSelecionadaId == 'desenvolvedor';
    final titulo = ehDesenvolvedor ? 'Desenvolvedor' : 'Sócio';
    final badge = ehDesenvolvedor ? 'Função Requisitada' : 'Papel Coletivo';
    final descricao = ehDesenvolvedor
        ? 'Função requisitada pelo próprio usuário para sinalizar que faz parte da equipe de desenvolvimento do ecossistema Nous. Não concede privilégios sobre outros membros.'
        : 'Na comunidade Nous, todos os participantes são sócios em regime de autogestão plena e horizontalidade absoluta. Ninguém é dono de ninguém.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.borderColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          if (ehDesenvolvedor) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    usuarioLogadoEhDesenvolvedor
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: usuarioLogadoEhDesenvolvedor
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      usuarioLogadoEhDesenvolvedor
                          ? 'Você está identificado como Desenvolvedor da equipe Nous.'
                          : 'Você pode requisitar a identificação de Desenvolvedor a qualquer momento.',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAlternarDesenvolvedor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: usuarioLogadoEhDesenvolvedor
                      ? theme.dangerColor.withValues(alpha: 0.15)
                      : theme.textColor,
                  foregroundColor: usuarioLogadoEhDesenvolvedor
                      ? theme.dangerColor
                      : theme.backgroundColor,
                  side: usuarioLogadoEhDesenvolvedor
                      ? BorderSide(
                          color: theme.dangerColor.withValues(alpha: 0.6))
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  usuarioLogadoEhDesenvolvedor
                      ? Icons.person_remove_outlined
                      : Icons.code_rounded,
                  size: 18,
                ),
                label: Text(
                  usuarioLogadoEhDesenvolvedor
                      ? 'Deixar de ser um desenvolvedor'
                      : 'Se tornar Desenvolvedor',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: usuarioLogadoEhDesenvolvedor
                        ? theme.dangerColor
                        : theme.backgroundColor,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Todos os usuários cadastrados no Nous têm a condição de Sócio no perfil coletivo. Todos têm voz, acesso transparente aos dados e participação igualitária.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
