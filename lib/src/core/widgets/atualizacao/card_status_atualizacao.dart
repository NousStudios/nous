import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/atualizacao/bloco_novidades_atualizacao.dart';

/// Card que exibe o estado da verificação, nova versão disponível ou sistema atualizado.
class CardStatusAtualizacao extends StatelessWidget {
  final AppTheme theme;
  final bool estaVerificando;
  final bool temNovaVersao;
  final InfoAtualizacao? info;
  final String? statusMsg;

  const CardStatusAtualizacao({
    super.key,
    required this.theme,
    required this.estaVerificando,
    required this.temNovaVersao,
    required this.info,
    required this.statusMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (estaVerificando) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Consultando atualizações disponíveis...',
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final novaInfo = info;
    if (temNovaVersao && novaInfo != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.borderColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.textColor,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.new_releases_outlined,
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nova Versão v${novaInfo.versao} Pronta!',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              novaInfo.nomeVersao,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            BlocoNovidadesAtualizacao(
              theme: theme,
              versao: novaInfo.versao,
              descricao: novaInfo.descricao,
              alteracoesRemotas: novaInfo.alteracoes,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: AtualizacaoService.baixando,
              builder: (context, estaBaixando, _) {
                if (!estaBaixando) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: AtualizacaoService.mensagemStatus,
                    builder: (context, msgStatus, _) {
                      final texto = msgStatus ?? '';
                      final ehErroOuAviso =
                          texto.toLowerCase().contains('erro') ||
                              texto.toLowerCase().contains('autorize');
                      if (!ehErroOuAviso) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              texto,
                              style: theme.getTextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: theme.dangerColor,
                              ),
                            ),
                            if (novaInfo.urlDownload.isNotEmpty &&
                                !novaInfo.urlDownload
                                    .contains('/api/download_')) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.borderColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    AtualizacaoService.abrirPaginaDownload(
                                  novaInfo.urlDownload,
                                ),
                                icon: Icon(
                                  Icons.open_in_browser_rounded,
                                  size: 16,
                                  color: theme.textColor,
                                ),
                                label: Text(
                                  'Baixar pelo Navegador',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                }
                return ValueListenableBuilder<double?>(
                  valueListenable: AtualizacaoService.progressoDownload,
                  builder: (context, progresso, _) {
                    final pct = ((progresso ?? 0.0) * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progresso,
                              backgroundColor:
                                  theme.borderColor.withValues(alpha: 0.3),
                              color: theme.textColor,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<String?>(
                            valueListenable: AtualizacaoService.mensagemStatus,
                            builder: (context, msgStatus, _) {
                              final texto = (progresso != null && progresso < 1.0)
                                  ? 'Baixando atualização in-app: $pct%...'
                                  : (msgStatus ?? 'Download concluído! Atualizando...');
                              return Text(
                                texto,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: theme.textColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema Atualizado (v${AtualizacaoService.versaoAtual})',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (statusMsg != null)
                      Text(
                        statusMsg!,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: theme.borderColor.withValues(alpha: 0.4),
            height: 1,
          ),
          const SizedBox(height: 8),
          BlocoNovidadesAtualizacao(
            theme: theme,
            versao: AtualizacaoService.versaoAtual,
          ),
        ],
      ),
    );
  }
}
