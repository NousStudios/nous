---
name: padrao-visual
description: Use whenever creating or editing any widget, dialog, or visual component in the Nous project.
---

# Padrão Visual e Sistema de Design do Nous

Diretrizes obrigatórias para criação e edição de widgets, telas, diálogos e componentes visuais no Nous.

---

## 1. AppTheme e ThemeController

- O tema da aplicação é gerenciado por `AppTheme` e exposto globalmente via `ThemeController.currentTheme` (`ValueNotifier<AppTheme>`).
- O acesso ao tema no widget ocorre via escuta do `ValueListenableBuilder(valueListenable: ThemeController.currentTheme, ...)` ou pelo recebimento de `final AppTheme theme` passado via construtor.
- Para estilos de texto, use sempre `theme.getTextStyle(...)` para respeitar a fonte e a escala configuradas pelo usuário.

---

## 2. Regras Estritas de Cores

- **PROIBIDO:** Usar cores fixas genéricas (`Colors.white`, `Colors.black`, `Colors.blue`, etc.) diretamente nos layouts. Nenhuma cor deve ser definida "no braço".
- **EXCEÇÕES PERMITIDAS:**
  - `Colors.transparent`
  - `theme.dangerColor` (exclusiva para ações destrutivas, exclusões, cancelamentos irreversíveis, alertas de quebra e valores de saldo negativo). O usuário pode personalizar essa cor na janela "Personalizar Aparência". Evite usar `Colors.redAccent` fixo.
- **Opacidade Moderna:** Use sempre `theme.backgroundColor.withValues(alpha: 0.4)` ou `theme.borderColor.withValues(alpha: 0.6)`. **Nunca use o método legado `.withOpacity()`**.
- **Tipografia e Cores de Texto:**
  - `theme.textColor`: Títulos, cabeçalhos e valores de destaque.
  - `theme.secondaryTextColor`: Subtítulos, rótulos de campos e descrições.

---

## 3. Componentes Visuais Padronizados

### Tabela de Padrões Obrigatórios

| Elemento | Padrão Obrigatório |
| :--- | :--- |
| **Bloco / Card Padrão** | `BoxDecoration(color: theme.backgroundColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)))` |
| **Títulos de Containers** | **Sempre centralizados** com `Center(child: Text('...', textAlign: TextAlign.center))` ou `Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon, Text]))`. |
| **Diálogos / Popups** | **Sempre centralizados** via `showDialog`. Fundo `theme.cardBackgroundColor`, `borderRadius: 16`, títulos centralizados em `theme.textColor`, mensagens centralizadas e largura máxima de `500`. **Nunca use Bottom Sheets.** |
| **Botões e Ações de Exclusão** | **Padrão Universal:** Botões na tela (como "Excluir Loja", "Excluir Cliente", "Excluir Fornecedor", "Excluir Cadastro" e itens destrutivos de menus popup) exibem o rótulo/ícone em `theme.dangerColor`. Ao serem acionados, **SEMPRE abrem janela de confirmação** (`AlertDialog` centralizado) com botão "Cancelar" neutro (`theme.secondaryTextColor`) e botão de confirmação ("Excluir" / "Remover") destacado em `theme.dangerColor`. |
| **Barras com Hover** | Todo item de lista (membros, fornecedores, clientes, trabalhadores, ações de auditoria) deve usar hover com borda contrastante e leve fundo translúcido `theme.borderColor.withValues(alpha: 0.18)` ao passar o cursor e `SystemMouseCursors.click`. |
| **Listas Vazias** | Use sempre `EstadoVazioContainer(theme: theme, mensagem: '...')`. |
| **Botões de Ação** | Ativos com `theme.buttonColor` (com fallback `theme.borderColor.withValues(alpha: 0.25)` quando `buttonColor == Colors.transparent`) e texto em `theme.buttonTextColor`. Secundários com `OutlinedButton` arredondado com hover dinâmico via `WidgetStateProperty.resolveWith(...)`. |
| **Botões e Seletores com Hover Persistente** | Botões de opção/toggle (impressora, filtros de relatórios, abas da loja, períodos no financeiro, tipo de estoque, unidades de medida e formas de pagamento) **mantêm destaque visual ativo quando selecionados** e respondem dinamicamente ao mouse em hover: fundo translúcido `alpha: 0.22` (ou `0.35` em hover), borda contrastante `1.6px` em `textColor`, `SystemMouseCursors.click` e fallback para temas escuros. |
| **Campos de Formulário** | Use `ThemedTextField(theme: theme, controller: ..., label: ...)` para garantir inputs coerentes com bordas arredondadas ou sublinhado padronizado. |

