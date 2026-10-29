# NOUS — Regras do Agente

> Você é um agente de código com acesso direto aos arquivos deste projeto.
> Este arquivo é carregado em TODA sessão: ele contém só **regras** e **ponteiros**.
> A descrição do que cada tela faz fica em `MAPA_DO_APP.md`. Os detalhes técnicos ficam em `docs/`.

## 1. Quem é o desenvolvedor e como trabalhar com ele

- Iniciante, autodidata, brasileiro. Pede mudanças no formato "na tela X, no container Y, o botão Z: mude tal coisa".
- **Responda e pense SEMPRE em português do Brasil.** Explique de forma curta, direta e didática, sem jargão. Se ele não entendeu, a falha é da explicação.
- **Raciocínio antes do código.** Antes de propor ou aplicar uma mudança, escreva: (1) o que entendeu do pedido, (2) os caminhos considerados, (3) o que descartou e por quê. Assim ele aprova a rota antes de você gastar código.
- **Decisões estruturais exigem alinhamento antes de codar:** novo modelo, nova feature, mudança de paradigma, remoção de código existente.
- **Mostre o que vai mudar** (trecho/diff) antes de grandes reescritas. Nunca sobrescreva arquivos sem transparência.
- **Nunca apague silenciosamente funcionalidades que funcionam.** Se precisar remover ou refatorar, avise antes e justifique.
- **Aviso de build/cache:** ao criar ou alterar campos em modelos persistidos (`fromJson`, `toJson`, `shared_preferences`), avise o desenvolvedor para rodar `flutter clean && flutter pub get`.
- **Higiene:** ao terminar uma edição, o arquivo fica sem imports não usados, sem comentário óbvio, sem código morto e sem `// TODO` que não será feito agora.
- **Engenharia de Estado Soberana e Escalável (Padrão Big Tech):**
  - Fundações sólidas e de concreto armado. Proibido fazer "puxadinhos", atalhos frágeis ou colocar regras de negócio e consultas de banco dentro de Widgets de tela.
  - O dado (entidades soberanas e repositórios) existe antes da tela; a tela é apenas um consumidor que renderiza o estado e dispara intenções do usuário.
  - Economia de contexto sim (leitura cirúrgica, grep e edições focadas), mas com arquitetura modular, limpa, desacoplada e escalável.
  - Foco no que foi pedido; sem remendos imediatistas que criem dívida técnica.
- **Não adicione pacotes ao `pubspec.yaml` sem alinhamento prévio.**
- **Higiene Estrita de Repositório (Git Leve):** Proibido commitar arquivos binários compilados (`dist/`, `*.apk`, `*.exe`, `*.msi`, `*.aab`). Todos os artefatos de build devem permanecer no `.gitignore`. O repositório armazena estritamente código-fonte e assets essenciais.
- **Cuidado Proativo com o Desenvolvedor Iniciante:** Por ser autodidata e iniciante, antecipe e proteja contra armadilhas técnicas que ele ainda não conhece (ex.: limites de tamanho do GitHub, arquivos temporários rastreados, flags de compilação pesadas, acoplamento de escopo). Explique os motivos com clareza antes de qualquer ação que impacte o fluxo de trabalho dele.

### Manter a documentação viva (regra mandatória)

Ao final de cada ciclo de trabalho:

1. **Mudou tela, container, botão, aba, atalho ou comportamento visível?** Atualize `MAPA_DO_APP.md` (a tela correspondente, uma vez só; não repita a informação em outro lugar).
2. **Mudou regra de negócio, de sincronização, de design ou de build?** Atualize o arquivo certo em `docs/`.
3. **Surgiu uma regra nova que o agente precisa seguir sempre, ou uma invariante mudou?** Só então atualize este `AGENTS.md`.
4. Registre o que foi feito em `CHANGELOG.md` (uma linha por mudança, com a versão).

Este arquivo deve continuar curto (meta: menos de 200 linhas). Funcionalidade nova **não** entra aqui.

### Build e instaladores (regra do desenvolvedor)

Após cada ciclo concluído e validado (testes e `flutter analyze`), compile os instaladores com `scripts/gerar_instalador.ps1`. O pipeline apaga versões antigas em `dist/` e mantém só a mais recente. Detalhes em `docs/build-e-distribuicao.md`.

## 2. O que é o Nous

SuperApp brasileiro, livre e de código aberto, de **Autogestão Comercial e Social**, baseado no Plataformismo Brasileiro. Hoje o núcleo é um **PDV completo** (lojas, vendas, estoque, caixa, financeiro, impressão térmica) com identidade por CPF, notificações deliberativas e sincronização local por Wi-Fi. Módulos futuros (pastas reservadas): `chat`, `timeline`, `delivery`, `banco`, `autogestao`.

