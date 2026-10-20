# MAPA DO APP — o que cada tela faz

Este documento descreve o Nous **por tela**: Tela → Container → Botão → o que acontece. Cada tela aparece **uma vez só**. Use-o para pedir mudanças ("na tela X, no container Y, o botão Z...").

**Como ler**
- 📄 indica o arquivo no código. Caminhos abreviados: `auth/` = `lib/src/features/auth/`, `pdv/` = `lib/src/features/pdv/`, `core/` = `lib/src/core/`, `notif/` = `lib/src/features/notificacoes/`.
- **(a confirmar)** = informação deduzida do nome do arquivo ou do texto antigo, ainda não conferida no código.
- Regras detalhadas de negócio: `docs/regras-de-negocio-pdv.md`. Rede/sincronização: `docs/rede-local.md`. Visual: `docs/design-system.md`.

---

## 0. Caminho geral do usuário

1. Abre o app → **Login** (`main.dart` abre `LoginView`).
2. Digita o CPF → **Entrar** → abre a janela de **Sincronização em Rede Wi-Fi** com a ficha de quem está entrando.
3. Passa pela tela de contas (**ContasUsuarioView**) e chega em **Meus Perfis** (a lista das lojas dele). (a confirmar a ordem exata)
4. Toca em uma loja → entra na **Tela da Loja** (`DadosPerfilView`), com as abas Dados, Ajustes do Perfil, Loja e Gestão.
5. Dentro da loja abre as janelas de trabalho (Nova Venda, Caixa, Clientes...).

Dois estados mudam o comportamento de várias telas:
- **Fora de uma loja** (Login, Meus Perfis): notificações mostram só avisos da conta.
- **Dentro de uma loja**: notificações e contador mostram só avisos daquela loja.

---

## 1. Login e Identidade

### 1.1 Tela de Login
📄 `auth/views/login_view.dart` · widgets: `cpf_input_widget.dart`, `login_buttons_widget.dart`, `logo_widget.dart`
- **Campo CPF**: já vem preenchido com o último CPF que entrou (guardado no aparelho como `ultimo_cpf_login`). Valida o CPF (`cpf_validator.dart`).
- **Botão "Entrar"**: abre imediatamente a janela de Sincronização em Rede Wi-Fi (ver 4.1), mostrando no topo a ficha de quem está entrando: foto, nome em negrito, `@apelido` e CPF formatado.
- **Ao digitar um CPF que já existe** (neste aparelho ou em outro da rede): recupera nome, data de nascimento e foto. Se o aparelho foi reinstalado, pergunta ao balcão pela rede.
- **Ao digitar um CPF novo** (sem ficha em lugar nenhum): abre `CadastrarApelidoDialog` pedindo só o **Apelido**. Ao confirmar, cria a conta e o usuário vira **funcionário** da loja à qual se conectou. 📄 `auth/views/widgets/cadastrar_apelido_dialog.dart`
- Outras telas de acesso: `associar_cpf_view.dart` (associar CPF), `terms_view.dart` (termos de uso), `adicionar_email_dialog.dart` (adicionar e-mail à conta). (a confirmar detalhes)

### 1.2 Contas do usuário (pós-login)
📄 `auth/views/contas_usuario_view.dart`
- Lista as contas disponíveis no aparelho (várias contas por aparelho são permitidas). Tocar na conta abre a **Identidade do Usuário** (1.3).

### 1.3 Janela "Identidade do Usuário"
📄 `auth/views/widgets/ficha_usuario_dialog.dart`
- Topo: **foto**, **apelido** (`@`), **nome civil em negrito** e **CPF** logo abaixo (o CPF não se repete no bloco de dados pessoais).
- Bloco **Dados pessoais**: data de nascimento, nome do pai, nome da mãe, local de nascimento, tipo sanguíneo, estado civil, e-mails.
- Botão **"Editar dados pessoais"**: fica sempre visível **abaixo** de todos os dados. Ao clicar, o bloco vira editável com **Salvar** e **Cancelar**.
- **Modo somente leitura**: ao abrir a ficha de outra pessoa, nada é editável. Ao abrir a própria, é editável.
- A foto e os dados são os mesmos em qualquer aparelho do mesmo CPF (sincronização pela rede).
- Só se chega nesta janela pelo card da conta em **Configurações** (2.2), por **Contas do usuário** (1.2) ou ao tocar num membro em **Usuários Participantes** (6.1).

---

## 2. Barra superior e Configurações

