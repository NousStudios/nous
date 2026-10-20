---
name: sincronizacao-contexto
description: Use at the completion of ANY implementation, refactoring, bugfix, or architectural decision to automatically update MAPA_DO_APP.md, CHANGELOG.md, and docs without touching AGENTS.md.
---

# Sincronização Contínua de Contexto e Documentação

Regra **MANDATÓRIA E AUTOMÁTICA** para todo agente atuando no ecossistema Nous. Execute sempre ao finalizar qualquer ciclo de trabalho, sem esperar solicitação do desenvolvedor.

---

## 1. Roteiro de Atualização (Onde Atualizar)

1. **Mudou tela, container, botão, aba, atalho ou comportamento visível?**
   - Atualize `MAPA_DO_APP.md` na tela correspondente (uma vez só; nunca repita a informação).
2. **Mudou regra de negócio, rede, design ou pipeline de build?**
   - Atualize o arquivo específico em `docs/`:
     - `docs/rede-local.md`: Wi-Fi, autocura, endpoints e WebSockets.
     - `docs/regras-de-negocio-pdv.md`: Vendas, estoque, caixa, mesas e financeiro.
     - `docs/design-system.md`: Cores, componentes visuais e mídias.
     - `docs/build-e-distribuicao.md`: Scripts, instaladores, APK e compilação.
     - `docs/filosofia.md`: Ontologia e política.
3. **Novo ciclo de versão ou entrega finalizada?**
   - Adicione **1 linha por mudança** no topo de `CHANGELOG.md` com a versão e data.
4. **`AGENTS.md` NUNCA deve ser inflado:**
   - Só altere o `AGENTS.md` se surgir uma regra nova inegociável de trabalho ou se uma invariante de sistema mudar. Meta: manter sempre menos de 200 linhas.

---

## 2. Pipeline Automático de Build

Após validar o ciclo com `flutter test` e `flutter analyze`:
1. Incremente a versão no `pubspec.yaml` (ex.: `1.0.12+13`).
2. Execute o compilador com PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "scripts/gerar_instalador.ps1"
   ```
3. O script apaga automaticamente instaladores e APKs antigos da pasta `dist/` e mantém apenas os mais recentes.
