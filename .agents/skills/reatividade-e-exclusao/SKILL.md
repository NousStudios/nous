---
name: reatividade-e-exclusao
description: Use whenever creating or editing any dialog, list, deletion, state sync, or network listener in the Nous project.
---

# Reatividade Imediata, Exclusões e Sincronia Multi-Dispositivo

Checklist obrigatório para garantir que qualquer criação, edição ou exclusão reflita na hora na UI local e em todos os aparelhos conectados, sem precisar fechar e reabrir janelas.

## 1. Proibido Congelar Listas em Diálogos
- **Nunca** copie listas mutáveis (`List.of(widget.itens)`) no `initState` sem um listener reativo.
- Use `context.watch<PdvProvider>()`, `context.watch<AuthProvider>()`, `context.watch<NotificacoesProvider>()` ou registre listeners com `addListener`/`removeListener` em:
  - `TimelineService.alteracoesTimelineNotifier` (Timeline, Posts, Stories, Player, Mapa)
  - `ChatService.alteracoesChatNotifier` (Chat, Favoritas, Salas, Participantes, Notificações)
- Em `SincronizadorEstadoLoja`, compare também campos internos mutáveis (ex.: `c.itemIds`, `status`, `quitado`), nunca apenas `id` ou `length`.

## 2. Exclusão = Atualizar Filho, Pai e Resumos
Ao excluir qualquer entidade (`PublicacaoSocial`, `ComentarioSocial`, `StorySocial`, `MensagemChat`, `ConversaChat`, `PedidoLoja`, `MovimentoEstoque`, `MesaLoja`):
1. **Janela/Card atual:** remova o item da lista na hora (`setState` / `Notifier`) ou feche o modal se o item aberto foi excluído (`DialogDetalhesPublicacao`, `FichaKardexDialog`).
2. **Contadores e resumos:** recalcule imediatamente valores derivados (ex.: `ultima_mensagem` em `conversas_chat`, saldo do Kardex, `_totalPosts`).
3. **Sem chamadas duplicadas:** em callbacks de exclusão de diálogos (`CriarMesaDialog`, `DetalhesMidiaDialog`), garanta um único `Navigator.pop()` e um único callback de remoção.
4. **`Dismissible` síncrono:** atualize a lista/Set em memória e chame `notifyListeners()` **antes** de qualquer `await` de gravação em disco.

## 3. Tombstones e Simetria na Rede Local
- Exclusões nunca podem depender apenas do timestamp `desde` no delta sync: sempre envie uma lista leve de IDs excluídos (`idsPublicacoesExcluidas`, `conversas_excluidas`, etc.).
- Ao adicionar metadados de presença em `TerminalConectadoInfo` (ex.: `versaoApp`), envie **tanto** no handshake inicial (`gerenciador_ws_cliente_helper.dart`) quanto nas atualizações (`gerenciador_dispositivo_local.dart`) e no host (`servidor_rede_local.dart`).