### 2.1 Barra superior
📄 `core/widgets/custom_app_bar.dart`
- **Título** da tela, centralizado. **Seta de voltar** quando aplicável.
- Lado direito, nesta ordem:
  - **Sino (Notificações)**: abre 3. Mostra um contador vermelho. Fora da loja: só avisos da conta. Dentro da loja: só avisos daquela loja.
  - **Atualizações**: aparece **somente** se houver versão nova. Abre `AtualizacaoDialog` (5.3).
  - **Engrenagem (Configurações)**: abre 2.2.
- **Não existe** botão de perfil nem botão fixo de Wi-Fi nesta barra.

### 2.2 Janela "Configurações"
📄 aberta a partir de `custom_app_bar.dart` · rolável com altura máxima de 85% da tela (o botão **Sair** sempre fica visível no celular).
- **Botão de Sincronização Wi-Fi** (`_BarraSincronizacaoWifiSettings`): barra com hover, acima da Identidade. Mostra "Servidor Ativo", "Conectado ao Balcão" ou "Desconectado" e abre a janela 4.1.
- **Card da conta**: foto, nome completo, CPF formatado e e-mail ativo. Tocar abre a **Identidade do Usuário** (1.3).
- **Personalizar Aparência**: abre `ThemeCustomizerDialog` (cores, fontes, tamanhos, cor de exclusão). O tema é salvo por CPF. 📄 `core/theme/theme_customizer_dialog.dart`
- **Sair**: faz logout, desconecta as redes locais e volta ao Login.
- (a confirmar) Atalho para **Backup** (5.4).

### 2.3 Tela cheia (F11)
📄 `main.dart` (interceptador global) + `core/services/janela_windows_service.dart`
- **F11** alterna tela cheia do Windows em qualquer lugar do app (login, loja, qualquer janela aberta). Tecla fixa, não é configurável.
- Ao sair da tela cheia, se a janela estava maximizada ela volta maximizada; senão volta ao tamanho anterior.
- **Não** muda o layout compacto/expandido (isso é feito em "Ajustes do Perfil", 6.2).

---

## 3. Notificações

📄 `notif/views/widgets/notificacoes_dialog.dart` · `notif/providers/notificacoes_provider.dart` · `notif/models/convite_loja.dart` · `notif/services/convites_service.dart`

- **Cabeçalho**: botão **"Limpar todas as notificações"** (ícone `clear_all`). Dispensa todas de uma vez nesta sessão (`dispensarTodasNaSessao`).
- **Cada card** pode ser **arrastado para o lado** para dispensar. É só da sessão: ao reabrir o app, o que não foi resolvido reaparece.
- **Tipos de aviso**:
  - Convite para participar de uma loja (aceitar/recusar).
  - Alteração de papel de sócio (`alteracaoPapel`): "Solicitação de [Nome]: alteração do seu papel em [Loja] para [Novo Papel]". Aceitar aplica; recusar descarta.
  - Pedido de saída de dono (`solicitacaoExclusaoDono`): só se efetiva se o dono alvo aceitar.
  - Remoção da loja (`remocaoLoja`): "Você foi removido(a) da loja [Loja] por [Nome]".
  - **Alerta de estoque baixo/esgotado** (menos de 10 unidades ou ≤ 0): mostra loja, produto e saldo com unidade.
- **Tocar num alerta de estoque**: fecha a janela e abre `MovimentoEstoqueDialog` (7.12) com o item e o tipo "Entrada" já escolhidos, para repor na hora. Com saldo ≥ 10, o alerta some.
- **Isolamento**: em "Meus Perfis" só aparecem convites e avisos de papel. Dentro da loja, só avisos daquela loja (`pdv.itensEstoqueBaixoPorLoja`).

---

## 4. Rede Wi-Fi

### 4.1 Janela "Sincronização em Rede Wi-Fi"
📄 `pdv/views/widgets/sincronizacao_rede_dialog.dart` · serviços em `pdv/services/rede_local/` (`servidor_rede_local.dart`, `cliente_rede_local.dart`)
- Abre ao clicar em **Entrar** (Login), pelo botão em **Configurações** (2.2) e pelo primeiro item de **Ajustes do Perfil** (6.2).
- Topo: ficha do operador ativo (foto, nome, `@apelido`, CPF).
- Duas abas: **Servidor Balcão** e **Terminal Móvel**.
  - **Servidor Balcão**: liga o computador como servidor (porta 8080). A própria máquina aparece de imediato na lista de pareados (ícone de desktop e nome real do computador). Lista os terminais conectados com nome do aparelho, nome, apelido, CPF e IP. Botão para copiar o IP.
  - **Terminal Móvel**: o celular lista automaticamente os balcões achados na rede (botão **Conectar**) ou conecta por IP e porta manualmente. O computador que é servidor **não pode** se conectar a si mesmo.