---

## 4. Detalhamento de Implementação no Código Real

### 4.1 Diálogos Centrais (`showDialog`)
Diálogos devem limitar sua largura máxima a 500 com `ConstrainedBox` e borda suave no tema:
```dart
showDialog<void>(
  context: context,
  builder: (dialogContext) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: meuConteudoDoDialog,
      ),
    );
  },
);
```

### 4.2 Barras de Lista com Hover
Itens clicáveis em listas utilizam `MouseRegion` para alternar o estado de hover, elevando o contraste da borda para `theme.textColor` e o fundo para alpha 0.18:
```dart
MouseRegion(
  onEnter: (_) => setState(() => _hover = true),
  onExit: (_) => setState(() => _hover = false),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: _hover
          ? theme.borderColor.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: _hover ? theme.textColor : theme.borderColor,
      ),
    ),
    child: linhaDeConteudo,
  ),
)
```

### 4.3 Container de Lista Vazia (`EstadoVazioContainer`)
Localizado em `lib/src/features/pdv/views/widgets/estado_vazio_container.dart`:
```dart
EstadoVazioContainer(
  theme: theme,
  mensagem: 'Nenhum registro encontrado',
)
```

### 4.4 Campos de Entrada (`ThemedTextField`)
Localizado em `lib/src/core/widgets/themed_text_field.dart`:
- Evite criar `TextFormField` crus com decorações manuais ad-hoc.
- Suporta `obrigatorio: true`, `linhas`, `tipoDeTeclado`, `formatadores` e variante `sublinhado: true`.
```dart
ThemedTextField(
  theme: theme,
  controller: _meuController,
  label: 'Nome do Titular',
  obrigatorio: true,
)
```

### 4.5 Linhas de Comprovantes, Comandas e Tickets Térmicos
Em linhas que exibem itens e valores (tanto na interface `impressora_dialog.dart`, `comanda_pedido.dart`, `nova_venda_dialog.dart`, quanto na geração real de PDFs térmicos de 58mm/80mm em `ImpressaoService.linhaDupla`):
- **Espaçamento de Respiro Obrigatório (`8px` / `pw.SizedBox(width: 8)`):** Entre a coluna esquerda e a direita deve haver SEMPRE um espaçador mínimo garantido para impedir que o final de nomes longos cole diretamente no valor monetário (ex.: prevenindo `deR$ 25,00`).
- **Valores Monetários à Direita (`R$ ...`):** NUNCA devem quebrar verticalmente letra por letra nem ser comprimidos. Devem manter largura intrínseca e `softWrap: false` / `pw.Text(direita, textAlign: pw.TextAlign.right)`.
- **Nomes de Produtos e Descrições à Esquerda:** Devem ser encapsulados em `Expanded(child: Text(..., softWrap: true))` para quebrar em 2 ou mais linhas caso o nome seja longo ou a fonte esteja no tamanho máximo.
- **Rótulos Fixos com Textos Longos à Direita (ex.: Pagamento / Forma / Operador):** A esquerda mantém largura intrínseca (`Text('$rotulo:')`) para **nunca sofrer compressão lateral nem quebra vertical de sílabas** (como em `Pa / ga / m / en / to`), e a direita recebe `Expanded(child: Text(valor, softWrap: true, textAlign: TextAlign.right))`, fluindo com elegância.

### 4.6 Adaptabilidade à Escala de Fontes (`theme.fontScale`)
O usuário pode alterar o tamanho da fonte para o máximo nas Configurações:
- Containers de cupom e listas de produtos não devem ter larguras rígidas que estourem a tela; utilize limites elásticos: `(larguraBase * theme.fontScale).clamp(min, max)`.
- Cards de catálogo (ex.: `item_loja_card.dart`) devem calcular alturas e larguras a partir de `theme.fontScale` para evitar sobreposição de preços e nomes.

### 4.7 Notificações e Itens Arrastáveis (`Dismissible`)
Para listas onde o usuário pode descartar itens por gesto horizontal (como na janela de notificações):
- Use `Dismissible(key: ValueKey(id), direction: DismissDirection.horizontal, ...)`
- `background` e `secondaryBackground` com `color: Colors.redAccent.withValues(alpha: 0.2)`, `borderRadius: BorderRadius.circular(10)` e ícone discreto (`Icons.visibility_off_outlined` ou similar).
- Dispensas de sessão não devem apagar dados do banco; use um `Set<String>` em memória no Provider para que pendências reais reapareçam ao reabrir o app caso o problema subjacente não tenha sido resolvido.

