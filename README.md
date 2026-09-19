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

Nous is in **early, active development**, built by a single self-taught
beginner developer — contributions, code review, and honest criticism from
experienced developers are genuinely welcome; this project is too large, by
design, for one person alone.

The first working piece is the **PDV (point-of-sale) module**, meant for
local businesses and organizations already aligned with this platformist
project. Every other module — chat, timeline, delivery, banking,
self-management — exists today only as a reserved, empty folder in the
codebase: planned, not built.

**This is not yet ready for production use or public distribution.**

## Architecture

Nous is a Flutter/Dart application. A few structural decisions are worth
documenting clearly, since the goal is for a growing team — and eventually a
whole federation of contributors, not unlike the federalism this project's
politics call for — to work on this codebase without stepping on each
other's feet.

### Feature-first, not layer-first

The codebase is organized by **business feature**, not by technical layer.
Each folder under `lib/src/features/` (`pdv`, `chat`, `banco`, `delivery`,
`timeline`, `clientes`, `estoque`, `autogestao`) is close to a self-contained
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
(`AuthProvider`, `PdvProvider`, and more to come), registered once in
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
    │   └── widgets/          # Generic shared widgets (app bar, nav bar...)
    │
    ├── features/
    │   ├── auth/             # Login, terms, CPF validation
    │   ├── pdv/              # Point of sale — the first working module
    │   ├── autogestao/       # Self-management tools (planned)
    │   ├── banco/            # Banking, incl. platform-managed public accounts (planned)
    │   ├── chat/             # Chat (planned)
    │   ├── clientes/         # Customers (planned)
    │   ├── delivery/         # Delivery app (planned)
    │   ├── estoque/          # Inventory (planned)
    │   └── timeline/         # Social timeline (planned)
    │
    └── shared/
```

Each feature folder follows the same internal shape as it grows:
`models/`, `providers/`, `services/`, `views/` (with `views/widgets/` for
screen-specific components).

## Roadmap

1. **PDV (point of sale)** — in progress. Store profile, theming, catalog
   (items, categories, component groups), transparent micromanagement.
2. Chat
3. Social timeline
4. Delivery app, with driver-negotiated route pricing
5. Banking system, including platform-managed public accounts
6. Self-management ("autogestão") tools and direct-democracy voting on
   platform rules
7. Backend architecture designed for real-time, social-network-scale traffic

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





##  <img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Brasil" width="20" /> PORTUGUÊS DO BRASIL  <img src="https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/br.svg" alt="Brasil" width="20" /> ## 





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

O Nous está em **desenvolvimento inicial e ativo**, construído por um único
desenvolvedor autodidata e iniciante — contribuições, revisão de código e
críticas honestas de desenvolvedores experientes são muito bem-vindas; este
projeto é grande demais, de propósito, para uma pessoa só.

A primeira parte funcional é o **módulo de PDV (ponto de venda)**, pensado
para negócios e organizações locais já alinhados a este projeto
plataformista. Todo o resto — chat, timeline, delivery, banco, autogestão —
existe hoje só como pasta reservada e vazia no código: planejado, mas ainda
não construído.

**Ainda não está pronto para uso em produção ou distribuição pública.**

## Arquitetura

O Nous é uma aplicação Flutter/Dart. Algumas decisões estruturais merecem
estar bem documentadas, já que o objetivo é que uma equipe cada vez maior —
e, no futuro, uma verdadeira federação de colaboradores, não muito diferente
do federalismo que a própria política deste projeto exige — consiga
trabalhar neste código sem atropelar o trabalho umas das outras.

### Organização por Feature, não por camada

O código é organizado por **assunto de negócio (feature)**, não por camada
técnica. Cada pasta dentro de `lib/src/features/` (`pdv`, `chat`, `banco`,
`delivery`, `timeline`, `clientes`, `estoque`, `autogestao`) funciona quase
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
`ChangeNotifier` (`AuthProvider`, `PdvProvider`, e outros que virão),
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
    │   └── widgets/          # Widgets genéricos compartilhados (app bar, nav bar...)
    │
    ├── features/
    │   ├── auth/             # Login, termos, validação de CPF
    │   ├── pdv/              # Ponto de venda — o primeiro módulo funcional
    │   ├── autogestao/       # Ferramentas de autogestão (planejado)
    │   ├── banco/            # Sistema bancário, incl. contas públicas geridas pela plataforma (planejado)
    │   ├── chat/             # Chat (planejado)
    │   ├── clientes/         # Clientes (planejado)
    │   ├── delivery/         # App de entregadores (planejado)
    │   ├── estoque/          # Estoque (planejado)
    │   └── timeline/         # Timeline social (planejado)
    │
    └── shared/
```

Cada pasta de feature segue o mesmo formato interno conforme cresce:
`models/`, `providers/`, `services/`, `views/` (com `views/widgets/` para
componentes específicos daquela tela).

## Roteiro (Roadmap)

1. **PDV (ponto de venda)** — em andamento. Perfil da loja, tema, catálogo
   (itens, categorias, grupos de componentes), microgestão transparente.
2. Chat
3. Timeline social
4. App de entregadores, com negociação do valor da rota pelo próprio
   trabalhador
5. Sistema bancário, incluindo contas públicas geridas pela plataforma
6. Ferramentas de autogestão e votação por democracia direta sobre as regras
   da própria plataforma
7. Arquitetura de backend projetada para tráfego em tempo real, em escala de
   rede social

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
