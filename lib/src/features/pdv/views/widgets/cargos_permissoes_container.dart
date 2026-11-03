import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/cargos/card_permissao_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/cargos/dialogs_gerenciar_cargo.dart';
import 'package:nous/src/features/pdv/views/widgets/cargos/painel_coletivo_nous_widget.dart';

/// Container retrátil para transparência e gerenciamento de cargos e permissões da loja.
class CargosEPermissoesContainer extends StatefulWidget {
  final AppTheme theme;
  final List<CargoLoja> cargosPersonalizados;
  final Map<String, Map<String, bool>> permissoesCargosNativos;
  final bool podeGerenciar;
  final bool ehDonoOuSocio;
  final ValueChanged<CargoLoja>? onAdicionarCargo;
  final ValueChanged<CargoLoja>? onAtualizarCargo;
  final ValueChanged<String>? onRemoverCargo;
  final void Function(String papel, Map<String, bool> permissoes)?
      onAtualizarPermissoesCargoNativo;
  final bool ehLojaColetivaNous;
  final bool usuarioLogadoEhDesenvolvedor;
  final VoidCallback? onAlternarDesenvolvedor;

  const CargosEPermissoesContainer({
    super.key,
    required this.theme,
    required this.cargosPersonalizados,
    this.permissoesCargosNativos = const {},
    required this.podeGerenciar,
    this.ehDonoOuSocio = false,
    this.ehLojaColetivaNous = false,
    this.usuarioLogadoEhDesenvolvedor = false,
    this.onAlternarDesenvolvedor,
    this.onAdicionarCargo,
    this.onAtualizarCargo,
    this.onRemoverCargo,
    this.onAtualizarPermissoesCargoNativo,
  });

  @override
  State<CargosEPermissoesContainer> createState() =>
      _CargosEPermissoesContainerState();
}

class _CargosEPermissoesContainerState
    extends State<CargosEPermissoesContainer> {
  bool _expandido = false;
  late String _abaSelecionadaId;

  @override
  void initState() {
    super.initState();
    _abaSelecionadaId = widget.ehLojaColetivaNous ? 'socio' : 'dono';
  }

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
                                widget.ehLojaColetivaNous
                                    ? '2'
                                    : '${4 + widget.cargosPersonalizados.length}',
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
                          widget.ehLojaColetivaNous
                              ? 'Papel coletivo e funções da comunidade Nous'
                              : 'Transparência de papéis e regras ativas da loja',
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
                  // Barra de abas
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
    if (widget.ehLojaColetivaNous) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _itemAba(
              id: 'socio',
              titulo: 'Sócio',
              icone: Icons.handshake_outlined,
              theme: theme,
            ),
            const SizedBox(width: 8),
            _itemAba(
              id: 'desenvolvedor',
              titulo: 'Desenvolvedor',
              icone: Icons.code_rounded,
              theme: theme,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _itemAba(
            id: 'dono',
            titulo: 'Dono',
            icone: Icons.workspace_premium_outlined,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'socio',
            titulo: 'Sócio',
            icone: Icons.handshake_outlined,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'admin',
            titulo: 'Administrador',
            icone: Icons.security_outlined,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _itemAba(
            id: 'funcionario',
            titulo: 'Funcionário',
            icone: Icons.badge_outlined,
            theme: theme,
          ),
          for (final cargo in widget.cargosPersonalizados) ...[
            const SizedBox(width: 8),
            _itemAba(
              id: cargo.id,
              titulo: cargo.nome,
              icone: Icons.tag_rounded,
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
              onPressed: () => DialogsGerenciarCargo.abrirDialogNovoCargo(
                context: context,
                theme: theme,
                onAdicionarCargo: widget.onAdicionarCargo,
                onCargoCriado: (novoId) =>
                    setState(() => _abaSelecionadaId = novoId),
              ),
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
    if (widget.ehLojaColetivaNous) {
      return PainelColetivoNousWidget(
        theme: theme,
        abaSelecionadaId: _abaSelecionadaId,
        usuarioLogadoEhDesenvolvedor: widget.usuarioLogadoEhDesenvolvedor,
        onAlternarDesenvolvedor: widget.onAlternarDesenvolvedor,
      );
    }

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
              if (!ehNativo &&
                  widget.podeGerenciar &&
                  cargoPersonalizado != null) ...[
                IconButton(
                  tooltip: 'Renomear cargo',
                  icon:
                      Icon(Icons.edit_outlined, size: 18, color: theme.textColor),
                  onPressed: () =>
                      DialogsGerenciarCargo.abrirDialogRenomearCargo(
                    context: context,
                    theme: theme,
                    cargo: cargoPersonalizado,
                    onAtualizarCargo: widget.onAtualizarCargo,
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir cargo',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      DialogsGerenciarCargo.confirmarExcluirCargo(
                    context: context,
                    theme: theme,
                    cargo: cargoPersonalizado,
                    onRemoverCargo: widget.onRemoverCargo,
                    onCargoExcluido: () =>
                        setState(() => _abaSelecionadaId = 'dono'),
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
            CardPermissaoLojaWidget(
              theme: theme,
              perm: perm,
              abaSelecionadaId: _abaSelecionadaId,
              permissoesCargosNativos: widget.permissoesCargosNativos,
              cargoPersonalizado: cargoPersonalizado,
              ehDonoOuSocio: widget.ehDonoOuSocio,
              podeGerenciar: widget.podeGerenciar,
              onAtualizarPermissoesCargoNativo:
                  widget.onAtualizarPermissoesCargoNativo,
              onAtualizarCargo: widget.onAtualizarCargo,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
