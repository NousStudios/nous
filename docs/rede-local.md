# Rede Local, Sincronização e Malha de Autocura

Princípio: **toda a aplicação conversa como um só organismo.** Qualquer informação ou foto que falte em um aparelho e exista em outro dispositivo da mesma rede deve ser atualizada nos demais, de forma orgânica, em qualquer direção, sem importar quem é servidor ou cliente.

Arquivos principais: `pdv/services/rede_local/servidor_rede_local.dart`, `pdv/services/rede_local/cliente_rede_local.dart`, `auth/providers/auth_provider.dart`, `auth/services/contas_nous_service.dart`, `pdv/services/imagem_service.dart`, `pdv/services/lojas_service.dart`, `pdv/providers/pdv_provider.dart`. Interface: `SincronizacaoRedeDialog` (ver `MAPA_DO_APP.md`, 4.1).

## 1. Arquitetura

- Motor nativo do Dart (`dart:io`: `HttpServer`, `WebSocket`, `RawDatagramSocket`). Sem internet, sem nuvem.
- **Servidor balcão** (`ServidorRedeLocal`): computador do caixa, porta **8080**. Anuncia presença por **broadcast UDP a cada 3 s na porta 45454** (`nous_loja_anuncio`).
- **Terminal móvel** (`ClienteRedeLocal`): escuta a porta 45454, lista balcões e conecta (ou conexão manual por IP/porta). Reconexão automática e heartbeat ping/pong.
- **Auto-conexão proibida:** o computador que hospeda o servidor não pode se conectar a si mesmo como terminal móvel (evita tempestade de ecos e loops de WebSocket).
- **Presença do host:** ao iniciar o servidor, a própria máquina aparece na lista de pareados (`Icons.desktop_windows_rounded`, `Platform.localHostname`).
- **Identificação:** cada terminal envia `nomeDispositivo`, `cpf` ativo e `nomeUsuario`.
- **Android:** `AndroidManifest.xml` com `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` e `usesCleartextTraffic="true"`.

## 2. Endpoints REST e WebSocket

| Endpoint | Para quê |
|---|---|
| `GET /api/status` | Estado do servidor |
| `GET /api/loja?cpf=...` | Snapshot da loja; autoriza e auto-associa o membro |
| `POST /api/loja/atualizar` | Envio de qualquer alteração da loja feita no terminal |
| `POST /api/loja/sair` | Notificação imediata de saída voluntária de membro da loja |
| `POST /api/pedido` | Criação ou atualização de pedidos (se o pedido já existe, atualiza status, valores e notas) |
| `POST /api/movimento_estoque` | Movimento de estoque |
| `POST /api/mesa` | Mesas e comandas |
| `GET /api/imagem?caminho=...` | Baixar foto/mídia |
| `POST /api/upload_imagem` | Subir bytes de imagem para o servidor |
| `GET /api/audio?caminho=...` | Streaming de áudio com `Accept-Ranges: bytes` |
| `GET /api/usuario?cpf=...` | Ficha do usuário (foto sanitizada se o arquivo físico não existir) |
| `POST /api/usuario` | Atualizar ficha do usuário |
| `POST /api/sincronizar_perfis_usuario` | Fusão pan-dispositivo de perfis/lojas do mesmo CPF |
| `GET /api/versao` | Versão e build disponíveis |
| `GET /api/download_apk` | APK da versão atual |
| `WS /api/ws` | Canal em tempo real |

Mensagens WebSocket:
- `dados_iniciais`: snapshot de handshake contendo loja, pedidos, contatos e lacunas de imagens ausentes.
- `loja_atualizada`: catálogo, membros, turnos, configurações.
- `usuario_atualizado`: ficha do usuário sincronizada.
- `pedido_adicionado` e `pedido_atualizado`: propagação imediata de novos pedidos e mudanças de status (Novo → Aceito → Concluído/Cancelado), quitado, valores ou cancelamento.
- `mensagem_chat`: troca de mensagens em tempo real entre atendentes e clientes com foto resolvida do remetente e autocura mútua.

## 3. Autorização de terminais

No primeiro `GET /api/loja` de um terminal novo, o servidor mostra janela modal com alerta sonoro (`_solicitarAutorizacaoTerminal`): nome do aparelho, nome do usuário, CPF e IP. **Autorizar** ou **Recusar**. Recusa ou timeout de 30 s → HTTP 403.

## 4. O que sincroniza em tempo real (bidirecional)

