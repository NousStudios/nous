# MAPA DO APP — o que cada tela faz

Este documento descreve o Nous **por tela**: Tela → Container → Botão → o que acontece. Cada tela aparece **uma vez só**. Use-o para pedir mudanças ("na tela X, no container Y, o botão Z...").

**Como ler**
- 📄 indica o arquivo no código. Caminhos abreviados: `auth/` = `lib/src/features/auth/`, `pdv/` = `lib/src/features/pdv/`, `core/` = `lib/src/core/`, `notif/` = `lib/src/features/notificacoes/`.
- **(a confirmar)** = informação deduzida do nome do arquivo ou do texto antigo, ainda não conferida no código.
- Regras detalhadas de negócio: `docs/regras-de-negocio-pdv.md`. Rede/sincronização: `docs/rede-local.md`. Visual: `docs/design-system.md`.

---

## 0. Caminho geral do usuário

1. Abre o app → **Login** (`main.dart` abre `LoginView`).
2. Digita o CPF → **Entrar** → janela de **Sincronização em Rede Wi-Fi** (`SincronizacaoRedeDialog`), permitindo ao dispositivo se conectar ao balcão imediatamente e receber os dados soberanos da conta cadastrada em outros dispositivos da rede (inclusive o `@username`).
3. Avança para a tela de triagem de contas/e-mails (**ContasUsuarioView**), onde o usuário seleciona por qual e-mail associado à sua conta Nous irá operar (ou opta por continuar sem e-mail).
4. Chega em **Meus Perfis** (`PerfisPdvView`).
5. Toca em uma loja → entra na **Tela da Loja** (`DadosPerfilView`), com as abas Dados, Ajustes do Perfil, Loja e Gestão.
6. Dentro da loja abre as janelas de trabalho (Nova Venda, Caixa, Clientes...).

Dois estados mudam o comportamento de várias telas:
- **Fora de uma loja** (Login, Meus Perfis): notificações mostram só avisos da conta.
- **Dentro de uma loja**: notificações e contador mostram só avisos daquela loja.

---

## 1. Login e Identidade

### 1.1 Tela de Login
📄 `auth/views/login_view.dart` · widgets: `cpf_input_widget.dart`, `login_buttons_widget.dart`, `logo_widget.dart`
- **Campo CPF**: já vem preenchido com o último CPF que entrou (guardado no aparelho como `ultimo_cpf_login`). Valida o CPF (`cpf_validator.dart`). Possui máscara de privacidade que mantém os 3 primeiros dígitos visíveis e oculta os dígitos seguintes com pontos médios no meio da linha (`123.•••.•••-••`). Ícone interativo de olho aberto/fechado no campo permite alternar entre visualizar o número completo ou manter ofuscado; o ícone some automaticamente quando o campo está vazio.
- **Botão "Entrar"**: abre primeiramente o diálogo de **Sincronização em Rede Wi-Fi** (`SincronizacaoRedeDialog`). Ao se conectar ao balcão ou continuar, consulta a conta na rede local. Se for uma conta totalmente nova sem registro, abre `CadastrarNomeUsuarioDialog` e `CadastrarApelidoDialog`. Se for conta antiga sem `@username`, solicita o nome de usuário. Em seguida, avança para a tela de triagem de e-mails (`ContasUsuarioView`).
- **Ao digitar um CPF que já existe** (neste aparelho ou em outro da rede): recupera nome, nome de usuário, data de nascimento e foto via Wi-Fi do balcão. Se faltar nome de usuário, solicita a criação imediata.
- **Ao digitar um CPF novo** (sem ficha em lugar nenhum): abre `CadastrarNomeUsuarioDialog` pedindo o **Nome de Usuário (@)** e em seguida `CadastrarApelidoDialog` pedindo o **Apelido**. Ao confirmar, cria a conta Nous e o cidadão vira automaticamente membro sócio da loja coletiva "Nous". 📄 `auth/views/widgets/cadastrar_nome_usuario_dialog.dart` e `cadastrar_apelido_dialog.dart`
- Outras telas de acesso: `terms_view.dart` (termos de uso), `adicionar_email_dialog.dart` (adicionar e-mail à conta).

### 1.2 Triagem de E-mails do Usuário (pós-sincronia)
📄 `auth/views/contas_usuario_view.dart`
- Lista os e-mails associados ao CPF da conta Nous. Tocar em um e-mail define-o como `emailAtivo` da sessão e avança diretamente para Meus Perfis (`PerfisPdvView`).
- Inclui botão para adicionar novo e-mail (`AdicionarEmailDialog`) e ação de contingência para "Continuar sem e-mail".

### 1.3 Janela "Identidade do Usuário"
📄 `auth/views/widgets/ficha_usuario_dialog.dart` · subcomponentes: `bloco_dados_pessoais_usuario.dart`, `bloco_emails_usuario.dart`, `bloco_lojas_usuario.dart`, `linha_info_usuario.dart`
- Topo: **foto**, **apelido** e **nome próprio editável pelo titular** (alinhados e centralizados simetricamente com largura de 260px e ícone de privacidade perfeitamente integrado via `Stack`), **nome de usuário** (`@`) e **CPF** (protegido contra alteração).
- Bloco **Dados pessoais** (`BlocoDadosPessoaisUsuario`): data de nascimento, nome do pai, nome da mãe, local de nascimento, tipo sanguíneo, estado civil, telefones e redes sociais.
- Bloco **E-mails Associados** (`BlocoEmailsUsuario`): e-mails vinculados ao CPF e destaque para a credencial ativa da sessão.
- Bloco **Lojas e Coletivos** (`BlocoLojasUsuario`): histórico de lojas administradas e participadas com indicação do cargo e papel do membro.
- Botão **"Editar dados pessoais"**: fica visível no rodapé do bloco de dados pessoais. Ao clicar, o bloco vira editável com **Salvar** e **Cancelar**.
- **Blindagem em Dados Ocultos**: quando os dados estão borrados pelo botão do olho, qualquer clique, hover ou foco nos botões e campos internos é totalmente desabilitado com `IgnorePointer(ignoring: true)`, impedindo interação acidental.
- **Privacidade Granular e Ícone de Olho Interativo**:
  - **Para o próprio titular**: ao clicar no ícone de olho, o dado alterna entre revelado e censurado de forma permanente (persistido localmente até novo clique do usuário).
  - **Para terceiros**: o dado aparece censurado (`••••••••`) com ícone de olho fechado. Ao clicar no olho, abre-se um diálogo confirmando o envio de solicitação deliberativa de acesso ao titular via notificações.
  - **Fallback para Apelido**: quando o titular mantém o nome próprio/civil privado, seu apelido é exibido nos cartões, mesas e participantes, mantendo a opção de pedir permissão para visualizar o nome civil.
- **Modo somente leitura**: ao abrir a ficha de outra pessoa, nada é editável. Ao abrir a própria, o nome e dados pessoais são editáveis; o CPF é sempre fixo.
- A foto e os dados são os mesmos em qualquer aparelho do mesmo CPF (sincronização pela rede).
- Acessada a partir da tela **Conta Nous** (2.2.1), pelo card em **Configurações** (2.2) ou ao tocar num membro em **Usuários Participantes** (6.1).

### 1.4 Tela "Perfil Social do Usuário"
📄 `auth/views/perfil_social_view.dart` · acessada pelo segundo ícone (pessoinha) da barra inferior flutuante (`FloatingBottomNavBar`).
- Topo com engrenagem de **Configurações** (sem botão de voltar quando acessada pela barra inferior).
- Cabeçalho vertical centralizado: foto grande de avatar centralizada, `@username` identificador único centralizado, **Nome Completo em negrito** centralizado (ambos com `TextoRolante`) e métricas reais (**Posts**, **Seguidores**, **Seguindo**) sincronizadas do modelo `UsuarioNous`.
- Bloco **Biografia** com título e descrição.
- Botões de ação em linha com `TextoRolante`: **"Editar Perfil"** (abre a edição social), **"Seguir" / "Seguindo"** (quando visualizando perfil de terceiros, alternando status social e persistindo seguidores), **"Compartilhar"** (exibe e copia o nome de usuário Nous `@username`) e **"Mensagens"** (abre a Mensageria do Usuário).
- Carrossel horizontal de destaques circulares.
- Barra de abas com 4 ícones (Grade, Reels/Vídeo, Documento, Música) e grade de 3 colunas de publicações.
- Barra flutuante universal no rodapé com o segundo botão (pessoinha) ativo.

### 1.5 Barra de Navegação Universal Dupla
📄 `core/widgets/floating_bottom_nav_bar.dart` · visível no modo compacto para celular e fora de lojas no modo desktop expandido.
- **Transição Vertical Fluida:** A troca de telas pela barra universal utiliza `PageRouteBuilder` com animação suave de deslize vertical (`SlideTransition` em `Curves.easeOutCubic`) e esmaecimento (`FadeTransition`), simulando com leveza física a impressão de subida ou descida da tela.
- **Botões Duplos com Rolagem Vertical:** Cada um dos 5 botões da barra possui dois modos e pode ser rolado para cima ou para baixo (arraste com o dedo ou rodinha do mouse), alternando os ícones e os destinos com animação vertical suave:
  1. **Slot 0 (Compras / Lojas):**
     - Modo Carrinho (`shopping_cart`): abre a tela **Compras & Carteira** (`ComprasUsuarioView`), com os containers "Carteira Soberana", "Carrinho de Compras" e "Histórico de Compras" (com `TextoRolante` e aviso de em construção).
     - Modo Lojinha (`storefront`): abre a tela **Meus Perfis** (`PerfisPdvView`).
  2. **Slot 1 (Social / Comunicação):**
     - Modo Pessoinha (`person`): abre o **Perfil Social do Usuário** (`PerfilSocialView`).
     - Modo Mensagens (`chat_bubble`): abre diretamente a **Mensageria** do Usuário (`MensageriaView`).
  3. **Slot 2 (Busca / Player Universal):**
     - Modo Lupa (`search`): abre a tela soberana de **Busca & Mapa** (`BuscaMapaView`), com barra de pesquisa para localização regional de lojas e produtos, filtros rápidos ("Todos", "Lojas", "Perfis"), cards de visita e botões para seguir perfis cidadãos.
     - Modo Player (`play_circle`): Super motor e player integrado de vídeos, músicas e PDFs (em construção).
  4. **Slot 3 (Feeds):**
     - Modo Descoberta (`explore`): Feed público e memes da rede (em construção).
     - Modo Conexões (`people`): Feed de amigos e rede de confiança (em construção).
  5. **Slot 4 (Autogestão / Governança):**
     - Modo Autogestão (`hub`): Painel geral de assembleias e deliberações populares (em construção).
     - Modo Governança (`account_tree`): Ferramentas específicas de autogestão (em construção).
- **Sem Seta de Voltar Indesejada:** A navegação entre os módulos principais da barra não acumula histórico indevido e o `CustomAppBar` possui `automaticallyImplyLeading: false`, garantindo que nenhuma tela de raiz exiba seta de voltar.

### 1.6 Tela "Mensageria e Chats do Usuário / Loja"
📄 `chat/views/mensageria_view.dart` · controller: `chat/controllers/mensageria_controller.dart` · views: `chat/views/chamada_ativa_view.dart` · widgets: `lista_conversas_widget.dart`, `painel_conversa_ativa_widget.dart`, `balao_mensagem_widget.dart`, `item_conversa_tile.dart`, cards (`card_mensagem_audio.dart`, `card_mensagem_imagem.dart`, `card_mensagem_arquivo.dart`, `card_mensagem_comanda.dart`) · dialogs: `dialog_chamada_recebida.dart`, `dialog_nova_conversa.dart`, `dialog_criar_grupo.dart`, `dialog_detalhes_contato.dart`, `dialog_encaminhar_mensagem.dart`, `dialog_editar_mensagem.dart`, `dialog_historico_edicoes.dart`, `dialog_renomear_conversa.dart`, `dialog_compartilhar_comanda.dart` · services: `chamada_webrtc_service.dart`, `resolvedor_foto_chat.dart`
- **Chamadas de Voz e Vídeo P2P via WebRTC:**
  - **Botões na Barra Superior:** O cabeçalho de conversas privadas e grupos (`PainelConversaAtivaWidget`) exibe os botões de ligação por áudio (`phone`) e vídeo (`videocam`), permitindo discar diretamente na rede local. Excluídos estritamente do chat comunitário público da Loja Nós.
  - **Modal de Chamada Recebida (`DialogChamadaRecebida`):** Toca alerta sonoro contínuo, exibe avatar e nome de quem está ligando, identifica se é áudio ou vídeo, e oferece botões claros de atender ou recusar.
  - **Tela de Chamada Ativa (`ChamadaAtivaView`):** Janela imersiva com renderização de vídeo remoto em tela cheia e vídeo local em Picture-in-Picture (PIP) flutuante, cronômetro de tempo de chamada, controles para silenciar microfone, ligar/desligar câmera, alternar entre câmera frontal e traseira e ativar viva-voz.
