import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/ajustes_loja/bloco_atalhos_teclado_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/ajustes_loja/bloco_sons_alertas_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/ajustes_loja/bloco_tempo_conclusao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/seletor_layouts_desktop_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart';

/// Aba de Ajustes e Configurações Globais da Loja (Layout, Rede Wi-Fi, Atalhos, Sons e Financeiro).
class AbaAjustesLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final bool possoEditarDados;
  final bool expandido;
  final double larguraDaTela;
  final bool tecladoFisicoDetectado;
  final Map<String, String> atalhosTeclado;
  final int tempoConclusaoMinutos;
  final Map<String, String> sonsAlertas;
  final List<String> arquivosAudio;
  final Map<String, String> descricoesAnexos;
  final BoxDecoration decoracaoBloco;
  final List<String> acoesAtalhosDisponiveis;
  final List<String> teclasFuncao;
  final String Function(String tecla)? onObterAcaoPorTecla;
  final VoidCallback onAlternarLayout;
  final void Function(String tecla, String? acao) onSalvarAtalho;
  final void Function(int minutos) onSalvarTempoConclusao;
  final void Function(String chave, String valor) onSalvarSomAlerta;
  final void Function(BuildContext context, AppTheme theme)
      onConfirmarResetTransacoes;

  const AbaAjustesLojaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.possoEditarDados,
    required this.expandido,
    required this.larguraDaTela,
    required this.tecladoFisicoDetectado,
    required this.atalhosTeclado,
    required this.tempoConclusaoMinutos,
    required this.sonsAlertas,
    required this.arquivosAudio,
    required this.descricoesAnexos,
    required this.decoracaoBloco,
    required this.acoesAtalhosDisponiveis,
    required this.teclasFuncao,
    this.onObterAcaoPorTecla,
    required this.onAlternarLayout,
    required this.onSalvarAtalho,
    required this.onSalvarTempoConclusao,
    required this.onSalvarSomAlerta,
    required this.onConfirmarResetTransacoes,
  });

  void _abrirSincronizacaoRede(BuildContext context) {
    final pdv = context.read<PdvProvider>();
    final lojaAtual = pdv.buscarPorId(lojaId);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SincronizacaoRedeDialog(
        theme: theme,
        loja: lojaAtual,
      ),
    );
  }

  Widget _buildContainerModoLayout(
    BuildContext context,
    AppTheme theme,
    bool podeEditar,
  ) {
    return SeletorLayoutsDesktopWidget(
      theme: theme,
      podeEditar: podeEditar,
      layoutExpandido: expandido,
      tipoLayoutSelecionado: 'classico',
      onAlternarLayout: onAlternarLayout,
      onSelecionarTipo: (_) {},
    );
  }

  Widget _buildContainerFinanceiro(
    BuildContext context,
    AppTheme theme,
    bool podeResetar,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.buttonColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Financeiro do Perfil',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Gerencie ajustes financeiros, histórico contábil e operações do perfil profissional.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: podeResetar ? 1.0 : 0.5,
            child: Tooltip(
              message: podeResetar
                  ? 'Limpa histórico de vendas, caixas e pagamentos da loja'
                  : 'Apenas Dono, Sócios ou usuários com permissão podem resetar transações',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: podeResetar
                    ? () => onConfirmarResetTransacoes(context, theme)
                    : null,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text(
                  'Resetar registros de transações da loja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerSincronizacaoRede(
    BuildContext context,
    AppTheme theme,
  ) {
    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_rounded, size: 20, color: theme.buttonColor),
                const SizedBox(width: 8),
                Text(
                  'Sincronização em Rede Wi-Fi',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Conecte computadores e celulares no mesmo Wi-Fi para operar a mesma loja em tempo real sem internet.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          StatefulBuilder(
            builder: (context, setSubstate) {
              final ativo = servidor.ativo;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dns_rounded,
                          size: 18,
                          color: ativo ? Colors.greenAccent : theme.textColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Computador Central (Balcão)',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              Text(
                                ativo
                                    ? 'Servidor ativo na porta ${servidor.porta}'
                                    : 'Desativado nesta máquina',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: ativo
                                      ? Colors.greenAccent
                                      : theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: ativo,
                          onChanged: (ligar) async {
                            final pdv = context.read<PdvProvider>();
                            final auth = context.read<AuthProvider>();
                            final lojaAtual = pdv.buscarPorId(lojaId) ??
                                (pdv.lojas.isNotEmpty ? pdv.lojas.first : null);
                            if (ligar) {
                              if (lojaAtual != null) {
                                await servidor.iniciar(
                                  loja: lojaAtual,
                                  pdv: pdv,
                                  auth: auth,
                                );
                              }
                            } else {
                              await servidor.parar();
                            }
                            setSubstate(() {});
                          },
                          activeThumbColor: theme.textColor,
                          activeTrackColor:
                              theme.borderColor.withValues(alpha: 0.5),
                          inactiveThumbColor: theme.secondaryTextColor,
                          inactiveTrackColor: Colors.transparent,
                          trackOutlineColor:
                              WidgetStateProperty.all(theme.borderColor),
                        ),
                      ],
                    ),
                    if (cliente.conectado) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Conectado ao Balcão: ${cliente.enderecoServidor}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _abrirSincronizacaoRede(context),
              icon: Icon(
                Icons.settings_ethernet_rounded,
                size: 16,
                color: theme.textColor,
              ),
              label: Text(
                'Gerenciar Conexões Wi-Fi',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final avisoSomenteLeitura = !possoEditarDados
        ? Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Modo somente leitura: você pode visualizar as configurações da loja, mas apenas Donos e Sócios podem alterar comandos, tempo de conclusão e alertas.',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    final possoResetar = pdv.possoResetarTransacoes(lojaId);
    final bool ehMobile = Platform.isAndroid || Platform.isIOS;
    final bool podeMostrarComandos = (!ehMobile) || tecladoFisicoDetectado;
    final bool podeMostrarModoLayout = (!ehMobile) || tecladoFisicoDetectado;

    final blocoAtalhos = BlocoAtalhosTecladoWidget(
      theme: theme,
      decoracaoBloco: decoracaoBloco,
      teclasFuncao: teclasFuncao,
      acoesAtalhosDisponiveis: acoesAtalhosDisponiveis,
      podeEditar: possoEditarDados,
      onObterAcaoPorTecla: onObterAcaoPorTecla,
      onSalvarAtalho: onSalvarAtalho,
    );

    final blocoTempo = BlocoTempoConclusaoWidget(
      theme: theme,
      decoracaoBloco: decoracaoBloco,
      podeEditar: possoEditarDados,
      tempoConclusaoMinutos: tempoConclusaoMinutos,
      onSalvarTempoConclusao: onSalvarTempoConclusao,
    );

    final blocoSons = BlocoSonsAlertasWidget(
      theme: theme,
      decoracaoBloco: decoracaoBloco,
      podeEditar: possoEditarDados,
      sonsAlertas: sonsAlertas,
      arquivosAudio: arquivosAudio,
      descricoesAnexos: descricoesAnexos,
      onSalvarSomAlerta: onSalvarSomAlerta,
    );

    if (expandido && larguraDaTela > 850) {
      return Column(
        children: [
          ?avisoSomenteLeitura,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildContainerSincronizacaoRede(context, theme),
                    if (podeMostrarModoLayout) ...[
                      const SizedBox(height: 16),
                      _buildContainerModoLayout(
                        context,
                        theme,
                        possoEditarDados,
                      ),
                    ],
                    if (podeMostrarComandos) ...[
                      const SizedBox(height: 16),
                      blocoAtalhos,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    blocoTempo,
                    const SizedBox(height: 16),
                    blocoSons,
                    const SizedBox(height: 16),
                    _buildContainerFinanceiro(context, theme, possoResetar),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        ?avisoSomenteLeitura,
        _buildContainerSincronizacaoRede(context, theme),
        if (podeMostrarModoLayout) ...[
          const SizedBox(height: 16),
          _buildContainerModoLayout(context, theme, possoEditarDados),
        ],
        if (podeMostrarComandos) ...[
          const SizedBox(height: 16),
          blocoAtalhos,
        ],
        const SizedBox(height: 16),
        blocoTempo,
        const SizedBox(height: 16),
        blocoSons,
        const SizedBox(height: 16),
        _buildContainerFinanceiro(context, theme, possoResetar),
      ],
    );
  }
}