- **Pedidos e comutação de status:** qualquer alteração em `DadosPerfilView` (aceitar pedido, cancelar, alterar status, observação) emite imediatamente `pedido_atualizado` via WebSocket e REST (`/api/pedido`). O servidor atualiza SQLite e retransmite aos demais nós. A UI compara profundamente id, status, quitado, valor pago e notas (`_sincronizarComLojaAtual`), garantindo atualização visual instantânea das abas (Novos, Aceitos, etc.) sem recarregar a tela.
- **Pedidos programados sem duplicação:** a geração de pedidos programados do dia usa IDs determinísticos (`prog_${id}_${ano}_${mes}_${dia}`) e só ocorre no nó servidor balcão (`!ClienteRedeLocal().estaConectado.value`). Pedidos já aceitos/gerados não são duplicados nem reabertos em novos terminais que se conectem à rede.
- **Mensageria com fotos e contatos unificados:** remetentes transmitem mensagens com foto de perfil anexada e autocura prévia de upload de imagem. A lista de conversas unifica o histórico existente e todos os membros e clientes cadastrados na loja, pesquisáveis por nome, cargo ou CPF.
- Pedidos, estoque, mesas e comandas (abertura, itens, transferências, fechamento).
- Toda a loja via `POST /api/loja/atualizar`: status Aberta/Fechada, membros (inclusive exclusão), papéis, cargos, permissões, produtos, categorias, grupos, clientes, fornecedores, turnos de caixa, pagamentos de funcionários, músicas, galeria, anexos e dados cadastrais. O servidor consolida **sem descartar campos**, atualiza SQLite e interface, e retransmite `loja_atualizada` aos demais.
- Papéis e cargos: qualquer alteração no balcão chega a todos os terminais na hora; `StatusLojaView` e `DadosPerfilView` re-renderizam sem reiniciar.
- Status **Aberta/Fechada** (`Loja.aberta`, `PdvProvider.alternarLojaAberta`).
- Presenças (online/offline, aparelhos, IPs) em `StatusLojaView`.

**Sincronização leve:** `loja_atualizada` atualiza memória e persistência via `adicionarOuAtualizarLoja`, **sem** chamar `entrarComCpf` (evita rebuild total). `entrarComCpf` só roda na primeira vinculação da referência (`!jaTem`).

## 5. Identidade e perfis por CPF (pan-dispositivo)

- A ficha `UsuarioNous` é consolidada em `ContasNousService` a partir de qualquer interação (cadastro de cliente/fornecedor, membro de loja, handshake Wi-Fi).
- Login/cadastro recupera dados prévios (`AuthProvider.buscarConta()`, `AssociarCpfView`). Aparelho reinstalado consulta o balcão (`GET /api/usuario?cpf=...`) e faz auto-login.
- **Fusão de perfis** (`POST /api/sincronizar_perfis_usuario`, `_mesclarUsuarios`): quando dois aparelhos do mesmo CPF se conectam, harmonizam lojas, `referencias_loja`, snapshots `Loja` (`LojasService.salvarLojaIndividual`) e toda a ficha (filiação, tipo sanguíneo, local de nascimento, e-mails), sem perda. Na sincronização de perfis (`sincronizarPerfisLojasComServidor`), o cliente móvel executa `_sincronizarImagensRemotas` para baixar fisicamente a logo e mídias de cada loja recebida. A tela "Meus Perfis" e a janela "Identidade do Usuário" mantêm **100% de paridade** entre aparelhos.
- **Saída de loja e expurgo de órfãs:** ao sair voluntariamente de uma loja participada, o cliente apaga o snapshot local do SQLite, notifica o balcão via `POST /api/loja/sair` e o balcão remove o vínculo do cofre da loja e expurga referências órfãs, garantindo que a loja não retorne à lista de perfis.
- **Aprovação mandatória com seletor Cliente vs Membro:** ao receber nova solicitação remota em `GET /api/loja`, o balcão dispara som de alerta e exibe diálogo interativo com as opções: (1) **Cliente** (cadastra o usuário em `loja.clientesLoja`, sem adicioná-lo à equipe de membros, preparando a base para auto-atendimento de pedidos sem garçom) ou (2) **Novo Membro da Loja** (associa o usuário como membro `PapelMembro.funcionario` em `loja.membros`). Se recusado ou atingido timeout de 30s, a requisição é rejeitada com 403.
- **Desduplicação:** o mesmo CPF em vários aparelhos é reconhecido; referências redundantes à loja do próprio dono são purgadas.
- Alterações da ficha (apelido, foto, dados pessoais, e-mails) propagam por `ClienteRedeLocal.enviarUsuario` / `POST /api/usuario`. Na inspeção de membros (`_buscarContaPorCpf` em `DadosPerfilView`), a ficha do balcão tem prioridade e enriquece os dados.

## 6. Malha de autocura mútua (self-healing mesh)

