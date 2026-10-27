# Glossário do Nous (para quem não é programador)

Este arquivo explica as palavras que aparecem nos outros documentos e como pedir mudanças de um jeito que a IA entenda de primeira.

## Como pedir uma mudança (modelo)

Quanto mais você disser **onde** e **o quê**, menos chance de erro. Use este formato:

> **Tela:** (nome que aparece na tela, ex.: "Dados da Loja")
> **Container ou janela:** (ex.: "Usuários Participantes")
> **Botão ou elemento:** (ex.: botão "Convidar")
> **Mude:** (o que deve acontecer de diferente)
> **Onde vale:** (celular, computador ou os dois)

Exemplo:
> Na tela **Meus Perfis**, no **botão de Notificações** (sino): não mostre avisos de lojas, só convites da conta. Vale para celular e computador.

Dicas:
- Se não souber o nome, diga "o quadro que fica abaixo de X" ou mande um print.
- Diga se é **só visual** ou se muda **o que o sistema faz**.
- Peça uma coisa de cada vez quando possível.
- Se a IA propuser algo diferente do que você queria, diga "não era isso, eu queria...". Ela deve explicar o raciocínio antes de mexer no código.

## Termos de tela

| Termo | O que é |
|---|---|
| **Tela (View)** | Uma página inteira do app. Ex.: Login, Meus Perfis, Dados da Loja. Arquivos terminam em `_view.dart`. |
| **Janela / Diálogo (Dialog)** | Caixa que abre no meio da tela por cima da tela atual (ex.: Nova Venda, Caixa). Arquivos terminam em `_dialog.dart`. |
| **Container** | Um quadro/bloco dentro de uma tela, com título e conteúdo (ex.: "Usuários Participantes"). |
| **Card** | Um quadrinho que representa uma coisa (um produto, uma conta). |
| **Barra** | Uma linha de lista (um membro, um cliente, um pedido). |
| **Aba** | Uma "página" dentro de uma tela, escolhida por botões no topo ou lateral (Dados, Ajustes do Perfil, Loja, Gestão). |
| **Barra superior (AppBar)** | Faixa no topo com título, sino de notificações, atualização e engrenagem. |
| **Barra lateral (Sidebar)** | Menu fixo à esquerda no layout desktop expandido. |
| **Sino** | O botão de Notificações. |
| **Engrenagem** | O botão de Configurações. |
| **Hover** | Efeito visual quando o mouse passa por cima (só existe no computador). |
| **Layout compacto** | Visual de coluna única, feito para celular. No celular é o único disponível. |
| **Layout desktop expandido** | Visual com barra lateral e colunas duplas, para computador. |
| **Tela cheia (F11)** | Esconde as bordas da janela do Windows. Não tem relação com o layout compacto/expandido. |
| **Texto rolante (marquee)** | Texto que desliza quando é grande demais para caber. |
| **Switch / Interruptor** | Botão de ligar/desligar. |
| **Rascunho** | Venda começada e não concluída, guardada para não se perder. |

## Termos do sistema

