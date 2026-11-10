import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/views/widgets/balao_mensagem_widget.dart';

/// Modal que exibe todas as mensagens favoritadas de uma conversa específica.
class DialogMensagensFavoritadas {
  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ConversaChat conversa,
    required void Function(MensagemChat) onVisualizarFotoAmpliada,
    required void Function(MensagemChat) onAbrirArquivo,
    required void Function(MensagemChat) onVerComanda,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'conversa_id = ? AND favorita = 1',
      whereArgs: [conversa.id],
      orderBy: 'data_hora DESC',
    );

    final mensagens = rows.map((r) {
      final rem = r['remetente_id'] as String? ?? '';
      return MensagemChat(
        id: r['id'] as String? ?? '',
        conversaId: r['conversa_id'] as String? ?? '',
        remetenteId: rem,
        remetenteNome: r['remetente_nome'] as String? ?? '',
        remetenteFoto: r['remetente_foto'] as String? ?? '',
        destinatarioId: r['destinatario_id'] as String? ?? '',
        texto: r['texto'] as String? ?? '',
        dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        enviadaPorMim: rem == conversa.identificador ? false : true,
        lida: (r['lida'] as int? ?? 0) == 1,
        tipo: r['tipo'] as String? ?? 'texto',
        caminhoAnexo: r['caminho_anexo'] as String? ?? '',
        nomeAnexo: r['nome_anexo'] as String? ?? '',
        tamanhoAnexo: r['tamanho_anexo'] as int? ?? 0,
        pedidoId: r['pedido_id'] as String? ?? '',
        dadosPedidoJson: r['dados_pedido_json'] as String? ?? '',
        editada: (r['editada'] as int? ?? 0) == 1,
        statusEnvio: r['status_envio'] as String? ?? 'enviada',
        entregue: (r['entregue'] as int? ?? 0) == 1,
        favorita: true,
      );
    }).toList();

    if (!context.mounted) return;

    await showDialog(
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
              Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 22),
              const SizedBox(width: 8),
              Text(
                'Mensagens Favoritadas',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
            child: mensagens.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            size: 48,
                            color: theme.secondaryTextColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma mensagem favoritada nesta conversa.',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: mensagens.length,
                    itemBuilder: (context, index) {
                      final m = mensagens[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BalaoMensagemWidget(
                          msg: m,
                          conversa: conversa,
                          enviadaPorMim: m.enviadaPorMim,
                          theme: theme,
                          onMostrarMenu: (_) {},
                          onVerHistoricoEdicoes: (_) {},
                          onAbrirArquivo: (c) => onAbrirArquivo(m),
                          onVisualizarFotoAmpliada: (c) =>
                              onVisualizarFotoAmpliada(m),
                          onVerComanda: (m) => onVerComanda(m),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
