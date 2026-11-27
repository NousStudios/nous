# Arquitetura Futura: Servidor Mãe, Servidores Particulares e Modo Local-First

Este documento registra o plano de evolução do Nous para operar em **3 modos de rede** sem jamais perder sua natureza **offline-first e soberana**.

---

## 1. Visão dos 3 Modos de Operação (Escolha do Usuário)

O banco SQLite local no aparelho do cidadão continua sendo o motor principal do app em todos os modos. Os servidores externos entram apenas como **nós espelhos 24h** na malha de sincronização:

1. **Modo Apenas Rede Local (Wi-Fi / Offline-First):**
   - Funciona 100% sem internet (padrão atual da marmitaria/comércio).
   - O computador balcão atua como servidor local e os celulares sincronizam por HTTP/WebSocket na rede Wi-Fi.
2. **Modo Servidor Particular (Comunidades, Cooperativas e Redes Locais):**
   - O usuário aponta o app para o endereço HTTPS de um servidor próprio (ex.: `https://servidor.cooperativa.org.br`).
   - Ideal para redes solidárias independentes que desejam hospedar seus próprios dados.
3. **Modo Servidor Mãe Nous (Nuvem Soberana Oficial):**
   - O usuário conecta-se ao servidor central mantido pelo projeto Nous, ativando o alcance regional/nacional como produto digital (busca pública ampla, feed social conectado à distância, pedidos online e backup contínuo entre dispositivos), mantendo sempre a opção de desligar ou migrar.

---

## 2. O que precisa ser feito quando formos ligar o Servidor Mãe

Antes de abrir o app para a internet pública com milhares de usuários, existem **4 transições obrigatórias** planejadas para a etapa de ativação do Servidor Mãe:

1. **Transporte Seguro e Prova Criptográfica por CPF:**
   - Todas as rotas HTTP/WebSocket externas devem operar em **HTTPS/WSS**.
   - Toda mutação enviada ao servidor deve carregar assinatura digital vinculada à chave privada do CPF (`CriptografiaService` / `AssinaturaRedeService`), impedindo que terceiros falsifiquem pedidos, posts ou alterações de perfil em nome de outro CPF.
2. **Separação Estrita entre Camada Pública e Camada Privada da Loja:**
   - **Camada Pública (aberta e paginada por região/busca):** vitrines, catálogos ativos, perfis públicos de cidadãos/lojas, feed social, projetos comunitários e avaliações.
   - **Camada Privada da Loja (restrita aos membros):** caixa, estoque, vendas internas, folha de pagamento, ponto dos trabalhadores e fichas cadastrais privadas. O Servidor Mãe só entrega dados privados mediante autorização do CPF naquela loja.
3. **Quebra dos "Pacotes Monolíticos" Restantes (Catálogo da `Loja`):**
   - Pedidos, caixa, estoque, chat e timeline já operam com tabelas próprias/deltas.
   - Antes do Servidor Mãe, os catálogos da `Loja` (`itens`, `categorias`, `gruposComponentes`) devem migrar do JSON único da loja para sincronização granular item a item com `atualizadaEm` e soft-delete, evitando conflitos em edições simultâneas e tráfego pesado em redes móveis 4G/5G.
4. **Ordem Temporal Confiável no Servidor:**
   - Na internet aberta, o relógio do aparelho do usuário não pode vencer disputas sozinho (risco de celulares com data errada ou adulterada). O Servidor Mãe deve validar desvios de relógio e carimbar o horário oficial de recepção (*server timestamp*) como referência de ordenação.

---

## 3. Os 5 Hábitos Obrigatórios para Todas as Novas Funcionalidades

Enquanto desenvolvemos as demais telas e módulos (`timeline`, `delivery`, `banco`, `autogestao` e melhorias do `pdv`/`chat`/`busca`), **toda nova funcionalidade e tabela deve nascer pronta para o Servidor Mãe**, seguindo estas 5 regras:

1. **Identidade e Carimbo Temporal desde o Nascimento:**
   - Toda entidade persistida nova nasce com **ID único** (UUID ou determinístico por ciclo) e campo **`atualizadaEm`** (UTC/ISO) atualizado em toda mutação, além de suporte no construtor, `copyWith`, `toJson` e `fromJson`.
2. **Exclusão Sempre Lógica (*Soft-Delete* / Tombstone):**
   - Proibido apagar registros sincronizáveis com `DELETE FROM` definitivo. Toda exclusão marca `excluido = true` (ou `excluida = true`) com `atualizadaEm` atualizado e propaga o tombstone na rede.
3. **Mídias por Caminho Relativo:**
   - Nunca gravar caminho absoluto de sistema (`C:\...` ou `/data/user/0/...`) em modelos sincronizados. Persistir sempre caminho relativo normalizado (`/`) resolvido localmente pelo `ImagemService` ou serviço equivalente.
4. **Listagens Paginadas e Incrementais:**
   - Toda consulta e endpoint de sincronização de listas que crescem com o tempo deve nascer com `limit` / `offset` (ou cursor `desde`), nunca carregando históricos ilimitados em memória ou JSON.
5. **Isolamento Público vs. Privado na Modelagem:**
   - Ao criar qualquer novo campo ou modelo, definir explicitamente desde o início o que é **público na rede social/busca** e o que é **privado do CPF ou da equipe da loja**, seguindo a regra da privacidade mínima soberana (Dados Pessoais, CPF e Nome Próprio protegidos; apelido e dados públicos visíveis).
