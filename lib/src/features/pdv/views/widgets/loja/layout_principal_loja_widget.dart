import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/barra_de_abas_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/desktop_sidebar_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao_widget.dart';

class LayoutPrincipalLojaWidget extends StatelessWidget {
  final String lojaId;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> onTrocarAba;
  final String tituloAba;
  final double larguraDinamica;
  final bool modoBalcaoAtivo;
  final VoidCallback onSairModoBalcao;
  final void Function(PedidoLoja pedido, List<MovimentoEstoque> movs) onConcluirVendaBalcao;
  final List<PedidoLoja> pedidos;
  final List<ItemLoja> itens;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final List<Cliente> clientes;
  final List<MovimentoEstoque> movimentosEstoque;
  final String cpfLogado;
  final String nomeLogado;
  final Map<String, String> atalhosTeclado;
  final bool temNovasMensagensLoja;
  final void Function(String tecla) onExecutarAtalho;
  final void Function(String acao) onExecutarAcao;
  final VoidCallback onAlternarLayout;
  final VoidCallback onLogout;
  final Widget Function(AppTheme theme, double maxWidth) construtorBarraAcoes;
  final Widget Function(AppTheme theme) construtorConteudoAba;

  const LayoutPrincipalLojaWidget({
    super.key,
    required this.lojaId,
    required this.abaSelecionada,
    required this.onTrocarAba,
    required this.tituloAba,
    required this.larguraDinamica,
    required this.modoBalcaoAtivo,
    required this.onSairModoBalcao,
    required this.onConcluirVendaBalcao,
    required this.pedidos,
    required this.itens,
    required this.categorias,
    required this.gruposComponentes,
    required this.clientes,
    required this.movimentosEstoque,
    required this.cpfLogado,
    required this.nomeLogado,
    required this.atalhosTeclado,
    required this.temNovasMensagensLoja,
    required this.onExecutarAtalho,
    required this.onExecutarAcao,
    required this.onAlternarLayout,
    required this.onLogout,
    required this.construtorBarraAcoes,
    required this.construtorConteudoAba,
  });

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(lojaId);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f1): () => onExecutarAtalho('F1'),
        const SingleActivator(LogicalKeyboardKey.f2): () => onExecutarAtalho('F2'),
        const SingleActivator(LogicalKeyboardKey.f3): () => onExecutarAtalho('F3'),
        const SingleActivator(LogicalKeyboardKey.f4): () => onExecutarAtalho('F4'),
        const SingleActivator(LogicalKeyboardKey.f5): () => onExecutarAtalho('F5'),
        const SingleActivator(LogicalKeyboardKey.f6): () => onExecutarAtalho('F6'),
        const SingleActivator(LogicalKeyboardKey.f7): () => onExecutarAtalho('F7'),
        const SingleActivator(LogicalKeyboardKey.f8): () => onExecutarAtalho('F8'),
        const SingleActivator(LogicalKeyboardKey.f9): () => onExecutarAtalho('F9'),
        const SingleActivator(LogicalKeyboardKey.f10): () => onExecutarAtalho('F10'),
        const SingleActivator(LogicalKeyboardKey.f11): () => onExecutarAtalho('F11'),
        const SingleActivator(LogicalKeyboardKey.f12): () => onExecutarAtalho('F12'),
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            if (modoBalcaoAtivo) {
              final proximoNumero = pedidos.fold<int>(
                    0,
                    (maior, pedido) =>
                        pedido.numero > maior ? pedido.numero : maior,
                  ) +
                  1;

              return ModoBalcaoWidget(
                theme: theme,
                lojaId: lojaId,
                nomeLoja: lojaAtual?.nome ?? '',
                logoLoja: lojaAtual?.logo ?? '',
                itens: itens,
                categorias: categorias,
                gruposComponentes: gruposComponentes,
                clientes: clientes,
                movimentosEstoque: movimentosEstoque,
                configuracoesImpressora: lojaAtual?.configuracoesImpressora ??
                    const ConfiguracoesImpressora(),
                cpfAutor: cpfLogado,
                nomeAutor: nomeLogado,
                proximoNumero: proximoNumero,
                caixaAberto: lojaAtual?.turnoCaixaAberto != null,
                onSair: onSairModoBalcao,
                onConcluirVenda: onConcluirVendaBalcao,
              );
            }

            final larguraDaTela = MediaQuery.sizeOf(context).width;
            final expandido = pdv.layoutDesktopAtivo(lojaId, larguraDaTela);

            if (expandido) {
              return Scaffold(
                backgroundColor: theme.backgroundColor,
                appBar: CustomAppBar(
                  title: tituloAba,
                  lojaId: lojaId,
                  onLogout: onLogout,
                ),
                body: SafeArea(
                  child: Row(
                    children: [
                      DesktopSidebarWidget(
                        theme: theme,
                        nomeLoja: lojaAtual?.nome ?? '',
                        logoLoja: lojaAtual?.logo ?? '',
                        abaSelecionada: abaSelecionada,
                        onTrocarAba: onTrocarAba,
                        onExecutarAtalho: onExecutarAtalho,
                        onExecutarAcao: onExecutarAcao,
                        atalhosTeclado: atalhosTeclado.isNotEmpty
                            ? atalhosTeclado
                            : (lojaAtual?.atalhosTeclado ?? const {}),
                        onAlternarLayout: onAlternarLayout,
                        tipoLayoutNome: 'Layout Desktop Expandido',
                        caixaAberto: lojaAtual?.turnoCaixaAberto != null,
                        temNovasMensagens: temNovasMensagensLoja,
                        ehLojaColetivaNous:
                            lojaId == PdvProvider.idLojaColetivaNous,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            if (abaSelecionada == AbaLoja.loja)
                              construtorBarraAcoes(theme, double.infinity),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: construtorConteudoAba(theme),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: CustomAppBar(
                title: tituloAba,
                lojaId: lojaId,
                onLogout: onLogout,
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: larguraDinamica),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: construtorConteudoAba(theme),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (abaSelecionada == AbaLoja.loja)
                    construtorBarraAcoes(theme, larguraDinamica),
                  BarraDeAbasDaLojaWidget(
                    theme: theme,
                    abaSelecionada: abaSelecionada,
                    aoTrocarAba: onTrocarAba,
                    maxWidth: larguraDinamica,
                    ehLojaColetivaNous:
                        lojaId == PdvProvider.idLojaColetivaNous,
                  ),
                  FloatingBottomNavBar(maxWidth: larguraDinamica),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
