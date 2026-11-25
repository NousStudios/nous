import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/fontes_app.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/dados_teste_impressora.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/widgets/controles_recuo_impressora_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/widgets/preview_comanda_termica_widget.dart';

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
              _botaoSelecao(
                'Pequena (8pt)',
                'pequena',
                tamanhoFonte,
                onTamanhoFonteAlterado,
              ),
              _botaoSelecao(
                'Normal (10pt)',
                'normal',
                tamanhoFonte,
                onTamanhoFonteAlterado,
              ),
              _botaoSelecao(
                'Grande (12pt)',
                'grande',
                tamanhoFonte,
                onTamanhoFonteAlterado,
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
          ControlesRecuoImpressoraWidget(
            theme: theme,
            margemEsquerdaMm: margemEsquerdaMm,
            margemDireitaMm: margemDireitaMm,
            onMargemEsquerdaAlterada: onMargemEsquerdaAlterada,
            onMargemDireitaAlterada: onMargemDireitaAlterada,
          ),
          const SizedBox(height: 14),
          PreviewComandaTermicaWidget(
            theme: theme,
            modeloFonte: modeloFonte,
            tamanhoFonte: tamanhoFonte,
            margemEsquerdaMm: margemEsquerdaMm,
            margemDireitaMm: margemDireitaMm,
            camposClienteComanda: camposClienteComanda,
            perfilHistorico: perfilHistorico,
            rodape: rodape,
            imprimindo: imprimindo,
            onImprimirExemplo: onImprimirExemplo,
          ),
        ],
      ),
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
