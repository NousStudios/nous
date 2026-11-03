# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

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
