import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/status_loja/bloco_resumo_operacional_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart';

class StatusLojaView extends StatefulWidget {
  final String lojaId;
  final bool lojaOnlineInicial;
  final ValueChanged<bool> aoAlterarOnline;
  final List<MembroLoja> membros;
  final String cpfLogado;
  final bool podeSair;
  final VoidCallback onSair;

  const StatusLojaView({
    super.key,
    required this.lojaId,
    required this.lojaOnlineInicial,
    required this.aoAlterarOnline,
    required this.membros,
    required this.cpfLogado,
    required this.podeSair,
    required this.onSair,
  });

  @override
  State<StatusLojaView> createState() => _StatusLojaViewState();
}

class _StatusLojaViewState extends State<StatusLojaView> {
  late bool _online;

  @override
  void initState() {
    super.initState();
    _online = widget.lojaOnlineInicial;
  }

  void _alternarOnline(bool valor) {
    setState(() => _online = valor);
    widget.aoAlterarOnline(valor);
    context.read<PdvProvider>().alternarLojaAberta(widget.lojaId, valor);
    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    if (lojaAtual != null) {
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'loja_atualizada',
          'loja': lojaAtual.toJson(),
        });
      }
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarLojaAtualizada(lojaAtual);
      }
    }
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(AppTheme theme, String texto) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: theme.getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  void _confirmarSaida() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = ThemeController.currentTheme.value;
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Sair da loja',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja sair desta loja?',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onSair();
              },
              child: Text(
                'Sair',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blocoStatus(AppTheme theme) {
    final loja = context.select<PdvProvider, Loja?>(
      (p) => p.buscarPorId(widget.lojaId),
    );
    final totalMembros = (loja?.membros ?? widget.membros).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Status da Loja'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(left: 20, right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _online ? 'Online' : 'Offline',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _online,
                  onChanged: _alternarOnline,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: theme.textColor,
                  activeTrackColor:
                      theme.borderColor.withValues(alpha: 0.4),
                  inactiveThumbColor: theme.secondaryTextColor,
                  inactiveTrackColor: Colors.transparent,
                  trackOutlineColor:
                      WidgetStatePropertyAll(theme.borderColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalMembros ${totalMembros == 1 ? 'membro' : 'membros'}',
            style: theme.getTextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          Divider(color: theme.borderColor.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            'Servidor da Loja (Wi-Fi Local)',
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: Listenable.merge([
              ServidorRedeLocal().estaAtivo,
              ServidorRedeLocal().totalConectados,
            ]),
            builder: (context, _) {
              final servidor = ServidorRedeLocal();
              final ativo = servidor.ativo;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ativo
                        ? Colors.greenAccent.withValues(alpha: 0.5)
                        : theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      ativo ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                      color: ativo ? Colors.greenAccent : theme.secondaryTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ativo ? 'Servidor Ligado' : 'Servidor Desligado',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ativo
                                ? '${servidor.ipServidor}:${servidor.porta} • ${servidor.totalConectados.value} conectados'
                                : 'Ligue para operar celulares e outros nós no balcão',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: ativo ? Colors.greenAccent : theme.secondaryTextColor,
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
                        final lojaAtual = pdv.buscarPorId(widget.lojaId) ??
                            (pdv.lojas.isNotEmpty ? pdv.lojas.first : null);
                        if (ligar) {
                          if (lojaAtual != null) {
                            await servidor.iniciar(loja: lojaAtual, pdv: pdv, auth: auth);
                          }
                        } else {
                          await servidor.parar();
                        }
                      },
                      activeThumbColor: theme.textColor,
                      activeTrackColor: theme.borderColor.withValues(alpha: 0.5),
                      inactiveThumbColor: theme.secondaryTextColor,
                      inactiveTrackColor: Colors.transparent,
                      trackOutlineColor: WidgetStateProperty.all(theme.borderColor),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.podeSair) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.dangerColor,
                  side: BorderSide(color: theme.dangerColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _confirmarSaida,
                child: Text(
                  'Sair da loja',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.dangerColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f11): () {
          JanelaWindowsService.alternarTelaCheia();
        },
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, theme, child) {
            final loja = context.select<PdvProvider, Loja?>(
              (p) => p.buscarPorId(widget.lojaId),
            );
            if (loja != null && loja.aberta != _online) {
              _online = loja.aberta;
            }
            final larguraDaTela = MediaQuery.sizeOf(context).width;
            final expandido =
                (loja?.layoutExpandido ?? false) && larguraDaTela > 850;

            final conteudoColuna1 = [
              BlocoResumoOperacionalWidget(
                lojaId: widget.lojaId,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _blocoStatus(theme),
            ];

            final conteudoColuna2 = [
              BlocoTrabalhadoresStatusWidget(
                lojaId: widget.lojaId,
                membrosFallback: widget.membros,
                cpfLogado: widget.cpfLogado,
                theme: theme,
              ),
            ];

            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: CustomAppBar(
                title: 'Status da Loja',
                lojaId: widget.lojaId,
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: expandido ? 1200 : 500,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: expandido
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: conteudoColuna1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: conteudoColuna2,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...conteudoColuna1,
                                const SizedBox(height: 16),
                                ...conteudoColuna2,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}