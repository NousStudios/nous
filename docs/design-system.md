# Sistema de Design, Temas e Mídia

## 1. Tema

- `AppTheme` gerenciado por `ThemeController.currentTheme` (`ValueNotifier<AppTheme>`).
- **Isolamento por CPF:** `ThemeController` salva o tema ativo e a lista de temas por CPF (`carregarTemaDoUsuario(cpf)`). Ao trocar de conta, cores, fontes, tamanhos e cor de exclusão carregam na hora. No logout volta ao padrão da máquina.
- **Cor de exclusão (`theme.dangerColor`)**: padrão `Color(0xFFFF5252)`, configurável em "Personalizar Aparência" (seletor estilo Canva, cores recentes).

## 2. Cores (regras estritas)

- **PROIBIDO** cor fixa genérica (`Colors.white`, `Colors.black`, `Colors.blue` etc.) nos layouts.
- **Permitido:** `Colors.transparent` e `theme.dangerColor` (ações destrutivas, exclusões, quebra de caixa, saldo negativo). Use sempre `theme.dangerColor`, nunca `Colors.redAccent` fixo.
- **Opacidade:** `theme.backgroundColor.withValues(alpha: 0.4)`, `theme.borderColor.withValues(alpha: 0.6)`. Nunca `.withOpacity()`.
- **Texto:** `theme.textColor` para títulos, cabeçalhos e valores de destaque; `theme.secondaryTextColor` para subtítulos, rótulos e descrições.
- Exceção de contexto: verde do troco no Modo Balcão (destaque de alto contraste) e cores de lógica de contraste em `contrast_helper.dart`.

## 3. Componentes padronizados

| Elemento | Padrão |
|---|---|
| **Bloco / Card** | `BoxDecoration(color: theme.backgroundColor.withValues(alpha: 0.4), borderRadius: 12, border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)))` |
| **Diálogos** | Sempre centralizados via `showDialog`. Fundo `theme.cardBackgroundColor`, `borderRadius: 16`, título e mensagem centralizados, largura máx. 500 (ou proporcional no desktop). Com `Flexible` + `SingleChildScrollView`: **sempre** `ConstrainedBox(maxHeight: MediaQuery.sizeOf(ctx).height * 0.90)`. **Nunca Bottom Sheet.** |
| **Ações de exclusão** | Rótulo/ícone em `theme.dangerColor`. Sempre abre `AlertDialog` centralizado de confirmação: "Cancelar" neutro (`theme.secondaryTextColor`) e "Excluir"/"Remover" em `theme.dangerColor`. |
| **Barras com hover** | Itens de lista (membros, fornecedores, clientes, trabalhadores): borda contrastante e fundo `theme.borderColor.withValues(alpha: 0.18)` ao passar o mouse. |
| **Listas vazias** | `EstadoVazioContainer(theme: theme, mensagem: '...')` |
| **Botões de ação** | Em repouso seguem o tema (`theme.buttonColor` ou transparente com borda 1.0), **nunca nascem com visual de hover**. Em hover: fundo translúcido alpha 0.18, borda 1.4 em `textColor`, cursor pointer. |
| **Botões/seletores com seleção** (impressora, filtros, abas da loja, períodos, tipo de movimento, unidades, formas de pagamento) | Mantêm destaque quando selecionados; fundo alpha 0.22 (0.35 em hover), borda 1.6 px em `textColor`, `SystemMouseCursors.click`, fallback para temas escuros. |
| **On/Off (`ThemedSwitch`)** | `activeThumbColor: theme.textColor`, `activeTrackColor: theme.borderColor.withValues(alpha: 0.45)`, `inactiveThumbColor: theme.secondaryTextColor`, `inactiveTrackColor: Colors.transparent`, `trackOutlineColor: theme.borderColor`. |
| **Texto rolante (`TextoRolante`)** | `TextoRolante(texto:, style:, textAlign: TextAlign.start)`. Se o texto excede a largura, desliza da direita para a esquerda com gradiente nas bordas; se cabe, é um `Text` estático sem custo. Usar em nomes de itens, categorias, grupos, clientes, fornecedores, mesas, comandas, pedidos programados, cabeçalhos, ações de auditoria e detalhes de pagamento. |

## 4. Responsividade

