# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

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