- Stack: Flutter/Dart, `Provider` (ChangeNotifier), SQLite local (`sqflite_common_ffi`), versão atual no `pubspec.yaml` (hoje v1.0.35+36).
- Plataformas: Windows (foco principal), Android; também Web, Linux, iOS.
- Política e filosofia completas: `docs/filosofia.md`.

## 3. Invariantes do domínio (nunca quebrar)

1. **Identidade é o CPF do cidadão, nunca o hardware.** Perfis, lojas e ficha cadastral pertencem ao CPF e devem aparecer iguais em qualquer aparelho dele. Proibido prender perfis ao dispositivo onde foram criados. CPF sempre normalizado (`PdvProvider._mesmoCpf`), sem depender de máscara.
2. **Aplicação como organismo único na rede local.** Sincronização absoluta e imediata: qualquer alteração de estado (status de pedido, estoque, mesas, mensagens, pagamentos) feita em qualquer nó online deve ser transmitida imediatamente (WebSocket + REST) e refletir em todos os aparelhos sem reiniciar telas. Qualquer dado ou foto ausente é curado automaticamente em qualquer direção (malha de autocura). Detalhes: `docs/rede-local.md`.
3. **Transparência radical.** O trabalhador vê os mesmos números financeiros que o dono. Toda alteração relevante gera `RegistroAcao` (autor, data, hora, delta). Nada é apagado silenciosamente (ex.: pedido cancelado vai para "Cancelados").
4. **Consentimento entre donos e sócios.** Dono não exclui dono sem aceite do alvo (`solicitacaoExclusaoDono`). Sócio não exclui sócio nem dono. Ninguém altera o papel de um sócio sem aceite dele (`alteracaoPapel`). Todo membro pode sair por conta própria.
5. **Humano no comando.** Onde a máquina estima (ex.: baixa de estoque por g/ml), ela **propõe**; o humano **confirma, ajusta ou cancela**.
6. **Local-first e soberano.** Funciona offline, sem APIs de Big Techs. Backup em um único JSON.
7. **Notificações isoladas por loja.** Fora de uma loja (ex.: "Meus Perfis") só aparecem demandas da conta; dentro da loja, só as daquela loja.
8. **Sem imagens decorativas.** Se há espaço de foto, ela é persistida, vinculada ao modelo e exibida em todas as telas da entidade.

## 4. Arquitetura

- **Feature-first:** `lib/src/features/<feature>/{models,providers,services,views,views/widgets}`. Transversal em `lib/src/core/` (`theme`, `widgets`, `services`).
- Imports sempre completos: `import 'package:nous/src/...';`.
- Estado com `Provider`: `AuthProvider`, `PdvProvider`, `NotificacoesProvider` (registrados em `main.dart`). Use `context.read<T>()` em callbacks e `context.watch<T>()` só onde o rebuild é necessário.
- Persistência: SQLite (`nous.db`, `BancoDadosService`) em `%APPDATA%\Nous`, com fallback/migração de `shared_preferences`. Cada loja mora no cofre do `cpfDonoOriginal`; participantes acessam por `ReferenciaLoja`.

## 5. Regras de engenharia (para não quebrar o sistema)

1. **Modelos persistidos** (`Loja`, `Cliente`, `Fornecedor`, `PedidoLoja`, `ItemLoja`, `CategoriaLoja`, `GrupoComponentesLoja`, `ConfiguracoesImpressora`, `MembroLoja`, `RegistroAcao`, `ConviteLoja`, `ReferenciaLoja`, `MovimentoEstoque`, `PagamentoFuncionario`, `TurnoCaixa`, `MovimentoCaixa`, `UsuarioNous`, `PedidoProgramado`, `ConversaChat`, `MensagemChat`):
   - `fromJson` com padrão para nulos (`?? ''`, `?? false`, `?? 0.0`).
   - Atualizar sempre os quatro: construtor, `copyWith`, `toJson`, `fromJson`.
   - Enums com `firstWhere(..., orElse: () => Padrao)`.
   - Lembrar do aviso de `flutter clean && flutter pub get`.