- **Padrão Mercado e Abertura Instantânea no Final:** O chat abre diretamente na última mensagem enviada com rolagem invertida natural (`reverse: true`), ancorando instantaneamente na base sem saltos visuais.
- **Gravação e Reprodução de Mensagens de Voz (Estilo WhatsApp):**
  - **Barra de Gravação Interativa:** O botão de envio exibe o ícone de microfone (`mic`) quando o campo de texto está vazio; ao tocar, inicia a gravação de áudio (.m4a AAC LC 128kbps) e transforma a barra de envio em uma faixa com indicador pulsante, cronômetro de duração em tempo real (`0:05`), botão de descarte imediato (lixeira) e botão de envio direto.
  - **Player Integrado na Bolha:** As mensagens de áudio são renderizadas com um reprodutor nativo (`_PlayerMensagemAudio`), com botão circular de Play/Pause, barra de progresso ajustável com busca temporal (`SliderTheme`), contador de tempo e microfone colorido indicativo de voz.
  - **Menu de Anexos:** Opção "Mensagem de Voz" também disponível no modal de anexos ao lado de Fotos, Documentos e Comandas de Pedidos.
- **Envio Otimista em 0ms e Fila Offline (Outbox):** Mensagens enviadas entram imediatamente na interface; quando desconectado da rede, são salvas com status pendente e sincronizadas de forma autônoma assim que restabelecida a conexão local.
- **Ciclo Completo de Confirmação Visual:** Ícone de relógio cinza (pendente na fila local), 1 check cinza (enviada e registrada na rede), 2 checks cinzas (entregue ao aparelho receptor) e 2 checks azuis WhatsApp (`#34B7F1`) para mensagens lidas.
- **Barra Superior da Conversa (AppBar / Cabeçalho):** Exibe com clareza o avatar, nome do contato (com `TextoRolante` quando o nome ultrapassa o espaço em telas móveis) e subtítulo com status de presença e `@username`. Inclui botão compacto de renomear conversa, descartando o antigo botão de 3 pontos para dar espaço máximo à identificação do contato.
- **Janela de Detalhes do Contato / Grupo Estilo WhatsApp (`DialogDetalhesContato`):** Exibe foto do contato em destaque clicável para visualização em tela cheia com zoom (`InteractiveViewer`), frase de recado/biografia importada do perfil público Nous (`usuario.biografia`), ações rápidas compactas e proporcionais ("Compartilhar", "Renomear", "Minha Ficha na Loja" para estabelecimentos e "Ver Perfil Público" para cidadãos), interruptor `ThemedSwitch` para silenciar notificações da conversa, atalho para ver mensagens favoritadas e mídias compartilhadas.
- **Autoatendimento pelo Chat (Fazer Pedido e Ficha do Cliente):** Em conversas com estabelecimentos/lojas (`ehLoja`), o menu do clipe de anexos e os detalhes do perfil disponibilizam a opção **"Fazer Pedido"** (`DialogFazerPedidoChat`). Abre o cardápio interativo com navegação de categorias por chips, produtos cadastrados, seleção de acompanhamentos/componentes (`GrupoComponentesLoja`), sacola de compras com subtotal acumulado e observações. Ao confirmar, o pedido é despachado via WebSocket/REST com status `StatusPedido.novo` (caindo na aba "Novos" do balcão da loja para o operador dar sequência) e insere uma comanda interativa no chat.
- **Gestão Soberana de Ficha de Cliente na Loja (`DialogEditarFichaClienteLoja`):** Vinculação inteligente e profilática do cliente por CPF e telefone para prevenir duplicação de cadastros no PDV; o cliente pode visualizar e editar seus próprios dados de contato e endereço na ficha cadastral da loja sem acesso aos dados financeiros restritos ao comerciante.
- **Favoritar Mensagens:** Menu contextual da mensagem na bolha (`DialogMenuMensagem`) inclui opção para favoritar/desfavoritar. Mensagens com estrela exibem um ícone sutil de estrela no balão e podem ser visualizadas na íntegra através do diálogo `DialogMensagensFavoritadas`, acessível pelos detalhes do contato.
- **Silenciamento de Conversas e Menu Contextual Posicionado:** Ao pressionar e segurar uma conversa na lista (`LongPress`), um menu contextual abre exatamente sobre o card da conversa selecionada, permitindo Silenciar/Reativar notificações, Renomear, Fixar/Desafixar no topo e Arquivar. Conversas silenciadas exibem ícone discreto de mudo no card e têm sons e alertas suprimidos no `ChatService.deveNotificarConversa`.
- **Painel de Anexos no Clipe (Estilo WhatsApp):** Tocar no ícone de clipe abre grade estilizada com botões temáticos: "Fazer Pedido" (quando em chat de loja), "Galeria" (abrindo a galeria nativa de fotos via `ImagePicker`, onde cancelar retorna imediatamente ao chat sem acionar o Google Files), "Documento", "Contato" (abre seletor de contatos Nous para compartilhamento rápido da ficha), "Comanda" de pedido, e atalhos com badge "Em construção" para Localização, Enquete, PIX e Evento.
- **Isolamento Absoluto entre Conta Pessoal e Lojas:** Grupos e conversas da conta pessoal não vazam para o atendimento das lojas, e conversas de clientes da loja ficam restritas ao escopo da loja (`lojaId`). No Modo Loja, o contato (cliente ou equipe) mantém estritamente sua identidade e foto civil (CPF), mesmo quando for o próprio dono logado, impedindo que a logo comercial da loja sobrescreva o avatar da pessoa.
- **Sincronização Pan-Dispositivo com Tombstones:** O histórico de conversas e grupos é sincronizado integralmente entre o computador (balcão) e os dispositivos móveis (terminais); conversas e grupos excluídos no computador geram registro na tabela `conversas_excluidas` e não ressuscitam no celular, garantindo paridade absoluta. Fotos de contatos e anexos ausentes no dispositivo local são autobaixadas em tempo real.
- **Campo de Busca de Mensagens:** Input de pesquisa utiliza alinhamento nativo de `hintText` com padding balanceado, posicionando o cursor perfeitamente antes da primeira letra ("P" de "Pesquisar") e suporta busca insensível a acentuação.
- **Visualizador Universal de Imagens no Chat (`VisualizadorImagemChatDialog`):** Clicar em qualquer imagem enviada no chat (seja na mensageria pessoal, chat de loja ou chat comunitário) abre a foto em tela cheia com fundo translúcido, suporte a zoom e deslocamento (`InteractiveViewer`), botão de download direto para o sistema de arquivos (com seletor no desktop ou pasta padrão no mobile) e botão de encaminhar para qualquer contato/grupo aberto.
- **Saída Discreta de Grupos:** Ao optar por "Sair do grupo" no painel de detalhes da conversa, a aplicação não dispara notificações intrusivas para os demais membros; o sistema apenas insere no histórico da conversa uma mensagem discreta informando que o participante saiu.
- **Referencial Reativo de Presença no Cabeçalho do Chat:** Logo abaixo do nome do contato ou loja na conversa ativa, exibe um ponto indicador colorido e rótulo reativo em tempo real via WebSocket local: **ponto verde vibrante** (`#4CAF50`) com texto "Online" quando o usuário ou equipe da loja está ativa na rede local; **ponto suave/translúcido** com texto "Ausente" quando desconectado; para lojas, valida o expediente (`loja.aberta == true`), exibindo "Fechada" se a loja estiver inativa; para grupos, contabiliza automaticamente os membros ativos no momento.
- **Título da Conversa dentro do Chat:** Posicionado dentro da própria área de mensagens, centralizado e em destaque com ícone de edição. Ao tocar, abre o diálogo de renomear a conversa e persiste no banco SQLite e na malha da rede local.
- **Teclado no Android com Enter para Pular Linha:** O campo de texto do chat opera em modo multiline (`TextInputAction.newline`), permitindo pular linhas com o Enter do teclado virtual; o envio é acionado exclusivamente pelo botão circular "Enviar" da interface Nous.
- **Câmera Física Direta:** O botão de câmera na barra de digitação aciona diretamente a câmera nativa do celular (`ImagePicker` com `ImageSource.camera`) para fotografar e enviar fotos instantaneamente, com fallback para seletor em desktops sem câmera ativa.
- **Encaminhamento de Mensagens com Prévia e Miniaturas:** Menu contextual na bolha permite encaminhar mensagens para qualquer contato ou grupo com prévia visual da mídia/mensagem no topo do diálogo (`DialogEncaminharMensagem`) e avatares reais dos contatos, com tráfego WebSocket de até 512 KB eliminando demoras no envio.
- **Criação e Propagação de Grupos:** Criar um grupo despacha evento imediato na rede local (`grupo_criado`), abrindo o chat de grupo em tempo real para todos os membros nos outros aparelhos.
- **Navegação com Botão Voltar do Android:** Controlado por `PopScope`: ao pressionar o botão voltar do sistema operacional com uma conversa aberta, o app desmarca a conversa e retorna para a lista de conversas da mensageria (sem fechar a tela).
- **Destaque Permanente no Desktop:** A conversa selecionada no painel lateral esquerdo mantém o destaque de hover e borda temática ativo permanentemente enquanto estiver aberta.
- **Chat Universal da Comunidade Nous (Gestão do Perfil / Perfil Profissional):**
  - **Tópicos Paralelos Delimitados:** Barra superior de tópicos com chips ("Geral", tópicos adicionais e botões "+ Nova Sala" e "Explorar Salas"), permitindo conversas comunitárias setorizadas sem misturar assuntos.
  - **Explorador de Salas Comunitárias:** Diálogo para pesquisar todas as salas comunitárias criadas por outros membros com filtro insensível a acentos, entrar em salas abertas, sair de salas e apagar salas criadas pelo próprio usuário (sendo `#Geral` a única sala comunitária fixa).
  - **Preservação de Títulos de Salas:** Salas comunitárias criadas pelo celular mantêm com rigor o nome definido (ex: "Desenvolver") ao sincronizar com o computador ou outros nós locais.
  - **Título Editável Centralizado:** Nome do tópico em destaque no meio do espaço do chat, com ícone de edição para renomear em tempo real com broadcast via WebSocket.
  - **Sino de Notificação por Tópico:** Ícone interativo de sino permitindo ao usuário silenciar ou ativar notificações daquele tópico específico na sua conta Nous.
  - **Suíte Completa de Mídia:** Gravação de áudio nativo com timer e cancelamento, player de áudio na bolha com busca temporal, câmera, galeria com visualizador ampliado, documentos e menu contextual de mensagens (copiar, editar e excluir para todos em até 1 min).
  - **Persistência e Sincronização Pan-Dispositivo Imediata:** Conversas abertas no celular espelham em tempo real no computador e vice-versa na mesma rede local, permanecendo sempre visíveis após reiniciar a aplicação.

---

## 2. Barra superior e Configurações

### 2.1 Barra superior
📄 `core/widgets/custom_app_bar.dart`
- **Título** da tela, centralizado com `TextoRolante`. **Seta de voltar** travada via `automaticallyImplyLeading: false` (só aparece se `showBackButton: true`).
- Lado direito, nesta ordem:
  - **Sino (Notificações)**: abre 3. Mostra ponto de sinalização vermelho ou contador. Fora da loja: convites, avisos da conta e **novas mensagens não lidas do usuário**. Dentro da loja: alertas de estoque e mensagens exclusivas daquela loja.
  - **Atualizações**: aparece **somente** se houver versão nova. Abre `AtualizacaoDialog` (5.3).
  - **Engrenagem (Configurações)**: abre 2.2.
