# DIRETRIZ ARQUITETURAL: NOUS HUB UNIVERSAL & ESCALABILIDADE LOCAL-FIRST

1. **Sem "Big Blob" no SQLite:** `Loja` mantém só metadados, catálogo, categorias, mesas ativas e configs. Listas históricas (`pedidosLoja`, `movimentosEstoque`, `pagamentosFuncionarios`, `turnosCaixa`) ficam em tabelas SQLite próprias com consultas paginadas/filtradas por período (`LIMIT/OFFSET`) e persistência pontual.
2. **Padrão Outbox e Latência Zero:** mutações locais gravam no SQLite e enfileiram na `outbox_eventos` para despacho assíncrono (LAN WebSocket/HTTP, futura Nuvem Soberana, adaptadores). A UI nunca trava esperando rede.
3. **Portas e Adaptadores:** canais externos (WhatsApp, feeds sociais) entram via gateways isolados (`CanalMensagensGateway`, `CanalFeedGateway`), sem acoplar o domínio.
4. **Identificadores e Idempotência:** novas entidades usam UUID v4 + timestamp monotônico UTC; sincronização e reprocessamento devem ser idempotentes (sem `DELETE NOT IN` cegos).
5. **Mídias Relativas:** proibido persistir caminho absoluto (`C:\...` ou `/data/user/0/...`). Usar caminhos relativos normalizados (`/`) com autocura em background (`ImagemService`).
