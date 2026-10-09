<a id="english"></a>

<p align="left">
  <a href="#english"><img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/us.svg" alt="English" width="24" /></a>
  &nbsp;
  <a href="#portugues"><img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Português do Brasil" width="24" /></a>
</p>

# Nous

**The State in the hands of the people, as software.**

<img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Brasil" width="20" /> An open-source Brazilian SuperApp for commercial and social self-management —
built on anarchist platformism 🏴‍☠️

🔗 **Links:** [linktr.ee/nous72](https://linktr.ee/nous72)

---

## What is Nous?

*Nous* (νοῦς) is Ancient Greek for intellect, reason — the mind's own eye,
the faculty that orders sense-data into understanding, as opposed to raw
sensation. This project takes that name seriously: it is an attempt to build
the computational manifestation of that concept — a platform that unifies
the institutions standing between the citizen and the resources of society,
the way *nous* itself is said to interpret and order the data of experience.

In plain terms: **Nous is a free, open-source SuperApp** — a single platform
meant to eventually carry point-of-sale, chat, a social timeline, delivery,
banking, and cooperative self-management tools, all interconnected as one
social network for economic and political self-organization.

This is not a neutral piece of software. It is built on **Brazilian
Platformism** — a Brazilian adaptation of the 1926 *Organizational Platform
of the General Union of Anarchists* (Makhno, Arshinov, and others) — with one
governing intent: **depersonalization and decentralization** of political
and economic power. No ruling class, no platform-owner elite, no algorithm
tuned to keep you scrolling. Software as the infrastructure of direct
democracy, not as a product competing for your attention.

## Why It's Different

Most of the apps you use daily are designed to extract as much of your time
and money as possible, with the platform's internal workings hidden from
you. Nous inverts that logic on purpose:

- **Radical transparency, by design.** The PDV (point-of-sale) module
  doesn't just process sales — it exposes the micromanagement of the
  business to everyone connected to it: workers, customers, the community.
  No hidden margins, no opaque hierarchy. Financial visibility as a tool for
  class consciousness, not an afterthought.
- **No engagement traps.** Nothing in Nous is built to lock users into
  endless consumption loops or push irrelevant content. Every feature exists
  to serve a real, stated demand — nothing more.
- **Direct democracy over the platform itself.** Internal rules and
  planning aren't set by a company board; they're meant to be set by the
  people using the platform, through the same tools it gives them to run
  their own businesses and organizations.

## Current Status

Nous is in **active development**, built by a self-taught Brazilian developer — contributions, code review, and honest criticism from experienced developers are genuinely welcome; this project is too large, by design, for one person alone.

The currently operating core includes:
- **Citizen Identity (`features/auth`)**: Real identity tied to the citizen's CPF (Brazilian tax ID), multiple authenticated accounts on the same machine, comprehensive citizen profile data, and local sovereign credential management without reliance on Big Tech logins.
- **Participatory PDV (`features/pdv`)**: A complete, transparent Point of Sale system with specialized business profiles (Standard Store, Restaurant with open tables & tabs, Freight & Rides):
  - Multi-item catalog with persisted photos, categories, complementary component groups, barcode (EAN) support, cost prices, live real-time stock counters (`Est: X un` or `Esgotado`), and priority display for categories upon sales opening.
  - Fast sales workflow with clean initial focus state (showing only categories on blank search and individual items upon active search), TapRegion gesture protection ensuring flawless selection of categories and customer suggestions, dynamic percentage discount and surcharge calculation (`10%`, `5%`) updating live tickets and totals in real time, instant full text selection on payment tender amounts for effortless overwriting, sales draft auto-preservation across accidental dialog dismissals with clear-draft toolbar action, instant USB barcode scanner support, optional automatic thermal receipt printing upon sales completion, desktop keyboard shortcuts (<kbd>F1</kbd> to open Nova Venda, <kbd>Esc</kbd> to dismiss dialogs), and anti-data-loss protection confirming whether to save or discard completed sales.
  - Store Status & Daily Operational Overview (`StatusLojaView`): Real-time daily performance dashboard positioned above store status controls, presenting Today's Revenue (R$), Total Sales Today, Average Ticket (R$), and Cash Drawer Status (Open/Closed badge with exact live physical cash balance), fully transparent to all store workers.
  - Configurable estimated order completion timeout (under store "Dados" tab) with automated dialog check-ins asking if accepted orders have been completed.
  - Cash drawer & shift control (`TurnoCaixa`): opening float, cash-in reinforcements (suprimentos) and withdrawals (sangrias) with mandatory justification and audit trail, change-deducted net cash calculations, instant signed thermal receipt vouchers with reprint capability, blind drawer closing with tender breakdown (cash, credit, debit, PIX), discrepancy reconciliation, and printed thermal closing receipts.
  - Open Table & Tab Management for Restaurants: Table registry with live status (free/occupied), continuous ordering per responsible worker, item-level audit trails, 58mm/80mm thermal pre-bill checks, bill splitting across multiple payers, service fees (10%), discounts, and table transfers/merging.
  - Order and ticket workflow (New, Accepted, Completed, Cancelled with stock reversal & audit trail) with split/multiple payments support, direct in-dialog thermal ticket reprint button on accepted orders (`PedidoAceitoDialog`), strict reverse-chronological sorting (most recent on top for completed and cancelled tickets), instant keyword & ticket number search box in Completed and Cancelled tabs, and expanded ergonomic desktop order list.
  - Multi-unit inventory tracking (`un`, `g`, `ml`) with automatic deduction proposals, bidirectional purchase cost calculation ($C_{\text{unit}} = \frac{C_{\text{total}}}{Q}$), critical low-stock alerts (< 10 units) integrated into app-bar notifications with direct interactive stock replenishment navigation, and detailed Product Kardex Sheets (`FichaKardex`) tracking chronological lot entries, deductions, unit costs, and balances.
  - Customer & Supplier registry with adaptive CPF/CNPJ formatting, unified sovereign local auto-fill (`DadosLocaisService`), universal multi-field quick search (`correspondeABusca`) allowing instant filtering by customer/supplier name, street/address, house number, formatted/unformatted tax IDs and phone numbers, e-mail, social handles, or notes, safety confirmation modal with real-time balance previews for credit debt discharge ("Quitar valor" / "Quitar tudo"), and comprehensive A4 PDF customer account statements.
  - Cooperative financial management with real-time audit trail, algorithmic egalitarian profit/surplus division suggestions, Simple Income Statement (DRE) by period with gross/net profit margins, daily cash closing, and A4 PDF export.
  - Dedicated Store Settings tab ("Ajustes do Perfil") consolidating:
    - Keyboard Shortcuts ("Comandos"): Configurable function keys (<kbd>F1</kbd> to <kbd>F8</kbd>) mapped to key PDV actions (Nova Venda, Clientes, Caixa, Relatórios, Impressora, Financeiro, Status da Loja) and universal <kbd>Esc</kbd> dismissal.
    - Estimated order completion timeout with automated status confirmation dialogs.
    - Customizable System Sounds & Beeps (`SomService` / `Loja.sonsAlertas`) for New Orders, Timeouts, and Barcode/Item scans.
  - Thermal receipt printing (supporting both 58mm and 80mm rolls) with roll width selector, universal bilateral margin calibration (independent left/right mm fine-tuning preventing edge cuts across hardware brands like Knup, B&G, Elgin), unified typography architecture (`FontesApp`) with 11 industry-standard free fonts (Arial/Helvetica for sharp thermal paper clarity without ink bleeding, Courier monospace for column alignment, Open Sans, Roboto, Roboto Mono, Inter, Lato, Poppins, Montserrat, Times New Roman, and Belleza), dropdown selection identical to appearance settings, live in-dialog receipt preview, direct sample printing, and PDF exports.
- **Deliberative Notifications & Governance (`features/notificacoes`)**: Direct collective governance for store members with stock-alert aggregation, direct tap-to-replenish stock workflow syncing live balances, persisting transparent action audit logs, and horizontal swipe-to-dismiss gesture per session (reappearing on next launch if unresolved). Anti-despotic rules: owners cannot unilaterally remove other owners without explicit consent; partners cannot alter another partner's role without prior acceptance.
- **Local-First & Sovereignty**: Entirely offline and self-contained with a high-performance local SQLite relational engine (`sqflite_common_ffi` with ACID atomic transactions), automatic migration from legacy store vaults, single-file universal JSON backup/restore (`file_selector`) with non-destructive intelligent merging, active profile deduplication by CNPJ/tax ID, category preservation, and silent automatic daily local backups to `%APPDATA%\Nous\backups`.
- **Desktop Distribution & Single-Instance Protection**: Official standalone Inno Setup Windows test installer (`Nous_Instalador_v1.0.0_Versao_Teste.exe`) with branded multi-resolution app icon, native Win32 Named Mutex single-instance protection preventing duplicate process conflicts, and offline-tolerant update notification mechanism (`AtualizacaoService`).

Upcoming modules — internal chat, social timeline, autonomous delivery, community banking, and direct-democracy self-management — are planned and organized in the architectural roadmap.

**This is currently functional for desktop (Windows) and undergoing continuous refinement before public distribution.**

## Architecture

Nous is a Flutter/Dart application. A few structural decisions are worth
documenting clearly, since the goal is for a growing team — and eventually a
whole federation of contributors, not unlike the federalism this project's
politics call for — to work on this codebase without stepping on each
other's feet.

### Feature-first, not layer-first

The codebase is organized by **business feature**, not by technical layer.
Each folder under `lib/src/features/` (`auth`, `notificacoes`, `pdv`, and planned
modules: `autogestao`, `banco`, `chat`, `delivery`, `timeline`) is a self-contained
module, with its own `models/`, `providers/`, `services/`, and `views/`
inside it. Shared building blocks (theme, generic widgets, core services)
live in `lib/src/core/` instead of being duplicated per feature.

This matters at this project's scale: a team working on `delivery/` can move
fast without needing to touch, understand, or accidentally break `pdv/` or
`chat/`. Organizing by layer instead — one giant `models/` folder, one giant
`views/` folder — tends to work for small projects and becomes a bottleneck
as more contributors and more features arrive. For a SuperApp meant to
eventually cover commerce, social features, banking, and logistics under one
roof, feature-first is the more scalable choice for **team throughput**, and
it is the structure Nous already follows — a codebase organized, in its own
small way, along federative lines.

### State management: Provider

App state is managed with the `Provider` package. Each major feature area
that needs shared state exposes a `ChangeNotifier`-based provider
(`AuthProvider`, `PdvProvider`, `NotificacoesProvider`, and more to come), registered once in
`main.dart` via `MultiProvider` and made available to the whole widget tree.

### Theming

The UI is fully theme-driven through an `AppTheme` class (background, card
background, text colors, button colors, borders, font, and font scale) and a
`ThemeController` that broadcasts theme changes app-wide. Users can create
and save their own named themes. No screen hard-codes colors or fonts —
everything reads from the current `AppTheme`.

### An open question: scale to millions of users

Everything above describes how the **Flutter client** is organized — it does
not, by itself, address what it takes to support millions of concurrent
users on a real-time, interconnected, social-network-style platform. That is
a **backend and infrastructure problem** (databases, real-time messaging,
horizontal scaling, likely a services-oriented backend rather than a single
monolith), and it has **not been designed yet**. This is flagged here
deliberately, as an open architectural decision the project will need to
face head-on once the client-side foundation — starting with PDV — is
solid, not something the current folder structure already solves.

## Project Structure

```
lib/
├── main.dart
└── src/
    ├── core/                 # Shared across all features
    │   ├── constants/
    │   ├── routes/
    │   ├── services/
    │   ├── theme/            # AppTheme, ThemeController, theme customizer
    │   └── widgets/          # Generic shared widgets (app bar, empty states...)
    │
    └── features/
        ├── auth/             # Citizen identity, CPF anchoring, profile
        ├── notificacoes/     # Deliberative governance, invites, consent requests
        ├── pdv/              # Complete point of sale, inventory, finance & printing
        ├── autogestao/       # Direct democracy & self-management tools (planned)
        ├── banco/            # Community bank & mutual credit (planned)
        ├── chat/             # Internal chat (planned)
        ├── delivery/         # Autonomous delivery network (planned)
        └── timeline/         # Social timeline (planned)
```

Each feature folder follows the same internal shape as it grows:
`models/`, `providers/`, `services/`, `views/` (with `views/widgets/` for
screen-specific components).

## Roadmap

1. **PDV & Governance Core** — functional and evolving. Complete point of sale, USB barcode scanning, shift & cash drawer control (`TurnoCaixa`), multi-unit inventory control (`un`/`g`/`ml`), customers/suppliers with sovereign auto-fill, egalitarian financial module, 58mm/80mm thermal printing with bilateral calibration, automatic daily backup, and consent-based collective governance.
2. Internal Chat (`features/chat`)
3. Social Timeline (`features/timeline`)
4. Autonomous Delivery Network (`features/delivery`), with driver-negotiated route pricing and direct dispatch
5. Community Bank & Mutual Credit (`features/banco`), including platform-managed public accounts
6. Direct-Democracy Self-Management (`features/autogestao`) for collective rule deliberation
7. Decentralized / federated backend architecture designed for real-time, social-network-scale traffic

## Media

The theoretical and political foundation of Nous — including the full book
*Nous* by Leonardo Tadeu Dalosa — is written in Brazilian Portuguese and
available on the [Linktree](https://linktr.ee/nous72) above.

The first piece of media released for this project was **"Ei, TRABALHADOR!
Este vídeo te INTERESSA!"** ("Hey, WORKER! This video INTERESTS you!"), a
40-minute video laying out the project in detail. The 22-episode series
**"Ei, você! Este vídeo te INTERESSA!"** ("Hey, you! This video INTERESTS
you!") was produced *afterwards*, as a set of shorter, symbolic episodes
meant to build an audience and direct viewers back to that original,
longer video.

## Contributing

This is a beginner-led project, and help is genuinely welcome — code review,
architecture feedback, or simply pointing out mistakes. Open an issue or a
pull request. Unity of theory, unity of tactics: read the book before you
argue about the politics, but the code speaks for itself.


---

<a id="portugues"></a>

<p align="left">
  <a href="#english"><img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/us.svg" alt="English" width="24" /></a>
  &nbsp;
  <a href="#portugues"><img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Português do Brasil" width="24" /></a>
</p>

## <img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Brasil" width="20" /> PORTUGUÊS DO BRASIL ##





# Nous

**O Estado na mão do povo, como um software.**

<img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Brasil" width="20" /> Um SuperApp brasileiro de código aberto para autogestão comercial e social —
construído sobre o plataformismo anarquista 🏴‍☠️

🔗 **Links:** [linktr.ee/nous72](https://linktr.ee/nous72)

---

## O que é o Nous?

*Nous* (νοῦς) é o termo grego para intelecto, razão — o "olho da mente", a
faculdade que ordena os dados dos sentidos em compreensão, em oposição à
sensação bruta. Este projeto leva esse nome a sério: é uma tentativa de
construir a manifestação computacional desse conceito — uma plataforma que
unifica as instituições que fazem a ponte entre o cidadão e os recursos da
sociedade, do mesmo modo que o próprio *nous* é dito interpretar e ordenar os
dados da experiência.

Em termos práticos: **o Nous é um SuperApp livre e de código aberto** — uma
única plataforma pensada para, no futuro, reunir ponto de venda, chat, uma
timeline social, delivery, banco e ferramentas de autogestão cooperativa,
tudo interligado como uma única rede social voltada à auto-organização
econômica e política.

Este não é um software neutro. Ele é construído sobre o **Plataformismo
Brasileiro** — uma adaptação brasileira da *Plataforma Organizacional da
União Geral dos Anarquistas* de 1926 (Makhno, Arshinov e outros) — com uma
intenção que rege tudo: a **despersonalização e a descentralização** do
poder político e econômico. Nenhuma classe governante, nenhuma elite
proprietária da plataforma, nenhum algoritmo ajustado para te prender
rolando a tela. Software como infraestrutura da democracia direta, não como
produto disputando sua atenção.

## Por que é diferente

A maioria dos aplicativos que você usa no dia a dia é projetada para extrair
o máximo possível do seu tempo e do seu dinheiro, com o funcionamento
interno da plataforma escondido de você. O Nous inverte essa lógica de
propósito:

- **Transparência radical, por projeto.** O módulo de PDV (Ponto de Venda)
  não só processa vendas — ele expõe a microgestão do negócio para todos os
  que se relacionam com ele: funcionários, clientes, a comunidade. Sem
  margens escondidas, sem hierarquia opaca. Transparência financeira como
  ferramenta de consciência de classe, não como detalhe secundário.
- **Sem armadilhas de engajamento.** Nada no Nous é feito para prender o
  usuário num ciclo infinito de consumo ou empurrar conteúdo irrelevante.
  Cada funcionalidade existe para atender uma demanda real e declarada —
  nada além disso.
- **Democracia direta sobre a própria plataforma.** As regras internas e o
  planejamento não são definidos por uma diretoria de empresa; devem ser
  definidos pelas próprias pessoas que usam a plataforma, com as mesmas
  ferramentas que ela oferece para administrarem seus próprios negócios e
  organizações.

## Estado Atual

O Nous está em **desenvolvimento ativo**, construído por um desenvolvedor autodidata brasileiro — contribuições, revisão de código e críticas honestas de desenvolvedores experientes são muito bem-vindas; este projeto é grande demais, de propósito, para uma pessoa só.

O núcleo atualmente funcional reúne:
- **Identidade Cidadã (`features/auth`)**: Identidade real ancorada no CPF do cidadão, suporte a múltiplas contas no mesmo dispositivo, perfil civil completo e soberania local sem dependência de autenticação de Big Techs.
- **PDV Participativo Completo (`features/pdv`)**: Ponto de Venda integral e transparente com perfis profissionais especializados (Loja Padrão, Restaurante com mesas/comandas abertas, Fretes e Viagens):
  - Catálogo de itens com fotos persistidas, categorias, grupos de adicionais/componentes, código de barras (EAN), preço de custo, saldo de estoque em tempo real (`Est: X un` ou `Esgotado`) e priorização de categorias na abertura da venda.
  - Fluxo ágil de vendas com foco inicial limpo (exibe apenas categorias na busca em branco e itens soltos apenas mediante pesquisa ativa), proteção de toque via TapRegion garantindo seleção perfeita de categorias e sugestões de clientes sem fechamento prematuro, cálculo dinâmico de desconto e acréscimo em porcentagem (`%`) ou valor fixo em reais atualizando a comanda viva e totais em tempo real, seleção numérica total instantânea no valor das formas de pagamento para edição rápida sem apagar caractere por caractere, preservação automática de rascunhos de venda contra fechamentos acidentais da janela com botão de limpeza rápida, leitor USB (bipador), atalhos de teclado no desktop (<kbd>F1</kbd> para Nova Venda, <kbd>Esc</kbd> para fechar janelas) e proteção com confirmação contra descarte acidental de venda finalizada.
  - Resumo Operacional do Dia e Status da Loja (`StatusLojaView`): Painel gerencial no topo da tela (acima do interruptor de status da loja) exibindo métricas em tempo real — Faturamento do Dia (R$), Vendas Realizadas Hoje, Ticket Médio e Situação do Caixa (badge Aberto/Fechado com saldo real em espécie apurado no momento), visível para todos os trabalhadores em consonância com a transparência radical do Nous.
  - Tempo de conclusão geral de pedidos estipulável nas configurações da loja (aba "Dados"), com disparo automático de janela perguntando se pedidos aceitos decorridos já foram concluídos.
  - Gestão e controle de turno de caixa (`TurnoCaixa`): abertura com fundo de troco, suprimentos (reforços) e sangrias (retiradas) com justificativa e auditoria, apuração rigorosa de dinheiro líquido (deduzindo trocos devolvidos), fechamento cego com declaração por forma de pagamento, conferência de diferenças e impressão de comprovante térmico de fechamento.
  - Gestão de Mesas e Comandas Abertas para Restaurantes: Cadastro de mesas com status dinâmico (livre/ocupada), lançamento contínuo de itens por trabalhador responsável, histórico de auditoria por item, impressão térmica de conferência não-fiscal de 58mm ou 80mm, divisão dinâmica de contas ("rachar a conta" em múltiplos pagamentos), taxa opcional de 10% de atendimento, descontos e transferência/unificação de mesas.
  - Gestão de pedidos e fluxo de comandas em tempo real (Novos, Aceitos, Concluídos, Cancelados com estorno de estoque e auditoria) com suporte a pagamentos parciais múltiplos, reimpressão térmica direta em pedidos aceitos, busca rápida por número (#0001), cliente ou produto nas abas Concluídos e Cancelados e lista de pedidos desktop ampliada.
  - Controle de estoque multivariado (`un`, `g`, `ml`) com proposta automática de baixa, confirmação humana mandatória e notificações de estoque baixo/esgotado interativas com reposição direta via diálogo de entrada de mercadorias.
  - Aba dedicada "Ajustes do Perfil" (antiga Interface do Perfil):
    - Container "Comandos": Menu configurável de teclas de atalho de função (<kbd>F1</kbd> a <kbd>F8</kbd>) e <kbd>Esc</kbd> universal para as ações de gestão da loja.
    - Container "Tempo de Conclusão dos Pedidos": Definição de prazo médio com verificação automática de status de pedidos aceitos.
    - Container "Sons e Alertas do Sistema": Personalização e teste de áudio/bip para novos pedidos, prazos e leituras de códigos de barra.
  - Cadastro de clientes e fornecedores com máscara adaptável CPF/CNPJ, autopreenchimento local soberano unificado (`DadosLocaisService`) e exportação de extrato completo de compras em PDF A4 com cálculo de dívida a prazo em tempo real.
  - Módulo financeiro cooperativo com trilha de auditoria e cálculo algorítmico de sugestão de divisão igualitária dos excedentes entre os membros.
  - Impressão térmica padrão de 58mm e 80mm com seletor de largura de bobina, calibração bilateral universal de recuo (ajuste fino em milímetros à esquerda e à direita), seleção de modelo de fonte (Belleza, sem serifa, monoespaçada, serifada), prévia adaptativa de comanda resistente a fontes máximas (sem quebras verticais de preço ou estouros de margem), envio direto para impressora física e exportação em PDF.
- **Governança Coletiva e Notificações Deliberativas (`features/notificacoes`)**: Autogestão participativa para membros de lojas com resolução interativa de alertas de estoque crítico diretamente ao tocar no card da notificação, repondo saldo no cofre, gerando auditoria transparente em Ações e sincronizando a tela do PDV em tempo real. Regras anti-despóticas: donos não podem excluir outros donos sem consentimento mútuo; sócios não podem alterar o papel de outros sócios sem aceite explícito.
- **Soberano e Local-First**: 100% autônomo e offline, impulsionado por um banco relacional local SQLite de alta performance (`sqflite_common_ffi` com transações atômicas ACID), migração automática transparente, exportação/importação de backup completo em arquivo JSON único (`file_selector`) com mesclagem inteligente não-destrutiva, desduplicação ativa de perfis por CNPJ, preservação de categoria e backup diário automático silencioso mantido em `%APPDATA%\Nous\backups`.
- **Distribuição Desktop e Instância Única Nativa**: Instalador oficial para Windows (Inno Setup 6) em arquivo `.exe` único ultra-comprimido com ícone oficial do Nous, proteção nativa Win32 C++ contra múltiplas janelas abertas simultaneamente (evitando concorrência no SQLite) e sistema de verificação de atualizações local-first discreto (`AtualizacaoService`).

Os módulos futuros — chat interno, timeline social, rede autônoma de entregadores, banco comunitário e autogestão deliberativa — estão planejados e estruturados no roteiro.

**Atualmente funcional para desktop (Windows) e em constante refinamento antes da distribuição pública.**

## Arquitetura

O Nous é uma aplicação Flutter/Dart. Algumas decisões estruturais merecem
estar bem documentadas, já que o objetivo é que uma equipe cada vez maior —
e, no futuro, uma verdadeira federação de colaboradores, não muito diferente
do federalismo que a própria política deste projeto exige — consiga
trabalhar neste código sem atropelar o trabalho umas das outras.

### Organização por Feature, não por camada

O código é organizado por **assunto de negócio (feature)**, não por camada
técnica. Cada pasta dentro de `lib/src/features/` (`auth`, `notificacoes`, `pdv`,
e módulos planejados: `autogestao`, `banco`, `chat`, `delivery`, `timeline`) funciona
como um módulo independente, com seus próprios `models/`, `providers/`,
`services/` e `views/` dentro dela. As peças compartilhadas (tema, widgets
genéricos, serviços centrais) ficam em `lib/src/core/`, em vez de serem
duplicadas em cada feature.

Isso importa na escala deste projeto: uma equipe trabalhando em `delivery/`
consegue avançar rápido sem precisar mexer, entender ou quebrar
acidentalmente o `pdv/` ou o `chat/`. Organizar por camada, em vez disso —
uma pasta gigante de `models/`, outra de `views/` — costuma funcionar em
projetos pequenos e vira gargalo conforme mais colaboradores e mais
funcionalidades chegam. Para um SuperApp que deve, no futuro, cobrir
comércio, funcionalidades sociais, banco e logística sob o mesmo teto, a
organização por feature é a escolha mais escalável para a **produtividade da
equipe** — e é a estrutura que o Nous já segue: um código organizado, à sua
própria maneira, em linhas federativas.

### Gerenciamento de estado: Provider

O estado do app é gerenciado com o pacote `Provider`. Cada área principal
que precisa de estado compartilhado expõe um provider baseado em
`ChangeNotifier` (`AuthProvider`, `PdvProvider`, `NotificacoesProvider`, e outros que virão),
registrado uma única vez no `main.dart` via `MultiProvider` e disponível
para toda a árvore de widgets.

### Sistema de tema

A interface é 100% controlada por tema, através de uma classe `AppTheme`
(cor de fundo, cor de fundo dos cards, cores de texto, cor dos botões,
bordas, fonte e escala de fonte) e de um `ThemeController` que avisa o app
inteiro quando o tema muda. O usuário pode criar e salvar seus próprios
temas com nome. Nenhuma tela fixa cores ou fontes "no braço" — tudo vem do
`AppTheme` atual.

### Uma pergunta em aberto: escala para milhões de usuários

Tudo que foi descrito acima é sobre como o **cliente Flutter** está
organizado — isso, sozinho, não resolve o que é necessário para suportar
milhões de usuários simultâneos numa plataforma em tempo real, interligada,
em formato de rede social. Isso é um **problema de backend e
infraestrutura** (bancos de dados, mensageria em tempo real, escalonamento
horizontal, provavelmente um backend orientado a serviços em vez de um
monólito único), e **ainda não foi projetado**. Isso está sinalizado aqui de
propósito, como uma decisão de arquitetura em aberto que o projeto vai
precisar enfrentar de frente assim que a base do lado cliente — começando
pelo PDV — estiver sólida, não algo que a estrutura de pastas atual já
resolva sozinha.

## Estrutura do Projeto

```
lib/
├── main.dart
└── src/
    ├── core/                 # Compartilhado entre todas as features
    │   ├── constants/
    │   ├── routes/
    │   ├── services/
    │   ├── theme/            # AppTheme, ThemeController, customizador de tema
    │   └── widgets/          # Widgets genéricos compartilhados (app bar, empty states...)
    │
    └── features/
        ├── auth/             # Identidade cidadã, ancoragem em CPF, perfil
        ├── notificacoes/     # Governança deliberativa, convites, pedidos de consentimento
        ├── pdv/              # PDV completo, estoque, finanças & impressão térmica
        ├── autogestao/       # Ferramentas de autogestão e deliberação (planejado)
        ├── banco/            # Banco comunitário e crédito mútuo (planejado)
        ├── chat/             # Chat interno (planejado)
        ├── delivery/         # Rede autônoma de entregadores (planejado)
        └── timeline/         # Timeline social (planejado)
```

Cada pasta de feature segue o mesmo formato interno conforme cresce:
`models/`, `providers/`, `services/`, `views/` (com `views/widgets/` para
componentes específicos daquela tela).

## Roteiro (Roadmap)

1. **Núcleo de PDV e Governança** — funcional e em evolução contínua. Ponto de venda completo, leitor de código de barras USB (bipador), controle de turno de caixa (`TurnoCaixa`) com sangria/suprimento e conferência cega, estoque multivariado (`un`/`g`/`ml`) com cálculo automático de compras e alertas de estoque crítico (< 10 un) no sino da barra superior, clientes e fornecedores com autopreenchimento local soberano, financeiro cooperativo com divisão igualitária e fechamento diário em PDF, impressão térmica de 58mm e 80mm universal com calibração bilateral de recuo, tipografia configurável, prévia viva com perfis históricos do anarquismo e impressão direta de amostras, backup diário automático silencioso e instalador oficial Windows para testes (`Nous_Instalador_v1.0.0_Versao_Teste.exe`).
2. Chat interno (`features/chat`)
3. Timeline social (`features/timeline`)
4. Rede autônoma de entregadores (`features/delivery`), com negociação de rotas pelo próprio trabalhador
5. Banco comunitário e crédito mútuo (`features/banco`), incluindo contas públicas geridas pela plataforma
6. Ferramentas de autogestão e deliberação coletiva (`features/autogestao`) sobre as regras da própria plataforma
7. Arquitetura de backend federada/descentralizada projetada para tráfego em tempo real em escala social

## Mídia

A fundamentação teórica e política do Nous — incluindo o livro completo
*Nous*, de Leonardo Tadeu Dalosa — está escrita em português do Brasil e
disponível no [Linktree](https://linktr.ee/nous72) acima.

O primeiro material divulgado do projeto foi o vídeo **"Ei, TRABALHADOR!
Este vídeo te INTERESSA!"**, de 40 minutos, apresentando o projeto em
detalhes. A série de 22 episódios **"Ei, você! Este vídeo te INTERESSA!"**
foi produzida *depois*, como uma sequência de episódios menores e simbólicos
pensados para construir audiência e direcionar os espectadores de volta a
esse vídeo original, mais longo.

## Contribuindo

Este é um projeto liderado por um iniciante, e ajuda é genuinamente
bem-vinda — revisão de código, feedback de arquitetura, ou só apontar erros.
Abra uma issue ou um pull request. Unidade teórica, unidade tática: leia o
livro antes de discutir a política, mas o código fala por si só.