- **Não existe** botão de perfil nem botão fixo de Wi-Fi nesta barra.

### 2.2 Janela "Configurações"
📄 aberta a partir de `custom_app_bar.dart` · rolável com altura máxima de 85% da tela (o botão **Sair** sempre fica visível no celular).
- **Botão de Sincronização Wi-Fi** (`_BarraSincronizacaoWifiSettings`): barra com hover, acima da Identidade. Mostra "Servidor Ativo", "Conectado ao Balcão" ou "Desconectado" e abre a janela 4.1.
- **Card da conta Nous integrado**: container reunindo foto, nome civil, CPF formatado, e-mail ativo e o botão estilizado **"Conta Nous"** (abre a tela 2.2.1).
- **Personalizar Aparência**: abre `ThemeCustomizerDialog` (cores, fontes, tamanhos, cor de exclusão). O tema é salvo por CPF. 📄 `core/theme/theme_customizer_dialog.dart`
- **Sair**: faz logout, desconecta as redes locais e volta ao Login.

### 2.2.1 Tela "Conta Nous"
📄 `auth/views/conta_nous_view.dart` · submódulos modulares em `auth/views/widgets/conta_nous/` (`bloco_identidade_conta_widget.dart`, `bloco_privacidade_conta_widget.dart`, `bloco_emails_conta_widget.dart`, `bloco_seguranca_conta_widget.dart`) · acessada pelo botão "Conta Nous" em Configurações.
- Reúne os módulos soberanos da identidade e dos dados do cidadão:
  - **Identidade do Usuário**: foto de perfil, `@username` identificador único com diálogo de edição, apelido, nome civil e CPF formatado com alternância permanente de revelação no olho para o dono, com botão "Ver / Editar Identidade Completa" (abre `FichaUsuarioDialog` 1.3).
  - **Privacidade e Transparência dos Dados**: container com interruptores `ThemedSwitch` por campo (Nome Próprio / Nome Civil, CPF, data de nascimento, filiação, local de nascimento, tipo sanguíneo, estado civil, telefone e endereço). Permite tornar dados públicos ou privados para terceiros nas lojas e buscas. Exibe a lista de membros que receberam autorização de acesso a cada dado privado e botão para revogar a permissão individualmente a qualquer momento.
  - **E-mails Associados**: listagem de todos os e-mails associados ao CPF da conta com indicação do e-mail ativo da sessão e botão para adicionar novo e-mail (`AdicionarEmailDialog`).
  - **Backup Soberano dos Dados**: atalho seguro para exportação e importação do cofre de dados em arquivo JSON único.
  - **Excluir Conta Nous Definitivamente**: botão de ação destrutiva em cor de perigo (`theme.dangerColor`) que expurga os dados do SQLite, limpa o cache persistido (`_chaveUltimoCpf`) e redireciona ao login inicial.

### 2.3 Tela cheia (F11)
📄 `main.dart` (interceptador global) + `core/services/janela_windows_service.dart`
- **F11** alterna tela cheia do Windows em qualquer lugar do app (login, loja, qualquer janela aberta). Tecla fixa, não é configurável.
- Ao sair da tela cheia, se a janela estava maximizada ela volta maximizada; senão volta ao tamanho anterior.
- **Não** muda o layout compacto/expandido (isso é feito em "Ajustes do Perfil", 6.2).

---

## 3. Notificações

📄 `notif/views/widgets/notificacoes_dialog.dart` · widgets: `notif/views/widgets/cards/card_notificacao_estoque.dart`, `card_notificacao_chat.dart`, `card_notificacao_convite.dart` · services: `notif/services/gerenciador_acoes_notificacao.dart`, `notif/services/convites_service.dart` · `notif/providers/notificacoes_provider.dart`

- **Cabeçalho**: botão **"Limpar todas as notificações"** (ícone `clear_all`). Dispensa todas de uma vez (fora da loja: na sessão local via `dispensarTodasNaSessao`; dentro da loja: persiste localmente e sincroniza via WebSocket com todos os outros membros conectados na rede local via `dispensarNotificacoesLoja`), incluindo mensagens e alertas.
- **Arquitetura Modular de Cards**: cada notificação é renderizada por seu widget especializado com isolamento de estilo e responsividade (`CardNotificacaoEstoque`, `CardNotificacaoChat`, `CardNotificacaoConvite`), delegando confirmações e ações para o `GerenciadorAcoesNotificacao`.
- **Cada card** pode ser **arrastado para o lado** para dispensar (dentro de loja, a dispensa sincroniza imediatamente para todos os membros na rede local e persiste em disco).
- **Tipos de aviso**:
  - **Mensagens Recebidas**: foto do remetente, nome e texto com `TextoRolante`, data/hora. **Clicar na notificação**: fecha a janela e abre a conversa na Mensageria na hora.
  - **Solicitação de Acesso a Dado Privado (`solicitacaoDadoUsuario`)**: remetente solicita ver dado restrito (CPF, telefone, filiação...). Ao aceitar, autoriza deliberadamente o solicitante a visualizar o dado.
  - Convite para participar de uma loja (aceitar/recusar).
  - Alteração de papel de sócio (`alteracaoPapel`): "Solicitação de [Nome]: alteração do seu papel em [Loja] para [Novo Papel]". Aceitar aplica; recusar descarta.
  - Pedido de saída de dono (`solicitacaoExclusaoDono`): só se efetiva se o dono alvo aceitar.
  - Remoção da loja (`remocaoLoja`): "Você foi removido(a) da loja [Loja] por [Nome]".
  - **Alerta de estoque baixo/esgotado** (menos de 10 unidades ou ≤ 0): mostra loja, produto e saldo com unidade.
- **Tocar num alerta de estoque**: fecha a janela e abre `MovimentoEstoqueDialog` (7.12) com o item e o tipo "Entrada" já escolhidos, para repor na hora.
- **Isolamento e Sincronização Pan-Loja**: em "Meus Perfis" e fora de loja só aparecem convites, avisos de papel e mensagens do usuário. Dentro da loja, só avisos e mensagens daquela loja. Qualquer alerta ou notificação limpa por um integrante em qualquer aparelho conectado à rede local deixa de aparecer imediatamente para todos os demais aparelhos conectados.
- **Notificações nativas no Android**: `NotificacaoAndroidService` exibe notificações nativas no sistema operacional com estilo de mensagem e ação de resposta rápida ("Responder" direta na notificação estilo WhatsApp).

---

## 4. Rede Wi-Fi

### 4.1 Janela "Sincronização em Rede Wi-Fi"
📄 `pdv/views/widgets/sincronizacao_rede_dialog.dart` · submódulos de UI em `pdv/views/widgets/sincronizacao_rede/` (`aba_servidor_balcao_widget.dart`, `aba_terminal_movel_widget.dart`, `dialog_aprovar_conexao_terminal.dart`) · serviços em `pdv/services/rede_local/` (`servidor_rede_local.dart`, `manipulador_midia_servidor.dart`, `cliente_rede_local.dart`, `reconciliador_loja_rede.dart`, `sincronizador_usuarios_rede.dart`, `transferencia_arquivos_rede.dart`)
- Abre pelo botão em **Configurações** (2.2), no primeiro item de **Ajustes do Perfil** (6.2) ou pós-login.
- Topo: ficha do operador ativo (foto, nome, `@apelido`, CPF).
- Duas abas: **Servidor Balcão** e **Terminal Móvel**.
  - **Servidor Balcão**: liga o computador como servidor (porta 8080). A máquina balcão reflete o CPF e nome do operador ativo no momento. Lista os terminais conectados/pareados com tipo de conexão (Membro / Cliente), nome do aparelho, operador, CPF protegido e IP. Exibe também uma lista de **Dispositivos Não Pareados** encontrados na rede local com botão para autorizar/parear diretamente.
  - **Terminal Móvel**: o celular lista automaticamente os balcões achados na rede (botão **Conectar**) ou conecta por IP e porta manualmente. O computador que é servidor **não pode** se conectar a si mesmo. Quando conectado a um servidor (seja Loja ou Modo Usuário Nous), exibe status, endereço do host, botão de desconectar e a **Lista de Usuários Conectados na Rede no Nous** com badge de contagem centralizado acima da lista, campo de pesquisa em tempo real (filtra por nome, `@username` ou CPF com botão de limpar), avatares reais, horários de conexão com `TextoRolante` e atalho para abrir a `FichaUsuarioDialog`.
- **Aprovação Obrigatória com Seletor Cliente vs Membro**: quando um terminal tenta se conectar, o balcão exibe diálogo interativo com som de alerta, detalhes do dispositivo e um seletor para aprovação:
  - **Cliente**: conecta o aparelho exclusivamente como cliente consumidor da loja (cadastrado em clientes, sem permissões de membro/gestão, pronto para auto-atendimento de pedidos).
  - **Novo Membro da Loja**: autoriza o aparelho como membro operacional participante da loja.
  - Botão **Recusar** (ou expiração por timeout de 30s) rejeita com 403.
- **Reconexão Automática na Retomada (Ciclo de Vida):** No Android e iOS, ao destravar o celular ou voltar ao aplicativo em primeiro plano, o `ClienteRedeLocal` valida a conexão WebSocket e reconecta ao balcão memorizado instantaneamente em segundo plano.
- **Compressão Nativa de Imagens:** Fotos de câmeras de celular (8 a 12 MB) e uploads são redimensionados para até 1200px e otimizados abaixo de 250 KB (`ImagemService.otimizarBytesImagem`), prevenindo estouro de memória RAM e lentidão na rede local.
- Funcionamento interno: `docs/rede-local.md`.

---

## 5. Meus Perfis e criação de loja

### 5.1 Tela "Meus Perfis"
📄 `pdv/views/perfis_pdv_view.dart`
- Duas listas: **"Perfis que eu administro"** (Administra) e **"Perfis que eu participo"** (Participa). No desktop, em grade de 2 colunas.
- **Logos das Lojas e Assets Embutidos:** Cada card exibe a logo real da loja (com resolução automática para fotos em disco locais ou assets embutidos do app como no Perfil Nous).
- **Sincronização Mútua Pan-Dispositivo:** Ao conectar na rede local Wi-Fi, todas as lojas participadas e administradas (incluindo lojas móveis como marmitarias) sobem seus arquivos de mídia e logos fisicamente para o balcão via `_prepararLojaComUploadsParaServidor` e consolidam no SQLite sem perda de fotos.
- **Perfil Profissional Coletivo "Nous":** Sempre listado em **"Perfis que eu participo"**. Todo usuário Nous cadastrado é membro sócio deliberativo desta organização soberana voltada à governança e autogestão da aplicação, contendo chat geral da comunidade.
- Mostra as **mesmas lojas em qualquer aparelho do mesmo CPF** (fusão automática pela rede).
- A loja do próprio dono nunca aparece duplicada.
- **Sino**: só avisos da conta (convites, papéis), sem avisos de lojas.
- Tocar numa loja entra nela (6).

### 5.2 Criar perfil / loja
📄 `pdv/views/widgets/criar_perfil_dialog.dart` · `pdv/views/cadastrar_loja_view.dart` (a confirmar a divisão entre os dois)
- Escolha de categoria: **Loja Padrão** (varejo, venda direta), **Restaurante** (cardápio, adicionais, mesas e comandas), **Fretes e Viagens** (transporte e entregas).
- Importar um backup **mescla** sem duplicar loja com o mesmo CNPJ (5.4).

### 5.3 Janela de Atualização
📄 `core/widgets/atualizacao_dialog.dart` · `core/services/atualizacao_service.dart`
- Mostra a versão instalada e a disponível. Se for a mesma versão, o botão sai da barra.
- Container **"Nova Atualização"**: exibe as **"Alterações"** da nova versão disponível (transmitidas diretamente via Wi-Fi pelo balcão ou catálogo offline) com botão de **minimizar/maximizar** para consulta das novidades pelo usuário.
- No celular com versão nova no balcão: **baixa o APK dentro do app com barra de progresso** e abre o instalador do Android.
- Fonte local (balcão) tem prioridade sobre a internet.