1. **Mapeamento de lacunas (servidor):** em `GET /api/loja` e `dados_iniciais`, o servidor inspeciona o próprio disco e envia `imagensAusentes` (logo, produtos, categorias, clientes, fornecedores com arquivo inexistente ou vazio) e `fotosUsuariosAusentes` (CPFs sem foto física no host).
2. **Validação física no host:** `GET /api/usuario` verifica o arquivo real (`ImagemService.resolverCaminhoExistente`); se não existir, responde `foto: ''` (nunca caminhos fantasmas de outra plataforma).
3. **Cura ativa pelo cliente:** compara com seu cofre e cache (`_obterFotoLocalValidaPorCpf`). Se tem em disco o que o servidor reportou faltar, sobe os bytes por `POST /api/upload_imagem` e despacha `POST /api/usuario` ou `POST /api/loja/atualizar`. Na conexão também roda `_reconciliarTodasContasLocaisComServidor()` e `sincronizarIdentidadeUsuario()` (vale para qualquer conta do aparelho, ex.: o celular do filho que tem a foto da mãe).
4. **Consolidação e malha:** o servidor grava o arquivo, atualiza SQLite e transmite `usuario_atualizado` / `loja_atualizada` a todos.
5. **Recarga nos nós:** quem recebe `usuario_atualizado` baixa o binário (`baixarImagemRemota`), grava no SQLite e recarrega a interface (`recarregarConta()`).
6. **Cache de uploads:** `_mapaUploadsRealizados[caminhoServidor] = caminhoLocal` evita tráfego repetido.
7. **Simetria:** se o computador não tem imagens e o celular tem, o computador se cura; se o celular não tem e o computador tem, o celular se cura.
8. Todas as janelas de perfil (`FichaUsuarioDialog`, `CustomAppBar`, `ContasUsuarioView`) resolvem foto com `ImagemService.resolverCaminhoExistente`, imune a caminhos legados ou de outra plataforma.

## 7. Imagens e áudio

- **Download soberano:** o celular baixa a mídia ausente (`GET /api/imagem` e `GET /api/audio`) para o armazenamento interno (`ImagemService.obterDiretorioBase()`) e reescreve os caminhos no SQLite local, funcionando offline depois. O endpoint `/api/audio` resolve tanto arquivos de música quanto anexos de áudio via `ImagemService.resolverCaminhoExistente`.
- **Upload de anexos (`POST /api/upload_anexo`):** o celular transmite binários de músicas, áudios e arquivos salvos localmente para as pastas equivalentes no servidor do balcão (`anexos/<subpasta>`).
- **Cache determinístico:** arquivo nomeado `remota_${caminhoLimpo.hashCode.abs()}.$ext`; se já existe íntegro, resolve instantaneamente (sem requisições nem escritas repetidas). Áudio: `${dirBase}/audios/remoto_audio_${hash}.mp3`.
- **Gravação atômica:** leitura do stream agregada ou pipe protegido (evita arquivos corrompidos de 0 bytes).
- **Blindagem contra sobrescrita (`LojasService.consolidarLojaComImagensLocais`):** toda atualização de loja passa por ela. Se a loja remota traz caminhos inexistentes localmente mas o cofre local tem fotos válidas, as locais são preservadas. Quando a atualização vem intencionalmente do usuário ou terminal móvel (`manterItensAusentes: false`), itens, categorias e registros excluídos não são ressuscitados indevidamente.
- **Autocura na inicialização (`LojasService.autocuraImagensDeLojas`, em `main.dart`):** recupera caminhos inválidos a partir dos arquivos reais e de `Nous/backups/*.json`. Também `ImagemService.unificarDiretoriosImagens()` consolida pastas legadas.
- **Fotos e Mídias no Chat (`ChatService` & `ClienteRedeLocal`):** ao enviar uma imagem em uma conversa, os bytes binários são codificados em Base64 no despacho do WebSocket/REST para gravação física imediata (`salvarBytesImagemLocal`) na pasta de imagens do destinatário. Se uma mensagem recebida ou recuperada no histórico apontar para uma foto não encontrada localmente, a interface aciona `ClienteRedeLocal.baixarImagemRemota` sob demanda via `/api/imagem`, atualizando o caminho da mensagem para a cópia física em cache e exibindo a miniatura real sem depender do disco do servidor.
- **Áudio:** `PlayerAudioService` resolve o caminho localmente em cache de subpastas ou baixa sob demanda via `ClienteRedeLocal.baixarAudioRemoto` antes de iniciar a reprodução. O reprodutor compara nomes de arquivos (`ehMesmoAudio`) para parear o arquivo remoto ao cache local no Android.

## 8. Proteções

- `aplicandoAtualizacaoRemota`: impede retransmissão circular de mensagens recebidas do balcão.
- **Blindagem de preferências de layout desktop:** `consolidarLojaComImagensLocais` preserva `layoutExpandido` e `tipoLayoutMaior` da máquina local, evitando loops de alternância de layout induzidos por snapshots vindos de dispositivos móveis.
- **Eliminação de ecos reflexivos:** o endpoint `/api/sincronizar_perfis_usuario` não retransmite eventos de WebSocket desnecessários que geravam ping-pong contínuo de sincronização entre balcão e terminais.
- **Debounce de 150 ms** nas ações do usuário; eventos críticos (ex.: exclusão de membro) vão imediatamente.
- Timer de pedidos programados roda **só no balcão** (servidor).
- Descoberta UDP: fechar o socket (`pararDescoberta()`) ao terminar, para poupar bateria e threads no Android.

## 9. Atualização do app pela rede

Ver `docs/build-e-distribuicao.md`, seção "Atualização por Wi-Fi".
