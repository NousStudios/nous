# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

## v1.0.97 (build 98) — 10/11/2026

- **Autoatendimento Interativo no Chat, Confirmação Real de Entrega (2 Checks), Lupa de Busca no Chat, Toque Duplo para Copiar, Separadores de Dia, Rolagem Rápida e Lapidação do Perfil no Chat:**
  - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart), [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart), [roteador_chat.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_chat.dart), [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart) & [sincronizador_chat_balcao.dart](file:///d:/Nous/nous/lib/src/features/chat/services/sincronizador_chat_balcao.dart): Corrigida a exibição prematura dos 2 traços cinzas (`entregue`); o evento `mensagem_entregue` agora é emitido exclusivamente quando o verdadeiro destinatário humano recebe a mensagem em seu dispositivo (`souDestinatarioReal && !souApenasRetransmissor`), impedindo que o servidor intermediário ou nós retransmissores marquem entrega antes da chegada real ao destino.
  - [dialog_menu_anexos_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/dialog_menu_anexos_chat.dart): Ícones da janela do clipe de papel padronizados em branco (`theme.textColor`) sobre círculos temáticos (`theme.backgroundColor` + `theme.borderColor`), eliminando cores fixas.
  - [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart) & [painel_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart): Removida a caneta de renomear do cabeçalho do chat (mantida no perfil do contato e no toque longo da lista de conversas) e adicionada lupa (`Icons.search_rounded`) que abre barra de pesquisa em tempo real de palavras-chave no histórico da conversa; adicionado botão flutuante inferior direito (`Icons.keyboard_arrow_down_rounded`) para descer até a última mensagem ao subir o chat e separadores de dia centralizados ("Hoje", "Ontem", "Anteontem", `dd/MM/yyyy`) entre mensagens de dias diferentes.
  - [dialog_detalhes_contato.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_detalhes_contato.dart): Botões "Renomear" e "Compartilhar" (e "Minha Ficha") reduzidos para pílulas compactas com rótulo centralizado; removido o container "Recado" com título torto, destacando apenas a frase da biografia centralizada; adicionado botão **"Identidade do Usuário"** que abre `FichaUsuarioDialog` respeitando integralmente as configurações de transparência e privacidade da conta Nous.
  - [dialog_fazer_pedido_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_fazer_pedido_chat.dart), [modal_personalizar_item_autoatendimento.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/widgets/modal_personalizar_item_autoatendimento.dart), [chat_autoatendimento_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_autoatendimento_service.dart), [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart) & [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Catálogo de "Fazer Pedido" no chat 100% interativo; toque em qualquer card de item ou categoria adiciona/personaliza variantes, grupos de componentes (`GrupoComponentesLoja` com contadores `+`/`-`), quantidades, observações, forma de pagamento e acesso a "Minha Ficha", despachando a comanda diretamente no chat e na aba **"Novos"** da loja com alerta sonoro (`SomService.eventoNovoPedido`).
  - [card_mensagem_comanda.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/cards/card_mensagem_comanda.dart) & [mensageria_acoes_delegate.dart](file:///d:/Nous/nous/lib/src/features/chat/services/mensageria_acoes_delegate.dart): Comanda enviada no chat exibe badge em tempo real da etapa do pedido ("AGUARDANDO ACEITE (NOVOS)", "EM PREPARO (ACEITO)", "CONCLUÍDO", "CANCELADO") e permite ao operador da loja avançar a etapa diretamente pelo card.
  - [balao_mensagem_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/balao_mensagem_widget.dart): Toque duplo rápido (`onDoubleTap`) em qualquer mensagem do chat copia instantaneamente seu conteúdo para a área de transferência.
  - [conversa_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/conversa_chat.dart), [chat_conversas_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_conversas_service.dart) & [item_conversa_tile.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/item_conversa_tile.dart): Ativado `TextoRolante` para nomes e prévias que excedem a largura na barra da lista de conversas e adicionados os traços de status (`enviada`, `entregue`, `lida`) ao lado da prévia das mensagens enviadas pelo usuário.
  - **Instaladores Atualizados (v1.0.97 • Build 98):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.96 (build 97) — 09/11/2026

- **Autoatendimento pelo Chat, Ficha de Cliente da Loja, Fim do Google Files ao Cancelar Galeria, Retransmissão Instantânea e Ação de Renomear:**
  - [chat_autoatendimento_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_autoatendimento_service.dart): Criado serviço soberano de autoatendimento no chat com resolução e vinculação automática de ficha de cliente sem duplicação (busca cruzada por CPF e nome), montagem do pedido com status `StatusPedido.novo` (direto para a aba 'Novos' do balcão da loja), despacho em tempo real via WebSocket/REST e envio simultâneo de mensagem de comanda interativa no chat.
  - [dialog_fazer_pedido_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_fazer_pedido_chat.dart): Criado diálogo completo de cardápio no chat ao conversar com lojas; navegação de categorias por chips, catálogo com fotos, preços e descrições, submodal de seleção de adicionais/componentes (`GrupoComponentesLoja`), sacola de compras com subtotal acumulado, campo de observações e confirmação de entrega.
  - [dialog_editar_ficha_cliente_loja.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_editar_ficha_cliente_loja.dart): Criado diálogo para o cliente visualizar e atualizar seus próprios dados de contato e endereço na ficha cadastral daquela loja, preservando estritamente os campos financeiros e regras comerciais restritas ao comerciante.
  - [dialog_menu_anexos_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/dialog_menu_anexos_chat.dart): Adicionado botão "Fazer Pedido" com ícone de cardápio nas conversas com loja.
  - [mensageria_acoes_delegate.dart](file:///d:/Nous/nous/lib/src/features/chat/services/mensageria_acoes_delegate.dart): Corrigida a abertura de galeria e câmera; ao cancelar ou fechar o seletor no Android, o app agora retorna pacificamente ao chat em vez de abrir indevidamente o Google Files via fallback de desktop.
  - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart) & [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart): Retransmissão de mensagens via WebSocket acelerada para 0ms (despacho imediato aos nós clientes antes da gravação em disco) e envio instantâneo de `mensagem_entregue` pelo receptor, eliminando atrasos na entrega entre celulares.
  - [item_conversa_tile.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/item_conversa_tile.dart), [dialog_detalhes_contato.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_detalhes_contato.dart) & [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart): Botão de "Renomear conversa" agora acessível tanto no menu contextual de toque longo quanto na janela de detalhes e no cabeçalho; botão redundante "Conversar" removido dos detalhes e ações rápidas reorganizadas com espaçamento harmonioso.
  - **Instaladores Atualizados (v1.0.96 • Build 97):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.95 (build 96) — 09/11/2026

- **Lapidação da Mensageria (Padrão WhatsApp): Mensagens Favoritadas, Silenciamento de Conversas, Menu Contextual Posicionado, Painel de Anexos Estilizado, Detalhes com Recado e Foto em Tela Cheia:**
  - [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart): Ocultado botão de lápis no mobile (preservando espaço no topo para o nome do contato e status com `TextoRolante`); 3 pontos removidos conforme solicitação (abertura direta tocando no avatar/nome).
  - [mensagem_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/mensagem_chat.dart) & [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Adicionado suporte completo à marcação de mensagens favoritas (`favorita: true`), com persistência no SQLite e estrela indicadora no balão de mensagem.
  - [conversa_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/conversa_chat.dart) & [chat_conversas_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_conversas_service.dart): Adicionado campo e persistência de `silenciada` para conversas, com ícone de mudo no card e supressão de sons/notificações no `ChatService.deveNotificarConversa`.
  - [item_conversa_tile.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/item_conversa_tile.dart): Menu contextual ao segurar a conversa (`LongPress`) agora se posiciona exatamente sobre a conversa selecionada via coordenadas do widget, com opções de silenciar/reativar notificações, fixar e arquivar.
  - [dialog_menu_mensagem.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_menu_mensagem.dart) & [dialog_mensagens_favoritadas.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_mensagens_favoritadas.dart): Menu da mensagem com opção de favoritar/desfavoritar e novo diálogo dedicado para listar e pesquisar todas as mensagens com estrela da conversa.
  - [dialog_menu_anexos_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/dialog_menu_anexos_chat.dart): Painel de anexos estilo WhatsApp ao tocar no clipe: grade estilizada com botões de Galeria (com `ImagePicker` nativo), Documento, Contato Nous (compartilhamento de fichas de perfil), Comanda e atalhos com badge "Em construção" (Localização, Enquete, PIX, Evento).
  - [dialog_detalhes_contato.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_detalhes_contato.dart): Avatar do contato com toque para visualização em tela cheia com zoom (`InteractiveViewer`); exibição do recado/biografia importado do perfil público Nous (`usuario.biografia`); `ThemedSwitch` para silenciar conversa; atalhos rápidos para mensagens favoritadas e mídias compartilhadas.
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): Blindagem otimista contra sumiço de mensagens pendentes durante recarregamentos assíncronos do SQLite.
  - [chat_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_service.dart): Confirmação de leitura em grupos calibrada para marcar `entregue` (2 checks cinzas) na recepção de outros membros, evitando falso check azul prematuro.
  - **Instaladores Atualizados (v1.0.95 • Build 96):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.94 (build 95) — 09/11/2026

- **Refinamento do Chat: Otimização de Mídias por WebSocket, Presença de Loja, Cabeçalho Compacto e Blindagem de Leitura:**
  - [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart): Removido o botão de 3 pontos (`Icons.more_vert`) no cabeçalho do chat (já acionado tocando no nome/avatar); botões laterais compactados para 28x28; integrado `TextoRolante` para nome do contato e `@username` quando excederem o espaço útil no celular; presença de lojas corrigida para checar `loja.aberta` e presença de membros da equipe online (loja fechada exibe "Fechada", aberta sem atendente exibe "Ausente" e aberta com atendente exibe "Online").
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): Blindada a confirmação de visualização/leitura (`lida: true` e 2 checks azuis); apenas o verdadeiro destinatário humano com o chat em foco pode confirmar leitura; servidores intermediários ou balcão operando como retransmissores na rede local nunca marcam visualizado prematuramente.
  - [chat_media_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_media_service.dart): Teto de mídias embutidas em Base64 no WebSocket (`limiteBytesBase64Ws`) elevado de 64 KB para 512 KB, permitindo tráfego instantâneo de fotos compactadas (< 50ms) sem engasgos de timeout HTTP.
  - [dialog_encaminhar_mensagem.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_encaminhar_mensagem.dart): Adicionado card de prévia com miniatura da imagem ou resumo do anexo/áudio no topo do diálogo de encaminhamento; resolução precisa das miniaturas de avatar de cada contato na lista.
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): Cascata resiliente de CPF na inicialização e recarregamento (`conta?.cpf ?? auth.cpf ?? pdv.cpfAtual ?? obterCpfLogadoLocal()`), garantindo que conversas e busca nunca sumam no desktop.
  - [dialog_detalhes_contato.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_detalhes_contato.dart): Extração do CPF canônico do interlocutor via `ChatService.extrairOutroCpf` ao clicar em "Ver Perfil Público", prevenindo congelamento ao navegar para o perfil civil/social.
  - **Instaladores Atualizados (v1.0.94 • Build 95):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.93 (build 94) — 09/11/2026

- **Engenharia de Escalabilidade e Fluidez: Compressão de Imagens, Retomada de Segundo Plano, Alívio do PdvProvider e Desafogamento do Big Blob:**
  - [imagem_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/imagem_service.dart): Implementada compressão e redimensionamento automático de imagens nativo em C++ (`otimizarBytesImagem` via `dart:ui.instantiateImageCodec`); fotos de alta resolução (câmera de 8-12 MB) são redimensionadas para teto de 1200px e otimizadas abaixo de 250 KB ao salvar ou receber mídias, evitando sobrecarga de memória (crash OOM no celular) e travamentos na rede local.
  - [mensageria_acoes_delegate.dart](file:///d:/Nous/nous/lib/src/features/chat/services/mensageria_acoes_delegate.dart) & [aba_gestao_nous_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/aba_gestao_nous_widget.dart): `ImagePicker` padronizado com `maxWidth: 1280, maxHeight: 1280, imageQuality: 82` para compressão primária no nível do sistema operacional.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart) & [main.dart](file:///d:/Nous/nous/lib/main.dart): Implementado monitoramento contínuo de ciclo de vida (`AppLifecycleListener` em `inicializarMonitoramentoCicloVida`); ao destravar o celular ou retomar o app em primeiro plano (`onResume`), dispara `verificarEAutoReconectarNaRetomada`, restabelecendo sockets e enviando ping de validação sem exigir intervenção do usuário.
  - [pdv_gastos_ponto_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_gastos_ponto_helper.dart) & [pdv_layout_impressora_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_layout_impressora_helper.dart): Modularização arquitetural do `PdvProvider`, desacoplando gastos diários/fixos, registro de ponto, contratos/escalas de trabalho e calibrações de layout/impressora térmica em helpers coesos e reutilizáveis.
  - [status_loja_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/status_loja_view.dart) & [financeiro_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/financeiro_view.dart): Substituição de `context.watch<PdvProvider>()` por `context.select<PdvProvider, Loja?>((p) => p.buscarPorId(...))`, eliminando rebuilds globais desnecessários e piscadas na interface.
  - [pedidos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pedidos_repositorio_loja.dart), [movimentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/movimentos_repositorio_loja.dart) & [pagamentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pagamentos_repositorio_loja.dart): Desafogamento do Big Blob em memória RAM (janela ativa de 80 pedidos concluídos, 120 movimentos e 100 pagamentos mantidos na memória rápida, com histórico completo consultado sob demanda via paginação no SQLite).
  - **Instaladores Atualizados (v1.0.93 • Build 94):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.92 (build 93) — 09/11/2026

- **Referencial Reativo de Presença (Online/Ausente) no Chat e Blindagem de Reconexão Wi-Fi Local:**
  - [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart): Implementado referencial de presença reativo em tempo real logo abaixo do nome do contato/loja no cabeçalho do chat; ponto verde vibrante (`0xFF4CAF50`) + "Online" quando conectado na rede local; ponto branco translúcido suave + "Ausente" quando desconectado; suporte adaptativo a contagem de membros ativos em grupos.
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart): Eliminação de conexões órfãs/zumbis; encerra imediatamente sockets antigos do mesmo IP antes de aceitar novo handshake WebSocket de terminais reconectados.
  - [sincronizacao_rede_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart): Memorização persistente do último IP do balcão (`nous_ultimo_ip_balcao`) carregada automaticamente nos inputs manuais; injeção antecipada de `PdvProvider` e `AuthProvider` na inicialização do radar de rede.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): `iniciarDescoberta` agora aceita injeção direta de provedores de estado para auto-conexão instantânea assim que o balcão for detectado.
  - [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Disparo silencioso de `tentarAutoConectarSeDisponivel` em segundo plano ao efetuar login ou restaurar sessão local, permitindo que o celular reconecte sem exigir navegação manual em telas de configuração.
  - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart): Drenagem automática da fila de saída de mensagens (`drenarFilaDeSaida`) disparada imediatamente após a identificação de um terminal reconectado.
  - **Instaladores Atualizados (v1.0.92 • Build 93):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.91 (build 92) — 09/11/2026

- **Sincronização em Tempo Real e Persistência de Notificações Dispensadas por Loja na Rede Local:**
  - [notificacoes_provider.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/providers/notificacoes_provider.dart): Criado armazenamento persistente de notificações dispensadas por loja (`_notificacoesDispensadasPorLoja`) gravado no `SharedPreferences` local (`nous_notificacoes_dispensadas_loja_$lojaId`), com despacho imediato via WebSocket do evento `notificacoes_loja_limpas` para a rede local.
  - [notificacoes_dialog.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/views/widgets/notificacoes_dialog.dart): Ao dispensar ou limpar todas as notificações (alertas de estoque baixo, mensagens da loja), dispara `dispensarNotificacoesLoja` propagando para todos os membros da loja na rede; `onDismissed` e botões de limpeza sincronizam dispensas sem ressurgir em outros aparelhos.
  - [chat_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_service.dart): `marcarMensagensDaLojaComoLidas` corrigido para despachar evento canônico `mensagens_lidas_loja` associado ao `lojaId`, resolvendo o bug em que mensagens da loja permaneciam com badge não-lido nos demais terminais.
  - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart) & [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart): Tratamento bidirecional dos eventos `notificacoes_loja_limpas` e `mensagens_lidas_loja` com retransmissão automática para todos os clientes conectados.
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart), [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart) & [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): Integração de `notificacoesDispensadasLoja` no handshake de `dados_iniciais` e no endpoint `/api/loja`, garantindo que novos terminais conectados herdem instantaneamente o estado limpo das notificações.
  - **Instaladores Atualizados (v1.0.91 • Build 92):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.90 (build 91) — 09/11/2026

- **Eliminação Total de Flickering/Piscamento da UI, Correção de Fuso e Autocura Temporal de Horários no Chat:**
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): Removida tempestade de rebuilds contínuos; `recarregarMensagensConversaAtiva` agora realiza dirty-checking comparando mensagens em memória antes de disparar `notifyListeners()`; `_iniciarPollingLeve` ajustado para intervalo relaxado (25s) sem forçar reconstrução da tela; envio de mensagens blindado contra propagação de timestamps corrompidos do passado.
  - [sincronizador_chat_balcao.dart](file:///d:/Nous/nous/lib/src/features/chat/services/sincronizador_chat_balcao.dart) & [roteador_chat.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_chat.dart): Notificações de alteração (`ChatService.notificarAlteracao()`) agora só disparam se mensagens ou conversas novas/modificadas forem efetivamente gravadas no SQLite local, eliminando o loop perpétuo de requisições e desmontagens visuais da lista de conversas.
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): `salvarMensagem` com deduplicação sem ruído, ignorando registros idênticos; cálculo de monotonia temporal protegido contra desvios de relógio de mensagens antigas.
  - [balao_mensagem_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/balao_mensagem_widget.dart), [lista_conversas_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/lista_conversas_widget.dart), [mensagem_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/mensagem_chat.dart) & [conversa_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/conversa_chat.dart): Todos os timestamps passam obrigatoriamente por `.toLocal()`, corrigindo a anomalia em que mensagens em fusos UTC exibiam 3 horas a mais no fuso de Brasília.
  - [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Adicionada rotina `curarTimestampsAnomalosDoPassado()` que higieniza e corrige retroativamente mensagens que haviam sido gravadas com horários no futuro por bugs de timezone legados.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart) & [sincronizacao_rede_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart): Timeouts de conexão HTTP em rede local reduzidos de 12s para 3s (conexão) e 4s (leitura), permitindo falhas ágeis e reconexão imediata; adicionado parâmetro `forcar: true` em conexões manuais para não travar cliques repetidos do usuário.
  - **Instaladores Atualizados (v1.0.90 • Build 91):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.89 (build 90) — 09/11/2026

- **Otimização do Envio de Mídias/Fotos no Chat e Desacoplamento de Cargas Úteis do WebSocket:**
  - [chat_media_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_media_service.dart): Limite máximo de Base64 embutido no payload do WebSocket reduzido de 3.5MB para 64KB (`limiteBytesBase64Ws`), reservado exclusivamente para miniaturas e áudios ultraleves; mídias maiores passam a transitar obrigatoriamente via stream binário HTTP.
  - [chat_sincronizacao_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_sincronizacao_service.dart): Sanitização de caminhos de arquivos transmitidos pelo balcão para formato relativo canônico (`imagens/nome_arquivo`), garantindo que clientes Android baixem mídias sem conflito com caminhos absolutos do Windows.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): `enviarMensagemChat` atualizado para despachar uploads HTTP multipart em segundo plano para imagens, áudios e arquivos anexos, transmitindo via WebSocket apenas metadados ultraleves (< 500 bytes).
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): `processarMensagemRecebidaRede` estendido para disparar downloads remotos automáticos em segundo plano tanto para imagens quanto para áudios e anexos, atualizando o SQLite e a interface reativamente após o término da transferência.
  - **Instaladores Atualizados (v1.0.89 • Build 90):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.88 (build 89) — 08/11/2026

- **Reconexão Wi-Fi Instantânea, Auto-Autorização Soberana de Terminais e Histórico de Dispositivos Conectados:**
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): `conectar()` atualizado com fallback para SharedPreferences (`ultimo_cpf_login`), garantindo que o handshake com o balcão envie o CPF do usuário mesmo durante o boot do aplicativo ou antes da finalização do login em memória; timeout do handshake ajustado para 12s para falha e recuperação ágeis.
  - [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart): Terminais na rede local Wi-Fi são auto-autorizados instantaneamente (membro se autenticado na equipe; cliente para pedidos, cardápio e chat), eliminando diálogos modais bloqueantes de 45 segundos e os consequentes timeouts de reconexão de 35 segundos ("Não foi possível conectar ao balcão").
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart) & [servidor_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede/servidor_balcao_widget.dart): Implementação do histórico de terminais registrados na sessão (`terminaisHistorico`); a seção "Outros Dispositivos na Rede (Não Pareados)" agora reflete com precisão os terminais que se desconectaram (rotulados como "Desconectado (Nous Fechado ou Fora do Alcance)") em vez de escutar um notifier vazio do cliente.
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): `inicializar()` passa a resolver o CPF, nome, foto e apelido do usuário logado caso não tenham sido passados no construtor (ex.: abertura via barra inferior); adicionado timer periódico de polling leve (4s) para drenar mensagens pendentes e reconciliar com o balcão em caso de oscilações na rede Wi-Fi.
  - [sincronizador_chat_balcao.dart](file:///d:/Nous/nous/lib/src/features/chat/services/sincronizador_chat_balcao.dart): Notificação reativa garantida (`ChatService.notificarAlteracao()`) ao término do download de mensagens do balcão, atualizando a interface imediatamente.
  - **Instaladores Atualizados (v1.0.88 • Build 89):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.87 (build 88) — 08/11/2026

- **Consistência Absoluta na Mensageria P2P Local-First, Correção de Autoria e Saneamento Canônico de Conversas:**
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): `salvarMensagem` corrigido para atribuir `identificadorSalvar = outroCpf` (interlocutor) ao criar conversas 1:1, eliminando a falha crítica em que conversas recebidas eram salvas com o CPF do próprio receptor; `processarMensagemRecebidaRede` atualizado para garantir `enviadaPorMim: false` em mensagens de terceiros e status `lida` ou `recebida`; `consolidarConversasDuplicadas` agora utiliza a chave canônica P2P `user_${min}_user_${max}` em vez do campo `identificador`, impedindo que conversas de contatos distintos fossem mescladas ou apagadas por engano.
  - [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Adicionada rotina de autocura e migração em `_migrarHistoricoExistenteParaConversas`, unificando automaticamente no SQLite mensagens e conversas salvas com chaves invertidas para o padrão canônico `user_${min}_user_${max}`.
  - [chat_conversas_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_conversas_service.dart): `obterTodasConversas` e `obterOuCriarConversa` blindados para resolver deterministicamente o `identificador` como o CPF do interlocutor (`outroCpf`), corrigindo inconsistências em registros antigos.
  - [resolvedor_conversa_info_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_conversa_info_service.dart) & [curador_conversas_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/curador_conversas_chat.dart): Blindagem na identificação de interlocutores, garantindo que o outro participante seja extraído deterministicamente mesmo quando o banco de dados contiver registros legados.
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): `enviarMensagem` passa a garantir que em conversas diretas o `destinatarioId` seja sempre o CPF do interlocutor extraído do ID canônico; integração de `ChatService.drenarFilaDeSaida()` na reconexão à rede local para envio imediato de mensagens pendentes (Outbox Pattern).
  - **Instaladores Atualizados (v1.0.87 • Build 88):** Compilação para Windows e Android na pasta `dist/`.

