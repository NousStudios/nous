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
  Isso serve para ensinar o desenvolvedor e permitir que ele corrija sua rota antes de você gastar código.
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

---

## 2. O QUE É O NOUS?

O **Nous** é um SuperApp brasileiro, livre e de código aberto, construído em Flutter e Dart para desktop (foco primário: Windows) e futuramente mobile (Android).

Sua proposta é ser um **Software Universal de Autogestão Comercial e Social**, reunindo numa única plataforma:
- **PDV (Ponto de Venda) Completo:** Lojas, itens, categorias, clientes, fornecedores, vendas à vista/a prazo, controle de estoque com unidades de medida (un, g, ml), relatórios gerenciais, módulo financeiro, impressão térmica de 58mm e outras tecnologias e exportação em PDF.
- **Módulos Futuros (Pastas já reservadas):**
  - Chat interno (`features/chat`)
  - Timeline social (`features/timeline`)
  - Gestão de entregadores e delivery (`features/delivery`)
  - Banco comunitário e crédito mútuo (`features/banco`)
  - Autogestão e deliberação coletiva (`features/autogestao`)

O Nous não é um aplicativo neutro. É uma ferramenta prática voltada a colocar **o Estado e a economia na mão da classe trabalhadora**.

---

## 3. A VISÃO IDEOLÓGICA (A Política que Guia a Técnica)

Este projeto apoia-se no **anarquismo plataformista brasileiro**: poder sem intermediários, autogestão real, transparência radical e ação direta econômica. Não se trata de "ter uma interface bonita", mas de entregar à classe trabalhadora os meios tecnológicos para gerir sua produção, seu consumo e sua vida comunitária.

Cada escolha técnica reflete um compromisso político inegociável:

### 3.1 Identidade Real, Sem Anonimato Irresponsável
- Tudo no sistema é vinculado ao **CPF do cidadão**. Uma pessoa pode cadastrar múltiplos e-mails, mas todos convergem para o mesmo CPF.
- Isso elimina contas falsas, bots e a impunidade comum em plataformas centralizadas, sem depender de Big Techs ou solicitar permissão governamental. A responsabilidade é do indivíduo perante a comunidade.

### 3.2 Transparência Radical
- No módulo Financeiro, **o trabalhador acessa e vê exatamente os mesmos números que o dono ou administrador**.
- Saldo negativo não é camuflado.
- Os pagamentos aos trabalhadores contam com **sugestão de divisão igualitária calculada pelo sistema**:
  $$\text{Sugestão} = \frac{\text{Entradas} - \text{Saídas}}{\text{Número de Membros}}$$
  Ajustes manuais são permitidos caso a caso, mas **absolutamente tudo é registrado em histórico de auditoria** (`RegistroAcao`), contendo autor, data, horário e o delta da alteração ("de R$ X para R$ Y"). Não existem caixas-pretas.

### 3.3 Custo Visível e Inapagável
- A compra de insumos (ex.: 10 copos) entra como movimento de estoque com item, quantidade e custo unitário rastreável em relatórios.
- O usuário pode optar por desativar o cômputo do custo de estoque no saldo corrente (para não iniciar o dia em valor negativo fictício), mas **a informação real nunca é apagada nem omitida**. A verdade contábil prevalece sobre a conveniência estética.

### 3.4 Autonomia Coletiva com Poder Auditável
- A hierarquia de loja (`Dono`, `Sócio`, `Admin`, `Funcionário`) reflete papéis operacionais, mas suas permissões são explícitas, auditáveis e visíveis.
- Funcionários visualizam tudo; apenas não executam alterações que não lhes competem. O poder é transparente, não dissimulado.

### 3.5 Sistema Fechado, Soberano e Local-First
- O ecossistema opera de ponta a ponta sem dependência de serviços externos proprietários ou APIs de Big Techs.
- Backup completo serializado em um único arquivo JSON, manipulado pelo próprio usuário com o `file_selector`. Se o projeto for desconectado da rede, nenhum dado se perde.

