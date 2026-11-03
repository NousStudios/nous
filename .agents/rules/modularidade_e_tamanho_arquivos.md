# Regra de Arquitetura: Modularidade, Tamanho Máximo de Arquivos e Organização

## 1. Limite de Tamanho de Arquivo e Proibição de Monólitos
- **Arquivos não devem se tornar monólitos**: Nenhum arquivo deve ultrapassar 500 a 800 linhas de código. Arquivos com mais de 500 linhas devem ser obrigatoriamente fatiados e modularizados.
- Se uma tela ou funcionalidade começar a crescer, fatie-a imediatamente em componentes especializados antes de adicionar novas funcionalidades.

## 2. Separação Estrita de Responsabilidades
Ao criar ou refatorar telas e features:
- **`views/`**: Responsável apenas pela casca da tela (Scaffold, Layout responsivo desktop/mobile, AppBar e posicionamento geral).
- **`controllers/`**: Toda regra de negócio, gestão de estado (ex.: `ChangeNotifier` ou `ValueNotifier`), fluxos assíncronos de carregamento e envio de mensagens. Não coloque dezenas de `setState` e chamadas a bancos diretamente na UI.
- **`widgets/`**: Componentes reutilizáveis específicos da feature (ex.: painéis, barras de ferramentas, tiles de lista, balões de mensagem, cartões especializados de mídia/áudio/comanda).
- **`dialogs/`**: Modais, popups, bottom sheets e menus de contexto devem ficar em arquivos dedicados na pasta `dialogs/`.
- **`services/` ou `utils/`**: Funções utilitárias repetitivas (como resolução e cache de fotos, normalização de termos e dados) devem ser centralizadas em serviços/helpers únicos.

## 3. Desempenho e Operações Assíncronas
- **Proibido loops com `await` sequencial dentro da UI ou em rotinas de recarregamento reativo**: Evite iterar sobre dezenas de contatos ou mensagens chamando o banco ou rede repetidamente a cada evento.
- **Uso de Caches e Resolução em Lote**: Pré-carregue dados em mapa/conjunto ou utilize métodos em lote (*batch*).
- **Segurança de Ciclo de Vida**: Sempre verifique `mounted` antes de utilizar `BuildContext` após qualquer operação assíncrona (`await`).

## 4. Manutenibilidade e Fluidez
- Não duplique rotinas (ex.: busca de fotos, unificação de contatos). Centralize em métodos e serviços reutilizáveis.
- Garanta código limpo, sem warnings no analyzer (`dart analyze`), com imports estritamente necessários e formatação consistente (`dart format`).
