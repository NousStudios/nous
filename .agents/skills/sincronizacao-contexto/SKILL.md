---
name: sincronizacao-contexto
description: Use at the completion of ANY implementation, refactoring, bugfix, or architectural decision to automatically update README.md, AGENTS.md, and relevant skill files without waiting for user requests.
---

# Sincronização Contínua de Contexto e Documentação

Esta regra é **MANDATÓRIA E INEGOCIÁVEL** para todo agente de código atuando no ecossistema Nous.

---

## 1. Objetivo Fundamental

O desenvolvedor é iniciante, autodidata e não deve gastar tempo nem mensagens solicitando que a IA atualize a documentação do projeto.
A cada prompt, o contexto repassado para a IA deve ser **sinteticamente superior, preciso e atualizado**, evitando que o agente:
1. Cometa os mesmos erros que já foram solucionados anteriormente.
2. Esqueça funcionalidades, modelos, atalhos e padrões já implementados.
3. Proponha soluções redundantes ou que conflitem com regras prévias.

---

## 2. Quando Executar a Sincronização

Sempre que você concluir:
- Criação ou modificação de modelos persistidos (`models/`).
- Adição ou refatoração de regras de negócio, fluxos de PDV, caixa ou estoque.
- Criação de novos diálogos, telas ou padrões visuais.
- Solução de bugs de interface, responsividade, escala de fontes ou concorrência.
- Implementação de novos comandos, atalhos de teclado ou integrações de hardware.

**Você deve atualizar os arquivos de documentação AUTOMATICAMENTE no mesmo ciclo de trabalho, sem esperar solicitação do usuário.**

---

## 3. Arquivos que Devem Ser Sincronizados

1. **`AGENTS.md` (Manifesto e Contexto de Transferência):**
   - Seção 5 (Arquitetura) / Seção 6 (Sistema de Design) / Seção 7 (Mapa do que já funciona):
     - Registre novas regras, comportamentos consolidados e decisões técnicas.
   - Seção 8 (Regras Críticas de Engenharia):
     - Registre pegadinhas (*gotchas*) e soluções comprovadas para prevenir regressões.

2. **`README.md` (Documento Público Bilíngue):**
   - Atualize a lista de recursos funcionais em **Current Status** (Inglês) e **Estado Atual** (Português do Brasil).
   - Mantenha o tom profissional, ideológico e alinhado com o propósito do Nous.

3. **Skills em `.agents/skills/`:**
   - `padrao-visual/SKILL.md`: se houver novidade visual, de acessibilidade ou layout.
   - `modelo-persistido/SKILL.md`: se houver novo modelo ou convenção de persistência.
   - `imagem-e-fotos/SKILL.md`: se houver novas regras para avatares, mídias ou anexos.

---

## 4. Diretrizes de Qualidade da Documentação

- **Sintético e Cirúrgico:** Não infle arquivos com textos longos ou redundantes. Documente de forma concisa o **quê**, o **porquê** e o **como**.
- **Português do Brasil (pt-BR):** Exceto a seção em inglês do `README.md`, todos os documentos devem ser escritos em pt-BR claro e pedagógico.
- **Validação de Sintaxe:** Antes de encerrar, confirme que o código compila perfeitamente com `dart analyze lib`.
