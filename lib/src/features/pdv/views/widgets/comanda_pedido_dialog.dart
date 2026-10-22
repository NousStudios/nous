import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

class ComandaPedidoDialog extends StatelessWidget {
  final String lojaId;
  final PedidoLoja pedido;
  final Cliente? cliente;

  const ComandaPedidoDialog({
    super.key,
    required this.lojaId,
    required this.pedido,
    this.cliente,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String lojaId,
    required PedidoLoja pedido,
    Cliente? cliente,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ComandaPedidoDialog(
        lojaId: lojaId,
        pedido: pedido,
        cliente: cliente,
      ),
    );
  }

  void _abrirDialogCompartilharNoChat(
    BuildContext context,
    AppTheme theme,
    Loja? loja,
    PedidoLoja pedido,
    Cliente? cliente,
  ) {
    final contatos = <({String nome, String identificador, String subtitulo, String foto})>[];
    final cpfClienteNorm = ChatService.normalizarCpf(cliente?.cnpj ?? '');

    if (cliente != null && cliente.nome.isNotEmpty) {
      contatos.add((
        nome: cliente.nome,
        identificador: cpfClienteNorm.isNotEmpty ? cpfClienteNorm : cliente.id,
        subtitulo: 'Cliente deste pedido',
        foto: cliente.foto,
      ));
    }

    if (loja != null) {
      for (final m in loja.membros) {
        final cM = ChatService.normalizarCpf(m.cpf);
        if (cM.isNotEmpty && cM != cpfClienteNorm) {
          contatos.add((
            nome: m.nome,
            identificador: cM,
            subtitulo: 'Equipe • ${m.papel.name.toUpperCase()}',
            foto: '',
          ));
        }
      }
      for (final cli in loja.clientesLoja) {
        final cCli = ChatService.normalizarCpf(cli.cnpj);
        if (cCli.isNotEmpty && cCli != cpfClienteNorm && !contatos.any((c) => c.identificador == cCli)) {
          contatos.add((
            nome: cli.nome,
            identificador: cCli,
            subtitulo: 'Cliente cadastrado',
            foto: cli.foto,
          ));
        }
      }
    }

    final numStr = pedido.numero.toString().padLeft(4, '0');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Enviar Comanda no Chat',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 420),
            child: contatos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Nenhum contato encontrado para compartilhar.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: contatos.length,
                    separatorBuilder: (dialogCtx, index) => Divider(
                      height: 1,
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (dialogCtx, index) {
                      final c = contatos[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                          child: Icon(Icons.person_outline, color: theme.buttonColor, size: 18),
                        ),
                        title: TextoRolante(
                          texto: c.nome,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          c.subtitulo,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        trailing: Icon(Icons.send_rounded, size: 18, color: theme.buttonColor),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final agora = DateTime.now();
                          final convId = loja != null
                              ? ChatService.conversaIdLojaUsuario(loja.id, c.identificador)
                              : 'chat_${c.identificador}';

                          final msg = MensagemChat(
                            id: 'msg_${agora.millisecondsSinceEpoch}',
                            conversaId: convId,
                            remetenteId: loja?.id ?? 'loja',
                            remetenteNome: loja?.nome ?? 'Loja',
                            destinatarioId: c.identificador,
                            texto: 'Pedido #$numStr • R\$ ${pedido.valor.toStringAsFixed(2)}',
                            dataHora: agora,
                            enviadaPorMim: true,
                            tipo: 'comanda',
                            pedidoId: pedido.id,
                            dadosPedidoJson: jsonEncode(pedido.toJson()),
                            lida: false,
                          );

                          await ChatService.salvarMensagem(msg);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                content: Text(
                                  'Comanda #$numStr enviada para ${c.nome} no chat!',
                                  style: theme.getTextStyle(color: theme.textColor),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final pdv = context.read<PdvProvider>();
        final loja = pdv.buscarPorId(lojaId);
        final configImpressora = loja?.configuracoesImpressora;

        var pedidoEfetivo = pedido;
        if (loja != null &&
            (pedidoEfetivo.nomeVendedor.isEmpty ||
                pedidoEfetivo.cnpjVendedor.isEmpty)) {
          pedidoEfetivo = pedidoEfetivo.copyWith(
            nomeVendedor: pedidoEfetivo.nomeVendedor.isNotEmpty
                ? pedidoEfetivo.nomeVendedor
                : loja.nome,
            cnpjVendedor: pedidoEfetivo.cnpjVendedor.isNotEmpty
                ? pedidoEfetivo.cnpjVendedor
                : loja.cnpj,
          );
        }

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: theme.textColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comanda do Pedido',
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: ComandaPedido(
                        theme: theme,
                        pedido: pedidoEfetivo,
                        cliente: cliente,
                        largura: 360,
                        mostrarTitulo: false,
                        camposClienteComanda: configImpressora?.camposClienteComanda ??
                            kCamposClienteComandaPadrao,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (configImpressora != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              side: BorderSide(color: theme.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Imprimir'),
                            onPressed: () async {
                              await ImpressaoService.imprimirComanda(
                                config: configImpressora,
                                pedido: pedidoEfetivo,
                                cliente: cliente,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: theme.cardBackgroundColor,
                                    content: Text(
                                      'Comanda enviada para a impressora.',
                                      style: theme.getTextStyle(color: theme.textColor),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat'),
                          onPressed: () => _abrirDialogCompartilharNoChat(
                            context,
                            theme,
                            loja,
                            pedidoEfetivo,
                            cliente,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