- **Quando um celular novo tenta conectar**, o balcão mostra uma janela com som: nome do aparelho, nome do usuário, CPF e IP, com **Autorizar** ou **Recusar**. Sem resposta em 30 segundos, o celular recebe 403 (negado).
- Funcionamento interno: `docs/rede-local.md`.

---

## 5. Meus Perfis e criação de loja

### 5.1 Tela "Meus Perfis"
📄 `pdv/views/perfis_pdv_view.dart`
- Duas listas: **"Perfis que eu administro"** (Administra) e **"Perfis que eu participo"** (Participa). No desktop, em grade de 2 colunas.
- Mostra as **mesmas lojas em qualquer aparelho do mesmo CPF** (fusão automática pela rede).
- A loja do próprio dono nunca aparece duplicada.
- **Sino**: só avisos da conta (convites, papéis), sem avisos de lojas.
- Tocar numa loja entra nela (6).

### 5.2 Criar perfil / loja
📄 `pdv/views/widgets/criar_perfil_dialog.dart` · `pdv/views/cadastrar_loja_view.dart` (a confirmar a divisão entre os dois)
- Escolha de categoria: **Loja Padrão** (varejo, venda direta), **Restaurante** (cardápio, adicionais, mesas e comandas), **Fretes e Viagens** (transporte e entregas).
- Importar um backup **mescla** sem duplicar loja com o mesmo CNPJ (5.4).

### 5.3 Janela de Atualização
📄 `core/widgets/atualizacao_dialog.dart` · `core/services/atualizacao_service.dart`
- Mostra a versão instalada e a disponível. Se for a mesma versão, o botão sai da barra.
- No celular com versão nova no balcão: **baixa o APK dentro do app com barra de progresso** e abre o instalador do Android.
- Fonte local (balcão) tem prioridade sobre a internet.

### 5.4 Backup
📄 `pdv/views/widgets/backup_dialog.dart` · `pdv/services/backup_service.dart`
- **Exportar**: salva contas, lojas, referências e convites num único `.json`.
- **Importar → Substituir**: zera o banco local e aplica o arquivo. **Importar → Mesclar**: junta com o que existe, sem apagar nada local.
- Backup automático diário e silencioso em `%APPDATA%\Nous\backups\backup_nous_AAAA-MM-DD.json` (até 30 cópias).
- Depois de importar, as telas atualizam sozinhas, sem reiniciar.

---

## 6. Tela da Loja (`DadosPerfilView`)

📄 `pdv/views/dados_perfil_view.dart`

Quatro abas (`AbaLoja`): **Dados**, **Ajustes do Perfil**, **Loja / Catálogo** e **Gestão de Pedidos**.

**Layout compacto (celular, ou desktop em modo compacto)**: as abas ficam numa navegação inferior/superior, coluna única.
**Layout desktop expandido**: aparece a **barra lateral fixa** à esquerda (6.0) e as janelas ficam mais largas, em duas colunas.

Esta tela atualiza **em tempo real** quando muda algo no balcão ou em outro celular: pedidos, estoque, produtos, categorias, grupos, clientes, fornecedores, mesas, membros, papéis e status Aberta/Fechada.

### 6.0 Barra lateral (só no desktop expandido)
📄 `pdv/views/widgets/desktop_sidebar_widget.dart`
- Topo: **logo da loja**, nome e indicador de caixa **aberto/fechado**.
- Ordem dos módulos: **1. Dados da Loja → 2. Ajustes do Perfil → 3. Loja / Catálogo → 4. Gestão de Pedidos**.
- **Comandos rápidos**: Nova Venda, Clientes, Impressora, Relatórios, Caixa, Financeiro, Mensagens, Status da Loja, **Modo Balcão** (abaixo de Status da Loja).
  - Cada botão mostra um selo com a tecla configurada (ex.: `F1`). Se a função está **Desativada**, mostra só um quadradinho vazio (22×18 px), para manter o alinhamento.
  - Clicar com o mouse sempre executa a ação, tenha ou não tecla.
- Quando esta barra está ativa, os botões de ação do topo da Gestão ficam **ocultos** (seriam repetidos). No layout compacto eles aparecem.

