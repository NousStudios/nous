# DIRETRIZ ARQUITETURAL: NOUS HUB UNIVERSAL & ESCALABILIDADE LOCAL-FIRST

> Esta regra define a arquitetura para que o Nous funcione como um organismo Local-First soberano hoje e escale perfeitamente como um **Hub Universal e Rede Social Descentralizada** integrado a nuvens soberanas e canais externos (WhatsApp Business, feeds sociais, etc.).

---

## 1. Eliminação do "Big Blob" no SQLite e Modelos em Memória

1. **Entidades Transacionais Desacopladas:**
   - O objeto `Loja` deve manter em memória apenas metadados, catálogo de produtos, categorias, mesas ativas e configurações de hardware.
   - Listas massivas históricas (`pedidosLoja`, `movimentosEstoque`, `pagamentosFuncionarios`, `turnosCaixa`) NÃO devem ser aninhadas dentro da propriedade JSON única da `Loja` (`dados_json`).
   - Elas residem e são gravadas em suas próprias tabelas SQLite indexadas (`pedidos`, `movimentos_estoque`, `pagamentos_funcionarios`, `turnos_caixa`).
2. **Consultas Paginadas e sob Demanda:**
   - Telas de histórico (Financeiro, Relatórios, Auditoria) devem carregar dados via consultas SQL com filtro por período ou paginação (`LIMIT / OFFSET`), nunca instanciando dezenas de milhares de registros de anos anteriores na memória RAM.
3. **Persistência Pontual:**
   - A criação ou atualização de um pedido deve salvar estritamente aquele registro na tabela `pedidos`, sem resserializar a loja inteira no disco.

---

## 2. O Padrão Outbox (Fila de Eventos Desacoplada)

Para garantir que o Nous funcione sem internet e sincronize de forma assíncrona tanto com o Balcão Wi-Fi quanto com o futuro Servidor em Nuvem e APIs externas (WhatsApp/Redes Sociais):

1. **Gravação Atômica Local-First:**
   - Toda mutação relevante gerada na ponta (nova venda, nova mensagem, alteração de status) é salva localmente e enfileirada na tabela `outbox_eventos`.
2. **Despacho Assíncrono com Garantia de Entrega:**
   - Um orquestrador em background consome a fila e despacha os eventos:
     - Para o Servidor Balcão local (via WebSocket/HTTP local);
     - Para o Servidor Nuvem Soberano (quando houver conexão externa);
     - Para adaptadores de canais externos (ex: bots e webhooks).
3. **Latência Zero na UI:**
   - A interface do usuário NUNCA aguarda resposta de rede para concluir uma ação. O feedback é otimista instantâneo (0ms).

---

## 3. Arquitetura de Portas e Adaptadores (Conectores Externos)

O core do Nous deve ser agnóstico quanto ao canal de transporte ou rede social externa:

1. **Adaptadores de Mensageria (`CanalMensagensGateway`):**
   - A Mensageria Nous deve se comunicar através de gateways abstratos. O mesmo contrato que atende mensagens locais Nous P2P deve permitir plugar adaptadores futuros (ex: `WhatsAppCloudApiAdapter`).
2. **Adaptadores de Feeds e Publicações (`CanalFeedGateway`):**
   - Agregação de publicações sociais e feeds externos via adaptadores isolados, sem injetar regras de redes sociais externas dentro do domínio central do app.
3. **Gateway de Sincronização Unificado:**
   - Uma interface de sincronização única que sabe operar em modo LAN (baixa latência via WebSocket local) e modo Cloud (espelhamento seguro com servidor central brasileiro por delta/timestamps).

---

## 4. Identificadores Globais e Imutabilidade Causal

1. **UUIDs Canônicos:**
   - Novas entidades geradas no app devem utilizar identificadores universais únicos (UUID v4) e carimbo de tempo monotônico (`created_at` / `updated_at` em milissegundos UTC).
2. **Idempotência Estrita:**
   - O reprocessamento de qualquer mensagem de rede ou sincronização de banco deve ser idempotente, usando chaves primárias imutáveis e operações de união aditiva (sem deleções cegas `DELETE NOT IN`).

---

## 5. Mídias Relativas e Resolução Universal

1. **Proibição de Caminhos Absolutos no Banco:**
   - É expressamente proibido persistir caminhos absolutos (`C:\...` ou `/data/user/0/...`) nas colunas do SQLite. Mídias devem ser referenciadas por caminhos relativos normalizados com barras universais (`/`) ou hash de conteúdo.
2. **Autocura Assíncrona:**
   - Se uma mídia referenciada não existir no disco local, o resolvedor (`ImagemService` / `ResolvedorFotoChat`) busca o arquivo em background na rede local ou nuvem, mantendo cache em memória sem travar a renderização das telas.
