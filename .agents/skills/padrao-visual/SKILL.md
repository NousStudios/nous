---
name: padrao-visual
description: Use whenever creating or editing any widget, dialog, or visual component in the Nous project.
---

# Padrão Visual e Componentes (Cheatsheet)

Cheatsheet de widgets, cores e snippets prontos para uso. Teoria completa em `docs/design-system.md`.

---

## 1. Cores e Textos

- **Proibido cor fixa:** Nunca use `Colors.white`, `Colors.black`, `Colors.blue`.
- **Cores permitidas:** `Colors.transparent` e `theme.dangerColor` (ações destrutivas / saldo negativo).
- **Opacidade:** `theme.backgroundColor.withValues(alpha: 0.4)`. Nunca `.withOpacity()`.
- **Texto:** `theme.textColor` (títulos, valores) e `theme.secondaryTextColor` (rótulos, descrições).

---

## 2. Snippets Rápidos dos Componentes Principais

### Bloco / Card Padrão
```dart
BoxDecoration(
  color: theme.backgroundColor.withValues(alpha: 0.4),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
)
```

### Diálogo Centralizado com Scroll
Nunca use Bottom Sheet. Use sempre `showDialog` com altura máxima delimitada a 90%:
```dart
showDialog<void>(
  context: context,
  builder: (dialogCtx) => Dialog(
    backgroundColor: theme.cardBackgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.90,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [...],
          ),
        ),
      ),
    ),
  ),
);
```

### Confirmação Destrutiva (Exclusão / Cancelamento)
Rótulo em `theme.dangerColor` + `AlertDialog` com confirmação:
```dart
final confirmou = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: theme.cardBackgroundColor,
    title: Text('Confirmar exclusão', style: theme.getTextStyle(color: theme.textColor)),
    content: Text('Esta ação não pode ser desfeita.', style: theme.getTextStyle(color: theme.secondaryTextColor)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
      ),
      TextButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text('Excluir', style: theme.getTextStyle(color: theme.dangerColor, fontWeight: FontWeight.bold)),
      ),
    ],
  ),
);
```

### Componentes Prontos Obrigatórios
- **Lista Vazia:** `EstadoVazioContainer(theme: theme, mensagem: 'Nenhum registro encontrado.')`
- **Texto Longo / Marquee:** `TextoRolante(texto: item.nome, style: ..., textAlign: TextAlign.start)`
- **Interruptor:** `ThemedSwitch(value: ativo, onChanged: (v) => ...)`
- **Itens Reordenáveis:** Sempre `LongPressDraggable` com `ValueKey('id_${item.id}')`, **nunca `GlobalKey`**.