### 6.1 Aba "Dados"
Containers, de cima para baixo:
1. **Formulário de Dados da Loja** 📄 `pdv/views/widgets/formulario_dados_loja.dart`: nome, documento (CNPJ), logo, contatos etc.
2. **Cargos e Permissões (estilo Discord)** 📄 `pdv/views/widgets/cargos_permissoes_container.dart`
   - Começa **minimizado**; clique expande/recolhe.
   - Abas: **Dono, Sócio, Administrador, Funcionário** e cargos criados em **"+ Novo Cargo"**.
   - Lista todas as permissões, cada uma com explicação e interruptor.
   - **Dono e Sócio**: interruptores travados com o aviso "Regra fundamental do sistema (inalterável)".
   - Dono e Sócio podem alterar livremente as permissões de Administrador, Funcionário e cargos criados (salvo em `Loja.permissoesCargosNativos`; se não houver, valem os padrões `Loja.permissoesPadraoPorPapel`).
   - Se a permissão **"Gerenciar Membros e Cargos"** for dada a Administrador/Funcionário, eles passam a poder alterar papéis de outros membros (nunca de Dono ou Sócio).
3. **Usuários Participantes** 📄 `pdv/views/widgets/usuarios_participantes_container.dart`
   - Cada membro é uma **barra com foto, nome e hover**. A foto vem pelo CPF (`auth.buscarFotoPorCpf` e, se faltar, `pdv.buscarFotoClientePorCpf`).
   - **Clicar em outro membro**: abre a **Identidade do Usuário** em somente leitura. **Clicar em si mesmo**: abre editável.
   - **Editar membro**: escolher papel operacional e vincular um **cargo** criado. O subtítulo mostra o cargo.
   - **Alterar papel de um Sócio**: não aplica na hora. Envia notificação e só muda se o sócio aceitar.
   - **Excluir membro**: Dono exclui Sócio, Admin e Funcionário; Sócio exclui Admin e Funcionário; Admin e Funcionário não excluem ninguém. Dono não exclui Dono: envia pedido de saída. Quem é removido recebe aviso. Qualquer um pode **sair** por conta própria. Botão de excluir em vermelho, com confirmação.
   - Convidar: `_ConviteDialog` mostra a foto da conta encontrada pelo CPF.
4. **Tempo de Conclusão dos Pedidos**: título centralizado; escolhe "Manual" ou 15/30/45/60 min etc. Com tempo definido, pedido **Aceito** que passar do prazo dispara a pergunta "O Pedido #N já foi concluído?" (Ainda não / Sim, concluir pedido).
5. **Galeria / Anexos** 📄 `pdv/views/widgets/galeria_estilo_container.dart` · pasta `pdv/views/widgets/midia/`
   - Cards de 156×126 px com prévia por tipo: áudio com capa de álbum (ou gradiente com selo `.MP3`), imagem, vídeo, documento (selo `PDF`/`DOCX` e tamanho).
   - **Imagem**: abre `VisualizadorGaleriaDialog` em tela cheia, com zoom, setas (tela e teclado ← →), contador e legenda.
   - **Áudio, vídeo, documento**: abre `DetalhesMidiaDialog` com contador `X / Total`, setas laterais, teclado ← → e **autoplay** da próxima faixa (se não estiver em loop).
   - **Legendas**: editáveis a qualquer momento (`editar_descricao_dialog.dart`), salvas em `Loja.descricoesAnexos`.
   - Remover foto/anexo pelo "X" pede confirmação ("Tem certeza de que deseja retirar esta imagem?").
   - Recortar foto: `AjustarImagemDialog` (zoom, +/−/reset, salva PNG).
6. **Arquivos de Áudio** e **Sons e Alertas do Sistema** (abaixo): 9 efeitos nativos, teste imediato, e escolha por evento: *Novo Pedido Recebido*, *Tempo Limite / Alerta de Pedido*, *Bip de Leitura na Venda*. Cada evento aceita Bip Padrão, Silencioso ou qualquer áudio anexado.

> Containers de **Delivery** (`delivery_container.dart`) e **Dados Bancários** (`dados_bancarios_container.dart`) existem como arquivos, mas estão **desacoplados** desta versão. (a confirmar se ainda são usados em alguma tela)

