import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

/// Card interativo para exibir e configurar uma permissão específica de um cargo.
class CardPermissaoLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final PermissaoInfo perm;
  final String abaSelecionadaId;
  final Map<String, Map<String, bool>> permissoesCargosNativos;
  final CargoLoja? cargoPersonalizado;
  final bool ehDonoOuSocio;
  final bool podeGerenciar;
  final void Function(String papel, Map<String, bool> permissoes)?
      onAtualizarPermissoesCargoNativo;
  final ValueChanged<CargoLoja>? onAtualizarCargo;

  const CardPermissaoLojaWidget({
    super.key,
    required this.theme,
    required this.perm,
    required this.abaSelecionadaId,
    required this.permissoesCargosNativos,
    required this.cargoPersonalizado,
    required this.ehDonoOuSocio,
    required this.podeGerenciar,
    this.onAtualizarPermissoesCargoNativo,
    this.onAtualizarCargo,
  });

  @override
  Widget build(BuildContext context) {
    final ehSoberano =
        abaSelecionadaId == 'dono' || abaSelecionadaId == 'socio';
    final ehNativoInferior =
        abaSelecionadaId == 'admin' || abaSelecionadaId == 'funcionario';

    final bool ativa;
    if (ehSoberano) {
      ativa = true;
    } else if (ehNativoInferior) {
      final customizadas = permissoesCargosNativos[abaSelecionadaId];
      if (customizadas != null && customizadas.containsKey(perm.chave)) {
        ativa = customizadas[perm.chave] ?? false;
      } else {
        ativa =
            Loja.permissoesPadraoPorPapel(abaSelecionadaId)[perm.chave] ??
                false;
      }
    } else {
      ativa = cargoPersonalizado?.temPermissao(perm.chave) ?? false;
    }

    final ValueChanged<bool>? onSwitchChanged;
    if (ehSoberano) {
      onSwitchChanged = null;
    } else if (ehNativoInferior) {
      // Sócios e Donos podem mudar todas as permissões de cargos inferiores nativos
      onSwitchChanged = ehDonoOuSocio
          ? (novoValor) {
              final mapaBase = permissoesCargosNativos[abaSelecionadaId] ??
                  Loja.permissoesPadraoPorPapel(abaSelecionadaId);
              final novoMapa = Map<String, bool>.from(mapaBase);
              novoMapa[perm.chave] = novoValor;
              onAtualizarPermissoesCargoNativo?.call(
                abaSelecionadaId,
                novoMapa,
              );
            }
          : null;
    } else {
      // Cargos personalizados criados
      onSwitchChanged = (podeGerenciar && cargoPersonalizado != null)
          ? (novoValor) {
              final novasPerms =
                  Map<String, bool>.from(cargoPersonalizado!.permissoes);
              novasPerms[perm.chave] = novoValor;
              final atualizado =
                  cargoPersonalizado!.copyWith(permissoes: novasPerms);
              onAtualizarCargo?.call(atualizado);
            }
          : null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ativa
              ? theme.textColor.withValues(alpha: 0.25)
              : theme.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _iconeDaPermissao(perm.chave),
            size: 20,
            color: ativa ? theme.textColor : theme.secondaryTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perm.titulo,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perm.descricao,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                if (ehSoberano) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Regra fundamental do sistema (inalterável)',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                ] else if (ehNativoInferior) ...[
                  const SizedBox(height: 2),
                  Text(
                    ehDonoOuSocio
                        ? 'Configurável por Sócios e Donos'
                        : 'Definido pela gestão da loja',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ThemedSwitch(
            theme: theme,
            value: ativa,
            onChanged: onSwitchChanged,
          ),
        ],
      ),
    );
  }

  static IconData _iconeDaPermissao(String chave) {
    switch (chave) {
      case PermissaoLojaConst.editarAbaLoja:
        return Icons.inventory_2_outlined;
      case PermissaoLojaConst.usarImpressora:
        return Icons.print_outlined;
      case PermissaoLojaConst.editarDadosLoja:
        return Icons.storefront_outlined;
      case PermissaoLojaConst.usarFinanceiro:
        return Icons.account_balance_wallet_outlined;
      case PermissaoLojaConst.registrarPagamento:
        return Icons.payments_outlined;
      case PermissaoLojaConst.gerenciarMembros:
        return Icons.people_alt_outlined;
      case PermissaoLojaConst.resetarTransacoes:
        return Icons.restart_alt_rounded;
      case PermissaoLojaConst.excluirLoja:
        return Icons.delete_forever_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}