- **Otimização Soberana da Mensageria Local-First, Blindagem do Histórico Ativo e Sincronização Suave de Mensagens:**
  - [mensagem_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/models/mensagem_chat.dart): `MensagemChat.fromJson` atualizado para oferecer suporte bidirecional resiliente tanto a camelCase quanto a snake_case (`conversa_id`, `remetente_id`, `data_hora`, `status_envio`, `caminho_anexo`) e inteiros booleanos (`0/1`), corrigindo a perda crítica de `conversaId` durante a drenagem de filas offline e sincronizações com o balcão.
  - [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): `carregarMensagens` aprimorado para suportar buscas com chave simétrica em conversas `user_${min}_user_${max}` e eliminação automática no banco de mensagens corrompidas com `conversa_id` em branco.
  - [mensageria_controller.dart](file:///d:/Nous/nous/lib/src/features/chat/controllers/mensageria_controller.dart): Adição do método de recarga cirúrgica `recarregarMensagensConversaAtiva()` (sub-5ms) que atualiza apenas as mensagens da conversa aberta sem reconstruir todas as lojas e contas; blindagem de `recarregarConversas()` e `selecionarConversa()` para nunca sobrescrever mensagens já carregadas em memória por listas vazias.
  - [mensageria_view.dart](file:///d:/Nous/nous/lib/src/features/chat/views/mensageria_view.dart): `_aoAtualizarChat` passa a atualizar as mensagens da conversa aberta imediatamente e aplica debounce de 300ms na reconstrução da lista lateral de contatos, eliminando travamentos de UI e tempestades de rebuild.
  - [sincronizador_chat_balcao.dart](file:///d:/Nous/nous/lib/src/features/chat/services/sincronizador_chat_balcao.dart) & [roteador_chat.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_chat.dart): Inserções de sincronização em lote agora usam `notificar: false` durante loops de mensagens e conversas, disparando uma notificação consolidada única ao final do processamento.
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): `consolidarConversasDuplicadas` prioriza determinismo para IDs canônicos `user_\d{11}_user_\d{11}` ao mesclar registros legados.
  - **Instaladores Atualizados (v1.0.86 • Build 87):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.85 (build 86) — 06/11/2026

- **Recusa Soberana de Pedidos (Cancelamento em Vez de Exclusão), Blindagem de Débitos de Clientes e Barra do Trabalhador Responsiva em 2 Linhas no Celular:**
  - [gerenciador_pedidos_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart): `recusarPedido` passa a atualizar o status para `StatusPedido.cancelado` com motivo `'Recusado pelo atendente'`, `dataHoraCancelamento` e auditoria com autor, além de disparar difusão imediata `pedido_atualizado` na rede local e atualizar `ultimaDataGerado` do `PedidoProgramado` correspondente. Isso elimina a ressurreição de pedidos recusados na aba Novos, encerra loops de autocura de pedidos ausentes e impede a duplicação indevida do valor a prazo devido pelo cliente.
  - [pdv_pedidos_programados_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart): `verificarEGerar` agora reconhece que o cliente com pedido programado já foi atendido hoje se já existir qualquer pedido ativo do mesmo dia emitido para ele (mesmo com valor aumentado ou modificado), impedindo a criação de pedidos agendados duplicados no mesmo dia.
  - [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Clientes móveis secundários são proibidos de forçar a cura de pedidos com status `novo` ausentes no balcão/servidor, preservando a soberania do host sobre a fila de novos pedidos.
  - [bloco_trabalhadores_status_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart), [card_membro_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios/card_membro_loja_widget.dart) & [barra_trabalhador_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios/barra_trabalhador_widget.dart): Implementação de layout responsivo com `LayoutBuilder`: em telas de celular (`maxWidth < 560px`), a linha superior exibe a foto do membro, o nome completo e cargo/CPF/status/diária com espaço amplo e legibilidade total, enquanto os botões de ação ("Mensagem", "Contrato", "Identidade do Usuário", "Horários e Escala" e "Histórico de Pagamentos") descem para uma segunda linha alinhada à direita com espaçamentos compactos e botões de toque confortável.
  - [contabilidade_pdv_pedidos_test.dart](file:///d:/Nous/nous/test/contabilidade_pdv_pedidos_test.dart): Nova suíte de testes unitários contábeis cobrindo débito a prazo de clientes, pedidos cancelados/recusados, pedidos quitados, blindagem anti-duplicação de agendados e precedência de status cancelado na reconciliação de rede.
  - **Instaladores Atualizados (v1.0.85 • Build 86):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.84 (build 85) — 06/11/2026

- **Blindagem Anti-Zumbi de Pedidos na Rede Local, Soberania do Balcão e Proteção Diária de Pedidos Programados:**
  - [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Implementação do filtro de soberania do nó balcão na autocura reversa via LAN; celulares e terminais secundários agora só enviam pedidos locais ausentes no balcão se tiverem sido emitidos estritamente na data de hoje e não forem pedidos antigos com status `novo` de dias passados, impedindo que dispositivos reconectados ressuscitem pedidos mortos no servidor e nos demais terminais.
  - [pdv_pedidos_programados_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart): Blindagem reforçada da geração diária de pedidos programados (`verificarEGerar`); verificação múltipla combinando ID determinístico (`prog_${id}_${ano}_${mes}_${dia}`), prefixo e correspondência de cliente e valor total no dia de hoje, além de checar `prog.ultimaDataGerado`. Evita qualquer regeneração ou duplicação de pedidos agendados ao relogar ou reiniciar a aplicação no balcão.
  - [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart): Expurgo profilático em `consolidar`; pedidos pendentes com status `novo` de dias anteriores são descartados na mesclagem de pedidos ativos da loja.
  - [bloco_pedidos_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja/bloco_pedidos_gestao_widget.dart): Aba `Novos` passa a filtrar estritamente pedidos com status `novo` cuja data seja a do dia atual (`mesmoDia(p.dataHora, agora)`).
  - [gerenciador_pedidos_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart): Criação de cancelamento silencioso (`cancelarPedidoSilencioso`) com motivo `'Expirado por decurso de prazo'` para purgar pedidos zumbis de dias anteriores na abertura da loja; fila automática de novos pedidos e som de alerta protegem contra pedidos fora da data atual e pedidos programados já atendidos hoje.
  - [pedidos_programados_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/pedidos_programados_dialog.dart): Diálogo de agendados do dia oculta programações que já possuem pedidos ativos ou atendidos gerados hoje.
  - **Instaladores Atualizados (v1.0.84 • Build 85):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.83 (build 84) — 06/11/2026

- **Conexão Fluida no Wi-Fi com Radar Híbrido (UDP Multi-Interface + Varredura Ativa HTTP), Permissão de Multicast Android e Sincronização Pan-Dispositivo Bidirecional de Lojas e Contas:**
  - [AndroidManifest.xml](file:///d:/Nous/nous/android/app/src/main/AndroidManifest.xml): Adição da permissão `android.permission.CHANGE_WIFI_MULTICAST_STATE` para impedir que dispositivos Android (incluindo Blackview e sistemas com economia agressiva de energia) descartem pacotes de broadcast UDP no Wi-Fi.
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart): Descoberta refinada de IP local em `obterIpLocal()` ignorando adaptadores virtuais (WSL, Docker, VirtualBox, VMware, Hyper-V); anúncio UDP emitido simultaneamente para todos os endereços de broadcast das placas de rede físicas locais (`subrede.255`) e `255.255.255.255`.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): Implementação do **Radar Ativo de Sub-rede HTTP** em segundo plano (`_iniciarVarreduraAtivaHttp()`) com consulta prioritária imediata ao último IP conectado (`/api/status` em 500ms) e varredura concorrente da sub-rede local em lotes paralelos de 25 IPs, garantindo que o terminal encontre o balcão em 2 a 3 segundos mesmo se o roteador bloquear tráfego UDP broadcast.
  - [sincronizacao_rede_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede_dialog.dart): Abertura inteligente da aba "Celular (Cliente)" por padrão em dispositivos móveis (Android e iOS), melhorando a experiência imediata de sincronização.
  - [roteador_usuarios.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_usuarios.dart) & [sincronizador_usuarios_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart): Sincronização integral independente do host balcão operar como Usuário Nous pessoal ou Loja; inclusão de lojas de referências do host no espelhamento; extração automática e cadastro no cofre de Contas Nous dos membros e clientes com CPF de todas as lojas recebidas e consolidadas (`_extrairContasNousDeLoja`).
  - [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart) & [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart): Implementação do método `sincronizarDadosUsuarioEmLojas(UsuarioNous)` para propagar em tempo real mudanças de nome, apelido e foto de contas Nous para os registros de clientes, fornecedores e membros de todas as lojas.
  - **Instaladores Atualizados (v1.0.83 • Build 84):** Compilação para Windows e Android na pasta `dist/`.

- **Nova Venda Desktop Sem Rolagem, Filtro de Período DD/MM/AAAA Corrigido, Gastos Fixos Recorrentes, Barra do Trabalhador Unificada, Central de Contrato e Privacidade Soberana:**
  - [nova_venda_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda_dialog.dart) & [comanda_resumo_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/comanda_resumo_nova_venda_widget.dart): Reorganização de Nova Venda no Desktop movendo o container "Formas de Pagamento" para baixo do container da "Comanda" (Coluna 1: cliente, produtos, ajustes; Coluna 2: comanda expandida sem corte, pagamentos e botão concluir), permitindo finalizar pedidos por cliques diretos na tela sem necessidade de scroll vertical prévio.
  - [data_input_formatter.dart](file:///d:/Nous/nous/lib/src/core/utils/data_input_formatter.dart): Criação do formatador soberano `DataInputFormatterBR` calculando a posição do cursor baseada estritamente nos dígitos digitados antes da inserção, eliminando o bug de digitação de datas brasileiras (`11/05/2021` virando `05/20/2111`); aplicação em [historico_compras_cliente_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/historico_compras_cliente_widget.dart), [item_linha_financeira.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart) e [filtros_relatorio_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/relatorios/filtros_relatorio_widget.dart).
  - [historico_compras_cliente_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/historico_compras_cliente_widget.dart): Reorganização visual limpa dos filtros em dois níveis: linha superior com filtros de datas selecionadas, formas de pagamento e ação de limpar; e linha inferior com os inputs `De: DD/MM/AAAA` e `Até: DD/MM/AAAA` com navegação por setas e date picker.
  - [gasto_fixo.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/gasto_fixo.dart), [dialog_novo_gasto_fixo.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/dialog_novo_gasto_fixo.dart) & [subcontainer_gastos_do_dia_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/subcontainer_gastos_do_dia_widget.dart): Criação da entidade `GastoFixo` com suporte à recorrência diária, semanal, mensal, dias alternados e dias da semana específicos; nova aba no subcontainer "Gastos do dia" com formulário de cadastro e alternância de status pago/pendente.
  - [bloco_resumo_operacional_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_resumo_operacional_widget.dart) & [bloco_funcionarios_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_funcionarios_financeiro_widget.dart): Integração do novo indicador unificado **Total Devido (A Pagar)** agrupando diárias a prazo de funcionários, compras a prazo de estoque e gastos do dia a prazo; integração das diárias com formas de pagamento e status de quitação.
  - [bloco_trabalhadores_status_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart): Preservação da barra tradicional de Status da Loja com foto por CPF, status online/offline, grade de dispositivos conectados na rede local com ícones de computador balcão / celular e IPs individuais, e adição dos novos botões de Mensagem direta, Identidade do Usuário e gaveta de Horários de Entrada/Saída (ponto eletrônico) e Escala Semanal.
  - [card_membro_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios/card_membro_loja_widget.dart) & [barra_trabalhador_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios/barra_trabalhador_widget.dart): Componente visual padronizado adaptado aos contextos de Financeiro e Perfil da Loja com botões de mensagem direta, troca de cargo e acesso à central de contrato.
  - [contrato_trabalho_membro.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/contrato_trabalho_membro.dart), [registro_ponto_membro.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/registro_ponto_membro.dart), [escala_trabalho_membro.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/escala_trabalho_membro.dart) & [dialog_central_contrato_trabalhador.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios/dialog_central_contrato_trabalhador.dart): Criação da **Central Soberana de Contrato do Trabalhador** com 5 abas integradas (Histórico financeiro, Módulo de Contrato com anexo de arquivos via `file_selector`, Ponto eletrônico com duração, Escala semanal e Identidade Nous).
  - [bloco_privacidade_conta_widget.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/conta_nous/bloco_privacidade_conta_widget.dart) & [usuario_nous.dart](file:///d:/Nous/nous/lib/src/features/auth/models/usuario_nous.dart): Expansão das permissões de privacidade da Conta Nous cobrindo biografia, e-mails, pagamentos/diárias de terceiros, escala e registros de ponto; garantia da hierarquia estrita de exibição de nomes soberanos (Nome Completo $\rightarrow$ Apelido $\rightarrow$ @Usuário Nous).
  - [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart) & [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Mesclagem e autocura das quatro novas entidades (`gastosFixos`, `contratosTrabalho`, `registrosPonto`, `escalasTrabalho`) em rede local e persistência soberana no SQLite.
  - **Instaladores Atualizados (v1.0.82 • Build 83):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.81 (build 82) — 04/11/2026

- **Filtros e PDF Personalizado no Histórico do Cliente, Frete Automático por Cliente, Forma de Pagamento Voucher e Subcontainer Gastos do Dia no Financeiro:**
  - [cliente.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/cliente.dart) & [frete_cliente_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/frete_cliente_widget.dart): Criação do campo persistido `fretePadrao` no modelo `Cliente` e do novo container visual **"Frete"** na janela `ClientesDialog` posicionado logo acima do container "A Prazo", permitindo configurar a taxa de entrega padrão do cliente.
  - [nova_venda_controller.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart) & [modo_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao_widget.dart): Preenchimento automático do valor de frete na comanda do pedido ao selecionar um cliente que possui taxa de frete cadastrada, preservando a liberdade do operador de ajustar ou zerar o valor na hora.
  - [historico_compras_cliente_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/historico_compras_cliente_widget.dart), [exportador_pdf_extrato_cliente.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/exportador_pdf_extrato_cliente.dart), [relatorios_pdf_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios_pdf_service.dart) & [impressao_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao_service.dart): Adição de filtros por período de data (Hoje, 7 dias, Mês, Todas) e forma de pagamento no histórico de compras do cliente; emissão do documento PDF A4 refletindo exatamente os pedidos filtrados e exibindo a descrição dos filtros aplicados no cabeçalho.
  - **Forma de Pagamento Voucher em Todo o PDV:** Inclusão de "Voucher" nas formas oficiais de pagamento em [nova_venda_controller.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart), [modo_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao_widget.dart), [fechar_conta_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/fechar_conta_mesa_dialog.dart), [financeiro_operacoes_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/financeiro_operacoes_helper.dart), [impressao_utils.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/impressao_utils.dart), [pdf_formatacao_util.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/pdf_formatacao_util.dart) e [programar_pedido_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido_dialog.dart).
  - [gasto_diario.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/gasto_diario.dart), [loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/loja.dart), [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart), [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart) & [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Criação da entidade soberana `GastoDiario` armazenada na `Loja` com reconciliação e cura em malha de rede local; métodos `adicionarGastoDiario` e `removerGastoDiario` no `PdvProvider`.
  - [subcontainer_gastos_do_dia_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/subcontainer_gastos_do_dia_widget.dart), [bloco_compras_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_compras_financeiro_widget.dart), [bloco_resumo_operacional_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_resumo_operacional_widget.dart) & [financeiro_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/financeiro_view.dart): Adição do subcontainer **"Gastos do dia"** dentro do container Compras para lançamento ágil de compras avulsas de abertura de portas (carnes, feira); integração no container **"Resumo Operacional do Dia"** com métrica de gastos declarados e cálculo comparativo do Saldo Operacional.
  - [cliente_frete_voucher_gastos_test.dart](file:///d:/Nous/nous/test/cliente_frete_voucher_gastos_test.dart): Novos testes unitários cobrindo o frete padrão do cliente, a forma de pagamento Voucher e a consolidação de gastos diários.
  - **Instaladores Atualizados (v1.0.81 • Build 82):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.80 (build 81) — 04/11/2026

- **Padronização da Comanda Impressa Conforme o Container da Comanda e Herança de Calibração da Impressora entre Lojas:**
  - [gerador_bobina_comanda.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/gerador_bobina_comanda.dart) & [pedido_programado.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/pedido_programado.dart): Remoção do bloco `Ref: ${pedido.comanda}` da comanda térmica impressa e limpeza do campo `comanda` em `PedidoProgramado.toPedidoLoja`. Isso elimina tanto a linha indevida `Ref: Programado: ...` nos pedidos agendados quanto a impressão duplicada em texto ASCII (`========================================`) que saía no topo das comandas de vendas normais quando `double.infinity` foi ativado.
  - [impressao_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao_service.dart): `ImpressaoService.imprimirComanda` e `imprimirComandaPedido` agora usam `config.camposClienteComanda` da loja por padrão quando `camposClienteComanda` não é passado explicitamente.
  - [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Adição de `_herdarCalibracaoImpressoraEntreLojasLocais` e propagação da calibração física da impressora (`modeloFonte`, `tamanhoFonte`, `margemEsquerdaMm`, `margemDireitaMm`, `larguraPapelMm`, `nomeImpressora`) entre lojas do mesmo terminal, garantindo que lojas recém-criadas (como `Berenice`) imprimam exatamente com a mesma fonte, margens e impressora já calibradas pelo usuário na estação (como `Providence`).
  - [modo_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao_widget.dart): Correção em `_finalizarVenda` para gravar o nome e o CNPJ da loja (`nomeVendedor` e `cnpjVendedor`) na comanda em vez do nome/CPF do operador.
  - **Instaladores Atualizados (v1.0.80 • Build 81):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.79 (build 80) — 04/11/2026

- **Baixa de Estoque e Impressão Automática no Aceite de Pedidos Programados, União de Movimentações de Turno de Caixa, Sincronização de Quitação de Fiado, Blindagem de Mesas Liberadas e Dívida no Modo Balcão:**
  - [gerenciador_pedidos_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart) & [comanda_novo_pedido_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/comanda_novo_pedido_dialog.dart): Ao aceitar um pedido em `StatusPedido.novo` (como pedidos programados/agendados), o sistema agora calcula e aplica automaticamente a baixa de estoque (`EstoqueBaixaService.calcularMovimentosBaixa`), transmite cada `MovimentoEstoque` na rede local (`estoque_atualizado`), registra na auditoria e dispara a impressão automática da comanda se `imprimirAutomaticoAoConcluir` estiver ativo.
  - [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart) & [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Adição de `ConsolidadorLojaLocal.mesclarDoisTurnosCaixa` para unir por ID todas as movimentações (`MovimentoCaixa` de suprimentos e sangrias) de um mesmo turno aberto entre terminais; blindagem na reconciliação de `MesaLoja` para impedir que celulares reconectados com cache antigo ressuscitam mesas já fechadas/liberadas no balcão.
  - [mesa_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/mesa_loja.dart): `MesaLoja.copyWith` agora limpa `dataHoraAbertura` automaticamente quando a mesa retorna para `StatusMesa.livre`.
  - [gerenciador_clientes_fornecedores_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_clientes_fornecedores_loja.dart): Correção da ordem de execução em `pagarCliente` para registrar o suprimento em dinheiro no caixa antes de persistir/difundir o estado da loja e envio individual de `pedido_atualizado` na rede local para cada pedido quitado parcial ou totalmente.
  - [modo_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao_widget.dart) & [cliente_ajustes_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao/cliente_ajustes_balcao_widget.dart): Exibição do selo `Deve R$ XX,XX` (`theme.dangerColor`) na busca e no chip do cliente selecionado no Modo Balcão, e unificação da baixa de estoque do Modo Balcão via `EstoqueBaixaService.calcularMovimentosBaixa` (incluindo acompanhamentos).
  - **Instaladores Atualizados (v1.0.79 • Build 80):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.78 (build 79) — 04/11/2026

- **Busca Instantânea de Clientes e Produtos na Nova Venda, Layout Desktop com Comanda Completa à Direita e Indicador de Dívida do Cliente:**
  - [nova_venda_controller.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart): Correção de `aoDigitarCliente` para acionar `clienteFocado = true` e `notifyListeners()` a cada tecla digitada (antes só notificava se já houvesse um cliente selecionado para desmarcar); adição de listener direto em `buscaController` para atualização instantânea na pesquisa de produtos; atualização de `obterDadoPrioritarioCliente` para exibir **Endereço (com número) + Telefone** combinados (`Rua X, 123 • (11) 99999-0000`) e adição de `dividaDoCliente(Cliente)` somando o saldo de pedidos `aPrazoEmAberto`.
  - [nova_venda_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda_dialog.dart), [comanda_resumo_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/comanda_resumo_nova_venda_widget.dart) & [gerenciador_dialogs_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_dialogs_loja.dart): Reorganização do layout Desktop em duas colunas de `Nova Venda`, posicionando **Nome do Cliente**, **Produto Solicitado**, **Frete/Desconto/Acréscimo**, **Formas de Pagamento** e o botão **Concluir Venda** na coluna esquerda (`flex: 6`) e a **Comanda** na coluna direita (`flex: 5`, `expandirAltura: true`) sem a trava de `maxHeight: 350` que cortava a visualização da comanda.
  - [cliente_seletor_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/cliente_seletor_nova_venda_widget.dart), [bloco_produtos_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/bloco_produtos_nova_venda_widget.dart), [lista_pesquisa_clientes_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/lista_pesquisa_clientes_widget.dart) & [clientes_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes_dialog.dart): Substituição do `Column` não-virtualizado e dos timers de `TextoRolante` nas listas de clientes e produtos por `ListView.builder` virtualizado e `Text(..., overflow: TextOverflow.ellipsis)`, eliminando gargalos de renderização ao digitar; inclusão do selo `Deve R$ XX,XX` (`theme.dangerColor`) na barra de cada cliente com pendência em aberto tanto na `Nova Venda` quanto na janela `Clientes`.
  - [impressora_e_pedidos_programados_test.dart](file:///d:/Nous/nous/test/impressora_e_pedidos_programados_test.dart): Adição de testes unitários para `NovaVendaController` validando notificação imediata ao digitar no campo de cliente, formatação simultânea de endereço + telefone e cálculo de dívida em aberto.
  - **Instaladores Atualizados (v1.0.78 • Build 79):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.77 (build 78) — 04/11/2026

- **Correção Definitiva de Impressão Térmica em Bobina Contínua (Sem Corte em 200mm) e Ciclo Completo de Pedidos Programados:**
  - [impressao_utils.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/impressao_utils.dart), [gerador_bobina_comanda.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/gerador_bobina_comanda.dart), [gerador_bobina_caixa.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/gerador_bobina_caixa.dart), [gerador_bobina_mesa.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/gerador_bobina_mesa.dart), [gerador_bobina_financeiro.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/impressao/gerador_bobina_financeiro.dart) & [impressora_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/impressora_dialog.dart): Substituição da altura fixa de `200mm` (que fazia o `pw.Column.layout` do pacote `pdf` abortar o loop de renderização após os primeiros itens da comanda) por altura de bobina contínua (`double.infinity`) durante o layout, seguida da extração da altura finita exata calculada pelo `pw.Page.postProcess` via `ImpressaoUtils.formatoResolvidoDoDocumento` para o spooler nativo do Windows (`Printing.directPrintPdf`). Compactação de divisores e colunas (`mainAxisSize: pw.MainAxisSize.min`) e repasse de `_larguraPapelMm` nos botões de teste e exemplo.
  - [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart) & [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Correção na consolidação de `pedidosProgramados` para que edições, pausas (`ativo: false`), `ultimaDataGerado` e exclusões prevaleçam e nunca sejam revertidas ou ressuscitadas pela cópia anterior em memória ou cache de terminais móveis; preservação das configurações locais de hardware de impressora quando ausentes em payloads remotos.
  - [pedido_programado.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/pedido_programado.dart), [pdv_pedidos_programados_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart), [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart) & [gerenciador_pedidos_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart): Sincronização imediata entre `PdvProvider` e a lista local `pedidos` do controlador da loja ao gerar pedidos programados, transmissão via WebSocket/REST (`pedido_adicionado`), cópia de `observacao` para `comentario`, resolução garantida de telefone/endereço do cliente (`resolverCliente`) e limpeza automática de pedidos ainda em `StatusPedido.novo` ao pausar ou excluir uma programação.
  - [programar_pedido_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido_dialog.dart), [pedidos_programados_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/pedidos_programados_dialog.dart), [pedidos_programados_cliente_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/clientes/pedidos_programados_cliente_widget.dart) & [pedidos_programados_relatorio_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/relatorios/pedidos_programados_relatorio_widget.dart): Suporte completo para edição de pedidos programados existentes (`pedidoExistente`), adição de `descricaoFrequenciaCurta` (eliminando duplicação do horário no cabeçalho do card), exibição do pedido real gerado no dia (`resolverPedidoDoDia` com número `#00XX` real em vez de `#0000`), remoção de `TextoRolante` em listas e substituição de cores fixas por `theme.dangerColor` com diálogo de confirmação ao excluir.
  - [impressora_e_pedidos_programados_test.dart](file:///d:/Nous/nous/test/impressora_e_pedidos_programados_test.dart): Novos testes unitários validando impressão térmica sem corte em comandas > 200mm e todo o ciclo de vida de pedidos programados.
  - **Instaladores Atualizados (v1.0.77 • Build 78):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.76 (build 77) — 04/11/2026

- **Blindagem de Persistência SQLite Multi-Loja, Isolamento de Rede e Integridade de Exclusões:**
  - [movimentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/movimentos_repositorio_loja.dart), [pagamentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pagamentos_repositorio_loja.dart) & [pedidos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pedidos_repositorio_loja.dart): Correção crítica nas colunas obrigatórias `NOT NULL` do SQLite (`item_id`, `tipo`, `custo_total` em `movimentos_estoque` e `valor` em `pagamentos_funcionarios`) que causavam rollback transacional silencioso ao salvar lojas do mesmo CPF (ex.: registros da loja Berenice quando a loja Laricas possuía movimentações de estoque); inclusão de métodos atômicos `excluirPorId` e `excluirTodosDaLoja`.
  - [lojas_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/lojas_service.dart), [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart) & [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Refatoração de `salvarLojaIndividual` para operar de forma atômica e isolada apenas sobre o `loja.id` alvo (sem recarregar nem tocar nas demais lojas do mesmo CPF dono) e preservação de exclusões locais (`mesclarColecoesRemotas: false` em salvamentos locais, além de limpeza física nas tabelas SQLite ao excluir pedidos, movimentos de estoque, pagamentos ou resetar transações).
  - [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart), [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart), [despachante_cliente_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/despachante_cliente_rede.dart), [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart) & [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart): Inclusão de `lojaId` explícito em `/api/movimento_estoque`, `/api/mesa`, `estoque_atualizado` e `mesa_atualizada`; desbloqueio de sincronização em rede para lojas secundárias editadas em terminais conectados e preservação de `manterItensAusentes: true` em `/api/sincronizar_perfis_usuario`.
  - [backup_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/backup_service.dart): `desduplicarLojas` agora exige coincidência de ID ou coincidência simultânea de CNPJ válido (não-placeholder) e nome normalizado, impedindo fusão acidental de lojas distintas.
- **Restauração da Soberania de Login e Logout (Eliminação de Auto-Login Forçado):**
  - [login_view.dart](file:///d:/Nous/nous/lib/src/features/auth/views/login_view.dart) & [auth_provider.dart](file:///d:/Nous/nous/lib/src/features/auth/providers/auth_provider.dart): Removida a rotina de restauração automática forçada de sessão no `LoginView`. A tela de login volta a ser o ponto de entrada neutro para digitar o CPF desejado e alternar contas com total liberdade; o logout agora encerra a sessão de forma imediata e permanente.
  - [AndroidManifest.xml](file:///d:/Nous/nous/android/app/src/main/AndroidManifest.xml): Configurado `android:launchMode="singleTask"` com `android:alwaysRetainTaskState="true"`, permitindo que o Android preserve a tarefa e a tela atual em memória ao minimizar o app, sem necessidade de auto-login persistente em disco.
  - [README.md](file:///d:/Nous/nous/README.md): Atualização da árvore de diretórios (`core/` e `features/`), referências de versão (`v1.0.76`) e paridade entre as seções em Inglês e Português com os avanços recentes da mensageria, privacidade de CPF e rede local.
  - **Instaladores Atualizados (v1.0.76 • Build 77):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.75 (build 76) — 03/11/2026

- **Intercalação Bilateral Perfeita de Chat (Esquerda/Direita) e Título Centralizado da Conversa:**
  - [painel_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart) & [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Reformulação cirúrgica da determinação de `enviadaPorMim`. No Modo Loja, o lado direito pertence estritamente à Loja ativa e mensagens de clientes ficam na esquerda. No Modo Usuário, o lado direito pertence ao CPF do usuário e mensagens de lojas ficam na esquerda, mesmo quando o mesmo operador atende e conversa consigo mesmo na própria loja (eliminando o problema de mensagens agrupadas do mesmo lado).
  - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): Na recepção de mensagens da rede, mensagens originadas de uma loja nunca mais são marcadas indevidamente como `enviadaPorMim = true` no nó do cliente quando o `cpfAtendente` coincide com o CPF do usuário logado.
  - [banner_titulo_conversa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/banner_titulo_conversa_widget.dart): O título/assunto personalizado da conversa agora é exibido de forma centralizada e com tipografia maior e destacada no início do histórico da conversa.
  - [montador_conversas_modo_social.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/montador_conversas_modo_social.dart), [montador_conversas_modo_loja.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/montador_conversas_modo_loja.dart) & [curador_conversas_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/curador_conversas_chat.dart): O título customizado da conversa não mais sobrescreve o nome real da Loja ou Contato (`titulo`), sendo armazenado estritamente em `tituloConversa`. O cabeçalho superior com botões de chamada preserva sempre o Nome Real da Loja/Contato.
  - [chat_mensageria_test.dart](file:///d:/Nous/nous/test/chat_mensageria_test.dart): Adicionado teste unitário cobrindo o alinhamento e intercalação de lados na conversa com a própria loja.
  - **Instaladores Atualizados (v1.0.75 • Build 76):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.74 (build 75) — 03/11/2026

- **Isolamento Absoluto de Pedidos por Loja, Correção Crítica de Mensageria e Notificações Android:**
  - [pedido_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/pedido_loja.dart): Inclusão do campo estrutural soberano `lojaId` em `PedidoLoja`, garantindo rastreabilidade e pertencimento invariante do pedido à loja de origem através de todo o ciclo de vida e trânsito em rede local.
  - [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart) & [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart): Blindagem no roteamento e persistência de pedidos e lojas. O endpoint `/api/loja/atualizar` e a rota de pedidos agora salvam no cofre individual da loja correspondente ao `lojaId`, sem jamais descartar dados de lojas secundárias ou sobrescrever dados da loja ativa balcão (resolvendo o sumiço dos dados da loja Berenice e a mistura com outras lojas).
  - [banco_dados_service.dart](file:///d:/Nous/nous/lib/src/core/services/banco_dados_service.dart) & [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Rotina de autocura no SQLite: expurgo retroativo de mensagens corrompidas/fantasmas (payloads de controle de entrega/leitura gravados indevidamente no banco) e realocação do pedido extraviado para a loja correta.
  - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart), [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart) & [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): Eventos `mensagem_entregue` e `mensagens_lidas` agora são tratados como eventos de protocolo sem geração de mensagens espúrias no chat; resolução do crash de notificações Android e do bug onde o sino de notificações ficava aceso eternamente.
  - [resolvedor_conversa_info_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_conversa_info_service.dart) & [resolvedor_foto_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_foto_chat.dart): Identificação fidedigna do interlocutor loja vs. cliente, garantindo que o cabeçalho da loja sempre renderize a logo da loja e nunca a foto do próprio usuário logado.
  - [AndroidManifest.xml](file:///d:/Nous/nous/android/app/src/main/AndroidManifest.xml) & [auth_provider.dart](file:///d:/Nous/nous/lib/src/features/auth/providers/auth_provider.dart): Configuração `android:alwaysRetainTaskState="true"` e restauração automática de sessão (`tentarRestaurarSessao`), evitando deslogar ao minimizar o aplicativo.
  - **Instaladores Atualizados (v1.0.74 • Build 75):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.73 (build 74) — 03/11/2026

- **Regras de Firewall Automáticas, Broadcast UDP Multi-Interface e Timeout Ágil de Conexão:**
  - [windows/installer.iss](file:///d:/Nous/nous/windows/installer.iss): Adicionadas regras automáticas no instalador Windows com permissão de administrador (`PrivilegesRequired=admin`) para liberar o `nous.exe`, a porta TCP 8080 (Servidor Balcão) e a porta UDP 45454 (Descoberta Wi-Fi) no Windows Defender Firewall em qualquer perfil de rede (`profile=any`).
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart): Broadcast UDP expandido para enviar datagramas para `255.255.255.255` e diretamente para o broadcast de sub-rede (`192.168.0.255`), contornando o bloqueio de roteadores comerciais entre o cabo Ethernet e o rádio Wi-Fi.
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): Timeout de conexão TCP (`connectionTimeout`) reduzido para 4 segundos, evitando congelamento da interface e permitindo troca ágil entre IPs de balcão.
  - **Instaladores Atualizados (v1.0.73 • Build 74):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.72 (build 73) — 03/11/2026

- **Checagem Imediata de Atualização, Mascaramento Universal de CPF, Manutenção de Sessão no Android e Correções de UI/Mensageria:**
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart), [contas_usuario_view.dart](file:///d:/Nous/nous/lib/src/features/auth/views/contas_usuario_view.dart) & [perfis_pdv_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/perfis_pdv_view.dart): Verificação prioritária de nova versão no balcão (`verificarAtualizacaoLocal`) executada imediatamente em background sem aguardar rotinas pesadas de sincronização, disparada logo após a escolha de e-mail e na entrada de perfis.
  - [AndroidManifest.xml](file:///d:/Nous/nous/android/app/src/main/AndroidManifest.xml): Remoção de `android:taskAffinity=""`, permitindo que o Android preserve a sessão e a task do usuário aberta ao minimizar o aplicativo.
  - [cpf_validator.dart](file:///d:/Nous/nous/lib/src/features/auth/services/cpf_validator.dart), [bloco_trabalhadores_status_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart), [ficha_usuario_dialog.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario_dialog.dart) & [identidade_ativa_card_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede/identidade_ativa_card_widget.dart): Mascaramento universal de CPF (`123.•••.•••-••`) respeitando a privacidade dos membros; inclusão de botão de alternância com olho aberto/fechado para o próprio usuário revelar ou manter protegido (ideal para capturas de tela).
  - [usuarios_conectados_rede_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede/usuarios_conectados_rede_widget.dart): Reposicionamento ergonômico do indicador verde `[X online na rede]` logo acima da lista de dispositivos; aplicação de `TextoRolante` e mascaramento de CPF na lista de usuários.
  - [servidor_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/sincronizacao_rede/servidor_balcao_widget.dart): Nova seção exibindo lista de dispositivos detectados na rede Wi-Fi que ainda não estão pareados ao balcão.
  - [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart): Correção na contagem de mensagens não lidas (`temMensagensNaoLidasNoUsuario`), desconsiderando mensagens enviadas pelo próprio usuário logado; o botão de notificações agora apaga pontualmente assim que as mensagens recebidas são lidas.
  - [resolvedor_foto_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_foto_chat.dart): Blindagem da conversa com lojas (`ehContatoLoja`); a foto da loja busca estritamente a logo cadastrada no PDV e nunca mais é sobrescrita pela foto do usuário logado.
  - [balao_mensagem_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/balao_mensagem_widget.dart) & [painel_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart): Eliminação de balões vazios minúsculos apenas com horário; mensagens sem texto e sem anexo são ignoradas.
  - [bloco_pedidos_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja/bloco_pedidos_gestao_widget.dart), [bloco_produtos_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/bloco_produtos_nova_venda_widget.dart), [cliente_seletor_nova_venda_widget.dart](file:///d:/Nous/nova_venda/cliente_seletor_nova_venda_widget.dart) & [conexao_impressora_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/impressora/conexao_impressora_widget.dart): Substituição de textos que truncavam em `...` por `TextoRolante` contínuo.
  - **Instaladores Atualizados (v1.0.72 • Build 73):** Compilação para Windows e Android na pasta `dist/`.

## v1.0.71 (build 72) — 03/11/2026

- **Máscara de Privacidade no CPF de Login com Ícone de Olho Dinâmico:**
  - [cpf_input_widget.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/cpf_input_widget.dart): Implementação do `CpfTextEditingController` com ofuscação inteligente via `buildTextSpan`; exibe os 3 primeiros dígitos do CPF digitado e mascara os números subsequentes com ponto no meio da linha (`123.•••.•••-••`), mantendo os números reais no buffer para login e validações sem erros de cursor ou quebras de digitação.
  - [cpf_input_widget.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/cpf_input_widget.dart): Inclusão do botão de olho aberto/fechado (`Icons.visibility_outlined` / `Icons.visibility_off_outlined`) com alinhamento visual simétrico (`prefixIcon` e `suffixIcon`); o ícone desaparece de forma limpa quando o campo está vazio e surge imediatamente ao digitar.
  - [cpf_input_mascara_test.dart](file:///d:/Nous/nous/test/cpf_input_mascara_test.dart): Testes de widget garantindo o comportamento visual de ofuscação e alternância de visibilidade do CPF.
  - **Instaladores Atualizados (v1.0.71 • Build 72):** Versão incrementada para detecção e atualização automática em nós móveis (Android) e Windows via Wi-Fi.

## v1.0.70 (build 71) — 03/11/2026

- **Ordenação Decrescente de Pedidos na Gestão do Perfil (Mais Recentes no Topo):**
  - [bloco_pedidos_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja/bloco_pedidos_gestao_widget.dart): Os pedidos exibidos nas quatro abas ("Novos", "Aceitos", "Concluídos" e "Cancelados") passam a ser ordenados universalmente do mais recente para o mais antigo por `dataHora` (com desempate pelo `numero` do pedido decrescente), garantindo que o operador e a marmitaria visualizem os pedidos mais atuais no topo da lista.
  - [sincronizacao_pan_dispositivo_test.dart](file:///d:/Nous/nous/test/sincronizacao_pan_dispositivo_test.dart): Teste unitário adicionado validando a ordenação decrescente precisa por data/hora e número de pedido.
  - **Instaladores Atualizados:** Nova compilação dos instaladores para Windows (`.exe` via Inno Setup) e Android (`.apk`) gerados na pasta `dist/`.

- **Conexão Instantânea Wi-Fi, Máquina de Estados Soberana de Pedidos e Notificações Android Nativas:**
  - [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart): Conexão WebSocket imediata em milissegundos após handshake HTTP; reconciliação mútua de imagens e mídias pesadas movida para execução assíncrona em segundo plano (`unawaited`), eliminando estouro de timeout de 35s que impedia conexão quando o servidor era iniciado por loja com catálogo extenso.
  - [consolidador_loja_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/consolidador_loja_local.dart): Implementação da máquina de estados unidirecional para mesclagem de pedidos (`mesclarDoisPedidos`); estados terminais (`concluido` e `cancelado`) e em andamento (`aceito`) prevalecem sobre estados anteriores (`novo`), garantindo que pedidos concluídos no balcão atualizem imediatamente no celular, além de preservar quitações, pagamentos parciais e notas.
  - [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Harmonização de pedidos na reconciliação de rede utilizando `mesclarDoisPedidos`, evitando regressão de status e perda de dados.
  - [roteador_usuarios.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_usuarios.dart): Em `/api/sincronizar_perfis_usuario`, o servidor agora inspeciona todas as lojas do host e disponibiliza lojas em que o solicitante participa como membro, assegurando que o celular receba a loja e o histórico mesmo quando o servidor balcão for iniciado em modo Usuário Nous; remoção de chamada concorrente a `entrarComCpf`.
  - [sincronizador_usuarios_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart): Substituição da chamada destrutiva `entrarComCpf` pós-sincronização por sincronização leve (`adicionarOuAtualizarLoja` e `notificarMudanca`), eliminando gargalos no SQLite e travamentos no tráfego de mensagens.
  - [notificacao_android_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/notificacao_android_service.dart): Adequação estrita às normas do Android `MessagingStyle` (definição de `conversationTitle: null` e `groupConversation: false` em conversas 1:1 para evitar quebra de layout na gaveta do sistema, fallback de texto descritivo para mídias/fotos, remoção de `colorized: true` e uso de ícone nativo sem conflito).
  - [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart): Uso do getter reativo `lojaAtiva` no handshake `dados_iniciais`, garantindo que o snapshot enviado contenha sempre os pedidos mais recentes em memória.
  - **Qualidade e Testes:** Novo teste unitário em [sincronizacao_pan_dispositivo_test.dart](file:///d:/Nous/nous/test/sincronizacao_pan_dispositivo_test.dart) validando transição para estados terminais de pedidos; 105 de 105 testes aprovados e 0 avisos no `dart analyze`.

- **Isolamento Absoluto de Identidade: Correção de Foto Civil do Dono vs Logo da Loja no Chat:**
  - [resolvedor_foto_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_foto_chat.dart): Resolução soberana do avatar civil; impede o descarte da foto quando o contato é o próprio usuário logado (`ehProprioUsuario`), blinda qualquer contato físico (CPF de 11 dígitos) contra contaminação por `loja.logo` e restringe o uso de logos comerciais exclusivamente para conversas cujo alvo seja comprovadamente uma loja (`ehContatoLoja`).
  - [montador_conversas_modo_loja.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/montador_conversas_modo_loja.dart): Ao montar a lista de conversas no Modo Loja, fixa `ehLoja: false` (o contato com cliente ou equipe é uma pessoa física, enquanto o escopo é delimitado por `lojaId`); assegura que clientes que coincidam com o operador logado (`ehProprioOperador`) recebam imediatamente a foto civil do perfil Nous.
  - [chat_conversas_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_conversas_service.dart): Autocura profilática no carregamento de conversas persistidas; recupera a foto civil do usuário logado e de contas conhecidas, sanando históricos legados onde a logo da loja havia sido gravada no SQLite.
  - [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart): Em `buscarFotoClientePorCpf`, valida `loja.logo.isEmpty || cliente.foto != loja.logo`, garantindo que a logo da loja nunca seja propagada como foto de cliente.
  - [resolvedor_conversa_info_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_conversa_info_service.dart): Define `ehLoja: false` ao gerar metadados de conversas de loja com usuários/clientes (`cpfUsuario.isNotEmpty`).
  - **Qualidade, Estabilidade e Testes:** Novo teste automatizado em [chat_mensageria_test.dart](file:///d:/Nous/nous/test/chat_mensageria_test.dart), 0 erros no `dart analyze` e 104 testes aprovados no `flutter test`.

## v1.0.69 (build 70) — 03/11/2026

- **Sincronização Pan-Dispositivo Robusta no Chat (Celular/Desktop), Isolamento de Perfil Nous vs Logo de Loja, Notificações Android e Otimização da Barra do Chat:**
  - **Sincronização e Resolução de Mensagens no Chat Loja/Cliente:**
    - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): Diferenciação inteligente de nó balcão ao receber mensagens enviadas pelo próprio dono em modo cliente; despacho imediato dos ACKs de entrega (`mensagem_entregue`) e leitura (`mensagem_lida`), eliminando mensagens presas como pendentes e retransmissões redundantes em fila.
    - [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): Tolerância estrita a pequenas dessincronizações de relógio local entre desktop e celular, garantindo ordem monotônica de timestamps (+5ms) e atualização segura de `atualizado_em` da conversa.
    - [chat_conversas_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_conversas_service.dart) & [montador_conversas_modo_loja.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/montador_conversas_modo_loja.dart): Resolução flexibilizada de identificadores de loja (com e sem prefixo `loja_`), eliminando qualquer oscilação ou desaparecimento temporário da conversa ao alternar telas ou sincronizar.
    - [curador_conversas_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador/curador_conversas_chat.dart): Desduplicação canônica por cliente no balcão da loja e unificação cronológica das mensagens por ID sem repetição.
  - **Isolamento de Identidade do Perfil Nous vs Logo Comercial:**
    - [dados_locais_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/dados_locais_service.dart): Restrição rigorosa da atribuição de `foto = loja.logo` exclusivamente para documentos de 14 dígitos (CNPJ), impedindo que buscas por CPF (11 dígitos) substituam a foto pessoal do dono pela logo da loja.
    - [auth_provider.dart](file:///d:/Nous/nous/lib/src/features/auth/providers/auth_provider.dart): Autocura profilática no carregamento de conta; se a foto do perfil coincidir com a logo de qualquer loja do usuário, a foto é sanitizada para restauração da imagem civil correta.
    - [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart): Persistência imediata e atualização no cofre de identidade da foto recebida via terminal remoto.
  - **Experiência do Usuário e Notificações Android:**
    - [notificacao_android_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/notificacao_android_service.dart): Cache de controle contra loops de notificações locais (`_mensagensNotificadas`), cancelamento automático de alertas da conversa ativa e exibição da foto real do remetente e do ícone oficial Nous no Android.
    - [cabecalho_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart): Botões de ação (vídeo, voz, edição e opções) compactados à direita com `VisualDensity.compact`, ampliando a visibilidade do nome e ativando `TextoRolante` para rolagem suave de títulos e subtítulos extensos.
  - **Qualidade e Estabilidade:** 0 avisos no `dart analyze` e 103 testes passando com sucesso no `flutter test`.

## v1.0.68 (build 69) — 02/11/2026

- **Concorrência Aditiva em Mesas na Rede Local, Manutenção Preventiva de Banco SQLite (VACUUM/Integrity Check) e Desacoplamento do PdvProvider (Meta /goal Concluída):**
  - **Blindagem Concorrente em Mesas na Rede Local P2P (Ponto A):**
    - [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Mesclagem de mesas aprimorada de substituição cega para união aditiva e granular de consumos (`ItemComandaMesa`). Itens lançados por diferentes garçons ou terminais concorrentes são mesclados por ID sem perda ou sobrescrita, preservando o status e total acumulado.
    - [roteador_loja_pedidos.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart): Endpoint `POST /api/mesa` atualizado para mesclagem aditiva inteligente, impedindo que lançamentos simultâneos descartem consumos registrados por outro terminal na mesma mesa.
  - **Manutenção Preventiva e Saúde do SQLite (Ponto C):**
    - [banco_dados_service.dart](file:///d:/Nous/nous/lib/src/core/services/banco_dados_service.dart): Implementado `executarManutencaoPreventiva()` com `PRAGMA integrity_check` (detecção de corrupção de páginas B-Tree), `VACUUM` (compactação, desfragmentação física e devolução de espaço em disco ao sistema operacional) e `PRAGMA optimize`. Rotina disparada automaticamente a cada 7 dias em segundo plano sem travar o startup.
  - **Desacoplamento e Redução do PdvProvider (Item 1):**
    - Criado [pdv_lojas_cofre_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/helpers/pdv_lojas_cofre_helper.dart): Extraídas responsabilidades de resolução de referências, expurgo de órfãs, sucessão de dono e loja coletiva Nous.
    - [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart) reduzido de **1.292 para 1.071 linhas**, tornando o fluxo de gerenciamento de lojas limpo e desacoplado.
  - **Qualidade, Estabilidade e Documentação:** 0 issues no `dart analyze`, 102/102 testes aprovados no `flutter test`, documentação em `MAPA_DO_APP.md`, `README.md` e binários atualizados na pasta `dist/`.

## v1.0.67 (build 68) — 02/11/2026

- **Blindagem Definitiva de Longo Prazo: Proteção de Memória (RAM), Otimização de Rede LAN O(1) e Paginação em Relatórios e Estoque (Meta /goal Concluída):**
  - **Otimização Assintótica O(1) de Reconciliação P2P na Rede Local:**
    - [reconciliador_loja_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart): Substituídas todas as iterações e buscas lineares $O(N \times M)$ (`.any()`) por conjuntos hash instantâneos (`Set<String>` e `Map<String, TurnoCaixa>`) para categorias, itens, clientes, fornecedores, mesas, ações de auditoria, pedidos, movimentos de estoque, pagamentos, turnos e cargos.
    - Estabelecido teto de contenção seguro de payload de rede Wi-Fi local para evitar estouro de HTTP e payload gigabyte: retenção das 2.000 ações e movimentos mais recentes e 1.000 pagamentos mais recentes no tráfego LAN.
  - **Blindagem de Memória e Persistência Estruturada no SQLite:**
    - Criado [movimentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/movimentos_repositorio_loja.dart): Gerencia movimentações de estoque da loja no banco SQLite com suporte a retenção ativa em memória (`carregarParaMemoria(limite: 2000)`), salvamento em lote em transação atômica (`salvarLote`), paginação histórica sob demanda (`carregarPaginado`) e contagem total rápida (`contarTotal`).
    - Criado [pagamentos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pagamentos_repositorio_loja.dart): Gerencia histórico de pagamentos e salários de colaboradores com retenção em memória dos 1.000 registros mais recentes e persistência relacional no SQLite.
    - [lojas_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/lojas_service.dart): Integrado com os repositórios estruturados, prevenindo qualquer risco de vazamento de memória ou perda de dados em anos de operação contínua.
  - **Refatoração e Paginação Inteligente de Monólitos Históricos:**
    - [auditoria_relatorio_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/relatorios/auditoria_relatorio_widget.dart): Reduzido de **767 para 285 linhas**. Criados [detalhes_acao_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/relatorios/auditoria/detalhes_acao_dialog.dart) e [barra_acao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/relatorios/auditoria/barra_acao_widget.dart). Implementada renderização em lotes de 50 ações com carregamento progressivo ao rolar o scroll, eliminando qualquer queda de taxa de quadros (jank) na interface.
    - [estoque_container.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/estoque_container.dart): Reduzido de **743 para 357 linhas**. Otimizado cálculo de saldos de estoque de $O(I \times M)$ para $O(M)$ por indexação Map prévia. Criados [ficha_kardex_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/estoque/ficha_kardex_dialog.dart) e [linha_movimento_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/estoque/linha_movimento_widget.dart). Implementada paginação progressiva de itens no catálogo de estoque.
  - **Qualidade e Estabilidade:** 0 avisos no `dart analyze` e aprovação de todos os 102 testes automatizados (`flutter test`).

## v1.0.66 (build 67) — 02/11/2026

- **Auditoria de Escalabilidade, Memória e Decomposição Completa dos Monólitos Restantes (Meta /goal 100% Concluída):**
  - **4 Pontos Principais de Atenção (Auditoria e Otimização de Performance):**
    - *Ponto 1 (Paginação e retenção inteligente no histórico de pedidos do PDV):* Criado [pedidos_repositorio_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/loja/pedidos_repositorio_loja.dart) e integrado em [lojas_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/lojas_service.dart) e [pdv_provider.dart](file:///d:/Nous/nous/lib/src/features/pdv/providers/pdv_provider.dart). Limite de 5.000 pedidos em memória e retenção dos últimos 1.000 registros para proteção contra estouro de RAM em operações de alto volume. [lojas_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/lojas_service.dart) reduzido de 1.016 para 420 linhas.
    - *Ponto 2 (Decomposição do diálogo Nova Venda):* Extraído [nova_venda_controller.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart); [nova_venda_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda_dialog.dart) reduzido de 1.320 para 540 linhas.
    - *Ponto 3 (Desacoplamento de Rede Local LAN P2P):* Criado [dialog_autorizacao_terminal.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/rede_local/dialog_autorizacao_terminal.dart) desacoplando a UI do servidor de rede ([servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart) reduzido de 1.036 para 727 linhas). Criado [despachante_cliente_rede.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/despachante_cliente_rede.dart) isolando os despachos REST de pedidos, estoque e mesas do cliente LAN.
    - *Ponto 4 (Governança e saneamento de cache de mídias temporárias):* Implementado em [imagem_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/imagem_service.dart) o método `limparArquivosTemporariosExpirados` com política LRU e cota de 500 MB para evitar crescimento infinito do cache de imagens.
  - **Refatoração e Pulverização dos Monólitos Restantes:**
    - [status_loja_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/status_loja_view.dart): Reduzido de 979 para **310 linhas**. Criados [bloco_resumo_operacional_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/status_loja/bloco_resumo_operacional_widget.dart) e [bloco_trabalhadores_status_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart).
    - [fornecedores_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/fornecedores_dialog.dart): Reduzido de 968 para **380 linhas**. Criados [formulario_fornecedor_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/fornecedores/formulario_fornecedor_widget.dart), [bloco_importar_cliente_fornecedor_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/fornecedores/bloco_importar_cliente_fornecedor_widget.dart) e [lista_fornecedores_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/fornecedores/lista_fornecedores_widget.dart).
    - [novo_item_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/novo_item_dialog.dart): Reduzido de 923 para **520 linhas**. Criados [coluna_identificacao_item_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/novo_item/coluna_identificacao_item_widget.dart) e [coluna_operacao_estoque_item_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/novo_item/coluna_operacao_estoque_item_widget.dart).
    - [adicionar_item_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/adicionar_item_mesa_dialog.dart): Reduzido de 921 para **280 linhas**. Criado [seletor_itens_mesa_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/seletor_itens_mesa_widget.dart).
    - [fechar_conta_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/fechar_conta_mesa_dialog.dart): Reduzido de 865 para **450 linhas**. Criados [painel_ajustes_totais_mesa_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/painel_ajustes_totais_mesa_widget.dart) e [painel_dividir_pagamento_mesa_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/painel_dividir_pagamento_mesa_widget.dart).
    - [aba_catalogo_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/abas_loja/aba_catalogo_loja_widget.dart): Reduzido de 885 para **160 linhas**. Criados [painel_categorias_grupos_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/abas_loja/catalogo/painel_categorias_grupos_widget.dart) e [painel_itens_catalogo_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/abas_loja/catalogo/painel_itens_catalogo_widget.dart).
    - [financeiro_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/financeiro_view.dart): Reduzido de 874 para **430 linhas**. Criado [financeiro_operacoes_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/financeiro_operacoes_helper.dart).
    - [gestao_loja_container.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja_container.dart): Reduzido de 850 para **130 linhas**. Criados [bloco_botoes_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja/bloco_botoes_gestao_widget.dart) e [bloco_pedidos_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_loja/bloco_pedidos_gestao_widget.dart).
    - [dialog_detalhes_contato.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/dialog_detalhes_contato.dart): Reduzido de 827 para **270 linhas**. Criados [painel_midias_links_docs_chat_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/widgets/painel_midias_links_docs_chat_widget.dart) e [painel_participantes_grupo_chat_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/dialogs/widgets/painel_participantes_grupo_chat_widget.dart).
    - [theme_customizer_dialog.dart](file:///d:/Nous/nous/lib/src/core/theme/theme_customizer_dialog.dart): Reduzido de 802 para **578 linhas**. Criado [canva_color_picker_modal.dart](file:///d:/Nous/nous/lib/src/core/theme/widgets/canva_color_picker_modal.dart).
  - **Qualidade e Estabilidade:** 100% de compilação limpa em `dart analyze` e todos os 102 testes automatizados passando com sucesso em `flutter test`.

## v1.0.65 (build 66) — 02/11/2026

- **Refatoração Arquitetural Global — Decomposição Plena dos Monólitos do PDV, Gestão Operacional, Identidade Social e Mensageria (Meta /goal Concluída):**
  - **Opção A — Higienização de Identidade Social e Mensageria:**
    - [conta_nous_view.dart](file:///d:/Nous/nous/lib/src/features/auth/views/conta_nous_view.dart): Decomposto de 1.115 para 66 linhas de puro orquestrador. Submódulos criados em `lib/src/features/auth/views/widgets/conta_nous/`:
      - `bloco_identidade_conta_widget.dart` (dados civis, CPF, nome completo, biometria).
      - `bloco_privacidade_conta_widget.dart` (regras e alternâncias de privacidade).
      - `bloco_emails_conta_widget.dart` (gestão e alternância de e-mails ativos).
      - `bloco_seguranca_conta_widget.dart` (PIN, senha, autenticação e recuperação).
    - [montador_conversas_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador_conversas_chat.dart): Reduzido de 907 para 170 linhas limpas. Submódulos criados em `lib/src/features/chat/services/montador/`:
      - `montador_conversas_modo_loja.dart`
      - `montador_conversas_modo_social.dart`
      - `curador_conversas_chat.dart`
    - [painel_conversa_ativa_widget.dart](file:///d:/Nous/nous/lib/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart): Reduzido de 884 para 170 linhas limpas. Submódulos criados em `lib/src/features/chat/views/widgets/painel_conversa/`:
      - `dialog_menu_anexos_chat.dart`
      - `banner_titulo_conversa_widget.dart`
      - `cabecalho_conversa_ativa_widget.dart`
      - `barra_envio_mensagem_widget.dart`
    - [mensageria_view.dart](file:///d:/Nous/nous/lib/src/features/chat/views/mensageria_view.dart): Reduzido de 951 para 370 linhas com eliminação total de 250 linhas de duplicação entre mobile e desktop via:
      - `lib/src/features/chat/services/mensageria_acoes_delegate.dart`
  - **Opção B — Higienização do PDV e Gestão Operacional:**
    - [nova_venda_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda_dialog.dart): Decomposto o bloco de finalização e baixa de estoque para:
      - `lib/src/features/pdv/views/widgets/nova_venda/finalizador_nova_venda.dart`
    - [usuarios_participantes_container.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/usuarios_participantes_container.dart): Reduzido de 1.094 para 290 linhas limpas. Submódulos criados em `lib/src/features/pdv/views/widgets/usuarios/`:
      - `dialog_convite_membro_loja.dart`
      - `dialog_troca_papel_membro.dart`
      - `card_membro_loja_widget.dart`
    - [venda_registrada_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/venda_registrada_dialog.dart): Reduzido de 1.076 para 180 linhas limpas. Submódulos criados em `lib/src/features/pdv/views/widgets/venda_registrada/`:
      - `barra_venda_widget.dart`
      - `bloco_acoes_venda_widget.dart`
      - `bloco_resumo_venda_widget.dart`
      - `bloco_itens_venda_widget.dart`
      - `bloco_comentario_venda_widget.dart`
    - [cargos_permissoes_container.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/cargos_permissoes_container.dart): Reduzido de 1.014 para 450 linhas limpas. Submódulos criados em `lib/src/features/pdv/views/widgets/cargos/`:
      - `dialogs_gerenciar_cargo.dart`
      - `painel_coletivo_nous_widget.dart`
      - `card_permissao_loja_widget.dart`
    - [financeiro_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/financeiro_view.dart): Decompostos os blocos de resumo e controle para `lib/src/features/pdv/views/widgets/financeiro/`:
      - `barra_acoes_financeiro_widget.dart`
      - `bloco_entradas_financeiro_widget.dart`
      - `bloco_balanco_financeiro_widget.dart`
    - [caixa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa_dialog.dart): Decomposto de 981 para 550 linhas limpas. Submódulos criados em `lib/src/features/pdv/views/widgets/caixa/`:
      - `painel_abertura_turno.dart`
      - `painel_turno_aberto.dart`
    - [modo_balcao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/modo_balcao_widget.dart): Decomposto de 924 para 780 linhas limpas. Submódulos criados em `lib/src/features/pdv/views/widgets/modo_balcao/`:
      - `barra_superior_balcao_widget.dart`
      - `campo_bipador_balcao_widget.dart`
  - **Garantia de Qualidade e Conformidade Soberana:**
    - Zero issues no analisador estático (`flutter analyze` = No issues found!).
    - 100% dos testes automatizados aprovados (102/102 testes verdes).
    - Scripts de build de instaladores para Windows e Android validados.

## v1.0.64 (build 65) — 02/11/2026

- **Refatoração Integral dos Monólitos Finais e Blindagem da Rede Social e Mensageria (Meta /goal Concluída):**
  - **Isolamento de Metadados e Saneamento do Chat da Aplicação:**
    - Criado [resolvedor_conversa_info_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/resolvedor_conversa_info_service.dart): desacoplou e centralizou a resolução de metadados, títulos, avatares e usernames da rede social com o modelo imutável `MetadadosConversaInfo`.
    - Refatoração de [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart): eliminada duplicação de regras de resolução de contatos e conversas, garantindo blindagem de identidade social contra sobreposições e cache corrompido.
  - **Modularização do Sistema de Notificações:**
    - Criado [card_notificacao_estoque.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/views/widgets/cards/card_notificacao_estoque.dart): exibição e resolução de alertas de estoque baixo por loja.
    - Criado [card_notificacao_chat.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/views/widgets/cards/card_notificacao_chat.dart): visualização e navegação de mensagens não lidas no chat social.
    - Criado [card_notificacao_convite.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/views/widgets/cards/card_notificacao_convite.dart): cards de solicitações de dados e convites de membros de loja.
    - Criado [gerenciador_acoes_notificacao.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/services/gerenciador_acoes_notificacao.dart): centralizou regras de aceite e recusa de convites.
    - Refatoração de [notificacoes_dialog.dart](file:///d:/Nous/nous/lib/src/features/notificacoes/views/widgets/notificacoes_dialog.dart): reduziu de **1.139 para 536 linhas** (-603 linhas).
  - **Modularização da Ficha de Identidade e Privacidade do Usuário:**
    - Criado [linha_info_usuario.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario/linha_info_usuario.dart): suporte completo a censura seletiva e privacidade por campo.
    - Criado [bloco_dados_pessoais_usuario.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario/bloco_dados_pessoais_usuario.dart): alternância entre visualização com blur e edição.
    - Criado [bloco_emails_usuario.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario/bloco_emails_usuario.dart): listagem de e-mails associados e status do e-mail ativo.
    - Criado [bloco_lojas_usuario.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario/bloco_lojas_usuario.dart): exibição de lojas administradas e participadas com cargos e papéis.
    - Refatoração de [ficha_usuario_dialog.dart](file:///d:/Nous/nous/lib/src/features/auth/views/widgets/ficha_usuario_dialog.dart): reduziu de **1.009 para 755 linhas**.
  - **Modularização dos Ajustes da Loja e Modo de Visualização do PDV:**
    - Criado [bloco_atalhos_teclado_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/ajustes_loja/bloco_atalhos_teclado_widget.dart): configuração de comandos e teclas de função F1-F12.
    - Criado [bloco_tempo_conclusao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/ajustes_loja/bloco_tempo_conclusao_widget.dart): tempo estimado de preparo e conclusão de pedidos.
    - Criado [bloco_sons_alertas_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/ajustes_loja/bloco_sons_alertas_widget.dart): configuração de áudios e sinos de avisos.
    - Refatoração de [aba_ajustes_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/abas_loja/aba_ajustes_loja_widget.dart): reduziu de **747 para 505 linhas**.
  - **Modularização de Movimento de Estoque e Cadastro de Item:**
    - Criado [card_ajustes_rapidos_item_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/estoque/card_ajustes_rapidos_item_dialog.dart): ajustes rápidos de venda, código de barras e unidade durante entrada de compras.
    - Criado [botao_hover_tipo_estoque.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/estoque/botao_hover_tipo_estoque.dart): seleção visual com hover para tipo de movimento.
    - Criado [botoes_hover_item_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/novo_item/botoes_hover_item_widget.dart): botões hover de unidades de medida e produto/serviço.
    - Refatoração de [movimento_estoque_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/movimento_estoque_dialog.dart): reduziu de **1.050 para 730 linhas**.
    - Refatoração de [novo_item_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/novo_item_dialog.dart): reduziu de **1.103 para 923 linhas**.
  - **Garantia de Qualidade e Conformidade Soberana:**
    - 0 warnings e 0 errors no analisador estático (`flutter analyze` = No issues found!).
    - 102/102 testes automatizados passando com 100% de sucesso (`flutter test`).

## v1.0.63 (build 64) — 02/11/2026

- **Modularização Profunda de Rede Local, Relatórios PDF, Caixas e Mesas para Crescimento Saudável da Aplicação (Meta /goal Concluída):**
  - **Decomposição dos Monólitos de Rede Local em Message Handlers Dedicados:**
    - Criado [terminal_conectado_info.dart](file:///d:/Nous/nous/lib/src/features/pdv/models/terminal_conectado_info.dart) para desacoplamento de metadados de conexões ativas na rede LAN.
    - Criado [servidor_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart) para centralizar a lógica de identificação, logout, chat, convites de loja e broadcast de sincronização.
    - Criado [cliente_ws_message_handler.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart) para orquestrar recepção de dados iniciais, reconciliação de loja, pedidos, estoque, mesas e convites.
    - Refatoração de [servidor_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/servidor_rede_local.dart) e [cliente_rede_local.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/rede_local/cliente_rede_local.dart), reduzindo mais de 650 linhas dos núcleos de conectividade.
  - **Reestruturação e Decomposição de Relatórios e Exportação Documental PDF:**
    - Criado [pdf_formatacao_util.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/pdf_formatacao_util.dart): utilitários compartilhados de estilo, formatação e gravação cross-platform (`FilePicker` / `file_selector`).
    - Criado [exportador_pdf_comanda.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/exportador_pdf_comanda.dart): geração especializada de comandas e recibos de mesa/balcão.
    - Criado [exportador_pdf_financeiro.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/exportador_pdf_financeiro.dart): relatórios gerenciais e fluxo financeiro analítico.
    - Criado [exportador_pdf_dre.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/exportador_pdf_dre.dart): Demonstrativo de Resultados do Exercício (DRE) detalhado.
    - Criado [exportador_pdf_extrato_cliente.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios/exportador_pdf_extrato_cliente.dart): extrato de compras e dívidas a prazo por cliente.
    - Redução drástica de [relatorios_pdf_service.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/relatorios_pdf_service.dart) de **1.372 linhas para apenas 78 linhas**, operando como uma Facade limpa e 100% retrocompatível.
  - **Modularização dos Diálogos Operacionais de Caixa e Mesas:**
    - Criados [painel_historico_turnos.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/painel_historico_turnos.dart), [bloco_movimentacoes_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/bloco_movimentacoes_turno.dart), [painel_lancamento_movimento.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/painel_lancamento_movimento.dart) e [painel_fechamento_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/painel_fechamento_turno.dart).
    - Criados [card_operacional_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/card_operacional_turno.dart) e [card_resumo_financeiro_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/card_resumo_financeiro_turno.dart), reduzindo [detalhes_turno_caixa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/detalhes_turno_caixa_dialog.dart) de 1.229 para **758 linhas** (saiu da lista de monólitos).
    - Criado [configuracao_item_mesa_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/configuracao_item_mesa_widget.dart): reduziu [adicionar_item_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/adicionar_item_mesa_dialog.dart) em ~300 linhas.
    - Criado [cadastro_cliente_rapido_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/cadastro_cliente_rapido_mesa_dialog.dart): reduziu [fechar_conta_mesa_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/mesas/fechar_conta_mesa_dialog.dart) em ~200 linhas.
  - **Conformidade de Compilação e Suíte de Testes:**
    - `ndkVersion` configurado de forma canônica no Android (`28.2.13676358`).
    - 0 warnings e 0 errors no analisador estático (`flutter analyze` = No issues found!).
    - 102/102 testes aprovados com 100% de sucesso (`flutter test`).

## v1.0.62 (build 63) — 02/11/2026

- **Correção de Identidade no Chat da Loja e Modularização Completa dos Monólitos do PDV (Meta /goal Concluída):**
  - **Correção Soberana de Identidade no Chat da Loja:**
    - Resolvido o bug de chave de cache em [montador_conversas_chat.dart](file:///d:/Nous/nous/lib/src/features/chat/services/montador_conversas_chat.dart) (`loja_conversa_${c.id}`), eliminando a sobreposição de identidade da atendente ("Rosa") nas conversas com clientes reais.
    - Implementada proteção e cura de identidade no [chat_mensagens_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_mensagens_service.dart) e na visualização de conversas, garantindo exibição fidedigna de avatar, nome real e telefone do cliente.
    - Criada suíte completa de 32 testes unitários em [chat_mensageria_test.dart](file:///d:/Nous/nous/test/chat_mensageria_test.dart) com 100% de aprovação.
  - **Modularização de `dados_perfil_view.dart` (Reduzido de 1.992 para 424 linhas):**
    - Criado [dados_perfil_loja_controller.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/dados_perfil_loja_controller.dart): orquestrador único de estados, timers e ciclo de vida.
    - Criado [seletor_conteudo_abas_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/seletor_conteudo_abas_loja_widget.dart): isolamento completo da renderização das 4 abas (Dados, Loja, Gestão e Ajustes).
    - Criado [layout_principal_loja_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/layout_principal_loja_widget.dart): encapsulamento de atalhos globais (F1-F12), Modo Balcão, Scaffold Desktop Expandido e Scaffold Compacto.
    - Criado [gerenciador_dialogs_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_dialogs_loja.dart): centralização de diálogos operacionais (clientes, financeiro, impressora, relatórios, caixa, mesas e atalhos).
    - Criado [gerenciador_clientes_fornecedores_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_clientes_fornecedores_loja.dart): regras de negócio e cadastro de clientes e fornecedores.
    - Criado [persistencia_loja_helper.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/persistencia_loja_helper.dart): persistência local e propagação na rede Wi-Fi.
  - **Modularização de `aba_gestao_nous_widget.dart` (Reduzido de 1.834 para 787 linhas):**
    - Criados [dialogs_topicos_gestao.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/dialogs_topicos_gestao.dart), [barra_envio_mensagem_gestao.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/barra_envio_mensagem_gestao.dart), [bolha_mensagem_gestao.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/bolha_mensagem_gestao.dart), [barra_topicos_comunitarios_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/barra_topicos_comunitarios_widget.dart) e [cabecalho_chat_gestao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/cabecalho_chat_gestao_widget.dart).
  - **Modularização de `programar_pedido_dialog.dart` (Reduzido de 1.592 para 606 linhas):**
    - Criados [bloco_frequencia_horario_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido/bloco_frequencia_horario_widget.dart), [bloco_selecao_item_programado_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido/bloco_selecao_item_programado_widget.dart) e [bloco_comanda_programada_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido/bloco_comanda_programada_widget.dart).
  - **Modularização da Suíte de Turno de Caixa e Venda:**
    - Criados [barra_turno_item.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/barra_turno_item.dart), [card_movimento_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/card_movimento_turno.dart), [card_venda_turno.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/caixa/card_venda_turno.dart) e [gerador_comprovante_venda.dart](file:///d:/Nous/nous/lib/src/features/pdv/services/gerador_comprovante_venda.dart).
  - **Métricas Finais e Auditoria de Qualidade:**
    - Zero issues no analisador estático (`flutter analyze` = No issues found!).
    - 102 de 102 testes passando com 100% de aprovação (`flutter test`).
    - Novos instaladores de teste gerados em `dist/`.

## v1.0.61 (build 62) — 02/11/2026

- **Modularização Arquitetural em Cascata e Extinção dos Três Maiores Monólitos Remanescentes:**
  - **Prioridade 1: Modularização da Criação e Fechamento de Vendas (`NovaVendaDialog`):**
    - Criado [cliente_seletor_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/cliente_seletor_nova_venda_widget.dart): desacoplou a busca preditiva de clientes, histórico recente, exibição prioritária com `TextoRolante` e gatilho de cadastro ágil.
    - Criado [comanda_resumo_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/comanda_resumo_nova_venda_widget.dart): encapsulou a renderização do cupom de papel da comanda física com itens, adicionais, observações e totais formatados.
    - Criado [pagamento_nova_venda_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda/pagamento_nova_venda_widget.dart): separou em `BlocoAjustesNovaVendaWidget` (frete, desconto, acréscimo) e `BlocoPagamentoNovaVendaWidget` (formas de pagamento, cálculo de troco/falta e quitação).
    - Redução drástica de [nova_venda_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/nova_venda_dialog.dart) de 2.430 linhas para 1.543 linhas (-887 linhas).
  - **Prioridade 2: Modularização da Comunidade e Gestão Nous (`AbaGestaoNousWidget`):**
    - Criado [dialog_explorar_salas_comunitarias.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/dialogs/dialog_explorar_salas_comunitarias.dart): diálogo modal completo para explorar, buscar e ingressar em salas comunitárias Nous.
    - Criado [card_audio_mensagem_gestao.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/gestao_nous/card_audio_mensagem_gestao.dart): player autônomo com scrubber slider, controle de reprodução e contador de duração.
    - Redução de [aba_gestao_nous_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/aba_gestao_nous_widget.dart) de 2.396 linhas para 1.833 linhas (-563 linhas).
  - **Prioridade 3: Modularização do Agendamento e Contratos Recorrentes (`ProgramarPedidoDialog`):**
    - Criado [dialog_digitar_horario.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/dialogs/dialog_digitar_horario.dart): diálogo especializado com máscara, rolagem por mouse wheel e sugestões rápidas de horário, com o reutilizável `HorarioInputFormatter`.
    - Criado [calendario_programacao_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido/calendario_programacao_widget.dart): grade visual adaptável de calendário com seleção múltipla de datas e navegação por mês.
    - Redução de [programar_pedido_dialog.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/programar_pedido_dialog.dart) de 2.140 linhas para 1.591 linhas (-549 linhas).
  - **Qualidade, Estabilidade e Suíte de Testes:**
    - Zero issues no analisador estático (`dart analyze` = No issues found!).
    - 100% de sucesso nos testes automatizados (101/101 testes passando).

## v1.0.60 (build 61) — 02/11/2026

- **Modularização de Monólitos do PDV e Desacoplamento da Gestão de Catálogo, Pedidos e Módulo Financeiro:**
  - **Desacoplamento do Catálogo da Loja (`GerenciadorCatalogoLoja`):**
    - Criado [gerenciador_catalogo_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_catalogo_loja.dart) desacoplando integralmente a criação, edição, expansão, exclusão e auditoria de itens, categorias e grupos de componentes.
    - Sincronização automática e atômica de vínculos entre categorias e grupos no catálogo do PDV.
  - **Desacoplamento do Ciclo de Vida de Pedidos da Loja (`GerenciadorPedidosLoja`):**
    - Criado [gerenciador_pedidos_loja.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/loja/gerenciador_pedidos_loja.dart) encapsulando o processamento da fila de novos pedidos, timers de verificação de conclusão, diálogos de cancelamento, recusa, estorno automático no estoque e registro em caixa.
    - Redução cumulativa de ~1.200 linhas em [dados_perfil_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/dados_perfil_view.dart) (caindo de 3.449 para 2.261 linhas), com UI 100% retrocompatível e ágil.
  - **Decomposição do Módulo Financeiro (`FinanceiroView`):**
    - Criado [item_linha_financeira.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart) com os widgets reutilizáveis `LinhaPagamentoFuncionarioWidget`, `LinhaCompraEstoqueWidget`, `LinhaComHoverWidget` e o formatador de datas `DataInputFormatter`.
    - Criado [seletor_periodo_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/seletor_periodo_financeiro_widget.dart) encapsulando a seleção de períodos (Hoje, Semana, Mês, Tudo, Personalizado), navegação direta por dia e calendário pop-up.
    - Criado [bloco_compras_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_compras_financeiro_widget.dart) com lista de compras por fornecedor, busca interativa e paginação visual.
    - Criado [bloco_funcionarios_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_funcionarios_financeiro_widget.dart) com gestão da folha de pagamento da equipe.
    - Criado [bloco_vendas_financeiro_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_vendas_financeiro_widget.dart) com busca de vendas, filtro por forma de pagamento e visualização de comprovantes.
    - Criado [bloco_resumo_operacional_widget.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/widgets/financeiro/bloco_resumo_operacional_widget.dart) com o dashboard de faturamento, ticket médio, status de caixa e recebíveis.
    - Redução maciça de 2.276 linhas para 995 linhas em [financeiro_view.dart](file:///d:/Nous/nous/lib/src/features/pdv/views/financeiro_view.dart) (-56% de código no arquivo!).
  - **Qualidade, Estabilidade e Suíte de Testes:**
    - Zero issues no Dart Analyzer (`dart analyze` = No issues found!).
    - 100% dos testes unitários e de integração aprovados (101/101 testes passando).

## v1.0.59 (build 60) — 01/11/2026

- **Decomposição do Monólito de Mensageria (`ChatService`) e Eliminação de Gargalos de Troca de Chat:**
  - **Criação do Repositório SQLite Dedicado (`ChatRepositorioSqlite`):**
    - Criado [chat_repositorio_sqlite.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_repositorio_sqlite.dart) centralizando tabelas, migrações e índices de alta performance (`idx_chat_lida` cobrindo `[conversa_id, lida, remetente_id]`).
    - **Otimização Crítica de Leitura:** Substituído loop O(N) que realizava updates individuais linha a linha por batch update único indexado (`UPDATE mensagens_chat SET lida = 1, status_envio = 'lida' WHERE conversa_id = ? AND lida = 0 AND remetente_id != ?`), eliminando o congelamento na troca de conversas.
    - Otimização da listagem de conversas e grupos com leitura de última mensagem via queries leves `LIMIT 1` em vez de carregar listas completas em memória.
  - **Criação do Serviço de Mídias e Resumos (`ChatMediaService`):**
    - Criado [chat_media_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_media_service.dart) para gestão segura de anexos em disco, leitura protegida de bytes em Base64 para envio na malha local e geração inteligente de resumos textuais de mensagens.
  - **Criação do Serviço de Sincronização e Malha de Rede (`ChatSincronizacaoService`):**
    - Criado [chat_sincronizacao_service.dart](file:///d:/Nous/nous/lib/src/features/chat/services/chat_sincronizacao_service.dart) para roteamento e propagação de mensagens, eventos de entrega, leitura e digitação via WebSocket/HTTP tanto no Balcão (Servidor) quanto nos Terminais (Clientes).
  - **Refatoração do `ChatService` como Fachada Soberana e Unificada:**
    - Redução maciça de 2.742 linhas para ~1.340 linhas, mantendo 100% de retrocompatibilidade com todos os métodos e fluxos públicos consumidos pela interface.
  - **Qualidade e Estabilidade:**
    - Zero erros estáticos no Dart Analyzer e 100% dos testes da suíte (101/101 testes) aprovados com sucesso.

## v1.0.58 (build 59) — 01/11/2026

- **Modularização de Monólitos do PDV, Higiene Arquitetural e Desacoplamento:**
  - **Criação do `EstoqueBaixaService` (lib/src/features/pdv/services/estoque_baixa_service.dart):**
    - Serviço canônico e unificado para cálculo soberano de baixas e estornos de estoque em vendas e cancelamentos.
    - Ponderação rigorosa por `consumoPorVenda` do item e de acompanhamentos selecionados em pedidos de balcão e de salão/mesas, eliminando discrepâncias e duplicação de regras.
  - **Desacoplamento do Gerenciador de Mesas (`GerenciadorMesasLoja`):**
    - Criado `lib/src/features/pdv/views/widgets/mesas/gerenciador_mesas_loja.dart` desacoplando toda a lógica de abertura, alteração de comanda, transferência, exclusão e fechamento de conta de salão.
    - Redução de ~400 linhas em `dados_perfil_view.dart`, tornando a tela de gestão ágil, testável e sem gargalos de manutenção.
  - **Extração de Formatadores Compartilhados (`texto_formatters.dart`):**
    - Extração de `PrimeiraLetraMaiusculaFormatter` de `clientes_dialog.dart` para `lib/src/core/utils/texto_formatters.dart`, viabilizando reuso global.
  - **Suíte de Testes Expandida:**
    - Criado `test/estoque_baixa_service_e_formatters_test.dart` com 100% de cobertura nos cálculos de estoque e formatação de texto (101 testes automatizados passando).

## v1.0.57 (build 58) — 01/11/2026

- **Trilha A: Blindagem Estrutural da Fase 1 Local-First & Preparação para Hub Universal:**
  - **Diretrizes Arquiteturais Soberanas:**
    - Criada a regra formal `.agents/rules/arquitetura_hub_universal.md` incorporada às instruções de agentes (`AGENTS.md`) definindo os 5 pilares do Hub Universal: Desacoplamento Físico de Dados, Outbox Pattern, Adaptadores de Conectores Externos, IDs Universais e Arquitetura de Mídia Relativa/Canônica.
  - **Blindagem Quádrupla de Resolução de Imagens e Mídia em Rede Local:**
    - `ManipuladorMidiaServidor._atenderImagem`: Adicionada resolução quádrupla e resiliente a falhas no endpoint `/api/imagem` (caminho -> fallback por `item_id` no catálogo -> fallback por `categoria_id` no catálogo -> fallback por CPF/CNPJ de cliente ou fornecedor -> fallback por nome base de arquivo), eliminando em 100% quebras de fotos na sincronização entre Windows e Android.
    - `ReconciliadorLojaRede.resolverCaminhoImagem`: Envio explícito de `item_id`, `categoria_id` e `cnpj` como parâmetros de consulta prioritários durante a reconciliação e download de mídias de produtos e contatos do catálogo da loja.
  - **Isolamento e Robustez em Banco de Dados SQLite em Testes:**
    - Adicionado método `@visibleForTesting` `BancoDadosService.resetDbInstanciaParaTestes()` para redefinição limpa de conexões SQLite entre suites.
    - Isolamento de diretórios temporários (`createTempSync`) em testes concorrentes (`dados_locais_service_test.dart`), prevenindo bloqueios de concorrência (`database is locked`) e assegurando 100% dos testes unitários passando (98/98).

## v1.0.56 (build 57) — 31/10/2026

- **Otimização de Desempenho e Decodificação Assíncrona de JSON em Isolate:**
  - Criado o utilitário soberano `json_isolate_utils.dart` com decodificação assíncrona em Isolates dedicados (`compute`) para payloads grandes (> 20KB).
  - Aplicada a decodificação em Isolate no cliente e no servidor de rede local para handshake REST de lojas/catálogos e mensagens WebSocket em tempo real, eliminando travamentos de UI e quedas de quadros (jank).
- **Refatoração Modular do Servidor de Rede Local (`ServidorRedeLocal`):**
  - Desacoplamento do monólito de 2.200 linhas em módulos de roteamento dedicados sob `pdv/services/rede_local/handlers/`:
    - `RoteadorLojaPedidos`: endpoints de Loja (`/api/loja`, `/api/loja/atualizar`, `/api/loja/sair`), Pedidos (`/api/pedido`), Movimentos de Estoque (`/api/movimento_estoque`) e Mesas (`/api/mesa`).
    - `RoteadorUsuarios`: endpoints de Identidade e Usuários (`/api/usuario`, `/api/usuarios`, `/api/sincronizar_perfis_usuario`).
    - `RoteadorChat`: endpoints de Mensageria (`/api/chat/mensagem`, `/api/chat/mensagens`, `/api/chat/conversas`, `/api/chat/conversas/sync`).
  - Redução drástica do tamanho e complexidade do servidor principal, mantendo 100% de retrocompatibilidade e zero perda de dados.
- **Suporte a Paginação no Carregamento de Mensagens de Chat:**
  - `ChatService.carregarMensagens` atualizado com suporte opcional a `limite` e `offset`, preparando a infraestrutura para carregamento sob demanda e scroll infinito.

## v1.0.55 (build 56) — 31/10/2026

- **Cabeçalho do Chat em Padrão WhatsApp (Anti-Sobreposição Pan-Dispositivo):**
  - Substituição da arquitetura em `Stack` centralizada por uma `Row` responsiva e adaptável: informações do contato (avatar circular, nome em negrito e status/@username) ancoradas à esquerda dentro de um `Expanded`, garantindo zero sobreposição com os controles.
  - Botões de ligação de vídeo, ligação de voz, edição/renomear e menu de 3 pontos alinhados à extrema direita em `Row(mainAxisSize: MainAxisSize.min)` tanto no modo compacto (mobile) quanto no modo desktop.
- **Espelhamento Correto de Câmera WebRTC e Ativação em Chamada de Voz:**
  - O vídeo local PiP agora utiliza espelhamento reativo (`mirror: cameraFrontalAtiva.value`): **apenas a câmera frontal (selfie) é espelhada**. Ao alternar para a câmera traseira (`inverterCamera`), o espelhamento é desativado para exibir o ambiente real de forma fidedigna.
  - Implementada a obtenção dinâmica de trilha de vídeo via `getUserMedia` quando a câmera é ativada no decorrer de uma ligação iniciada em modo voz.
- **Lista de Usuários Conectados e Pesquisa na Aba "Terminal Móvel" (Wi-Fi):**
  - Identificação clara do host conectado (se conectado a uma Loja ou ao Servidor em Modo Usuário Nous) e respectivo endereço IP e porta.
  - Implementada a listagem em tempo real de todos os nós/usuários conectados na mesma rede local (`presencasAtivas`), com input de pesquisa instantânea filtrando por nome civil, nome de usuário (`@username`) ou CPF mascarado.
  - Acesso direto à ficha cadastral dos usuários conectados via modal soberano (`FichaUsuarioDialog`).
- **Preservação Cronológica e Reconciliação do Histórico do SQLite:**
  - Ajuste de causalidade monotônica restrito estritamente a novas mensagens locais/em trânsito (`!originadaDaRede`), preservando os timestamps originais de mensagens antigas sincronizadas.
  - Atualização determinística do resumo da conversa (`ultima_mensagem` e `data_hora_ultima_mensagem`) na tabela `conversas_chat` utilizando sempre a mensagem mais recente do histórico.
  - Reconciliação em segundo plano do histórico do SQLite ao selecionar uma conversa no `MensageriaController`.

## v1.0.54 (build 55) — 31/10/2026

- **Chamadas de Áudio e Vídeo P2P via WebRTC nos Chats:**
  - Implementado sistema completo de chamadas diretas P2P em tempo real (`flutter_webrtc: ^1.6.3`) utilizando a rede local Wi-Fi sem necessidade de internet ou servidores externos na nuvem.
  - **Sinalização Nativa sobre WebSocket:** Roteamento bidirecional transparente no `ServidorRedeLocal` e `ClienteRedeLocal` para mensagens de sinalização (`chamada_iniciar`, `chamada_aceita`, `chamada_rejeitada`, `chamada_encerrada`, `chamada_sinal_sdp`, `chamada_candidato_ice`).
  - **Interface Imersiva de Chamada (`ChamadaAtivaView`):** Vídeo local em picture-in-picture (PIP), fluxo de vídeo remoto em tela cheia, cronômetro de duração, controles para silenciar microfone, alternar câmera frontal/traseira, ligar/desligar câmera e chavear viva-voz.
  - **Modal de Chamada Recebida (`DialogChamadaRecebida`):** Notificação em tempo real com avatar, nome de contato, indicação clara de chamada de voz ou vídeo e toque sonoro contínuo com opções de atender ou recusar.
  - **Botões Integrados na Conversa:** Botões de ligar por áudio (`phone`) e vídeo (`videocam`) incorporados ao cabeçalho de conversas privadas e grupos no `PainelConversaAtivaWidget`, com exclusão estrita e deliberada do chat comunitário público da Loja Nous.
  - **Permissões de Hardware no Android:** Adicionadas permissões `CAMERA`, `RECORD_AUDIO` e `MODIFY_AUDIO_SETTINGS` ao `AndroidManifest.xml`.
- **Paridade e Estabilidade do Modo Servidor de Usuário Nous:**
  - Corrigido o handshake de rede local para quando o servidor é iniciado no modo pessoal/usuário (sem loja comercial aberta). O host agora inclui sempre a sua própria presença em `obterTodasPresencas()` e o cliente aceita o snapshot sem descartar eventos de sincronização.

## v1.0.53 (build 54) — 31/10/2026

- **Sincronização de Relógio em Rede Local (Uníssono Silencioso):**
  - Implementado `RelogioRedeService` e endpoint `/api/relogio` no balcão calculando latência RTT e offset de relógio via algoritmo de Cristian, garantindo ordem causal estrita em chats e comandas mesmo com relógios divergentes.
  - Sincronização 100% autônoma e em segundo plano no handshake de conexão com o balcão.
- **Unificação de Fotos de Perfil e Autocura de Imagens:**
  - `PerfilSocialView` e `DialogDetalhesContato` integrados com `ResolvedorFotoChat` e rotina de busca de dados remotos e download de imagens ausentes via rede local.
- **Eliminação de Gargalos, Perda de Mensagens e Divergência de Históricos:**
  - IDs únicos protegidos contra colisão via contador monotônico e entropia aleatória.
  - Causalidade de Lamport antes da inserção no banco de dados SQLite.
  - Limitação segura de frames WebSocket a 3.5MB para evitar travamento da Isolate principal e estouro de buffer.
  - Download assíncrono não-bloqueante de imagens recebidas via balcão.

## v1.0.52 (build 53) — 30/10/2026

- **Eliminação Total da Lentidão na Troca de Chats (Zero-Lag UI a 60/120 FPS):**
  - **Seleção Otimista Instantânea:** A troca de conversa em `MensageriaController.selecionarConversa` e `selecionarOuIniciarConversa` agora atualiza a conversa ativa imediatamente no mesmo frame (0ms de atraso perceptível), eliminando consultas síncronas bloqueantes de banco de dados.
  - **Interrupção de Loop de Recarga Local:** O método `ChatService.marcarComoLidas` recebeu o parâmetro `notificar: false` para operações originadas na tela de mensagens ativa. Isso impede que a seleção de um chat dispare notificações de alteração global no `alteracoesChatNotifier`, que causava um congelamento de tela com debounce de 120ms para reconsultar todos os contatos do SQLite.
  - **Otimização de Parsing JSON:** Em `ChatService.carregarMensagens`, mensagens não editadas ignoram completamente chamadas desnecessárias de `jsonDecode`, acelerando em mais de 10x o carregamento do histórico.
- **Decomposição do Monólito do PDV Balcão (`ModoBalcaoWidget`):**
  - **Extração de `ComandaBalcaoWidget` (-524 linhas):** Criado `comanda_balcao_widget.dart` isolando o carrinho lateral ampliado do cliente, a listagem viva de itens escaneados, adicionais, observações, seleção rápida de formas de pagamento e cálculo em tempo real de troco.
  - Redução de `modo_balcao_widget.dart` de 2.375 para 1.851 linhas, permitindo renderizações pontuais e melhorias de performance em PDVs com catálogos extensos.
- **Validação de Integridade e Testes:**
  - Zero erros e zero advertências estáticas (`dart analyze`).
  - 100% dos 98 testes automatizados validados com sucesso.

## v1.0.51 (build 52) — 30/10/2026

- **Desacoplamento Arquitetural de Relatórios PDF A4 (`RelatoriosPdfService`):**
  - **Extração de Serviço Especializado:** Criado `relatorios_pdf_service.dart` (1.375 linhas), isolando completamente a geração e composição visual de relatórios documentais A4 (`exportarComandaPDF`, `exportarFinanceiroPDF`, `exportarDREPDF` e `exportarExtratoClientePDF`).
  - **Enxugamento do `ImpressaoService` (-43%):** Redução de 2.798 para 1.606 linhas (-1.192 linhas), concentrando `ImpressaoService` estritamente no envio térmico de cupons (ESC/POS 58mm/80mm) e expondo métodos de fachada retrocompatíveis que delegam para `RelatoriosPdfService`.
  - **Isolamento de Dependências:** O pacote `file_selector` foi restrito a `relatorios_pdf_service.dart`, mantendo o serviço de impressão puramente dedicado à integração direta com o spooler do sistema (`printing`).
- **Expurgo Cirúrgico de Código Morto e Arquivos Órfãos:**
  - Removidos 6 arquivos legados que não eram referenciados em nenhuma parte da aplicação: `associar_cpf_view.dart`, `modelo_layout_desktop.dart`, `container_simbolico.dart`, `dados_bancarios_container.dart`, `delivery_container.dart` e `grupo_componentes_container.dart` (-972 linhas de ruído eliminadas).
- **Modularização de Telas e Modais do PDV (`DadosPerfilView`):**
  - Desacoplados componentes modais focados: `dialog_conclusao_pedido_tempo.dart` (alerta de tempo de preparo com timer sonoro), `estoque_dialog.dart` (modal padronizado de controle de estoque), `dialog_confirmacao_estorno_pedido.dart` (confirmação de estorno de itens ao estoque) e `barra_acoes_loja_widget.dart` (ações rápidas de catálogo e suprimentos).
- **Higiene, Estabilidade e Integridade do Super App:**
  - Zero advertências e zero erros estáticos na suíte completa (`dart analyze: No issues found!`).
  - 100% dos testes automatizados validados com sucesso (`flutter test: 98/98 passed`).

## v1.0.50 (build 51) — 30/10/2026

- **Sincronização Soberana Aditiva e Proteção Anti-Perda de Finanças (Pedidos e Turnos de Caixa):**
  - **Reconciliação Não-Destrutiva Bidirecional:** A consolidação de lojas (`LojasService.consolidarLojaComImagensLocais` e `ClienteRedeLocal._reconciliarLojaMutua`) agora realiza a união soberana de pedidos (`pedidosLoja`), turnos de caixa (`turnosCaixa`), movimentações de estoque (`movimentosEstoque`), pagamentos de funcionários (`pagamentosFuncionarios`), pedidos programados e cargos. Dispositivos desatualizados que se conectam na rede local nunca mais sobrescrevem ou zeram finanças de outros terminais.
  - **Eliminação de Deleção Cega no SQLite:** Removida a rotina `DELETE ... NOT IN` em `LojasService.salvarLojas`, impedindo que pedidos históricos ou criados em modo offline sejam deletados silenciosamente por snapshots parciais de rede.
  - **Propagação Mútua de Novidades Financeiras:** Ao conectar ao balcão via WebSocket, se o terminal móvel detectar que possui pedidos, turnos ou estoque que o servidor central não tem, ele despacha imediatamente a versão enriquecida para o balcão se atualizar em tempo real.
- **Triagem com E-mail Estritamente Obrigatório e Remoção de Entrada sem E-mail:**
  - **Exigência Mandatória de E-mail:** Na segunda tela de triagem (`ContasUsuarioView`), foi removida a opção "Continuar sem e-mail". Usuários sem e-mail cadastrado são impedidos de prosseguir e direcionados ao cadastro obrigatório de e-mail.
- **Encerramento Completo de Conexões e Sessões no Logout:**
  - O método `AuthProvider.sair()` e as ações de saída da aplicação agora encerram e fecham ativamente os sockets WebSockets (`ClienteRedeLocal.desconectar(manual: true)`), cancelam timers de reconexão e ping, interrompem a escuta de anúncios UDP (`pararDescoberta`), limpam o operador do balcão e resetam o estado do `PdvProvider` (`limparSessao`).
- **Refatoração Arquitetural e Desmembramento de Monólitos de Rede e Chat:**
  - **Decomposição do `ClienteRedeLocal` (-47% de código monólito):**
    - Criado `transferencia_arquivos_rede.dart` (256 linhas): isolamento completo de upload/download HTTP multipart e binário de fotos de produtos, anexos de chat, áudios e comprovantes com cache local.
    - Criado `reconciliador_loja_rede.dart` (658 linhas): isolamento dos algoritmos de união não-destrutiva de pedidos, turnos, movimentos de estoque, pagamentos, catálogo e mesas.
    - Criado `sincronizador_usuarios_rede.dart` (574 linhas): isolamento da sincronização pan-dispositivo de identidades Nous, fotos e vínculos de lojas por CPF.
    - O arquivo `cliente_rede_local.dart` foi reduzido de 2.589 para 1.373 linhas, preservando 100% da fachada pública (zero breaking changes para chamadores).
  - **Decomposição do `ChatService` (-20% de código monólito):**
    - Criado `sincronizador_chat_balcao.dart` (338 linhas): centralização da esteira de sincronização HTTP e reconciliação SQLite de conversas, mensagens, tombstones de exclusão e anexos.
    - Criado `comunidade_chat_service.dart` (390 linhas): gestão modular de salas comunitárias e tópicos da Comunidade Nous (`#Geral` e tópicos dinâmicos).
    - O arquivo `chat_service.dart` foi reduzido de 3.303 para 2.682 linhas, mantendo métodos de conveniência e contratos existentes.
  - **Decomposição do `ServidorRedeLocal` (Par Arquitetural Cliente-Servidor):**
    - Criado `manipulador_midia_servidor.dart` (260 linhas): centraliza o streaming de áudio com `Accept-Ranges: bytes`, atendimento binário e por CPF de imagens (`/api/imagem`), recepção de uploads de mídia e entrega de instaladores APK Android via Wi-Fi (`/api/download_apk`, `/api/versao`).
    - O arquivo `servidor_rede_local.dart` delegou todas as operações de baixo nível de stream de arquivos, mantendo a regra de autorização de terminais, roteamento REST e canais WebSocket intactos.
  - **Decomposição e Desacoplamento da `DadosPerfilView` (Tela da Loja):**
    - Criado `barra_acoes_loja_widget.dart` (85 linhas): desacopla a barra de ações horizontais da vitrine da loja (Novo Item, Nova Categoria, Novo Grupo e Estoque).
    - Criado `dialog_conclusao_pedido_tempo.dart` (140 linhas): isola o diálogo de conclusão por tempo estimado de preparo atingido com feedback sonoro e visual.
    - Criado `estoque_dialog.dart` (112 linhas): padroniza a abertura modal do container de estoque, isolando o estado e callbacks de fornecedores e movimentações.
    - Criado `dialog_confirmacao_estorno_pedido.dart` (75 linhas): desacopla a confirmação de estorno de itens de volta ao estoque no fluxo de exclusão de pedidos.
    - Redução de ~380 linhas de código inline no maior arquivo da aplicação, melhorando drasticamente a legibilidade e a manutenção operacional.
  - **Eficiência e Fluidez:** Código mais legível, busca instantânea e navegação otimizada para desenvolvedores e agentes de IA, sem gargalos ou acoplamentos circulares. Zero erros no analisador estático (`dart analyze`) e 100% dos testes automatizados validados.

## v1.0.49 (build 50) — 30/10/2026

- **Sincronização e Download Automático de Fotos de Perfil e Grupos (Autocura de Avatares):**
  - **Normalização de Caminhos Multiplataforma:** Normalizadas as barras invertidas (`\`) para barras (`/`) em caminhos de arquivos vindos do Windows, corrigindo falha no Android onde arquivos recebidos ficavam inacessíveis.
  - **Download com Fallback Baseado em CPF (`/api/imagem`):** O endpoint HTTP do servidor balcão agora aceita parâmetro `cpf`. Se o caminho absoluto do arquivo no servidor mudar ou for inacessível no terminal móvel, o servidor localiza a foto atualizada no cadastro do usuário e a devolve.
  - **Widget `_AvatarComAutocura` no Chat:** Quando um avatar do chat (contato ou grupo) aponta para um caminho local ainda inexistente, o widget renderiza o placeholder e dispara download em segundo plano via Wi-Fi pelo balcão, atualizando o avatar na tela assim que o download termina sem travar o scroll ou a UI.
  - **Eliminação de Gargalo de Reconciliação em Massa:** No `ClienteRedeLocal`, o loop de reconciliação de contas deixou de disparar dezenas de requisições HTTP redundantes e lentas, aproveitando a lista completa de contas já entregue em lote pelo servidor.
- **Desobstrução do Fluxo de Envio e WebSocket do Chat:**
  - **Despacho Imediato de Mensagens com Imagem:** Mensagens com anexos em Base64 são enviadas de imediato pelo socket WebSocket sem aguardar upload HTTP prévio bloqueante de até 15s.
  - **Pipeline Sequencial de Reconexão:** Ao restabelecer conexão Wi-Fi, o `ClienteRedeLocal` executa as etapas de sincronização em uma esteira única não bloqueante, eliminando esgotamento de conexões e quedas acidentais do WebSocket (`onDone`).
- **Sincronização Completa de Mensagens de Grupos na Rede Local:**
  - Corrigidas as consultas de sincronização de mensagens (`obterConversasParaSincronizacao` e `obterMensagensParaSincronizacao`) para incluir grupos (`eh_grupo = 1` e `conversa_id LIKE 'grupo_%'`), garantindo que mensagens trocadas em grupos sejam sincronizadas para todos os membros mesmo quando recebidas enquanto offline.
  - Inclusão dos metadados de grupo (`grupoTitulo`, `grupoFoto`, `grupoParticipantesJson`) no payload de rede, evitando perdas de dados cadastrais do grupo em dispositivos móveis conectados.

## v1.0.48 (build 49) — 30/10/2026

- **Confirmação Instantânea de Leitura e Risquinhos Azuis (`status_envio == 'lida'`):**
  - **Reconhecimento Imediato de Visualização:** Quando o usuário está com a conversa aberta na tela (`idConversaAtiva`), novas mensagens que chegam pela rede local são salvas instantaneamente como lidas (`lida: true, statusEnvio: 'lida'`) e o evento de confirmação de leitura (`mensagens_lidas`) é despachado imediatamente para o remetente, ativando os dois risquinhos azuis em tempo real.
  - **Atualização Bidirecional de Leitura:** O método `marcarComoLidas()` agora atualiza o banco local com `status_envio: 'lida'` e retransmite a confirmação pela rede, sincronizando os checks azuis no balcão e nos celulares pareados.
- **Supressão de Notificações Redundantes e Limpeza de Indicadores com Conversa Aberta:**
  - **Supressão de Bip e Push em Conversa Ativa:** Mensagens recebidas na conversa atualmente aberta deixam de emitir alerta sonoro e não disparam notificações de push locais no Android, respeitando a visualização em tempo real do usuário.
  - **Barra de Conversas e Sino de Notificações Limpos:** As queries de contagem não lida (`temMensagensNaoLidasNoUsuario` e `temMensagensNaoLidasNaLoja`), bem como o `MontadorConversasChat` e o `ItemConversaTile`, agora desconsideram mensagens da conversa ativa (`idConversaAtiva`), mantendo o sino da `CustomAppBar` e os badges da lista limpos enquanto o usuário está conversando.
- **Centralização do Nome da Conversa no Cabeçalho:**
  - Em `PainelConversaAtivaWidget`, o nome do contato/loja/grupo, avatar e status foram reposicionados com alinhamento centralizado geométrico (`Stack` e `Center`), garantindo harmonia visual e equilíbrio com os botões de retorno à esquerda e ações à direita.
- **Notificações Nativas no Android Estilo WhatsApp com Logo Nous e Resposta Rápida:**
  - A notificação no Android agora utiliza o ícone oficial do Nous (`@mipmap/ic_launcher`) tanto no ícone pequeno quanto no `largeIcon`, exibe a cor do tema da aplicação (`colorized: true`) e adota `MessagingStyleInformation`, permitindo responder diretamente pela notificação com envio imediato para a malha da rede local via `ChatService.enviarMensagemInstantanea()`.
- **Isolamento de Fotos de Perfis Profissionais de Lojas:**
  - Corrigido o resolvedor de fotos (`ResolvedorFotoChat.buildAvatar`) e o `MontadorConversasChat` para que buscas por lojas recém-criadas sem logotipo (ex.: "Berenice") nunca herdem ou exibam a foto do usuário que a criou; lojas sem logo personalizada exibem o ícone padrão de perfis comerciais do Nous (`Icons.storefront_outlined`).
- **Controle Flexível e Fim do Auto-Start Indevido do Servidor Balcão:**
  - Removida a inicialização automática silenciosa do servidor local como "Laricas" em `perfis_pdv_view.dart`. O servidor agora é iniciado sob demanda pelo usuário, com seletor de identidade que permite escolher entre atuar como "Usuário Nous" ou como uma Loja comercial específica.
- **Expurgo e Bloqueio Total de Lojas Host Artificiais ("Host: Usuário Nous"):**
  - **Servidor Puro em Modo Usuário Nous:** O `ServidorRedeLocal.iniciar()` agora suporta formalmente execução sem loja vinculada (`loja: null`), transmitindo anúncio UDP e rotas HTTP/WebSocket com `tipoHost: 'usuario'`, sem instanciar qualquer objeto `Loja` artificial.
  - **Expurgo Automático no Banco de Dados:** Adicionado `LojasService.expurgarLojasHostFalsas()`, que elimina do SQLite qualquer registro espúrio criado anteriormente (`id` iniciando com `host_`, tags `host_pessoal` ou nome `Host:`), acionado preventivamente no login e inicialização do `PdvProvider`.
  - **Garantia de Exibição Única de Lojas Autênticas:** `PdvProvider`, `LojasService` e `ClienteRedeLocal` bloqueiam adição, salvamento ou sincronização de lojas falsas de host, garantindo que em "Meus Perfis Profissionais" e "Perfis que eu participo" constem estritamente as lojas criadas pelos próprios usuários.
  - **Interface de Sincronização Wi-Fi Aprimorada:** O diálogo `SincronizacaoRedeDialog` mantém o seletor de transmissão na rede ("Transmitir na rede como:"), permitindo alternar entre "👤 Usuário Nous" e as lojas reais cadastradas, com ícones distintos na descoberta do Wi-Fi (pessoa em azul para usuários, loja em verde para estabelecimentos).

## v1.0.47 (build 48) — 29/10/2026

- **Ordenação Temporal Monotônica e Causalidade Distribuída (Relógio de Lamport):**
  - **Resolução de Skew de Relógios entre Dispositivos:** Resolvido o problema de mensagens invertidas quando o relógio do celular e do computador apresentam diferença de horário. Implementada causalidade lógica de Lamport tanto na criação otimista (`enviarMensagem`) quanto na persistência e reconciliação de rede (`salvarMensagem`), garantindo que novas mensagens sempre tenham timestamp estritamente posterior à última mensagem conhecida da conversa.
- **Eliminação Definitiva do Reabrimento Automático de Chat no Celular:**
  - **Fim da Recuperação Forçada em Reload:** Removido o bloco de auto-seleção indevida em `recarregarConversas()` quando nenhuma conversa está ativa (`_conversaSelecionada == null`). Ao fechar uma conversa no celular (`onVoltarMobile` ou botão voltar), o estado permanece nulo e limpo na lista de conversas, sem reabrir conversas em segundo plano a cada sincronização ou mensagem recebida.
  - **Consumo Único de `conversaInicialId`:** Parâmetros de navegação inicial agora são consumidos uma única vez na inicialização (`_conversaInicialConsumida`), impedindo que eventos do barramento local restaurem telas anteriores.
- **Correção Estrutural de Títulos de Conversa e Eliminação de Loops Recursivos:**
  - **Separação Rígida entre Nome do Contato e Título do Chat:** Refatorada a propriedade `temTituloConversa` para descartar títulos redundantes que replicam o nome do contato ou do grupo (`tituloConversa == titulo`).
  - **Eliminação de Loop Infinito no Montador de Conversas:** Substituída a chamada recursiva de `ChatService.renomearConversa()` dentro de `MontadorConversasChat.montarConversas()` pelo método silencioso `ChatService.atualizarMetadadosContatoConversa()`, que persiste atualizações cadastrais no banco SQLite sem disparar loops ininterruptos de notificação reativa e re-renderização.
  - **Higienização Automática de Dados Corrompidos:** Adicionada rotina de migração em `_migrarHistoricoExistenteParaConversas()` que limpa automaticamente registros antigos onde `titulo_conversa` havia sido indevidamente gravado com o nome do contato.
- **Otimização Extrema de Desempenho e I/O de Imagens:**
  - **Cache em Memória de Resolução de Caminhos (`_cacheResolucaoCaminhos`):** Adicionado cache rápido em `ImagemService.resolverCaminhoExistente()`, eliminando dezenas de verificações síncronas de sistema de arquivos (`existsSync`) por quadro para caminhos de fotos que não existem ou que vieram de plataformas diferentes (ex.: Android vs Windows).

## v1.0.46 (build 47) — 29/10/2026

- **Sincronização Local-First em Tempo Real de Convites de Loja:**
  - **Barramento de Convites via WebSocket:** Convites de loja (`ConviteLoja`), solicitações de papéis e remoções agora são transmitidos em tempo real via rede local (`novo_convite_loja` e `convite_loja_removido`) por `ConvitesService`, `NotificacoesProvider`, `ServidorRedeLocal` e `ClienteRedeLocal`.
  - **Anexação e Preservação de Metadados da Loja:** O envio do convite agora anexa a definição completa da `Loja`, que é salva imediatamente no SQLite do aparelho receptor. Ao aceitar o convite, o terminal convidado já possui os dados completos da loja sem erros de "loja indisponível".
  - **Sincronização na Conexão:** Ao identificar um terminal pelo CPF (`tipo: 'identificacao'`), o servidor busca e transmite imediatamente todos os convites pendentes armazenados para aquele cidadão (`sincronizacao_convites`).
- **Eliminação Total de Flickering e Piscas no Chat:**
  - **Remoção de Animações Concorrentes:** Substituído o widget `TextoRolante` por `Text` com `TextOverflow.ellipsis` no cabeçalho da conversa ativa (`PainelConversaAtivaWidget`), em todos os cards da lista lateral (`ItemConversaTile`) e no card de arquivos anexos (`CardMensagemArquivo`), eliminando dezenas de timers concorrentes e o efeito visual de piscar intermitente.
  - **Banner de Título Sob Demanda:** O banner de título no topo do histórico agora só é renderizado quando a conversa de fato possui um título definido (`temTituloConversa == true`), sem poluir a área do chat com caixas de layout instáveis.
- **Debouncing de Atualizações Reativas no Chat:**
  - Implementado debounce de 120ms em `_aoAtualizarChat` no `MensageriaView`, agrupando disparos rápidos de mensagens e sincronização para evitar reconstruções e leituras de banco desnecessárias.
- **Nova Regra de Arquitetura (.agents/rules/contrato_rede_local_first.md):**
  - Formalizado o contrato de 4 elos obrigatórios (Persistência Origem -> Despacho WebSocket -> Recepção Destino -> Reatividade UI) e proibição de animações contínuas em listas dinâmicas.

## v1.0.45 (build 46) — 29/10/2026

- **Solução Definitiva do Loop de Conexão/Desconexão Wi-Fi no Celular:**
  - **Eliminação de Corrida Concorrente:** Adicionada trava atômica `_conectando` e guarda de estado em `ClienteRedeLocal`, impedindo que broadcasts UDP a cada 3 segundos ou múltiplos disparos paralelos chamem `conectar()` enquanto uma conexão já está em andamento.
  - **Descarte de Eventos `onDone` de Sockets Substituídos:** O ouvinte de WebSocket agora compara `_ws == socketInstancia`, garantindo que o fechamento ordenado de conexões antigas nunca mais feche o novo socket ativo nem dispare `_aoDesconectar()` acidentalmente.
  - **Isolamento de Terminais por CPF no Servidor Balcão:** O `ServidorRedeLocal` agora desduplica conexões estritamente por CPF em vez de fechar indiscriminadamente por IP (`mesmoIp`), permitindo múltiplos terminais na mesma sub-rede/Wi-Fi sem que um aparelho mate a conexão do outro.
  - **Proteção de Reconexão Manual e Desconexão Limpa:** `desconectar(manual: true)` agora sinaliza explicitamente a intenção do usuário, cancelando temporizadores residuais e impedindo loops de reconexão forçada.

## v1.0.44 (build 45) — 29/10/2026

- **Eliminação Definitiva da Reconciliação Destrutiva de Conversas:** Removida a rotina que excluía conversas e mensagens locais no celular caso o servidor balcão ainda não as tivesse registrado. Conversas locais agora são estritamente preservadas e protegidas contra apagamentos acidentais.
- **Fim do Atraso de 35 Segundos no Envio e Conexão:** Dispositivos e cidadãos/usuários Nous conectados com CPF válido na rede Wi-Fi agora são auto-autorizados instantaneamente (0ms) no `ServidorRedeLocal`, eliminando o modal de bloqueio de 35/45 segundos que travava conexões de terminais móveis e atrasava a transmissão de mensagens.
- **Confirmação Imediata de Entrega (2 Checks) via WebSocket:** O `ServidorRedeLocal` agora despacha imediatamente uma confirmação de entrega (`mensagem_entregue`) de volta ao socket remetente ao receber uma mensagem de chat, garantindo atualização em tempo real do status de envio.
- **Limpeza Defensiva de Tombstones Espúrios de Usuários:** Adicionada rotina de expurgo de tombstones espúrios (`user_%`) na inicialização do `ChatService`, ressuscitando imediatamente conversas de contatos pessoais (como a Carol) que haviam sido marcadas indevidamente como excluídas.
- **Persistência e Restauração da Última Conversa Aberta:** O `MensageriaController` agora memoriza e restaura a última conversa ativa por usuário através do `SharedPreferences`, assegurando que o contexto de navegação não seja perdido ao abrir e fechar a tela no celular.

## v1.0.43 (build 44) — 29/10/2026

- **Bloqueio de Mensagens Diretas para a Loja Coletiva Nous:** A Loja Nous Coletiva (`loja_nous_coletiva`) agora fica restrita exclusivamente ao seu chat público acessível diretamente dentro da loja. Ela não é mais inserida como conversa 1-a-1 na barra lateral de chats, nem na lista de contatos do diálogo "Nova Conversa", e conversas diretas residuais com a Loja Nous são automaticamente expurgadas do banco de dados local.
- **Ressurreição Imediata de Conversas Excluídas ao Enviar Mensagens:** Solução definitiva da falha em que contatos (como a Carol) não apareciam na lista de chats após o envio de mensagem. O tombstone em `conversas_excluidas` agora é automaticamente removido pelo `ChatService` ao enviar mensagens, ao selecionar/iniciar uma conversa e durante a leitura de exclusões, garantindo que qualquer conversa com atividade recente volte a ser exibida instantaneamente na lista lateral.
- **Desacoplamento Rigoroso entre Nome do Contato e Título/Assunto da Conversa:** O nome oficial do contato (`conversa.titulo`, ex: "Claudiane Basilio Fernandes") nunca mais é sobrescrito ou corrompido ao alterar o título de uma conversa. Foi criado o campo persistido e sincronizado `tituloConversa` (`titulo_conversa` no SQLite) para armazenar o título customizado ou assunto temático atribuído pelo usuário àquela conversa.
- **Banner de Título de Conversa no Topo da Área de Chat com Rolagem Natural:** O título da conversa agora é exibido como um banner elegante no topo da área de rolagem do chat (acima da primeira mensagem), permitindo edição rápida através de botão contextual. Conforme novas mensagens são enviadas e a conversa cresce para baixo, o banner sobe naturalmente com o histórico do chat.
- **Identificação de Títulos Customizados na Lista Lateral:** Na lista de conversas, o título do item continua sendo o nome real da pessoa, e caso a conversa possua um título/assunto customizado, ele é exibido sutilmente com o marcador `🏷️ [Título da Conversa]` no subtítulo, oferecendo clareza sem alterar a identidade do interlocutor.

## v1.0.42 (build 43) — 29/10/2026

- **Identidade Real e Autocura de Contatos na Mensageria:** Solução definitiva da causa-raiz que atribuía o nome e a foto do próprio usuário logado aos cards de contato quando este enviava a última mensagem (`_migrarHistoricoExistenteParaConversas`, `obterTodasConversas`, `enviarMensagemInstantanea`). Agora o interlocutor é resolvido e mantido de ponta a ponta com nome real, foto de perfil soberana e `@username`.
- **Blindagem de Títulos Customizados contra Nomes do Próprio Usuário:** `ChatService.obterTitulosCustomizados([String? cpfLogado])` filtra ativamente variantes de nome civil, social e apelido do usuário autenticado, impedindo que nomes de remetente gravados em conversas 1-a-1 sejam interpretados como apelidos locais.
- **Autocura e Sanitização de Avatares no ResolvedorFotoChat:** Detecção e descarte proativo do avatar do usuário autenticado em chats 1-a-1; o resolvedor busca o avatar verdadeiro do contato ou seu fallback gerado com iniciais elegantes, atualizando e curando registros incorretos no SQLite.
- **Subtítulo Harmonioso com @username no ItemConversaTile:** Quando a conversa possui `@username`, a visualização exibe `@username • última mensagem` (ou apenas `@username` caso ainda não haja mensagens), garantindo busca instantânea e identificação imediata sem o termo genérico "Conversa".
- **Modularização Arquitetural das Abas da Loja:** Extração de `BarraDeAbasDaLojaWidget` e `BotaoAbaLojaWidget` para `lib/src/features/pdv/views/widgets/abas_loja/barra_de_abas_loja_widget.dart`, reduzindo o arquivo `dados_perfil_view.dart` em mais de 2.200 linhas com desacoplamento total de responsabilidade.
- **Modularização do Demonstrativo Financeiro (DRE):** Extração do relatório DRE em modal dedicado (`DialogDemonstrativoDRE` em `lib/src/features/pdv/views/dialogs/dialog_demonstrativo_dre.dart`), enxugando `financeiro_view.dart`.
- **Modularização da Janela de Nova Venda do PDV:** Criação de `lib/src/features/pdv/models/modelos_nova_venda.dart` para `LinhaCarrinho`, `LinhaPagamento`, `ItemRascunho` e `RascunhoVenda`; extração de `BotaoHoverForma`, `DialogEscolherVarianteItem`, `DialogEditarAcompanhamentos` e `DialogSeletorItemCategoria`, enxugando e desacoplando a experiência de frente de caixa.
- **Controle Direto e Resiliente de Ligar/Desligar o Servidor Local da Loja:** Disponibilizado botão liga/desliga (Switch) direto e reativo para o servidor Wi-Fi do balcão na tela "Status da Loja" (`StatusLojaView`) e no card de sincronização dos "Ajustes da Loja" (`AbaAjustesLojaWidget`), sem exigir navegação oculta por diálogos. No menu de sincronização (`CustomAppBar` e `SincronizacaoRedeDialog`), o diálogo agora recebe a loja ativa do PDV (`buscarPorId(lojaId)`), não força mais a aba cliente quando aberto sem parâmetro e implementa fallback defensivo soberano, garantindo que o servidor possa ser iniciado ou desligado com 1 clique a qualquer momento.
- **Isolamento de Fotos de Lojas contra Fotos de Usuários:** Conversas com lojas no modo social agora preservam rigorosamente o `logo` da loja e descartam proativamente a foto do próprio usuário logado caso tenha sido associada indevidamente no SQLite (`ChatService.obterTodasConversas`, `MontadorConversasChat` e `ResolvedorFotoChat`), sanando a exibição de lojas com a foto do titular.
- **Filtro de Busca Inteligente Sem Falsos Positivos de Lojas:** `MensageriaController.combinaBusca` agora ignora prefixos técnicos como `loja_` e o subtítulo genérico `'Loja'` na busca por caracteres únicos (como a letra "j"), evitando que todas as lojas sejam listadas indevidamente ao pesquisar por contatos ou amigos.
- **Sincronização e Reconciliação Instantânea de Contatos entre Celular e PC:** Exposição pública de `reconciliarContasComServidor()` no `ClienteRedeLocal` com notificação reativa de alteração no `ChatService`, permitindo que celulares conectados pela primeira vez com outro CPF recebam imediatamente todo o catálogo de contas de usuários do balcão e os exibam na busca da mensageria.
- **Ordenação Estável de Conversas e Reordenação Imediata ao Enviar:** Correção no `MontadorConversasChat` que atribuía indevidamente `DateTime.now()` a lojas e contatos sem histórico de mensagens toda vez que a lista era reconstruída, fazendo com que conversas vazias saltassem para o topo e empurrassem conversas ativas (como a loja "Laricas") para baixo. Agora conversas sem mensagens iniciam com época zero (`fromMillisecondsSinceEpoch(0)`), e ao enviar uma mensagem o `MensageriaController` reposiciona a conversa imediatamente no índice 0 (topo da lista).
- **Proteção Total contra Crash de Ciclo de Vida do MensageriaController:** Resolução definitiva da exceção `FlutterError (A MensageriaController was used after being disposed)` ao navegar para a loja ou trocar de tela após enviar mensagem. Todas as operações assíncronas em segundo plano (`enviarMensagemInstantanea.then`, `sincronizarComRedeLocal`, `recarregarConversas`, `inicializar`, `selecionarOuIniciarConversa`) e os listeners da `MensageriaView` agora checam rigorosamente `isDisposed` e `mounted` antes de despachar notificações ou alterar o estado da interface.
- **Qualidade, Estabilidade e Testes Unitários:** Adição de testes cobrindo reordenação para o topo no envio, ordenação de conversas vazias versus ativas e blindagem de ciclo de vida após descarte; 100% de testes automatizados passando (85/85) e zero avisos ou erros no `flutter analyze`.

## v1.0.41 (build 42) — 28/10/2026

- **Modularização Arquitetural e Alta Performance na Mensageria:** Refatoração completa da tela de chat (`mensageria_view.dart`, anteriormente com mais de 5.390 linhas), dividida em camadas soberanas e desacopladas: controller reativo (`MensageriaController`), widgets especializados (`ListaConversasWidget`, `PainelConversaAtivaWidget`, `BalaoMensagemWidget`, `ItemConversaTile`), cards dedicados (áudio, imagem, arquivo, comanda), diálogos isolados em `views/dialogs/` e serviço centralizado com cache de fotos (`ResolvedorFotoChat`).
- **Eliminação de Gargalo em Tempo de Execução e Autocura de Mídias:** Remoção das centenas de consultas e loops assíncronos que travavam a renderização a cada mensagem recebida; resolução de fotos agora conta com cache em memória em tempo constante (O(1)); correção do encaminhamento de mensagens para envio e despacho imediato na malha local; e correção da galeria de mídias que agora consome as mensagens ativas em tempo real.
- **Nova Regra Institucional de Modularidade e Limite de Tamanho de Arquivos:** Instituída diretriz mandatória em `.agents/rules/modularidade_e_tamanho_arquivos.md` e `AGENTS.md` fixando teto estrito de 500 a 800 linhas para arquivos `.dart`, proibindo arquivos monolíticos gigantes e exigindo divisão padronizada em views, controllers, widgets, dialogs e services.
- **Unificação e Fim de Contatos Duplicados na Mensageria:** Implementado o método `ChatService.consolidarConversasDuplicadas()` e desduplicação canônica por chave universal de identidade (`user_{cpf}`, `grupo_{id}`, `loja_{id}`). Cada pessoa física, loja ou grupo aparece exatamente uma única vez na lista de conversas, agrupando históricos fragmentados e isolando os clientes do balcão do PDV da lista de amigos/contatos do chat social pessoal.
- **Títulos com Nomes Reais de Contatos (Padrão WhatsApp):** Os cards na lista de conversas, o campo de busca e o cabeçalho ativo agora exibem com destaque o nome real do interlocutor (ex: nome da pessoa, da loja ou do grupo), eliminando o texto genérico "Conversa" e removendo a faixa cinza redundante que ocupava o topo do chat.
- **Higiene do Repositório Git e Proteção de Tamanho:** Adicionada regra no `.gitignore` para a pasta `dist/` e instaladores/binários (`*.apk`, `*.exe`), e atualizado o arquivo `AGENTS.md` com diretrizes permanentes de higiene do repositório, unicidade de mensageria e cuidado proativo com desenvolvedor iniciante.
- **Ordenação Cronológica Estrita e Ancoragem ao Fim no Chat:** Refinada a ordenação de mensagens com critério rigoroso `data_hora ASC, id ASC` tanto no banco de dados SQLite quanto na mesclagem em memória, corrigindo inversões temporais quando mensagens são enviadas alternadamente pelo celular e computador; implementada rolagem automática imediata para o final da tela após envios locais e recebimentos em tempo real via rede Wi-Fi.
- **Separação Rigorosa entre Nome do Grupo e Nome da Conversa:** Introduzido o campo persistido `nomeGrupo` (`nome_grupo` no SQLite) em `ConversaChat` e nos payloads de sincronização em rede local. O nome atribuído ao grupo ao ser criado permanece inalterado e preservado mesmo que o usuário renomeie a conversa para outro título; o card da conversa, o cabeçalho e o modal de detalhes agora diferenciam perfeitamente o título da conversa e o nome original do grupo.
- **Fluidez Absoluta e Fim dos Travamentos na Busca de Contatos:** Eliminada a execução de chamadas assíncronas com múltiplos `setState()` disparadas indevidamente de dentro do método de renderização `build` dos avatares ao renderizar a lista de contatos; adicionado debounce de 180ms no input de pesquisa de mensagens e unificação dos contatos locais e usuários conhecidos da rede com comparação insensível a acentos (`TextoUtils`), garantindo resposta instantânea e fluida ao digitar.
- **Leitura Dinâmica do Changelog na Janela de Atualizações do Sistema:** O arquivo `CHANGELOG.md` foi adicionado aos assets do aplicativo no `pubspec.yaml` e conectado ao `ChangelogService`. A janela "Atualizações do sistema" e o diálogo de atualização agora extraem em tempo real as notas de lançamento da versão exata que o usuário está prestes a baixar/atualizar, descartando mensagens genéricas.

## v1.0.40 (build 41) — 28/10/2026

- **Conexão Ubíqua Sem Dependência de Loja Aberta no Balcão:** O endpoint `/api/loja` e o upgrade WebSocket do `ServidorRedeLocal` agora respondem com sucesso 200 OK mesmo quando o computador estiver na tela de Mensagens ou Perfil Nous (sem loja comercial ativa vinculada). Isso resolve a falha em que o celular recebia 404 e abortava o WebSocket antes de conectar.
- **Espelhamento Bidirecional de Grupos e Mensagens em Tempo Real:** Implementados handlers para `grupo_criado`, `grupo_atualizado`, `mensagem_editada` e `mensagem_excluida` tanto no `ServidorRedeLocal` quanto no `ClienteRedeLocal`. Grupos criados no celular agora aparecem imediatamente no computador e vice-versa.
- **Silenciamento Inteligente de Auto-Notificação (Estilo WhatsApp):** Quando uma mensagem enviada pelo usuário em um dispositivo (ex: computador) é espelhada nos outros aparelhos da mesma conta (ex: celular Android), o aparelho reconhece a autoria por CPF, marca a mensagem como `enviadaPorMim: true` e a espelha na conversa silenciosamente, sem emitir bipe sonoro e sem disparar notificação push no Android como se fosse mensagem de si mesmo.
- **Envio com Tecla Enter no Teclado do Computador:** O campo de texto da mensageria no desktop agora envia mensagens diretamente ao pressionar a tecla `Enter`, permitindo quebras de linha com `Shift + Enter`. Em dispositivos móveis (Android/iOS), o Enter do teclado virtual continua quebrando linhas normalmente.

## v1.0.39 (build 40) — 28/10/2026

- **Eliminação de Presenças Duplicadas no Balcão (Computador 5x):** O `ClienteRedeLocal` agora aborta imediatamente tentativas de conexão se a máquina já for o Servidor Balcão ativo (`ServidorRedeLocal().ativo == true`), e o endpoint `/api/ws` rejeita upgrades locais/loopback (`127.0.0.1`, `::1` ou IP local). Em `obterTodasPresencas()`, foi adicionada filtragem rigorosa de loopbacks e desduplicação por CPF e IP, garantindo que o computador apareça exatamente uma única vez na janela "Sincronização em Rede Wi-Fi".
- **Auto-Autorização Instantânea (0ms) para Mesma Conta e Membros:** O servidor balcão agora reconhece conexões da mesma conta (mesmo CPF do balcão e do celular), do dono e de membros cadastrados, auto-aprovando a conexão imediatamente sem travar a interface nem abrir modais de autorização de 35 segundos, permitindo sincronia transparente e instantânea.
- **Envio de Mensagens Resiliente e Desbloqueado no Celular:** Removida a tentativa síncrona bloqueante de upload de foto do remetente no envio de texto comum (`enviarMensagemChat`), permitindo entrega em microssegundos. Implementado fallback automático para HTTP POST `/api/chat/mensagem` caso o WebSocket oscile, e implementado esvaziamento proativo da fila de mensagens pendentes (`ChatService.drenarFilaDeSaida()`) no momento da reconexão.
- **Padronização dos Títulos Padrão de Conversas como "Conversa":** Tanto na lista lateral de chats quanto nos cards e no cabeçalho ativo, conversas 1-on-1 adotam rigorosamente o título padrão `"Conversa"`, alocando o nome do contato no subtítulo, mantendo a possibilidade de o usuário renomear individualmente.

## v1.0.38 (build 39) — 28/10/2026

- **Reconciliação Rigorosa Pan-Dispositivo (Paridade PC x Celular):** Implementada a purga automática e reconciliação bidirecional de conversas e mensagens na mesma rede Wi-Fi; conversas ou grupos excluídos em um dispositivo são limpos imediatamente no outro sem ressuscitar, eliminando divergências na lista de chats.
- **Auto-Inicialização e Descoberta Contínua de Rede:** O Servidor Balcão no Windows agora inicializa automaticamente em background no startup e os dispositivos móveis (Android) conectam-se imediatamente ao servidor via UDP ou último IP salvo, mantendo sincronia instantânea e transparente.
- **Download Resiliente e Cache de Fotos de Contatos no Mobile:** Correção na resolução de fotos de contatos no celular; a busca remota agora baixa a imagem do balcão para o armazenamento local sob ambos os identificadores (hash e basename) e persiste o caminho atualizado, garantindo carregamento impecável dos avatares de todos os contatos.
- **Padronização do Título Padrão como "Conversa":** O título padrão exibido no cabeçalho das conversas 1-on-1 foi padronizado rigorosamente para `"Conversa"`, removendo o prefixo "Conversa com [nome]" ou o nome isolado do usuário, mantendo a opção do usuário renomear livremente ou manter o nome do grupo caso seja grupo/sala.

## v1.0.37 (build 38) — 28/10/2026

- **Sincronização Perfeita Pan-Dispositivo e Exclusão com Tombstones:** Implementada a tabela de tombstones `conversas_excluidas` e rotas de exclusão sincronizadas via HTTP e WebSocket; conversas e grupos excluídos no computador não ressuscitam mais no celular na mesma conta e rede Wi-Fi, garantindo paridade absoluta entre dispositivos.
- **Autocura e Download Automático de Fotos em Dispositivos Móveis:** As fotos de contatos, perfis e anexos de chat são verificadas em tempo real e baixadas automaticamente via `ClienteRedeLocal().baixarImagemRemota` quando ausentes no armazenamento local do celular, corrigindo contatos que apareciam sem foto.
- **Correção do Cursor de Pesquisa nas Mensagens:** Removido o elemento de sobreposição incorreto que fazia o traço de digitação se posicionar sobre a letra "E" da palavra "Pesquisar"; agora o input utiliza o `hintText` nativo com padding harmonioso e alinhamento milimétrico do cursor antes do primeiro caractere.
- **Preservação de Título das Salas Comunitárias da Loja Nous:** Corrigido o fallback na recepção de mensagens que renomeava salas comunitárias criadas pelo celular (como "Desenvolver") para o nome do usuário ("Leonardo"); o título da sala agora é preservado integralmente entre todos os dispositivos.
- **Explorador Completo de Salas Comunitárias da Loja Coletiva Nous:** Criado o diálogo interativo "Explorar Salas Comunitárias", permitindo aos usuários buscar salas por nome com filtro insensível a acentuação, entrar em novas salas, sair de salas existentes e apagar salas criadas pelo próprio usuário (com a sala `#Geral` sendo a única comunitária padrão fixa).
- **Visualizador Universal de Imagens com Zoom, Download e Encaminhamento:** Criado o componente `VisualizadorImagemChatDialog` compartilhado entre o chat pessoal do usuário Nous, chats de lojas e o chat comunitário da Loja Nous; permite abrir fotos em tela cheia com gestos de pinça/zoom (`InteractiveViewer`), baixar a imagem com seletor de arquivos no desktop ou salvamento no celular, e encaminhar para qualquer conversa aberta com feedback visual.
- **Saída Discreta de Grupos e Notificações Sem Invasão:** Ao sair de um grupo, a aplicação não dispara alertas ou notificações intrusivas para outros membros; apenas registra no histórico do chat do próprio grupo uma mensagem informativa discreta de sistema indicando que o usuário saiu.

## v1.0.36 (build 37) — 28/10/2026

- **Alinhamento Uniforme e Reto da Identidade do Usuário:** Padronização de um slot fixo de 20px para o ícone de privacidade em todas as linhas de `_linhaInfo` em `FichaUsuarioDialog`, eliminando o zigue-zague visual nos textos da coluna direita; centralização matemática simétrica do CPF com `Stack` e `SizedBox(width: 220)` sem qualquer deslocamento causado pelo olho de privacidade.
- **Capitalização Inteligente de Nome e Endereço com Preservação de Minúsculas:** `PrimeiraLetraMaiusculaFormatter` aprimorado para detectar deleção pelo usuário e permitir a digitação de letras minúsculas intencionais (como preposições "de", "da", "do"), preservando-as durante a digitação subsequente.
- **Busca Insensível a Acentuação em Todo o Sistema:** Utilitário `TextoUtils` integrado aos modelos `Cliente` e `Fornecedor`, ao diálogo de Nova Venda (categorias e produtos), estoque, relatórios e contatos de chat; digitar letras sem acento agora localiza instantaneamente registros com acento e vice-versa.
- **Layout Adaptativo e Responsivo da Janela "Nova Venda":** Redistribuição equilibrada dos containers no desktop/notebook (coluna da esquerda com Produto, Comanda e Ajustes de Frete/Desconto; coluna da direita com Cliente, Pagamento e botão Concluir Venda), permitindo concluir vendas na marmitaria sem necessidade de rolar a tela com o mouse; transição fluída para 1 coluna vertical quando a janela for redimensionada para menos de 780px, e quebra dinâmica de campos em `_blocoAjustes` eliminando erros de `RenderFlex overflowed`.
- **Correção de Travamento ao Iniciar Nova Conversa na Loja:** Substituição de `ConstrainedBox` com `Column` por `SizedBox(width: 420, height: 450)` com altura definida em `_abrirDialogNovaConversa`, resolvendo assertion de constraints não limitadas no Flutter, com suporte a clientes cadastrados com CNPJ e proteção contra exceções.

## v1.0.35 (build 36) — 26/10/2026

- **Blindagem de Sintaxe SQL nas Consultas SQLite:** Correção de literais em cláusulas `WHERE` de [`ChatService`](file:///d:/Nous/nous/lib/src/features/chat/services/chat_service.dart), substituindo aspas duplas por argumentos parametrizados `?` em `obterInterlocutoresDoUsuario` e aspas simples em `obterGrupos`, eliminando o erro de `no such column: "sistema"` e prevenindo travamentos do aplicativo.
- **Persistência Integral de Histórico na Tela de Mensagens:** Correção do filtro de consultas SQLite que omitia conversas com lojas ou outros contatos ao reiniciar o aplicativo; a tela "Mensagens" agora preserva permanentemente todas as conversas iniciadas até exclusão deliberada pelo usuário.
- **Sincronização em Tempo Real Pan-Dispositivo (PC e Mobile):** Abertura ou criação de conversa em qualquer dispositivo na mesma rede local transmite imediatamente o evento `conversa_atualizada` via WebSocket (Servidor e Cliente), espelhando conversas instantaneamente entre computadores e celulares.
- **Universalização Completa do Chat em "Gestão do Perfil" (Perfil Profissional Nous):** A aba de gestão do perfil profissional agora adota a suíte universal completa de mensageria: gravação e envio de áudio nativo com timer, player com controle de avanço na bolha, captura de fotos com a câmera física do dispositivo, galeria, documentos, menu contextual (copiar, editar e excluir) e confirmação de entrega/leitura.
- **Tópicos Paralelos na Comunidade do Perfil Nous:** Usuários podem criar e alternar entre múltiplos tópicos de conversa com cabeçalho editável centralizado no meio do chat, delimitando assuntos sem atrapalhar outros grupos e escolhendo por tópico se desejam receber notificações na conta Nous através de um sino interativo.
- **Comportamento do Teclado no Android (Enter para Pular Linha):** Entrada de texto em todos os chats ajustada para multiline com `TextInputAction.newline`, garantindo que a tecla Enter do teclado virtual insira novas linhas, reservando o envio exclusivamente ao botão "Enviar" da interface Nous.
- **Mensagens de Voz no Chat (Estilo WhatsApp):** Gravação de áudio de alta fidelidade (.m4a AAC LC 128kbps) integrada com a biblioteca oficial `record`, permitindo gravar mensagens de voz diretamente da barra de envio ou do menu de anexos.
- **Barra de Gravação Interativa com Timer ao Vivo:** Ao iniciar a gravação, a barra de texto se transforma em uma interface de gravação com ícone pulsante, cronômetro de duração decorrida em tempo real, botão de descarte/cancelamento imediato com lixeira e botão de envio instantâneo.
- **Player de Áudio Nativo Integrado na Bolha:** Bolhas de áudio exibem reprodutor no padrão WhatsApp, com botão de Play/Pause, barra de progresso interativa para avanço/retrocesso temporal, contador de tempo decorrido/total e microfone colorido indicativo de mensagem de voz.
- **Alternância Dinâmica entre Microfone e Envio:** Campo de texto exibe o ícone de microfone quando vazio (para gravação ágil) e alterna fluidamente para a seta de envio assim que qualquer caractere for digitado.
- **Autocura e Sincronização Local de Mensagens de Voz:** Arquivos de áudio são transmitidos em Base64 na malha local via WebSocket e REST, suportando download e reprodução automática em qualquer aparelho da rede.
- **Permissão de Microfone no Android:** Declarada permissão `android.permission.RECORD_AUDIO` no manifesto da aplicação para operação completa em smartphones e tablets.
- **Primeira Letra Maiúscula no Endereço do Cliente:** `PrimeiraLetraMaiusculaFormatter` aplicado ao campo "Endereço" no cadastro de clientes, padronizando a formatação com o campo de nome.
- **Alinhamento Simétrico na Identidade do Usuário:** Padronização da largura dos inputs em 260px com `Stack` em `FichaUsuarioDialog`, garantindo centralização visual sem desvios.
- **Correção Completa do Encaminhamento de Mensagens:** Persistência imediata de conversas ao encaminhar mensagens e atualização reativa do histórico.
- **Filtro Estrito de Alterações na Janela de Atualizações:** Exibição exclusiva das novidades da próxima versão a ser instalada, omitindo o container de alterações caso o sistema já esteja na versão mais recente.

## v1.0.34 (build 35) — 26/10/2026

- **Reestruturação Soberana e Escalável de Mensageria (Padrão Big Tech):** Arquitetura desacoplada onde os dados residem no SQLite local com índices otimizados (`conversas_chat` e `mensagens_chat`), migração retrocompatível e integridade garantida dos dados legados.
- **Envio Otimista Instantâneo em 0ms:** Mensagens digitadas entram imediatamente na interface do usuário na hora do envio, limpando o input e avançando a rolagem sem travamentos de rede ou banco.
- **Fila de Saída Offline (*Outbox*) com Drenagem Automática:** Mensagens enviadas enquanto offline permanecem salvas localmente com status `pendente` e são automaticamente transmitidas e sincronizadas assim que a conexão de rede local (cliente ou servidor balcão) é estabelecida.
- **Ciclo Completo de Confirmação Visual de Mensagens:** Exibição nativa de relógio cinza (pendente na fila local), 1 check cinza (enviada e registrada na rede), 2 checks cinzas (entregue ao dispositivo receptor) e 2 checks azuis WhatsApp (`#34B7F1`) para mensagens lidas.
- **Persistência Imediata de Conversas:** Ao selecionar qualquer contato ou cliente para abrir um chat, a conversa é persistida na hora no banco SQLite, eliminando o problema de conversas abertas que desapareciam da lista.
- **Fixação e Arquivamento de Conversas:** Suporte a toque longo ou clique com botão direito para fixar chats com ícone de alfinete discreto no topo da lista e arquivar conversas.
- **Confirmação de Entrega em Tempo Real:** Servidor e cliente agora emitem e retransmitem o evento `mensagem_entregue` via WebSocket, atualizando instantaneamente os 2 checks cinzas no nó remetente.
- **Formatação com Primeira Letra Maiúscula no Endereço do Cliente:** `PrimeiraLetraMaiusculaFormatter` integrado ao campo "Endereço" no diálogo de clientes, padronizando a grafia automaticamente com o campo de nome.
- **Alinhamento e Centralização Simétrica na Identidade do Usuário:** Inputs de Apelido e Nome Próprio em `FichaUsuarioDialog` padronizados com 260px de largura e ícone de visibilidade integrado em `Stack`, eliminando o desvio visual do eixo central.
- **Correção Completa do Encaminhamento de Mensagens:** `_dialogEncaminharMensagem` agora persiste a conversa de destino com `ChatService.salvarConversa`, anexa a foto real do remetente, despacha pela rede local e atualiza a interface reativamente.
- **Filtro Estrito de Alterações na Janela de Atualizações:** `AtualizacaoDialog` agora exibe exclusivamente os itens da próxima versão a ser instalada, omitindo o container de alterações quando o sistema já se encontra na versão estável mais recente.

## v1.0.33 (build 34) — 24/10/2026

- **Isolamento Absoluto entre Conversas da Conta Pessoal e Painel da Loja:** Campo `lojaId` adicionado ao modelo `ConversaChat` e tabela SQLite com migração defensiva; grupos e conversas sociais da conta pessoal agora são filtrados e restritos ao escopo social (`loja_id IS NULL`), impedindo que apareçam dentro do atendimento das lojas e vice-versa.
- **Sincronização Pan-Dispositivo Bidirecional de Conversas e Grupos:** Endpoints `/api/chat/conversas` (GET) e `/api/chat/conversas/sync` (POST) implementados no servidor e integrados ao cliente; o histórico de chats e grupos criados no celular ou PC é unificado e sincronizado em qualquer dispositivo conectado com a mesma conta.
- **Janela de Detalhes do Grupo no Cabeçalho e Edição de Foto:** Clicar no cabeçalho ou botão de informações de um grupo abre modal detalhado com contagem, lista de participantes com identificação visual de "Você", galeria de mídias/documentos e botão com acionamento de câmera/galeria para alterar a foto do grupo, com replicação em tempo real na rede local.
- **Padronização Universal de Chats (Estilo WhatsApp em Todo o App):** Chat comunitário da Loja Nous (`AbaGestaoNousWidget`) e mensageria unificados: suporte a copiar texto, editar mensagens (com histórico de revisões e badge `(editada)`), excluir mensagens para todos até 1 minuto após envio e confirmação de entrega com risquinhos duplos azuis (`#34B7F1`) para mensagens lidas.
- **Correção do Ícone de Notificações Preso no Vermelho:** Sino da barra superior e `NotificacoesDialog` agora carregam mensagens de loja pendentes quando dentro de uma loja e limpam o status não lido ao dispensar ou tocar na mensagem, retornando o ícone para branco.
- **Exclusão de Loja Persistente e Propagada:** Processo de exclusão de loja tornado assíncrono com expurgo no banco local e transmissão do evento `loja_excluida` via WebSocket (cliente e servidor), impedindo que outro nó online ressuscite a loja excluída.
- **Regra Permanente de IA em `AGENTS.md`:** Seção 5, item 6 formaliza a exigência de aderência estrita ao padrão de mensageria WhatsApp nos padrões visuais do Nous para qualquer módulo de comunicação do sistema.

## v1.0.32 (build 33) — 24/10/2026

- **Reflexo Instantâneo de Privacidade e Transparência:** Alterações nas opções de visibilidade em "Privacidade e Transparência" agora atualizam o cache síncrono e notificam a malha de rede imediatamente via WebSocket e REST, refletindo em tempo real no container "Usuários Participantes" da tela "Dados do Perfil" em todos os aparelhos.
- **Abertura dos Chats no Final (Padrão WhatsApp):** Lista de mensagens de `MensageriaView` refatorada com `reverse: true` e âncora natural na última mensagem enviada, iniciando instantaneamente na base sem saltos visuais.
- **Acionamento da Câmera Nativa do Celular:** Botão de câmera do chat integrado ao pacote oficial `image_picker` (`ImageSource.camera`), acionando a câmera física do aparelho para fotografar e enviar fotos em tempo real.
- **Título da Conversa Centralizado Grande dentro do Chat:** O título da conversa agora fica posicionado dentro da própria área de mensagens, centralizado e em letras grandes com ação de clique para renomear, mantendo o nome do contato ou grupo intacto na barra superior (AppBar).
- **Persistência e Replicação do Chat Coletivo da Loja Nous:** Mensagens enviadas na aba de gestão da Loja Coletiva Nous agora são despachadas imediatamente na rede local e sincronizadas com todos os participantes.
- **Status de Visualização Realista para Contas Offline:** Mensagens enviadas para destinatários offline nascem como não lidas (`lida: false`) e só são marcadas como lidas quando o destinatário de fato abre o chat, emitindo evento de leitura na rede.
- **Criação e Propagação em Tempo Real de Grupos:** Criar um grupo agora despacha o evento `grupo_criado` e a mensagem de sistema via WebSocket para a malha da rede local, abrindo a conversa de grupo instantaneamente para todos os membros.
- **Navegação no Android com `PopScope` e Hover Permanente no Desktop:** O botão padrão de voltar do Android agora retorna para a lista de conversas da mensageria quando houver um chat aberto; no modo desktop, a conversa selecionada mantém o destaque visual e a borda temática ativos permanentemente.
- **Compartilhamento de Perfil com `@username`:** Ao clicar em "Compartilhar" no Perfil Social, o diálogo agora exibe e copia o identificador social `@nome_de_usuario` do cidadão Nous, e não o CPF.

## v1.0.31 (build 32) — 24/10/2026

- **Privacidade Granular de Dados Soberana:** Suporte a bloqueio e revelação de campos cadastrais (inclusive Nome Próprio / Nome Civil) em toda a aplicação. Dono visualiza e alterna a revelação permanente clicando no ícone do olho com persistência local (`SharedPreferences`). Terceiros veem censurado (`••••••••`) com ícone de olho para solicitar permissão por notificação deliberativa.
- **Transparência e Revogação de Acesso a Dados (`ContaNousView`):** Novo controle no container "Privacidade e Transparência" listando individualmente os membros autorizados para cada dado sensível, com botão para revogar a permissão a qualquer momento.
- **Fallback para Apelido em Caso de Nome Civil Privado:** Componentes como `UsuariosParticipantesContainer`, `DadosPerfilView` e cartões exibem o apelido do usuário quando o nome civil estiver privado sem autorização prévia, com suporte a solicitação direta por diálogo.
- **Ordem Natural das Mensagens no Chat (`MensageriaView`):** Rolagem e fluxo corrigidos para o padrão natural (mensagens antigas no topo, mensagens recentes embaixo, com autoscroll até o fim).
- **Seleção e Menu Contextual de Mensagens (Estilo WhatsApp):** Menu via clique/long-press permitindo Copiar texto, Encaminhar para qualquer contato/conversa, Editar texto (somente autor, mantendo histórico de versões visível em badge `(editada)`) e Excluir para todos (somente autor e com prazo estrito de até 1 minuto após envio).
- **Confirmação de Leitura com Double Check Azul:** Ícone `Icons.done_all` exibido em azul oficial WhatsApp (`#34B7F1`) para mensagens lidas e secundário para não lidas.
- **Renomeação de Conversas e Título Ampliado:** Conversas novas iniciam como "Nova Conversa" centralizado e com fonte 17px, permitindo renomeação direta ao clicar no título ou ícone de edição, refletindo imediatamente na rede local.
- **Destaque Permanente da Conversa Ativa na Sidebar (Desktop):** A conversa selecionada no desktop recebe borda sólida de 4px em `theme.buttonColor`, fundo com contraste nítido e contorno visível.
- **Captura Direta de Fotos pela Câmera:** Botão de câmera adicionado à barra de envio ao lado do clipe de anexos para registrar e enviar fotos instantaneamente.
- **Mídia, Links e Docs com Backup e Exclusão Mútua:** Diálogo de detalhes do contato agora conta com "Exportar backup da conversa" (arquivo JSON soberano) e "Excluir conversa" (com notificação deliberativa de consentimento mútuo).
- **Arquitetura de Alta Performance e Delimitação de Blockchain:** Removido overhead de encadeamento criptográfico contínuo em ações do PDV, consolidando o fluxo ultrarrápido em SQLite local e WebSockets para resposta instantânea de rede social massiva (60 fps). A arquitetura de blockchain e livro-razão imutável fica formalmente reservada para as funcionalidades futuras de Autogestão Social (deliberações, votações de urnas e contratos coletivos).

## v1.0.30 (build 31) — 23/10/2026

- **Suporte Unificado a Assets e Arquivos em Disco (`ImagemService`):** Implementados os métodos `ehAsset`, `obterImageProvider` e `construirImagem` com resolução automática e fallback transparente, suportando tanto assets do Flutter bundle (`assets/images/logo.png`) quanto imagens salvas localmente em disco.
- **Restauração da Logo do Perfil Coletivo Nous e Lojas Participadas (`PerfisPdvView` & Sidebars):** Corrigida a renderização de logos em `_PerfilCard`, `DesktopSidebarWidget`, `FormularioDadosLoja`, `ModoBalcaoWidget`, `BuscaMapaView`, `MensageriaView` e diálogos de rede/usuários, eliminando o erro de arquivos inexistentes para assets.
- **Upload e Sincronização Pan-Dispositivo Bidirecional de Lojas e Fotos (`ClienteRedeLocal` & `ServidorRedeLocal`):** No método `sincronizarPerfisLojasComServidor`, o cliente agora executa `_prepararLojaComUploadsParaServidor` enviando os arquivos físicos de logo, categorias, itens e contatos para o servidor balcão antes do envio do JSON, e o servidor consolida os snapshots com `LojasService.consolidarLojaComImagensLocais`, garantindo que lojas participadas criadas no celular (como a marmitaria) persistam com suas imagens no computador.
- **Proteção Absoluta contra Sobrescrita de Imagens Válidas (`LojasService`):** Ajustados `sanitizarCaminhosImagens`, `consolidarLojaComImagensLocais` e `autocuraImagensDeLojas` para preservar caminhos de assets e imagens físicas já existentes no disco local de cada dispositivo.

## v1.0.29 (build 30) — 23/10/2026

- **Padronização Soberana de Nome de Usuário (@username):** Garantido na fonte do modelo (`UsuarioNous.usernameExibicao`) que o nome de usuário contenha rigorosamente um único `@`, expurgando duplicações em todas as telas (Perfil Social, Busca & Mapa, Conta Nous e Identidade do Usuário).
- **Nome de Usuário Imutável na "Identidade do Usuário":** Exibição do Nome de Usuário Nous (`@username`) logo acima do CPF em `FichaUsuarioDialog` com estilo idêntico ao CPF (texto secundário, discreto e sem campo de edição), tornando evidente a proximidade visual e a imutabilidade dessas informações.
- **Perfil Profissional Coletivo "Nous" (Layout Exclusivo e Soberano):** Removidas as abas "Ajustes" e "Loja" da Loja Coletiva Nous, mantendo exclusivamente as abas "Dados" e "Gestão" no celular e no Desktop.
- **Aba Gestão da Loja Nous (Status da Loja e Chat Geral de Membros):** Substituído todo o layout comercial de vendas e pedidos da loja coletiva por um botão largo "Status da Loja" (mostrando o total de membros online na rede em tempo real) e um Chat Geral integrado com todos os membros da comunidade Nous.
- **Cargos e Permissões da Loja Nous (Sócio e Desenvolvedor Requisitado):** Removidas as hierarquias tradicionais da loja Nous; no container de cargos restam apenas as abas "Sócio" e "Desenvolvedor". A função de Desenvolvedor é voluntariamente requisitada com o botão "Se tornar Desenvolvedor" / "Deixar de ser um desenvolvedor", passando a exibir o rótulo `Sócio • Desenvolvedor` no container "Usuários Participantes".
- **Dados Institucionais Fixos e Proibição de Saída/Exclusão:** Removidos botões de salvar, excluir e sair da loja coletiva Nous; os dados do perfil passam a ser informativos e fixos (Nome: Nous, Email: nousstudios72@gmail.com, Redes: @nous.studios72, Categorias: Autogestão, Comunidade, Software Livre, Descrição: Software Universal de Autogestão Comercial e Social, Foto: Logo do App).
- **Sincronia Pan-Wi-Fi da Loja Nous e Chat:** Sincronização da loja coletiva e das mensagens do chat da comunidade disparada automaticamente ao conectar em qualquer loja via Wi-Fi.

## v1.0.28 (build 29) — 23/10/2026

- **Fluxo Oficial do Usuário: Login > Sincronia Wi-Fi > Triagem com E-mails:** O caminho de entrada foi corrigido para apresentar o diálogo de Sincronização Wi-Fi logo após a inserção do CPF no Login, garantindo que o dispositivo móvel se conecte ao balcão e receba os dados soberanos da conta antes de qualquer validação cadastral ou triagem de e-mails.
- **Preservação e Mesclagem Integral do Nome de Usuário (`@username`) via Wi-Fi:** Corrigidas as funções `_mesclarUsuarios`, `sincronizarIdentidadeUsuario` e `buscarUsuarioRemoto` no `ClienteRedeLocal` e `buscarConta()` no `AuthProvider` para mesclar integralmente o campo `nomeDeUsuario` (e metadados sociais/privacidade), impedindo que o nome de usuário cadastrado pelo computador seja descartado ou zerado no celular.
- **Transição Fluida da Triagem para os Perfis (`ContasUsuarioView`):** Ao escolher o e-mail na triagem, o usuário é direcionado diretamente para seus perfis/lojas sem duplicidade de abertura do diálogo de sincronização.
- **Suíte de Testes e Análise Estática:** Teste dedicado de preservação de `nomeDeUsuario` na mesclagem de contas adicionado, 60 testes executados com 100% de sucesso e `flutter analyze` com 0 apontamentos.

## v1.0.27 (build 28) — 22/10/2026

- **Organização e Perfil Profissional Coletivo "Nous" (`PdvProvider` & `PerfisPdvView`):** Adicionado perfil profissional de autogestão soberana "Nous" em "Perfis que eu participo", onde todos os usuários cadastrados no SuperApp são membros sócios deliberativos para evolução do software, com chat geral integrado.
- **Transmissão Direta de Alterações da Nova Versão via Wi-Fi (`AtualizacaoDialog` & `ServidorRedeLocal`):** O balcão agora envia no endpoint `/api/versao` a lista exata das alterações da nova versão ofertada, garantindo que o celular veja o que mudou na versão de destino e não na instalada; rótulo simplificado de "Alterações (CHANGELOG.MD)" para "Alterações".
- **Sincronização Bidirecional de Contas na Rede e Correção de Hardware (`ServidorRedeLocal` & `BuscaMapaView`):** Novos endpoints `/api/usuarios` (GET e POST) para unificação pan-rede das contas de usuários entre celulares e computador balcão; blindagem contra uso indevido de nomes de hardware (ex.: "BlackView") como identidade de cidadão.
- **Diálogo Obrigatório de Nome de Usuário (@username):** Criação de `CadastrarNomeUsuarioDialog` bloqueante para validação e cadastro obrigatório de nome de usuário Nous em minúsculas e sem espaços, exigido tanto para novos cadastros quanto para contas antigas no login e triagem de e-mails.
- **Hierarquia de Dados do Cliente em Nova Venda com `TextoRolante` (`NovaVendaDialog`):** Campo secundário do cliente na seleção e no container passa a priorizar 1º Endereço cadastrado, 2º Telefone, 3º Descrição e demais dados com animação contínua de `TextoRolante` para textos longos.
- **Capitalização Automática de Nome de Clientes (`ClientesDialog`):** Campo "Nome do Cliente" agora formata em tempo real com `PrimeiraLetraMaiusculaFormatter` (primeira letra de cada palavra em maiúsculo) e garante Title Case no salvamento do cadastro.
- **Conformidade Estática e Testes:** 60 testes unitários passando com 100% de sucesso e `flutter analyze` com 0 erros e 0 warnings.

## v1.0.26 (build 27) — 22/10/2026

- **Auditoria Imutável em Blockchain Local (`RegistroAcao` & `CriptoService`):** Cada ação registrada no PDV agora é criptograficamente encadeada com a anterior usando hash SHA-256 nativo (bloco gênese de 64 zeros), garantindo integridade inviolável sem bibliotecas externas.
- **Animação Vertical Fluida na Barra Universal (`FloatingBottomNavBar`):** Transição de tela reimplementada com `PageRouteBuilder`, `CurvedAnimation(Curves.easeOutCubic)` e deslocamento vertical suave (`SlideTransition` + `FadeTransition`), simulando o movimento de subida/descida do arrasto.
- **Identificador Único Nome de Usuário (`@username` em `UsuarioNous`):** Adicionado campo dedicado de nome de usuário único no cidadão (distinto do apelido e CPF), com exibição formatada, edição na "Conta Nous" e suporte em toda a rede.
- **Transparência e Privacidade com Deliberação por Notificação:** Novo container em `ContaNousView` com `ThemedSwitch` para definir visibilidade pública de dados civis; informações privadas exibem ícone de olho fechado que permite a terceiros solicitar autorização deliberativa ao titular via `NotificacoesProvider`.
- **Blindagem e Perda de Foco em Dados Borrados (`FichaUsuarioDialog`):** Containers de dados sensíveis ocultos agora utilizam `IgnorePointer(ignoring: true)`, bloqueando qualquer clique, hover ou foco nos botões borrados da janela "Identidade do Usuário".
- **Exclusão Definitiva de Conta Nous Unificada:** Botões e diálogos em `ContasUsuarioView` e `ContaNousView` unificados para "Excluir Conta Nous Definitivamente", expurgando registros do banco SQLite, limpando o cache persistido (`_chaveUltimoCpf`) e encerrando a sessão com segurança.
- **Tela Soberana de Busca & Mapa (`BuscaMapaView`):** Conexão do terceiro slot da barra universal com tela completa de busca por lojas e perfis de cidadãos, filtros dinâmicos, visita a lojas e sistema mútuo de "Seguir" / "Seguindo".
- **Suíte de Testes Automatizados e Análise Estática:** 60 testes unitários e de integração executados com 100% de sucesso e `flutter analyze` com 0 erros e 0 warnings.

## v1.0.25 (build 26) — 22/10/2026

- **Container "Nova Atualização" com Novidades Sintetizadas (`AtualizacaoDialog`):** O modal de atualização agora sintetiza o histórico de alterações diretamente do `CHANGELOG.md` e inclui botão de minimizar/maximizar para leitura opcional das novidades pelo usuário.
- **Restauração do Fluxo de Login com Triagem de E-mails (`ContasUsuarioView`):** Ao validar o CPF, o usuário passa pela triagem dos e-mails vinculados à sua conta Nous, definindo o e-mail ativo da sessão antes de avançar para a sincronização Wi-Fi e lojas (com fallback seguro "Continuar sem e-mail").
- **Edição de Nome Próprio na "Identidade do Usuário" (`FichaUsuarioDialog`):** O titular da conta agora pode alterar e salvar seu próprio nome civil a qualquer momento, mantendo o CPF permanentemente bloqueado contra alterações indevidas.
- **Aprovação Obrigatória de Conexão com Seletor Cliente vs Membro (`ServidorRedeLocal`):** Toda requisição de conexão remota exige aceite explícito no servidor balcão com alerta sonoro e seletor de papel entre Cliente (auto-atendimento de pedidos sem acesso a gestão) e Novo Membro da Loja (equipe operacional).
- **Nova Tela "Conta Nous" e Menu Reestruturado em Configurações (`ContaNousView` & `CustomAppBar`):** Criação da tela soberana "Conta Nous" agrupando Identidade, E-mails associados, Backup dos dados e Exclusão de Conta, além da integração do card de usuário no diálogo de configurações com o botão "Conta Nous".
- **Correção da Identificação do Operador no "Status da Loja":** O servidor balcão agora reflete fielmente o CPF e nome do operador logado na sessão ativa em vez de fixar indevidamente o dono original da loja.
- **Conformidade Estática e Testes Automatizados:** 54 testes unitários e de integração executados com 100% de sucesso e `flutter analyze` com 0 erros e 0 avisos.

## v1.0.24 (build 25) — 22/10/2026

- **Botão de Voltar no Chat em Modo Desktop (`MensageriaView`):** Ao acessar Mensagens pela barra flutuante universal no desktop e selecionar uma conversa (quando a barra é desabilitada), o topo agora exibe o botão de voltar à esquerda para desmarcar o chat e permitir navegação sem prender o usuário.
- **Separação Soberana entre Identidade do Usuário e Perfil Social:** A janela "Identidade do Usuário" (`FichaUsuarioDialog`) preserva exclusivamente os dados civis e cadastrais oficiais; a edição de perfil público no Perfil Social (`EditarPerfilDialog`) agora customiza apenas campos públicos (`nomePublico`, `apelidoPublico`, `fotoPublica`, `biografia`), com fallback transparente para a Identidade e sem sobrescrevê-la.
- **Envio Físico e Autocura de Fotos na Rede Local (`ChatService` & `ClienteRedeLocal`):** Fotos enviadas no chat agora embutem payload Base64 para gravação física direta no disco do destinatário (`salvarBytesImagemLocal`) e contam com autocura automática sob demanda via endpoint `/api/imagem`, garantindo visualização da imagem real no celular ou servidor balcão.
- **Container Dinâmico "Mídias, Links e Docs":** Modal de detalhes do contato no chat povoado dinamicamente com abas de fotos trocadas (com visualização em tela cheia), documentos (com abertura nativa) e detecção automática de links web com abertura no navegador.
- **Auditoria e Integridade de Testes:** 54 testes unitários automatizados cobrindo a integridade dos modelos e separação cadastral, com `flutter analyze` 100% limpo (0 erros e 0 warnings).

## v1.0.23 (build 24) — 21/10/2026

- **Ordem de Mensagens Invertida e Ancorada (`MensageriaView`):** `ListView.builder` atualizado com `reverse: true` e índice invertido (`length - 1 - index`), fixando as mensagens mais recentes na base ao lado do campo de digitação sem saltos ou sobressaltos de rolagem ao carregar.
- **Campo de Busca de Contatos com `TextoRolante`:** O placeholder do campo de pesquisa de contatos da mensageria agora conta com `TextoRolante` ativo quando vazio, eliminando qualquer truncamento visual de texto.
- **Envio de Fotos e Documentos no Chat:** Novo botão de clipe/anexo com envio de imagens (armazenadas em diretório local seguro com preview e visualização em tela cheia) e documentos/arquivos (com metadados de peso/tamanho e abertura no leitor nativo do sistema).
- **Compartilhamento Interativo de Comandas de Pedidos:** Envio de comandas no chat com card estilizado contendo número do pedido (`#0001`), cliente, resumo de itens, valor total e botão "Ver Comanda Completa"; adicionado botão "Chat" no diálogo de comanda (`ComandaPedidoDialog`) para compartilhamento em 1 clique com o cliente ou equipe.
- **Correção de Cores Fixas e Higiene Visual:** Remoção de `Colors.white` no badge de mensagens não lidas substituído por `theme.buttonTextColor`, e resumo inteligente na lista lateral exibindo identificadores de mídia (📷 Foto, 📎 Arquivo, 🧾 Comanda).
- **Persistência Completa de Anexos no SQLite:** Atualização do modelo `MensagemChat` e da tabela `mensagens_chat` com migração dinâmica de schema no `ChatService` para colunas `tipo`, `caminhoAnexo`, `nomeAnexo`, `tamanhoAnexo`, `pedidoId` e `dadosPedidoJson`.

## v1.0.22 (build 23) — 21/10/2026

- **Barra de Navegação Universal Dupla com Rolagem Vertical:** Cada um dos 5 botões da barra flutuante agora é duplo e rolável para cima e para baixo (gesto de swipe vertical ou rodinha do mouse), alternando instantaneamente os modos com micro-indicador de posição e transição suave.
- **Nova Tela Compras & Carteira (`ComprasUsuarioView`):** Carrinho da barra agora abre a tela com os 3 containers soberanos ("Carteira Soberana", "Carrinho de Compras" e "Histórico de Compras"), enquanto a lojinha rolável dá acesso a "Meus Perfis".
- **Acesso Direto à Mensageria:** O segundo botão rola entre o Perfil Social do Usuário e a tela de Mensagens (título limpo "Mensagens" sem o prefixo "Nous").
- **Telas Padrão "Em Construção":** Busca no mapa, player universal de mídias/PDFs, feeds e autogestão social abrem tela receptiva com `TextoRolante` e navegação contínua na barra.
- **Blindagem Definitiva contra Seta de Voltar Indesejada:** Adição de `automaticallyImplyLeading: false` no `CustomAppBar` e navegação raiz na barra universal, garantindo que o perfil público, compras e mensagens nunca exibam a seta indevida de retorno.
- **Ponto de Notificação Vermelho e Mensagens no Sino:** Sino fora de loja sinaliza com ponto vermelho novas mensagens do usuário e demandas da conta; o diálogo lista mensagens não lidas com foto e abre o chat diretamente ao tocar.
- **Notificações Nativas no Android estilo WhatsApp:** Integração com `flutter_local_notifications` permitindo ver novas mensagens e responder diretamente pela barra de notificações do Android (Direct Reply).
- **Texto Rolante Obrigatório (`TextoRolante`):** Aplicação estrita de texto rolante em todos os botões, cabeçalhos de perfil e novos containers para eliminar truncamento de informações.

## v1.0.21 (build 22) — 21/10/2026

- **Sincronização Absoluta de Status de Pedidos na Rede Local:** Comutação imediata de status de pedidos (aceitar, cancelar, observação) entre dispositivos móveis e balcão via WebSocket (`pedido_atualizado`) e REST (`/api/pedido`), com re-renderização profunda sem bloqueios por igualdade de IDs na UI.
- **Prevenção de Duplicidade em Pedidos Agendados/Programados:** Geração determinística de IDs por data (`prog_{id}_{ano}_{mes}_{dia}`) e centralização da orquestração de pedidos programados no servidor balcão, impedindo reabertura ou duplicação por terminais clientes ao reconectar.
- **Busca Unificada e Resolução de Fotos na Mensageria:** Campo de pesquisa na barra lateral localiza conversas abertas e contatos de toda a loja (equipe e clientes) por nome, cargo ou CPF; avatares de membros da equipe resolvem fotos reais por CPF com autocura prévia ao balcão.
- **Leitura Fluida sem Truncamento:** Aplicação do widget soberano `TextoRolante` no subtítulo do cabeçalho da conversa ativa e no preview da última mensagem para impedir corte de textos longos.

## v1.0.20 (build 21) — 21/10/2026

- **Privacidade Soberana na Ficha do Usuário (`FichaUsuarioDialog`):** Ícone de alternância de visualização com olho aberto/fechado (por padrão fechado), aplicando desfoque visual suave (`ImageFilter.blur`) sobre CPF, dados pessoais e e-mails associados para permitir prints seguros sem expor dados pessoais.
- **Edição Soberana do Perfil Público (`EditarPerfilDialog`):** Diálogo dedicado para edição livre de biografia, apelido (@), nome de exibição e foto de perfil, persistido no modelo `UsuarioNous` e sincronizado via rede local para todos os dispositivos.
- **Perfil Social (`PerfilSocialView`):** Remoção do botão de voltar quando acessado pela barra universal inferior (ícone pessoinha), exibição da biografia soberana e suporte ao modo visualização de perfil de terceiros com botão de retorno.
- **Mensageria com Painel Limpo (`MensageriaView`):** Eliminação da auto-seleção da primeira conversa ao abrir; o painel direito inicia limpo convidando o usuário a escolher um contato, com destaque visual aceso e hover fixo na conversa selecionada.
- **Contatos Ocultos por Padrão e Ação "+ Nova Conversa":** A lista lateral de chats exibe exclusivamente conversas já iniciadas ou grupos; contatos não iniciados são selecionados sob demanda através do botão com sinal de mais (+) ao lado de "Novo Grupo".
- **Janela de Detalhes do Contato estilo WhatsApp:** Clique no cabeçalho da conversa abre modal com mídias/documentos e botão direto "Ver Perfil Público" para navegar até o perfil do usuário e retornar com segurança.

## v1.0.19 (build 20) — 20/10/2026

- Conexão e sincronização bidirecional em tempo real do Chat Nous via rede local (WebSocket + REST) entre balcão e dispositivos móveis, com alerta sonoro e recarregamento automático da UI.
- Auto-autorização e associação imediata na loja de novos membros autenticados por CPF ao conectarem via Wi-Fi, eliminando timeout de 30s e bloqueio de novos aparelhos.
- Garantia de presença online em "Status da Loja": terminais móveis transmitem dados nominais de identificação e são refletidos imediatamente com status online no balcão e nos demais aparelhos.
- Otimização do fluxo de áudios/músicas na sincronização de loja: o download passa a ocorrer em background de forma assíncrona, evitando travamentos no handshake inicial e garantindo que o catálogo e mídias fiquem visíveis imediatamente.

## v1.0.18 (build 19) — 20/10/2026

- Desduplicação soberana de contatos por CPF na Mensageria (`MensageriaView`): membros da equipe e operador logado cadastrados como clientes são unificados em um único perfil/chat sem duplicações, preservando fotos e identificadores.
- Destaque visual da conversa ativa com fundo acentuado, borda indicativa e micro-interação de hover suave nos itens de conversa da barra lateral.

## v1.0.17 (build 18) — 20/10/2026

- Ponto de atenção vermelho nos botões "Mensagens" da Loja (barra lateral e gestão de pedidos) para alertar sobre novas mensagens não lidas.
- Persistência das mensagens no SQLite (`ChatService`) com chave de conversa canônica compartilhada (`loja_{id}_usuario_{cpf}`), sincronizando em tempo real as conversas entre a Loja e o Perfil Social do Usuário.
- Suporte a grupos de mensagens com múltiplos participantes via botão "+ Novo Grupo" e diálogo modal de seleção.
- Redesenho da tela "Perfil Social do Usuário" com alinhamento vertical centralizado para foto, apelido, nome e métricas.
- Botão "Mensagens" adicionado abaixo do botão "Clientes" na barra lateral desktop expandida com suporte a atalhos configuráveis de teclado.
- Conexão do botão "Mensagens" na aba "Gestão de Pedidos" e na barra lateral à interface de mensageria respondendo em nome da Loja com identificador de atendente.
- Criação da tela "Perfil Social do Usuário" (`PerfilSocialView`), acessível pelo segundo ícone (pessoinha) da barra flutuante universal, com foto, apelido, métricas, biografia, ações ("Editar Perfil", "Compartilhar", "Mensagens"), carrossel de destaques e grade de posts.
- Navegação bidirecional conectada na `FloatingBottomNavBar` entre Meus Perfis (carrinho) e o Perfil Social (pessoinha).
- Implementação da tela de Mensageria responsiva estilo WhatsApp (`MensageriaView`) e modelos `MensagemChat` e `ConversaChat`, com busca rápida e operação adaptável em modo Loja ou modo Usuário Nous.
- Remoção definitiva da cópia legada `Nous_Android_v1.0.0_Versao_Teste.apk` da pasta `dist/` e dos scripts de build, mantendo apenas a distribuição oficial versionada.
- Blindagem e robustez do endpoint `/api/download_apk` no servidor local para distribuição contínua do APK atualizado aos celulares por Wi-Fi sem erros.

- Padronização das barras de itens filhos (`ProdutoLojaRow`) no mesmo padrão visual da barra pai em Categorias e Grupos de Componentes (foto 32×32, nome expandido com `TextoRolante`, pílula arredondada de preço `R$`, switch compacto 28×16, chevron e menu de 3 pontos).
- Remoção da opção "Adicionar Grupo de Componentes" do menu de 3 pontos do item filho, mantendo apenas "Editar Item" e "Excluir Produto".
- Remoção do cabeçalho de colunas desalinhado "Produtos | Ativo | Preços" nas listas de itens de Categorias e Grupos de Componentes.
- Ativação de `TextoRolante` nos seletores de Categorias e Grupos de Componentes, resumo da descrição e cálculos de formação de custo/margem na janela "Editar Item".
- Eliminação do sinal `+` duplicado nos botões de criação rápida de categoria e grupo nos modais de seleção.
- Aplicação de `TextoRolante` nos títulos de checkbox (`CheckboxListTile`) para impedir quebra de linha em palavras longas (ex: "Acompanhamentos").
- Eliminação de espaçamentos e paddings invisíveis entre os botões de ação nas barras de Categorias e Grupos de Componentes, liberando cerca de 75px de largura extra para visualização dos nomes no modo celular.

## v1.0.15 (build 16) — 20/10/2026

- Padronização e compactação inicial das barras de "Categorias" e "Grupos de Componentes" na tela "Loja do Perfil".

## v1.0.14 (build 15) — 19/10/2026

- Reprodutor de áudio responsivo: layout adaptativo para celular com botões de reprodução centralizados e botão Play/Pause sempre visível em destaque.
- Aplicação de `TextoRolante` no título e subtítulo de áudios no player e no cabeçalho do modal de mídias (`DetalhesMidiaDialog`), eliminando truncamento de texto.
- Ocultação do container "Modo de Visualização e Layout do PDV" na aba "Ajustes do Perfil" no celular quando não houver teclado físico conectado.
- Aplicação de `TextoRolante` com restrição de largura no identificador de dispositivos conectados na "Lista de Trabalhadores" ("Status da Loja"), impedindo estouro de container.

## v1.0.13 (build 14) — 19/10/2026

- Correção da reprodução de áudios e músicas no celular conectado ao balcão (resolução de caminhos em subpastas de anexos, download assíncrono via streaming no Android e pareamento de áudio ativo pelo nome do arquivo).
- Nova rota de rede local `POST /api/upload_anexo` e correção de `/api/audio` com `resolverCaminhoExistente` no balcão.
- Sincronização bidirecional completa da loja: inclusão de upload de fotos de clientes, fornecedores, galeria e anexos ao enviar alterações do celular para o balcão.
- Blindagem contra ressurreição de dados excluídos via `manterItensAusentes: false` em `consolidarLojaComImagensLocais`.
- Atualização em tempo real de anexos (músicas, galeria, vídeos) e campos cadastrais da loja em `DadosPerfilView` ao receber atualizações da rede.

## v1.0.12 (build 13) — 19/10/2026

- Correção do loop infinito de alternância entre layout compacto e desktop no computador (eliminação de eco WebSocket e blindagem de preferências locais).
- Desvinculação definitiva ao sair de lojas participadas com exclusão no SQLite local, endpoint `POST /api/loja/sair` e expurgo de referências órfãs no balcão.
- Download automático e resolução de imagens/logo ao sincronizar perfis de lojas participantes no celular (`sincronizarPerfisLojasComServidor`).
- Resolução dinâmica do cargo real do usuário em "Identidade do Usuário" (exibindo cargos personalizados da loja ou papéis formais).
- Inclusão de nome e CNPJ da loja na comanda de pedidos programados nos Relatórios e fallback em `ComandaPedidoDialog`.
- Compilação automatizada com limpeza de instaladores e APKs antigos em `dist/` a cada ciclo de entrega.

## v1.0.11 (build 12) — estado na data da reorganização da documentação

- Isolamento contextual de notificações por loja; botão "Limpar todas as notificações".
- Container "Comandos" oculto no modo compacto do celular; reabilitado no Windows ou com teclado físico.
- Malha de autocura mútua na rede Wi-Fi (fotos de identidade e catálogos), fusão pan-dispositivo de perfis por CPF.
- Distribuição de atualizações e APK pelo balcão via Wi-Fi, com instalação in-app no Android.
- Modo desktop expandido com barra lateral e duas colunas; Modo Balcão; mesas e comandas; pedidos programados; DRE; Kardex; sons e alertas; cargos e permissões estilo Discord; reordenação por pressão.

> Histórico anterior a esta versão ficou registrado apenas no antigo `AGENTS.md` e não foi detalhado por versão.
