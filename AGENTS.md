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

Este projeto apoia-se no **anarquismo plataformista brasileiro**: poder sem intermediários, autogestão real, transparência radical e ação direta econômica.

### 3.1 Identidade Real, Sem Anonimato Irresponsável
- Tudo no sistema é vinculado ao **CPF do cidadão**. Uma pessoa pode cadastrar múltiplos e-mails, mas todos convergem para o mesmo CPF.
- Isso elimina contas falsas, bots e a impunidade comum em plataformas centralizadas, sem depender de Big Techs ou solicitar permissão governamental. A responsabilidade é do indivíduo perante a comunidade.

### 3.2 Transparência Radical
- No módulo Financeiro, **o trabalhador acessa e vê exatamente os mesmos números que o dono ou administrador**. Saldo negativo não é camuflado.
- Os pagamentos aos trabalhadores contam com **sugestão de divisão igualitária calculada pelo sistema**:
  $$\text{Sugestão} = \frac{\text{Entradas} - \text{Saídas}}{\text{Número de Membros}}$$
- Ajustes manuais são permitidos caso a caso, mas **absolutamente tudo é registrado em histórico de auditoria** (`RegistroAcao`), contendo autor, data, horário e delta da alteração.

### 3.3 Autonomia Coletiva e Consentimento entre Donos e Sócios
- A hierarquia de loja reflete papéis operacionais (`Dono`, `Sócio`, `Admin`, `Funcionário`), mas o poder não é despótico.
- **Hierarquia e Regras de Exclusão de Membros:**
  - **Outros donos NÃO podem excluir outros donos diretamente:** Se um dono tentar excluir outro dono, o sistema envia uma solicitação de saída via notificação (`TipoNotificacao.solicitacaoExclusaoDono`). A saída só se efetiva se o dono alvo consentir (aceitar).
  - **Donos:** Podem excluir membros abaixo na hierarquia (`Sócio`, `Admin`, `Funcionário`). Ao fazê-lo, o membro é removido e recebe notificação informativa (`TipoNotificacao.remocaoLoja`): *"Você foi removido(a) da loja [Loja] por [Nome]"*.
  - **Sócios NÃO podem excluir Sócios nem Donos:** A opção não é acessível. Sócios podem excluir apenas quem estiver abaixo na hierarquia (`Admin` e `Funcionário`), gerando a notificação de remoção.
  - **Admins e Funcionários:** Não possuem poder de exclusão de terceiros.
  - **Autoexclusão:** Todo membro tem direito de sair voluntariamente da loja a qualquer momento.
- **Princípio Inegociável entre Sócios:** **Um sócio não pode alterar o papel de outro sócio unilateralmente.** Qualquer alteração de papel de um sócio exige notificação (`TipoNotificacao.alteracaoPapel`) e o **consentimento explícito (aceite)** do sócio alvo.

### 3.4 Sistema Fechado, Soberano e Local-First
- O ecossistema opera de ponta a ponta sem dependência de APIs de Big Techs.
- Backup completo serializado em um único arquivo JSON manipulado pelo próprio usuário com `file_selector`.

### 3.5 A Vida Real Manda (O Humano no Comando)
- Onde a máquina calcula estimativas (ex.: baixa de estoque em gramas ou ml por venda), ela **propõe a baixa**, mas o ser humano **confirma, ajusta ou cancela** antes de efetivar.

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

---

## 6. SISTEMA DE DESIGN E TEMAS (REGRAS MANDATÓRIAS)

### 6.1 AppTheme e ThemeController
- O tema é gerenciado por `AppTheme` e exposto globalmente via `ThemeController.currentTheme` (`ValueNotifier<AppTheme>`).

### 6.2 Regras Estritas de Cores
- **PROIBIDO:** Usar cores fixas genéricas (`Colors.white`, `Colors.black`, `Colors.blue`, etc.) diretamente nos layouts.
- **EXCEÇÕES PERMITIDAS:**
  - `Colors.transparent`
  - `Colors.redAccent` (exclusiva para ações destrutivas, exclusões, alertas de quebra e valores de saldo negativo).