### 5.4 Backup
📄 `pdv/views/widgets/backup_dialog.dart` · `pdv/services/backup_service.dart`
- **Exportar**: salva contas, lojas, referências e convites num único `.json`.
- **Importar → Substituir**: zera o banco local e aplica o arquivo. **Importar → Mesclar**: junta com o que existe, sem apagar nada local.
- Backup automático diário e silencioso em `%APPDATA%\Nous\backups\backup_nous_AAAA-MM-DD.json` (até 30 cópias).
- Depois de importar, as telas atualizam sozinhas, sem reiniciar.

---

## 6. Tela da Loja (`DadosPerfilView`)

📄 `pdv/views/dados_perfil_view.dart` (< 450 linhas, altamente modular).
Controladores e componentes modulares especialistas:
- `widgets/loja/dados_perfil_loja_controller.dart`: orquestrador de estado reativo, controladores e ciclo de vida.
- `widgets/loja/layout_principal_loja_widget.dart`: gerencia atalhos de teclado (F1-F12), alternância Desktop Expandido / Balcão / Compacto.
- `widgets/loja/seletor_conteudo_abas_loja_widget.dart`: renderizador de abas isolado (Dados, Loja, Gestão, Ajustes).
- `widgets/loja/gerenciador_dialogs_loja.dart`: central de roteamento de diálogos, popups e confirmações operacionais.
- `widgets/loja/gerenciador_clientes_fornecedores_loja.dart`: regras de negócio e persistência de clientes e fornecedores.
- `widgets/loja/persistencia_loja_helper.dart`: sincronização e difusão na rede local Wi-Fi.
- `widgets/loja/gerenciador_catalogo_loja.dart`, `widgets/loja/gerenciador_pedidos_loja.dart`, `widgets/mesas/gerenciador_mesas_loja.dart`, `widgets/loja/gerenciador_membros_loja.dart`, `widgets/loja/gerenciador_anexos_loja.dart`.

Quatro abas (`AbaLoja`): **Dados**, **Ajustes do Perfil**, **Loja / Catálogo** e **Gestão de Pedidos**.
*(Exceção soberana: no Perfil Profissional Coletivo **Nous**, existem apenas duas abas: **Dados** e **Gestão**, sem botões de salvar, excluir ou sair).*

**Layout compacto (celular, ou desktop em modo compacto)**: as abas ficam numa navegação inferior/superior, coluna única.
**Layout desktop expandido**: aparece a **barra lateral fixa** à esquerda (6.0) e as janelas ficam mais largas, em duas colunas.

Esta tela atualiza **em tempo real** quando muda algo no balcão ou em outro celular: pedidos, estoque, produtos, categorias, grupos, clientes, fornecedores, mesas, membros, papéis, anexos (músicas, galeria, vídeos, arquivos), dados cadastrais e status Aberta/Fechada.

### 6.A Particularidades da Loja Coletiva Nous (`idLojaColetivaNous`)
- **Abas Restritas**: Apenas **Dados** e **Gestão** (as abas Ajustes e Loja/Catálogo são removidas).
- **Dados Institucionais Fixos**: Exibição da logo oficial (`assets/images/logo.png`) e dados fixos apenas de leitura (Nome: *Nous*, Email: *nousstudios72@gmail.com*, Redes Sociais: *@nous.studios72*, Categorias: *Autogestão, Comunidade, Software Livre*, Descrição: *Software Universal de Autogestão Comercial e Social*). Sem botões de "Salvar Dados" ou "Excluir Loja". Os usuários podem enviar fotos, vídeos e arquivos para as galerias normalmente.
- **Cargos e Permissões**: Apenas duas abas: **Sócio** e **Desenvolvedor**. A função de Desenvolvedor é voluntariamente requisitada com o botão "Se tornar Desenvolvedor" / "Deixar de ser um desenvolvedor". No container "Usuários Participantes", o membro desenvolvedor recebe o rótulo `Sócio • Desenvolvedor`.
- **Aba Gestão Modularizada**: 📄 `aba_gestao_nous_widget.dart` (< 790 linhas) composto por:
  - `widgets/gestao_nous/dialogs_topicos_gestao.dart`: criação, exclusão, renomeação e saída de salas.
  - `widgets/gestao_nous/barra_envio_mensagem_gestao.dart`: input de texto, áudio com timer e anexos.
  - `widgets/gestao_nous/bolha_mensagem_gestao.dart`: bolhas, menus de contexto e ações de mensagens.
  - `widgets/gestao_nous/barra_topicos_comunitarios_widget.dart`: navegação horizontal entre salas comunitárias.
  - `widgets/gestao_nous/cabecalho_chat_gestao_widget.dart`: cabeçalho centralizado com sino e ações da sala.
  - `widgets/gestao_nous/card_audio_mensagem_gestao.dart` e `dialogs/dialog_explorar_salas_comunitarias.dart`.
- **Proibição de Saída**: Nenhum usuário pode sair da loja coletiva Nous nem ser excluído por terceiros. Sincronização automática na rede Wi-Fi ao conectar em qualquer loja.

### 6.0 Barra lateral (só no desktop expandido)
📄 `pdv/views/widgets/desktop_sidebar_widget.dart`
- Topo: **logo da loja**, nome e indicador de caixa **aberto/fechado**.
- Ordem dos módulos: **1. Dados da Loja → 2. Ajustes do Perfil → 3. Loja / Catálogo → 4. Gestão de Pedidos**.
- Comandos rápidos: Nova Venda, Clientes, Mensagens (com ponto de atenção vermelho se houver nova mensagem), Caixa, Relatórios, Impressora, Financeiro, Status da Loja, **Modo Balcão** (abaixo de Status da Loja).
  - Cada botão mostra um selo com a tecla configurada (ex.: `F1`). Se a função está **Desativada**, mostra só um quadradinho vazio (22×18 px), para manter o alinhamento.
  - Clicar com o mouse sempre executa a ação, tenha ou não tecla.
- Quando esta barra está ativa, os botões de ação do topo da Gestão ficam **ocultos** (seriam repetidos). No layout compacto eles aparecem.

### 6.1 Aba "Dados"
Containers, de cima para baixo:
1. **Formulário de Dados da Loja** 📄 `pdv/views/widgets/formulario_dados_loja.dart`: nome, documento (CNPJ), logo, contatos etc.
2. **Cargos e Permissões (estilo Discord)** 📄 `pdv/views/widgets/cargos_permissoes_container.dart` · subcomponentes: `pdv/views/widgets/cargos/` (`dialogs_gerenciar_cargo.dart`, `painel_coletivo_nous_widget.dart`, `card_permissao_loja_widget.dart`)
   - Começa **minimizado**; clique expande/recolhe.
   - Abas: **Dono, Sócio, Administrador, Funcionário** e cargos criados em **"+ Novo Cargo"**.
   - Lista todas as permissões, cada uma com explicação e interruptor.
   - **Dono e Sócio**: interruptores travados com o aviso "Regra fundamental do sistema (inalterável)".
   - Dono e Sócio podem alterar livremente as permissões de Administrador, Funcionário e cargos criados (salvo em `Loja.permissoesCargosNativos`; se não houver, valem os padrões `Loja.permissoesPadraoPorPapel`).
   - Se a permissão **"Gerenciar Membros e Cargos"** for dada a Administrador/Funcionário, eles passam a poder alterar papéis de outros membros (nunca de Dono ou Sócio).
3. **Usuários Participantes** 📄 `pdv/views/widgets/usuarios_participantes_container.dart` · subcomponentes: `pdv/views/widgets/usuarios/` (`dialog_convite_membro_loja.dart`, `dialog_troca_papel_membro.dart`, `card_membro_loja_widget.dart`, `dialog_central_contrato_trabalhador.dart`, `barra_trabalhador_widget.dart`)
   - Cada membro é uma **barra com foto, nome e hover** com **layout responsivo adaptável**: no modo celular (`maxWidth < 560px`), a linha superior exibe foto, nome soberano completo e cargo/CPF com legibilidade total sem corte, enquanto os botões de ação descem para uma segunda linha alinhada à direita com espaçamentos compactos; no desktop, permanecem em linha única. A foto vem pelo CPF (`auth.buscarFotoPorCpf` e, se faltar, `pdv.buscarFotoClientePorCpf`).
   - **Clicar no card do membro**: abre a **Identidade do Usuário** (`FichaUsuarioDialog`) respeitando as permissões de privacidade configuradas pelo cidadão.
   - **Ações contextuais na barra**:
     - **Botão de Mensagem Direta**: inicia conversa via Conta Nous no chat da loja.
     - **Botão Contrato e Trabalho**: abre a modal soberana `CentralContratoTrabalhadorDialog` contendo:
       1. *Histórico financeiro completo* repassado pela empresa (total recebido, pendências e lista de pagamentos).
       2. *Módulo de Contrato de Trabalho* com tipo de contrato, valor base, forma de pagamento padrão, observações e upload/anexo de arquivos interativos (PDF, imagens, documentos via `file_selector`).
       3. *Registro de ponto eletrônico* (entrada/saída com duração calculada e botão de bater ponto).
       4. *Escala semanal de rotação de funcionários* (dias trabalhados e horários de entrada/saída).
       5. *Ficha Soberana de Identidade do Usuário*.
     - **Botão Trocar Papel**: permite escolher papel operacional e vincular um **cargo** criado.
     - **Botão Excluir / Sair**: Dono exclui Sócio, Admin e Funcionário; Sócio exclui Admin e Funcionário; Admin e Funcionário não excluem ninguém. Dono não exclui Dono: envia pedido de saída. Quem é removido recebe aviso. Qualquer um pode **sair** por conta própria. Botão de excluir em vermelho, com confirmação.
   - **Alterar papel de um Sócio**: não aplica na hora. Envia notificação e só muda se o sócio aceitar.
   - Convidar: `_ConviteDialog` mostra a foto da conta encontrada pelo CPF.
4. **Tempo de Conclusão dos Pedidos**: título centralizado; escolhe "Manual" ou 15/30/45/60 min etc. Com tempo definido, pedido **Aceito** que passar do prazo dispara a pergunta "O Pedido #N já foi concluído?" (Ainda não / Sim, concluir pedido).
5. **Galeria / Anexos** 📄 `pdv/views/widgets/galeria_estilo_container.dart` · pasta `pdv/views/widgets/midia/`
   - Cards de 156×126 px com prévia por tipo: áudio com capa de álbum (ou gradiente com selo `.MP3`), imagem, vídeo, documento (selo `PDF`/`DOCX` e tamanho).
   - **Imagem**: abre `VisualizadorGaleriaDialog` em tela cheia, com zoom, setas (tela e teclado ← →), contador e legenda.
   - **Áudio, vídeo, documento**: abre `DetalhesMidiaDialog` com contador `X / Total`, setas laterais, teclado ← → e **autoplay** da próxima faixa (se não estiver em loop). No celular conectado ao balcão, áudios e músicas são baixados automaticamente via rede local e reproduzidos normalmente.
   - **Legendas**: editáveis a qualquer momento (`editar_descricao_dialog.dart`), salvas em `Loja.descricoesAnexos`.
   - Remover foto/anexo pelo "X" pede confirmação ("Tem certeza de que deseja retirar esta imagem?").
   - Recortar foto: `AjustarImagemDialog` (zoom, +/−/reset, salva PNG).
6. **Arquivos de Áudio** e **Sons e Alertas do Sistema** (abaixo): 9 efeitos nativos, teste imediato, e escolha por evento: *Novo Pedido Recebido*, *Tempo Limite / Alerta de Pedido*, *Bip de Leitura na Venda*. Cada evento aceita Bip Padrão, Silencioso ou qualquer áudio anexado.

> Containers de **Delivery** (`delivery_container.dart`) e **Dados Bancários** (`dados_bancarios_container.dart`) existem como arquivos, mas estão **desacoplados** desta versão. (a confirmar se ainda são usados em alguma tela)

