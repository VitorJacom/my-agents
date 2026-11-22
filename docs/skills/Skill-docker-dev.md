[← Voltar ao Sumário de Skills](Skills-Catalog)

> [!WARNING]
> ⚠️ **DEPRECATED**: Esta skill está obsoleta e será removida em versão futura.

> **Diagnóstico e Gestão de Containers**  
> **Definição Canônica**: [`skills/docker-dev/SKILL.md`](https://github.com/VitorJacom/my-agents/blob/main/skills/docker-dev/SKILL.md)  
> **Categoria**: Engenharia, Arquitetura & Infra  
> **Status**: `DEPRECATED`  
> **Comando de Invocação**: Invocação contextual em tarefas de Docker e Docker Compose

---

## 🎯 Objetivo

A skill **`docker-dev`** orienta o diagnóstico, operação e validação de ambientes locais baseados em **Docker** e **Docker Compose**, além de impor boas práticas de segurança e otimização na escrita de `Dockerfile` e `docker-compose.yml`.

---

## ⚡ Quando Acionar (*Progressive Disclosure*)

- Quando containers falham na inicialização ou entram em *restart loop* (complementando o guia de [`Troubleshooting`](Troubleshooting)).
- Em conflitos de portas, problemas de rede entre serviços ou volumes montados incorretamente.
- Ao criar ou auditar `Dockerfile`, `.dockerignore` e `docker-compose.yml` durante implementações conduzidas pelo [`coder`](Agent-coder).

---

## 🚀 Exemplos de Invocação

```text
O container da API está reiniciando em loop, descubra o motivo
Verifique as portas em conflito no docker-compose.yml
Audite este Dockerfile aplicando multi-stage build e usuário não-root
```

---

## 🔍 Comandos de Diagnóstico & Ciclo de Vida

```bash
# Inspeção e logs
docker ps -a
docker logs --tail 100 -f <container_name_or_id>
docker compose ps
docker compose logs --tail 50 <service_name>

# Operação local
docker compose up -d
docker compose build --no-cache <service_name> && docker compose up -d <service_name>
docker compose restart <service_name>
```

---

## 🛡️ Boas Práticas Obrigatórias em Dockerfiles

1. **Multi-Stage Builds**: Separar compilação/build da imagem final de produção para reduzir tamanho e superfície de ataque.
2. **Usuário Não-Root**: Nunca executar a aplicação como `root` (`USER node` ou `USER appuser`).
3. **Zero Secrets Hardcoded**: Jamais embutir tokens ou senhas no `Dockerfile`; usar `.env` ou Docker Secrets.
4. **`.dockerignore` Limpo**: Excluir `node_modules`, `.git`, `.env` e arquivos temporários do contexto de build.

---

## 🔗 Navegação

[← Anterior: `git-workflow`](Skill-git-workflow) | [Sumário de Skills](Skills-Catalog) | [Próxima Skill: `game-dev-patterns` →](Skill-game-dev-patterns)
