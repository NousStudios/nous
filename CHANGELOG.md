# CHANGELOG

Uma linha por mudança, da mais recente para a mais antiga. O agente deve acrescentar aqui o que fez em cada ciclo (versão do `pubspec.yaml` + o que mudou). Este arquivo guarda **histórico**; a descrição atual do app fica em `MAPA_DO_APP.md`.

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
