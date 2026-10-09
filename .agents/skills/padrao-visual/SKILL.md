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
  - `Colors.redAccent` (exclusiva para ações destrutivas, exclusões, alertas de quebra e valores de saldo negativo).
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
| **Diálogos / Popups** | **Sempre centralizados** via `showDialog`. Fundo `theme.cardBackgroundColor`, `borderRadius: 16` e largura máxima de `500`. **Nunca use Bottom Sheets.** |
| **Barras com Hover** | Todo item de lista (membros, fornecedores, clientes, trabalhadores) deve usar hover com borda contrastante e leve fundo translúcido `theme.borderColor.withValues(alpha: 0.18)` ao passar o cursor. |
| **Listas Vazias** | Use sempre `EstadoVazioContainer(theme: theme, mensagem: '...')`. |
| **Botões de Ação** | Ativos com `theme.buttonColor` e texto em `theme.buttonTextColor`. Secundários com `OutlinedButton` arredondado. |
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
Em linhas que exibem itens e valores (como em `impressora_dialog.dart`, `comanda_pedido.dart`, `nova_venda_dialog.dart`):
- **Valores Monetários à Direita (`R$ ...`):** NUNCA devem quebrar verticalmente letra por letra nem ser comprimidos. Devem manter largura intrínseca e `softWrap: false`.
- **Nomes de Produtos e Descrições à Esquerda:** Devem ser encapsulados em `Expanded(child: Text(..., softWrap: true))` para quebrar em 2 ou mais linhas caso o nome seja longo ou a fonte esteja no tamanho máximo.
- **Rótulos Fixos com Textos Longos à Direita (ex.: Pagamento / Forma):** A esquerda mantém largura intrínseca (`Text(rotulo)`) e a direita recebe `Expanded(child: Text(valor, softWrap: true, textAlign: TextAlign.right))`.

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



