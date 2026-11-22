[← Voltar ao Sumário de Scripts](Scripts-Catalog)

# 🪝 Scripts: Hooks de Runtime (`scripts/hooks/`)

> **Diretório**: [`scripts/hooks/`](https://github.com/VitorJacom/my-agents/tree/main/scripts/hooks)  
> **Quantidade**: 2 scripts  
> **Orquestração**: Declarados em [`hooks.json`](https://github.com/VitorJacom/my-agents/blob/main/hooks.json)

---

## 🎯 Propósito

Os scripts em `scripts/hooks/` são disparados automaticamente pelo **Antigravity CLI** em eventos do ciclo de vida da sessão, fornecendo blindagem preventiva contra comandos destrutivos e injeção dinâmica de contexto sem poluir arquivos versionados.

---

## 📋 Catálogo de Hooks (2)

### 1. `safety-guard.sh`
- **Evento**: `PreToolUse`
- **Função**: Intercepta comandos de terminal antes da execução para bloquear operações destrutivas não autorizadas (como `rm -rf /`, `git push --force` em branches protegidas ou comandos que violam guardrails de segurança).
- **Comportamento**: Retorna código de saída diferente de zero com diagnóstico claro quando detecta violação, impedindo a execução da ferramenta.

### 2. `session-start-context.sh`
- **Evento**: `SessionStart`
- **Função**: Carrega automaticamente `PROJECT_CONTEXT.md` e injeta o estado volátil do Git em tempo real (branch ativa, último commit e `git status --short`) na abertura de cada sessão.
- **Benefício**: Garante *Zero Token Waste* (o agente já nasce situado no projeto) e mantém o `PROJECT_CONTEXT.md` 100% estável sem diffs voláteis a cada commit (validado em [`Test-core`](Test-core)).

---

## 🔗 Navegação

[← Voltar ao Sumário de Scripts](Scripts-Catalog) | [Próxima Categoria: Esteira & Governança AIDD →](Script-pipeline)
