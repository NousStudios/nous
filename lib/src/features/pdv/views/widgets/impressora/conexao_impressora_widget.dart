import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:printing/printing.dart';

class ConexaoImpressoraWidget extends StatelessWidget {
  final AppTheme theme;
  final String tipoConexao;
  final TextEditingController nomeImpressoraController;
  final TextEditingController enderecoRedeController;
  final List<Printer> impressoras;
  final bool carregandoImpressoras;
  final ValueChanged<String> onTipoConexaoAlterado;
  final VoidCallback onRecarregarImpressoras;
  final VoidCallback onNomeAlterado;

  const ConexaoImpressoraWidget({
    super.key,
    required this.theme,
    required this.tipoConexao,
    required this.nomeImpressoraController,
    required this.enderecoRedeController,
    required this.impressoras,
    required this.carregandoImpressoras,
    required this.onTipoConexaoAlterado,
    required this.onRecarregarImpressoras,
    required this.onNomeAlterado,
  });

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
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

  Widget _linhaImpressora(Printer printer) {
    final selecionada =
        nomeImpressoraController.text.trim() == printer.name;

    return InkWell(
      onTap: () {
        nomeImpressoraController.text = printer.name;
        onNomeAlterado();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selecionada
              ? (theme.buttonColor != Colors.transparent
                  ? theme.buttonColor.withValues(alpha: 0.35)
                  : theme.borderColor.withValues(alpha: 0.25))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionada
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionada ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              printer.isAvailable
                  ? Icons.print_outlined
                  : Icons.print_disabled_outlined,
              size: 18,
              color: theme.textColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextoRolante(
                texto: printer.name,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight:
                      selecionada ? FontWeight.bold : FontWeight.normal,
                  color: theme.textColor,
                ),
              ),
            ),
            if (selecionada)
              Icon(Icons.check, size: 18, color: theme.textColor),
          ],
        ),
      ),
    );
  }

  Widget _listaDeImpressoras() {
    if (carregandoImpressoras) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.textColor,
            ),
          ),
        ),
      );
    }

    if (impressoras.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhuma impressora encontrada.',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: impressoras.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) => _linhaImpressora(impressoras[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Conexão',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('USB', 'usb', tipoConexao, onTipoConexaoAlterado),
              _botaoSelecao(
                  'Bluetooth', 'bluetooth', tipoConexao, onTipoConexaoAlterado),
              _botaoSelecao(
                  'Rede', 'rede', tipoConexao, onTipoConexaoAlterado),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomeImpressoraController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo(
              'Nome da impressora (escolha abaixo ou digite)',
            ),
            onChanged: (_) => onNomeAlterado(),
          ),
          if (tipoConexao == 'rede') ...[
            const SizedBox(height: 8),
            TextField(
              controller: enderecoRedeController,
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              keyboardType: TextInputType.number,
              decoration: _decoracaoCampo('Endereço IP (ex: 192.168.0.50)'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Impressoras encontradas',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: theme.textColor,
                ),
                onPressed:
                    carregandoImpressoras ? null : onRecarregarImpressoras,
              ),
            ],
          ),
          _listaDeImpressoras(),
        ],
      ),
    );
  }
}
