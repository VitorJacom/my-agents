[← Voltar ao Sumário de Scripts](Scripts-Catalog)

# ⚡ Scripts: Statusline & Quota CLI (`scripts/statusline/`)

> **Diretório**: [`scripts/statusline/`](https://github.com/VitorJacom/my-agents/tree/main/scripts/statusline)  
> **Quantidade**: 3 scripts

---

## 🎯 Propósito

Fornece a barra de status modular integrada ao rodapé do Antigravity CLI (detalhada no guia [`Getting-Started`](Getting-Started)), exibindo contexto de repositório, quota da API Gemini em tempo real e notificação não-intrusiva de novas versões do plugin, mantendo **latência estritamente inferior a 50ms** graças a cache TTL local — validada pelas suítes em [`Test-statusline`](Test-statusline) (em caso de falhas locais, consulte [`Troubleshooting`](Troubleshooting)).

---

## 📋 Catálogo de Scripts (3)

| Script | Função Principal |
| :--- | :--- |
| **`install-statusline.sh`** | Instala e configura automaticamente a statusline do `my-agents` em `~/.gemini/antigravity-cli/settings.json` de forma idempotente (sem sobrescrever preferências existentes). Suporta `--dry-run`. |
| **`statusline-quota.sh`** | Motor principal de renderização da statusline (< 50ms com cache TTL em `$XDG_CACHE_HOME` / `~/.cache`). Inclui consulta de quota e o `widget_update` para notificação de atualizações. |
| **`test-statusline.sh`** | Utilitário de fumaça e benchmark rápido para validar renderização ANSI e tempo de resposta sub-50ms localmente. |

---

## 💻 Exemplos de Uso

```bash
# Simular instalação sem modificar settings.json
./scripts/statusline/install-statusline.sh --dry-run

# Instalar a statusline no ambiente local
./scripts/statusline/install-statusline.sh

# Validar renderização e latência rapidamente
./scripts/statusline/test-statusline.sh
```

---

## 🔗 Navegação

[← Anterior: Revisor de PR & Telemetria](Script-pr-reviewer) | [Sumário de Scripts](Scripts-Catalog) | [Próxima Categoria: Migrações Históricas →](Script-migrations)