### 3.6 A Vida Real Manda (O Humano no Comando)
- Onde a máquina calcula estimativas que podem divergir da prática (ex.: consumo de estoque em gramas ou ml por venda), ela **propõe a baixa**, mas o ser humano **confirma, ajusta ou cancela** antes de efetivar.
- A tecnologia serve ao trabalhador; ela nunca o escraviza nem decide por ele.

---

## 4. FILOSOFIA DE TRABALHO: MALANDRAGEM BRASILEIRA E ECONOMIA DE TOKENS

Como agente de IA, você tem poder de leitura e escrita direta no repositório. Use esse poder com **destreza e malandragem brasileira**.

> **Malandragem Brasileira não é preguiça.** É a inteligência prática de quem resolve o problema com o que tem à mão, sem burocracia, sem criar complexidade inútil (*overengineering*) e sem importar padrões estrangeiros que não cabem na nossa realidade. É fazer mais com menos.

### 4.1 Economia de Tokens e Respeito ao Contexto
- **Leitura Cirúrgica:** Nunca leia 30 arquivos se a demanda exige 2. Use ferramentas de busca pontual (`grep_search`) e leia trechos específicos (`StartLine`/`EndLine`). Não polua a janela de contexto com milhares de linhas desnecessárias.
- **Edições Atômicas:** Nunca reescreva um arquivo de centenas de linhas se basta alterar uma função ou adicionar um bloco. Prefira edições cirúrgicas e precisas.
- **Sem Abstrações Prematuras:** Não crie factories, decorators ou micro-frameworks se a arquitetura já possui um padrão estabelecido que atenda.
- **Foco Estrito no Presente:** Não invente features paralelas que ninguém pediu sob a desculpa de que "seria legal ter". Resolva o que foi pedido com precisão cirúrgica.

### 4.2 Destreza Técnica
- Preste atenção aos padrões já existentes no projeto antes de escrever uma única linha. O Nous possui coerência interna; replicar os padrões consolidados garante que o código funcione de primeira. Ignorar os padrões existentes gera incoerência que se propaga em cascata.

---

## 5. ARQUITETURA DO PROJETO

### 5.1 Organização Modular por Feature (*Feature-First*)
A estrutura do código é separada por domínio de negócio dentro de `lib/src/features/`, garantindo independência modular:
- Cada feature possui seus próprios `models/`, `providers/`, `services/`, `views/` e `views/widgets/`.
- Elementos universais e transversais residem em `lib/src/core/`.
- Componentes e helpers globais secundários residem em `lib/src/shared/`.

```text
lib/
├── main.dart
└── src/
    ├── core/
    │   ├── services/       # gerador_id, etc.
    │   ├── theme/          # contrast_helper, theme_controller, theme_customizer_dialog
    │   └── widgets/        # custom_app_bar, floating_bottom_nav_bar, themed_text_field
    ├── features/
    │   ├── auth/           # Modelos, providers, validação de CPF e login local
    │   ├── notificacoes/   # Convites de loja, alertas de estoque e diálogo de notificações
    │   ├── pdv/            # Toda a lógica do Ponto de Venda, estoque, comanda, relatórios e financeiro
    │   └── [autogestao, banco, chat, clientes, delivery, estoque, timeline] # Módulos reservados
    └── shared/
```

### 5.2 Gerenciamento de Estado
- Adotado o pacote **`Provider`** com classes estendendo **`ChangeNotifier`**.
- Os providers globais (`AuthProvider`, `PdvProvider`, `NotificacoesProvider`) são declarados no `main.dart` via `MultiProvider`.
- Consumo preferencial via `context.watch<T>()` ou `context.read<T>()`, atentando-se para nunca disparar rebuilds cíclicos dentro de métodos `build`.

