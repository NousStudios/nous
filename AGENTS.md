# ═══════════════════════════════════════════════════════════════
# NOUS — MANIFESTO DE CÓDIGO E CONTEXTO DE DESENVOLVIMENTO
# Documento de transferência entre IAs e Diretrizes do Agente
# Projeto: Nous — Software Universal de Autogestão Comercial e Social
# ═══════════════════════════════════════════════════════════════

> **VOCÊ É UM AGENTE DE CÓDIGO COM ACESSO DIRETO AOS ARQUIVOS DESTE PROJETO.**
> Antes de qualquer ação, leia este documento com atenção. Ele contém a identidade, o propósito político, a arquitetura, o estado atual da base de código, as decisões técnicas e o modo de trabalho em conjunto com o desenvolvedor. Não é um adorno: **é a razão de existir do Nous.**

---

## 1. QUEM É O DESENVOLVEDOR E COMO TRABALHAR COM ELE

- **Perfil:** O desenvolvedor é iniciante em programação, autodidata e mora no Brasil.
- **Idioma Obrigatório:** Responda **SEMPRE em Português do Brasil (pt-BR)**.
- **Didática e Clareza:** Explique mudanças de forma sintética, direta e pedagógica. Sem jargões desnecessários ou pretensão acadêmica. Se ele não entender, a falha é sua na explicação.
- **Raciocínio Explícito ANTES do Código:**
  Antes de propor ou aplicar qualquer modificação, estruture seu raciocínio em português:
  1. O que você entendeu da demanda.
  2. Os caminhos considerados.
  3. O que você descartou e o porquê.
  Isso serve para ensinar o desenvolvedor e permitir que ele aprove a rota antes de você gastar código.
- **Validação Prévia de Decisões Estruturais:**
  Quando a alteração envolver novo modelo, nova feature, mudança de paradigma ou remoção de código existente, **pergunte e alinhe ANTES de codar**.
- **Apresentação de Diffs e Aprovação:**
  Mostre o que será modificado de forma clara (trecho/diff) antes de aplicar grandes reescritas. Nunca sobrescreva arquivos sem transparência.
- **Preservação de Funcionalidades:**
  **Nunca apague silenciosamente funcionalidades que já funcionam.** Se for necessário refatorar ou remover algo, avise antes e justifique tecnicamente e conceitualmente.
- **Aviso Obrigatório de Build/Cache:**
  Sempre que criar, editar ou alterar campos em modelos persistidos (`fromJson`, `toJson`, `shared_preferences`), **avise proativamente o desenvolvedor para executar:**
  ```bash
  flutter clean && flutter pub get
  ```
- **Higiene de Código:**
  Ao finalizar qualquer edição, certifique-se de que o arquivo esteja limpo: sem imports não utilizados, sem comentários óbvios ou inúteis, sem código morto e sem `// TODO` fictícios que não serão implementados imediatamente.
- **Sincronização Proativa de Contexto (README, AGENTS.md e Skills):**
  **REGRA MANDATÓRIA:** A cada ciclo de trabalho onde novas features, campos persistidos, padrões visuais, atalhos ou correções forem implementados, a IA **DEVE atualizar proativamente o `README.md`, o `AGENTS.md` e as skills pertinentes** antes de encerrar o turno, sem esperar que o desenvolvedor solicite. Isso garante que a memória do projeto permaneça sempre fresca, objetiva e sintética, prevenindo a repetição de erros e o retrabalho.

---

## 2. O QUE É O NOUS?

O **Nous** é um SuperApp brasileiro, livre e de código aberto, construído em Flutter e Dart para desktop (foco primário: Windows) e futuramente mobile (Android).

Sua proposta é ser um **Software Universal de Autogestão Comercial e Social**, reunindo numa única plataforma:
- **PDV (Ponto de Venda) Completo:** Lojas, itens, categorias, clientes, fornecedores, vendas à vista/a prazo, controle de estoque com unidades de medida (un, g, ml), relatórios gerenciais, módulo financeiro, impressão térmica de 58mm outras formas de impressão consagradas no mercado e exportação em PDF.
- **Módulos Futuros (Pastas já reservadas):**
  - Chat interno (`features/chat`)
  - Timeline social (`features/timeline`)
  - Gestão de entregadores e delivery (`features/delivery`)
  - Banco comunitário e crédito mútuo (`features/banco`)
  - Autogestão e deliberação coletiva (`features/autogestao`)

O Nous não é um aplicativo neutro. É uma ferramenta prática voltada a colocar **a economia e os meios de produção na mão da classe trabalhadora**.

---

## 3. A VISÃO IDEOLÓGICA (A Política que Guia a Técnica)

Este projeto apoia-se no **Plataformismo Brasileiro**: uma síntese pioneira entre a tradição organizativa anarquista de 1926 (*Dielo Truda*, Nestor Makhno) e as possibilidades das plataformas computacionais contemporâneas no Sul Global, visando a autogestão real, soberania digital e a emancipação da classe trabalhadora rumo a uma sociedade sem classes e sem exploração.

### 3.1 A Ontologia do Nous (A Mente Operadora)
- **Etimologia e Sentido Filosófico:** *Nous* (νοῦς) — atividade do intelecto puro, a razão divina ordenadora que em Anaxágoras organiza o cosmo a partir do caos original, o primeiro motor e intelecto ativo em Aristóteles que intui princípios indemonstráveis sem premissas intermediárias, e o "olho da mente" em Platão.
- **Manifestação Computacional:** O software Nous atua como a **Mente Coletiva** e o **interpretador universal** dos dados sensíveis e das relações produtivas da sociedade. Ele traduz a microgestão deliberada pelos próprios trabalhadores em interfaces visuais diretas, sem a intermediação de burocracias parasitárias ou algoritmos de manipulação voltados ao consumo anestesiante.

### 3.2 O Princípio Político Fundamental: Negação do *Arkhon*, Afirmação do *Arkhein*
- **Etimologia de Anarquia:** Deriva de *an* (sem) + *arkhos* (chefe, líder, príncipe) + *arkhein* (governar, comandar, começar, planejar, ter *télos* ou finalidade).
- **A Distinção Crucial do Projeto:**
  - **Negação do *Arkhon*:** Rejeição absoluta do chefe, do tirano, do oligarca, do dono absolutista e da classe de políticos profissionais. Não há governantes nem castas privilegiadas.
  - **Afirmação do *Arkhein*:** Planejamento, ordem, cálculo econômico, previsão de demandas e teleologia coletiva são indispensáveis à sobrevivência e emancipação da espécie humana. Governar é planejar. O que o Nous propõe é o **governo sem classe governante**: a diluição da administração nas mãos do povo trabalhador via democracia direta e ferramentas digitais.

### 3.3 A Inserção Orgânica no Mercado (O "Cavalo de Troia" Emancipatório)
- O Nous não se isola em um gueto utópico. Ele se insere organicamente no comércio real oferecendo a melhor ferramenta operacional possível (PDV rápido, local-first, offline, sem mensalidades, intuitivo e com impressão térmica precisa).
- Uma vez adotado, o software infunde uma lógica cooperativa e despersonalizada: expõe a saúde financeira aos trabalhadores, sugere a divisão igualitária dos excedentes, distribui turnos sem sobrecarga e estimula a consciência de classe na prática cotidiana.

### 3.4 Transparência Radical (Antídoto à Opacidade do Capital)
- A degeneração do capital prolifera na escuridão e no segredo. A corrupção e a exploração são intrinsecamente privadas.
- O antídoto técnico do Nous é a **exposição contínua e irrestrita à luz**:
  - No módulo Financeiro, **o trabalhador acessa e vê exatamente os mesmos números que o dono ou administrador**. Saldo negativo ou sobras nunca são camuflados.
  - Os pagamentos aos trabalhadores contam com **sugestão de divisão igualitária calculada pelo sistema**:
    $$\text{Sugestão} = \frac{\text{Entradas} - \text{Saídas}}{\text{Número de Membros}}$$
  - Ajustes manuais são permitidos caso a caso, mas **absolutamente tudo é registrado em histórico de auditoria** (`RegistroAcao`), contendo autor, data, horário e delta da alteração.

### 3.5 Identidade Real Soberana, Sem Anonimato Irresponsável
- A despersonalização do poder não se confunde com covardia ou anonimato destrutivo.
- Tudo no sistema é vinculado ao **CPF do cidadão**. Uma pessoa pode cadastrar múltiplos e-mails, mas todos convergem para o mesmo CPF.
- Isso elimina contas falsas, bots e a impunidade comum em plataformas centralizadas, sem depender de Big Techs ou solicitar permissão governamental. A responsabilidade é do indivíduo perante a comunidade.

### 3.6 Autonomia Coletiva e Consentimento entre Donos e Sócios
- A hierarquia de loja reflete papéis operacionais (`Dono`, `Sócio`, `Admin`, `Funcionário`), mas o poder não é despótico.
- **Hierarquia e Regras de Exclusão de Membros:**
  - **Outros donos NÃO podem excluir outros donos diretamente:** Se um dono tentar excluir outro dono, o sistema envia uma solicitação de saída via notificação (`TipoNotificacao.solicitacaoExclusaoDono`). A saída só se efetiva se o dono alvo consentir (aceitar).
  - **Donos:** Podem excluir membros abaixo na hierarquia (`Sócio`, `Admin`, `Funcionário`). Ao fazê-lo, o membro é removido e recebe notificação informativa (`TipoNotificacao.remocaoLoja`): *"Você foi removido(a) da loja [Loja] por [Nome]"*.
  - **Sócios NÃO podem excluir Sócios nem Donos:** A opção não é acessível. Sócios podem excluir apenas quem estiver abaixo na hierarquia (`Admin` e `Funcionário`), gerando a notificação de remoção.
  - **Admins e Funcionários:** Não possuem poder de exclusão de terceiros.
  - **Autoexclusão:** Todo membro tem direito de sair voluntariamente da loja a qualquer momento.
- **Princípio Inegociável entre Sócios:** **Um sócio não pode alterar o papel de outro sócio unilateralmente.** Qualquer alteração de papel de um sócio exige notificação (`TipoNotificacao.alteracaoPapel`) e o **consentimento explícito (aceite)** do sócio alvo.

### 3.7 Sistema Fechado, Soberano e Local-First
- O ecossistema opera de ponta a ponta sem dependência de APIs de Big Techs.
- Backup completo serializado em um único arquivo JSON manipulado pelo próprio usuário com `file_selector`.

### 3.8 A Vida Real Manda (O Humano no Comando)
- Onde a máquina calcula estimativas (ex.: baixa de estoque em gramas ou ml por venda), ela **propõe a baixa**, mas o ser humano **confirma, ajusta ou cancela** antes de efetivar.

### 3.9 O Horizonte do SuperApp e Lema de Produção
- O ecossistema prevê a evolução integrada para a IA assistente (**Hermes**), redes de mapa e entrega com negociação direta de fretes, banco comunitário com crédito mútuo, e autogestão deliberativa.
- **Lema Síntese:** *"Trabalhar todos, trabalhar menos, produzir o necessário, distribuir tudo."* (Com metas de turnos de 4 horas diárias de trabalho em alta rotatividade, erradicação do lucro parasitário e soberania tecnológica cooperada).

---

## 4. FILOSOFIA DE TRABALHO: MALANDRAGEM BRASILEIRA E ECONOMIA DE TOKENS

> **Malandragem Brasileira não é preguiça.** É a inteligência prática de quem resolve o problema com o que tem à mão, sem burocracia, sem complexidade inútil (*overengineering*) e sem importar padrões estrangeiros vazios. É fazer mais com menos.

- **Leitura Cirúrgica:** Nunca leia arquivos em excesso. Use `grep_search` e leia trechos pontuais (`StartLine`/`EndLine`).
- **Edições Atômicas:** Nunca reescreva arquivos inteiros se basta alterar uma função ou adicionar um bloco.
- **Sem Abstrações Prematuras:** Reutilize os padrões e widgets já consolidados no projeto.
- **Foco Estrito no Presente:** Resolva o que foi pedido com precisão. Não invente features paralelas desnecessárias.

---

## 5. ARQUITETURA DO PROJETO

### 5.1 Organização Modular por Feature (*Feature-First*)
- Domínios de negócio residem em `lib/src/features/` (`auth/`, `notificacoes/`, `pdv/`, etc.).
- Cada feature organiza seus próprios `models/`, `providers/`, `services/`, `views/` e `views/widgets/`.
- Elementos transversais residem em `lib/src/core/` (`theme/`, `widgets/`, `services/`).
- Imports completos de pacote são obrigatórios: `import 'package:nous/src/...';`.

### 5.2 Gerenciamento de Estado
- Adotado o pacote **`Provider`** com `ChangeNotifier`.
- Provedores globais (`AuthProvider`, `PdvProvider`, `NotificacoesProvider`) registrados no `main.dart`.
- Evite rebuilds cíclicos: use `context.read<T>()` em callbacks e `context.watch<T>()` onde a reconstrução do widget for estritamente necessária.

### 5.3 Persistência Local Soberana e Banco de Dados SQLite
- **Motor Relacional Local (`sqflite_common_ffi`):** Os dados operacionais (lojas, pedidos, estoque, pagamentos, contas e convites) são persistidos localmente no Windows em banco SQLite (`nous.db` gerenciado por `BancoDadosService`), garantindo transações atômicas ACID, proteção contra quedas repentinas de energia e escalabilidade para dezenas de milhares de vendas sem sobrecarregar a memória RAM.
- **Tabelas Indexadas e Arquitetura Híbrida:**
  - `lojas`: dados cadastrais e configurações vinculados ao `cpf_dono`.
  - `pedidos`: cada venda como linha individual, indexada por `loja_id`, `data_hora DESC` e `status`.
  - `movimentos_estoque`: cada entrada/baixa indexada por `loja_id` e `data_hora DESC`.
  - `pagamentos_funcionarios`, `referencias_loja`, `contas_usuarios` e `convites`.
- **Migração Transparente e Fallback:** Na primeira execução, o `BancoDadosService` migra automaticamente registros legados de `shared_preferences` para o SQLite sem perda de dados.
- **Cofre Soberano e Backup Universal:** Cada loja reside no cofre do seu `cpfDonoOriginal`. Membros participantes acessam através de `ReferenciaLoja`. O `BackupService` exporta e importa a totalidade dos dados em um único arquivo `.json` manipulado diretamente pelo usuário com `file_selector`.

### 5.4 Automação de Build e Distribuição (Pasta `dist/` e Scripts)
- **Pasta `dist/`:** Destinada a armazenar os binários compilados de entrega do sistema para testes e produção:
  - Windows: `dist/Nous_Instalador_v1.0.0_Versao_Teste.exe` (instalador executável com Inno Setup 6).
  - Android: `dist/Nous_Android_v1.0.0_Versao_Teste.apk` (pacote APK único gerado em modo Release).
- **Scripts em `scripts/`:**
  - `scripts/gerar_instalador.ps1`: Compila a aplicação Windows Desktop (`flutter build windows --release`), empacota via Inno Setup 6 (`windows/installer.iss`) e entrega o executável em `dist/`. Aceita a flag opcional `-IncluirAndroid` para disparar a build do APK na mesma esteira.
  - `scripts/gerar_apk.ps1`: Compila o APK para Android (`flutter build apk --release`) e copia automaticamente o binário final gerado para a pasta `dist/` gerando exclusivamente `dist/Nous_Android_v1.0.0_Versao_Teste.apk`.
  - `scripts/deploy_wifi.ps1`: Conecta automaticamente ao celular via ADB sobre Wi-Fi e instala a versão atualizada do APK diretamente no aparelho.
  - `scripts/converter_icone.ps1`: Converte automaticamente `assets/images/logo.png` em ícone multirresolução Windows (`app_icon.ico`) e no Android gera tanto o `ic_launcher.png` com fundo 100% preto sólido (`#000000`) de ponta a ponta quanto o Adaptive Icon oficial (`res/mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_foreground.png` centralizado na safe zone), eliminando halos ou recortes claros nos launchers de celulares.
- **Reconhecimento Soberano de Dispositivo no PDV:** O `PdvProvider.layoutDesktopAtivo(lojaId, larguraTela)` e o getter `loja.layoutExpandidoEfetivo` desativam categoricamente o modo desktop expandido em Android e iOS. Ao importar backups criados no Windows onde a loja estava em modo expandido, o sistema ignora o flag de desktop na interface móvel, garantindo que os botões de ação e gestão da loja (`GestaoLojaContainer`) permaneçam 100% visíveis.