### 6.2 Aba "Ajustes do Perfil"
Primeiro item: botão de **Sincronização em Rede Wi-Fi** (abre 4.1). Depois:
1. **Modo de Visualização e Layout do PDV** 📄 `pdv/views/widgets/seletor_layouts_desktop_widget.dart`
   - **Desktop**: alterna entre **Layout Desktop PDV Expandido** (barra lateral + colunas duplas) e **Layout Compacto Padrão**. É preferência da máquina, sempre disponível, sem exigir ser dono.
   - **Celular**: ocultado no celular em modo compacto sem teclado físico conectado; se houver teclado físico ou no desktop, o container fica visível.
   - Não mexe na tela cheia (F11).
2. **Comandos** (atalhos de teclado)
   - Duas colunas lado a lado: **F1–F6** e **F7–F12**. No celular, 1 coluna.
   - Todas as teclas nascem **Desativadas**; o usuário escolhe. Salvo em `Loja.atalhosTeclado`.
   - **F11 é fixa** ("Tela Cheia (Padrão do Sistema)", com selo "Fixo"). **Esc** é fixa no topo ("Voltar / Fechar Janelas").
   - **Quando aparece**: some no **modo compacto em celular** (Android/iOS sem teclado físico). Aparece no Windows, mesmo em modo compacto, e quando um teclado físico é detectado.
3. **Tempo de Conclusão dos Pedidos** e **Sons e Alertas do Sistema**: ver 6.1 (itens 4 e 6, quando exibidos aqui). (a confirmar em qual aba cada um está)
4. **Financeiro do Perfil**: botão **Resetar Transações** (confirmação em vermelho). Apaga vendas, turnos de caixa e pagamentos a trabalhadores; **mantém** produtos, clientes, membros e o saldo físico de estoque. Só Dono, Sócio ou quem tiver a permissão `resetarTransacoes`.
5. **Somente leitura**: quem não é Dono/Sócio vê um **banner com cadeado** e os seletores ficam esmaecidos (opacidade 0,65) e bloqueados.

### 6.3 Aba "Loja / Catálogo"
📄 partes: `categoria_loja_container.dart`, `grupo_componentes_loja_container.dart` (e `grupo_componentes_container.dart`, a confirmar qual está em uso), `produto_loja_row.dart`, `componente_loja_row.dart`, `item_loja_card.dart`, `estoque_container.dart`
- **Categorias** e **Grupos de Componentes**: lista vertical com barras padronizadas (foto/ícone 32×32 à esquerda com resolução de imagem local, nome com `TextoRolante` alinhado à esquerda com espaço priorizado, pílula de preço `R$`, interruptor compacto 28×16, chevron e menu de 3 opções).
- **Barras filhas (Itens/Produtos)** (`ProdutoLojaRow`): seguem a mesma identidade e proporção da barra pai (foto 32×32 do item, nome com `TextoRolante`, pílula arredondada de preço `R$`, switch de ativo/inativo, expansão e menu de 3 pontos com "Editar Item" e "Excluir Produto").
- **Janela "Editar Item / Novo Item"** (`NovoItemDialog`): campos de seleção ("Categorias do item" e "Grupos de componentes"), resumo da descrição e cálculos de custo/margem usam `TextoRolante` para leitura integral; botões de criação rápida possuem apenas um sinal `+` e lista de seleção múltipla com `TextoRolante` impedindo quebra de linha.
- **Reordenar**: segurar **1 segundo** em um card/barra e arrastar; ele flutua, abre espaço e encaixa ao soltar (ordem salva na hora). Só quem tem `possoEditarAbaLoja`.
- **Altura das listas**: no desktop, até ~7–8 barras antes de rolar (altura máx. 440); no celular, 180.
- **Card de produto** (`ItemLojaCard`): foto, badge de saldo (`Est: X`, com kg/L automáticos) ou **"Esgotado"** em vermelho.
- **Estoque**: tocar num item abre a **Ficha Kardex** (preço de venda e custo, estoque mínimo, código de barras, saldo e histórico cronológico).
- Botões típicos: Novo Item, Nova Categoria, Novo Grupo (rótulo curto "Novo Grupo" em telas estreitas).