### 4.8 Modais de Confirmação Segura com Prévia de Saldo
Para operações financeiras críticas (como quitação ou abate de dívidas a prazo em `ClientesDialog`):
- Abra sempre `showDialog` com `AlertDialog` centralizado (`maxWidth: 420` a `500`).
- Apresente um container interno com borda e fundo translúcido `theme.backgroundColor.withValues(alpha: 0.4)` detalhando: Valor da Ação, Saldo Atual e Saldo Restante calculado em tempo real.
- Botão "Cancelar" com `theme.secondaryTextColor` e botão afirmativo de confirmação destacado com `theme.buttonColor` e `theme.buttonTextColor`.

### 4.9 Diálogos com Rolagem Vertical e Prevenção de Unbounded Constraints
Ao criar diálogos contendo `Flexible` + `SingleChildScrollView`:
- **`ConstrainedBox` com `maxHeight` Obrigatório:** O `Dialog` deve sempre receber `ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(ctx).height * 0.90))` para evitar a exceção fatal `RenderFlex children have non-zero flex but incoming height constraints are unbounded`.
- **Cuidado com `Expanded` em Adaptabilidade (`LayoutBuilder`):** Em widgets que alternam entre `Row` (desktop/telas largas) e `Column` (celular/telas estreitas), NUNCA insira `Expanded` dentro da ramificação `Column`, pois colunas dentro de scrollviews não possuem altura finita. Deixe o `Expanded` estritamente para o `Row`.

### 4.10 TextoRolante (Efeito Marquee da Direita para a Esquerda)
Sempre que um nome ou texto puder ultrapassar a largura disponível no container (nomes de produtos, categorias, grupos de componentes, clientes, fornecedores, mesas, comandas, itens programados e títulos de cabeçalhos/diálogos), utilize obrigatoriamente `TextoRolante(texto: ..., textAlign: ..., style: ...)`:
- O widget mede a largura intrínseca do texto contra o espaço disponível (`LayoutBuilder`).
- Se couber perfeitamente, exibe como texto estático alinhado.
- Se for maior que a largura, aplica máscara de gradiente nas bordas e desliza suavemente da direita para a esquerda com pausa no início e no final, permitindo ler 100% da informação sem truncamentos secos com reticências e sem quebras verticais.

### 4.11 Responsividade Mobile vs. Desktop e Modo Compacto
- **Dispositivos Móveis (Android e iOS):**
  - O modo padrão é SEMPRE **Compacto** (`layoutDesktopAtivo` retorna `false`).
  - **Blindagem contra Backups Desktop:** Ao restaurar backups criados no computador (onde `loja.layoutExpandido == true`), a aplicação NUNCA deve ler `loja.layoutExpandido` de forma crua. Deve-se SEMPRE utilizar `loja.layoutExpandidoEfetivo` ou `pdv.layoutDesktopAtivo(lojaId, larguraTela)`. Isso impede que os botões de gestão da loja no topo sumam achando que existe uma barra lateral desktop.
  - Na tela de ajustes ("Modo de Visualização e Layout do PDV"), o usuário **NÃO PODE** alterar para o modo desktop expandido. A interface apresenta um card explicativo indicando que o modo compacto é fixo e exclusivo para telas verticais com toque.
  - As teclas de atalho (F1–F12) se adaptam para 1 coluna contínua quando a largura for inferior a 520px, com `TextoRolante` no F11, eliminando esmagamentos de texto.
  - A barra de ações da loja (`_barraDeAcoesLoja`) utiliza `Wrap` inteligente com rótulos compactos ("Novo Grupo") em telas estreitas, mantendo todos os botões visíveis sem rolagem cortada.
  - O cabeçalho de Mesas e Comandas (`MesasContainer`) isola o título em coluna flexível com `TextoRolante`, evitando qualquer sobreposição com o botão "+ Nova Mesa".
- **Computador (Desktop):**
  - O usuário possui total autonomia para alternar entre a versão compacta e a experiência desktop expandida com barra lateral e atalhos rápidos.
  - O container de alternância é construído com `LayoutBuilder` responsivo, prevenindo esmagamentos de texto se a janela do sistema for redimensionada para tamanhos estreitos.