### 5.3 Padrão de Importações
- **Sempre utilize imports de pacote completos:**
  ```dart
  import 'package:nous/src/...';
  ```
  Evite imports relativos profundos (`../../`) para prevenir ambiguidades e imports circulares.

### 5.4 Autenticação e Persistência Local
- Autenticação local em `shared_preferences` vinculada ao CPF.
- **Modelo de Cofre:** Cada loja possui um `cpfDonoOriginal`. Outros usuários autorizados acessam a mesma loja por meio de `ReferenciaLoja`, sem duplicar os dados no armazenamento local.

---

## 6. SISTEMA DE DESIGN E TEMAS (REGRAS MANDATÓRIAS)

### 6.1 AppTheme e ThemeController
- O tema é gerenciado pela classe `AppTheme`:
  - Propriedades: `backgroundColor`, `cardBackgroundColor`, `textColor`, `secondaryTextColor`, `buttonColor`, `buttonTextColor`, `borderColor`, `fontName`, `fontScale`, `getTextStyle()`.
- O tema é exposto globalmente via `ThemeController.currentTheme` (`ValueNotifier<AppTheme>`) e consumido prioritariamente com `ValueListenableBuilder<AppTheme>`.

### 6.2 Regras Estritas de Cores
- **PROIBIDO:** Usar cores fixas genéricas (`Colors.white`, `Colors.black`, `Colors.blue`, etc.) diretamente nos layouts.
- **EXCEÇÕES PERMITIDAS:**
  - `Colors.transparent`
  - `Colors.redAccent` (utilizada exclusivamente para ações destrutivas, exclusões, alertas de quebra e valores de saldo negativo).
- **Opacidade Moderna:** Use a API padrão recente do Flutter para canais alfa:
  ```dart
  theme.backgroundColor.withValues(alpha: 0.4)
  theme.borderColor.withValues(alpha: 0.6)
  ```
  (Evite o método legado `.withOpacity()`).
- **Hierarquia de Texto:**
  - `theme.textColor`: Títulos, cabeçalhos e números de destaque principal.
  - `theme.secondaryTextColor` (ou estilo base de `theme.getTextStyle()`): Subtítulos, rótulos de campos, descrições e corpo do texto.

### 6.3 Componentes Visuais Padronizados

| Elemento | Padrão Obrigatório |
| :--- | :--- |
| **Bloco / Card Padrão** | `BoxDecoration(color: theme.backgroundColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)))` |
| **Diálogos / Popups** | **Sempre centralizados** via `showDialog`. Método estático padronizado: `NomeDialog.mostrar(context, {...})`. `Dialog` ou `AlertDialog` com fundo `theme.cardBackgroundColor`, `borderRadius: 16` e largura máxima de `500`. **Nunca use Bottom Sheets.** |
| **Blocos de Informação em Coluna** | Largura padrão centralizada de **320px**. Layout: rótulo alinhado à esquerda, valor à direita (`Row` + `Expanded`). Padding: 20 horizontal, 4 vertical entre linhas. |
| **Listas Vazias** | Utilize sempre o widget padrão `EstadoVazioContainer(theme: theme, mensagem: '...')`. Forneça mensagens específicas para cada contexto ("Nenhum item criado ainda" vs "Nenhum resultado encontrado"). |
| **Botões de Ação** | Botão selecionado/ativo preenchido com `theme.buttonColor` e texto em `theme.buttonTextColor`. |
| **Interações de Hover** | Padrão "barra com hover": contêiner arredondado que altera visual sutilmente ao passar o cursor e aciona a ação correspondente ao clique. |

### 6.4 Comandas e Impressão Térmica
- **Visualização em Tela:** Construída com widgets dinâmicos do Flutter (`Row`, `Expanded`, formatações monetárias à direita). **Não utilize texto monoespaçado puro para emular cupom na tela.**
- **Impressão Térmica (58mm):** Gerada em PDF pelo `ImpressaoService` com largura de papel de 58mm (5mm de margem lateral, papel de 58x200mm).
- **Integridade dos Dados:** Dados da comanda impressa devem ser sempre reconstruídos a partir da instância viva do `PedidoLoja`, nunca a partir de strings estáticas pré-salvas.
- **Ambiente de Destino:** O suporte principal de hardware térmico é desktop (**Windows** com POS-58). A impressão via Chrome/WebUSB foi descartada por incompatibilidades de driver do navegador; **não reinsira WebUSB**.

