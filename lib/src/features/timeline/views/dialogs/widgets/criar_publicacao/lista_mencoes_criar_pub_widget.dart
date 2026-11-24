import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

class ListaMencoesCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final String termoMencao;
  final List<UsuarioNous> todasContas;
  final ValueChanged<UsuarioNous> onSelecionarUsuario;

  const ListaMencoesCriarPubWidget({
    super.key,
    required this.theme,
    required this.termoMencao,
    required this.todasContas,
    required this.onSelecionarUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final filtrados = todasContas.where((c) {
      final nome = c.nomeExibicao.toLowerCase();
      final user = c.nomeDeUsuario.toLowerCase().replaceAll('@', '');
      if (termoMencao.isEmpty) return user.isNotEmpty;
      return nome.contains(termoMencao) || user.contains(termoMencao);
    }).take(6).toList();

    if (filtrados.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 170),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.45),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtrados.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: theme.borderColor.withValues(alpha: 0.2),
        ),
        itemBuilder: (_, idx) {
          final conta = filtrados[idx];
          final handle = conta.usernameExibicao.isNotEmpty
              ? conta.usernameExibicao
              : '@${conta.nomeDeUsuario}';
          return InkWell(
            onTap: () => onSelecionarUsuario(conta),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.18),
                    child: Text(
                      conta.nomeExibicao.isNotEmpty
                          ? conta.nomeExibicao[0].toUpperCase()
                          : '@',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conta.nomeExibicao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    handle,
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
