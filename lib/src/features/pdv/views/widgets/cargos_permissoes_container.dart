import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';

class CargosEPermissoesContainer extends StatefulWidget {
  final AppTheme theme;
  final List<CargoLoja> cargosPersonalizados;
  final bool podeGerenciar;
  final ValueChanged<CargoLoja>? onAdicionarCargo;
  final ValueChanged<CargoLoja>? onAtualizarCargo;
  final ValueChanged<String>? onRemoverCargo;

  const CargosEPermissoesContainer({
    super.key,
    required this.theme,
    required this.cargosPersonalizados,
    required this.podeGerenciar,
    this.onAdicionarCargo,
    this.onAtualizarCargo,
    this.onRemoverCargo,
  });

  @override
  State<CargosEPermissoesContainer> createState() =>
      _CargosEPermissoesContainerState();
}

class _CargosEPermissoesContainerState
    extends State<CargosEPermissoesContainer> {
  bool _expandido = false;
  String _abaSelecionadaId = 'dono';

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho colapsável
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cargos e Permissões',
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.borderColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${4 + widget.cargosPersonalizados.length}',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transparência de papéis e regras ativas da loja',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.textColor,
                  ),
                ],
              ),
            ),
          ),

          if (_expandido) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: theme.borderColor.withValues(alpha: 0.3),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra de abas (Estilo Discord)
                  _construirBarraAbas(theme),
                  const SizedBox(height: 16),
                  // Conteúdo do cargo selecionado
                  _construirPainelCargo(theme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirBarraAbas(AppTheme theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _itemAba(
            id: 'dono',
            titulo: 'Dono',
            icone: Icons.workspace_premium_outlined,
            ehNativo: true,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'socio',
            titulo: 'Sócio',
            icone: Icons.handshake_outlined,
            ehNativo: true,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'admin',
            titulo: 'Administrador',
            icone: Icons.security_outlined,
            ehNativo: true,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'funcionario',
            titulo: 'Funcionário',
            icone: Icons.badge_outlined,
            ehNativo: true,
            theme: theme,
          ),
          for (final cargo in widget.cargosPersonalizados) ...[
            const SizedBox(width: 8),
            _itemAba(
              id: cargo.id,
              titulo: cargo.nome,
              icone: Icons.tag_rounded,
              ehNativo: false,
              theme: theme,
            ),
          ],
          if (widget.podeGerenciar) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.8),
                  style: BorderStyle.solid,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _abrirDialogNovoCargo(theme),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Novo Cargo',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemAba({
    required String id,
    required String titulo,
    required IconData icone,
    required bool ehNativo,
    required AppTheme theme,
  }) {
    final selecionado = _abaSelecionadaId == id;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _abaSelecionadaId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.15)
              : theme.backgroundColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.4),
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 15,
              color: selecionado ? theme.textColor : theme.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                color: selecionado ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPainelCargo(AppTheme theme) {
    final ehNativo = ['dono', 'socio', 'admin', 'funcionario']
        .contains(_abaSelecionadaId);
    final cargoPersonalizado = widget.cargosPersonalizados
        .where((c) => c.id == _abaSelecionadaId)
        .firstOrNull;

    final String nomeCargo;
    final String descricaoCargo;

    if (ehNativo) {
      switch (_abaSelecionadaId) {
        case 'dono':
          nomeCargo = 'Dono';
          descricaoCargo =
              'Fundador e titular do cofre. Possui acesso total inalterável e não pode ser excluído por terceiros.';
          break;
        case 'socio':
          nomeCargo = 'Sócio';
          descricaoCargo =
              'Co-gestor pleno. Possui acesso total e alterações em seu papel exigem consentimento mútuo.';
          break;
        case 'admin':
          nomeCargo = 'Administrador';
          descricaoCargo =
              'Responsável operacional pela loja, catálogo de produtos, impressora, financeiro e pagamentos.';
          break;
        case 'funcionario':
        default:
          nomeCargo = 'Funcionário';
          descricaoCargo =
              'Operador do PDV. Acesso às vendas e ao módulo financeiro por transparência radical da autogestão.';
          break;
      }
    } else {
      nomeCargo = cargoPersonalizado?.nome ?? 'Cargo';
      descricaoCargo =
          'Cargo customizado com permissões flexíveis definidas pela equipe da loja.';
    }

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
          // Topo do cargo selecionado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nomeCargo,
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
                            ehNativo ? 'Cargo Nativo' : 'Personalizado',
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
                      descricaoCargo,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!ehNativo && widget.podeGerenciar && cargoPersonalizado != null) ...[
                IconButton(
                  tooltip: 'Renomear cargo',
                  icon: Icon(Icons.edit_outlined, size: 18, color: theme.textColor),
                  onPressed: () => _abrirDialogRenomearCargo(
                    theme,
                    cargoPersonalizado,
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir cargo',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmarExcluirCargo(
                    theme,
                    cargoPersonalizado,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.borderColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          // Lista de permissões
          for (final perm in PermissaoLojaConst.todas) ...[
            _construirCardPermissao(
              theme: theme,
              perm: perm,
              ehNativo: ehNativo,
              cargoPersonalizado: cargoPersonalizado,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _construirCardPermissao({
    required AppTheme theme,
    required PermissaoInfo perm,
    required bool ehNativo,
    required CargoLoja? cargoPersonalizado,
  }) {
    final bool ativa;
    if (ehNativo) {
      ativa = _permissaoNativaAtiva(_abaSelecionadaId, perm.chave);
    } else {
      ativa = cargoPersonalizado?.temPermissao(perm.chave) ?? false;
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
                if (ehNativo) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Regra fundamental do sistema (inalterável)',
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
            onChanged: (!ehNativo && widget.podeGerenciar && cargoPersonalizado != null)
                ? (novoValor) {
                    final novasPerms =
                        Map<String, bool>.from(cargoPersonalizado.permissoes);
                    novasPerms[perm.chave] = novoValor;
                    final atualizado =
                        cargoPersonalizado.copyWith(permissoes: novasPerms);
                    widget.onAtualizarCargo?.call(atualizado);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  bool _permissaoNativaAtiva(String papelId, String chave) {
    if (papelId == 'dono') return true;
    if (papelId == 'socio') return true;
    if (papelId == 'admin') {
      return chave == PermissaoLojaConst.editarAbaLoja ||
          chave == PermissaoLojaConst.usarImpressora ||
          chave == PermissaoLojaConst.usarFinanceiro ||
          chave == PermissaoLojaConst.registrarPagamento;
    }
    if (papelId == 'funcionario') {
      return chave == PermissaoLojaConst.usarFinanceiro;
    }
    return false;
  }

  IconData _iconeDaPermissao(String chave) {
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
      case PermissaoLojaConst.excluirLoja:
        return Icons.delete_forever_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  void _abrirDialogNovoCargo(AppTheme theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Novo Cargo',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dê um nome para o novo cargo (ex: Gerente, Garçom, Cozinheiro, Entregador):',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: theme.getTextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nome do cargo...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final nome = controller.text.trim();
                if (nome.isEmpty) return;
                final novoCargo = CargoLoja(
                  id: 'cargo_${DateTime.now().millisecondsSinceEpoch}',
                  nome: nome,
                  permissoes: {
                    PermissaoLojaConst.usarFinanceiro: true,
                  },
                );
                widget.onAdicionarCargo?.call(novoCargo);
                setState(() => _abaSelecionadaId = novoCargo.id);
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Criar Cargo',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirDialogRenomearCargo(AppTheme theme, CargoLoja cargo) {
    final controller = TextEditingController(text: cargo.nome);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Renomear Cargo',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: theme.getTextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Novo nome...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
              ),
              onPressed: () {
                final nome = controller.text.trim();
                if (nome.isEmpty) return;
                widget.onAtualizarCargo?.call(cargo.copyWith(nome: nome));
                Navigator.pop(dialogContext);
              },
              child: Text('Salvar', style: theme.getTextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _confirmarExcluirCargo(AppTheme theme, CargoLoja cargo) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent),
          ),
          title: Text(
            'Excluir Cargo',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: Text(
            'Deseja excluir o cargo "${cargo.nome}"? Os membros que possuem esse cargo voltarão ao papel nativo padrão.',
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                widget.onRemoverCargo?.call(cargo.id);
                setState(() => _abaSelecionadaId = 'dono');
                Navigator.pop(dialogContext);
              },
              child: Text('Excluir', style: theme.getTextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );
  }
}