### 5.5 Sincronização em Rede Wi-Fi Local-First (Balcão & Terminais Móveis)
- **Operação Simultânea Offline:** Computadores e celulares na mesma rede Wi-Fi sincronizam pedidos, estoque e mesas em tempo real via WebSocket e REST local (`servidor_rede_local.dart` e `cliente_rede_local.dart`) sem dependência de internet.
- **Sincronização Soberana de Imagens:** O servidor expõe `GET /api/imagem?caminho=...`. O terminal móvel no celular faz o download físico das fotos ausentes (produtos, categorias, clientes, fornecedores e logo da loja) diretamente para o armazenamento interno local (`ImagemService.obterDiretorioBase()`), reescrevendo os caminhos no SQLite local para garantir autonomia e visualização offline total.
- **Cache Determinístico e Resolução Instantânea de Imagens:** O cliente Wi-Fi nomeia as mídias baixadas via hash determinístico do caminho remoto (`remota_${caminhoLimpo.hashCode.abs()}.$ext`). Se o arquivo já existir com tamanho íntegro no aparelho, a resolução é imediata (0.01ms), eliminando completamente tempestades de requisições HTTP, escritas redundantes na memória flash e saturação de I/O a cada atualização de estoque, mesas ou pedidos.
- **Sincronização Leve sem Reconstrução Destrutiva:** Mensagens WebSocket de atualização de loja (`loja_atualizada`) atualizam o estado em memória e persistência através de `adicionarOuAtualizarLoja` sem disparar `entrarComCpf`, prevenindo loops de rebuild total da interface. `entrarComCpf` é acionado exclusivamente na primeira vinculação da referência (`!jaTem`).
- **Isolamento de Tarefas Periódicas em Terminais Móveis:** O timer de verificação periódica de pedidos programados é executado com exclusividade pelo computador balcão (servidor), suspendendo rotinas redundantes de escrita em SQLite nos aparelhos de colaboradores conectados via Wi-Fi.
- **Fechamento e Limpeza de Sockets UDP:** A rotina de busca de servidores via broadcast UDP para consulta de ficha de usuário remoto desativa e fecha explicitamente o socket (`pararDescoberta()`), prevenindo consumo de bateria e vazamento de threads no Android.
- **Unificação Soberana da Identidade por CPF:** O sistema consolida automaticamente uma ficha permanente em `ContasNousService` (`UsuarioNous`) a partir de qualquer interação do cidadão: seja via cadastro de cliente/fornecedor no PDV, membros de loja ou handshake de terminal via Wi-Fi. Ao digitar o CPF no login ou cadastro (`AuthProvider.buscarConta()` e `AssociarCpfView`), o sistema recupera os dados prévios (nome, data de nascimento e foto) e, se o aparelho for reinstalado, consulta o balcão na rede local via REST (`GET /api/usuario?cpf=...`), permitindo auto-login imediato sem exigir preenchimento manual repetitivo.
- **Sincronização da Identidade do Usuário por CPF:** Ao conectar no balcão Wi-Fi, o celular consulta `GET /api/usuario?cpf=...`, baixa a foto de perfil do computador via `/api/imagem` para a pasta local e atualiza o banco SQLite e o `AuthProvider` (`recarregarConta()`), mantendo a mesma foto e dados cadastrais no computador e no celular sob o mesmo CPF.
- **Distribuição Local-First de Atualizações via Wi-Fi:** O computador balcão atua como servidor de distribuição na rede local (expondo `GET /api/versao` e `GET /api/download_apk` transmitindo o APK de `dist/Nous_Android_v1.0.0_Versao_Teste.apk`). O celular móvel ao se conectar compara estritamente a versão e o build (`buildRemota > buildAtual || versaoMaior(versaoRemota, versaoAtual)`). Se for a mesma versão já instalada, o botão e o card de atualização somem imediatamente (`temAtualizacao = false`). Havendo versão superior, acende o botão na `CustomAppBar` e, ao clicar, o app realiza o download dos bytes diretamente in-app com barra de progresso em tempo real, gravando no armazenamento temporário e acionando o assistente nativo de instalação do sistema via `FileProvider` (`MethodChannel("com.nous.app/instalador")` com `instalarApk`), permitindo ao usuário atualizar o aplicativo sem sair para o navegador e sem etapas intermediárias externas. O `AtualizacaoDialog` e o `AtualizacaoService` priorizam a fonte local e protegem o estado `temAtualizacao` e `infoAtualizacao`, impedindo categoricamente que buscas secundárias na internet apaguem ou zerem a notificação do balcão.
- **Identificação Nominal e Handshake de CPF:** Cada terminal conectado envia ao servidor balcão seu `nomeDispositivo` (ex.: *"Celular da Mãe"*), o `cpf` ativo da sessão e o `nomeUsuario`.
- **Autoassociação de Membro da Loja e Prevenção de Referências Órfãs:** Quando um dispositivo conecta ao balcão, o celular transmite seu CPF já no snapshot inicial `GET /api/loja?cpf=...`. O servidor balcão auto-associa imediatamente o membro (`PapelMembro.funcionario`) e retorna o snapshot já contendo o usuário na equipe. No celular (`_vincularLojaSeNecessario`), a loja recebida é persistida atômica e integralmente no cofre do dono original local (`loja.cpfDonoOriginal`) antes do registro da `ReferenciaLoja`, prevenindo que `entrarComCpf` a purge como órfã e fazendo a loja aparecer instantaneamente na tela "Meus Perfis" (`lojasQueParticipo`).
- **Transferência Atômica de Imagens sem Flapping:** O download de mídias remotas (`resolverCaminhoImagem` e `baixarImagemRemota`) realiza a leitura do stream em bytes agregados com gravação atômica direta via `writeAsBytes`, eliminando fechamentos indevidos de sinks (`pipe` duplo) e impedindo quedas/reconexões cíclicas do WebSocket que causavam instabilidade de presenças na interface.
- **Reconhecimento Multi-Dispositivo por CPF e Desduplicação Soberana:** O sistema detecta e agrupa quando o mesmo CPF está acessando a loja através de múltiplos dispositivos simultaneamente (ex.: computador balcão + smartphone pessoal). O sistema previne e purga categoricamente referências redundantes (`ReferenciaLoja`) para a loja do próprio dono, garantindo que a loja nunca seja duplicada na lista de perfis.
- **Propagação em Tempo Real de Papéis e Cargos via WebSocket:** Qualquer alteração de papel (`atualizarPapelMembro`), permissões ou cargos personalizados (`atribuirCargoMembro`, `adicionarCargoLoja`, etc.) realizada no computador balcão é transmitida instantaneamente (`loja_atualizada`) para todos os terminais móveis conectados. As interfaces abertas (`StatusLojaView` e `DadosPerfilView`) re-renderizam imediatamente na hora sem necessidade de reiniciar a aplicação.
- **Rastreamento de Presenças em "Status da Loja":** A tela `StatusLojaView` (Lista de Trabalhadores) exibe em tempo real o status online/offline de cada membro e os dispositivos conectados (computador balcão, smartphones, IPs locais e nomes dos aparelhos).
- **Diálogo Interativo de Autorização de Terminais Móveis no Servidor:** Quando um novo terminal móvel tenta se conectar e sincronizar na loja via Wi-Fi (`GET /api/loja`), o servidor balcão intercepta a requisição e exibe uma janela modal centralizada com alerta sonoro (`_solicitarAutorizacaoTerminal`) contendo os dados do aparelho solicitante (Nome do Aparelho, Nome do Usuário, CPF e IP local). O operador balcão pode **Autorizar** ou **Recusar** o acesso. Em caso de recusa ou expiração do timeout de 30 segundos, o terminal remoto recebe HTTP 403 Forbidden e é impedido de sincronizar dados da loja.
- **Prevenção de Auto-Conexão e Eliminação de Loops WebSocket:** O sistema proíbe categoricamente que o próprio computador que hospeda o servidor balcão se conecte a si mesmo como terminal móvel na aba "Terminal Móvel" do `SincronizacaoRedeDialog`. Isso previne tempestades de ecos e loops infinitos de mensagens WebSocket que travavam a rede local e causavam lentidão extrema nos smartphones.
- **Presença Instantânea do Host Balcão nos Terminais Pareados:** No momento em que o servidor é iniciado no computador balcão, a máquina local é imediatamente listada na lista de terminais pareados com o ícone correspondente (`Icons.desktop_windows_rounded`) e o hostname real (`Platform.localHostname`), tanto na interface do computador quanto nas telas de status dos colaboradores.
- **Sincronização Bidirecional e Persistência Instantânea de Mesas e Comandas:** Aberturas de mesas, inserção/remoção de itens em comandas, transferências e fechamento de contas de mesas realizadas nos smartphones são sincronizadas em tempo real via REST (`POST /api/mesa`) e WebSocket para o computador balcão e vice-versa. O listener `_aoAtualizarPdv` de `DadosPerfilView` monitora e atualiza atômica e instantaneamente o estado `_mesas`, garantindo sincronicidade total entre salão e balcão sem travamentos.
- **Logout Universal e Responsividade no Mobile:** O modal de configurações em `CustomAppBar` implementa rolagem contínua delimitada (`ConstrainedBox` com `maxHeight: 85% da tela` + `SingleChildScrollView`), garantindo que o botão "Sair" permaneça 100% visível e funcional em celulares de qualquer proporção, disparando `_efetuarLogoutPadrao` com desconexão de redes locais e retorno limpo para `LoginView`.
- **Sincronização Bidirecional Soberana de Toda a Loja (`POST /api/loja/atualizar`):** Qualquer alteração realizada em terminal móvel (exclusão de funcionários/membros, alteração de papéis operacionais, cargos personalizados, produtos, categorias, grupos de adicionais, clientes, fornecedores e dados cadastrais da loja) é despachada automaticamente via HTTP `POST /api/loja/atualizar` para o servidor central no computador balcão. O servidor balcão consolida os dados, purga referências de membros removidos no SQLite local (`LojasService.removerReferencia`), atualiza a interface no Windows na hora e transmite via WebSocket (`loja_atualizada`) para todos os outros terminais móveis conectados.
- **Proteção Contra Loops de Rede e Debounce Inteligente:** O `ClienteRedeLocal` possui a flag `aplicandoAtualizacaoRemota` que bloqueia retransmissões circulares ao receber mensagens do WebSocket balcão. Ações do usuário operam com debounce de 150ms para evitar sobrecarga de requisições em alterações contínuas, e despacho imediato prioritário para eventos críticos (ex.: exclusão de membros).
- **Listener Unificado de Tempo Real em `DadosPerfilView` (`_aoAtualizarPdv`):** A tela `DadosPerfilView` monitora ativamente não apenas pedidos e estoque, mas também produtos (`itensLoja`), categorias (`categoriasLoja`), grupos de complementos (`gruposComponentesLoja`), clientes (`clientesLoja`), fornecedores (`fornecedoresLoja`), mesas (`mesas`) e membros da equipe (`membros`), refletindo instantaneamente qualquer mutação ocorrida no balcão ou em outros terminais móveis.
- **Acesso ao Menu de Sincronização Wi-Fi:**
  - **Barra Superior Limpa (`CustomAppBar`):** Contém estritamente Notificações, Atualizações (somente quando houver novidade disponível) e Configurações (engrenagem). Não possui botões fixos de Wi-Fi.
  - **Menu em Configurações:** Na janela "Configurações", acima da "Identidade do Usuário", há o botão em barra com hover `_BarraSincronizacaoWifiSettings` que exibe em tempo real o status de conexão (Servidor Ativo, Conectado ao Balcão ou Desconectado) e abre o `SincronizacaoRedeDialog`.
  - **Ajustes do Perfil:** Permanece acessível também como primeiro item dentro da aba **"Ajustes do Perfil"** (`AbaLoja.interface`).


---

## 6. SISTEMA DE DESIGN E TEMAS (REGRAS MANDATÓRIAS)

### 6.1 AppTheme e ThemeController
- O tema é gerenciado por `AppTheme` e exposto globalmente via `ThemeController.currentTheme` (`ValueNotifier<AppTheme>`).
- **Personalização Soberana e Isolamento por CPF:** O `ThemeController` persiste o tema ativo e a lista de temas salvos individualmente para cada CPF (`carregarTemaDoUsuario(cpf)`). Ao alternar de conta, as preferências de cores, fontes, tamanhos e cor de exclusão do usuário são instantaneamente carregadas. No logout, desvincula e retorna às configurações gerais da máquina.
- **Cor de Exclusão e Alerta (`theme.dangerColor`):** Ações destrutivas e alertas críticos utilizam `theme.dangerColor` (padrão `Color(0xFFFF5252)` - `Colors.redAccent`), configurável pelo usuário na janela "Personalizar Aparência" através de seletor Canva e paleta de cores recentes.

### 6.2 Regras Estritas de Cores
- **PROIBIDO:** Usar cores fixas genéricas (`Colors.white`, `Colors.black`, `Colors.blue`, etc.) diretamente nos layouts.
- **EXCEÇÕES PERMITIDAS:**
  - `Colors.transparent`
  - `theme.dangerColor` (exclusiva para ações destrutivas, exclusões, alertas de quebra e valores de saldo negativo; utilize sempre `theme.dangerColor` ao invés de `Colors.redAccent` fixo).
- **Opacidade Moderna:** Use sempre `theme.backgroundColor.withValues(alpha: 0.4)` ou `theme.borderColor.withValues(alpha: 0.6)`. Nunca use o método legado `.withOpacity()`.
- **Tipografia:**
  - `theme.textColor`: Títulos, cabeçalhos e valores de destaque.
  - `theme.secondaryTextColor`: Subtítulos, rótulos de campos e descrições.

### 6.3 Componentes Visuais Padronizados

| Elemento | Padrão Obrigatório |
| :--- | :--- |
| **Bloco / Card Padrão** | `BoxDecoration(color: theme.backgroundColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)))` |
| **Diálogos / Popups** | **Sempre centralizados** via `showDialog`. Fundo `theme.cardBackgroundColor`, `borderRadius: 16`, títulos centralizados em `theme.textColor`, mensagens explicativas centralizadas e largura máxima de `500` (ou proporcional no desktop). Diálogos com `Flexible` + `SingleChildScrollView` **devem sempre definir** `maxHeight: MediaQuery.sizeOf(ctx).height * 0.90` no `ConstrainedBox` para evitar erro de *unbounded height* no mobile. **Nunca use Bottom Sheets.** |
| **Botões e Ações de Exclusão** | **Padrão Universal:** Botões na tela (como "Excluir Loja", "Excluir Cliente", "Excluir Fornecedor", "Excluir Cadastro" e itens destrutivos de menus popup) exibem o rótulo/ícone em `theme.dangerColor`. Ao serem acionados, **SEMPRE abrem janela de confirmação** (`AlertDialog` centralizado) com botão "Cancelar" neutro (`theme.secondaryTextColor`) e botão de confirmação ("Excluir" / "Remover") destacado em `theme.dangerColor`. |
| **Barras com Hover** | Todo item de lista (membros, fornecedores, clientes, trabalhadores) deve usar o widget de hover com borda contrastante e leve fundo translúcido `theme.borderColor.withValues(alpha: 0.18)` ao passar o cursor. |
| **Listas Vazias** | Use sempre `EstadoVazioContainer(theme: theme, mensagem: '...')`. |
| **Botões de Ação** | No repouso, respeitam o tema (`theme.buttonColor` ou transparente com borda fina `1.0`), **nunca nascendo com o visual de hover ativado**. Respondem dinamicamente ao mouse em hover: fundo translúcido `alpha: 0.18`, borda `1.4` em `textColor` e cursor pointer. |
| **Botões e Seletores com Hover Persistente** | Botões de opção/toggle (impressora, filtros de relatórios, abas da loja, períodos no financeiro, tipo de movimento de estoque, unidades e formas de pagamento) **mantêm destaque visual ativo quando selecionados** e respondem dinamicamente ao mouse em hover: fundo translúcido `alpha: 0.22` (ou `0.35` em hover), borda contrastante `1.6px` em `textColor`, `SystemMouseCursors.click` e fallback para temas escuros. |
| **Botões On/Off (`ThemedSwitch`)** | Interruptores padronizados de alto contraste (`activeThumbColor: theme.textColor`, `activeTrackColor: theme.borderColor.withValues(alpha: 0.45)`, `inactiveThumbColor: theme.secondaryTextColor`, `inactiveTrackColor: Colors.transparent`, `trackOutlineColor: theme.borderColor`), eliminando switches apagados no modo escuro. |
| **Texto Rolante (Marquee Automático)** | `TextoRolante(texto: ..., style: ..., textAlign: TextAlign.start)`. Quando o texto excede a largura disponível (especialmente em telas compactas de smartphones em barras de vendas, pedidos programados, ações de auditoria, detalhes de pagamentos e títulos), ativa automaticamente deslizamento da direita para a esquerda com gradiente suave nas bordas, garantindo leitura integral de 100% das informações sem deformar a altura de cards e barras. Quando o texto cabe na largura, opera com custo zero como `Text` estático. |

