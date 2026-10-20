# Filosofia e Política do Nous

Este documento explica por que o sistema é como é. O agente não precisa ler isto em toda sessão: as regras que importam para o código estão resumidas em `AGENTS.md` (invariantes). Leia aqui quando uma decisão técnica tocar em poder, dinheiro, identidade ou transparência.

## 1. O projeto

O Nous é um SuperApp brasileiro, livre e de código aberto (Flutter/Dart), multiplataforma, com foco inicial no Windows. É um Software Universal de Autogestão Comercial e Social. Hoje reúne um PDV completo; os módulos futuros têm pastas reservadas: chat interno (`features/chat`), timeline social (`features/timeline`), gestão de entregadores e delivery (`features/delivery`), banco comunitário e crédito mútuo (`features/banco`) e autogestão e deliberação coletiva (`features/autogestao`).

O Nous não é neutro: é uma ferramenta prática para colocar a economia e os meios de produção na mão da classe trabalhadora.

## 2. Base política: Plataformismo Brasileiro

Síntese entre a tradição organizativa anarquista de 1926 (Dielo Truda, Nestor Makhno) e as possibilidades das plataformas computacionais no Sul Global: autogestão real, soberania digital e emancipação da classe trabalhadora rumo a uma sociedade sem classes e sem exploração.

### 2.1 Ontologia: Nous (νοῦς)

Atividade do intelecto puro, a razão ordenadora que em Anaxágoras organiza o cosmo a partir do caos, o intelecto ativo em Aristóteles que intui princípios sem premissas intermediárias, o "olho da mente" em Platão. Computacionalmente, o software atua como mente coletiva e interpretador universal dos dados sensíveis e das relações produtivas: traduz a microgestão deliberada pelos trabalhadores em interfaces diretas, sem burocracias parasitárias nem algoritmos de manipulação.

### 2.2 Negação do Arkhon, afirmação do Arkhein

Anarquia = *an* (sem) + *arkhos* (chefe) + *arkhein* (governar, planejar, ter finalidade).
- **Nega o arkhon:** o chefe, o tirano, o oligarca, o dono absolutista, a classe política profissional.
- **Afirma o arkhein:** planejamento, ordem, cálculo econômico e previsão de demandas são indispensáveis. Governar é planejar. O Nous propõe o governo sem classe governante: administração diluída nas mãos do povo trabalhador, por democracia direta e ferramentas digitais.

### 2.3 Inserção orgânica no mercado

O Nous entra no comércio real oferecendo a melhor ferramenta operacional (PDV rápido, local-first, offline, sem mensalidade, impressão térmica precisa). Uma vez adotado, infunde lógica cooperativa e despersonalizada: expõe a saúde financeira aos trabalhadores, sugere divisão igualitária de excedentes, distribui turnos sem sobrecarga e estimula consciência de classe na prática.

### 2.4 Transparência radical

A corrupção e a exploração são privadas por natureza; o antídoto é a exposição contínua à luz.
- No Financeiro, o trabalhador vê exatamente os mesmos números do dono. Saldo negativo ou sobras nunca são camuflados.
- **Sugestão de divisão igualitária:** `Sugestão = (Entradas − Saídas) / Número de Membros`. Ajustes manuais são permitidos caso a caso, mas tudo fica em histórico de auditoria (`RegistroAcao`): autor, data, horário e delta.

### 2.5 Identidade real soberana

Despersonalizar o poder não é anonimato irresponsável. Tudo é vinculado ao CPF do cidadão; um CPF pode ter vários e-mails. Elimina contas falsas, bots e impunidade, sem depender de Big Techs nem pedir permissão governamental. A responsabilidade é do indivíduo perante a comunidade.

### 2.6 Autonomia coletiva entre donos e sócios

Os papéis (`Dono`, `Sócio`, `Admin`, `Funcionário`) refletem funções operacionais, mas o poder não é despótico.
- Dono não exclui outro dono diretamente: envia solicitação de saída (`TipoNotificacao.solicitacaoExclusaoDono`); só se efetiva se o alvo aceitar.
- Dono exclui Sócio, Admin e Funcionário; o removido é notificado (`TipoNotificacao.remocaoLoja`): "Você foi removido(a) da loja [Loja] por [Nome]".
- Sócio não exclui Sócio nem Dono; exclui apenas Admin e Funcionário.
- Admin e Funcionário não excluem terceiros.
- **Autoexclusão:** todo membro pode sair a qualquer momento por conta própria.
- **Inegociável:** um sócio não pode alterar o papel de outro sócio unilateralmente; exige notificação (`TipoNotificacao.alteracaoPapel`) e aceite explícito do sócio alvo.

### 2.7 Sistema fechado, soberano e local-first

Opera de ponta a ponta sem APIs de Big Techs. Backup completo em um único JSON, manipulado pelo próprio usuário com `file_selector`.

### 2.8 A vida real manda (o humano no comando)

Onde a máquina calcula estimativas (ex.: baixa de estoque em g/ml), ela propõe; o humano confirma, ajusta ou cancela antes de efetivar.

### 2.9 O horizonte do SuperApp

Evolução integrada para a IA assistente Hermes, redes de mapa e entrega com negociação direta de fretes, banco comunitário com crédito mútuo e autogestão deliberativa.
Lema: *"Trabalhar todos, trabalhar menos, produzir o necessário, distribuir tudo."* (metas de turnos de 4 horas diárias em alta rotatividade, erradicação do lucro parasitário, soberania tecnológica cooperada).

### 2.10 Ontologia pan-dispositivo por CPF

O ser humano (CPF) é o centro soberano do sistema; não é um terminal nem um computador. Ele transita entre casa, trabalho, cooperativas e rua com vários aparelhos (celular, notebook, desktop do balcão).
- Proibido aprisionar perfis em hardware. Lojas e coletivos de que o cidadão participa não podem ficar retidos no aparelho onde foram registrados.
- Fusão e harmonização automática na rede local: sempre que dois dispositivos do mesmo CPF (ou celular e balcão) se conectam ao mesmo Wi-Fi, o sistema funde e harmoniza lojas participantes, `referencias_loja`, snapshots `Loja` e toda a ficha `UsuarioNous` (`POST /api/sincronizar_perfis_usuario`, `_mesclarUsuarios`).
- A janela "Identidade do Usuário" e a tela "Meus Perfis" exibem 100% de paridade de dados pessoais e lojas ("Administra" e "Participa") em qualquer dispositivo do cidadão.

## 3. Mídia e fundamentação teórica

A fundamentação completa está no livro *Nous*, de Leonardo Tadeu Dalosa (português do Brasil), disponível em [linktr.ee/nous72](https://linktr.ee/nous72). Primeiro vídeo: *"Ei, TRABALHADOR! Este vídeo te INTERESSA!"* (40 min); depois, a série de 22 episódios *"Ei, você! Este vídeo te INTERESSA!"*.

## 4. Pergunta em aberto

Escala para milhões de usuários é um problema de backend e infraestrutura (bancos, mensageria em tempo real, escalonamento horizontal, provavelmente serviços em vez de monólito), ainda não projetado. Será enfrentado quando a base do cliente (começando pelo PDV) estiver sólida. Roadmap: PDV e governança (em andamento) → chat → timeline → delivery → banco comunitário → autogestão → backend federado/descentralizado.
