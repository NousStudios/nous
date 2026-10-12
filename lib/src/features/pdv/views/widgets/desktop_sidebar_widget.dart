import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';

class DesktopSidebarWidget extends StatelessWidget {
  final AppTheme theme;
  final String nomeLoja;
  final String logoLoja;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> onTrocarAba;
  final Function(String tecla)? onExecutarAtalho;
  final Function(String acao)? onExecutarAcao;
  final Map<String, String> atalhosTeclado;
  final VoidCallback onAlternarLayout;
  final String tipoLayoutNome;
  final bool caixaAberto;

  const DesktopSidebarWidget({
    super.key,
    required this.theme,
    required this.nomeLoja,
    required this.logoLoja,
    required this.abaSelecionada,
    required this.onTrocarAba,
    this.onExecutarAtalho,
    this.onExecutarAcao,
    this.atalhosTeclado = const {},
    required this.onAlternarLayout,
    required this.tipoLayoutNome,
    this.caixaAberto = false,
  });

  String _obterTeclaParaAcao(String acao) {
    for (final entry in atalhosTeclado.entries) {
      if (entry.value == acao) {
        return entry.key;
      }
    }
    return '';
  }

  void _executar(String acao) {
    if (onExecutarAcao != null) {
      onExecutarAcao!(acao);
      return;
    }
    final tecla = _obterTeclaParaAcao(acao);
    if (tecla.isNotEmpty && onExecutarAtalho != null) {
      onExecutarAtalho!(tecla);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temLogo = logoLoja.isNotEmpty && File(logoLoja).existsSync();

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.7),
        border: Border(
          right: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da Sidebar com Identidade da Loja
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                  backgroundImage: temLogo ? FileImage(File(logoLoja)) : null,
                  child: !temLogo
                      ? Icon(
                          Icons.storefront_outlined,
                          color: theme.textColor,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeLoja.isNotEmpty ? nomeLoja : 'Minha Loja',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: caixaAberto
                                  ? const Color(0xFF4CAF50)
                                  : theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            caixaAberto ? 'Caixa Aberto' : 'Caixa Fechado',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.borderColor.withValues(alpha: 0.4),
          ),

          // Navegação de Abas do Sistema (Ordem: Dados > Ajustes > Loja > Gestão)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Text(
                    'MÓDULOS DO PDV',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor.withValues(alpha: 0.7),
                    ).copyWith(letterSpacing: 0.8),
                  ),
                ),
                _ItemAbaSidebar(
                  theme: theme,
                  titulo: 'Dados da Loja',
                  icone: Icons.badge_outlined,
                  selecionada: abaSelecionada == AbaLoja.dados,
                  onTap: () => onTrocarAba(AbaLoja.dados),
                ),
                _ItemAbaSidebar(
                  theme: theme,
                  titulo: 'Ajustes do Perfil',
                  icone: Icons.tune,
                  selecionada: abaSelecionada == AbaLoja.interface,
                  onTap: () => onTrocarAba(AbaLoja.interface),
                ),
                _ItemAbaSidebar(
                  theme: theme,
                  titulo: 'Loja / Catálogo',
                  icone: Icons.storefront,
                  selecionada: abaSelecionada == AbaLoja.loja,
                  onTap: () => onTrocarAba(AbaLoja.loja),
                ),
                _ItemAbaSidebar(
                  theme: theme,
                  titulo: 'Gestão de Pedidos',
                  icone: Icons.receipt_long,
                  selecionada: abaSelecionada == AbaLoja.gestao,
                  onTap: () => onTrocarAba(AbaLoja.gestao),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.borderColor.withValues(alpha: 0.4),
          ),

          // Seção de Comandos de Teclado Rápidos (Acompanha atalhos configurados)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'COMANDOS RÁPIDOS',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor.withValues(alpha: 0.7),
                      ).copyWith(letterSpacing: 0.8),
                    ),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Nova Venda'),
                    rotulo: 'Nova Venda',
                    icone: Icons.add_shopping_cart,
                    onTap: () => _executar('Nova Venda'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Clientes'),
                    rotulo: 'Clientes',
                    icone: Icons.people_outline,
                    onTap: () => _executar('Clientes'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Caixa'),
                    rotulo: 'Caixa',
                    icone: Icons.point_of_sale,
                    onTap: () => _executar('Caixa'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Relatórios'),
                    rotulo: 'Relatórios',
                    icone: Icons.bar_chart,
                    onTap: () => _executar('Relatórios'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Impressora'),
                    rotulo: 'Impressora',
                    icone: Icons.print_outlined,
                    onTap: () => _executar('Impressora'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Financeiro'),
                    rotulo: 'Financeiro',
                    icone: Icons.account_balance_wallet_outlined,
                    onTap: () => _executar('Financeiro'),
                  ),
                  _BotaoAtalhoSidebar(
                    theme: theme,
                    tecla: _obterTeclaParaAcao('Status da Loja'),
                    rotulo: 'Status da Loja',
                    icone: Icons.insights,
                    onTap: () => _executar('Status da Loja'),
                  ),
                ],
              ),
            ),
          ),

          // Rodapé da Sidebar: Status do Layout Desktop e Alternar F11
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'LAYOUT DESKTOP ATIVO',
                  style: theme.getTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ).copyWith(letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  tipoLayoutNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onAlternarLayout,
                  icon: const Icon(Icons.view_compact_outlined, size: 16),
                  label: Text(
                    'Usar Layout Compacto',
                    style: theme.getTextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemAbaSidebar extends StatefulWidget {
  final AppTheme theme;
  final String titulo;
  final IconData icone;
  final bool selecionada;
  final VoidCallback onTap;

  const _ItemAbaSidebar({
    required this.theme,
    required this.titulo,
    required this.icone,
    required this.selecionada,
    required this.onTap,
  });

  @override
  State<_ItemAbaSidebar> createState() => _ItemAbaSidebarState();
}

class _ItemAbaSidebarState extends State<_ItemAbaSidebar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selecionada = widget.selecionada;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selecionada
                  ? (theme.buttonColor != Colors.transparent
                      ? theme.buttonColor.withValues(alpha: 0.8)
                      : theme.borderColor.withValues(alpha: 0.28))
                  : (_hover
                      ? theme.borderColor.withValues(alpha: 0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selecionada
                    ? theme.textColor
                    : (_hover
                        ? theme.textColor.withValues(alpha: 0.5)
                        : Colors.transparent),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icone,
                  size: 18,
                  color: selecionada ? theme.textColor : theme.secondaryTextColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight:
                          selecionada ? FontWeight.bold : FontWeight.normal,
                      color: selecionada
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoAtalhoSidebar extends StatefulWidget {
  final AppTheme theme;
  final String tecla;
  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;

  const _BotaoAtalhoSidebar({
    required this.theme,
    required this.tecla,
    required this.rotulo,
    required this.icone,
    required this.onTap,
  });

  @override
  State<_BotaoAtalhoSidebar> createState() => _BotaoAtalhoSidebarState();
}

class _BotaoAtalhoSidebarState extends State<_BotaoAtalhoSidebar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : theme.backgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hover
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                widget.tecla.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.borderColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.textColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          widget.tecla,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      )
                    : Container(
                        width: 22,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.borderColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.textColor.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                const SizedBox(width: 8),
                Icon(widget.icone, size: 16, color: theme.secondaryTextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.rotulo,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