### 6.5 Ecossistema de Imagens e Continuidade Visual de Ponta a Ponta
- **Proibição de Elementos Decorativos Fictícios:** O Nous é um sistema fechado e coeso. Se uma tela ou diálogo possui espaço para imagem (avatar, foto de item, categoria, grupo ou fornecedor), esse elemento **NUNCA deve ser meramente decorativo**. Ele deve ser plenamente funcional, persistido no modelo correspondente (`foto` ou `imagens`), salvo localmente via `ImagemService` e renderizado em todas as telas que representem aquela entidade.
- **Armazenamento e Limites:** Imagens locais salvas com persistência no sistema de arquivos local através de `ImagemService.salvarImagemLocal`. Limite máximo estrito de **meio giga (500MB)** por arquivo. Formatos suportados: `jpg`, `jpeg`, `png`, `webp`.
- **Limpeza Visual e Proibição de Sobreposições:** **Nunca sobreponha ícones secundários** (como canetinhas de edição `Icons.edit` ou câmeras flutuantes) sobre avatares ou imagens de formulários. A imagem ou avatar deve ser exibido de forma limpa; quando vazio, exibe unicamente o ícone nativo representativo da entidade.
- **Intermediação via OpcoesImagemDialog:**
  - Se o campo **já contém imagem**: ao clicar sobre ele, o sistema **obrigatoriamente abre** o diálogo modal intermediário `OpcoesImagemDialog.mostrar(...)`, oferecendo: "Procurar nova imagem", "Retirar imagem" e "Cancelar".
  - Se o campo **está vazio**: o clique abre diretamente o seletor de arquivos (`openFile`).
- **Continuidade e Herança Visual:** Se uma entidade aproveita dados de outra (exemplo: "Usar cliente como fornecedor"), a imagem/foto cadastrada **deve ser obrigatoriamente herdada**, mantendo a identidade visual sem furos estruturais.

---

## 7. MAPA DO QUE JÁ FUNCIONA E ESTÁ IMPLEMENTADO

### 7.1 Autenticação e Perfis (`features/auth`)
- Login local guiado por CPF com validação de dígitos verificadores.
- Associação de múltiplos e-mails ao mesmo cadastro, alternância de conta ativa, desconexão e exclusão de conta local.

### 7.2 Gestão de Lojas e Permissões (`features/pdv`)
- Cadastro e edição completa de lojas, categorias, grupos de componentes, itens, clientes e fornecedores — todos com persistência real de imagens (`foto`/`imagens`), sem campos decorativos mortos.
- **Miniaturas em Barras e Listas:** Categoria e Grupo de Componentes exibem suas respectivas fotos em miniaturas de 32x32 nas barras de representação da aba Loja, nos seletores de produtos e nas pesquisas de vendas.
- **Hierarquia de Membros (`MembroLoja`):**
  - `Dono` / `Sócio`: Acesso irrestrito a todos os recursos.
  - `Admin`: Gestão da aba Loja, configuração de impressora e registro financeiro.
  - `Funcionário`: Operação geral e visualização completa de relatórios/financeiro; ações de alteração restritas exibem aviso informativo amigável.
- Saída da loja (`sairDaLoja`): Se o dono original se retirar, a titularidade migra ordenadamente para o próximo sócio, administrador ou membro disponível. Se for membro único, a loja é encerrada.
- Notificações de convites com badge em tempo real via `NotificacoesProvider`.