### 6.4 Ecossistema de Imagens e Continuidade Visual Estrita
- **Proibição de Elementos Fictícios:** Se um componente visual possui espaço para avatar ou imagem, ela **NUNCA é meramente decorativa**. Deve ser persistida, vinculada ao modelo e exibida em todas as telas que representam aquela entidade.
- **Sem Ícones Estáticos Enganosos:** Nunca exiba `Icon(Icons.account_circle)` estático onde há fotos ou CPF associado. Sempre renderize `CircleAvatar` com `FileImage` da imagem real e utilize o ícone nativo apenas como fallback limpo caso a foto inexista.
- **Sem Sobreposições Sujas:** Nunca sobreponha ícones secundários (canetinhas de edição `Icons.edit` ou câmeras flutuantes) sobre avatares ou imagens de formulários.
- **Intermediação via OpcoesImagemDialog:**
  - Se o campo contém imagem: o clique abre `OpcoesImagemDialog.mostrar(...)` ("Procurar nova imagem", "Retirar imagem", "Cancelar").
  - Se o campo está vazio: o clique abre diretamente o seletor de arquivos (`openFile`).
- **Limites e Formatos:** Até 500MB via `ImagemService.salvarImagemLocal` (`jpg`, `jpeg`, `png`, `webp`).
- **Visualizador de Mídias e Anexos Soberanos:**
  - **Cards de Anexos Ampliados com Prévia Visual Rica (`GaleriaEstiloContainer`):**
    - Cards ampliados para 156px de altura e 126px de largura, proporcionando ergonomia e leitura clara de cada anexo nos dados do perfil da loja.
    - **Prévias Visuais por Tipo:** Para músicas/áudios com tags ID3 (`MetadadosAudioService`), exibe a imagem real da capa do álbum com badge sonoro, além do título e artista legíveis; para áudios sem capa, gradiente temático com badge da extensão (`.MP3`, `.WAV`); para imagens, foto em alta qualidade; para vídeos, fundo cinematográfico com badge de formato; para documentos, ícone temático com badge (`PDF`, `DOCX`) e tamanho formatado em bytes/KB/MB.
  - **Imagens:** Ao tocar no card em `GaleriaEstiloContainer`, abre `VisualizadorGaleriaDialog` em tela cheia com zoom interativo (`InteractiveViewer`), navegação contínua entre fotos da lista (setas visuais flutuantes, teclado <kbd>ArrowLeft</kbd>/<kbd>ArrowRight</kbd>, arraste `PageView`), contador e barra inferior com descrição persistida em `Loja.descricoesAnexos`.
  - **Navegação Contínua e Playlist em Áudios, Vídeos e Documentos (`DetalhesMidiaDialog` & `ReprodutorAudioWidget`):**
    - Ao abrir qualquer anexo na lista, o modal conecta a coleção inteira de arquivos:
      - Exibe contador de posição no topo (`X / Total`);
      - Botões flutuantes laterais com bordas circulares e sombra (`chevron_left` e `chevron_right`) para passar para o arquivo anterior ou próximo;
      - Atalhos de teclado no desktop (<kbd>ArrowLeft</kbd> e <kbd>ArrowRight</kbd>);
      - Botões dedicados de controle no player de áudio (`skip_previous_rounded` e `skip_next_rounded`);
      - **Autoplay Inteligente:** ao finalizar uma faixa com o player ativo, se houver próxima música na playlist e o loop não estiver ligado, o sistema avança e inicia automaticamente a reprodução da próxima faixa.
  - **Legendas em Anexos:** Ao subir um anexo ou a qualquer momento pelo card/diálogo, o usuário pode adicionar/editar uma descrição persistida no cofre local da loja.

---

## 7. MAPA DO QUE JÁ FUNCIONA E REGRAS ESPECÍFICAS CONSOLIDADAS

### 7.1 Identidade Cidadã e Acesso ao Perfil (`features/auth`)
- **Acesso Exclusivo à Identidade:**
  - **NÃO existe botão de perfil na CustomAppBar.**
  - O único modo de visualizar a janela **"Identidade do Usuário"** dentro da aplicação é tocando no card do usuário dentro do diálogo de **Configurações** (engrenagem no canto superior direito), além da tela pós-login `ContasUsuarioView`.
  - O card da conta em Configurações consolida: Foto do perfil, Nome completo, CPF formatado e **E-mail ativo da sessão**.
- **Dados Pessoais Cidadãos Ampliados:**
  - O modelo `UsuarioNous` armazena e persiste:
    `cpf`, `nome`, `dataNascimento`, `emails`, `foto`, `nomePai`, `nomeMae`, `localNascimento`, `tipoSanguineo` e `estadoCivil`.
  - Na `FichaUsuarioDialog`:
    - O CPF **não se repete** dentro do bloco "Dados Pessoais" (já é exibido com destaque no topo abaixo do nome).
    - O botão **"Editar dados pessoais"** deve ficar **sempre claramente visível e posicionado abaixo de todas as informações pessoais**. Ao clicar, o bloco entra em modo de edição com inputs arredondados e botões "Salvar" e "Cancelar".
  - Sincronização automática bidirecional de fotos entre o CPF da conta e o cadastro de clientes.

### 7.2 Gestão de Lojas, Perfis e Consentimento (`features/pdv` & `features/notificacoes`)
- **Categorias de Perfil Profissional (`_CriarPerfilDialog`):**
  - **`Loja Padrão`:** Varejo comercial em geral (mercearia, papelaria, ferragista) com fluxo ágil de venda direta no balcão.
  - **`Restaurante`:** Especialização para alimentação (cardápio, componentes/adicionais e dinâmica de mesas e comandas abertas).
  - **`Fretes e Viagens`:** Unificação de transporte individual e entregas de mercadorias.
- **Aba "Dados" da Loja:**
  - Exibe estritamente: Formulário de Dados da Loja, **Usuários Participantes** e **Galeria / Anexos**. Containers de Delivery e Dados Bancários permanecem desacoplados desta pré-versão local offline.
- **Consentimento Obrigatório entre Sócios:**
  - Em `dados_perfil_view.dart`, se o usuário tentar alterar o papel de um membro que atualmente é `Sócio`:
    - A alteração **não é aplicada imediatamente**.
    - O sistema cria e envia uma notificação `ConviteLoja` com `TipoNotificacao.alteracaoPapel` para o CPF do sócio alvo.
    - O sócio visualiza no sino: *"Solicitação de [Nome]: Alteração do seu papel em [Loja] para [Novo Papel]"*.
    - Ao **Aceitar**, o papel é atualizado no cofre da loja e em memória. Ao **Recusar**, a notificação é descartada e o papel permanece intacto.
- **Trabalhadores e Membros com Foto e Hover:**
  - **Continuidade de Fotos de Contas Locais:** O `AuthProvider` armazena cache de fotos de todas as contas locais via `ContasNousService.carregarTodas()`. Em "Status da Loja", "Usuários Participantes" e "Registrar Pagamento", a foto é recuperada por `auth.buscarFotoPorCpf(membro.cpf)` com fallback em `pdv.buscarFotoClientePorCpf(membro.cpf)`. A foto de qualquer conta cadastrada na mesma máquina é exibida em todas as telas sem furos.
  - "Status da Loja" -> "Lista de Trabalhadores": cada barra carrega a foto do trabalhador associada ao seu CPF e possui efeito de hover dinâmico.
  - "Usuários Participantes" (Aba Loja): mesma estrutura com miniatura de foto real por CPF e hover.
  - Diálogo de convite de membro (`_ConviteDialog`): ao encontrar a conta pelo CPF, exibe o avatar com a foto da conta encontrada.
  - Pagamento financeiro a trabalhadores (`RegistrarPagamentoDialog`): o seletor dropdown exibe a miniatura redonda com o avatar do trabalhador.
  - "Usar cliente como fornecedor": a lista de clientes exibe a foto real do cliente cadastrado.
- **Cadastro de Clientes com CNPJ ou CPF Adaptável e Autopreenchimento:**
  - O campo de documento em `ClientesDialog` utiliza label `"CNPJ ou CPF"` e o formatador `CpfOuCnpjInputFormatter`. Ele adapta a máscara automaticamente: até 11 dígitos formata como CPF (`000.000.000-00`) e de 12 a 14 dígitos formata como CNPJ (`00.000.000/0000-00`).
  - **Autopreenchimento Local Soberano (`DadosLocaisService`):** Ao preencher o campo com um documento completo (11 ou 14 dígitos), o sistema pesquisa automaticamente nas contas de usuários Nous, nas lojas locais registradas e nos cadastros prévios da máquina. Se encontrar correspondência, autopreencha Nome, Telefone, Endereço, Número, E-mail, Redes Sociais e Foto, exibindo a origem do registro em tela. A busca é unificada: cruza o CPF da conta com cadastros prévios de clientes e com a loja criada pelo próprio titular (por CPF do cofre, e-mails associados e nome), garantindo que dados como telefone e endereço nunca fiquem vazios.
- **Busca Universal Multicampo de Clientes e Fornecedores (`correspondeABusca`):**
  - Nos containers "Clientes Cadastrados" (`ClientesDialog`), "Fornecedores" (`FornecedoresDialog`) e na busca de cliente na Nova Venda (`NovaVendaDialog`), o filtro pesquisa simultaneamente por **qualquer dado da ficha**: nome, rua/logradouro, número do imóvel, CPF/CNPJ (com ou sem pontuação), telefone (com ou sem pontuação), e-mail, redes sociais ou descrição.
  - Permite pesquisar apenas o nome de uma rua para listar imediatamente todos os clientes residentes nela.
- **Container "Cargos e Permissões" (Estilo Discord, `CargosEPermissoesContainer`):**
  - Posicionado acima do container "Usuários Participantes" na aba "Dados do Perfil".
  - Minimizado por padrão com expansão/recolhimento sob clique para preservar a ergonomia visual.
  - Abas horizontais no estilo Discord para cargos nativos (`Dono`, `Sócio`, `Administrador`, `Funcionário`) e novos cargos customizados criados via `+ Novo Cargo`.
  - Transparência radical e Governança Democrática: lista todas as permissões do sistema (`PermissaoLojaConst.todas`) com explicação didática e `ThemedSwitch`.
  - **Soberania dos Fundadores:** Nas abas `Dono` e `Sócio`, os switches permanecem travados com o badge *"Regra fundamental do sistema (inalterável)"*, garantindo a co-gestão plena.
  - **Governança de Cargos Inferiores por Sócios e Donos:** Sócios e Donos têm poder irrestrito para alternar todas as permissões dos cargos inferiores: **Administrador**, **Funcionário** e cargos personalizados criados. As permissões personalizadas dos cargos nativos são persistidas no cofre da loja em `Loja.permissoesCargosNativos` com fallback transparente para os padrões do sistema (`Loja.permissoesPadraoPorPapel`).
  - **Delegação a Administradores e Funcionários:** Se Sócios ou Donos ativarem a permissão *"Gerenciar Membros e Cargos"* (`PermissaoLojaConst.gerenciarMembros`) para Administradores ou Funcionários, estes passam a poder alterar cargos e papéis operacionais de outros membros da equipe (respeitando a proteção inegociável de Donos e Sócios).
  - **Atribuição de Cargos Criados em Membros (`UsuariosParticipantesContainer`):** O diálogo de edição de membros permite selecionar o papel operacional e vincular diretamente qualquer cargo criado (`Loja.cargosPersonalizados` via `vincularCargoAoMembro`), com identificação clara no subtítulo do membro.
- **Atalho Universal de Tela Cheia (<kbd>F11</kbd>):**
  - Gerenciado no nível de hardware nativo em `main.dart` via `HardwareKeyboard.instance.addHandler`.
  - Alterna instantaneamente o modo de tela cheia nativo do Windows em qualquer ponto da aplicação, seja no modo compacto (para celulares), no modo desktop expandido, na tela de login ou com qualquer diálogo/popup aberto.
  - **Separação Clara de Responsabilidades:** O <kbd>F11</kbd> é estritamente para tela cheia. O único modo de alternar entre o modo compacto e o modo desktop é pelas configurações através do botão "Ajustes" da loja (aba Ajustes/Interface).

### 7.3 Fluxo de Venda, Comandas e Estoque
- **Reordenação Fluida por Pressão sem Alça de Arraste (Loja do Perfil):**
  - Na tela "Loja do Perfil", usuários com permissão (`possoEditarAbaLoja`) podem segurar por 1 segundo (`LongPressDraggable` com `delay: const Duration(seconds: 1)` e `dragAnchorStrategy: pointerDragAnchorStrategy`) qualquer card ou barra para reordenar:
    - **Categorias** (lista vertical com `DragTarget<int>` e `AnimatedSize` de 250ms abrindo caminho suave para baixo);
    - **Grupos de Componentes** (lista vertical com `DragTarget<int>` e `AnimatedSize` de 250ms abrindo caminho suave para baixo);
    - **Produtos** (no modo compacto horizontal e no modo expandido em Wrap com `DragTarget<int>` e `AnimatedSize` abrindo slot com contorno do tema e empurrando os itens vizinhos para o lado).
  - **Proibição Estrita de GlobalKey em Itens Reordenáveis:** É mandatório usar `ValueKey('cat_${id}')` e `ValueKey('grp_${id}')`. O uso de `GlobalKey` em widgets dentro de `LongPressDraggable` é proibido pois duplica a chave no overlay de feedback do Flutter e causa travamento imediato (`Duplicate GlobalKey detected`).
  - Ao soltar o card/barra, ele se encaixa no slot aberto e a nova ordem é salva imediatamente no cofre da loja (`_persistirListasLoja`).
- Itens vendidos (`ItemVendido`) guardam a foto do produto, garantindo miniaturas na vitrine, no carrinho, na busca, nas abas de gestão (`Novos`, `Aceitos`, `Concluídos`, `Cancelados`) e nas comandas (`ComandaPedido` e `PedidoAceitoDialog`).
- Suporte a pagamentos múltiplos (`List<PagamentoParcial>`) acessados prioritariamente via getter `pedido.todosPagamentos`.
- Impressão térmica padrão de 58mm e 80mm gerada em PDF via `ImpressaoService`.
- Controle de estoque com unidades (`un`, `g`, `ml`) e baixa automática sugerida (`BaixaEstoqueDialog`) com ajuste humano obrigatório.
- **Modo Balcão / Frente de Caixa Profissional (`ModoBalcaoWidget`):**
  - **Venda Avulsa vs. Categorizada:** Ao registrar ou selecionar um item na aba "Todos" (ou por busca/bipador avulso), o sistema cobra estritamente o preço base do produto (ex: copo avulso por R$ 2,00). O valor da categoria só é somado se o operador tiver selecionado previamente a categoria correspondente (ex: Categoria Açaí R$ 17,00 + Copo R$ 2,00 = R$ 19,00).
  - **Campo "Frete" no Operador do Balcão:** Posicionado estrategicamente acima de "Acrésc:", permitindo lançar valor de entrega/frete que é somado ao total geral do pedido, registrado no cofre da loja (`PedidoLoja.frete`) e discriminado na comanda térmica.
