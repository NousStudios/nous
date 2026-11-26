import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/atualizacao/card_status_atualizacao.dart';
import 'package:nous/src/core/widgets/atualizacao/card_versao_atual.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class AtualizacaoDialog extends StatefulWidget {
  final AppTheme theme;

  const AtualizacaoDialog({
    super.key,
    required this.theme,
  });

  static Future<void> mostrar(BuildContext context) {
    final theme = ThemeController.currentTheme.value;
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.90,
          ),
          child: SingleChildScrollView(
            child: AtualizacaoDialog(theme: theme),
          ),
        ),
      ),
    );
  }

  @override
  State<AtualizacaoDialog> createState() => _AtualizacaoDialogState();
}

class _AtualizacaoDialogState extends State<AtualizacaoDialog> {
  @override
  void initState() {
    super.initState();
    if (!AtualizacaoService.baixando.value &&
        AtualizacaoService.ultimaVerificacao.value == null &&
        !AtualizacaoService.temAtualizacao.value) {
      _verificarPriorizandoGithub();
    }
  }

  Future<void> _verificarPriorizandoGithub() async {
    final encontrouGithub = await AtualizacaoService.verificarAtualizacao();
    if (!encontrouGithub && ClienteRedeLocal().conectado) {
      await ClienteRedeLocal().verificarAtualizacaoLocal();
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final min = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$min';
  }

  Widget _cabecalho(BuildContext context, AppTheme theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(
            Icons.system_update_alt_rounded,
            color: theme.textColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atualizações do Sistema',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Text(
                'Nous — SuperApp Soberano',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.secondaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _notaSoberania(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: theme.secondaryTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Soberania Local: Ao atualizar o Nous, seu banco de dados (nous.db), lojas, estoques e históricos permanecem 100% seguros e intactos no seu aparelho.',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botoesAcao(
    BuildContext context,
    AppTheme theme, {
    required bool estaVerificando,
    required bool temNovaVersao,
    required InfoAtualizacao? info,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: estaVerificando
                ? null
                : _verificarPriorizandoGithub,
            child: Text(
              'Verificar Agora',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.textColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (temNovaVersao && info != null)
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: AtualizacaoService.baixando,
              builder: (context, estaBaixando, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: estaBaixando
                      ? null
                      : () {
                          final urlAtual =
                              AtualizacaoService.infoAtualizacao.value?.urlDownload ??
                                  info.urlDownload;
                          AtualizacaoService.baixarEInstalarAtualizacao(
                            urlAtual,
                          );
                        },
                  child: estaBaixando
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.buttonTextColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instalando...',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.buttonTextColor,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Instalar v${info.versao}',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                );
              },
            ),
          )
        else
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          AtualizacaoService.verificando,
          AtualizacaoService.temAtualizacao,
          AtualizacaoService.infoAtualizacao,
          AtualizacaoService.mensagemStatus,
          AtualizacaoService.ultimaVerificacao,
          AtualizacaoService.baixando,
        ]),
        builder: (context, _) {
          final estaVerificando = AtualizacaoService.verificando.value;
          final temNovaVersao = AtualizacaoService.temAtualizacao.value;
          final info = AtualizacaoService.infoAtualizacao.value;
          final ultimaChecagem = AtualizacaoService.ultimaVerificacao.value;
          final statusMsg = AtualizacaoService.mensagemStatus.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(context, theme),
              const SizedBox(height: 18),
              CardVersaoAtual(theme: theme),
              const SizedBox(height: 12),
              CardStatusAtualizacao(
                theme: theme,
                estaVerificando: estaVerificando,
                temNovaVersao: temNovaVersao,
                info: info,
                statusMsg: statusMsg,
              ),
              const SizedBox(height: 12),
              _notaSoberania(theme),
              if (ultimaChecagem != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Última checagem: ${_formatarData(ultimaChecagem)}',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _botoesAcao(
                context,
                theme,
                estaVerificando: estaVerificando,
                temNovaVersao: temNovaVersao,
                info: info,
              ),
            ],
          );
        },
      ),
    );
  }
}