### 6.4 Aba "Gestão de Pedidos"
📄 `pdv/views/widgets/gestao_loja_container.dart`
- Botões de ação no topo (somem no desktop expandido): **Nova Venda, Clientes, Mensagens, Impressora, Relatórios, Caixa, Financeiro, Status da Loja**. O botão "Mensagens" exibe um ponto de atenção vermelho quando há mensagens não lidas para a loja. Tocar em "Mensagens" abre a interface de mensageria da loja. Em tela < 520 px ficam em 2×2.
- **Abas de pedidos**: **Novos, Aceitos, Concluídos, Cancelados**. Lista com ~380 px de altura no desktop. Todas as abas exibem os pedidos em ordem decrescente (**mais recentes primeiro no topo**, ordenados por data/hora e número). Abas Concluídos e Cancelados contam com **campo de busca** (por #0001, cliente, produto).
- **Sincronização em tempo real na rede local**: qualquer mudança de status (aceitar, concluir, cancelar ou adicionar observação) feita no celular ou balcão reflete imediatamente em todos os aparelhos conectados sem recarregar a tela; a comparação de pedidos na interface detecta alterações profundas de status e valores.
- **Novos**: exibe estritamente os pedidos com status `novo` **gerados na data de hoje** (com expurgo profilático e cancelamento silencioso de pedidos zumbis pendentes de dias anteriores ao abrir a loja). Tocar num pedido abre a comanda com **Recusar / Imprimir / Aceitar**. A ação de **Recusar** cancela soberanamente o pedido (`StatusPedido.cancelado`) com motivo registrado e difusão em rede local, garantindo que o pedido não seja cobrado no saldo devedor do cliente e não renasça na aba de novos pedidos. Pedidos programados do dia entram aqui sozinhos pelo nó balcão com ID determinístico, blindados contra regeneração duplicada no mesmo dia e protegidos contra ressuscitação de pedidos zumbis ao reconectar aparelhos móveis à rede local.
- **Ao entrar no app**: se houver pedidos Novos, toca o alerta sonoro e abre a comanda do primeiro; **Aceitar/Recusar** passa para o próximo; o **X** interrompe a fila sem perder nada.
- **Aceitos**: tocar abre `PedidoAceitoDialog`, com botão de **impressora** (reimprime a comanda sem concluir), **Cancelar Pedido** e **Concluir**.
- **Cancelados**: tocar abre `PedidoCanceladoDetalhesDialog` (quem cancelou, quando, motivo, se houve estorno).
- **Mesas** (só perfil Restaurante): container retrátil **"Mesas"** entre os botões e o painel de pedidos (ver 7.8).
- Avisos de pedidos programados do dia também abrem aqui ao entrar (`PedidosProgramadosDialog`).

---

## 7. Janelas de trabalho do PDV

Todas abrem centralizadas, aceitam **F11** e, no desktop expandido, ficam em **duas colunas** (~1050 px).

### 7.1 Nova Venda
📄 `nova_venda_dialog.dart` · subwidgets modulares: `widgets/nova_venda/nova_venda_controller.dart`, `widgets/nova_venda/cliente_seletor_nova_venda_widget.dart`, `widgets/nova_venda/bloco_produtos_nova_venda_widget.dart`, `widgets/nova_venda/comanda_resumo_nova_venda_widget.dart`, `widgets/nova_venda/pagamento_nova_venda_widget.dart`, `widgets/nova_venda/botao_hover_forma.dart`
- **Layout Adaptativo e Responsivo (Desktop Sem Rolagem)**: no modo desktop/notebook, distribui dinamicamente os containers em 2 colunas simétricas:
  - **Coluna da Esquerda**: Nome do Cliente, Produto Solicitado, Frete / Desconto / Acréscimo.
  - **Coluna da Direita**: Comanda totalmente visível por padrão (sem corte inferior prematuro e com altura ampliada até 520 px), com o container de **Formas de Pagamento** posicionado diretamente abaixo da comanda e o botão **Concluir Venda** na base, permitindo finalizar a venda inteira diretamente por cliques sem necessidade de rolagem vertical prévia da tela. Em telas < 780 px, o layout se reorganiza fluidamente em coluna única.
- **Estado inicial limpo e busca instantânea.** Campo de busca em branco com foco → mostra **só as categorias**. Produtos soltos aparecem imediatamente a cada tecla digitada ou bipada (busca insensível a acentuação).
- **Nome do Cliente**: com foco e vazio, lista os clientes com virtualização (`ListView.builder`); filtra instantaneamente a cada tecla digitada ignorando acentos (nome, rua, número, CPF/CNPJ, telefone, e-mail, redes, descrição).
  - **Exibição completa na barra do cliente (Endereço + Telefone + Dívida)**: na lista de sugestões e no card de cliente selecionado, a barra exibe simultaneamente o **Endereço completo** (rua + número) e o **Telefone** (`Rua X, 123 • (11) 99999-0000`), além de um selo vermelho (`Deve R$ XX,XX` em `theme.dangerColor`) caso o cliente possua saldo em aberto de vendas À Prazo.
- **Leitor de código de barras**: digitar/bipar o código exato + Enter adiciona ao carrinho e limpa o campo.
- **Variantes**: ao escolher produto com variantes, abre seletor (Padrão + variantes com preço).
- **Frete, Desconto, Acréscimo**: aceitam R$ ou `%` (ex.: `10%`). Ao tocar, o valor inteiro fica selecionado. Em telas estreitas, quebra em linhas separadas para evitar qualquer estouro visual. Ao selecionar um cliente com taxa de frete cadastrada, o valor do frete é preenchido automaticamente na comanda.
- **Pagamento**: Dinheiro, Pix, Débito, Crédito, Voucher, À Prazo; pode combinar várias formas. Troco = excesso real sobre o total.
- **Rascunho**: se a janela for fechada sem querer (Esc, voltar, clique fora), tudo é guardado e volta ao reabrir. Botão **lixeira** "Limpar campos da venda". Venda concluída limpa o rascunho.
- Cada item mostra saldo (`Est: X un`) ou "Esgotado".
- Cadastro rápido de produto aqui com estoque inicial gera o movimento de estoque automaticamente.
- Ao concluir: **VendaConcluidaDialog** (cupom). Protegido: sair pede para salvar ou descartar; tem **Voltar** e **"Voltar para edição"**.

### 7.2 Modo Balcão (frente de caixa)
📄 `modo_balcao_widget.dart` · submódulos modulares em `pdv/views/widgets/modo_balcao/` (`barra_superior_balcao_widget.dart`, `campo_bipador_balcao_widget.dart`, `catalogo_balcao_widget.dart`, `visor_ultimo_produto_widget.dart`, `cliente_ajustes_balcao_widget.dart`, `comanda_balcao_widget.dart`, `dialogo_variante_balcao.dart`, `dialogo_componentes_balcao.dart`) · abre pela barra lateral ("Modo Balcão") ou pelo botão equivalente; **Esc** volta.
- **Esquerda (Operador)**: campo de bipador sempre focado; visor do último produto (foto, quantidade, nome, valor); catálogo por categorias com badges de saldo; busca de cliente com painel flutuante (avatar, CPF/CNPJ, telefone, endereço e selo vermelho **`Deve R$ XX,XX`** se houver débito em aberto) e chip do cliente selecionado com selo de dívida e botão de desvincular.
- **Direita (Comanda ampliada)**: cada item com nome completo (categoria e variante), preço, **+ / − / remover**, resumo dos adicionais, observação em itálico (`Obs: ...`) e botões **+ Componentes** e **+ Observação / Editar Obs**.
- Campos **Frete** (acima de **Acrésc:**, preenchido automaticamente ao selecionar cliente com frete cadastrado), **Desconto**, **Acréscimo**; **TOTAL GERAL** gigante; formas de pagamento (Dinheiro, Pix, Débito, Crédito, Voucher, À Prazo) com valor recebido e **troco em verde**.
- **FINALIZAR VENDA (ENTER)**: baixa estoque (item principal e acompanhamentos via `EstoqueBaixaService`) e abre o cupom.
- **À Prazo** exige cliente: sem cliente, abre a busca; finalizar sem cliente é bloqueado. Se o cliente for desmarcado, volta para "Dinheiro".
- Venda avulsa em "Todos" cobra o preço puro do item; o preço da categoria só soma se a categoria estiver selecionada.

### 7.3 Clientes
📄 `clientes_dialog.dart` · submódulos modulares em `pdv/views/widgets/clientes/` (`painel_lista_clientes_widget.dart`, `lista_pesquisa_clientes_widget.dart`, `formulario_cadastro_cliente_widget.dart`, `dialog_acoes_cliente.dart`, `dialog_quitacao_debito_cliente.dart`)
- Lista com **busca insensível a acentuação** e formulário de cadastro; cada barra de cliente exibe nome, **endereço + telefone** e selo vermelho **`Deve R$ XX,XX`** (`theme.dangerColor`) quando o cliente possui débitos em aberto.
- **Nome do Cliente e Endereço**: formatado automaticamente com `PrimeiraLetraMaiusculaFormatter` (a primeira letra de cada palavra digitada é convertida automaticamente em maiúscula em tempo real, permitindo minúsculas intencionais caso o usuário apague e digite em minúsculo).
- Campo **"CNPJ ou CPF"** com máscara automática (até 11 dígitos = CPF, 12 a 14 = CNPJ).
- **Autopreenchimento**: ao completar o documento, busca em contas Nous, lojas e cadastros prévios e preenche nome, telefone, endereço, e-mail, redes e foto.
- Altura da lista de clientes: 490 px no desktop expandido; 200 px no compacto.
- Ao tocar num cliente: valor total já gasto, container **"Frete"** (definição da taxa de entrega padrão do cliente com aplicação automática na comanda de vendas), container **"A Prazo"** (quitação de débitos), **Histórico de Compras** (organizado em dois níveis visuais limpos: linha superior com filtros de datas pré-definidas e formas de pagamento com botão de limpar, e linha inferior com os campos de data por input `De: DD/MM/AAAA` e `Até: DD/MM/AAAA` com navegação por setas e date picker; botão **Exportar Extrato PDF** refletindo exatamente os filtros aplicados), **Programar Pedido** (📄 `programar_pedido_dialog.dart` com `dialogs/dialog_digitar_horario.dart` e `widgets/programar_pedido/calendario_programacao_widget.dart`), **Pedidos Programados** (ver, pausar/ativar, excluir) e quitação.
- **Quitar valor / Quitar tudo**: abre confirmação mostrando cliente, valor, dívida atual e saldo restante. Escolhe a forma (Dinheiro, Pix, Cartão). Se for dinheiro e o caixa estiver aberto, registra um **suprimento** no turno.
- **Excluir Cliente**: em vermelho, com confirmação; avisa se houver débito a prazo. O histórico de pedidos é preservado.

### 7.4 Fornecedores
📄 `fornecedores_dialog.dart` — lista e clientes vinculados à esquerda; cadastro à direita. Busca multicampo. Excluir em vermelho com confirmação. Opção "usar cliente como fornecedor" mostra a foto do cliente.

### 7.5 Caixa do Balcão
📄 `caixa_dialog.dart` · `detalhes_turno_caixa_dialog.dart` · subwidgets modulares em `pdv/views/widgets/caixa/` (`painel_abertura_turno.dart`, `painel_turno_aberto.dart`, `painel_historico_turnos.dart`, `bloco_movimentacoes_turno.dart`, `painel_lancamento_movimento.dart`, `painel_fechamento_turno.dart`, `card_operacional_turno.dart`, `card_resumo_financeiro_turno.dart`, `barra_turno_item.dart`, `card_movimento_turno.dart`, `card_venda_turno.dart`)
- **Caixa fechado**: formulário de **abertura** (`PainelAberturaTurno`: fundo de troco, responsável) e lista **"Últimos Turnos Fechados"** (`PainelHistoricoTurnos`).
  - Cada barra tem hover, seta e dica; **clicar** abre `DetalhesTurnoCaixaDialog` (< 760 linhas, decomposto com `CardOperacionalTurno` e `CardResumoFinanceiroTurno`); o botão de **impressora** reimprime o fechamento sem abrir detalhes.
- **Caixa aberto**: **Suprimento** (entrada) e **Sangria** (saída) via `PainelLancamentoMovimento`, ambos com justificativa obrigatória e botões **Confirmar** / **Confirmar e Imprimir** (comprovante com linha de assinatura). Histórico do turno com reimpressão de 2ª via.
- **Fechar caixa** (fechamento cego) via `PainelFechamentoTurno`: informa o contado em Dinheiro, Crédito, Débito, Pix e Outros; o sistema compara e mostra sobra ou falta. Emite comprovante de fechamento (58 ou 80 mm).
- **Detalhes do turno**: quem abriu e quem fechou (foto, nome, CPF), horários, duração, resumo (fundo, vendas por forma incluindo À Prazo, suprimentos, sangrias, esperado × informado, divergência em `dangerColor`), abas de **movimentações** e de **vendas do turno**, observação de fechamento e **Apagar Registro** (confirmação + auditoria).

### 7.6 Relatórios
📄 `relatorios_dialog.dart` · submódulos modulares em `pdv/views/widgets/relatorios/` (`aba_pedidos_relatorios_widget.dart`, `aba_pendencias_relatorios_widget.dart`, `aba_acoes_relatorios_widget.dart`, `dialog_detalhes_acao_relatorio.dart`)
- Filtros por data com botões `<` e `>`, calendário e campo de data.
- **Pedidos Programados** (acima de Pendências): agendamentos do dia, com foto do cliente, horário e frequência; clique abre a comanda.
- **Pendências**: pedidos a prazo em aberto **agrupados por cliente** (total devido, último pedido, selo com quantidade). Clique abre a ficha do cliente, ou a comanda se for pedido avulso.
- **Ações** (auditoria): cada barra abre `_DetalhesAcaoDialog` com data/hora, autor (CPF e e-mail) e descrição, com atalho **"Ver Perfil de [Cliente]"** ou **"Ver Comanda do Pedido #N"** quando ainda existem.

### 7.7 Impressora e Exportação Documental PDF
📄 `impressora_dialog.dart` · submódulos de interface em `pdv/views/widgets/impressora/` (`coluna_configuracao_hardware_widget.dart`, `coluna_automacao_recibo_widget.dart`, `painel_previa_comanda_widget.dart`) · suíte de impressão térmica em `pdv/services/impressao/` (`impressao_utils.dart`, `gerador_bobina_comanda.dart`, `gerador_bobina_caixa.dart`, `gerador_bobina_mesa.dart`, `gerador_bobina_financeiro.dart`, `gerador_escpos_service.dart`, `comunicador_socket_impressora.dart`, `comunicador_windows_spooler.dart` com fachada em `impressao_service.dart`) · suíte modular de relatórios documentais PDF em `pdv/services/relatorios/` (`exportador_pdf_comanda.dart`, `exportador_pdf_financeiro.dart`, `exportador_pdf_dre.dart`, `exportador_pdf_extrato_cliente.dart`, `pdf_formatacao_util.dart` com fachada retrocompatível em `pdv/services/relatorios_pdf_service.dart`)
- Coluna 1: conexão, **largura da bobina (58 / 80 mm)**, **Tipografia da Comanda** (lista de 11 fontes com prévia), **Calibração Bilateral** (margem esquerda padrão 5 mm e direita padrão 3 mm, passos de 0,5 mm).
- Coluna 2: dados da loja/cliente no recibo, automações (**impressão automática ao concluir venda**), rodapé, **testar** e **salvar**.
- **Impressão em Bobina Contínua Sem Cortes e Fiel ao Container da Comanda**: os geradores de bobina realizam o layout com altura ilimitada (`double.infinity`) e extraem a dimensão vertical exata resolvida pelo documento (`ImpressaoUtils.formatoResolvidoDoDocumento`) antes de enviar ao spooler do Windows (`Printing.directPrintPdf`), garantindo que comandas longas com múltiplos marmitex, acompanhamentos, observações, endereço e rodapé sejam impressas integralmente do início ao fim sem truncamento e sem textos extras como `Ref:`. Além disso, a calibração física da impressora da estação (fonte, recuo esquerdo/direito, largura de bobina e impressora selecionada) é herdada automaticamente entre as lojas locais do mesmo terminal.
- **Prévia viva** da comanda dentro da calibração, com um dos 10 perfis históricos (sorteado), e botão de impressora para imprimir o exemplo respeitando a largura configurada (58 / 80 mm).

### 7.8 Mesas e Comandas (Restaurante)
📄 pasta `pdv/views/widgets/mesas/` — `mesas_container.dart`, `criar_mesa_dialog.dart`, `comanda_mesa_dialog.dart`, `adicionar_item_mesa_dialog.dart`, `configuracao_item_mesa_widget.dart`, `fechar_conta_mesa_dialog.dart`, `cadastro_cliente_rapido_mesa_dialog.dart`, `transferir_mesa_dialog.dart`
- Cada mesa tem status (**livre/ocupada**), número, descrição/capacidade, cliente e atendente.
- Lançar item: seleção visual desacoplada em `ConfiguracaoItemMesaWidget` (variantes, complementos, quantidades e observações); remover item gera auditoria. **Imprimir conferência** (pré-fechamento).
- **Transferir / Unir** comandas.
- **Fechar conta**: pagamento único ou **dividido** em várias formas (Dinheiro, Pix, Cartão de Crédito/Débito, Voucher, À Prazo) com saldo restante; botão de **10% de atendimento**; desconto. Se faltar quitar ou sobrar pagamento, **bloqueia**. Forma "À Prazo" exige cliente; se não existir, abre `CadastroClienteRapidoMesaDialog` desacoplado (nome obrigatório, endereço, telefone).
- Cabeçalho "Mesas" com `TextoRolante`, sem colidir com **+ Nova Mesa**.

### 7.9 Financeiro
📄 `pdv/views/financeiro_view.dart` · widgets em `pdv/views/widgets/financeiro/`: `barra_acoes_financeiro_widget.dart`, `seletor_periodo_financeiro_widget.dart`, `bloco_resumo_operacional_widget.dart`, `bloco_entradas_financeiro_widget.dart`, `bloco_balanco_financeiro_widget.dart`, `bloco_compras_financeiro_widget.dart`, `bloco_vendas_financeiro_widget.dart`, `bloco_funcionarios_financeiro_widget.dart`, `item_linha_financeira.dart`, `dialog_novo_gasto_fixo.dart`
- Ordem dos containers: **Resumo Operacional do Dia/Contexto** (primeiro, logo abaixo do filtro de período, com Faturamento, Ticket Médio, Saldo do Caixa, Gastos Declarados do Dia, Saldo Operacional e o indicador unificado **Total Devido (A Pagar)** que agrupa todas as pendências a prazo da loja: compras de estoque a prazo, diárias pendentes e despesas operacionais a prazo) → período e balanço → **Compras do Período** (com subcontainer **"Gastos do dia"** dividido em Gastos Avulsos do Dia e **Gastos Fixos Recorrentes** com suporte a periodicidade diária, semanal, mensal, dias alternados e dias da semana fixos, com indicação de forma de pagamento e status de quitação) → **Vendas do Período** (busca, filtros por forma de pagamento incluindo Voucher e À Prazo, lista de vendas) → **Pagamento de Funcionários** (utiliza o componente padronizado `BarraTrabalhadorWidget`, exibindo nome soberano, CPF mascarado, valor da diária, forma de pagamento, status de pendência/quitação a prazo, botão de chat direto e botão para abrir histórico financeiro do trabalhador).
- **Período**: Hoje, Semana, Mês, Tudo, ou **De / Até** (um dia só, ou intervalo com máscara brasileira DD/MM/AAAA corrigida). Botões `<` `>` e calendário. Digitar uma data desmarca o botão ativo; botão `x` limpa.
- **Entradas por forma de pagamento**: inclui **À Prazo** e **Voucher** com valores reais e discriminados.
- **Sugestão de divisão igualitária** entre trabalhadores. Botão **Registrar Pagamento** (`registrar_pagamento_dialog.dart`, com foto de cada trabalhador e forma de pagamento incluindo À Prazo) registra a ação com a diferença para a sugestão.
- Botões: **Imprimir** (térmica), **DRE Simples** (popup com receita, CMV, lucro bruto, pagamentos, resultado líquido; **Exportar DRE em PDF**) e **Exportar PDF** do financeiro.
- Desktop expandido: duas colunas.

### 7.10 Status da Loja
📄 `pdv/views/status_loja_view.dart` · `pdv/views/widgets/status_loja/bloco_trabalhadores_status_widget.dart`
- Topo (acima do status): **Resumo Operacional do Dia** com Faturamento do Dia, Vendas Hoje, Ticket Médio e Situação do Caixa (Aberto/Fechado + saldo físico).
- **Interruptor Aberta/Fechada** (sincronizado em todos os aparelhos).
- **Lista de Trabalhadores**: exibe a barra tradicional com foto por CPF, nome soberano (respeitando hierarquia Nome Completo $\rightarrow$ Apelido $\rightarrow$ @Usuário Nous), hover, cargo, CPF mascarado com botão de olho para o usuário logado, status **online/offline** e a grade de dispositivos conectados em tempo real com ícones (computador balcão, smartphones, nomes e IPs individuais). Acrescenta os novos botões de ação: **Mensagem Direta** (chat da loja via Conta Nous), **Identidade do Usuário** (`FichaUsuarioDialog`) e **Horários e Escala de Trabalho** (gaveta retrátil com registro de ponto e escala semanal).
- Desktop expandido: duas colunas.

### 7.11 Programar Pedido
📄 `programar_pedido_dialog.dart` · `pedidos_programados_dialog.dart` · `widgets/clientes/pedidos_programados_cliente_widget.dart` · `widgets/relatorios/pedidos_programados_relatorio_widget.dart`
- Acesso: ficha do cliente, relatórios e aviso de agendados do dia. Suporta **criação e edição completa** de programações existentes (`pedidoExistente`).
- Itens: **avulso** (preço base) ou **por categoria** (soma preço da categoria e mostra grupos de adicionais com `+`/`−`); variantes **nascem Desativadas** (opção "Desativado" pode ser religada); observações copiadas automaticamente para o `comentario` da comanda gerada.
- Dois modos: **Contrato / Dias da Semana** (Seg a Dom, com atalhos Dias Úteis, Fim de Semana, Todos os Dias) e **Calendário Visual** mensal com várias datas.
- **Horário**: digitável (`HH:mm`), rodinha do mouse (±1 min), botões `−1m`/`+1m`, e janela **"Digite o Horário"** (atalhos ±5/±10 min, Salvar/Enter). Nos cards de listagem, o badge exibe o horário (`[12:00]`) ao lado de `descricaoFrequenciaCurta` (`Seg a Sex`) sem repetição redundante.
- Entra sozinho em **Novos** no dia certo (com número sequencial real `#00XX`, resolução garantida de telefone/endereço do cliente e transmissão imediata na rede local), sem duplicar e sem ressuscitar ao pausar ou excluir.

### 7.12 Item e Estoque
- **Novo/Editar Item** 📄 `novo_item_dialog.dart` (submódulos modulares em `pdv/views/widgets/novo_item/`: `seletor_midia_item_widget.dart`, `campos_basicos_item_widget.dart`, `seletor_taxonomia_item_widget.dart`, `gestao_variantes_item_widget.dart`, `gestao_estoque_custo_widget.dart`) — ordem dos campos: Foto → Nome → Descrição (minimizada) → Tipo (Produto/Serviço) → Preço de Venda → Categorias e Grupos → Variantes → Código de Barras → Unidades (`un`, `g`, `ml`) → Consumo por Venda → **Estoque e Preço de Custo** (saldo, ajuste/inicial, mínimo, **Lançar Movimento Detalhado**, custo unitário da última compra, margem estimada) → Delivery. Largura: ~740 px (2 colunas) no expandido, ~380 px (1 coluna) no compacto.
- **Movimento de Estoque** 📄 `movimento_estoque_dialog.dart` — tipo (Entrada etc.), quantidade e **custo total da compra** (o custo unitário se calcula sozinho, e vice-versa). Seção rápida permite mudar preço de venda, código de barras e **unidade de medida**.
- **Baixa de Estoque e Estornos Unificados** 📄 `lib/src/features/pdv/services/estoque_baixa_service.dart` — serviço soberano para cálculo de saídas por vendas e entradas por estornos, ponderando rigorosamente o `consumoPorVenda` do item base e de todos os acompanhamentos selecionados em pedidos de balcão e comandas de mesas.
- **Gestão Modular de Mesas e Salão** 📄 `lib/src/features/pdv/views/widgets/mesas/gerenciador_mesas_loja.dart` — controlador desacoplado responsável por comandas de mesa (`comanda_mesa_dialog.dart`), transferências e unificações de mesas (`transferir_mesa_dialog.dart`), edição/cadastro (`criar_mesa_dialog.dart`) e fechamento de conta com baixa automática de estoque (`fechar_conta_mesa_dialog.dart`).
- **Cancelar Pedido** 📄 `cancelar_pedido_dialog.dart` — motivo obrigatório e opção de devolver ao estoque com estorno recalculado via `EstoqueBaixaService`.
- Outras janelas de apoio: `nova_categoria_dialog.dart`, `novo_grupo_componentes_dialog.dart`, `opcoes_imagem_dialog.dart` ("Procurar nova imagem", "Retirar imagem", "Cancelar"; se o campo está vazio, abre direto o seletor de arquivos), `venda_registrada_dialog.dart` (comanda de venda já feita, com **Quitar Pagamento à Prazo**, modularizado com `barra_venda_widget.dart`, `bloco_acoes_venda_widget.dart`, `bloco_resumo_venda_widget.dart`, `bloco_itens_venda_widget.dart`, `bloco_comentario_venda_widget.dart`), `comanda_pedido.dart`, `comanda_pedido_dialog.dart`.

### 7.13 Mensageria e Chat
📄 `chat/views/mensageria_view.dart` · serviços `chat/services/chat_service.dart`, `chat/services/chat_autoatendimento_service.dart`, `chat/services/sincronizador_chat_balcao.dart`, `chat/services/comunidade_chat_service.dart` · modelos em `chat/models/` (`mensagem_chat.dart`, `conversa_chat.dart`)
- Interface estilo WhatsApp adaptável: lista de conversas à esquerda e conversa ativa à direita no desktop (≥ 720 px); lista ou conversa em tela cheia com botão voltar no celular.
- **Cabeçalho da Conversa Ativa Padrão WhatsApp**: tanto em celular/compacto quanto no desktop, o topo do chat alinha estritamente as informações do contato à esquerda (avatar circular com foto ou iniciais, nome completo do contato em negrito com `TextoRolante` e subtítulo com status de presença online/ausente/fechada ou `@username`, com toque em splash que abre os detalhes da conversa) e posiciona os botões de ação à direita (`IconButton` de chamada de vídeo, chamada de áudio e lupa `Icons.search_rounded` para pesquisar palavras-chave no histórico da conversa).
- **Chamadas de Voz e Vídeo WebRTC LAN P2P**: chamadas diretas pela rede local sem internet. Permite iniciar por voz e ativar a câmera dinamicamente no meio da chamada (`alternarCamera`). O espelhamento de vídeo é inteligente e seletivo: apenas a câmera frontal (selfie) é espelhada localmente (`mirror: true`), mantendo a câmera traseira na orientação real e a câmera do interlocutor remoto sempre fiel e desespelhada.
- **Botão de Voltar no Desktop quando chat aberto**: ao navegar para Mensagens pela barra flutuante universal no desktop e selecionar uma conversa (momento em que a barra universal é desabilitada), o `CustomAppBar` exibe automaticamente o botão de voltar no canto superior esquerdo para desmarcar a conversa atual e voltar à lista, impedindo que o usuário fique preso na tela.
- **Ordem Natural, Separadores de Dia e Rolagem Automática com Botão Flutuante**: mensagens em ordem cronológica direta (antigas no topo, recentes embaixo), com badges separadores de dia centralizados ("Hoje", "Ontem", "Anteontem" ou `dd/MM/yyyy`) entre dias diferentes, rolando suavemente até o final ao abrir o chat ou receber novas mensagens. Ao subir o histórico do chat, surge no canto inferior direito um botão flutuante (`Icons.keyboard_arrow_down_rounded`) que desce instantaneamente até a última mensagem.
- **Título da Conversa Interativo e Identidade Soberana**: conversas 1-on-1 exibem com destaque o nome real e avatar do interlocutor (com `@username` visível e filtragem soberana que nunca exibe o próprio nome do usuário logado); grupos mantêm o nome do grupo e tópicos comunitários o nome da sala; renomear a conversa fica disponível nos detalhes do contato e ao segurar a conversa na lista.
- **Barra de Conversa na Lista (`ItemConversaTile`)**: nomes e prévias de mensagem utilizam `TextoRolante` quando excedem a largura disponível e exibem os traços de status (`pendente`, `enviada`, `entregue`, `lida`) antes do texto quando a última mensagem foi enviada pelo próprio usuário.
- **Arquitetura Modular da Mensageria e Recarga Cirúrgica de Histórico**: organizada em camadas desacopladas (`MensageriaController`, `ListaConversasWidget`, `PainelConversaAtivaWidget`, `BalaoMensagemWidget`, `ItemConversaTile`, `ResolvedorFotoChat`, `SincronizadorChatBalcao`, `ComunidadeChatService`), garantindo renderização instantânea em O(1) com cache inteligente e autocura no SQLite. Mensagens da conversa aberta são atualizadas cirurgicamente em sub-5ms (`recarregarMensagensConversaAtiva`) sem acionar loops de rebuild geral de contatos.
- **Confirmação de Leitura em Check Duplo Azul**: mensagens lidas pelo destinatário exibem check duplo no azul oficial WhatsApp (`#34B7F1`).
- **Ações Contextuais de Mensagem (Toque Duplo / Clique / Toque Longo)**:
  - **Toque Duplo Rápido**: tocar duas vezes rapidamente em qualquer mensagem copia seu conteúdo imediatamente para a área de transferência.
  - **Favoritar / Desfavoritar**: marca a mensagem com estrela (`favorita: true`), consultável na lista de Mensagens Favoritadas da conversa.
  - **Copiar**: copia o texto da mensagem para a área de transferência.
  - **Encaminhar**: abre diálogo de seleção de outra conversa da lista (com prévia de miniatura) para envio imediato.
  - **Editar**: disponível para o autor da mensagem; exibe selo `(editada)` na bolha, com histórico completo de versões anteriores acessível ao tocar no selo.
  - **Excluir para todos**: disponível para o autor e **somente nos primeiros 60 segundos** após o envio.
- **Barra de Envio com Câmera, Menu de Anexos (Ícones Brancos Temáticos) e Autoatendimento ("Fazer Pedido")**:
  - **Ícone de Câmera**: captura e envio instantâneo de fotos físicas direto pelo visualizador/câmera.
  - **Botão de Anexo (`+` / clipe, `DialogMenuAnexosChat`)**: painel estilo WhatsApp com ícones brancos temáticos (`theme.textColor`):
    - **Fazer Pedido (`DialogFazerPedidoChat` + `ModalPersonalizarItemAutoatendimento`)**: visível ao conversar com uma loja; importa o catálogo completo da loja (local ou via rede) e permite que o próprio cliente interaja com categorias (com valor base e grupos de adicionais), itens, variantes, grupos de componentes (`GrupoComponentesLoja` com contadores `+`/`-`), observações por item, forma de pagamento e edição da sua própria ficha de cliente na loja (`DialogEditarFichaClienteLoja`, sem duplicar cadastros por CPF/nome). Ao clicar em **"Despachar Pedido"**, envia o card interativo da comanda no chat e cria o pedido diretamente na aba **"Novos"** do balcão da loja com alerta sonoro.
    - **Galeria**: seleção de imagens nativa com retorno direto ao chat ao fechar.
    - **Documento**: envio de PDFs e arquivos gerais com ícone do tipo e tamanho formatado.
    - **Contato**: compartilhamento de contatos Nous cadastrados.
    - **Comanda de Pedido**: envio de card interativo com badge ao vivo da etapa do pedido ("AGUARDANDO ACEITE (NOVOS)", "EM PREPARO (ACEITO)", "CONCLUÍDO", "CANCELADO"), botão para o operador avançar a etapa, itens, total e atalho para `ComandaPedidoDialog`.
    - **Localização, Enquete, PIX e Evento**: atalhos com aviso de "Funcionalidade em construção".
- **Compartilhamento de Comanda direto do PDV** (`ComandaPedidoDialog`): botão "Chat" ao lado de Imprimir e Fechar que permite enviar a comanda com 1 clique para o cliente do pedido ou para a equipe da loja.
- **Painel limpo por padrão**: ao abrir a tela de Mensagens, nenhuma conversa é auto-selecionada; o painel direito exibe o espaço limpo e receptivo convidando o usuário a escolher ou iniciar um chat.
- **Destaque Permanente da Conversa Ativa**: o chat selecionado na barra lateral desktop recebe destaque visual fixo (borda nítida de 4px e fundo aceso contrastante) e efeito suave de hover nos demais contatos.
- **Busca de Contatos com `TextoRolante`**: placeholder rolante e filtragem dinâmica de contatos e lojas.
- **Resolução de fotos da equipe**: fotos dos membros da equipe e de clientes são resolvidas automaticamente por CPF (`auth.buscarFotoPorCpf`, `pdv.buscarFotoClientePorCpf`), garantindo fotos reais nos avatares e transmissão com autocura prévia ao balcão.
- **Detalhes do Contato e Gestão da Conversa (`DialogDetalhesContato`)**: clique no cabeçalho abre janela estilo WhatsApp com:
  - Foto ampliada (com toque para tela cheia com zoom), frase da biografia em destaque sem container, botões compactos centralizados (**"Renomear"**, **"Compartilhar"** e **"Minha Ficha"** em lojas), botão **"Ver Perfil Público"** e botão **"Identidade do Usuário"** (abre `FichaUsuarioDialog` respeitando a transparência/privacidade da conta Nous).
  - **Mensagens Favoritadas** e **Silenciar notificações** (`ThemedSwitch`).
  - **Mídias, Links e Docs**: grade de imagens trocadas, lista de documentos e detecção automática de links web clicáveis.
  - **Exportar backup da conversa**: exporta todo o histórico em arquivo JSON estruturado.
  - **Excluir conversa deliberativa**: solicita exclusão com consentimento mútuo entre as partes via notificação deliberativa.
- **Envio Otimista Instantâneo em 0ms**: ao tocar em enviar, a mensagem surge imediatamente na bolha, o campo de digitação é limpo e a rolagem avança; a persistência SQLite e a transmissão pela malha ocorrem de forma não-bloqueante em segundo plano.
- **Fila de Saída Offline (*Outbox*) com Autodrenagem**: se o dispositivo estiver offline, a mensagem é armazenada com status pendente (ícone de relógio cinza) e é automaticamente drenada e transmitida no momento da reconexão (cliente ou servidor).
- **Ciclo Completo de Confirmação Visual de Envio/Entrega/Leitura**:
  - *Relógio cinza* (`Icons.access_time_rounded`): pendente na fila local.
  - *1 check cinza* (`Icons.check`): transmitida e gravada na rede.
  - *2 checks cinzas* (`Icons.done_all`): entregue fisicamente e confirmada apenas pelo dispositivo do verdadeiro destinatário.
  - *2 checks azuis* (`#34B7F1`, `Icons.done_all`): visualizada e marcada como lida pelo destinatário.
- **Fixação, Silenciamento e Arquivamento de Conversas**:
  - Clique com botão direito ou toque longo no item da conversa abre menu posicionado diretamente sobre a conversa selecionada com "Renomear conversa", "Fixar/Desafixar", "Silenciar/Reativar notificações" e "Arquivar/Desarquivar".
  - Conversas fixadas exibem ícone discreto de alfinete (`Icons.push_pin_rounded`) e têm prioridade no topo da lista.
- **Fonte Única da Verdade, Persistência Imediata e Arquitetura Modular**: novas conversas abertas são imediatamente gravadas na tabela `conversas_chat` do SQLite com índices aceleradores (`idx_chat_lida`), garantindo que nunca desapareçam da lista de chats ativos e que a troca de conversa seja instantânea sem travamentos. O subsistema de chat foi modularizado e desacoplado em responsabilidades únicas:
  - 📄 `chat/services/chat_repositorio_sqlite.dart`: persistência SQLite soberana, batch updates atômicos de leitura e carregamento paginado leve.
  - 📄 `chat/services/chat_media_service.dart`: gestão segura de anexos em disco, leitura protegida em Base64 e formatação de resumos.
  - 📄 `chat/services/chat_sincronizacao_service.dart`: despacho via malha de rede local Wi-Fi (servidor/cliente), eventos de entrega/leitura e drenagem de fila.
  - 📄 `chat/services/chat_service.dart`: fachada soberana e unificada de mensageria retrocompatível.
  - 📄 `pdv/providers/helpers/pdv_vendas_estoque_helper.dart` e `pdv_sincronizacao_rede_helper.dart`: módulos especialistas desacoplados do `PdvProvider` para gerenciamento soberano de baixas de estoque e tráfego de sincronização de rede local.
- **Modo Loja**: remetente é a Loja atual; bolhas de mensagem exibem o atendente responsável; carrega membros da equipe e clientes cadastrados de forma desduplicada.
- **Modo Usuário Nous**: remetente é o cidadão/CPF logado; acessado pelo botão "Mensagens" do Perfil Social; conversa com lojas que participa e outros contatos da rede.

### 7.14 Perfil Social e Identidade do Usuário
📄 `auth/views/perfil_social_view.dart` · `auth/views/widgets/editar_perfil_dialog.dart` · `auth/views/widgets/ficha_usuario_dialog.dart` · `auth/models/usuario_nous.dart`
- **Acesso principal**: segundo ícone da barra flutuante universal inferior (ícone pessoinha); ao abrir por essa barra, a tela **não exibe botão de voltar** no topo esquerdo.
- **Visual centralizado**: foto do perfil em círculo (raio 50), `@apelido`, nome de exibição em negrito, métricas ("Posts", "Seguidores", "Seguindo") e biografia do usuário, todos alinhados ao centro.
- **Separação Soberana entre Identidade Civil e Perfil Social**:
  - **Identidade do Usuário (`FichaUsuarioDialog`)**: contém os dados civis e cadastrais oficiais do cidadão (`nome`, `apelido`, `foto`, `cpf`, filiação, tipo sanguíneo, etc.) para verificação e integridade do sistema. O Nome de Usuário Nous (`@username`) é exibido de forma imutável logo acima do CPF com a mesma tipografia secundária, deixando evidente a imutabilidade dessas credenciais, enquanto Apelido e Nome Próprio permanecem editáveis pelo próprio titular.
  - **Edição do Perfil Público (`EditarPerfilDialog`)**: acessado pelo botão "Editar Perfil" no Perfil Social. Altera exclusivamente os dados de exibição pública (`nomePublico`, `apelidoPublico`, `fotoPublica`, `biografia`), com fallback transparente para a Identidade caso não personalizados. Garante total liberdade estética ao usuário sem comprometer ou sobrescrever os dados oficiais de sua Identidade.
### 7.15 Arquitetura Modular e Otimizada do PDV e Financeiro (v1.0.66)
- **Catálogo de Produtos (`AbaCatalogoLojaWidget`)**: Decomposto em módulos coesos para categorias e grupos (`PainelCategoriasGruposWidget`) e grade de cards com drag & drop reordenável (`PainelItensCatalogoWidget`).
- **Módulo Financeiro (`FinanceiroView`)**: Operações de DRE, fluxo de caixa, pagamentos de equipe, compras e balanço desacopladas via `FinanceiroOperacoesHelper`.
- **Gestão Operacional de Pedidos (`GestaoLojaContainer`)**: Desacoplado em barra de atalhos rápidos (`BlocoBotoesGestaoWidget`) e listagem paginada de pedidos com filtros e abas (`BlocoPedidosGestaoWidget`).
- **Resumo Operacional e Fornecedores**: Telas `StatusLojaView` e `FornecedoresDialog` estruturadas em subcomponentes reutilizáveis de formulário, importação e listagem.
- **Auditoria de Memória**: `PedidosRepositorioLoja` com retenção inteligente de pedidos e `ImagemService` com política LRU (cota de 500 MB) para sanitização automática de cache.

### 7.16 Blindagem de Longo Prazo, Persistência Estruturada e Otimização Assintótica (v1.0.67)
- **Reconciliação Instantânea em O(1) na Rede Local P2P (`ReconciliadorLojaRede`)**:
  - Eliminação de pesquisas lineares e aninhadas ($O(N \times M)$) por indexações em hash sets (`Set<String>`) e mapas diretos para mesclagem instantânea sem jank ao receber dados via Wi-Fi.
  - Teto de retenção de tráfego de rede: protege a largura de banda LAN limitando transferências de histórico a 2.000 ações e movimentos mais recentes e 1.000 pagamentos mais recentes.
- **Persistência Estruturada e Retenção em Memória no SQLite**:
  - 📄 `pdv/services/loja/movimentos_repositorio_loja.dart`: Repositório dedicado de movimentações de estoque, gravando em lotes atômicos e mantendo apenas a janela recente em RAM com consultas paginadas sob demanda.
  - 📄 `pdv/services/loja/pagamentos_repositorio_loja.dart`: Repositório dedicado de pagamentos e salários de funcionários, garantindo integridade de balanço plurianual.
- **Refatoração com Paginação Progressiva**:
  - 📄 `pdv/views/widgets/relatorios/auditoria_relatorio_widget.dart`: Reduzido para 285 linhas, com renderização de lotes progressivos (50 itens por página) via rolagem infinita. Detalhes desacoplados em `detalhes_acao_dialog.dart` e `barra_acao_widget.dart`.
  - 📄 `pdv/views/widgets/estoque_container.dart`: Reduzido para 357 linhas. Cálculo de saldos otimizado de $O(I \times M)$ para $O(M)$ por pré-computação em mapa hash. Subcomponentes `ficha_kardex_dialog.dart` e `linha_movimento_widget.dart` extraídos para `views/widgets/estoque/`.

### 7.17 Concorrência Aditiva em Mesas, Manutenção de Banco e Desacoplamento do PdvProvider (v1.0.68)
- **Blindagem de Concorrência em Mesas na Rede Local P2P**:
  - 📄 `pdv/services/rede_local/reconciliador_loja_rede.dart` e `pdv/services/rede_local/handlers/roteador_loja_pedidos.dart`:
    - Mesclagem aditiva e granular de consumos (`ItemComandaMesa`) nas mesas.
    - Quando dois garçons ou terminais lançam pedidos concorrentemente na mesma mesa, os itens são combinados por ID único sem perda de consumo e sem sobrescrever comanda.
- **Manutenção Preventiva e Saúde do SQLite**:
  - 📄 `core/services/banco_dados_service.dart`: Método `executarManutencaoPreventiva()` executando `PRAGMA integrity_check`, `VACUUM` (compactação física de páginas e liberação de espaço em disco ao sistema) e `PRAGMA optimize`.
  - Execução periódica automática em segundo plano a cada 7 dias de uso contínuo.
- **Desacoplamento do PdvProvider**:
  - 📄 `pdv/providers/helpers/pdv_lojas_cofre_helper.dart`: Extraído helper de carregamento de lojas, referências, sucessão de dono e consolidação da Loja Coletiva Nous, reduzindo a complexidade de `PdvProvider`.

---

## 8. Atalhos de teclado (resumo)
- **F11** tela cheia (fixa, global). **Esc** fecha janelas / sai do Modo Balcão (fixa).
- **F1 a F10 e F12**: configuráveis em "Ajustes do Perfil → Comandos" (inclui Mensagens), todas começam desativadas.
- **Enter** no Modo Balcão finaliza venda; no bipador, adiciona item.
- **← →** nos visualizadores de mídia.
- Leitores USB de código de barras funcionam como teclado.

## 9. O que ainda não existe (pastas reservadas)
`features/timeline`, `features/delivery`, `features/banco`, `features/autogestao`. (Módulo `chat` e Perfil Social agora implementados).
