# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

## v1.0.16 (build 17) — 20/10/2026

- Eliminação de espaçamentos e paddings invisíveis entre os botões de ação nas barras de Categorias e Grupos de Componentes, liberando cerca de 75px de largura extra para visualização dos nomes no modo celular.

## v1.0.15 (build 16) — 20/10/2026

- Padronização e compactação inicial das barras de "Categorias" e "Grupos de Componentes" na tela "Loja do Perfil".

## v1.0.14 (build 15) — 19/10/2026

- Reprodutor de áudio responsivo: layout adaptativo para celular com botões de reprodução centralizados e botão Play/Pause sempre visível em destaque.
- Aplicação de `TextoRolante` no título e subtítulo de áudios no player e no cabeçalho do modal de mídias (`DetalhesMidiaDialog`), eliminando truncamento de texto.
- Ocultação do container "Modo de Visualização e Layout do PDV" na aba "Ajustes do Perfil" no celular quando não houver teclado físico conectado.
- Aplicação de `TextoRolante` com restrição de largura no identificador de dispositivos conectados na "Lista de Trabalhadores" ("Status da Loja"), impedindo estouro de container.

## v1.0.13 (build 14) — 19/10/2026

- Correção da reprodução de áudios e músicas no celular conectado ao balcão (resolução de caminhos em subpastas de anexos, download assíncrono via streaming no Android e pareamento de áudio ativo pelo nome do arquivo).
- Nova rota de rede local `POST /api/upload_anexo` e correção de `/api/audio` com `resolverCaminhoExistente` no balcão.
- Sincronização bidirecional completa da loja: inclusão de upload de fotos de clientes, fornecedores, galeria e anexos ao enviar alterações do celular para o balcão.
- Blindagem contra ressurreição de dados excluídos via `manterItensAusentes: false` em `consolidarLojaComImagensLocais`.
- Atualização em tempo real de anexos (músicas, galeria, vídeos) e campos cadastrais da loja em `DadosPerfilView` ao receber atualizações da rede.

## v1.0.12 (build 13) — 19/10/2026

- Correção do loop infinito de alternância entre layout compacto e desktop no computador (eliminação de eco WebSocket e blindagem de preferências locais).
- Desvinculação definitiva ao sair de lojas participadas com exclusão no SQLite local, endpoint `POST /api/loja/sair` e expurgo de referências órfãs no balcão.
- Download automático e resolução de imagens/logo ao sincronizar perfis de lojas participantes no celular (`sincronizarPerfisLojasComServidor`).
- Resolução dinâmica do cargo real do usuário em "Identidade do Usuário" (exibindo cargos personalizados da loja ou papéis formais).
- Inclusão de nome e CNPJ da loja na comanda de pedidos programados nos Relatórios e fallback em `ComandaPedidoDialog`.
- Compilação automatizada com limpeza de instaladores e APKs antigos em `dist/` a cada ciclo de entrega.

## v1.0.11 (build 12) — estado na data da reorganização da documentação

- Isolamento contextual de notificações por loja; botão "Limpar todas as notificações".
- Container "Comandos" oculto no modo compacto do celular; reabilitado no Windows ou com teclado físico.
- Malha de autocura mútua na rede Wi-Fi (fotos de identidade e catálogos), fusão pan-dispositivo de perfis por CPF.
- Distribuição de atualizações e APK pelo balcão via Wi-Fi, com instalação in-app no Android.
- Modo desktop expandido com barra lateral e duas colunas; Modo Balcão; mesas e comandas; pedidos programados; DRE; Kardex; sons e alertas; cargos e permissões estilo Discord; reordenação por pressão.

> Histórico anterior a esta versão ficou registrado apenas no antigo `AGENTS.md` e não foi detalhado por versão.
