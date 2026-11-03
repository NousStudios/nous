# Regra de Arquitetura: Contrato Local-First e Barramento de Rede Local

## 1. O Princípio Local-First do Nous
O Nous opera sob o paradigma descentralizado e offline-first: cada nó (dispositivo Windows, tablet ou smartphone Android) possui seu próprio banco de dados SQLite local isolado.
**Nenhum dado gravado no SQLite de um aparelho existirá em outro aparelho a menos que seja explicitamente transmitido pela rede local.**

## 2. Os 4 Elos Obrigatórios de Toda Funcionalidade Multi-Dispositivo
Qualquer funcionalidade que altere estado entre usuários ou terminais (mensagens de chat, convites de loja, comandas, pedidos, estoques, alteração de papéis) DEVE obrigatoriamente implementar os 4 elos do ciclo de dados:
1. **Persistência Local na Origem:** O dado é salvo imediatamente no SQLite local para garantir resposta instantânea da interface e operação offline.
2. **Despacho Imediato no Barramento Local (WebSocket):** O evento correspondente (`tipo: '...'`) é serializado e transmitido pelo WebSocket através de `ServidorRedeLocal` ou `ClienteRedeLocal`.
3. **Recepção e Persistência no Destino:** O terminal receptor processa o pacote no manipulador de WebSocket, valida a assinatura e grava o registro em seu SQLite local.
4. **Atualização Reativa da Interface Destinatária:** O Provider/Controller receptor é notificado imediatamente para que o usuário veja a mudança em tempo real sem precisar reiniciar o app.

## 3. Handshake e Sincronização na Conexão
Quando um cliente móvel se conecta e se identifica perante o servidor balcão (`tipo: 'identificacao'`), o servidor DEVE:
- Consultar registros e convites pendentes direcionados ao CPF do cliente conectado e despachá-los em lote (`tipo: 'sincronizacao_...'`).
- O cliente DEVE processar a sincronização em lote e atualizar seus providers ativos.

## 4. Estabilidade de Interface e Prevenção de Flickering
- **Proibição de Animações Infinitas em Listas e Cabeçalhos Dinâmicos:** Widgets com animações contínuas baseadas em timer/controller (como `TextoRolante` ou Marquee) **NUNCA** devem ser inseridos em itens de `ListView`, cards de conversas ou cabeçalhos que sofrem frequentes `setState` ou `notifyListeners`.
- Use sempre `Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)` para títulos, subtítulos e nomes de contato.
- **Debouncing de Eventos de Rede:** Ouvintes de notificações de alteração (`alteracoesChatNotifier`, `notificarMudanca`) que disparem releituras de banco de dados devem utilizar `Timer` com debouncing (ex.: 100 a 150 ms) para evitar cascata de rebuilds durante tráfego intenso de pacotes.
