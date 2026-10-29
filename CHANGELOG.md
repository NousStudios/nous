# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

## v1.0.41 (build 42) — 28/10/2026

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