### 6.2 Aba "Ajustes do Perfil"
Primeiro item: botão de **Sincronização em Rede Wi-Fi** (abre 4.1). Depois:
1. **Modo de Visualização e Layout do PDV** 📄 `pdv/views/widgets/seletor_layouts_desktop_widget.dart`
   - **Desktop**: alterna entre **Layout Desktop PDV Expandido** (barra lateral + colunas duplas) e **Layout Compacto Padrão**. É preferência da máquina, sempre disponível, sem exigir ser dono.
   - **Celular**: mostra só um card informando que o modo compacto está ativo, sem opção de mudar.
   - Não mexe na tela cheia (F11).
2. **Comandos** (atalhos de teclado)
   - Duas colunas lado a lado: **F1–F6** e **F7–F12**. No celular, 1 coluna.
   - Todas as teclas nascem **Desativadas**; o usuário escolhe. Salvo em `Loja.atalhosTeclado`.
   - **F11 é fixa** ("Tela Cheia (Padrão do Sistema)", com selo "Fixo"). **Esc** é fixa no topo ("Voltar / Fechar Janelas").
   - **Quando aparece**: some no **modo compacto em celular** (Android/iOS sem teclado físico). Aparece no Windows, mesmo em modo compacto, e quando um teclado físico é detectado.
3. **Tempo de Conclusão dos Pedidos** e **Sons e Alertas do Sistema**: ver 6.1 (itens 4 e 6, quando exibidos aqui). (a confirmar em qual aba cada um está)
4. **Financeiro do Perfil**: botão **Resetar Transações** (confirmação em vermelho). Apaga vendas, turnos de caixa e pagamentos a trabalhadores; **mantém** produtos, clientes, membros e o saldo físico de estoque. Só Dono, Sócio ou quem tiver a permissão `resetarTransacoes`.
5. **Somente leitura**: quem não é Dono/Sócio vê um **banner com cadeado** e os seletores ficam esmaecidos (opacidade 0,65) e bloqueados.

### 6.3 Aba "Loja / Catálogo"
📄 partes: `categoria_loja_container.dart`, `grupo_componentes_loja_container.dart` (e `grupo_componentes_container.dart`, a confirmar qual está em uso), `produto_loja_row.dart`, `componente_loja_row.dart`, `item_loja_card.dart`, `estoque_container.dart`
- **Categorias**: lista vertical. **Grupos de Componentes**: lista vertical. **Produtos**: cards (compacto horizontal ou grade em `Wrap` no expandido).
- **Reordenar**: segurar **1 segundo** em um card/barra e arrastar; ele flutua, abre espaço e encaixa ao soltar (ordem salva na hora). Só quem tem `possoEditarAbaLoja`.
- **Altura das listas**: no desktop, até ~7–8 barras antes de rolar (altura máx. 440); no celular, 180.
- **Card de produto** (`ItemLojaCard`): foto, badge de saldo (`Est: X`, com kg/L automáticos) ou **"Esgotado"** em vermelho.
- **Estoque**: tocar num item abre a **Ficha Kardex** (preço de venda e custo, estoque mínimo, código de barras, saldo e histórico cronológico).
- Botões típicos: Novo Item, Nova Categoria, Novo Grupo (rótulo curto "Novo Grupo" em telas estreitas).

