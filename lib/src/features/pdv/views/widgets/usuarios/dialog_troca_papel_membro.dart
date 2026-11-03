import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

String _rotuloPapel(PapelMembro papel) {
  switch (papel) {
    case PapelMembro.dono:
      return 'Dono';
    case PapelMembro.socio:
      return 'Sócio';
    case PapelMembro.admin:
      return 'Admin';
    case PapelMembro.funcionario:
      return 'Funcionário';
  }
}

/// Diálogo para alteração do papel operacional e vinculação de cargo personalizado de um membro.
class DialogTrocaPapelMembro {
  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required MembroLoja membro,
    required List<MembroLoja> membros,
    required List<CargoLoja> cargosPersonalizados,
    required String cpfLogado,
    required void Function(String cpf, PapelMembro papel) onAtualizarPapel,
    required void Function(String cpf, String? cargoId)? onVincularCargoPersonalizado,
    required void Function(String mensagem) onAviso,
  }) {
    final meuMembro = membros.firstWhere(
      (m) => m.cpf == cpfLogado,
      orElse: () => MembroLoja(
        cpf: cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDonoOuSocio =
        meuMembro.papel == PapelMembro.dono || meuMembro.papel == PapelMembro.socio;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Cargo e Papel de ${membro.nome}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Papel Operacional:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                for (final papel in PapelMembro.values)
                  ListTile(
                    dense: true,
                    title: Text(
                      _rotuloPapel(papel),
                      style: theme.getTextStyle(
                        color: papel == membro.papel
                            ? theme.textColor
                            : theme.secondaryTextColor,
                        fontWeight: papel == membro.papel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: papel == membro.papel
                        ? Icon(Icons.check, color: theme.textColor, size: 18)
                        : null,
                    onTap: () {
                      if (!souDonoOuSocio &&
                          (papel == PapelMembro.dono ||
                              papel == PapelMembro.socio)) {
                        onAviso(
                          'Apenas Donos e Sócios podem promover membros a Dono ou Sócio.',
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      onAtualizarPapel(membro.cpf, papel);
                    },
                  ),
                if (cargosPersonalizados.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cargo Criado na Loja:',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Nenhum cargo criado',
                      style: theme.getTextStyle(
                        color: membro.cargoPersonalizadoId == null
                            ? theme.textColor
                            : theme.secondaryTextColor,
                        fontWeight: membro.cargoPersonalizadoId == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: membro.cargoPersonalizadoId == null
                        ? Icon(Icons.check, color: theme.textColor, size: 18)
                        : null,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onVincularCargoPersonalizado?.call(membro.cpf, null);
                    },
                  ),
                  for (final cargo in cargosPersonalizados)
                    ListTile(
                      dense: true,
                      title: Text(
                        cargo.nome,
                        style: theme.getTextStyle(
                          color: membro.cargoPersonalizadoId == cargo.id
                              ? theme.textColor
                              : theme.secondaryTextColor,
                          fontWeight: membro.cargoPersonalizadoId == cargo.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: membro.cargoPersonalizadoId == cargo.id
                          ? Icon(Icons.check, color: theme.textColor, size: 18)
                          : null,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onVincularCargoPersonalizado?.call(membro.cpf, cargo.id);
                      },
                    ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