- **Opacidade Moderna:** Use sempre `theme.backgroundColor.withValues(alpha: 0.4)` ou `theme.borderColor.withValues(alpha: 0.6)`. Nunca use o método legado `.withOpacity()`.
- **Tipografia:**
  - `theme.textColor`: Títulos, cabeçalhos e valores de destaque.
  - `theme.secondaryTextColor`: Subtítulos, rótulos de campos e descrições.

### 6.3 Componentes Visuais Padronizados

| Elemento | Padrão Obrigatório |
| :--- | :--- |
| **Bloco / Card Padrão** | `BoxDecoration(color: theme.backgroundColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)))` |
| **Diálogos / Popups** | **Sempre centralizados** via `showDialog`. Fundo `theme.cardBackgroundColor`, `borderRadius: 16` e largura máxima de `500`. **Nunca use Bottom Sheets.** |
| **Barras com Hover** | Todo item de lista (membros, fornecedores, clientes, trabalhadores) deve usar o widget de hover com borda contrastante e leve fundo translúcido `theme.borderColor.withValues(alpha: 0.18)` ao passar o cursor. |
| **Listas Vazias** | Use sempre `EstadoVazioContainer(theme: theme, mensagem: '...')`. |
| **Botões de Ação** | Ativos com `theme.buttonColor` e texto em `theme.buttonTextColor`. Secundários com `OutlinedButton` arredondado. |

### 6.4 Ecossistema de Imagens e Continuidade Visual Estrita
- **Proibição de Elementos Fictícios:** Se um componente visual possui espaço para avatar ou imagem, ela **NUNCA é meramente decorativa**. Deve ser persistida, vinculada ao modelo e exibida em todas as telas que representam aquela entidade.
- **Sem Ícones Estáticos Enganosos:** Nunca exiba `Icon(Icons.account_circle)` estático onde há fotos ou CPF associado. Sempre renderize `CircleAvatar` com `FileImage` da imagem real e utilize o ícone nativo apenas como fallback limpo caso a foto inexista.
- **Sem Sobreposições Sujas:** Nunca sobreponha ícones secundários (canetinhas de edição `Icons.edit` ou câmeras flutuantes) sobre avatares ou imagens de formulários.
- **Intermediação via OpcoesImagemDialog:**
  - Se o campo contém imagem: o clique abre `OpcoesImagemDialog.mostrar(...)` ("Procurar nova imagem", "Retirar imagem", "Cancelar").
  - Se o campo está vazio: o clique abre diretamente o seletor de arquivos (`openFile`).
- **Limites e Formatos:** Até 500MB via `ImagemService.salvarImagemLocal` (`jpg`, `jpeg`, `png`, `webp`).
- **Visualizador de Mídias e Anexos Soberanos:**
  - **Imagens:** Ao tocar no card em `GaleriaEstiloContainer`, abre `VisualizadorGaleriaDialog` em tela cheia com zoom interativo (`InteractiveViewer`), navegação contínua entre fotos da lista (setas visuais, teclado `ArrowLeft`/`ArrowRight`, arraste `PageView`), contador e barra inferior com descrição persistida em `Loja.descricoesAnexos`.
  - **Áudios, Vídeos e Documentos:** Ao tocar no card, abre `DetalhesMidiaDialog` com metadados do arquivo (tamanho, formato), legenda editável e reprodução/abertura soberana no reprodutor padrão do sistema operacional via `ImagemService.abrirNoSistema` sem inchaço de dependências.
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
  - Cada card de cliente e fornecedor na listagem renderiza visualmente o endereço (`rua, nº número`) abaixo do nome em tipografia secundária para conferência instantânea.

