import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

/// Aba de Contrato de Trabalho: tipo, diária padrão, observações e anexos.
class AbaContratoTrabalhadorWidget extends StatelessWidget {
  final AppTheme theme;
  final bool podeGerenciar;
  final TextEditingController tipoContratoController;
  final TextEditingController valorPadraoController;
  final TextEditingController observacoesContratoController;
  final List<String> arquivosContrato;
  final VoidCallback onAnexarArquivo;
  final void Function(String caminho) onRemoverArquivo;
  final VoidCallback onSalvarContrato;

  const AbaContratoTrabalhadorWidget({
    super.key,
    required this.theme,
    required this.podeGerenciar,
    required this.tipoContratoController,
    required this.valorPadraoController,
    required this.observacoesContratoController,
    required this.arquivosContrato,
    required this.onAnexarArquivo,
    required this.onRemoverArquivo,
    required this.onSalvarContrato,
  });

  OutlineInputBorder _borda(Color cor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cor),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de Contrato', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: tipoContratoController,
                    enabled: podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'CLT, PJ, Diarista, Temporário',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: _borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: _borda(theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valor Padrão da Diária', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: valorPadraoController,
                    enabled: podeGerenciar,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: _borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: _borda(theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Observações do Contrato', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
        const SizedBox(height: 4),
        TextField(
          controller: observacoesContratoController,
          enabled: podeGerenciar,
          maxLines: 2,
          style: theme.getTextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Acordos, condições de pagamento, benefícios...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: _borda(theme.borderColor.withValues(alpha: 0.5)),
            focusedBorder: _borda(theme.textColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextoRolante(
                texto: 'Arquivos & Documentos Anexados (${arquivosContrato.length}):',
                style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
              ),
            ),
            if (podeGerenciar) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                onPressed: onAnexarArquivo,
                icon: Icon(Icons.attach_file, size: 14, color: theme.textColor),
                label: Text('Anexar', style: theme.getTextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (arquivosContrato.isEmpty)
          Text('Nenhum documento anexado ainda.', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: arquivosContrato.map((caminho) {
              final nomeArquivo = caminho.split(RegExp(r'[\\/]')).last;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 13, color: theme.textColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: TextoRolante(
                          texto: nomeArquivo,
                          style: theme.getTextStyle(fontSize: 10.5),
                        ),
                      ),
                      if (podeGerenciar) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onRemoverArquivo(caminho),
                          child: Icon(Icons.close, size: 12, color: theme.dangerColor),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        if (podeGerenciar) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
                foregroundColor: theme.textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onSalvarContrato,
              child: Text('Salvar Contrato', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }
}
