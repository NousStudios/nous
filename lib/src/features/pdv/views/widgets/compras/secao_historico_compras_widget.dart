import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Seção "Histórico de Compras" (Print 1 do protótipo) com acesso aos detalhes
/// do pedido e opção para o comprador avaliar o produto recebido.
class SecaoHistoricoComprasWidget extends StatelessWidget {
  final AppTheme theme;
  final bool modoVisitante;
  final List<RegistroCompraUsuario> historico;
  final void Function(RegistroCompraUsuario reg) onAbrirDetalhes;

  const SecaoHistoricoComprasWidget({
    super.key,
    required this.theme,
    required this.modoVisitante,
    required this.historico,
    required this.onAbrirDetalhes,
  });

  String _rotuloStatus(StatusPedido status) {
    switch (status) {
      case StatusPedido.novo:
        return 'Novo • Aguardando';
      case StatusPedido.aceito:
        return 'Aceito • Em Preparo';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  String _formatarDataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (modoVisitante) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Entre com seu CPF para ver seu histórico de compras.',
      );
    }

    if (historico.isEmpty) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Nenhuma compra registrada ainda.',
      );
    }

    return Column(
      children: historico.map((reg) {
        final p = reg.pedido;
        return InkWell(
          onTap: () => onAbrirDetalhes(reg),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 20,
                  color: theme.textColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${p.numero} • ${reg.nomeLoja}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.produtoNome.isNotEmpty
                            ? p.produtoNome
                            : _rotuloStatus(p.status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${_rotuloStatus(p.status)} • ${_formatarDataHora(p.dataHora)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'R\$ ${p.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
