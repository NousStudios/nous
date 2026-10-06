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
