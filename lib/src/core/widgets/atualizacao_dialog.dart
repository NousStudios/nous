import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AtualizacaoDialog(theme: theme),
        ),
      ),
    );
  }

  @override
  State<AtualizacaoDialog> createState() => _AtualizacaoDialogState();
}

class _AtualizacaoDialogState extends State<AtualizacaoDialog> {
  bool _novidadesExpandidas = false;

  @override
  void initState() {
    super.initState();
    // Se conectado ao balcão Wi-Fi, consulta prioritariamente a versão local
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().verificarAtualizacaoLocal();
    } else if (AtualizacaoService.ultimaVerificacao.value == null &&
        !AtualizacaoService.temAtualizacao.value) {
      AtualizacaoService.verificarAtualizacao();
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final min = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$min';
  }

  Widget _blocoNovidades({
    required AppTheme theme,
    required String versao,
    String? descricao,
  }) {
    final novidade = ChangelogService.obterUltimaVersao(versao);
    final itens = (novidade != null && novidade.alteracoes.isNotEmpty)
        ? novidade.alteracoes
        : (descricao != null && descricao.trim().isNotEmpty
            ? [descricao.trim()]
            : <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 15,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Alterações (CHANGELOG.MD)',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                _novidadesExpandidas
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: theme.textColor,
                size: 22,
              ),
              tooltip: _novidadesExpandidas
                  ? 'Minimizar alterações'
                  : 'Maximizar alterações',
              onPressed: () {
                setState(() => _novidadesExpandidas = !_novidadesExpandidas);
              },
            ),
          ],
        ),
        if (_novidadesExpandidas) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itens.isEmpty)
                    Text(
                      descricao ?? 'Melhorias de desempenho e correções gerais.',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    )
                  else
                    for (final item in itens)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ] else ...[
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _novidadesExpandidas = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: theme.secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Toque para ver o resumo das novas mudanças',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ValueListenableBuilder<bool>(
        valueListenable: AtualizacaoService.verificando,
        builder: (context, estaVerificando, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: AtualizacaoService.temAtualizacao,
            builder: (context, temNovaVersao, _) {
              final info = AtualizacaoService.infoAtualizacao.value;
              final ultimaChecagem =
                  AtualizacaoService.ultimaVerificacao.value;
              final statusMsg = AtualizacaoService.mensagemStatus.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  Row(
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
                  ),
                  const SizedBox(height: 18),

                  // Card da Versão Atual
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versão Instalada',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${AtualizacaoService.versaoAtual} (Build ${AtualizacaoService.buildAtual})',
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            Platform.isAndroid
                                ? 'Android (Móvel)'
                                : (Platform.isWindows
                                    ? 'Windows Desktop'
                                    : (Platform.isIOS
                                        ? 'iOS (Móvel)'
                                        : Platform.operatingSystem)),
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status ou Notificação de Nova Versão
                  if (estaVerificando)
                    Container(
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
                    )
                  else if (temNovaVersao && info != null)
                    Container(
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
                                  'Nova Versão v${info.versao} Pronta!',
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
                            info.nomeVersao,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _blocoNovidades(
                            theme: theme,
                            versao: info.versao,
                            descricao: info.descricao,
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: AtualizacaoService.baixando,
                            builder: (context, estaBaixando, _) {
                              if (!estaBaixando) return const SizedBox.shrink();
                              return ValueListenableBuilder<double?>(
                                valueListenable:
                                    AtualizacaoService.progressoDownload,
                                builder: (context, progresso, _) {
                                  final pct = ((progresso ?? 0.0) * 100).toInt();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: progresso,
                                            backgroundColor: theme.borderColor
                                                .withValues(alpha: 0.3),
                                            color: theme.textColor,
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          progresso != null && progresso < 1.0
                                              ? 'Baixando atualização in-app: $pct%...'
                                              : 'Download concluído! Iniciando instalador...',
                                          style: theme.getTextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.textColor,
                                          ),
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
                    )
                  else
                    Container(
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
                                        statusMsg,
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
                          const SizedBox(height: 8),
                          _blocoNovidades(
                            theme: theme,
                            versao: AtualizacaoService.versaoAtual,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Nota de Soberania e Preservação de Dados
                  Container(
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
                  ),

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

                  // Botões de Ação
                  Row(
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
                              : () async {
                                  if (ClienteRedeLocal().conectado) {
                                    await ClienteRedeLocal().verificarAtualizacaoLocal();
                                  } else {
                                    await AtualizacaoService.verificarAtualizacao();
                                  }
                                },
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: estaBaixando
                                    ? null
                                    : () {
                                        AtualizacaoService.baixarEInstalarAtualizacao(
                                          info.urlDownload,
                                        );
                                      },
                                child: estaBaixando
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
