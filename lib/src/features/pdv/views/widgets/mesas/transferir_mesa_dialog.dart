import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class TransferirMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja mesaOrigem;
  final List<MesaLoja> todasMesas;

  const TransferirMesaDialog({
    super.key,
    required this.theme,
    required this.mesaOrigem,
    required this.todasMesas,
  });

  static Future<MesaLoja?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MesaLoja mesaOrigem,
    required List<MesaLoja> todasMesas,
  }) {
    return showDialog<MesaLoja>(
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
          constraints: const BoxConstraints(maxWidth: 440),
          child: TransferirMesaDialog(
            theme: theme,
            mesaOrigem: mesaOrigem,
            todasMesas: todasMesas,
          ),
        ),
      ),
    );
  }

  @override
  State<TransferirMesaDialog> createState() => _TransferirMesaDialogState();
}

class _TransferirMesaDialogState extends State<TransferirMesaDialog> {
  MesaLoja? _mesaDestinoSelecionada;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final outrasMesas = widget.todasMesas
        .where((m) => m.id != widget.mesaOrigem.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Transferir Mesa ${widget.mesaOrigem.numero}',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mover consumo de ${widget.mesaOrigem.quantidadeItensTotal} itens '
            '(${_valorFormatado(widget.mesaOrigem.totalAcumulado)}) para:',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          if (outrasMesas.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Não existem outras mesas cadastradas nesta loja.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: outrasMesas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final mesa = outrasMesas[index];
                  final ehSelecionada = _mesaDestinoSelecionada?.id == mesa.id;
                  final ehLivre = mesa.status == StatusMesa.livre;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _mesaDestinoSelecionada = mesa),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ehSelecionada
                            ? theme.borderColor.withValues(alpha: 0.18)
                            : theme.backgroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ehSelecionada
                              ? theme.textColor
                              : theme.borderColor.withValues(alpha: 0.5),
                          width: ehSelecionada ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_restaurant_outlined,
                            size: 24,
                            color: ehSelecionada
                                ? theme.textColor
                                : theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mesa ${mesa.numero}',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (mesa.descricao.isNotEmpty)
                                  Text(
                                    mesa.descricao,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              ehLivre ? 'Livre' : 'Ocupada (Juntar)',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ehLivre
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _mesaDestinoSelecionada == null
                      ? null
                      : () => Navigator.of(context).pop(_mesaDestinoSelecionada),
                  child: Text(
                    'Transferir',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.buttonTextColor,
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
}