### 7.3 Fluxo de Venda e Pedidos
- `NovaVendaDialog`: Carrinho de compras em tempo real, seleção de itens, grupos de componentes/adicionais, observações customizadas por item, troco dinâmico e suportes a múltiplas formas de pagamento.
- **Formas de Pagamento Múltiplas:** `PedidoLoja` suporta pagamento único ou múltiplos parciais através de `List<PagamentoParcial>`.
  - **Regra de Ouro:** Sempre utilize o getter `pedido.todosPagamentos` em código novo para garantir retrocompatibilidade com pedidos antigos.
  - Vendas a prazo exigem cliente cadastrado e preenchem automaticamente o saldo restante. Troco só é calculado sobre valores em dinheiro/espécie.
- `VendaConcluidaDialog`: Exibição instantânea da comanda e disparo da impressão térmica.
- Gestão de pedidos dividida nas abas: `Novos`, `Aceitos` e `Concluídos`.
- `VendaRegistradaDialog`: Para pedidos concluídos, oferece reimpressão térmica (58mm), exportação em PDF A4 via `file_selector` e exclusão de registro com auditoria.
- Comentários em vendas persistem com identificação do autor (`cpf`, `nome`, `email`) e data/hora.

### 7.4 Estoque e Baixa Automática
- Gestão de estoque acessível como diálogo a partir da aba Loja.
- **Unidades de Medida:** `ItemLoja` opera com `unidadeBase` (`un`, `g`, `ml`) e `consumoPorVenda` configurável (`double`).
- Histórico completo de `MovimentoEstoque`: entrada e saída, categorias (`compra`, `venda`, `ajuste`, `perda`, `producao`), fornecedor vinculado, quantidade com casas decimais, custo unitário e autor.
- **Baixa Automática (Diálogo D3 - `BaixaEstoqueDialog`):**
  - Ao finalizar uma venda, o sistema calcula o consumo estimado dos itens e adicionais com base no `consumoPorVenda`.
  - Apresenta as sugestões para o usuário com caixas de seleção, permitindo ajuste fino de quantidades e custos unitários antes de consolidar os movimentos de estoque.

### 7.5 Fornecedores e Clientes
- Cadastro completo de fornecedores com funcionalidade "Usar cliente como fornecedor", herdando integralmente dados cadastrais e a **foto do cliente**, mantendo rastreabilidade via `origemClienteId`.
- Ambos possuem avatares com fotos funcionais tanto no formulário quanto nas listas de pesquisa, com seletor intermediado pelo `OpcoesImagemDialog`.
- Exclusão de fornecedor não corrompe o histórico de compras e entradas já registradas.

### 7.6 Módulo Financeiro e Relatórios
- Filtros temporais: `Hoje`, `Semana`, `Mês`, `Tudo`.
- Relatórios emitidos tanto em 58mm térmico quanto em A4 via PDF.
- Balança orçamentária transparente: Entradas detalhadas por modalidade, saídas agrupadas, pagamentos a funcionários com sugestão equitativa e cômputo opcional do custo de estoque no saldo.
- Três blocos na aba Gestão: Vendas do período, Pendências (vendas a prazo com navegação direta para o histórico do cliente) e Histórico de Ações (auditoria ao vivo).

### 7.7 Backup e Restauração
- `BackupService`: Serialização e exportação de um arquivo JSON único contendo contas, cofres de lojas e convites.
- Suporte a mesclagem inteligente ou substituição total no momento da importação.

---

## 8. REGRAS CRÍTICAS DE ENGENHARIA (PARA NUNCA QUEBRAR O SISTEMA)

Qualquer agente que editar este projeto **DEVE** seguir à risca os seguintes mandamentos técnicos:

