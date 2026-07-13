---
name: backend-verify
description: Roda a verificação local do backend (lint, typecheck, testes unitários e build) e reporta o resultado, além do passo a passo dos testes e2e que exigem Postgres/PostGIS. Use antes de abrir um PR do backend, depois de mexer em backend/, ou quando o usuário pedir para "verificar", "checar" ou "validar" o backend.
---

## Verificação rápida (sem banco)

!`cd backend && npm run lint && npm run typecheck && npm test && npm run build`

## Como interpretar

- **Tudo verde acima** → o backend passa no mesmo gate do `Backend CI` (a parte
  que não depende de banco). Pode seguir para o PR.
- **Algo falhou** → corrija antes de commitar. O hook de pre-commit
  (`.claude/hooks/pre-commit-guard.mjs`) barra o commit pelas mesmas checagens de
  lint/typecheck, então não adianta tentar commitar por cima.

## Verificação completa (com Postgres/PostGIS) — testes e2e

Os e2e sobem a API real contra um Postgres com PostGIS e exigem um banco migrado
(detalhes em `backend/README.md`):

1. Suba o Postgres+PostGIS: `docker compose up -d` (em `backend/`) ou um Postgres
   local com a extensão `postgis` instalada.
2. Aplique schema + PostGIS no banco de e2e (lembre: `psql` não aceita o
   `?schema=` do Prisma):
   - `DATABASE_URL_E2E=... DATABASE_URL=... npx prisma migrate deploy`
   - `psql "${DATABASE_URL_E2E%%\?*}" -f prisma/sql/postgis.sql`
3. `cd backend && DATABASE_URL_E2E=... npm run test:e2e`

## Regras do projeto ao verificar

- Nunca desative lint/typecheck/testes "temporariamente" para passar.
- Código novo exportado/público exige teste correspondente antes de ser dado como
  concluído.
- Se a mudança tocou contrato de API, rode também a skill `api-contract-sync`.