### 7.3 Fluxo de Venda, Comandas e Estoque
- Itens vendidos (`ItemVendido`) guardam a foto do produto, garantindo miniaturas na vitrine, no carrinho, na busca, nas abas de gestão (`Novos`, `Aceitos`, `Concluídos`, `Cancelados`) e nas comandas (`ComandaPedido` e `PedidoAceitoDialog`).
- Suporte a pagamentos múltiplos (`List<PagamentoParcial>`) acessados prioritariamente via getter `pedido.todosPagamentos`.
- Impressão térmica padrão de 58mm e 80mm gerada em PDF via `ImpressaoService`.
- Controle de estoque com unidades (`un`, `g`, `ml`) e baixa automática sugerida (`BaixaEstoqueDialog`) com ajuste humano obrigatório.
- **Leitor de Código de Barras e Bipador Rápido:**
  - O modelo `ItemLoja` armazena `codigoBarras` e `precoCusto`.
  - No diálogo `NovaVendaDialog`, a busca aceita leitores de código de barras USB (bipadores). Ao pressionar Enter ou bipar o código exato, o item é adicionado imediatamente ao carrinho e o campo é limpo para a próxima leitura.
  - O catálogo de produtos na venda exibe os itens cadastrados sem limites artificiais de exibição (`take(4)`/`take(3)` removidos), permitindo rolagem fluida.
- **Estoque em Tempo Real e Prioridade para Categorias (`NovaVendaDialog`):**
  - Cada item exibe o saldo de estoque real atualizado (`Est: X un` ou badge vermelho `Esgotado` quando $\le 0$).
  - **Ordem de Preferência na Abertura:** Ao abrir a janela de Nova Venda (busca em branco), o container "Produto Solicitado" renderiza **primeiro todas as categorias disponíveis** e, logo abaixo, os itens soltos, permitindo acesso rápido a grupos de produtos.
- **Busca Rápida de Pedidos em "Concluídos" e "Cancelados" (`GestaoLojaContainer`):**
  - Campo de busca no topo das abas "Concluídos" e "Cancelados" filtrando instantaneamente por número do pedido (`#0001`), cliente, produto ou descrição de itens com limpeza ágil e estado vazio contextualizado.
- **Aba "Ajustes" e "Ajustes do Perfil" (`AbaLoja.interface`):**
  - Renomeada a aba e o botão inferior de "Interface" para **"Ajustes"** ("Ajustes do Perfil"), concentrando todas as configurações operacionais do lojista:
    - **Container "Comandos":** Gerenciamento e atribuição interativa das teclas de atalho (<kbd>F1</kbd> a <kbd>F8</kbd>) para ações de gestão ("Nova Venda", "Clientes", "Caixa", "Relatórios", "Impressora", "Financeiro", "Status da Loja" ou "Desativado") e tecla fixa <kbd>Esc</kbd> ("Voltar / Fechar Janelas"), persistido em `Loja.atalhosTeclado`.
    - **Container "Tempo de Conclusão dos Pedidos":** Migrado da aba Dados para Ajustes.
    - **Container "Sons e Alertas do Sistema":** Migrado da aba Dados para Ajustes.
  - A aba **"Dados"** permanece despoluída, focando estritamente em Formulário de Dados da Loja, Usuários Participantes e Galeria/Anexos.
- **Ação Imediata ao Clicar em Notificações (`NotificacoesDialog`):**
  - Ao tocar em um alerta de estoque baixo ou esgotado na central de notificações (sino), a janela é fechada e abre imediatamente o diálogo `MovimentoEstoqueDialog` com o item e tipo "Entrada" pré-configurados, permitindo reabastecimento imediato e persistência direta no cofre da loja.