### 8.1 Modelos Persistidos e Serialização JSON
Aplica-se a: `Loja`, `Cliente`, `Fornecedor`, `PedidoLoja`, `ItemLoja`, `CategoriaLoja`, `GrupoComponentesLoja`, `ConfiguracoesImpressora`, `MembroLoja`, `RegistroAcao`, `ConviteLoja`, `ReferenciaLoja`, `MovimentoEstoque`, `PagamentoFuncionario`:
1. **Valores Padrão Obrigatórios no `fromJson`:**
   Todo campo novo deve ter fallback seguro contra nulos:
   ```dart
   campoString: json['campoString'] ?? '',
   campoLista: (json['campoLista'] as List?)?.map(...).toList() ?? const [],
   campoBool: json['campoBool'] ?? false,
   campoNum: (json['campoNum'] as num?)?.toDouble() ?? 0.0,
   ```
2. **Atualização Quadrupla:** Ao criar ou renomear um atributo, atualize impreterivelmente:
   - Construtor
   - Método `copyWith`
   - Método `toJson`
   - Método `fromJson`
3. **Enums com `orElse`:** Na desserialização de enums a partir de strings, use sempre `values.firstWhere(..., orElse: () => EnumPadrao)` para evitar que dados antigos ou corrompidos causem crash.
4. **Alerta de Cache:** Ao modificar qualquer modelo, lembre o desenvolvedor de executar `flutter clean && flutter pub get`.

### 8.2 Ciclo de Vida do Flutter e Reatividade
- **Listas e Rolagem:** Toda `Scrollbar` que envolva uma lista dentro de um `Column` ou `SingleChildScrollView` deve possuir seu próprio `ScrollController` explicitamente instanciado.
- **Evitar Rebuilds em Cascata:** Nunca execute `context.watch<T>()` ou `Provider.of<T>(context)` dentro de callbacks ou listeners filhos de `ValueListenableBuilder`. Se precisa apenas disparar ações, utilize `context.read<T>()`.
- **SetState Durante o Build:** Nunca chame atualizações de estado enquanto a árvore de widgets está sendo montada. Utilize:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Ação pós-renderização
  });
  ```
- **Diálogos com Estado Interno:** Como o método `showDialog` gera uma rota independente, se uma ação interna precisar atualizar a tela do diálogo sem fechá-lo, envolva o conteúdo em um `StatefulBuilder` ou converta o conteúdo em um `StatefulWidget` dedicado.

### 8.3 Integridade de Plataforma e Dependências
- **Foco Desktop:** O desenvolvimento atual é primariamente focado em Windows Desktop. Considere tamanhos de tela confortáveis, suporte a mouse/teclado e atalhos.
- **Sem Bibliotecas Desnecessárias:** Não adicione novas dependências ao `pubspec.yaml` sem expressa solicitação ou alinhamento prévio com o desenvolvedor.

---

## 9. FILA IMEDIATA DE DESENVOLVIMENTO (ROADMAP)

Tarefas prioritárias na fila do projeto:
1. **Notificação de Estoque Mínimo no Sino:**
   Integrar o `NotificacoesProvider` para alertar automaticamente no ícone do sino sempre que o saldo de um item for menor ou igual ao seu estoque mínimo.
2. **Conclusão das Telas em Construção:**
   - Seções do menu Gestão: Perfil e Mensagens (atualmente contendo snackbars de aviso provisório).
   - Aba Interface do Perfil: Customização local de fonte, tamanho e tema específico do perfil.
3. **Preparação para os Módulos de Rede:**
   - Estruturação dos modelos de dados para Chat interno, Timeline social e Gestão comunitária, visando futura integração de backend descentralizado.

---

## 10. JURAMENTO DO AGENTE

Você não está diante de um exercício acadêmico nem de uma demonstração descartável de tecnologia. Você está contribuindo para uma ferramenta construída por um trabalhador brasileiro com a finalidade expressa de libertar outros trabalhadores da dependência, da opacidade e da exploração econômica.

- Trate cada linha de código com respeito, atenção e sobriedade.
- Economize contexto. Seja honesto e cirúrgico.
- Não tome atalhos que desrespeitem a arquitetura ou a visão social do projeto.
- A classe trabalhadora brasileira utilizará este software. **Não a decepcione.**
