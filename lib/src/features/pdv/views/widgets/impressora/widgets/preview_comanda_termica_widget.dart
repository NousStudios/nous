import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/fontes_app.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/dados_teste_impressora.dart';

class PreviewComandaTermicaWidget extends StatelessWidget {
  final AppTheme theme;
  final String modeloFonte;
  final String tamanhoFonte;
  final double margemEsquerdaMm;
  final double margemDireitaMm;
  final List<String> camposClienteComanda;
  final PerfilHistoricoAnarquista perfilHistorico;
  final String rodape;
  final bool imprimindo;
  final VoidCallback onImprimirExemplo;

  const PreviewComandaTermicaWidget({
    super.key,
    required this.theme,
    required this.modeloFonte,
    required this.tamanhoFonte,
    required this.margemEsquerdaMm,
    required this.margemDireitaMm,
    required this.camposClienteComanda,
    required this.perfilHistorico,
    required this.rodape,
    required this.imprimindo,
    required this.onImprimirExemplo,
  });

  double get _escalaFonte => tamanhoFonte == 'pequena'
      ? 0.88
      : tamanhoFonte == 'grande'
          ? 1.15
          : 1.0;

  TextStyle _estilo(
    OpcaoFonte opcaoFonte, {
    required double fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return FontesApp.criarTextStyle(
      fontName: opcaoFonte.familiaFlutter,
      fontSize: fontSize * _escalaFonte,
      color: color ?? theme.textColor,
      fontWeight: fontWeight,
    );
  }

  Widget _linhaDadoCliente(
    OpcaoFonte opcaoFonte,
    String rotulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rotulo: ',
            style: _estilo(
              opcaoFonte,
              fontSize: 12,
              color: theme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              softWrap: true,
              style: _estilo(
                opcaoFonte,
                fontSize: 12,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaComanda(
    OpcaoFonte opcaoFonte,
    String esquerda,
    String direita, {
    bool destaque = false,
  }) {
    final ehPreco = direita.trim().startsWith('R\$');
    final cor = destaque ? theme.textColor : theme.secondaryTextColor;
    final peso = destaque ? FontWeight.bold : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ehPreco)
            Expanded(
              child: Text(
                esquerda,
                softWrap: true,
                style: _estilo(
                  opcaoFonte,
                  fontSize: 12,
                  color: cor,
                  fontWeight: peso,
                ),
              ),
            )
          else
            Text(
              esquerda,
              style: _estilo(
                opcaoFonte,
                fontSize: 12,
                color: cor,
                fontWeight: peso,
              ),
            ),
          const SizedBox(width: 8),
          if (ehPreco)
            Text(
              direita,
              textAlign: TextAlign.right,
              softWrap: false,
              style: _estilo(
                opcaoFonte,
                fontSize: 12,
                color: cor,
                fontWeight: peso,
              ),
            )
          else
            Expanded(
              child: Text(
                direita,
                textAlign: TextAlign.right,
                softWrap: true,
                style: _estilo(
                  opcaoFonte,
                  fontSize: 12,
                  color: cor,
                  fontWeight: peso,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opcaoFonte = FontesApp.obterPorIdOuNome(modeloFonte);
    final double padEsq = 14.0 + (margemEsquerdaMm * 1.5);
    final double padDir = 14.0 + (margemDireitaMm * 1.5);
    final totalItens = perfilHistorico.itens
        .fold(0.0, (soma, i) => soma + i.value)
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    return Column(
      children: [
        Divider(color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 15,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Prévia da Comanda',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: (320.0 * theme.fontScale).clamp(320.0, 440.0),
            ),
            padding: EdgeInsets.fromLTRB(padEsq, 14, padDir, 16),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'NOUS COMÉRCIO & SERVIÇOS',
                    textAlign: TextAlign.center,
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'CNPJ: 12.345.678/0001-90',
                    textAlign: TextAlign.center,
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Pedido #0042',
                    textAlign: TextAlign.center,
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Data: 08/10/2026 14:30',
                    textAlign: TextAlign.center,
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (camposClienteComanda.isNotEmpty) ...[
                  _linhaDadoCliente(
                    opcaoFonte,
                    'Cliente',
                    perfilHistorico.cliente,
                  ),
                  if (camposClienteComanda.contains('cnpj'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'CNPJ/CPF',
                      perfilHistorico.cnpj,
                    ),
                  if (camposClienteComanda.contains('telefone'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'Telefone',
                      perfilHistorico.telefone,
                    ),
                  if (camposClienteComanda.contains('endereco'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'Endereço',
                      perfilHistorico.endereco,
                    ),
                  if (camposClienteComanda.contains('email'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'Email',
                      'nousstudios72@gmail.com',
                    ),
                  if (camposClienteComanda.contains('redesSociais'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'Redes sociais',
                      '@nous.studios72',
                    ),
                  if (camposClienteComanda.contains('descricao'))
                    _linhaDadoCliente(
                      opcaoFonte,
                      'Descrição',
                      perfilHistorico.descricao,
                    ),
                  const SizedBox(height: 6),
                ],
                Center(
                  child: Text(
                    'ITENS',
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                for (final item in perfilHistorico.itens)
                  _linhaComanda(
                    opcaoFonte,
                    item.key,
                    'R\$ ${item.value.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                const SizedBox(height: 8),
                Divider(color: theme.borderColor.withValues(alpha: 0.6)),
                _linhaComanda(opcaoFonte, 'Subtotal', 'R\$ $totalItens'),
                _linhaComanda(
                  opcaoFonte,
                  'TOTAL',
                  'R\$ $totalItens',
                  destaque: true,
                ),
                const SizedBox(height: 4),
                _linhaComanda(
                  opcaoFonte,
                  'Pagamento',
                  'Crédito Mútuo / Autogestão',
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    rodape.isNotEmpty ? rodape : 'linktr.ee/nous72',
                    textAlign: TextAlign.center,
                    style: _estilo(
                      opcaoFonte,
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Tooltip(
            message: 'Imprimir este exemplo de comanda',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: imprimindo ? null : onImprimirExemplo,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: imprimindo
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.textColor,
                        ),
                      )
                    : Icon(
                        Icons.print_outlined,
                        size: 18,
                        color: theme.textColor,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
