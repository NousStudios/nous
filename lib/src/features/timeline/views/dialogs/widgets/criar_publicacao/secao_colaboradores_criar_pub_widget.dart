import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

class SecaoColaboradoresCriarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final bool expandido;
  final TextEditingController buscaCtrl;
  final List<UsuarioNous> todosUsuarios;
  final List<UsuarioNous> selecionados;
  final VoidCallback onAlternarExpandido;
  final VoidCallback onBuscaAlterada;
  final ValueChanged<UsuarioNous> onRemoverCoautor;
  final ValueChanged<UsuarioNous> onAlternarCoautor;

  const SecaoColaboradoresCriarPubWidget({
    super.key,
    required this.theme,
    required this.expandido,
    required this.buscaCtrl,
    required this.todosUsuarios,
    required this.selecionados,
    required this.onAlternarExpandido,
    required this.onBuscaAlterada,
    required this.onRemoverCoautor,
    required this.onAlternarCoautor,
  });

  @override
  Widget build(BuildContext context) {
    final filtroCoautor = buscaCtrl.text.trim().toLowerCase();
    final sugestoesCoautor = filtroCoautor.isEmpty
        ? const <UsuarioNous>[]
        : todosUsuarios
            .where(
              (u) =>
                  u.nomeExibicao.toLowerCase().contains(filtroCoautor) ||
                  u.usernameExibicao.toLowerCase().contains(filtroCoautor),
            )
            .take(5)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.person_add_alt_1_outlined,
            color: theme.textColor,
            size: 20,
          ),
          title: Text(
            'Marcar colaboradores',
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
          ),
          subtitle: selecionados.isNotEmpty
              ? Text(
                  '${selecionados.length} selecionado(s)',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                )
              : null,
          trailing: Icon(
            expandido ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
            color: theme.secondaryTextColor,
          ),
          onTap: onAlternarExpandido,
        ),
        if (expandido) ...[
          ThemedTextField(
            theme: theme,
            controller: buscaCtrl,
            label: 'Buscar usuário por nome ou @',
            onChanged: (_) => onBuscaAlterada(),
          ),
          if (selecionados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selecionados.map((u) {
                return Chip(
                  label: Text(
                    u.nomeExibicao,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                  onDeleted: () => onRemoverCoautor(u),
                );
              }).toList(),
            ),
          ],
          if (sugestoesCoautor.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sugestoesCoautor.map((u) {
                final jaTem = selecionados.any((c) => c.cpf == u.cpf);
                return ActionChip(
                  label: Text(
                    '${jaTem ? "✓ " : "+ "}${u.nomeExibicao}',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                  onPressed: () => onAlternarCoautor(u),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}