### 6.4 Aba "Gestão de Pedidos"
📄 `pdv/views/widgets/gestao_loja_container.dart`
- Botões de ação no topo (somem no desktop expandido): **Nova Venda, Clientes, Impressora, Relatórios, Caixa, Financeiro, Mensagens, Status da Loja**. Em tela < 520 px ficam em 2×2.
- **Abas de pedidos**: **Novos, Aceitos, Concluídos, Cancelados**. Lista com ~380 px de altura no desktop. Concluídos e Cancelados: **mais recentes primeiro** e com **campo de busca** (por #0001, cliente, produto).
- **Novos**: tocar num pedido abre a comanda com **Recusar / Imprimir / Aceitar**. Pedidos programados do dia entram aqui sozinhos.
- **Ao entrar no app**: se houver pedidos Novos, toca o alerta sonoro e abre a comanda do primeiro; **Aceitar/Recusar** passa para o próximo; o **X** interrompe a fila sem perder nada.
- **Aceitos**: tocar abre `PedidoAceitoDialog`, com botão de **impressora** (reimprime a comanda sem concluir), **Cancelar Pedido** e **Concluir**.
- **Cancelados**: tocar abre `PedidoCanceladoDetalhesDialog` (quem cancelou, quando, motivo, se houve estorno).
- **Mesas** (só perfil Restaurante): container retrátil **"Mesas"** entre os botões e o painel de pedidos (ver 7.8).
- Avisos de pedidos programados do dia também abrem aqui ao entrar (`PedidosProgramadosDialog`).

---

## 7. Janelas de trabalho do PDV

Todas abrem centralizadas, aceitam **F11** e, no desktop expandido, ficam em **duas colunas** (~1050 px).

### 7.1 Nova Venda
📄 `nova_venda_dialog.dart`
- **Estado inicial limpo.** Campo de busca em branco com foco → mostra **só as categorias**. Produtos soltos só aparecem ao pesquisar ou bipar.
- **Nome do Cliente**: com foco e vazio, lista **todos os clientes**; filtra ao digitar (nome, rua, número, CPF/CNPJ, telefone, e-mail, redes, descrição).
- **Leitor de código de barras**: digitar/bipar o código exato + Enter adiciona ao carrinho e limpa o campo.
- **Variantes**: ao escolher produto com variantes, abre seletor (Padrão + variantes com preço).
- **Frete, Desconto, Acréscimo**: aceitam R$ ou `%` (ex.: `10%`). Ao tocar, o valor inteiro fica selecionado.
- **Pagamento**: Dinheiro, Pix, Débito, Crédito, À Prazo; pode combinar várias formas. Troco = excesso real sobre o total.
- **Rascunho**: se a janela for fechada sem querer (Esc, voltar, clique fora), tudo é guardado e volta ao reabrir. Botão **lixeira** "Limpar campos da venda". Venda concluída limpa o rascunho.
- Cada item mostra saldo (`Est: X un`) ou "Esgotado".
- Cadastro rápido de produto aqui com estoque inicial gera o movimento de estoque automaticamente.
- Ao concluir: **VendaConcluidaDialog** (cupom). Protegido: sair pede para salvar ou descartar; tem **Voltar** e **"Voltar para edição"**.

### 7.2 Modo Balcão (frente de caixa)
📄 `modo_balcao_widget.dart` · abre pela barra lateral ("Modo Balcão") ou pelo botão equivalente; **Esc** volta.
- **Esquerda (Operador)**: campo de bipador sempre focado; visor do último produto (foto, quantidade, nome, valor); catálogo por categorias com badges de saldo; busca de cliente com painel flutuante (avatar, CPF/CNPJ, telefone, endereço) e chip do cliente selecionado com botão de desvincular.
- **Direita (Comanda ampliada)**: cada item com nome completo (categoria e variante), preço, **+ / − / remover**, resumo dos adicionais, observação em itálico (`Obs: ...`) e botões **+ Componentes** e **+ Observação / Editar Obs**.
- Campos **Frete** (acima de **Acrésc:**), **Desconto**, **Acréscimo**; **TOTAL GERAL** gigante; formas de pagamento com valor recebido e **troco em verde**.
- **FINALIZAR VENDA (ENTER)**: baixa estoque e abre o cupom.
- **À Prazo** exige cliente: sem cliente, abre a busca; finalizar sem cliente é bloqueado. Se o cliente for desmarcado, volta para "Dinheiro".
- Venda avulsa em "Todos" cobra o preço puro do item; o preço da categoria só soma se a categoria estiver selecionada.

### 7.3 Clientes
📄 `clientes_dialog.dart`
- Lista com **busca** e formulário de cadastro. Campo **"CNPJ ou CPF"** com máscara automática (até 11 dígitos = CPF, 12 a 14 = CNPJ).
- **Autopreenchimento**: ao completar o documento, busca em contas Nous, lojas e cadastros prévios e preenche nome, telefone, endereço, e-mail, redes e foto.
- Altura da lista de clientes: 490 px no desktop expandido; 200 px no compacto.
- Ao tocar num cliente: valor total já gasto, histórico, **Exportar Extrato PDF**, **Programar Pedido**, **Pedidos Programados** (ver, pausar/ativar, excluir) e quitação.
- **Quitar valor / Quitar tudo**: abre confirmação mostrando cliente, valor, dívida atual e saldo restante. Escolhe a forma (Dinheiro, Pix, Cartão). Se for dinheiro e o caixa estiver aberto, registra um **suprimento** no turno.
- **Excluir Cliente**: em vermelho, com confirmação; avisa se houver débito a prazo. O histórico de pedidos é preservado.

### 7.4 Fornecedores
📄 `fornecedores_dialog.dart` — lista e clientes vinculados à esquerda; cadastro à direita. Busca multicampo. Excluir em vermelho com confirmação. Opção "usar cliente como fornecedor" mostra a foto do cliente.

### 7.5 Caixa do Balcão
📄 `caixa_dialog.dart` · `detalhes_turno_caixa_dialog.dart`
- **Caixa fechado**: formulário de **abertura** (fundo de troco, responsável) e lista **"Últimos Turnos Fechados"**.
  - Cada barra tem hover, seta e dica; **clicar** abre `DetalhesTurnoCaixaDialog`; o botão de **impressora** reimprime o fechamento sem abrir detalhes.
- **Caixa aberto**: **Suprimento** (entrada) e **Sangria** (saída), ambos com justificativa obrigatória e botões **Confirmar** / **Confirmar e Imprimir** (comprovante com linha de assinatura). Histórico do turno com reimpressão de 2ª via.
- **Fechar caixa** (fechamento cego): informa o contado em Dinheiro, Crédito, Débito, Pix e Outros; o sistema compara e mostra sobra ou falta. Emite comprovante de fechamento (58 ou 80 mm).
- **Detalhes do turno**: quem abriu e quem fechou (foto, nome, CPF), horários, duração, resumo (fundo, vendas por forma incluindo À Prazo, suprimentos, sangrias, esperado × informado, divergência em `dangerColor`), abas de **movimentações** e de **vendas do turno**, observação de fechamento e **Apagar Registro** (confirmação + auditoria).

### 7.6 Relatórios
📄 `relatorios_dialog.dart`
- Filtros por data com botões `<` e `>`, calendário e campo de data.
- **Pedidos Programados** (acima de Pendências): agendamentos do dia, com foto do cliente, horário e frequência; clique abre a comanda.
- **Pendências**: pedidos a prazo em aberto **agrupados por cliente** (total devido, último pedido, selo com quantidade). Clique abre a ficha do cliente, ou a comanda se for pedido avulso.
- **Ações** (auditoria): cada barra abre `_DetalhesAcaoDialog` com data/hora, autor (CPF e e-mail) e descrição, com atalho **"Ver Perfil de [Cliente]"** ou **"Ver Comanda do Pedido #N"** quando ainda existem.

### 7.7 Impressora
📄 `impressora_dialog.dart` · `pdv/services/impressao_service.dart`
- Coluna 1: conexão, **largura da bobina (58 / 80 mm)**, **Tipografia da Comanda** (lista de 11 fontes com prévia), **Calibração Bilateral** (margem esquerda padrão 5 mm e direita padrão 3 mm, passos de 0,5 mm).
- Coluna 2: dados da loja/cliente no recibo, automações (**impressão automática ao concluir venda**), rodapé, **testar** e **salvar**.
- **Prévia viva** da comanda dentro da calibração, com um dos 10 perfis históricos (sorteado), e botão de impressora para imprimir o exemplo.

### 7.8 Mesas e Comandas (Restaurante)
📄 pasta `pdv/views/widgets/mesas/` — `mesas_container.dart`, `criar_mesa_dialog.dart`, `comanda_mesa_dialog.dart`, `adicionar_item_mesa_dialog.dart`, `fechar_conta_mesa_dialog.dart`, `transferir_mesa_dialog.dart`
- Cada mesa tem status (**livre/ocupada**), número, descrição/capacidade, cliente e atendente.
- Lançar item (com variantes e adicionais); remover item gera auditoria. **Imprimir conferência** (pré-fechamento).
- **Transferir / Unir** comandas.
- **Fechar conta**: pagamento único ou **dividido** em várias formas com saldo restante; botão de **10% de atendimento**; desconto. Se faltar quitar ou sobrar pagamento, **bloqueia**. Forma "À Prazo" exige cliente; se não existir, abre cadastro rápido (nome obrigatório, endereço, telefone).
- Cabeçalho "Mesas" com `TextoRolante`, sem colidir com **+ Nova Mesa**.

### 7.9 Financeiro
📄 `pdv/views/financeiro_view.dart` (tela, não janela)
- Ordem dos containers: **Resumo Operacional do Dia/Contexto** (primeiro, logo abaixo do filtro de período) → período e balanço → **Compras do Período** → **Vendas do Período** (busca, filtros por forma de pagamento, lista de vendas) → trabalhadores.
- **Período**: Hoje, Semana, Mês, Tudo, ou **De / Até** (um dia só, ou intervalo). Botões `<` `>` e calendário. Digitar uma data desmarca o botão ativo; botão `x` limpa.
- **Entradas por forma de pagamento**: inclui **À Prazo** com o valor real.
- **Sugestão de divisão igualitária** entre trabalhadores. Botão **Registrar Pagamento** (`registrar_pagamento_dialog.dart`, com foto de cada trabalhador) registra a ação com a diferença para a sugestão.
- Botões: **Imprimir** (térmica), **DRE Simples** (popup com receita, CMV, lucro bruto, pagamentos, resultado líquido; **Exportar DRE em PDF**) e **Exportar PDF** do financeiro.
- Desktop expandido: duas colunas.

### 7.10 Status da Loja
📄 `pdv/views/status_loja_view.dart`
- Topo (acima do status): **Resumo Operacional do Dia** com Faturamento do Dia, Vendas Hoje, Ticket Médio e Situação do Caixa (Aberto/Fechado + saldo físico).
- **Interruptor Aberta/Fechada** (sincronizado em todos os aparelhos).
- **Lista de Trabalhadores**: foto por CPF, hover, **online/offline** e aparelhos conectados (computador balcão, celulares, IPs e nomes).
- Desktop expandido: duas colunas.

### 7.11 Programar Pedido
📄 `programar_pedido_dialog.dart` · `pedidos_programados_dialog.dart`
- Acesso: ficha do cliente e comandas.
- Itens: **avulso** (preço base) ou **por categoria** (soma preço da categoria e mostra grupos de adicionais com `+`/`−`); variantes **nascem Desativadas** (opção "Desativado" pode ser religada); observações.
- Dois modos: **Contrato / Dias da Semana** (Seg a Dom, com atalhos Dias Úteis, Fim de Semana, Todos os Dias) e **Calendário Visual** mensal com várias datas.
- **Horário**: digitável (`HH:mm`), rodinha do mouse (±1 min), botões `−1m`/`+1m`, e janela **"Digite o Horário"** (atalhos ±5/±10 min, Salvar/Enter).
- Entra sozinho em **Novos** no dia certo, sem duplicar.

### 7.12 Item e Estoque
- **Novo/Editar Item** 📄 `novo_item_dialog.dart` — ordem dos campos: Foto → Nome → Descrição (minimizada) → Tipo (Produto/Serviço) → Preço de Venda → Categorias e Grupos → Variantes → Código de Barras → Unidades (`un`, `g`, `ml`) → Consumo por Venda → **Estoque e Preço de Custo** (saldo, ajuste/inicial, mínimo, **Lançar Movimento Detalhado**, custo unitário da última compra, margem estimada) → Delivery. Largura: ~740 px (2 colunas) no expandido, ~380 px (1 coluna) no compacto.
- **Movimento de Estoque** 📄 `movimento_estoque_dialog.dart` — tipo (Entrada etc.), quantidade e **custo total da compra** (o custo unitário se calcula sozinho, e vice-versa). Seção rápida permite mudar preço de venda, código de barras e **unidade de medida**.
- **Baixa de Estoque** 📄 `baixa_estoque_dialog.dart` — o sistema propõe, o humano confirma.
- **Cancelar Pedido** 📄 `cancelar_pedido_dialog.dart` — motivo obrigatório e opção de devolver ao estoque.
- Outras janelas de apoio: `nova_categoria_dialog.dart`, `novo_grupo_componentes_dialog.dart`, `opcoes_imagem_dialog.dart` ("Procurar nova imagem", "Retirar imagem", "Cancelar"; se o campo está vazio, abre direto o seletor de arquivos), `venda_registrada_dialog.dart` (comanda de venda já feita, com **Quitar Pagamento à Prazo**), `comanda_pedido.dart`, `comanda_pedido_dialog.dart`.

---

## 8. Atalhos de teclado (resumo)
- **F11** tela cheia (fixa, global). **Esc** fecha janelas / sai do Modo Balcão (fixa).
- **F1 a F10 e F12**: configuráveis em "Ajustes do Perfil → Comandos", todas começam desativadas.
- **Enter** no Modo Balcão finaliza venda; no bipador, adiciona item.
- **← →** nos visualizadores de mídia.
- Leitores USB de código de barras funcionam como teclado.

## 9. O que ainda não existe (pastas reservadas)
`features/chat`, `features/timeline`, `features/delivery`, `features/banco`, `features/autogestao`. Mensagens: o botão "Mensagens" existe na Gestão, mas o módulo de chat ainda é futuro. (a confirmar o comportamento atual do botão)