- **Caixa do Balcão e Detalhes de Turnos Fechados (`CaixaDialog` & `DetalhesTurnoCaixaDialog`):**
  - **Barra de Turnos com Hover e Acesso Rápido:** Na listagem de "Últimos Turnos Fechados" em `CaixaDialog`, cada barra responde dinamicamente ao mouse em hover (borda contrastante e fundo `theme.borderColor.withValues(alpha: 0.18)`), exibindo tooltip explicativo e seta indicadora. O clique na barra abre a janela dedicada `DetalhesTurnoCaixaDialog`, enquanto o botão de impressão rápido permanece independente.
  - **Operadores com Foto e Duração:** Identifica quem abriu e quem fechou o turno com foto real do perfil por CPF (via `AuthProvider` / `PdvProvider`), nome, CPF formatado, horários e duração total calculada do turno, além de observação de fechamento.
  - **Resumo Financeiro e Conferência:** Apresenta fundo inicial, total de vendas por forma (Dinheiro, Eletrônico/Cartão, À Prazo), suprimentos, sangrias, saldo esperado em caixa vs. saldo informado e divergência (quebra/falta em `Colors.redAccent` ou sobra/exato).
  - **Histórico de Movimentações (Retiradas e Entradas):** Aba dedicada listando detalhadamente quem retirou/inseriu dinheiro (foto, nome e CPF do autor), horário, motivo/justificativa e valor.
  - **Histórico de Vendas do Turno:** Aba listando todos os pedidos realizados no período do turno com cliente, forma de pagamento e total.
  - **Apagar Registro do Turno:** Botão destrutivo "Apagar Registro" com confirmação segura contra cliques acidentais. Ao confirmar, remove o turno do cofre da loja (`PdvProvider.excluirTurnoCaixa`), salva a alteração, registra ação de auditoria (`TipoAcao.turnoCaixaExcluido`) e atualiza reativamente a interface em tempo real.
- **Leitor de Código de Barras e Bipador Rápido:**
  - O modelo `ItemLoja` armazena `codigoBarras` e `precoCusto`.
  - No diálogo `NovaVendaDialog`, a busca aceita leitores de código de barras USB (bipadores). Ao pressionar Enter ou bipar o código exato, o item é adicionado imediatamente ao carrinho e o campo é limpo para a próxima leitura.
  - O catálogo de produtos na venda exibe os itens cadastrados sem limites artificiais de exibição (`take(4)`/`take(3)` removidos), permitindo rolagem fluida.
- **Estoque em Tempo Real e Prioridade para Categorias (`NovaVendaDialog`):**
  - Cada item exibe o saldo de estoque real atualizado (`Est: X un` ou badge vermelho `Esgotado` quando $\le 0$).
  - **Ordem de Preferência na Abertura:** Ao abrir a janela de Nova Venda (busca em branco), o container "Produto Solicitado" renderiza **primeiro todas as categorias disponíveis** e, logo abaixo, os itens soltos, permitindo acesso rápido a grupos de produtos.
- **Busca Rápida de Pedidos em "Concluídos" e "Cancelados" (`GestaoLojaContainer`):**
  - Campo de busca no topo das abas "Concluídos" e "Cancelados" filtrando instantaneamente por número do pedido (`#0001`), cliente, produto ou descrição de itens com limpeza ágil e estado vazio contextualizado.
- **Controle de Estoque e Cálculo de Custos Unitários (`MovimentoEstoqueDialog` e `NovoItemDialog`):**
  - **Custo Unitário e Persistência Universal:** Ao registrar uma entrada de estoque informando quantidade e custo total da compra (ex: 50 copos por R$ 35,00 = R$ 0,70/un), o sistema persiste o custo unitário calculado no cadastro do item (`precoCusto`), garantindo sincronização e exibição imediata na janela "Editar Item". A tela de edição também exibe bloco visual dedicado com o "Custo Unitário da Última Compra".
  - **Estoque Inicial na Criação Rápida de Produto (`NovaVendaDialog`):** Quando um item é cadastrado rapidamente pelo botão de adição na tela de Nova Venda com saldo inicial de estoque, o sistema gera e persiste automaticamente o `MovimentoEstoque.ajuste` de entrada correspondente, garantindo integridade de estoque idêntica ao cadastro pela aba de produtos.
  - **Variantes em Comandas de Restaurante (`AdicionarItemMesaDialog`):** Ao lançar um produto na mesa ou comanda aberta, o sistema disponibiliza seletor interativo de variantes ("Padrão" e variantes cadastradas com badge de preço), calculando o valor exato no pedido e persistindo `varianteNome` em `ItemVendido`.
  - **Estorno Integral em Cancelamento de Pedidos (`_cancelarPedidoComDialog`):** Ao cancelar um pedido, o estorno de estoque devolve a quantidade real ponderada pela receita cadastrada (`quantidade * consumoPorVenda`) e estorna recursivamente todos os acompanhamentos/componentes selecionados na venda.
  - **Baixa de Estoque Proporcional no Fechamento de Mesas (`_fecharContaMesa`):** Ao fechar a conta da mesa, o sistema calcula a baixa considerando o consumo real da unidade de medida do produto (`item.quantidade * itemCadastrado.consumoPorVenda`) e a quantidade de cada adicional (`acomp.quantidadePorUnidade * item.quantidade * acompCadastrado.consumoPorVenda`), eliminando baixas truncadas em produtos fracionados (g/ml).
- **Aba "Ajustes" e "Ajustes do Perfil" (`AbaLoja.interface`):**
    - **Container "Modo de Visualização e Layout do PDV":** Card único e limpo (`SeletorLayoutsDesktopWidget`) permitindo alternar unicamente entre o **Layout Desktop PDV Expandido** (com barra lateral de navegação e comandos) e o **Layout Compacto Padrão**. A alternância de layout é uma preferência da máquina local e permanece sempre acessível ao operador no desktop, sem depender de permissões de dono da loja. A alternância altera estritamente a disposição visual dos painéis da aplicação, **sem alterar ou interferir no estado de tela cheia (Full Screen)**, que é gerenciado de forma independente pela tecla <kbd>F11</kbd>.
    - **Modo Somente Leitura e Normalização de CPF nos Ajustes:**
      - **Normalização Soberana de CPF (`PdvProvider._mesmoCpf`):** Elimina falhas de reconhecimento de membros/donos decorrentes de divergências de máscara (com vs sem pontuação) entre máquinas ou backups, assegurando que `meuMembro`, `lojasQueAdministro`, `lojasQueParticipo` e `sairDaLoja` operem sem falsos negativos.
      - **Feedback Visual Claro de Permissões:** Quando um usuário sem permissão de dono/sócio abre "Ajustes do Perfil", a tela exibe um banner explicativo com cadeado informando o modo somente leitura, e atenua a opacidade dos seletores (`0.65`) junto ao `AbsorbPointer`, eliminando a impressão de botões travados ou bugados.
    - **Blindagem do Ecossistema de Áudio e Metadados:**
      - **Escape Seguro no Windows (`SomService`):** Ao tocar arquivos pelo PowerShell, utiliza `file.uri.toString()` codificada em `[System.Uri]::new(...)`, prevenindo erros de execução com colchetes `[...]`, apóstrofos, acentos e caracteres especiais no nome dos arquivos.
      - **Proteção Defensiva em `MetadadosAudioService`:** Parsing de tags ID3v2 com fechamento garantido de `RandomAccessFile` em `finally`, tratamento estrito de exceções em `_buscarCapaNaPasta` e normalização universal de separadores de caminho (`RegExp(r'[\\/]')`) em todo o sistema.
    - **Container "Financeiro do Perfil" (`dados_perfil_view.dart` - `AbaLoja.interface`):**
      - Concentra operações e manutenções financeiras do perfil profissional.
      - **Reset de Registros de Transações:** Botão com confirmação segura e alerta (`Colors.redAccent`) para limpar o histórico de vendas, caixas e pagamentos a trabalhadores mantendo catálogo de produtos, clientes e membros intactos.
      - **Governança Estrita:** Liberado nativamente para Donos e Sócios, e acessível a outros papéis/cargos mediante a permissão `PermissaoLojaConst.resetarTransacoes`.
    - **Filtros de Data Ergonômicos e Práticos do Dia a Dia:**
      - **Navegação com 1 Clique (`<` e `>`):** Botões nas laterais de cada campo de data para avançar ou recuar dia a dia sem apagar o texto.
      - **Seletor de Calendário Nativo Temático:** Ícone de calendário (`showDatePicker`) em `financeiro_view.dart` e `relatorios_dialog.dart` integrado ao tema ativo.
      - **Correção de Cursor no `_DataInputFormatter`:** O cursor não é mais empurrado para o final da string ao editar caracteres no meio da data.
    - **Módulo Financeiro Ampliado (`financeiro_view.dart`):**
      - **Container "Resumo Operacional do Dia / Contexto":** Posicionado como o **primeiro container da página** (logo abaixo da barra de ações e do menu de filtro de período), acompanhando dinamicamente o período ou data de contexto selecionada (Hoje, dia único selecionado com navegação `<` e `>`, ou período geral). Consolida Faturamento, Vendas, Ticket Médio, Saldo em Dinheiro do Caixa e badge de status (aberto/fechado com base no período).
      - **Container "Vendas do Período":** Exibido na coluna 2 abaixo de "Compras do Período", contendo busca de vendas por texto, filtros de forma de pagamento e lista de `BarraVenda` com altura delimitada.
    - **Tela Cheia Real do Windows via FFI (`JanelaWindowsService` e Tecla <kbd>F11</kbd>):**
      - A tecla <kbd>F11</kbd> é a tecla padrão fixa do sistema e não pode ser reconfigurada: ela alterna exclusivamente o modo **Full Screen** (tela cheia sem bordas `WS_POPUP` cobrindo 100% da tela do Windows).
      - **Preservação de Janela Maximizada:** Ao ativar tela cheia, o sistema detecta se a janela do Windows já estava maximizada (`IsZoomed` da `user32.dll`). Ao desativar o <kbd>F11</kbd>, se a janela estava maximizada, o Windows a restaura fielmente no estado **maximizado** (`ShowWindow(SW_MAXIMIZE)`), sem reduzi-la para tamanho menor. Se não estava maximizada, restaura para as coordenadas e dimensões livres anteriores (`SW_RESTORE`).
      - O <kbd>F11</kbd> opera de forma totalmente independente do layout (funciona tanto no layout compacto quanto no layout expandido).
    - **Barra Superior (`CustomAppBar`):**
      - Exibe o título da aba/tela centralizado, a seta de retorno (quando aplicável) e, no canto direito:
        - Sino de **Notificações**.
        - Botão de **Atualizações de Versão** (`_botaoAtualizacoes`): exibido reativamente com indicador visual vermelho **apenas se houver uma nova versão disponível** do aplicativo via `AtualizacaoService.temAtualizacao`.
        - Engrenagem de **Configurações**.
    - **Moldura Desktop Soberana (`DesktopSidebarWidget`) e Ocultação de Botões Redundantes:**
      - Quando o layout expandido está ativo, a aplicação exibe a **Barra Lateral Fixa à Esquerda**:
        - **Identidade:** logo real da loja, nome e indicador em tempo real do status do caixa (aberto/fechado).
        - **Módulos do PDV ordenados estritamente de cima para baixo:**
          1. **"Dados da Loja"** (`AbaLoja.dados`)
          2. **"Ajustes do Perfil"** (`AbaLoja.interface`)
          3. **"Loja / Catálogo"** (`AbaLoja.loja`)
          4. **"Gestão de Pedidos"** (`AbaLoja.gestao`)
        - **Comandos Rápidos e Acompanhamento Dinâmico de Teclas:**
          - Os atalhos padrão nascem com todas as teclas desativadas para autonomia total do usuário.
          - Cada botão de comando rápido reflete dinamicamente a tecla configurada em "Ajustes do Perfil" -> "Comandos do Teclado" (`loja.atalhosTeclado`).
          - Se a função estiver configurada com uma tecla (ex: `F1`), a prévia exibe o badge estilizado com a identificação da tecla.
          - Se a função estiver **Desativada**, exibe apenas o **pequeno quadrado elegante sem identificação textual** (22x18px), mantendo o alinhamento visual perfeito.
          - O clique via mouse em qualquer botão da barra lateral aciona a ação correspondente imediatamente, independente de haver tecla associada.
      - Na tela "Gestão do Perfil" (`GestaoLojaContainer`), os botões de ação do topo ("Nova Venda", "Clientes", "Impressora", "Relatórios", "Caixa", "Financeiro", "Mensagens", "Status da Loja") são **automaticamente ocultados no modo expandido**, pois já estão acessíveis de forma permanente na barra lateral, eliminando redundância visual e aproveitando melhor o espaço de comandas e pedidos. No modo compacto, os botões permanecem visíveis.
      - O catálogo de produtos e itens (`ItemLojaCard`) conta com altura e largura delimitadas, eliminando o erro de *unbounded height* no motor do Flutter e garantindo rolagem fluida e estabilidade absoluta.
    - **Adaptação Responsiva Mobile vs. Desktop e Modo Compacto Fixo no Celular:**
      - **Modo Compacto Mandatório no Celular:** Em dispositivos móveis (Android e iOS), o Nous opera com modo compacto por padrão e exclusivo (`PdvProvider.layoutDesktopAtivo` retorna `false`). Na tela de "Ajustes do Perfil" -> "Modo de Visualização e Layout do PDV", o usuário do celular é apresentado a um card informativo indicando o modo compacto ativo, **sem a opção de mudar para o modo desktop expandido**.
      - **Autonomia no Desktop:** Em computadores (Windows, Linux, macOS), o usuário mantém autonomia para alternar livremente entre layout compacto e layout expandido. O seletor de layout é construído com `LayoutBuilder` elástico, impedindo que textos quebrem na vertical caso a janela seja redimensionada.
      - **TextoRolante Universal (Efeito Marquee da Direita para a Esquerda):** Qualquer nome ou texto que exceda a largura útil do seu container desliza suavemente da direita para a esquerda com pausas nas bordas e máscara de gradiente, abrangendo nomes de itens, categorias, grupos de componentes, clientes, fornecedores, mesas, comandas, pedidos programados e cabeçalhos.
      - **Ergonomia e Prevenção de Quebras em Telas Pequenas (< 520px):**
        - A barra de ações da loja (`_barraDeAcoesLoja`) organiza os botões em `Wrap` 2x2 com rótulos compactos ("Novo Grupo") em telas estreitas, prevenindo cortes textuais.
        - As teclas de atalho de teclado F1–F12 organizam-se em 1 coluna confortável em telas móveis, com `TextoRolante` no rótulo da tecla F11.
        - O cabeçalho de Mesas e Comandas (`MesasContainer`) aloca o título e o badge em coluna flexível com `TextoRolante`, eliminando sobreposições com o botão "+ Nova Mesa".
    - **Altura Dinâmica de Categorias e Grupos de Componentes no Desktop:**
      - No modo Desktop (`MediaQuery.sizeOf(context).width > 720` ou `layoutExpandido`), as listas verticais de "Categorias" e "Grupos de Componentes" em `dados_perfil_view.dart` comportam até 7 ou 8 barras completas (`maxHeight: 440.0`) antes de habilitar a rolagem interna suave, preenchendo harmonicamente a altura da tela sem acionar o scroll da página. No modo mobile/compacto, mantém limite ergonômico de 180.0.
    - **Reorganização, Container Unificado e Modo Expandido de `NovoItemDialog`:**
      - **Disposição Estrita dos Campos:**
        1. **Foto** (espaço de fotos com recorte/ajuste e seleção);
        2. **Nome do Item**;
        3. **Descrição do Item Minimizada** (bloco expansível com prévia da primeira linha e chevron de recolhimento);
        4. **Tipo do Item** (seletor moderno com hover persistente e indicador entre Produto e Serviço);
        5. **Preço de Venda**;
        6. **Barras de Seleção** (Categorias do Item e Grupos de Componente);
        7. **Variantes** (lista de variantes cadastradas e botão "Adicionar variante");
        8. **Código de Barras / EAN**;
        9. **Botões de Unidade de Medida** (`un`, `g`, `ml`);
        10. **Consumo por Venda** (na unidade base);
        11. **Container Unificado "Estoque e Preço de Custo":** unifica estoque atual com badge de saldo, campo de ajuste/inicial, estoque mínimo, botão de "Lançar Movimento Detalhado" e bloco de custo de compra com cálculo unitário e margem bruta estimada;
        12. **Delivery** (ThemedSwitch com campos condicionais de frete grátis e km).
      - **Adaptação Estrita aos Ajustes do Perfil:** A janela obedece exclusivamente à configuração de layout da loja definida em "Ajustes do Perfil". Quando o **Layout Desktop PDV Expandido** está ativado, a janela abre no formato expandido em duas colunas ergonômicas (~740px de largura). Quando o **Layout Compacto Padrão** está ativado (ou em telas de celulares), a janela abre estritamente no formato compacto em coluna única (~380px de largura), sem botões soltos ou redundantes no cabeçalho.
    - **Modo Balcão (Frente de Caixa Profissional de Alto Desempenho):**
      - **Acesso:** Comando rápido dedicado "Modo Balcão" na barra lateral desktop (`DesktopSidebarWidget`) abaixo de "Status da Loja", com tecla de atalho configurável e clique via mouse.
      - **Tela Imersiva (`ModoBalcaoWidget`):** Ocupa 100% da área do PDV dividida em 2 grandes setores de alta visibilidade ergonômica:
        - **Área do Operador (Esquerda):**
          - Campo bipador/leitor de código de barras USB de resposta instantânea com foco persistente após cada bipada ou clique;
          - Visor panorâmico do último produto registrado com foto real, quantidade, nome com categoria e valor unitário somado;
          - Catálogo visual com navegação por categorias, miniaturas reais, badges de saldo em estoque formatado de forma adaptável e aviso de esgotado, com cálculo e nomeação automática da categoria no item vendido (`nomeCategoria`, `precoCategoria`, `nomeExibicao` e `precoUnitario`);
          - Seção de vinculação interativa de clientes (`_buildSecaoClienteEAjustes`): painel flutuante de busca instantânea multicampo (`_sugestoesClientes`) com avatares, CPF/CNPJ, telefone e endereço, e chip visual do cliente selecionado com botão de desvinculação ágil.
        - **Área da Comanda Ampliada (Direita), Grupos de Componentes e Observações:**
          - Comanda ampliada para facilitar a leitura simultânea do cliente e do operador no balcão, exibindo o nome completo com categoria e variante (`nomeExibicao`) e preço unitário somado;
          - **Suporte a Grupos de Componentes / Adicionais e Observações do Item:** Para cada item adicionado na comanda do balcão, o sistema exibe resumo dos adicionais escolhidos (`item.acompanhamentos`), a observação em itálico (`Obs: ...`) e botões interativos `+ Componentes` e `+ Observação` (ou `Editar Obs`). Ao clicar em `+ Componentes`, abre diálogo para ajustar componentes e campo direto para observação. O botão `+ Observação` abre modal rápido para inclusão ou edição de observações mesmo em itens sem grupos de componentes cadastrados. A observação é integrada fielmente na comanda impressa (`_montarComanda`);
          - Controles ergonômicos de quantidade (+ / - / remover) para cada item;
          - Campos de Desconto e Acréscimo monetário com cálculo instantâneo;
          - Bloco de **TOTAL GERAL GIGANTE** com alto contraste temático;
          - Seletor de formas de pagamento (Dinheiro, Pix, Débito, Crédito, À Prazo) com campo de valor recebido e visor de troco destacado em verde;
          - Botão gigante de "FINALIZAR VENDA (ENTER)" integrado a baixas automáticas de estoque e diálogo de cupom térmico (`VendaConcluidaDialog`);
          - Botão no topo e tecla <kbd>Esc</kbd> para retornar à navegação normal do PDV a qualquer momento.
      - **Seleção e Persistência de Variantes em Qualquer Layout (`NovaVendaDialog` e `ModoBalcaoWidget`):**
        - Ao selecionar, clicar ou bipar um produto que possua variantes cadastradas (`ItemLoja.variantes`), o sistema abre modal de seleção (`_selecionarVarianteDialog`), apresentando a opção "Padrão" e a lista de variantes com seus respectivos preços específicos (ex: "Copo 400ml" com variante "Isopor" a R$ 4,50).
        - O item vendido (`ItemVendido`) persiste `varianteNome` no banco de dados SQLite e JSON, formatando o nome de exibição como `Nome ($varianteNome)` no carrinho, na comanda, nos relatórios gerenciais e na impressão de cupons térmicos.
        - Os rascunhos de venda (`_ItemRascunho`) preservam as variantes selecionadas caso o operador alterne de tela.
      - **Ajuste e Recorte de Imagens com Confirmação Segura de Exclusão (`AjustarImagemDialog`):**
        - **Recorte e Enquadramento Visual:** Ferramenta nativa em Flutter com zoom interativo (`InteractiveViewer`), botões de ampliação (+ / - / reset) e captura de alta definição via `RenderRepaintBoundary.toImage(pixelRatio: 2.5)` salvando o corte em PNG. Disponível no cadastro e edição de itens (`NovoItemDialog`) e na galeria de anexos da loja (`GaleriaEstiloContainer`).
        - **Segurança contra Exclusão Acidental:** Ao clicar no botão de fechar ("X") em fotos de itens ou anexos de mídia, o sistema exibe diálogo de confirmação ("Tem certeza de que deseja retirar esta imagem?"), impedindo a perda imediata de arquivos por clique involuntário.
      - **Máscara e Formatação Adaptável de Unidades de Medida (`formatarQuantidadeComUnidade`):**
        - O sistema formata automaticamente volumes e pesos para a unidade mais intuitiva quando os valores forem grandes:
          - $\ge 1000\text{g} \rightarrow \text{kg}$ (ex: $1000\text{g} \rightarrow 1\text{ kg}$, $1500\text{g} \rightarrow 1,5\text{ kg}$, $2250\text{g} \rightarrow 2,25\text{ kg}$);
          - $\ge 1000\text{ml} \rightarrow \text{L}$ (ex: $1000\text{ml} \rightarrow 1\text{ L}$, $1500\text{ml} \rightarrow 1,5\text{ L}$);
          - Valores menores ou contagens em `un` mantêm sua unidade base ($500\text{ g}$, $350\text{ ml}$, $10\text{ un}$);
          - Saldos negativos preservam o sinal com a conversão apropriada ($-1000\text{g} \rightarrow -1\text{ kg}$).
      - **Badge de Saldo de Estoque e Esgotado nos Cards de Produto (`ItemLojaCard`):**
        - No catálogo de produtos do PDV (tanto no layout expandido desktop quanto no layout compacto), os cards de item exibem badge no topo da imagem com o saldo atual formatado de forma adaptável (`Est: X`) ou o badge de alerta `Esgotado` em vermelho quando o saldo for $\le 0$.
      - **Ajuste de Unidade de Medida no "Movimento de Estoque" (`MovimentoEstoqueDialog`):**
        - No container "Dados do cadastro do item", a seção de ajustes rápidos permite alterar o preço de venda, código de barras e também selecionar diretamente a unidade de medida do item (`un`, `g`, `ml`), sincronizando os rótulos do diálogo e persistindo a alteração no cadastro do produto.
      - **Container "Clientes Cadastrados" com Altura Adaptável (`ClientesDialog`):**
        - Em modo desktop expandido (duas colunas), a lista de clientes cadastrados possui altura ampliada (`maxHeight: 490px`), acompanhando o tamanho do formulário "Novo Cliente" vizinho sem ativar rolagem prematura em 3 clientes. No layout padrão compacto, preserva a altura de 200px para ergonomia na visualização em coluna única.
      - **Handler Global do Atalho F11:** Registro de listener no motor do framework via `HardwareKeyboard.instance.addHandler` tanto em `DadosPerfilView` quanto em `ModoBalcaoWidget`, garantindo que o atalho <kbd>F11</kbd> funcione de forma ininterrupta dentro do modo balcão e após o retorno à navegação padrão, sem perda de foco.
      - **Retorno e Edição Segura em `VendaConcluidaDialog`:** Adicionados botões dedicados de "Voltar" (no topo à esquerda e na barra inferior de ações) e opção amigável "Voltar para edição" no diálogo de confirmação, permitindo que o lojista retorne para a comanda ou para o balcão com todos os produtos, quantidades e pagamentos preservados caso queira corrigir algo antes de efetivar.
    - **Instalador Oficial Windows (`dist/Nous_Instalador_v1.0.0_Versao_Teste.exe`):**
      - Script automatizado PowerShell `scripts\gerar_instalador.ps1` realiza a compilação Release nativa e invoca o Inno Setup Compiler (`ISCC.exe`), gerando o instalador executável completo com ícones, dependências C++ e SQLite integradas.
    - **Diálogos Operacionais Ampliados e Reativos (`NovaVendaDialog`, `ClientesDialog`, `CaixaDialog`, `RelatoriosDialog`, `FornecedoresDialog`, `ImpressoraDialog`):**
      - Todas as janelas operacionais acompanham a nova configuração desktop:
        - **`Nova Venda`:** Em modo expandido, amplia sua largura para até 1150px e distribui os blocos em **duas colunas paralelas** (Catálogo de produtos e leitor de código de barras à esquerda; cliente, carrinho, descontos, pagamento e conclusão à direita).
        - **`Clientes`:** Amplia para 1050px e exibe lista com busca à esquerda e formulário de cadastro à direita (ou formulário/dívidas à esquerda e histórico à direita durante edição).
        - **`Caixa do Balcão`:** Amplia para 1050px e exibe abertura/turno atual à esquerda e histórico de turnos fechados à direita.
        - **`Relatórios`:** Amplia para 1050px e divide filtros/pendências à esquerda e histórico de ações à direita.
        - **`Fornecedores`:** Amplia para 1050px e exibe lista e clientes vinculados à esquerda e cadastro à direita.
        - **`Impressora`:** Amplia para até 1050px e divide em **duas colunas paralelas**: coluna 1 com conexão, largura da bobina (58mm/80mm), tipografia e calibração; coluna 2 com dados da loja/cliente no recibo, automações, rodapé e botões de teste/salvar.
        - **Atalho F11 Reativo:** Todas as janelas operacionais capturam a tecla <kbd>F11</kbd> em tempo real via `CallbackShortcuts` alternando a tela cheia do Windows via `JanelaWindowsService.alternarTelaCheia()`.
    - **Persistência Global da Experiência Desktop em Todas as Telas:**
      - O layout expandido e a tecla <kbd>F11</kbd> funcionam em:
        - `DadosPerfilView`: Moldura com sidebar à esquerda e área de trabalho em tela cheia à direita;
        - `FinanceiroView`: Organização automática em duas colunas amplas (ações, período e balanço à esquerda; compras e trabalhadores à direita);
        - `StatusLojaView`: Divisão em duas colunas amplas (resumo do dia à esquerda; trabalhadores e membros à direita);
        - `PerfisPdvView`: Distribuição dos perfis profissionais e participações em grid de duas colunas.
    - **Container "Comandos":**
      - Gerenciamento de teclas de atalho (<kbd>F1</kbd> a <kbd>F12</kbd>) organizadas em **duas colunas lado a lado** (F1–F6 e F7–F12).
      - **Padrão Inicial Desativado:** Todas as teclas configuráveis (<kbd>F1</kbd> a <kbd>F10</kbd> e <kbd>F12</kbd>) iniciam categoricamente como **"Desativado"**, cabendo ao usuário configurá-las manualmente segundo sua preferência de operação.
      - **Tecla <kbd>F11</kbd> Fixa:** A tecla <kbd>F11</kbd> é reservada e fixa como *"Tela Cheia (Padrão do Sistema)"*, com indicador visual "Fixo" e bloqueio contra alteração indevida.
      - A tecla <kbd>Esc</kbd> permanece fixa no topo ("Voltar / Fechar Janelas").
    - **Container "Tempo de Conclusão dos Pedidos":** Título centralizado, definindo tempo de conclusão automática ou manual.
    - **Container "Sons e Alertas do Sistema":** Título centralizado com catálogo de 9 efeitos sonoros nativos registrados em `assets/sounds` (`SomService.sonsNativos`), botão de teste/preview sonoro imediato e seleção por tipo de evento.
