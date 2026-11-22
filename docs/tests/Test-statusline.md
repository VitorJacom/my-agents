[← Voltar ao Sumário de Testes](Tests-Catalog)

# ⚡ Testes: Statusline & Performance (`tests/features/statusline/`)

> **Diretório**: [`tests/features/statusline/`](https://github.com/VitorJacom/my-agents/tree/main/tests/features/statusline)  
> **Quantidade**: 3 suítes  
> **Comando**: `./tests/run.sh --category statusline`

---

## 🎯 Propósito da Camada

Valida a arquitetura modular da barra de status (statusline) do CLI ([`Script-statusline`](Script-statusline)), garantindo **latência sub-50ms** via cache TTL, instalação idempotente multi-ambiente e renderização do widget de notificação de atualizações do plugin.

---

## 📋 Suítes da Categoria (3)

| Suíte | Origem | O que Valida |
| :--- | :--- | :--- |
| **`test_statusline.sh`** | Issue #6 | Arquitetura modular da statusline, formatação ANSI, fallback seguro sem Git e **benchmark determinístico de latência (< 50ms)**. |
| **`test_install_statusline.sh`** | Issue #7 | Instalador automatizado e idempotente da statusline no ambiente local sem sobrescrever configurações existentes do usuário. |
| **`test_statusline_update_widget.sh`** | Issue #67 | Widget modular de notificação de atualização (`statusline-update-notification`), cache TTL e degradação silenciosa quando offline. |

---

## 🔗 Navegação

[← Anterior: Revisão de PR & Telemetria](Test-pr-review) | [Sumário de Testes](Tests-Catalog)
