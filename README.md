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
  - Multi-item catalog with persisted photos, image cropping and adjustment tool (`AjustarImagemDialog`), safety confirmation modals against accidental image deletion, categories, item variants (e.g. materials, sizes with dedicated prices), complementary component groups, barcode (EAN) support, cost prices, live real-time stock counters (`Est: X un` or `Esgotado`), priority display for categories upon sales opening, and **fluid touch/hold drag-and-drop reordering for products, categories, and component groups** on the store management screen.
  - Fast sales workflow with clean initial focus state (showing only categories on blank search and individual items upon active search), TapRegion gesture protection ensuring flawless selection of categories and customer suggestions, seamless item variant selector dialogs across all product selection paths (catalog, barcode scan, category view), dynamic percentage discount and surcharge calculation (`10%`, `5%`) updating live tickets and totals in real time, instant full text selection on payment tender amounts for effortless overwriting, sales draft auto-preservation across accidental dialog dismissals with clear-draft toolbar action, instant USB barcode scanner support, optional automatic thermal receipt printing upon sales completion, desktop keyboard shortcuts (<kbd>F1</kbd> to open Nova Venda, <kbd>Esc</kbd> to dismiss dialogs), and anti-data-loss protection confirming whether to save or discard completed sales.
  - **Full-Screen Cashier Counter Mode (Modo Balcão)**: High-throughput supermarket-style point of sale layout dividing the screen into an Operator Area (persistent barcode scanner focus, real-time last-scanned item preview, categorized visual product catalog with stock badges, customer linking, contextual category pricing applying only when category tabs are actively selected versus standalone item sales, dedicated Delivery/Freight fee input field positioned above surcharges) and an Enlarged Customer Receipt Area (oversized total amount, quick quantity controls, cash change calculation, item variant support, **custom item-level notes/observations persisted and printed on kitchen/thermal tickets**, and instant thermal receipt printing).
  - **Bidirectional Product & Inventory Integration**: Direct stock quantity adjustment and minimum stock thresholds right inside the Product Creation/Edit dialog, alongside real-time sale price and barcode editing inside the Stock Movement dialog, with automatic cost price synchronization upon receiving supplier purchases.
  - **Role & Permission Management Container (Discord-Style, `CargosEPermissoesContainer`)**: Positioned above store members in the "Dados" tab, collapsible by default, presenting Discord-style role tabs for native roles (Owner, Partner, Admin, Employee) and custom team-created roles (`+ Novo Cargo`), with switches transparently detailing all permissions. Owners and Partners have full governance to customize all permissions of lower roles (Admin, Employee, and custom roles, persisted under `Loja.permissoesCargosNativos`). Employees and Admins can also manage and change member roles when granted permission by Owners/Partners, and created roles can be linked directly to participants.
  - **Universal Full-Screen Keyboard Shortcut (<kbd>F11</kbd>)**: Low-level hardware keyboard handler in `main.dart` toggling borderless native Windows full-screen seamlessly anywhere across the application (compact mobile layout, desktop layout, login, or open dialogs). Switching between compact mobile and desktop layouts remains strictly accessible via store settings ("Ajustes" tab).
  - Store Status & Daily Operational Overview (`StatusLojaView`): Real-time daily performance dashboard positioned above store status controls, presenting Today's Revenue (R$), Total Sales Today, Average Ticket (R$), and Cash Drawer Status (Open/Closed badge with exact live physical cash balance), fully transparent to all store workers.
  - Configurable estimated order completion timeout (under store "Dados" tab) with automated dialog check-ins asking if accepted orders have been completed.
  - Cash drawer & shift control (`TurnoCaixa`): opening float, cash-in reinforcements (suprimentos) and withdrawals (sangrias) with mandatory justification and audit trail, change-deducted net cash calculations, instant signed thermal receipt vouchers with reprint capability, blind drawer closing with tender breakdown (cash, credit, debit, PIX), discrepancy reconciliation, printed thermal closing receipts, and interactive shift history in `CaixaDialog` with dynamic hover navigation to `DetalhesTurnoCaixaDialog` — showcasing opening/closing operators with real profile avatars by tax ID, shift duration, comprehensive financial overview (cash, electronic, credit receivables, float, and variance), detailed withdrawals list identifying responsible operators with photos and justifications, associated sales ticket history, thermal receipt reprinting, and safe permanent shift record deletion with action audit logs.
  - Open Table & Tab Management for Restaurants: Table registry with live status (free/occupied), continuous ordering per responsible worker, item-level audit trails, 58mm/80mm thermal pre-bill checks, bill splitting across multiple payers, service fees (10%), discounts, and table transfers/merging.
  - Order and ticket workflow (New, Accepted, Completed, Cancelled with stock reversal & audit trail) with split/multiple payments support, direct in-dialog thermal ticket reprint button on accepted orders (`PedidoAceitoDialog`), strict reverse-chronological sorting (most recent on top for completed and cancelled tickets), instant keyword & ticket number search box in Completed and Cancelled tabs, and expanded ergonomic desktop order list.
  - Multi-unit inventory tracking (`un`, `g`, `ml`) with automatic deduction proposals, bidirectional purchase cost calculation ($C_{\text{unit}} = \frac{C_{\text{total}}}{Q}$), critical low-stock alerts (< 10 units) integrated into app-bar notifications with direct interactive stock replenishment navigation, and detailed Product Kardex Sheets (`FichaKardex`) tracking chronological lot entries, deductions, unit costs, and balances.
  - Customer & Supplier registry with adaptive CPF/CNPJ formatting, unified sovereign local auto-fill (`DadosLocaisService`), universal multi-field quick search (`correspondeABusca`) allowing instant filtering by customer/supplier name, street/address, house number, formatted/unformatted tax IDs and phone numbers, e-mail, social handles, or notes, safety confirmation modal with real-time balance previews for credit debt discharge ("Quitar valor" / "Quitar tudo"), and comprehensive A4 PDF customer account statements.
  - **Cooperative Financial Management & Daily Operations (`financeiro_view.dart`)**:
    - Real-time audit trail, algorithmic egalitarian surplus division suggestions among workers, Simple Income Statement (DRE) by period with gross/net profit margins, daily cash closing, and A4 PDF export.
    - **Daily Operational Overview ("Resumo Operacional"):** Positioned as the **first container of the page** (immediately below the period filter menu in both single-column and dual-column layouts), dynamically accompanying the active context date/period (Today, specific day selected via `<`/`>` buttons, or general period) with live revenue, sales count, average ticket, cash drawer balance, and drawer status badge.
    - **Sales of the Period Container ("Vendas do Período")**: Positioned directly beneath Period Purchases, delivering live text search across sales (customer, product, ticket #), tender breakdown filters (Pix, Cash, Debit, Credit, Store Credit/À Prazo), and detailed `BarraVenda` list with ergonomic height constraints.
    - **Ergonomic Day-by-Day Date Filtering**: Quick single-click backward/forward day navigation buttons (<kbd>&lt;</kbd> and <kbd>&gt;</kbd>) alongside theme-integrated calendar pickers (`showDatePicker`) and smart cursor selection preservation across both `FinanceiroView` and `RelatoriosDialog`.
  - Dedicated Store Settings tab ("Ajustes do Perfil") consolidating:
    - Keyboard Shortcuts ("Comandos"): Configurable function keys (<kbd>F1</kbd> to <kbd>F8</kbd>) mapped to key PDV actions (Nova Venda, Clientes, Caixa, Relatórios, Impressora, Financeiro, Status da Loja) and universal <kbd>Esc</kbd> dismissal.
    - Estimated order completion timeout with automated status confirmation dialogs.
    - Customizable System Sounds & Beeps (`SomService` / `Loja.sonsAlertas`) for New Orders, Timeouts, and Barcode/Item scans.
    - **Store Financial Settings ("Financeiro do Perfil")**: Dedicated container offering a secure, permission-controlled button to **Reset Store Transaction Records** (wiping sales, drawer shifts, employee payments, and past stock purchase costs from the financial history while consolidating and preserving physical inventory counts exactly intact). Accessible natively to Owners and Partners, or team members with explicit `PermissaoLojaConst.resetarTransacoes` permission.
    - **Scheduled Orders & Customer Contracts ("Pedidos Programados") & New Orders Queue**: Full scheduling and contract workflow across customer records, reports, and real-time operations. Features full operational parity with store ticketing: products can be scheduled as standalone items or tied to a category (accumulating category base prices and offering associated component/topping groups with `+`/`-` counters), alongside item variants and custom notes. Flexible recurrence configuration offers two distinct modes: **Contract / Days of the Week** with interactive weekday selectors (Mon..Sun) and quick-presets or a **Visual Monthly Calendar** directly inside the dialog for multi-date selection. When launching the application, today's scheduled orders spawn automatically in the "Novos" order queue. If there are new pending orders upon launching, the application immediately sounds an alert (`SomService.eventoNovoPedido`) and opens a dedicated receipt dialog (`ComandaNovoPedidoDialog`) displaying the complete ticket along with **Print**, **Reject**, and **Accept** buttons, cycling through each pending new order one-by-one until all new orders have been attended.
  - Thermal receipt printing (supporting both 58mm and 80mm rolls) with roll width selector, universal bilateral margin calibration (independent left/right mm fine-tuning preventing edge cuts across hardware brands like Knup, B&G, Elgin), unified typography architecture (`FontesApp`) with 11 industry-standard free fonts (Arial/Helvetica for sharp thermal paper clarity without ink bleeding, Courier monospace for column alignment, Open Sans, Roboto, Roboto Mono, Inter, Lato, Poppins, Montserrat, Times New Roman, and Belleza), dropdown selection identical to appearance settings, live in-dialog receipt preview, direct sample printing, and PDF exports.
- **Deliberative Notifications & Governance (`features/notificacoes`)**: Direct collective governance for store members with stock-alert aggregation, direct tap-to-replenish stock workflow syncing live balances, persisting transparent action audit logs, and horizontal swipe-to-dismiss gesture per session (reappearing on next launch if unresolved). Anti-despotic rules: owners cannot unilaterally remove other owners without explicit consent; partners cannot alter another partner's role without prior acceptance.
- **Local-First & Sovereignty**: Entirely offline and self-contained with a high-performance local SQLite relational engine (`sqflite_common_ffi` with ACID atomic transactions), automatic migration from legacy store vaults, single-file universal JSON backup/restore (`file_selector`) with non-destructive intelligent merging, active profile deduplication by CNPJ/tax ID, category preservation, and silent automatic daily local backups to `%APPDATA%\Nous\backups`.
- **Desktop Distribution & Single-Instance Protection**: Official standalone Inno Setup Windows test installer (`Nous_Instalador_v1.0.0_Versao_Teste.exe`) with branded multi-resolution app icon, native Win32 Named Mutex single-instance protection preventing duplicate process conflicts, and offline-tolerant update notification mechanism (`AtualizacaoService`).
- **Local-First Wi-Fi Synchronization & Terminal Distribution (`servidor_rede_local.dart` & `cliente_rede_local.dart`)**: Real-time zero-internet local network synchronization connecting PC Cashier Counter and Mobile Phones (Android) on the same Wi-Fi, featuring automatic peer discovery via UDP broadcast, bidirectional WebSocket data streaming, instant real-time role & custom permission broadcasting, active profile deduplication preventing duplicated store entries across multi-device owner logins, deterministic persistent image caching (`remota_<hash>`) eliminating repetitive download storms and mobile freezing, lightweight in-memory sync without destructive widget rebuilding, sovereign physical download of images directly to phone storage, automatic User Identity & avatar synchronization by CPF, and local-first in-network software updates directly from the counter PC.

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

### Theming & User Customization

The UI is fully theme-driven through an `AppTheme` class (background, card
background, text colors, button colors, borders, danger/deletion action color `dangerColor`, font, and font scale) and a
`ThemeController` that broadcasts theme changes app-wide. Users can create,
customize, and save their own named themes with a Canva-style color picker. Appearance settings and saved themes are automatically persisted per citizen user (keyed by `cpf`), restoring individual visual preferences seamlessly on login. In addition, all destructive and deletion operations throughout the app strictly adhere to a unified pattern: buttons styled with `theme.dangerColor` and mandatory confirmation modals before deletion. No screen hard-codes colors or fonts — everything reads dynamically from the active `AppTheme`.

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

1. **PDV & Governance Core** — functional and evolving. Complete point of sale, USB barcode scanning, shift & cash drawer control (`TurnoCaixa`) with automatic cash drawer reconciliation on debt clearance, multi-unit inventory control (`un`/`g`/`ml`) with smart stock return on order deletion, customers/suppliers with sovereign auto-fill, egalitarian financial module with invariant operational profit sharing base, faithful credit sales accounting and grouped customer pending balances with instant direct settlement, 58mm/80mm thermal printing with bilateral calibration, persistent hover feedback across all selectors, automatic daily backup, and consent-based collective governance.
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
  - Catálogo de itens com fotos persistidas, ferramenta de enquadramento e corte de imagens (`AjustarImagemDialog`), diálogos de confirmação de segurança contra exclusão acidental de fotos e anexos, categorias, **variantes de produtos com preços específicos (ex: materiais, tamanhos)**, grupos de adicionais/componentes, código de barras (EAN), preço de custo, saldo de estoque em tempo real com máscara adaptável (`Est: X un/kg/L` ou `Esgotado`), badges visuais integrados nos cards de produto do PDV (expandido e compacto), priorização de categorias na abertura da venda e **reordenação fluida por pressão de 1 segundo (sem alças de arraste, o card flutua seguindo o cursor ou dedo e reencaixa suavemente ao soltar) para produtos, categorias e grupos de componentes** na tela "Loja do Perfil".
  - Fluxo ágil de vendas com foco inicial limpo (exibe apenas categorias na busca em branco e itens soltos apenas mediante pesquisa ativa), proteção de toque via TapRegion garantindo seleção perfeita de categorias e sugestões de clientes sem fechamento prematuro, **seleção intuitiva de variantes em qualquer layout de venda (catálogo, busca, categorias e bipador óptico)**, cálculo dinâmico de desconto e acréscimo em porcentagem (`%`) ou valor fixo em reais atualizando a comanda viva e totais em tempo real, seleção numérica total instantânea no valor das formas de pagamento para edição rápida sem apagar caractere por caractere, preservação automática de rascunhos de venda contra fechamentos acidentais da janela com botão de limpeza rápida, leitor USB (bipador), atalhos de teclado no desktop (<kbd>F1</kbd> para Nova Venda, <kbd>Esc</kbd> para fechar janelas) e proteção com confirmação contra descarte acidental de venda finalizada.
  - **Modo Balcão (Frente de Caixa Profissional)**: Interface clássica em tela cheia para alto fluxo operacional (supermercados e varejo), com foco persistente em bipador de código de barras USB, visor do último produto registrado com foto real, catálogo de produtos por categorias com badges de saldo adaptáveis, cálculo contextual de categorias (venda avulsa em "Todos" pelo valor puro do item e acúmulo de preço de categoria apenas ao selecionar a aba da categoria correspondente), campo dedicado de "Frete" posicionado ergonomicamente acima de "Acrésc:" somando ao total geral e cupom térmico, vinculação ágil e interativa de clientes com painel suspenso de busca multicampo e avatares, atalho <kbd>F11</kbd> global contínuo, suporte completo a Grupos de Componentes / Adicionais configuráveis por item com recálculo automático da comanda, **seleção de variantes do produto**, **campo de observação/comentário personalizado por item no pedido com edição direta no carrinho e impressão na comanda**, controles ergonômicos de quantidade, cálculo de troco destacado e janela de conclusão com botão de retorno seguro para edição.
  - **Integração Bidirecional de Estoque e Formação de Preço de Custo (`NovoItemDialog`)**: Gestão integrada entre a ficha de produto e a movimentação de estoque. A janela "Novo Item" conta com disposição sequencial estrita (Foto > Nome > Descrição Minimizada > Tipo Produto/Serviço com hover > Preço de Venda > Categorias e Grupos > Variantes > Código de Barras > Unidades de Medida > Consumo por venda > Container Unificado "Estoque e Preço de Custo" > Delivery). A janela adapta seu formato estritamente à seleção ativa em "Ajustes do Perfil" (duas colunas amplas no Layout Desktop Expandido e coluna única sequencial no Layout Compacto voltado a celulares). As listas verticais de Categorias e Grupos na tela da loja comportam até 7 a 8 barras completas antes de habilitar a rolagem interna, otimizando a altura útil do monitor sem provocar rolagem da tela.
  - **Container "Cargos e Permissões" (Estilo Discord, `CargosEPermissoesContainer`)**: Posicionado acima de "Usuários Participantes" na aba "Dados do Perfil", colapsado por padrão para ergonomia visual, com abas horizontais para cargos nativos (Dono, Sócio, Administrador, Funcionário) e cargos customizados da loja (`+ Novo Cargo`), exibindo a transparência radical de todas as permissões do sistema. Sócios e Donos possuem controle pleno para alterar todas as permissões de cargos inferiores (Administrador, Funcionário e cargos criados, persistidos em `Loja.permissoesCargosNativos`). Administradores e funcionários também podem alterar os cargos e papéis de outros membros caso recebam essa permissão dos Donos ou Sócios. No diálogo de membros participantes, permite vincular diretamente qualquer cargo criado da loja (`vincularCargoAoMembro`).
  - Resumo Operacional do Dia e Status da Loja (`StatusLojaView`): Painel gerencial no topo da tela (acima do interruptor de status da loja) exibindo métricas em tempo real — Faturamento do Dia (R$), Vendas Realizadas Hoje, Ticket Médio e Situação do Caixa (badge Aberto/Fechado com saldo real em espécie apurado no momento), visível para todos os trabalhadores em consonância com a transparência radical do Nous.
  - Tempo de conclusão geral de pedidos estipulável nas configurações da loja (aba "Dados"), com disparo automático de janela perguntando se pedidos aceitos decorridos já foram concluídos.
  - Gestão e controle de turno de caixa (`TurnoCaixa`): abertura com fundo de troco, suprimentos (reforços) e sangrias (retiradas) com justificativa e auditoria, apuração rigorosa de dinheiro líquido (deduzindo trocos devolvidos), fechamento cego com declaração por forma de pagamento, conferência de diferenças e impressão de comprovante térmico de fechamento. Histórico de turnos fechados interativo na janela "Caixa do Balcão" com efeito dinâmico de hover e clique para a janela `DetalhesTurnoCaixaDialog`, exibindo operadores responsáveis pela abertura e fechamento com foto do perfil por CPF, duração do turno, resumo financeiro completo (fundo, vendas em dinheiro/eletrônico/prazo, suprimentos, sangrias e quebra de caixa), lista detalhada de retiradas e depósitos identificando o operador com foto, CPF e justificativa, histórico de vendas do turno, reimpressão de comprovante e exclusão segura do registro de turno com confirmação e auditoria.
  - Gestão de Mesas e Comandas Abertas para Restaurantes: Cadastro de mesas com status dinâmico (livre/ocupada), lançamento contínuo de itens por trabalhador responsável, histórico de auditoria por item, impressão térmica de conferência não-fiscal de 58mm ou 80mm, divisão dinâmica de contas ("rachar a conta" em múltiplos pagamentos), taxa opcional de 10% de atendimento, descontos e transferência/unificação de mesas.
  - Gestão de pedidos e fluxo de comandas em tempo real (Novos, Aceitos, Concluídos, Cancelados com estorno de estoque e auditoria) com suporte a pagamentos parciais múltiplos, reimpressão térmica direta em pedidos aceitos, busca rápida por número (#0001), cliente ou produto nas abas Concluídos e Cancelados e lista de pedidos desktop ampliada.
  - Controle de estoque multivariado (`un`, `g`, `ml`) com proposta automática de baixa, confirmação humana mandatória e notificações de estoque baixo/esgotado interativas com reposição direta via diálogo de entrada de mercadorias.
  - Aba dedicada "Ajustes do Perfil" (antiga Interface do Perfil):
    - Container "Modo de Visualização e Layout do PDV": Alternância direta entre o Layout Expandido (com barra lateral e colunas duplas) e o Layout Compacto Padrão. Em dispositivos móveis (celulares), o modo compacto é o padrão mandatório e fixo para ergonomia ao toque (sem permissão de alternar para desktop no smartphone); no computador (desktop), o usuário mantém autonomia total para alternar entre os modos.
    - Letreiro Digital e Texto Deslizante Universal (`TextoRolante`): Toda a aplicação adota rolagem suave de texto da direita para a esquerda (efeito Marquee) para qualquer nome que exceda a largura do seu container (itens, categorias, grupos, clientes, fornecedores, mesas e títulos), garantindo leitura completa sem truncamentos secos ou quebras verticais.
    - Tela Cheia Nativa Windows (<kbd>F11</kbd>): Interceptador global no nível de hardware nativo em `main.dart` alternando full screen do Windows instantaneamente em qualquer ponto da aplicação (layout compacto para celulares, desktop expandido, tela de login ou popups).
    - Container "Comandos": Menu de teclas de atalho (<kbd>F1</kbd> a <kbd>F12</kbd>) iniciando com todas as funções como "Desativado" por padrão para configuração manual do usuário, <kbd>F11</kbd> fixo para Tela Cheia com `TextoRolante` e disposição adaptada para 1 coluna contínua no celular, e <kbd>Esc</kbd> para fechar janelas.
    - Container "Tempo de Conclusão dos Pedidos": Definição de prazo médio com verificação automática de status de pedidos aceitos.
    - Container "Sons e Alertas do Sistema": Personalização e teste de áudio/bip para novos pedidos, prazos e leituras de códigos de barra.
    - **Container "Financeiro do Perfil"**: Painel dedicado para operações financeiras da loja com botão seguro de **Reset dos Registros de Transações** (limpa vendas, turnos de caixa e pagamentos de equipe, mantendo produtos, estoque e clientes). Protegido pela permissão `resetarTransacoes`, disponível para Donos, Sócios e membros autorizados.
    - **Módulo de Pedidos Programados e Contratos de Clientes ("Pedidos Programados")**: Fluxo completo de agendamento e contratos recorrentes acessível pela ficha do cliente, relatórios e operação em tempo real. Paridade total com a comanda do sistema: permite selecionar o produto como item solto/avulso ou vinculado a uma Categoria (somando o preço da categoria e disponibilizando grupos de componentes e acompanhamentos/adicionais com seletores `+`/`-`), variantes e observações. Dois modos intuitivos de programação: **Contrato / Dias da Semana** com botões seletores (<kbd>Seg</kbd> a <kbd>Dom</kbd>) e atalhos rápidos ("Qua a Sex", "Dias Úteis", "Todos os Dias") ou **Calendário Visual Interativo Mensal** embutido para seleção múltipla de datas. Avisos automáticos na inicialização do aplicativo resumem os agendamentos do dia, os pedidos entram automaticamente na fila de "Novos" na data devida e a janela de Relatórios traz container dedicado acima de Pendências com inspeção de comanda em 1 clique.
  - Cadastro de clientes e fornecedores com máscara adaptável CPF/CNPJ, autopreenchimento local soberano unificado (`DadosLocaisService`) e exportação de extrato completo de compras em PDF A4 com cálculo de dívida a prazo em tempo real.
  - **Módulo Financeiro Cooperativo e Operação do Dia (`financeiro_view.dart`)**:
    - Trilha de auditoria em tempo real, cálculo algorítmico de divisão igualitária dos excedentes, DRE por período com margens de lucro e exportação em PDF.
    - **Resumo Operacional do Dia / Contexto**: Posicionado como o **primeiro container da página** (logo abaixo do menu de filtro de período, tanto no layout de coluna única quanto no expandido), acompanhando dinamicamente o dia ou período de contexto selecionado (Hoje, dia específico ajustado via botões `<`/`>` ou período geral), consolidando Faturamento, Vendas, Ticket Médio, Saldo em Dinheiro e situação do caixa (Aberto/Fechado).
    - **Container "Vendas do Período"**: Posicionado abaixo de Compras do Período, com pesquisa multicampo de vendas (#pedido, cliente, produto), filtros rápidos por forma de pagamento e cards `BarraVenda` com limite ergonômico de rolagem.
    - **Filtros de Data Ágeis do Dia a Dia**: Botões rápidos `<` e `>` para avançar ou recuar dia a dia com 1 clique sem apagar o campo, seletor de calendário nativo temático (`showDatePicker`) e correção do cursor do teclado no `_DataInputFormatter` em `FinanceiroView` e `RelatoriosDialog`.
  - Impressão térmica padrão de 58mm e 80mm com seletor de largura de bobina, calibração bilateral universal de recuo (ajuste fino em milímetros à esquerda e à direita), seleção de modelo de fonte (Belleza, sem serifa, monoespaçada, serifada), prévia adaptativa de comanda resistente a fontes máximas (sem quebras verticais de preço ou estouros de margem), envio direto para impressora física e exportação em PDF.
- **Governança Coletiva e Notificações Deliberativas (`features/notificacoes`)**: Autogestão participativa para membros de lojas com resolução interativa de alertas de estoque crítico diretamente ao tocar no card da notificação, repondo saldo no cofre, gerando auditoria transparente em Ações e sincronizando a tela do PDV em tempo real. Regras anti-despóticas: donos não podem excluir outros donos sem consentimento mútuo; sócios não podem alterar o papel de outros sócios sem aceite explícito.
- **Soberano e Local-First**: 100% autônomo e offline, impulsionado por um banco relacional local SQLite de alta performance (`sqflite_common_ffi` com transações atômicas ACID), migração automática transparente, exportação/importação de backup completo em arquivo JSON único (`file_selector`) com mesclagem inteligente não-destrutiva, desduplicação ativa de perfis por CNPJ, preservação de categoria e backup diário automático silencioso mantido em `%APPDATA%\Nous\backups`.
- **Distribuição Desktop e Instância Única Nativa**: Instalador oficial para Windows (Inno Setup 6) em arquivo `.exe` único ultra-comprimido com ícone oficial do Nous, proteção nativa Win32 C++ contra múltiplas janelas abertas simultaneamente (evitando concorrência no SQLite) e sistema de verificação de atualizações local-first discreto (`AtualizacaoService`).
- **Sincronização em Rede Wi-Fi Local e Distribuição Soberana (`servidor_rede_local.dart` e `cliente_rede_local.dart`)**: Operação simultânea entre computador balcão e smartphones na mesma rede Wi-Fi local sem necessidade de conexão com a internet, com descoberta automática via UDP, comunicação bidirecional via WebSocket e REST local (`POST /api/loja/atualizar`), sincronização bidirecional completa de toda a loja (exclusão de funcionários/membros com purga de referências locais no SQLite, atualização de papéis e cargos, catálogo de produtos, categorias, grupos de complementos, clientes e fornecedores), listener unificado de tempo real em `DadosPerfilView` (`_aoAtualizarPdv`), proteção contra loops de WebSocket e debounce inteligente no celular, janela modal interativa de autorização de novos terminais no balcão com alerta sonoro e recusa segura (HTTP 403), prevenção estrita de auto-conexão eliminando lentidão no Wi-Fi, presença automática do computador balcão na lista de terminais pareados, sincronização bidirecional em tempo real e persistência instantânea de mesas e comandas de restaurante entre salão e balcão, auto-associação imediata de novos membros já no snapshot HTTP inicial (`GET /api/loja?cpf=...`), persistência atômica da loja no cofre local prevenindo referências órfãs e garantindo aparição instantânea em "Meus Perfis", propagação instantânea de alterações de papéis e permissões de membros em tempo real para os terminais móveis, desduplicação rigorosa de lojas prevenindo entradas redundantes ao logar com o mesmo CPF do dono em múltiplos aparelhos, cache determinístico persistente de imagens (`remota_<hash>`) eliminando tempestades de downloads e travamentos em celulares, sincronização leve em memória sem reconstruções destrutivas da tela, download físico soberano de fotos (produtos, categorias, clientes, fornecedores e avatar de perfil) com gravação de bytes protegida contra quedas de conexão, sincronização da Identidade do Usuário por CPF e distribuição local-first de atualizações transmitidas diretamente pelo computador do balcão para os celulares com download e instalação in-app nativa via `FileProvider`.

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

### Sistema de tema e personalização soberana

A interface é 100% controlada por tema, através de uma classe `AppTheme`
(cor de fundo, cor de fundo dos cards, cores de texto, cor dos botões,
bordas, cor de ações de perigo e exclusão `dangerColor`, fonte e escala de fonte) e de um `ThemeController` que avisa o app
inteiro quando o tema muda. O usuário pode criar, personalizar e salvar seus próprios
temas com nome via seletor estilo Canva. As configurações visuais e temas salvos são persistidos individualmente por cidadão (chaveados pelo `cpf`), restaurando as preferências visuais de cada perfil no momento do login. Além disso, todas as ações destrutivas e exclusões da aplicação seguem um padrão estrito: botões estilizados com `theme.dangerColor` e diálogo de confirmação prévia obrigatório. Nenhuma tela fixa cores ou fontes "no braço" — tudo vem dinamicamente do `AppTheme` ativo.

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

1. **Núcleo de PDV e Governança** — funcional e em evolução contínua. Ponto de venda completo, leitor de código de barras USB (bipador), controle de turno de caixa (`TurnoCaixa`) com sangria/suprimento e conciliação automática na quitação de dívidas/fiado, estoque multivariado (`un`/`g`/`ml`) com cálculo automático de compras e sincronização universal de custo unitário (`precoCusto`), variantes em mesas e comandas, estorno integral de estoque (incluindo acompanhamentos e consumo de receitas) em cancelamentos, baixa proporcional no fechamento de contas, alertas de estoque crítico (< 10 un) no sino e estorno inteligente na exclusão de pedidos, clientes e fornecedores com autopreenchimento local soberano, financeiro cooperativo com base estável de divisão igualitária, filtro avançado de transações por dia específico ou intervalo de datas personalizado integrado à DRE e relatórios, contabilização fiel de vendas à prazo por forma de pagamento no financeiro e em impressões térmicas/PDF, pendências consolidadas por cliente exibindo saldo devido total e indicação do último pedido com acesso desobstruído a pedidos avulsos, bloqueio rigoroso de fiados sem cadastro no modo balcão, quitação rápida e direta de pedidos à prazo na comanda (`VendaRegistradaDialog`), modo desktop expandido com barra lateral fixa reordenada ergonomicamente ("Dados da Loja" > "Ajustes do Perfil" > "Loja / Catálogo" > "Gestão de Pedidos") e prévia dinâmica de atalhos sincronizados com quadrados vazios para funções desativadas, normalização universal de CPF no cofre local eliminando discrepâncias de pontuação entre máquinas, feedback visual de modo somente leitura e alternância de layout desobstruída em "Ajustes do Perfil", botões e seletores com hover persistente universal, reprodutor interno de áudio moderno (`ReprodutorAudioWidget`) com blindagem de caracteres especiais no Windows, extração soberana de capas ID3v2 de fundo translúcido e controle de volume contínuo, impressão térmica de 58mm e 80mm universal com calibração bilateral de recuo, tipografia configurável, prévia viva com perfis históricos do anarquismo e impressão direta de amostras, backup diário automático silencioso, rolagem horizontal automática universal (`TextoRolante`) em relatórios e barras de informações para celulares, auto-instalação in-app nativa via `FileProvider` no Android com cálculo de progresso em tempo real, instalador oficial Windows para testes (`dist/Nous_Instalador_v1.0.2_Versao_Teste.exe`) e pacote APK Android para dispositivos móveis (`dist/Nous_Android_v1.0.0_Versao_Teste.apk`).
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