| Termo | O que é |
|---|---|
| **Loja / Perfil profissional** | Um negócio cadastrado. Tipos: Loja Padrão, Restaurante, Fretes e Viagens. |
| **Dono, Sócio, Administrador, Funcionário** | Papéis de quem participa da loja. Dono e Sócio são os fundadores e têm poder igual. |
| **Cargo** | Papel personalizado criado pela loja (estilo Discord), com permissões escolhidas. |
| **Cofre** | Onde os dados de uma loja ficam guardados, ligado ao CPF do dono original. |
| **Referência de loja** | Um "atalho" que diz que você participa de uma loja que está no cofre de outra pessoa. |
| **Identidade do Usuário (ficha)** | Seus dados pessoais, ligados ao CPF. |
| **Balcão** | O computador principal da loja. Ele pode servir dados aos celulares. |
| **Terminal móvel** | Celular conectado ao balcão pela rede Wi-Fi. |
| **Rede local** | Os aparelhos conectados ao mesmo Wi-Fi, sem precisar de internet. |
| **Sincronização** | Os aparelhos trocarem informações para ficarem iguais. |
| **Malha de autocura** | Quando um aparelho nota que falta algo (ex.: uma foto) em outro e manda o que falta, sem ninguém pedir. |
| **Local-first** | O app funciona no próprio aparelho, sem depender de internet ou nuvem. |
| **Snapshot** | Uma "foto" dos dados da loja num instante. |
| **Notificação deliberativa** | Aviso que exige sua resposta (aceitar/recusar), como pedido de mudança de papel. |
| **Auditoria (RegistroAcao)** | Histórico de quem fez o quê e quando. |
| **À Prazo / Fiado** | Venda cujo pagamento fica pendente na ficha do cliente. |
| **Sangria / Suprimento** | Retirada / entrada de dinheiro na gaveta do caixa durante o turno. |
| **Turno de caixa** | Período entre abrir e fechar o caixa. |
| **Fechamento cego** | O operador conta o dinheiro sem ver o que o sistema espera. |
| **Kardex** | Ficha de um produto com todas as entradas e saídas de estoque. |
| **DRE** | Demonstrativo de resultado: receita, custos, lucro. |
| **Variante** | Versão de um produto com preço próprio (ex.: tamanho, material). |
| **Modo Balcão** | Tela de caixa rápida para bipar produtos e finalizar vendas. |
| **Envio Otimista (0ms)** | A mensagem aparece imediatamente na tela ao enviar, sem esperar banco ou rede responder. |
| **Fila de Saída (Outbox)** | Mensagens enviadas sem sinal ficam salvas no aparelho e são transmitidas sozinhas ao reconectar. |
| **Confirmação em 4 Estágios** | Relógio (pendente), 1 check cinza (enviada), 2 checks cinzas (entregue) e 2 checks azuis (lida). |
| **Fixação de Conversas** | Manter conversas importantes no topo da lista com um alfinete discreto. |

## Termos de programação

| Termo | O que é |
|---|---|
| **Flutter / Dart** | A ferramenta e a linguagem em que o app é escrito. |
| **Widget** | Qualquer peça visual do Flutter (botão, texto, tela inteira). |
| **Model (modelo)** | Arquivo que descreve um tipo de dado (Loja, Cliente, Pedido). Fica em `models/`. |
| **Provider** | Guarda dados que várias telas usam e avisa as telas quando mudam. Fica em `providers/`. |
| **Service (serviço)** | Código que faz um trabalho específico (imprimir, salvar no banco, falar com a rede). Fica em `services/`. |
| **SQLite** | O banco de dados dentro do próprio aparelho (`nous.db`). |
| **JSON** | Formato de texto usado para salvar e trocar dados (e para o arquivo de backup). |
| **`fromJson` / `toJson`** | Funções que leem e gravam um modelo em JSON. Se mudar um campo, os dois precisam mudar. |
| **`copyWith`** | Função que cria uma cópia de um modelo com alguns campos alterados. |
| **Enum** | Lista fixa de opções (ex.: status do pedido). |
| **REST / endpoint** | Pedido HTTP a um endereço do balcão (ex.: `GET /api/loja`). |
| **WebSocket** | Canal aberto entre aparelhos para avisos em tempo real. |
| **UDP broadcast** | O balcão "gritando" na rede "estou aqui" para os celulares o acharem. |
| **Debounce** | Esperar um instante antes de enviar, para não mandar mil mensagens seguidas. |
| **Build** | Gerar o programa final (instalador, APK). |
| **APK** | O arquivo de instalação do Android. |
| **`flutter clean && flutter pub get`** | Comandos que limpam o cache e baixam as dependências. Rode quando a IA avisar. |
| **`pubspec.yaml`** | Arquivo com nome, versão e pacotes do projeto. |
| **Dependência / pacote** | Código pronto de terceiros usado no projeto. |
| **Diff** | Mostra o que foi removido e o que foi adicionado numa edição. |
| **Refatorar** | Reorganizar o código sem mudar o que ele faz. |
| **Skill** | Arquivo de instruções que ensina a IA a fazer um tipo de tarefa. |
