import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/fontes_app.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/dados_teste_impressora.dart';

class CalibracaoEPreviewComandaWidget extends StatelessWidget {
  final AppTheme theme;
  final double larguraPapelMm;
  final String modeloFonte;
  final String tamanhoFonte;
  final double margemEsquerdaMm;
  final double margemDireitaMm;
  final List<String> camposClienteComanda;
  final PerfilHistoricoAnarquista perfilHistorico;
  final String rodape;
  final bool imprimindo;
  final ValueChanged<double> onLarguraPapelAlterada;
  final ValueChanged<String> onModeloFonteAlterado;
  final ValueChanged<String> onTamanhoFonteAlterado;
  final ValueChanged<double> onMargemEsquerdaAlterada;
  final ValueChanged<double> onMargemDireitaAlterada;
  final VoidCallback onImprimirExemplo;

  const CalibracaoEPreviewComandaWidget({
    super.key,
    required this.theme,
    required this.larguraPapelMm,
    required this.modeloFonte,
    required this.tamanhoFonte,
    required this.margemEsquerdaMm,
    required this.margemDireitaMm,
    required this.camposClienteComanda,
    required this.perfilHistorico,
    required this.rodape,
    required this.imprimindo,
    required this.onLarguraPapelAlterada,
    required this.onModeloFonteAlterado,
    required this.onTamanhoFonteAlterado,
    required this.onMargemEsquerdaAlterada,
    required this.onMargemDireitaAlterada,
    required this.onImprimirExemplo,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _botaoSelecao(
    String rotulo,
    String valor,
    String valorAtual,
    ValueChanged<String> aoSelecionar,
  ) {
    final selecionado = valor == valorAtual;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return InkWell(
      onTap: () => aoSelecionar(valor),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? fundoAtivo : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          rotulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado ? textoAtivo : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _blocoLarguraBobina() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Largura da Bobina Térmica'),
          Text(
            'Escolha a largura do papel térmico instalado na sua impressora.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao(
                '58 mm (Mini / Portátil)',
                '58',
                larguraPapelMm.toInt().toString(),
                (v) => onLarguraPapelAlterada(58.0),
              ),
              _botaoSelecao(
                '80 mm (Balcão Padrão)',
                '80',
                larguraPapelMm.toInt().toString(),
                (v) => onLarguraPapelAlterada(80.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoFonte() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Tipografia da Comanda'),
          Text(
            'Personalize o modelo da letra e o tamanho da fonte da impressão.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Modelo da Letra (Família)',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: FontesApp.obterPorIdOuNome(modeloFonte).id,
                dropdownColor: theme.cardBackgroundColor,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: theme.textColor),
                items: FontesApp.todas.map((opcao) {
                  return DropdownMenuItem<String>(
                    value: opcao.id,
                    child: Text(
                      opcao.rotulo,
                      overflow: TextOverflow.ellipsis,
                      style: FontesApp.criarTextStyle(
                        fontName: opcao.familiaFlutter,
                        color: theme.textColor,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (novoId) {
                  if (novoId != null) {
                    onModeloFonteAlterado(novoId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tamanho da Fonte',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('Pequena (8pt)', 'pequena', tamanhoFonte,
                  onTamanhoFonteAlterado),
              _botaoSelecao('Normal (10pt)', 'normal', tamanhoFonte,
                  onTamanhoFonteAlterado),
              _botaoSelecao('Grande (12pt)', 'grande', tamanhoFonte,
                  onTamanhoFonteAlterado),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colunaRecuo({
    required String titulo,
    required String subtitulo,
    required double valor,
    required ValueChanged<double> aoMudar,
    required List<double> atalhos,
    required double padrao,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          Text(
            subtitulo,
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: valor > 0.5
                    ? () => aoMudar((valor - 0.5).clamp(0.5, 15.0))
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: valor > 0.5
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.textColor, width: 1.4),
                ),
                child: Text(
                  '${valor.toStringAsFixed(1)} mm',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: valor < 15.0
                    ? () => aoMudar((valor + 0.5).clamp(0.5, 15.0))
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: valor < 15.0
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final a in atalhos)
                InkWell(
                  onTap: () => aoMudar(a),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: (valor - a).abs() < 0.1
                          ? (theme.buttonColor != Colors.transparent
                              ? theme.buttonColor
                              : theme.borderColor.withValues(alpha: 0.25))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (valor - a).abs() < 0.1
                            ? theme.textColor
                            : theme.borderColor.withValues(alpha: 0.45),
                        width: (valor - a).abs() < 0.1 ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      '${a.toStringAsFixed(1)}${a == padrao ? '*' : ''}',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: (valor - a).abs() < 0.1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (valor - a).abs() < 0.1
                            ? (theme.buttonColor != Colors.transparent
                                ? theme.buttonTextColor
                                : theme.textColor)
                            : theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoCalibracao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Calibração Bilateral de Recuo (58mm)'),
          Text(
            'Ajuste fino em milímetros caso o texto sofra cortes mecânicos '
            'na borda esquerda ou na borda direita da bobina térmica.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final estreito = constraints.maxWidth < 360;
              if (estreito) {
                return Column(
                  children: [
                    _colunaRecuo(
                      titulo: 'Recuo Esquerdo',
                      subtitulo: 'Início do texto',
                      valor: margemEsquerdaMm,
                      aoMudar: onMargemEsquerdaAlterada,
                      atalhos: const [3.0, 5.0, 6.5, 8.0],
                      padrao: 5.0,
                    ),
                    const SizedBox(height: 10),
                    _colunaRecuo(
                      titulo: 'Recuo Direito',
                      subtitulo: 'Fim dos preços',
                      valor: margemDireitaMm,
                      aoMudar: onMargemDireitaAlterada,
                      atalhos: const [1.5, 3.0, 4.5, 6.0],
                      padrao: 3.0,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _colunaRecuo(
                      titulo: 'Recuo Esquerdo',
                      subtitulo: 'Início do texto',
                      valor: margemEsquerdaMm,
                      aoMudar: onMargemEsquerdaAlterada,
                      atalhos: const [3.0, 5.0, 6.5, 8.0],
                      padrao: 5.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _colunaRecuo(
                      titulo: 'Recuo Direito',
                      subtitulo: 'Fim dos preços',
                      valor: margemDireitaMm,
                      aoMudar: onMargemDireitaAlterada,
                      atalhos: const [1.5, 3.0, 4.5, 6.0],
                      padrao: 3.0,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _blocoPreviewComanda(),
        ],
      ),
    );
  }

  Widget _blocoPreviewComanda() {
    final double escalaFonte = tamanhoFonte == 'pequena'
        ? 0.88
        : tamanhoFonte == 'grande'
            ? 1.15
            : 1.0;

    final opcaoFonte = FontesApp.obterPorIdOuNome(modeloFonte);

    TextStyle estilo({
      required double fontSize,
      Color? color,
      FontWeight fontWeight = FontWeight.normal,
    }) {
      return FontesApp.criarTextStyle(
        fontName: opcaoFonte.familiaFlutter,
        fontSize: fontSize * escalaFonte,
        color: color ?? theme.textColor,
        fontWeight: fontWeight,
      );
    }

    Widget linhaDadoCliente(String rotulo, String valor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$rotulo: ',
              style: estilo(
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
                style: estilo(
                  fontSize: 12,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget linhaComanda(String esquerda, String direita,
        {bool destaque = false}) {
      final ehPreco = direita.trim().startsWith('R\$');

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
                  style: estilo(
                    fontSize: 12,
                    color:
                        destaque ? theme.textColor : theme.secondaryTextColor,
                    fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )
            else
              Text(
                esquerda,
                style: estilo(
                  fontSize: 12,
                  color:
                      destaque ? theme.textColor : theme.secondaryTextColor,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(width: 8),
            if (ehPreco)
              Text(
                direita,
                textAlign: TextAlign.right,
                softWrap: false,
                style: estilo(
                  fontSize: 12,
                  color:
                      destaque ? theme.textColor : theme.secondaryTextColor,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                ),
              )
            else
              Expanded(
                child: Text(
                  direita,
                  textAlign: TextAlign.right,
                  softWrap: true,
                  style: estilo(
                    fontSize: 12,
                    color:
                        destaque ? theme.textColor : theme.secondaryTextColor,
                    fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final double padEsq = 14.0 + (margemEsquerdaMm * 1.5);
    final double padDir = 14.0 + (margemDireitaMm * 1.5);

    return Column(
      children: [
        Divider(color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 15, color: theme.secondaryTextColor),
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
                    style: estilo(
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
                    style: estilo(
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
                    style: estilo(
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
                    style: estilo(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (camposClienteComanda.isNotEmpty) ...[
                  linhaDadoCliente('Cliente', perfilHistorico.cliente),
                  if (camposClienteComanda.contains('cnpj'))
                    linhaDadoCliente('CNPJ/CPF', perfilHistorico.cnpj),
                  if (camposClienteComanda.contains('telefone'))
                    linhaDadoCliente('Telefone', perfilHistorico.telefone),
                  if (camposClienteComanda.contains('endereco'))
                    linhaDadoCliente('Endereço', perfilHistorico.endereco),
                  if (camposClienteComanda.contains('email'))
                    linhaDadoCliente('Email', 'nousstudios72@gmail.com'),
                  if (camposClienteComanda.contains('redesSociais'))
                    linhaDadoCliente('Redes sociais', '@nous.studios72'),
                  if (camposClienteComanda.contains('descricao'))
                    linhaDadoCliente('Descrição', perfilHistorico.descricao),
                  const SizedBox(height: 6),
                ],
                Center(
                  child: Text(
                    'ITENS',
                    style: estilo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                for (final item in perfilHistorico.itens)
                  linhaComanda(
                    item.key,
                    'R\$ ${item.value.toStringAsFixed(2).replaceAll('.', ',')}',
                  ),
                const SizedBox(height: 8),
                Divider(color: theme.borderColor.withValues(alpha: 0.6)),
                linhaComanda(
                  'Subtotal',
                  'R\$ ${perfilHistorico.itens.fold(0.0, (soma, i) => soma + i.value).toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                linhaComanda(
                  'TOTAL',
                  'R\$ ${perfilHistorico.itens.fold(0.0, (soma, i) => soma + i.value).toStringAsFixed(2).replaceAll('.', ',')}',
                  destaque: true,
                ),
                const SizedBox(height: 4),
                linhaComanda('Pagamento', 'Crédito Mútuo / Autogestão'),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    rodape.isNotEmpty ? rodape : 'linktr.ee/nous72',
                    textAlign: TextAlign.center,
                    style: estilo(
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _blocoLarguraBobina(),
        const SizedBox(height: 12),
        _blocoFonte(),
        const SizedBox(height: 12),
        _blocoCalibracao(),
      ],
    );
  }
}