- **Celular:** modo compacto obrigatório e exclusivo (`PdvProvider.layoutDesktopAtivo` retorna `false`). "Ajustes do Perfil" mostra só um card informativo.
- **Desktop:** alterna livremente compacto/expandido (`LayoutBuilder` elástico no seletor, para o texto não quebrar na vertical).
- **Telas < 520 px:** barra de ações da loja em `Wrap` 2×2 com rótulos curtos; atalhos F1–F12 em 1 coluna; cabeçalho de Mesas em coluna com `TextoRolante`.
- **Catálogo (`ItemLojaCard`):** altura e largura delimitadas (evita "unbounded height").
- **Prévia da comanda:** largura máx. `(320.0 * theme.fontScale).clamp(320.0, 440.0)`.

## 5. Imagens: continuidade visual estrita

- **Proibido elemento fictício:** se há espaço para avatar/imagem, a imagem **nunca é decorativa**: é persistida, vinculada ao modelo e exibida em todas as telas da entidade.
- **Proibido ícone estático enganoso:** onde há foto ou CPF associado, use `CircleAvatar` com `FileImage`; o ícone nativo só como fallback quando a foto não existe.
- **Sem sobreposições sujas:** nada de lápis/câmera flutuando sobre avatares.
- **`OpcoesImagemDialog`:** se o campo tem imagem, o clique abre "Procurar nova imagem" / "Retirar imagem" / "Cancelar". Se está vazio, abre direto o seletor (`openFile`).
- **Formatos e limite:** até 500 MB via `ImagemService.salvarImagemLocal` (`jpg`, `jpeg`, `png`, `webp`).
- **Recorte (`AjustarImagemDialog`):** `InteractiveViewer`, botões +/−/reset, captura `RenderRepaintBoundary.toImage(pixelRatio: 2.5)` salva em PNG. Usado em `NovoItemDialog` e `GaleriaEstiloContainer`.
- **Exclusão de imagem:** o "X" pede confirmação ("Tem certeza de que deseja retirar esta imagem?").
- **Miniaturas por entidade:** `ItemVendido` guarda a foto do produto (vitrine, carrinho, busca, abas de gestão, comandas). Membros, clientes, fornecedores e trabalhadores mostram a foto real por CPF.

## 6. Mídia, galeria e áudio

- **Cards de anexo** (`GaleriaEstiloContainer`): 156 px de altura × 126 px de largura; prévia por tipo (capa ID3 de álbum com badge sonoro, título e artista; gradiente com selo da extensão; foto em alta qualidade; fundo cinematográfico para vídeo; ícone com selo `PDF`/`DOCX` e tamanho).
- **`VisualizadorGaleriaDialog`:** tela cheia, `InteractiveViewer`, setas flutuantes, teclado ← →, arraste (`PageView`), contador, barra inferior com legenda (`Loja.descricoesAnexos`).
- **`DetalhesMidiaDialog` / `ReprodutorAudioWidget`:** playlist com contador `X / Total`, setas laterais, ← →, `skip_previous_rounded`/`skip_next_rounded`, **autoplay** da próxima faixa (se não estiver em loop).
- **Player de áudio (`PlayerAudioService`):** `audioplayers` (Media Foundation no Windows). Tags ID3v2 por `MetadadosAudioService` (frames `APIC`, título, artista, álbum; busca de capa na pasta como fallback; `RandomAccessFile` sempre fechado em `finally`; separadores de caminho normalizados com `RegExp(r'[\\/]')`).
- **Windows:** `SomService` usa `file.uri.toString()` com `[System.Uri]::new(...)` no PowerShell (colchetes, apóstrofos, acentos).
- **`ReprodutorAudioWidget`:** capa translúcida de fundo, miniatura com selo "TOCANDO", barra de progresso, volume com mute, play/pause, ±10 s, loop, parar. Reutilizável.

## 7. Tipografia (`FontesApp`)

Lista mestra compartilhada entre "Personalizar Aparência" e "Tipografia da Comanda" (11 opções): **Belleza** (identidade do Nous, `assets/fonts/Belleza-Regular.ttf`), **Arial/Helvetica** (melhor para cabeças térmicas 203 DPI), **Courier**, **Roboto**, **Roboto Mono**, **Open Sans**, **Inter**, **Lato**, **Poppins**, **Montserrat**, **Times New Roman**. Seleção por lista expansível com prévia em tempo real. Sem dependência de APIs externas: interface usa a renderização nativa do Windows; PDF usa fontes vetoriais otimizadas.

## 8. Reordenação por pressão

`LongPressDraggable` (`delay: 1 s`, `dragAnchorStrategy: pointerDragAnchorStrategy`) com `DragTarget<int>` e `AnimatedSize` de 250 ms. **Chaves obrigatórias:** `ValueKey('cat_${id}')` e `ValueKey('grp_${id}')`. **Proibido `GlobalKey`** (causa "Duplicate GlobalKey" no overlay do Flutter).