- **Atalhos Globais de Teclado no Desktop (`CallbackShortcuts`):**
  - Teclas <kbd>F1</kbd> a <kbd>F8</kbd> dinâmicas mapeadas para as ações definidas no container "Comandos", além de <kbd>Esc</kbd> para fechar modais e diálogos.
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
- **Lançamento de Itens:** Permite adicionar produtos com adicionais e acompanhamentos dinâmicos de grupos de componentes vinculados.
- **Impressão de Conferência:** Emite via `ImpressaoService.imprimirConferenciaMesa` o comprovante de pré-fechamento térmico em 58mm ou 80mm.
- **Múltiplos Pagamentos e Divisão de Conta:** No fechamento (`FecharContaMesaDialog`), permite pagamento único ou parcelamento dinâmico em múltiplas formas de pagamento (dividindo a conta entre várias pessoas com cálculo automático de saldo restante), botão de acréscimo de 10% de atendimento e descontos.
- **Transferência e Unificação de Mesas:** Permite transferir uma comanda para outra mesa livre ou unir comandas existentes (`TransferirMesaDialog`), registrando ação de auditoria (`TipoAcao.mesaTransferida`).

### 7.5 Ficha do Cliente e Extrato em PDF (`features/pdv/views/widgets/clientes_dialog.dart`)
- **Extrato Financeiro e de Compras:** Ao tocar em um cliente cadastrado no diálogo de clientes, o lojista visualiza o valor total acumulado já gasto e o botão **"Exportar Extrato PDF"**.
- O `ImpressaoService.exportarExtratoClientePDF` gera um documento paginado em formato A4 contendo dados cadastrais, saldo devedor a prazo em aberto e tabela completa com data, número do pedido, itens e valores.

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
- **Tipografia e Família de Letras Personalizável:**
  - O usuário pode definir o modelo de fonte da comanda térmica (`modeloFonte`):
    - `belleza`: Fonte padrão oficial do ecossistema Nous, carregada dinamicamente via `rootBundle.load('assets/fonts/Belleza-Regular.ttf')`.
    - `padrao`: Sem serifa limpa (*Helvetica*).
    - `mono`: Monoespaçada clássica de máquina/cupom (*Courier*).
    - `serifada`: Clássica com serifa (*Times*).
- **Prévia Dinâmica Integrada com Variações Históricas do Anarquismo:**
  - No diálogo de impressora (`ImpressoraDialog`), a comanda simulada é renderizada **diretamente dentro do container de calibração bilateral**, variando o padding em tempo real conforme os ajustes de mm.
  - Sorteia dinamicamente 1 dos 10 perfis históricos anarquistas e do Nous (Makhno, Bakunin, Malatesta, Kropotkin, Emma Goldman, Durruti, Maria Lacerda de Moura, Comuna de Paris, CNT/FAI e Nous Autogestão).
  - Responde em tempo real a todos os seletores de dados do cliente (CNPJ, telefone, endereço, e-mail, redes sociais e descrição), integrando os canais oficiais do Nous (`nousstudios72@gmail.com`, `@nous.studios72`).
  - **Formatação Resiliente contra Esmagamento e Overflows:**
    - Renderiza dados do cliente com `linhaDadoCliente` onde o rótulo é mantido intacto e o valor reside em `Expanded(softWrap: true)` alinhado à direita.
    - **Renderização Adaptativa de Itens e Preços (`linhaComanda`):** Se a coluna direita for valor monetário (`R$ ...`), ela mantém largura natural e `softWrap: false` (nunca quebra na vertical letra por letra nem sofre compressão), enquanto a coluna esquerda (nome do produto) recebe `Expanded(softWrap: true)`, quebrando suavemente em múltiplas linhas sem estourar o container.
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
- **Resumo Financeiro Diário com Exportação em PDF:**
  - O botão "Financeiro" na aba Gestão da loja abre diretamente no período "Hoje", apresentando vendas, pagamentos, sugestão de divisão igualitária e botão "Exportar PDF" gerado em folha A4.

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
- **Demonstrativo do Resultado do Exercício — DRE Simples (`FinanceiroView`):**
  - Botão "DRE Simples" na barra de ações financeiras. Exibe popup centralizado com Receita Operacional Bruta, (-) Custos das Mercadorias/Insumos (CMV), (=) Lucro Bruto com margem %, (-) Pagamentos a Trabalhadores e (=) Resultado Líquido com margem %, além de botão de exportação direta em PDF.
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