- **Player Interno de Áudio Soberano, Metadados ID3 e Reprodutor Visual Moderno (`PlayerAudioService`, `MetadadosAudioService` & `ReprodutorAudioWidget`):**
  - **Saída de Som Física Confiável:** Reprodução nativa via Microsoft Media Foundation (`audioplayers`), garantindo que o som saia com fidelidade nos autofalantes e fones do computador em Windows 10/11, sem problemas de direcionamento de canais do MCI legado.
  - **Extração Soberana de Metadados e Capas ID3v2 (`MetadadosAudioService`):** Parser puro em Dart que lê tags de arquivos MP3/áudio, extraindo bytes de capa de álbum incorporadas (frames `APIC` JPEG/PNG), título, artista e álbum, com fallback para busca de imagem na pasta do arquivo (`cover.jpg`, etc.).
  - **Componente Reutilizável de SuperApp (`ReprodutorAudioWidget`):** Widget desacoplado com padrão visual contemporâneo (inspirado nos melhores elementos de plataformas como Spotify, SoundCloud e YouTube Music):
    - Fundo imersivo com imagem da capa do áudio translúcida em baixa opacidade;
    - Miniatura quadrada com cantos arredondados, sombra e badge dinâmico "TOCANDO";
    - Barra de progresso deslizante contínua (seek bar) com minutos e segundos decorridos/totais;
    - Controle de volume contínuo com slider e botão de silenciar (mute) e restauração rápida;
    - Controles de reprodução: Play/Pause circular em destaque de tema, pular/voltar 10 segundos, repetição contínua (loop) e botão de parada total.
    - Totalmente desacoplado para ser reutilizado em qualquer tela de rede social, perfis ou anexos da plataforma.
- **Caixa e Fechamento com Discriminação de Vendas À Prazo (`CaixaDialog` e `ImpressaoService`):**
  - O diálogo de Caixa e o cupom de fechamento térmico separam categoricamente:
    - `Vendas em Dinheiro (+)` (entradas na gaveta física).
    - `Vendas Pix / Cartão (+)` (entradas eletrônicas comprovadas).
    - `Vendas à Prazo / Fiado (a receber)` (crédito concedido na sessão, que não compõe saldo de caixa imediato).
    Garante conciliação bancária sem falsas discrepâncias com maquininhas de cartão.
- **Auditoria Interativa de Ações em Relatórios (`RelatoriosDialog` e `_DetalhesAcaoDialog`):**
  - Cada barra na aba "Ações" de Relatórios é interativa (com efeito hover dinâmico, cursor pointer e chevron de navegação).
  - Ao clicar na barra, abre a janela centralizada `_DetalhesAcaoDialog` com data/hora completa, autor (com CPF e e-mail) e descrição detalhada.
  - **Navegação Inteligente:** Se a ação refere-se a um cliente ativo, disponibiliza o botão *"Ver Perfil de [Cliente]"* (abrindo diretamente a ficha do cliente); se refere-se a um pedido ativo, disponibiliza *"Ver Comanda do Pedido #[Nº]"* (abrindo a comanda completa); para exclusões ou dados históricos, exibe nota de auditoria preservada.
- **Ação Imediata ao Clicar em Notificações (`NotificacoesDialog`):**
  - Ao tocar em um alerta de estoque baixo ou esgotado na central de notificações (sino), a janela é fechada e abre imediatamente o diálogo `MovimentoEstoqueDialog` com o item e tipo "Entrada" pré-configurados, permitindo reabastecimento imediato e persistência direta no cofre da loja.
- **Atalhos Globais de Teclado no Desktop (`CallbackShortcuts`):**
  - Teclas <kbd>F1</kbd> a <kbd>F12</kbd> dinâmicas mapeadas para as ações definidas no container "Comandos", além de <kbd>Esc</kbd> para fechar modais e diálogos.
- **Tempo de Conclusão de Pedidos e Alerta Automático:**
  - Campo persistido `tempoConclusaoMinutos` em `Loja` (com atualização em `copyWith`, `toJson`, `fromJson`).
  - Container "Tempo de Conclusão dos Pedidos" na aba "Dados" da loja (abaixo de "Usuários Participantes") permitindo selecionar "Manual" ou tempos pré-definidos (15, 30, 45, 60 min, etc.).
  - Timer periódico na aplicação: pedidos no status `aceito` que ultrapassarem o tempo estipulado disparam janela centralizada perguntando: *"O Pedido #[Nº] já foi concluído?"*, com opções "Ainda não" e "Sim, concluir pedido".
- **Prevenção contra Perda de Vendas (`VendaConcluidaDialog`):**
  - Diálogo protegido com `PopScope(canPop: false)` e barreira não descartável acidentalmente: ao tentar sair ou fechar, abre janela de confirmação de segurança perguntando se o operador deseja salvar a venda ou descartá-la.