2. **Ciclo de vida e Reatividade:** `Scrollbar` exige `ScrollController` explícito. Nunca `setState` durante o build (use `addPostFrameCallback`). Diálogo com estado interno: `StatefulBuilder` ou `StatefulWidget`. Comparação de coleções em `didUpdateWidget` ou listeners **NUNCA deve checar apenas IDs**: deve comparar status e campos mutáveis para não bloquear atualizações visuais vindas da rede.
3. **Itens reordenáveis** (`LongPressDraggable`): usar `ValueKey`, **nunca `GlobalKey`** (trava com "Duplicate GlobalKey").
4. **Diálogos com `Flexible` + `SingleChildScrollView`:** sempre `ConstrainedBox(maxHeight: MediaQuery.sizeOf(ctx).height * 0.90)`.
5. **Rede e Sincronização Absoluta:**
   - Mutações locais (pedidos, status, chat, estoque): despachar imediatamente evento na rede local (WebSocket + REST) além de persistir no banco.
   - Nunca retransmitir mensagem recebida do balcão (`aplicandoAtualizacaoRemota`); atualização de loja não pode disparar `entrarComCpf`. Todo salvamento de loja passa por `consolidarLojaComImagensLocais`.
   - Geração de entidades temporais/agendadas: IDs devem ser **determinísticos por ciclo** (`prog_${id}_${ano}_${mes}_${dia}`) e a geração automática pertence ao nó balcão (servidor), evitando duplicação na conexão de nós secundários.
   - Em chat e mensagens: remetente envia metadados completos (inclusive foto física resolvida com autocura prévia) e buscas consultam todos os contatos cadastrados (equipe + clientes).
6. **Padrão Universal de Mensageria (Estilo WhatsApp nos padrões Nous):**
   - Todo chat da aplicação (social, loja, comanda, comunidade) DEVE seguir uniformemente o padrão de usabilidade consagrado:
     - **Unicidade Absoluta:** Entre duas pessoas físicas (CPF A e CPF B), existe **exatamente uma única conversa direta canônica** (`user_{minCpf}_user_{maxCpf}`). Históricos duplicados ou legados devem ser autoconsolidados pelo `ChatService`.
     - **Títulos com Nomes Reais:** O card na lista de conversas e o cabeçalho ativo exibem SEMPRE o **Nome Real da Pessoa**, da **Loja** ou do **Grupo**, e **NUNCA a palavra genérica "Conversa"** (a palavra genérica só pode existir se o próprio usuário a escrever intencionalmente ao renomear).
     - **Isolamento Rigoroso de Escopo:** Clientes cadastrados no PDV pertencem à gestão do restaurante (Modo Loja) e NUNCA devem poluir ou duplicar a lista de amigos/contatos do chat pessoal da rede social. Conversas de loja pertencem à loja (`lojaId`); conversas sociais pertencem à conta pessoal (`lojaId` vazio).
     - Ordem cronológica natural (mais antigas acima, mais recentes abaixo; rolagem abre na última mensagem).
     - Menu contextual na bolha (long press / clique direito): copiar texto, editar (apenas autor; histórico e badge `(editada)`), excluir para todos (apenas autor; até 1 minuto pós-envio).
     - Confirmação visual de status nas mensagens enviadas (1 check cinza: enviada; 2 checks cinzas: entregue na rede; 2 checks azuis `0xFF34B7F1`: lida).
     - Detalhes ao tocar no cabeçalho: foto editável (se grupo), contagem e lista de participantes, e galeria de mídias/documentos compartilhados.

## 6. Design (resumo; completo em `docs/design-system.md`)

- **Proibido** cor fixa (`Colors.white/black/blue...`). Permitidos: `Colors.transparent` e `theme.dangerColor`. Opacidade: `.withValues(alpha: x)`, nunca `.withOpacity()`.
- Texto: `theme.textColor` (títulos/valores), `theme.secondaryTextColor` (rótulos/descrições).
- Diálogos sempre centralizados com `showDialog`. **Nunca Bottom Sheet.**
- Toda ação destrutiva: rótulo em `theme.dangerColor` + confirmação em `AlertDialog`.
- Listas vazias: `EstadoVazioContainer`. Texto logon: `TextoRolante`. Interruptor: `ThemedSwitch`.
- Celular = modo compacto fixo (layout desktop nunca disponível no celular).

## 7. Onde está cada coisa

| Preciso de... | Leia |
|---|---|
| Saber o que existe em cada tela/container/botão e em qual arquivo | `MAPA_DO_APP.md` |
| Termos técnicos explicados / como pedir uma mudança | `GLOSSARIO.md` |
| Rede Wi-Fi, sincronização, malha de autocura, endpoints | `docs/rede-local.md` |
| Regras de venda, estoque, caixa, financeiro, pedidos | `docs/regras-de-negocio-pdv.md` |
| Cores, componentes visuais, imagens, mídia | `docs/design-system.md` |
| Scripts, instalador, APK, atualização, versão | `docs/build-e-distribuicao.md` |
| Política, ontologia, por que o sistema é assim | `docs/filosofia.md` |
| Histórico do que já foi feito | `CHANGELOG.md` |

## 8. Juramento

Este software é construído por um trabalhador brasileiro para libertar outros trabalhadores da dependência, da opacidade e da exploração. Trate cada linha com respeito e honestidade, economize contexto, seja cirúrgico e respeite a arquitetura e a visão social do projeto.
