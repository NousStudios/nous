import 'package:flutter/material.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Bloco expansível que exibe as alterações e novidades da versão disponível.
class BlocoNovidadesAtualizacao extends StatefulWidget {
  final AppTheme theme;
  final String versao;
  final String? descricao;
  final List<String> alteracoesRemotas;

  const BlocoNovidadesAtualizacao({
    super.key,
    required this.theme,
    required this.versao,
    this.descricao,
    this.alteracoesRemotas = const [],
  });

  @override
  State<BlocoNovidadesAtualizacao> createState() =>
      _BlocoNovidadesAtualizacaoState();
}

class _BlocoNovidadesAtualizacaoState extends State<BlocoNovidadesAtualizacao> {
  bool _expandido = false;

  List<String> _resolverItens() {
    if (widget.alteracoesRemotas.isNotEmpty) {
      return widget.alteracoesRemotas;
    }

    if (widget.descricao != null && widget.descricao!.trim().isNotEmpty) {
      final linhas = widget.descricao!
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('## '))
          .map((l) {
            if (l.startsWith('### ')) {
              return l.replaceFirst(RegExp(r'^#{1,6}\s*'), '').trim();
            }
            var limpa = l.replaceAll(RegExp(r'^[-*•]\s*'), '');
            limpa = limpa.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');
            limpa = limpa.replaceAllMapped(
              RegExp(r'\[([^\]]+)\]\([^)]+\)'),
              (m) => m.group(1) ?? '',
            );
            return limpa.trim();
          })
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();
      if (linhas.isNotEmpty) return linhas;
    }

    final novidade = widget.versao.isNotEmpty
        ? (ChangelogService.obterUltimaVersao(widget.versao) ??
            ChangelogService.obterUltimaVersao())
        : ChangelogService.obterUltimaVersao();

    if (novidade != null && novidade.alteracoes.isNotEmpty) {
      return novidade.alteracoes;
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final itens = _resolverItens();

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
                  'Alterações',
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
                _expandido
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: theme.textColor,
                size: 22,
              ),
              tooltip: _expandido
                  ? 'Minimizar alterações'
                  : 'Maximizar alterações',
              onPressed: () {
                setState(() => _expandido = !_expandido);
              },
            ),
          ],
        ),
        if (_expandido) ...[
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
                      widget.descricao ??
                          'Melhorias de desempenho e correções gerais.',
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
            onTap: () => setState(() => _expandido = true),
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
}
