import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

/// Bloco que lista as lojas e coletivos que o usuário administra ou participa.
class BlocoLojasUsuario extends StatelessWidget {
  final AppTheme theme;
  final String cpfUsuario;
  final List<Loja> lojasAdmin;
  final List<Loja> lojasParticipa;
  final BoxDecoration decoracao;

  const BlocoLojasUsuario({
    super.key,
    required this.theme,
    required this.cpfUsuario,
    required this.lojasAdmin,
    required this.lojasParticipa,
    required this.decoracao,
  });

  String _obterCargoUsuarioNaLoja(Loja loja, String cpf) {
    final cpfDigitos = cpf.replaceAll(RegExp(r'\D'), '');
    for (final m in loja.membros) {
      if (m.cpf.replaceAll(RegExp(r'\D'), '') == cpfDigitos) {
        if (m.cargoPersonalizadoId != null &&
            m.cargoPersonalizadoId!.trim().isNotEmpty) {
          final cargoPers = loja.cargosPersonalizados
              .where((c) => c.id == m.cargoPersonalizadoId)
              .firstOrNull;
          if (cargoPers != null && cargoPers.nome.trim().isNotEmpty) {
            return cargoPers.nome.trim();
          }
        }
        switch (m.papel) {
          case PapelMembro.dono:
            return 'Dono';
          case PapelMembro.socio:
            return 'Sócio';
          case PapelMembro.admin:
            return 'Administrador';
          case PapelMembro.funcionario:
            return 'Funcionário';
        }
      }
    }
    if (loja.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == cpfDigitos) {
      return 'Dono';
    }
    return 'Membro';
  }

  Widget _linhaLoja(String nomeLoja, String cargo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              nomeLoja,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            cargo,
            textAlign: TextAlign.right,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Lojas e Coletivos',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          if (lojasAdmin.isEmpty && lojasParticipa.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Nenhuma loja associada neste dispositivo.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          else ...[
            if (lojasAdmin.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                child: Text(
                  'Administra:',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              for (final l in lojasAdmin)
                _linhaLoja(l.nome, _obterCargoUsuarioNaLoja(l, cpfUsuario)),
            ],
            if (lojasParticipa.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                child: Text(
                  'Participa:',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              for (final l in lojasParticipa)
                _linhaLoja(l.nome, _obterCargoUsuarioNaLoja(l, cpfUsuario)),
            ],
          ],
        ],
      ),
    );
  }
}
