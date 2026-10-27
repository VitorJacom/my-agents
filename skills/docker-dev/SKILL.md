---
name: docker-dev
description: >-
  Diagnóstico, gerenciamento e validação de containers locais e configurações Docker / Docker Compose.
---

# Docker Dev & Container Troubleshooting

Esta Skill auxilia na operação, diagnóstico e manutenção do ambiente de desenvolvimento baseado em Docker.

## 1. Inspeção e Diagnóstico Rápido

Quando houver falhas de inicialização, portas ocupadas ou containers parando inesperadamente:

```bash
# Listar containers em execução e parados com status
docker ps -a

# Inspecionar os últimos logs de erro do container com timestamp
docker logs --tail 100 -f <container_name_or_id>

# Verificar status dos serviços no Docker Compose
docker compose ps
docker compose logs --tail 50 <service_name>
```

---

## 2. Ciclo de Vida do Ambiente Local

- **Subir serviços em background**:
  ```bash
  docker compose up -d
  ```
- **Reconstruir imagens sem cache quando houver alterações de dependências**:
  ```bash
  docker compose build --no-cache <service_name>
  docker compose up -d <service_name>
  ```
- **Reiniciar um serviço específico sem derrubar o restante da stack**:
  ```bash
  docker compose restart <service_name>
  ```

---

## 3. Boas Práticas e Segurança em Dockerfiles

Ao criar ou editar `Dockerfile` e `docker-compose.yml`:
1. **Multi-Stage Builds**: Sempre separe a etapa de compilação/build da imagem final de produção (reduz superfície de ataque e tamanho).
2. **Usuário Não-Root**: Evite rodar a aplicação como `root` dentro do container (`USER node` ou `USER appuser`).
3. **Variáveis de Ambiente**: Nunca coloque secrets, tokens ou senhas fixas no `Dockerfile` (use `.env` ou secrets do Docker).
4. **Camadas (.dockerignore)**: Sempre garanta que `node_modules`, `.git`, `.env` e arquivos temporários estão listados no `.dockerignore`.