- **Ergonomia Visual de Pedidos:** A lista de pedidos na aba "Gestão da Loja" foi ampliada de 260px para 380px para melhor ergonomia de visualização em telas desktop.
- **Cancelamento e Estorno de Pedidos (`CancelarPedidoDialog`):**
  - Pedidos nos status `novo` ou `aceito` podem ser cancelados através do diálogo de confirmação `CancelarPedidoDialog`, informando obrigatoriamente o motivo do cancelamento e permitindo a opção de devolver automaticamente as mercadorias ao estoque.
  - Pedidos cancelados recebem `StatusPedido.cancelado` e são movidos para a aba dedicada **"Cancelados"** na gestão da loja. Eles **nunca são apagados silenciosamente do sistema**, preservando a transparência e auditoria coletiva.
  - Ao clicar em um pedido cancelado na aba "Cancelados", o sistema abre o `PedidoCanceladoDetalhesDialog` exibindo quem cancelou, quando, motivo e se houve estorno de estoque.
  - Se a devolução de estoque for confirmada, o sistema gera movimentos de entrada automáticos (`TipoMovimentoEstoque.entrada`, categoria `ajuste`) e registra ações de auditoria (`TipoAcao.pedidoCancelado` e `TipoAcao.movimentoEstoqueRegistrado`).
  - Pedidos cancelados **não são computados no faturamento nem nas entradas do módulo Financeiro**.

### 7.4 Dinâmica de Restaurante, Mesas e Comandas Abertas (`features/pdv/views/widgets/mesas`)
- No perfil profissional **Restaurante**, é exibido o container retrátil **"Mesas"** entre as ações rápidas e o painel de pedidos.
- Cada mesa possui status (`livre` ou `ocupada`), número, descrição/capacidade, nome do cliente e atendente responsável persistidos em cofre.
- **Lançamento e Auditoria de Itens:** Permite adicionar produtos com adicionais e acompanhamentos dinâmicos de grupos de componentes vinculados. Cada item lançado gera `TipoAcao.itemAdicionadoMesa`, e qualquer cancelamento ou remoção de item da comanda gera obrigatoriamente `TipoAcao.itemRemovidoMesa`, preservando o princípio inegociável de transparência radical do Nous.
- **Liberação e Fechamento:** A liberação da mesa gera `TipoAcao.mesaLiberada`.
- **Impressão de Conferência:** Emite via `ImpressaoService.imprimirConferenciaMesa` o comprovante de pré-fechamento térmico em 58mm ou 80mm.
- **Múltiplos Pagamentos e Divisão de Conta:** No fechamento (`FecharContaMesaDialog`), permite pagamento único ou parcelamento dinâmico em múltiplas formas de pagamento (dividindo a conta entre várias pessoas com cálculo automático de saldo restante), botão de acréscimo de 10% de atendimento e descontos.
- **Cadastro Rápido de Cliente para Venda à Prazo na Mesa:** Ao fechar a conta com a opção "À Prazo", caso o cliente não esteja cadastrado na loja, o sistema abre automaticamente o diálogo centralizado `_CadastroClienteRapidoMesaDialog` solicitando Nome (obrigatório), Endereço e Telefone/WhatsApp. Ao salvar, persiste o cliente na loja, vincula à comanda e conclui o fechamento com o fiado devidamente registrado na ficha do cliente.
- **Transferência e Unificação de Mesas:** Permite transferir uma comanda para outra mesa livre ou unir comandas existentes (`TransferirMesaDialog`), registrando ação de auditoria (`TipoAcao.mesaTransferida`).

### 7.5 Ficha do Cliente, Quitação Universal e Extrato em PDF (`features/pdv/views/widgets/clientes_dialog.dart`)
- **Quitação Universal a Prazo (`aplicarPagamentoAPrazo`):** A baixa de pagamentos a prazo localiza e quita pedidos tanto pelo `clienteId` quanto por correspondência de `clienteNome` (`clienteNome: cliente.nome`), garantindo que pedidos anotados a prazo antes da criação formal do cadastro ou associados pelo nome sejam abatidos sem deixar dívidas fantasmas.
- **Exclusão de Clientes com Alerta de Débito:** No formulário de edição de cliente, o lojista conta com botão "Excluir Cliente". Caso o cliente possua débito a prazo em aberto, o sistema exibe alerta em destaque avisando o saldo devedor antes de confirmar a exclusão. O histórico de pedidos concluidos permanece intacto para contabilidade e auditoria.
- **Extrato Financeiro e de Compras:** Ao tocar em um cliente cadastrado no diálogo de clientes, o lojista visualiza o valor total acumulado já gasto e o botão **"Exportar Extrato PDF"**.
- O `ImpressaoService.exportarExtratoClientePDF` gera um documento paginado em formato A4 contendo dados cadastrais, saldo devedor a prazo em aberto e tabela completa com data, número do pedido, itens e valores.

### 7.5.1 Caixa do Balcão, Turnos e Alinhamento de Saldos (`features/pdv/views/widgets/caixa_dialog.dart`)
- **Cálculo Preciso de Dinheiro:** Tanto no diálogo do Caixa quanto no painel "Status da Loja", o cálculo de vendas em dinheiro distingue vendas simples (onde o valor do pedido já é o líquido arrecadado) de vendas com pagamentos múltiplos (onde o troco é abatido do montante em dinheiro), eliminando qualquer divergência entre telas.
- **Histórico e Reimpressão de Turnos Fechados:** Quando o caixa está fechado, além do formulário de abertura de novo turno, o diálogo lista os últimos turnos de caixa fechados, exibindo datas de abertura/fechamento, operadores, fundos iniciais, saldos informados e observações, com botão para reimpressão imediata do comprovante térmico de fechamento.

### 7.5.2 Pedidos Programados, Contratos Semanais e Calendário Visual Interativo (`features/pdv/views/widgets/programar_pedido_dialog.dart`)
- **Módulo de Agendamento e Contratos de Clientes:**
  - Acessível no diálogo de clientes (`ClientesDialog`) via botão "Programar Pedido" e na visualização/edição de comandas.
  - O modelo `PedidoProgramado` oferece flexibilidade completa para contratos recorrentes e agendamentos pontuais:
    - **Frequência Dinâmica:** `diasSemana: List<int>` (1=Segunda a 7=Domingo), `datasEspecificas: List<DateTime>`, `modoProgramacao` ('dias_semana' ou 'datas_especificas'), `horario: String`, `ativo: bool`.
    - **Cálculo Matemático de Ocorrência (`coincideComData`):** Avalia se o pedido deve ser executado na data alvo considerando o dia da semana ou as datas pontuais programadas.
    - **Descrição Humanizada Inteligente (`descricaoFrequencia`):** Formata automaticamente textos como *"Qua, Qui, Sex às 12:00"*, *"Diário às 12:00"*, *"Seg a Sex às 08:30"* ou datas marcadas.
- **Seleção de Itens e Categorias com Paridade Operacional Total:**
  - **Modo Item Solto / Avulso:** O produto é adicionado cobrando estritamente seu preço de venda base cadastrado.
  - **Modo Categoria:** Permite selecionar uma categoria da loja (`CategoriaLoja`), adicionando o valor da categoria ao preço do item e disponibilizando os grupos de componentes e acompanhamentos/adicionais associados com contadores `+`/`-`, idêntico à dinâmica de comandas e mesas do restante do sistema.
  - **Variantes Desativadas por Padrão e Observações:** No seletor de produto com variantes, a opção "Desativado" permanece como padrão inicial e pode ser religada a qualquer momento caso o usuário deseje escolher uma variante específica. Campo para observações específicas de cada item ou gerais do contrato.
- **Dois Modos Ergonômicos de Programação:**
  - **Modo 1: Contrato / Dias da Semana:**
    - Botões seletores para os 7 dias da semana (<kbd>Seg</kbd> a <kbd>Dom</kbd>) com destaque de seleção ativo e hover do tema.
    - Atalhos com 1 clique para agendamentos rápidos: *"Dias Úteis (Seg a Sex)"*, *"Fim de Semana (Sáb e Dom)"*, *"Todos os Dias"*.
  - **Modo 2: Calendário Visual Interativo:**
    - Calendário mensal visual renderizado diretamente dentro do diálogo com navegação `< Mês/Ano >`, grade de dias da semana e seleção múltipla de datas.
- **Digitação Direta, Rolagem do Mouse e Microajuste de Horário:**
  - Campo de texto editável com formatador automático `_HorarioInputFormatter` (`HH:mm`), permitindo digitar instantaneamente qualquer horário quebrado no teclado (ex: `12:07`).
  - **Rolagem da Bolinha do Mouse (Mouse Wheel):** Ao rolar a rodinha do mouse para cima sobre o campo, o horário avança minuto a minuto (+1m); ao rolar para baixo, o horário recua minuto a minuto (-1m).
  - Botões dedicados de microajuste minuto a minuto (`[-1m]` e `[+1m]`) para afinar o horário rapidamente com cliques.
  - **Diálogo Dedicado "Digite o Horário (HH:MM)":** Ao tocar no ícone de relógio, abre janela centralizada própria (`_DigitarHorarioDialog`) com visor de alto contraste, suporte contínuo à rolagem da rodinha do mouse em todo o painel (sobe/desce números), botões rápidos de delta (`[-10m]`, `[-5m]`, `[+5m]`, `[+10m]`), atalhos comerciais e botão **"Salvar"** no rodapé com confirmação direta ou tecla Enter.
- **Integração Sistêmica e Avisos de Início:**
  - **Avisos do Dia na Entrada (`PedidosProgramadosDialog`):** Ao iniciar o aplicativo, logo após o fechamento de notificações (ou diretamente se não houver notificações), se houver pedidos agendados para a data, exibe diálogo centralizado com resumo e acesso direto à comanda do pedido.
  - **Aba "Novos" na Gestão do Perfil:** Injeta automaticamente no painel de novos pedidos os pedidos programados do dia para fácil aceite e despacho.
  - **Relatórios Gerenciais (`RelatoriosDialog`):** Container dedicado acima de "Pendências" listando todos os agendamentos do dia selecionado com foto do cliente, horário, frequência e clique interativo para abrir a comanda.


### 7.6 Atualizações do Sistema e Instalador Windows
- **Atualização Local-First Soberana:** Botão na `CustomAppBar` ao lado da engrenagem com `AtualizacaoDialog`, exibindo versão instalada, checagem via `AtualizacaoService` e garantia de preservação de dados locais. O botão na AppBar só é renderizado quando há atualização detectada.
- **Cofre Soberano Intacto:** O banco de dados local SQLite (`nous.db`) e arquivos residem em `%APPDATA%\Nous`, permanecendo intactos mesmo após reinstalações ou atualizações de versão.
- **Instância Única Nativa (Single Instance):** Implementada no runner Win32 C++ (`windows/runner/main.cpp`) via `CreateMutex` nomeado (`Nous_Single_Instance_Mutex`). Ao tentar abrir o aplicativo novamente, a segunda instância é abortada e a janela já existente é trazida e restaurada para o primeiro plano, evitando conflitos de concorrência com o SQLite.
- **Instalador Oficial Windows:** Configurado via `windows/installer.iss` (Inno Setup 6) e script Powershell de automação `scripts/gerar_instalador.ps1`. Ícone oficial gerado a partir de `assets/images/logo.png`.

### 7.7 Backup Soberano, Mesclagem Inteligente e Desduplicação por CNPJ (`features/pdv/services/backup_service.dart`)
- **Exportação e Importação Soberana:** Operação via `BackupService` e `BackupDialog` sem dependência de nuvem, exportando e importando contas, lojas, referências e convites em arquivo `.json` único através do `file_selector`.
- **Modos de Importação:**
  - **Substituir:** Zera as tabelas locais do SQLite e aplica o estado integral do arquivo de backup.
  - **Mesclar:** Une o conteúdo do arquivo com o cofre existente sem perda de dados locais.
- **Identificação Unificada por CNPJ / Documento:**
  - Ao mesclar, o sistema compara os documentos (`cnpj`) ignorando pontuações (`mesmoDocumento`). Se o documento coincidir ou o `id` for o mesmo, o sistema **NUNCA cria uma loja duplicada** no container *"Meus Perfis Profissionais"*.
  - **Precedência da Categoria Ativa:** Se a loja atual possui categoria mais especializada (ex.: `Restaurante` com dinâmica de mesas e comandas) e a loja do backup era `Loja Padrão`, a categoria `Restaurante` e suas mesas são preservadas intactas.
  - **Mesclagem Granular e Enriquecimento:** Itens/produtos, clientes, categorias, grupos de adicionais, histórico de auditoria de ações (`RegistroAcao`), pedidos de venda, movimentações de estoque, turnos de caixa, pagamentos e anexos são unificados e enriquecidos sem sobrescrita destrutiva nem duplicatas de produtos/clientes.
  - **Reatividade Pós-Importação:** Ao finalizar o fluxo no `BackupDialog`, o sistema recarrega automaticamente `AuthProvider`, `PdvProvider` e `NotificacoesProvider`, refletindo os dados mesclados imediatamente em tela sem exigir reinicialização do aplicativo.
- **Backup Diário Automático e Silencioso:** No arranque do sistema (`main.dart`), o `BackupService.realizarBackupAutomaticoSeNecessario()` gera silenciosamente uma cópia soberana em `%APPDATA%\Nous\backups\backup_nous_YYYY-MM-DD.json`, mantendo até 30 versões diárias para proteção contra falhas de hardware ou exclusões acidentais.

### 7.8 Impressão Térmica Soberana, Calibração Bilateral e Prévia Viva (`features/pdv/services/impressao_service.dart`)
- **Suporte a Bobinas de 58mm e 80mm com Calibração Dinâmica:**
  - Em `ConfiguracoesImpressora`, o campo `larguraPapelMm` permite alternar entre bobinas padrão de 58.0 mm e bobinas largas de 80.0 mm.
  - O `ImpressaoService` ajusta dinamicamente a área imprimível, larguras de coluna e divisores conforme a bobina selecionada.
- **Adaptação Universal a Fabricantes (Knup, B&G, Elgin, Daruma, etc.):**
  - Para sanar cortes mecânicos na cabeça de impressão sem perder padronização, o sistema disponibiliza **Calibração Bilateral Independente**:
    - `margemEsquerdaMm` (default: 5.0 mm): calibra o recuo inicial do texto à esquerda.
    - `margemDireitaMm` (default: 3.0 mm): calibra o recuo final de valores e descrições à direita.
    - Ajustáveis com precisão de 0.5 mm (`[-] / [+]`) e atalhos rápidos pré-calibrados.
- **Tipografia Unificada Soberana e Lista Expansível (`FontesApp`):**
  - Mapeamento centralizado de tipografia compartilhado simultaneamente entre a aplicação ("Personalizar Aparência") e as comandas ("Tipografia da Comanda").
  - **Lista Mestra com 11 Opções Consagradas no Mercado:**
    - `Belleza`: Identidade visual oficial do Nous (carregada offline de `assets/fonts/Belleza-Regular.ttf`).
    - `Arial / Helvetica`: Campeã absoluta para cabeças térmicas (traços uniformes sem quebras em 203 DPI).
    - `Courier`: Monoespaçada clássica de recibos/bobinas com alinhamento vertical estrito de colunas e números.
    - `Roboto` e `Roboto Mono`: Sem serifa universal e monoespaçada moderna de alta precisão.
    - `Open Sans`: Traços amplos e abertos que evitam manchas/borrões com a saturação de calor no papel térmico.
    - `Inter`, `Lato`, `Poppins` e `Montserrat`: Opções geométricas e modernas consagradas.
    - `Times New Roman`: Serifada tradicional para extratos e documentos formais.
  - **Interface com Lista Expansível (Dropdown):** No container "Tipografia da Comanda" de `ImpressoraDialog`, a seleção de fonte adota o componente de lista expansível idêntico ao de "Personalizar Aparência", exibindo o rótulo descritivo e o preview tipográfico em tempo real no simulador da comanda.
  - **Resolução no PDF e na Interface:** Zero dependência externa ou APIs de Big Techs — na interface utiliza a renderização nativa do Windows e no PDF (`ImpressaoService`) resolve fontes vetoriais otimizadas para impressoras térmicas.
