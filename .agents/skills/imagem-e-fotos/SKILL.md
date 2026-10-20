---
name: imagem-e-fotos
description: Use whenever adding, displaying, storing, or syncing an image, avatar, or thumbnail in the Nous project.
---

# Imagens, Avatares e Continuidade Visual (Cheatsheet)

Diretrizes obrigatórias e código rápido para manipulação de mídias no Nous. Detalhes de sincronização e rede em `docs/rede-local.md`.

---

## 1. Princípios Inegociáveis

1. **Sem Imagens Decorativas:** Se há espaço para imagem (logo, produto, membro, cliente, fornecedor), ela **sempre** é persistida, vinculada ao modelo e exibida em todas as telas daquela entidade.
2. **Uso Mandatório de `resolverCaminhoExistente`:**
   - **NUNCA** faça `File(caminho).existsSync()` diretamente sem passar por `ImagemService.resolverCaminhoExistente(caminho)`.
   - Caminhos remotos (Windows vs. Android) ou pastas legadas só são localizados via `resolverCaminhoExistente`.
3. **Sem Sobreposições Sujas:** Não coloque ícones flutuantes (lápis/câmera) sobre o avatar.

---

## 2. Como Renderizar Avatares e Fotos com Segurança

```dart
final caminhoResolvido = ImagemService.resolverCaminhoExistente(foto);

if (caminhoResolvido != null) {
  return CircleAvatar(
    radius: 20,
    backgroundImage: FileImage(File(caminhoResolvido)),
  );
} else {
  return CircleAvatar(
    radius: 20,
    backgroundColor: theme.borderColor.withValues(alpha: 0.25),
    child: Text(
      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
      style: theme.getTextStyle(fontWeight: FontWeight.bold),
    ),
  );
}
```

---

## 3. Salvar e Sincronizar Imagens

1. **Seleção e Salvamento Local:**
   ```dart
   final caminhoLocal = await ImagemService.salvarImagemLocal(caminhoOrigem);
   ```
2. **Sincronização em Rede Wi-Fi:**
   - Ao receber lojas via rede (`sincronizarPerfisLojasComServidor` ou `loja_atualizada`), invoque obrigatoriamente `_sincronizarImagensRemotas(loja)` para que as mídias sejam baixadas e salvas no diretório local do dispositivo antes de gravar no SQLite.
   - Em `LojasService.consolidarLojaComImagensLocais`, se a loja recebida trouxer caminhos quebrados ou de outro sistema operacional, preserve 100% as fotos válidas que já existem no cofre local.