- **Prévia Dinâmica Integrada com Variações Históricas do Anarquismo:**
  - No diálogo de impressora (`ImpressoraDialog`), a comanda simulada é renderizada **diretamente dentro do container de calibração bilateral**, variando o padding em tempo real conforme os ajustes de mm.
  - Sorteia dinamicamente 1 dos 10 perfis históricos anarquistas e do Nous (Makhno, Bakunin, Malatesta, Kropotkin, Emma Goldman, Durruti, Maria Lacerda de Moura, Comuna de Paris, CNT/FAI e Nous Autogestão).
  - Responde em tempo real a todos os seletores de dados do cliente (CNPJ, telefone, endereço, e-mail, redes sociais e descrição), integrando os canais oficiais do Nous (`nousstudios72@gmail.com`, `@nous.studios72`).
  - **Formatação Resiliente contra Esmagamento e Overflows:**
    - Renderiza dados do cliente com `linhaDadoCliente` onde o rótulo é mantido intacto e o valor reside em `Expanded(softWrap: true)` alinhado à direita.
    - **Renderização Adaptativa de Itens e Preços (`linhaComanda` e `ImpressaoService.linhaDupla`):** 
      - Se a coluna direita for valor monetário (`R$ ...`): a coluna esquerda recebe `Expanded` com espaçamento mínimo garantido de respiro (`8px` / `pw.SizedBox(width: 8)`) para que descrições longas de itens nunca colidam ou grudem nos preços (ex: impedindo `deR$ 25,00`), enquanto o valor da direita preserva largura fixa alinhado à direita.
      - Se a coluna direita NÃO for preço (como `Pagamento: Crédito Mútuo / Autogestão`, nomes de operadores ou observações): o rótulo à esquerda preserva sua largura natural fixa (`Text('$rotulo:')`), **eliminando categoricamente a compressão lateral e quebra vertical sílaba por sílaba** (como em `Pa / ga / m / en / to`), enquanto a coluna direita recebe `Expanded` com alinhamento à direita e quebra fluida.
    - **Container Elástico por Escala de Fonte:** O preview tem largura máxima adaptável calculada por `(320.0 * theme.fontScale).clamp(320.0, 440.0)`, comportando zoom máximo de acessibilidade sem esmagamento visual.
  - **Impressão Direta do Exemplo:** Botão de ícone compacto (`Icons.print_outlined`) posicionado logo abaixo da prévia que envia o exemplo sorteado diretamente para a impressora física via `ImpressaoService.imprimirExemploComanda`.

### 7.9 Automação de Compras no Estoque, Notificações de Estoque Crítico e Financeiro Diário
- **Cálculo Automático em Movimento de Estoque (`MovimentoEstoqueDialog`):**
  - Campo "Custo da compra (R$)" com sincronização recíproca automática: ao digitar a quantidade e o valor total pago, calcula e preenche o custo unitário instantaneamente ($C_{\text{unit}} = \frac{C_{\text{total}}}{Q}$), e vice-versa.
- **Indicador Visual de Estoque Baixo / Esgotado (< 10 un) e Resolução Sincronizada:**
  - Monitoramento contínuo em `PdvProvider.todosItensEstoqueBaixo` para qualquer produto não-serviço com saldo menor que 10 unidades ou esgotado ($\le 0$).
  - O botão de notificações na `CustomAppBar` acende com ícone de alerta ativo e soma o total de itens críticos no badge vermelho.
  - A janela `NotificacoesDialog` exibe cards de alerta dedicados indicando o nome da loja, produto, saldo exato com unidade (`un`, `g`, `ml`) e instruções de reposição.
  - **Ação Imediata, Auditoria e Sincronismo Soberano (`NotificacoesDialog` & `DadosPerfilView`):**
    - Ao tocar no alerta, o diálogo delega a resolução para a tela ativa e abre `MovimentoEstoqueDialog` com o item e tipo "Entrada" pré-selecionados.
    - Ao salvar a entrada de mercadorias:
      - Registra a movimentação no cofre SQLite via `pdv.adicionarMovimentoEstoque`.
      - Registra a auditoria em `loja.acoes` via `pdv.registrarAcao` com `TipoAcao.movimentoEstoqueRegistrado`, contendo autor, data/hora, quantidade formatada e nome do produto.
      - Recalcula o saldo imediatamente; com estoque $\ge 10$, a notificação é removida do sino e do diálogo.
      - `DadosPerfilView` mantém sincronização reativa com `PdvProvider.addListener`, atualizando `_movimentosEstoque`, `_pedidos` e `_membros` em tempo real para impedir qualquer sobrescrita por dados defasados.
      - `ItemLoja` implementa `operator ==` e `hashCode` por `id`, assegurando equivalência exata nos seletores e `DropdownButton`.
- **Resumo Financeiro com Filtro por Dia Específico, Intervalo e Exportação em PDF (`FinanceiroView`):**
  - O botão "Financeiro" na aba Gestão da loja abre inicialmente no período "Hoje", apresentando vendas, pagamentos, entradas por forma, sugestão de divisão igualitária e botão "Exportar PDF" gerado em folha A4.
  - **Filtro de Data Flexível (Dia Específico ou Intervalo X a Y):** Logo abaixo dos botões "Hoje", "Semana", "Mês" e "Tudo", a tela disponibiliza inputs dedicados ("De: dd/mm/aaaa" e "Até: dd/mm/aaaa") com máscara automática `_DataInputFormatter`.
    - Ao preencher apenas o primeiro campo, o sistema apura **apenas aquele dia único** (00:00:00 às 23:59:59).
    - Ao preencher ambos, filtra com exatidão o intervalo de datas solicitado.
    - Se o usuário clicar nos botões predefinidos, os campos são limpos; ao digitar uma data, o botão ativo é desmarcado (`PeriodoFinanceiro.personalizado`) e um botão de reset (`x`) permite limpar rapidamente.
    - **Integração Integral com Apuração, DRE e Impressão:** Ao acionar "Imprimir" (cupom térmico), "DRE Simples" (modal contábil e PDF) ou "Exportar PDF", todos os dados apurados (vendas, entradas por forma, custos/CMV, despesas de pessoal e resultado líquido) e o cabeçalho de período estampado no documento refletem com exatidão o(s) dia(s) escolhido(s).

### 7.10 Gestão de Turno de Caixa e Controle de Gaveta (`features/pdv/views/widgets/caixa_dialog.dart`)
- **Abertura de Caixa e Fundo de Troco:** O operador inicia o turno informando o valor inicial da gaveta (troco), associando o CPF e nome do responsável e data/hora de abertura.
- **Movimentações Avulsas (Sangrias e Suprimentos):**
  - **Suprimento (Entrada):** Reforço de troco ou entrada avulsa em dinheiro com justificativa.
  - **Sangria (Saída):** Retirada de valores para cofre, despesas urgentes ou segurança, com justificativa obrigatória.
  - Ambas as ações são auditadas em `RegistroAcao` e integradas ao turno aberto.
- **Fechamento Cego, Acurácia de Troco e Conferência de Valores:**
  - O operador realiza o fechamento informando os valores contados fisicamente (dinheiro em espécie, cartão de crédito, cartão de débito, PIX, outros) sem visualização prévia das somas do sistema ("conferência cega").
  - **Acurácia Rigorosa em Espécie:** O total de vendas em dinheiro desconta o troco devolvido aos clientes ($\text{Dinheiro Líquido} = \text{Entradas em Dinheiro} - \text{Troco}$), computando todos os pedidos do turno (`aceito` e `concluido`).
  - O sistema calcula o saldo apurado pelo sistema versus o saldo informado, apontando sobras ou faltas de caixa de forma transparente.
- **Comprovante Térmico de Fechamento (`imprimirFechamentoCaixa`):**
  - Emite cupom térmico detalhado em 58mm ou 80mm com dados do operador, período, saldo inicial, total de vendas por forma de pagamento, sangrias, suprimentos, saldo esperado em dinheiro, saldo informado e divergência apurada.

### 7.11 Instalador Oficial Windows — Versão Teste
- Configurado em `windows/installer.iss` (Inno Setup 6) gerando `dist/Nous_Instalador_v1.0.0_Versao_Teste.exe`.
- Automação completa pelo script PowerShell `scripts/gerar_instalador.ps1`.

### 7.12 Notificações Arrastáveis, Kardex, DRE e Automação de Impressão
- **Ordenação Decrescente de Concluídos e Cancelados (`gestao_loja_container.dart`):** Os pedidos nas abas "Concluídos" e "Cancelados" são ordenados estritamente com os mais recentes no topo (`b.dataHora.compareTo(a.dataHora)`).
- **Notificações Arrastáveis em Sessão (`notificacoes_dialog.dart` / `notificacoes_provider.dart`):**
  - Notificações de alerta de estoque e convites possuem suporte a arrastar para o lado (`Dismissible` horizontal) com indicação visual de dispensar.
  - O controle é mantido em memória via `_notificacoesDispensadasSessao`. Ao fechar e reabrir o aplicativo, qualquer notificação cuja causa subjacente ainda não foi resolvida reaparece automaticamente para o operador, mantendo o controle soberano sem apagar dados acidentalmente.
- **Impressão Automática ao Concluir Venda (`ConfiguracoesImpressora.imprimirAutomaticoAoConcluir`):**
  - Switch dedicado nas configurações de impressora. Quando ativado, a comanda térmica é enviada automaticamente à impressora configurada no momento da abertura do diálogo de venda concluída, eliminando toques manuais redundantes.
- **Comprovantes Térmicos de Sangria e Suprimento (`caixa_dialog.dart` / `impressao_service.dart`):**
  - Ao registrar uma sangria ou suprimento, o operador pode clicar em "Confirmar" ou "Confirmar e Imprimir".
  - O comprovante térmico (`imprimirMovimentoCaixa`) inclui dados da loja, operador, tipo de movimentação, valor, motivo, data/hora e linha pontilhada para assinatura de conferência.
  - Histórico de movimentações do turno exibe botão de reimpressão de 2ª via.
- **Demonstrativo do Resultado do Exercício — DRE Simples (`FinanceiroView` / `ImpressaoService.exportarDREPDF`):**
  - Botão "DRE Simples" na barra de ações financeiras. Exibe popup centralizado com Receita Operacional Bruta, (-) Custos das Mercadorias/Insumos (CMV), (=) Lucro Bruto com margem %, (-) Pagamentos a Trabalhadores e (=) Resultado Líquido com margem %.
  - **Exportação Dedicada em PDF (`exportarDREPDF`):** O botão "Exportar DRE em PDF" dentro do modal gera um documento contábil executivo exclusivo de página única (`dre_AAAAMMDD_HHMM.pdf`), separado do relatório financeiro geral analítico (`financeiro_AAAAMMDD_HHMM.pdf`). Inclui tabela estruturada, destaque de margens, dados da loja e nota de autogestão e transparência.
- **Ficha Kardex do Produto (`estoque_container.dart`):**
  - Ao tocar em um item no estoque, abre a Ficha Kardex completa exibindo dados cadastrais (preço de venda, preço de custo, estoque mínimo, código de barras), saldo atual em tempo real e a lista cronológica de movimentações (com tipo, data/hora, fornecedor, quantidade e custos).

### 7.13 Impressão em Pedidos Aceitos, Confirmação de Quitação e Bips Sonoros Customizáveis
- **Botão de Impressão Direta em Pedidos Aceitos (`PedidoAceitoDialog`):**
  - Adicionado botão compacto de impressora (`IconButton(Icons.print_outlined)`) posicionado logo acima dos botões de ação ("Cancelar Pedido" e "Concluir"), permitindo emitir a comanda térmica a qualquer momento durante a preparação sem precisar concluir o pedido previamente.
- **Confirmação de Segurança no Abate de Dívidas (`ClientesDialog`):**
  - Implementada janela modal de confirmação (`showDialog`) ao clicar em "Quitar valor" ou "Quitar tudo".
  - O modal detalha o nome do cliente, o valor que será abatido, a dívida atual e o saldo restante calculado em tempo real, prevenindo baixas acidentais de contas de clientes a prazo.
- **Ecossistema de Sons e Bips Personalizáveis (`SomService` / `Loja.sonsAlertas` / `DadosPerfilView`):**
  - Serviço nativo `SomService` que executa bips do sistema com latência zero e reprodução de arquivos WAV/MP3 anexados sem dependências pesadas externas.
  - Novo container "Sons e Alertas do Sistema" na aba "Dados" da loja (posicionado logo abaixo de "Arquivos de Áudio"), permitindo configurar efeitos sonoros para 3 eventos principais:
    1. *Novo Pedido Recebido* (`SomService.eventoNovoPedido`)
    2. *Tempo Limite / Alerta de Pedido* (`SomService.eventoConclusaoPedido`)
    3. *Bip de Leitura na Venda (Código de Barras / Item)* (`SomService.eventoBipVenda`)
  - Cada evento possui dropdown com opções ("Bip Padrão do Sistema", "Silencioso" ou qualquer áudio anexado em `_arquivosAudio`) e botão com ícone de reprodução para testes imediatos.
### 7.14 Ergonomia de Venda, Preservação de Rascunhos e Resumo Operacional Diário
- **Estado Inicial Limpo, Foco Dinâmico e Regiões de Toque (`NovaVendaDialog`):**
  - Ao abrir a tela de Nova Venda, os containers "Produtos Solicitados" e "Nome do Cliente" iniciam limpos, sem listagens soltas iniciais.
  - Ao focar/clicar no campo de busca com pesquisa em branco, renderiza **exclusivamente as categorias cadastradas da loja**, sem produtos soltos.
  - Produtos individuais aparecem apenas mediante pesquisa ativa por nome ou leitura por bipador de código de barras.
  - O container "Nome do Cliente", ao receber foco com pesquisa em branco, renderiza **todos os clientes cadastrados da loja**, filtrando em tempo real conforme digitação.
  - **Interação Estável com `TapRegion`:** Containers de produto e cliente envolvidos em `TapRegion` com controle de foco (`onTapOutside`), eliminando fechamentos prematuros ou perda de eventos de toque ao clicar em categorias ou clientes da lista.
- **Desconto e Acréscimo em Porcentagem (`%`) ou Valor Fixo (`R$`):**
  - Os campos de "Desconto" e "Acréscimo" aceitam valores numéricos diretos em reais ou porcentagens com o símbolo `%` (ex.: `10%`, `5%`, `2.5%`).
  - O sistema calcula o valor percentual dinamicamente sobre o subtotal dos itens da comanda ($\text{Subtotal} \times \frac{\%}{100}$), atualizando a comanda viva, o valor total e o saldo restante de vendas a prazo em tempo real, discriminando na comanda e no cupom impresso `Desconto (X%)` ou `Acréscimo (X%)`.
- **Seleção Numérica Total Instantânea em Pagamentos:**
  - Ao adicionar qualquer forma de pagamento ou ao tocar no campo de valor correspondente (inclusive frete, desconto e acréscimo), todo o valor numérico é pré-selecionado (`TextSelection(baseOffset: 0, extentOffset: text.length)`). O operador pode digitar um novo valor diretamente sem precisar deletar dígito por dígito.
- **Preservação de Rascunho Soberano contra Fechamento Acidental:**
  - Caso o operador feche acidentalmente a tela de Nova Venda (via <kbd>Esc</kbd>, botão de voltar ou clique fora), todos os itens selecionados (quantidades, acompanhamentos dinâmicos, observações individuais), cliente, frete, desconto, acréscimo e formas de pagamento são preservados em memória (`_rascunhosPorLoja`).
  - Ao reabrir a janela de Nova Venda na mesma loja, todos os dados são restaurados automaticamente no formulário e na comanda viva.
  - Um botão dedicado de lixeira/limpeza ("Limpar campos da venda") é disponibilizado no cabeçalho para resetar o formulário manualmente com 1 clique caso desejado.
  - Ao concluir a venda com sucesso, o rascunho é limpo automaticamente.
- **Card de Resumo Operacional do Dia no Topo (`StatusLojaView`):**
  - Posicionado no topo da tela de Status da Loja, **acima** do container de Status da Loja.
  - Métricas em tempo real sob o princípio da transparência radical:
    1. *Faturamento do Dia (R$)*: somatório das vendas não canceladas de hoje.
    2. *Vendas Hoje (qtd)*: quantidade de pedidos realizados no dia.
    3. *Ticket Médio (R$)*: média financeira por venda hoje.
    4. *Situação do Caixa*: indicador visual dinâmico ("Caixa Aberto" ou "Caixa Fechado") com o saldo real apurado em dinheiro físico em mãos no momento ($\text{Saldo Inicial} + \text{Suprimentos} - \text{Sangrias} + \text{Vendas em Dinheiro Líquidas}$).

### 7.15 Integridade de Relacionamentos, Governança e Auditoria Contábil
- **Convites com `cpfDonoOriginal` Soberano:** O modelo `ConviteLoja` persiste `cpfDonoOriginal`, garantindo que convites enviados por Sócios ou Admins acessem e salvem a loja diretamente no cofre do dono titular, eliminando o falso erro *"A loja deste convite não está mais disponível"*.
- **Comandas de Mesas com Múltiplos Pagamentos Preservados:** `PedidoLoja.pagamentosExtras` armazena a totalidade dos pagamentos realizados no fechamento de mesa (sem descarte do índice 0), corrigindo relatórios, caixas e impressões térmicas.
- **Nomenclatura Unificada e Defensiva de "À Prazo":** Padronizado `'À Prazo'` em todo o sistema e getter `PedidoLoja.temAPrazo` tolerante a variações (`'À Prazo'`, `'A Prazo'`, `'Fiado / A Prazo'`). No fechamento de mesa, o `clienteId` é vinculado automaticamente caso haja cliente cadastrado com o nome da comanda.
- **Consistência de Pagamentos à Prazo, Vendas Mistas e Fechamento de Mesas:**
  - Vendas quitadas ou sem débito à prazo nascem com `quitado: true` e `valorPago: total`.
  - Vendas à prazo ou mistas (com entrada à vista) registram em `valorPago` o valor real já recebido na hora da venda (`valorPagoNaoPrazo`), permitindo que `valorRestante` calcule a dívida real exata sem cobrar duas vezes o valor pago.
  - Vendas canceladas (`StatusPedido.cancelado`) são estritamente excluídas do cálculo de débitos em aberto (`aPrazoEmAberto`), relatórios gerenciais e faturamento do dia.
  - Fechamento de comanda de mesa com forma à prazo exige cliente selecionado ou cadastrado antes da conclusão.
- **Estorno Inteligente de Estoque na Exclusão de Pedidos:** Ao excluir um pedido da listagem da loja, o lojista é consultado se deseja estornar os produtos de volta ao estoque, registrando a entrada correspondente com trilha de auditoria (`cpfAutor`, `nomeAutor` e justificativa).
- **Base de Rateio Igualitário Estável aos Trabalhadores:**
  - O cálculo da sugestão de divisão igualitária aos membros (`RegistrarPagamentoDialog`) baseia-se no resultado operacional do período ($\text{Entradas} - \text{ComprasEstoque}$), dividindo a cota de forma constante entre todos os membros ($\text{Cota} = \text{BaseRateio} / \text{Membros}$), sem degradar em cascata conforme os membros anteriores recebem suas retiradas.
- **Contabilização Fiel de Vendas À Prazo no Financeiro e Impressão:**
  - No `FinanceiroView` e no `ImpressaoService` (tela, térmica e PDF), o container "Entradas por forma de pagamento" soma e exibe com exatidão o valor faturado em cada modalidade, incluindo `'À Prazo'`. Vendas lançadas a prazo atualizam imediatamente a linha correspondente, garantindo conferência visual fiel de tudo o que foi vendido no período.
- **Pendências Agrupadas por Cliente em Relatórios (`RelatoriosDialog`):**
  - No container "Pendências", múltiplos pedidos a prazo em aberto de um mesmo cliente são consolidados em uma única barra. A barra exibe o total devido somado no canto direito e, abaixo do nome do cliente, a indicação textual do último pedido realizado (`Último pedido: #XXXX • Data/Hora`), além de badge com a quantidade de pedidos em aberto quando houver mais de um.
  - Ao clicar na barra, o sistema abre a ficha do cliente para conferência e quitação. Se for um pedido avulso antigo ou sem cadastro vinculado, o sistema abre diretamente a comanda (`VendaRegistradaDialog`), garantindo que nenhuma barra de pendência fique inacessível ou travada.
- **Bloqueio de Vendas à Prazo sem Cliente no Modo Balcão (`ModoBalcaoWidget`):**
  - No modo balcão, a modalidade "À Prazo" exige cliente cadastrado: o clique na opção "À Prazo" sem cliente abre imediatamente a busca de clientes com foco no campo. Ao tentar finalizar a venda (`_finalizarVenda`), o sistema bloqueia e emite aviso para seleção de cliente, impedindo a criação indevida de pendências anônimas como "Consumidor Final". Se o cliente for desmarcado, a forma de pagamento é revertida automaticamente para "Dinheiro".
- **Quitação Rápida e Direta de Pedidos à Prazo (`VendaRegistradaDialog` & `PdvProvider`):**
  - Em qualquer comanda de venda registrada que possua saldo a prazo em aberto (`pedido.aPrazoEmAberto`), o trabalhador conta com o botão direto "Quitar Pagamento à Prazo". O diálogo confirma o valor, permite selecionar a forma recebida (Dinheiro, Pix, Cartão) e aciona `PdvProvider.quitarPedidoLoja`, atualizando o pedido no cofre, gerando suprimento de caixa caso recebido em dinheiro e registrando a ação de auditoria com rastreabilidade total.
- **Troco Real e Entrada em Vendas Mistas no PDV:**
  - O troco em `NovaVendaDialog` é calculado pelo excesso real sobre o total ($\text{TotalPagamentos} - \text{Total}$), gravando o valor líquido recebido no ato e garantindo conciliação física da gaveta de caixa sem quebras.
- **Quitação de Fiados Integrada ao Caixa Aberto:**
  - Ao abater dívidas de clientes em `ClientesDialog`, o lojista indica a forma de pagamento (Dinheiro, Pix, Cartão). Sendo em dinheiro e com caixa aberto no balcão, o sistema registra automaticamente um suprimento de caixa no turno atual, impedindo "sobras" de dinheiro inexplicadas na conferência cega.
- **Validação Estrita de Pagamentos em Mesas:**
  - `FecharContaMesaDialog` valida e bloqueia o fechamento tanto quando faltar quitar o saldo quanto quando a soma dos pagamentos parciais ultrapassar o total da comanda (por exemplo, após concessão de desconto tardio).
- **Cálculo de Troco no Caixa sem Dupla Dedução:** `_vendasDinheiro` em `CaixaDialog` diferencia pagamento único (onde `p.valor` já é líquido) de pagamentos múltiplos, evitando subtrair o troco duas vezes.
- **Limpeza em Cascata no SQLite:** Ao excluir lojas em `LojasService.salvar`, os registros de `pedidos`, `movimentos_estoque` e `pagamentos_funcionarios` correspondentes são excluídos, eliminando dados órfãos.
- **Mesclagem Completa no Backup:** `BackupService.mesclarLojas` unifica `turnosCaixa`, `atalhosTeclado`, `tempoConclusaoMinutos` da loja, bem como `codigoBarras`, `precoCusto`, `unidadeBase` e `consumoPorVenda` de `ItemLoja`.
- **Auditoria Transparente em Pagamentos aos Membros:** Pagamentos aos trabalhadores em `FinanceiroView` registram ações `RegistroAcao` com autor, valor e delta discriminado em relação à sugestão igualitária calculada pelo sistema.
- **Sincronização de Fornecedores por Foto:** Ao atualizar foto de usuário por CPF, a foto é propagada para clientes e fornecedores originados.
- **Reset de Transações com Preservação do Estoque Físico:**
  - No botão "Resetar Transações", o `pdv_provider.dart` consolida os saldos de estoque físico de cada item através de movimentos de ajuste com `custoUnitario: 0.0` e `custoTotal: 0.0`. O saldo físico de produtos em unidades, gramas ou ml permanece rigorosamente intocado, enquanto o histórico de compras com custos anteriores desaparece do módulo Financeiro.
- **Módulo de Pedidos Programados:**
  - **Modelo Soberano (`PedidoProgramado`):** Armazena `id`, `lojaId`, `clienteId`, `clienteNome`, `clienteTelefone`, `clienteEndereco`, `itens` (`List<ItemVendido>`), `valorTotal`, `formaPagamento`, `horario`, `recorrente` (diário vs pontual), `dataProgramada`, `ativo`, `dataCriacao` e `ultimaDataGerado`.
  - **Ficha do Cliente (`ClientesDialog`):** Container "Pedidos Programados" posicionado acima do "Histórico de Compras", com botão "+ Programar Pedido" e lista de agendamentos ativos do cliente com opções de ver comanda, pausar/ativar e excluir.
  - **Diálogo Prático de Programação (`ProgramarPedidoDialog`):**
    - **Padronização Visual Centralizada:** Todos os títulos dos blocos internos (`Frequência e Horário do Pedido`, `Adicionar Item ao Pedido`, `Comanda do Pedido` e `Forma de Pagamento e Detalhes`), o cabeçalho do diálogo e o container de `Pedidos Programados` em `ClientesDialog` seguem rigorosamente o alinhamento central da aplicação (`MainAxisAlignment.center` e `textAlign: TextAlign.center`).
    - **Calendário e Frequência:** Modos "Contrato / Dias da Semana" (com pré-seleção rápida e chips individuais de Segunda a Domingo) e "Calendário de Datas" interativo (mês a mês com marcação visual).
    - **Seletor de Horário Robusto e Ergonômico:** Formatador `_HorarioInputFormatter` imune a inversão de dígitos nos minutos através do mapeamento numérico anterior ao cursor, suporte nativo a backspace sobre o separador `:`, auto-seleção de texto com um toque (`onTap` e `autofocus`), rolagem isolada com a rodinha do mouse (`NeverScrollableScrollPhysics` durante foco/hover), botões delta minuto a minuto (`-1m`, `+1m`), atalhos rápidos e modal ampliado `_DigitarHorarioDialog` com título limpo `"Digite o Horário"`.
    - **Seleção Fiel de Itens e Variantes Opcionais:** Suporta seleção por categoria ou item avulso, lista completa de acompanhamentos com contadores de quantidade e variantes que nascem desativadas por padrão com a opção explícita "Desativado".
  - **Avisos ao Entrar na Aplicação (`DadosPerfilView`):** Após fechar as notificações (ou diretamente se não houver notificações), exibe a janela `PedidosProgramadosDialog` com os avisos dos pedidos agendados para o dia de hoje. Se não houver pedidos para hoje, não mostra nada.
  - **Injeção em "Novos" e Fila Automática de Novos Pedidos (`ComandaNovoPedidoDialog`):**
    - Ao verificar os agendamentos do dia, pedidos programados ativos geram um `PedidoLoja` com status `novo` na Gestão do Perfil sem duplicações (`ultimaDataGerado`).
    - **Fila Sequencial ao Entrar na Aplicação:** Logo após a checagem inicial, se houver pedidos com `StatusPedido.novo` na loja, o sistema emite alerta sonoro (`SomService.eventoNovoPedido`) e abre a janela com a comanda completa do primeiro pedido e botões de ação:
      - **`Recusar`:** Recusa o pedido (`_recusarPedido`), remove da lista, registra ação de auditoria e avança imediatamente para o próximo pedido novo da fila.
      - **`Imprimir`:** Envia a comanda para a impressora configurada sem fechar a janela, permitindo que o operador imprima e decida se aceita ou recusa.
      - **`Aceitar`:** Aceita o pedido (`_alterarStatusPedido`), move para a aba "Aceitos", registra auditoria e abre o próximo pedido novo da fila até que todos os pedidos novos acabem.
      - **Dispensar:** O botão "X" fecha a janela e interrompe o loop inicial sem perder os pedidos, que permanecem na aba "Novos" de `GestaoLojaContainer`.
    - **Abertura na Aba "Novos":** Ao clicar em qualquer pedido na aba "Novos" da tela de gestão, abre essa mesma janela `ComandaNovoPedidoDialog`, mantendo coerência absoluta.
  - **Janela de Relatórios (`RelatoriosDialog`):** Container "Pedidos Programados" posicionado acima de "Pendências", listando os clientes que agendaram pedidos para a data filtrada com resumo e clique abrindo a comanda do pedido (`ComandaPedidoDialog`).

### 7.15 Sincronização em Rede Wi-Fi Local (Local-First Multi-Terminal)
- **Operação Simultânea PC ↔ Celular sem Dependência de Internet Externa:**
  - O subsistema de rede local (`features/pdv/services/rede_local/`) permite que a loja opere em múltiplos computadores e celulares conectados ao mesmo roteador Wi-Fi, com latência zero e 100% soberano utilizando o motor de rede nativo do Dart (`dart:io` - `HttpServer`, `WebSocket` e `RawDatagramSocket`).
  - **Servidor do Balcão (`ServidorRedeLocal`):**
    - O computador do caixa/balcão pode ser ativado como servidor mestre na porta padrão `8080`.
    - Disponibiliza rotas REST (`GET /api/status`, `GET /api/loja`, `POST /api/pedido`, `POST /api/movimento_estoque`, `POST /api/mesa`) e canal contínuo `WebSocket` (`/api/ws`).
    - Emite broadcast UDP a cada 3s na porta `45454` anunciando a presença do balcão na rede local para descoberta automática (`nous_loja_anuncio`).
  - **Terminal Móvel / Cliente (`ClienteRedeLocal`):**
    - Celulares escutam a porta UDP `45454` e listam automaticamente as lojas disponíveis no Wi-Fi com botão direto "Conectar" (além de permitir conexão manual por IP e porta).
    - Ao conectar, o celular faz o download do cardápio completo, estoque e mesas, integrando-se reativamente ao `PdvProvider`.
    - Mantém reconexão automática e heartbeat ping/pong.
  - **Sincronização em Tempo Real Bidirecional:**
    - Vendas e pedidos lançados no celular são enviados via HTTP/WebSocket diretamente ao servidor do balcão.
    - O computador central recebe o pedido, adiciona à lista da loja, dá baixa no estoque físico, **emite o alerta sonoro de novo pedido** e, se a impressora térmica estiver ligada, pode imprimir imediatamente o comprovante.
    - Alterações de itens, preços ou estoque realizadas no balcão são propagadas instantaneamente via WebSocket para todos os celulares conectados.
  - **Interface Centralizada (`SincronizacaoRedeDialog` & `_barraDeAcoesLoja`):**
    - Acesso direto via botão "Rede Wi-Fi" na barra de ações da loja e no container "Sincronização em Rede Wi-Fi" na aba Ajustes do Perfil.
    - Indicador de status em tempo real com badge verde quando online, quantidade de terminais conectados e botão de cópia de IP.
  - **Permissões Android:** `AndroidManifest.xml` configurado com `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` e `usesCleartextTraffic="true"` para garantir tráfego HTTP/WebSocket sem restrições em redes Wi-Fi locais.

---

## 8. REGRAS CRÍTICAS DE ENGENHARIA (PARA NUNCA QUEBRAR O SISTEMA)

1. **Modelos Persistidos e Serialização JSON:**
   Aplica-se a: `Loja`, `Cliente`, `Fornecedor`, `PedidoLoja`, `ItemLoja`, `CategoriaLoja`, `GrupoComponentesLoja`, `ConfiguracoesImpressora`, `MembroLoja`, `RegistroAcao`, `ConviteLoja`, `ReferenciaLoja`, `MovimentoEstoque`, `PagamentoFuncionario`, `TurnoCaixa`, `MovimentoCaixa`, `UsuarioNous`:
   - **Valores padrão obrigatórios no `fromJson`:** Nunca confie em nulos vindos do disco. Use `json['campo'] ?? ''` ou `?? false` ou `?? 0.0`.
   - **Atualização Quádrupla Obrigatória:** Sempre atualize Construtor, `copyWith`, `toJson` e `fromJson`.
   - **Enums sempre com `orElse`:** Use `Enum.values.firstWhere(..., orElse: () => EnumPadrao)` para evitar quebra de compatibilidade com dados antigos.
   - **Aviso Obrigatório de Build/Cache:**
     Sempre lembre o desenvolvedor:
     ```bash
     flutter clean && flutter pub get
     ```
2. **Reatividade e Ciclo de Vida:**
   - Rolagens com `Scrollbar` devem ter `ScrollController` explicitamente instanciado.
   - Não use `setState` durante o build; utilize `WidgetsBinding.instance.addPostFrameCallback((_) { ... })`.
   - Para diálogos com atualização interna, use `StatefulBuilder` ou `StatefulWidget` dedicado.
3. **Sem Dependências Desnecessárias:**
   - Não adicione pacotes ao `pubspec.yaml` sem alinhamento prévio explícito.

---

## 9. JURAMENTO DO AGENTE

Você não está diante de um exercício acadêmico nem de uma demonstração descartável de tecnologia. Você está contribuindo para uma ferramenta construída por um trabalhador brasileiro com a finalidade expressa de libertar outros trabalhadores da dependência, da opacidade e da exploração econômica.

- Trate cada linha de código com respeito, sobriedade e honestidade.
- Economize contexto. Seja cirúrgico.
- Não tome atalhos que desrespeitem a arquitetura ou a visão social do projeto.
- A classe trabalhadora brasileira utilizará este software. **Não a decepcione.**
