# GoodRoads — Backend

API REST em Node.js + Express + Prisma + PostgreSQL (com PostGIS) para a plataforma GoodRoads. Ver arquitetura completa em `../docs/ARQUITETURA_GOODROADS.md`.

## Status (Etapa 6 — roadmap original concluído)

Implementado na Etapa 1:

- Schema completo do banco (`prisma/schema.prisma`), cobrindo todo o modelo entidade-relacionamento do documento de arquitetura.
- Autenticacao: registro, login, refresh (com rotacao e deteccao de reuso), logout, esqueci minha senha e redefinicao de senha.
- Middlewares centrais: guard de autenticacao (JWT RS256), guard de RBAC, rate limiting, validacao com zod, tratamento de erros, logger estruturado, auditoria.
- Abstracoes de infraestrutura ja seguindo as decisoes do cliente: `StorageProvider` (implementacao local em disco, pronta para trocar por S3/R2/MinIO) e `PushProvider` (stub, pronto para receber a integracao com Firebase Cloud Messaging na Etapa 5).
- Endpoint `GET/PATCH /api/v1/users/me`.

Implementado nesta etapa (Etapa 2):

- **Ocorrencias** (`/api/v1/occurrences`): criar (multipart, com 1 a 5 fotos obrigatorias via `StorageProvider`), listar (escopada por papel — cidadao ve so as suas, equipe ve todas, com filtros de status/prioridade/categoria/busca, paginacao e ordenacao), detalhar (com checagem de posse), historico de status, atualizar status (com validacao de transicao permitida, geracao de historico e notificacao ao cidadao) e atualizar categoria/prioridade/equipe/responsavel/observacoes internas.
- Numeracao de protocolo (`GR-{ano}-{sequencial}`) gerada de forma atomica no banco (`ProtocolSequence`), sem condicao de corrida sob concorrencia.
- **Categorias** (`/api/v1/categories`) e **Times** (`/api/v1/teams`): CRUD leve, leitura publica (categorias) e escrita restrita a `FUNCIONARIO`/`ADMIN`.
- **Notificacoes in-app** (`/api/v1/notifications`): toda mudanca de status grava uma notificacao consultavel pelo cidadao (`GET`/`PATCH :id/read`) e aciona `PushProvider` (ainda `NoopPushProvider` ate a Etapa 5 integrar o FCM de fato).
- **Mapa** (`/api/v1/map/occurrences`): busca geoespacial por bounding box usando o indice GiST do PostGIS (`ST_Intersects`), com filtros opcionais de status/categoria.
- Tratamento de erros do Multer (upload) integrado ao `errorHandler` central.

Implementado nesta etapa (Etapa 4, para suportar as telas novas do app desktop — ver `../docs/DECISOES.md`):

- **Funcionarios** (`/api/v1/staff`): listagem (qualquer `FUNCIONARIO`/`ADMIN`, usada tambem para popular o seletor de "Atribuido a" nas ocorrencias) e criacao/edicao restritas a `ADMIN`.
- **Dashboard** (`/api/v1/dashboard/stats`): cards agregados (total, por status, cidadaos cadastrados), contagem por categoria, serie mensal dos ultimos 6 meses e as 5 ocorrencias mais recentes.
- **Relatorios** (`/api/v1/reports/export?format=csv|pdf`): exportacao de ocorrencias filtradas (status/categoria/periodo) em CSV (separador `;` e BOM UTF-8, compativel com Excel em pt-BR, gerado sem biblioteca externa em `src/core/utils/csv.ts`) ou PDF (tabela paginada via `pdfkit`, `src/core/utils/pdf.ts`).
- Seed atualizado (`prisma/seed.ts`): agora cria tambem uma conta `ADMIN` (`admin@goodroads.dev`) alem da `FUNCIONARIO` (`funcionario@goodroads.dev`), ambas com senha `Trocar@123`, para poder testar as rotas de `/staff` (escrita) localmente.

Implementado nesta etapa (Etapa 5 — push real + suporte a sincronizacao offline do mobile):

- **`FcmPushProvider`** (`src/infra/push/FcmPushProvider.ts`): implementacao real da interface `PushProvider` usando o Firebase Admin SDK. Selecionada via `PUSH_DRIVER=fcm` (padrao continua `noop`, que nao exige nenhuma credencial). Envia para todos os devices do usuario (`sendEachForMulticast`) e remove automaticamente tokens que o FCM reporta como invalidos/nao registrados.
- **Modelo `DeviceToken`** (`prisma/schema.prisma`): um usuario pode ter varios tokens (varios devices logados). Endpoints `POST /api/v1/notifications/devices` (registrar) e `DELETE /api/v1/notifications/devices` (remover, usado no logout).
- Variaveis de ambiente novas (`.env.example`): `PUSH_DRIVER` (`noop`|`fcm`) e `FCM_SERVICE_ACCOUNT_PATH` (caminho do JSON da service account do Firebase, padrao `./keys/dev/firebase-service-account.json`).

**Para ativar push de verdade:** crie um projeto no [Firebase Console](https://console.firebase.google.com), gere uma service account em Configuracoes do projeto → Contas de servico → Gerar nova chave privada, salve o JSON em `backend/keys/dev/firebase-service-account.json` (pasta ja no `.gitignore`) e defina `PUSH_DRIVER=fcm` no `.env`. Sem isso, o backend continua funcionando normalmente com `NoopPushProvider` (as notificacoes in-app continuam sendo gravadas normalmente, so nao ha push real).

Implementado nesta etapa (Etapa 6 — hardening, observabilidade, testes e2e, producao; ver `../docs/ARQUITETURA_GOODROADS.md`, secao 12):

- **Seguranca:** `trust proxy` em producao, HSTS via `helmet` quando `NODE_ENV=production`, `X-Request-Id` por requisicao, desligamento gracioso (`SIGTERM`/`SIGINT`) em `src/server.ts` fechando conexoes HTTP e Prisma antes de encerrar.
- **Observabilidade:** `GET /health` (liveness), `GET /health/ready` (readiness — checa o Postgres) e `GET /metrics` (Prometheus, via `prom-client` — metricas do processo Node + duracao/contagem de requisicoes HTTP). `/metrics` nao tem autenticacao propria; mantenha fora do acesso publico no seu deploy.
- **Testes end-to-end** (`tests/e2e/`): sobem a aplicacao real e batem contra um Postgres/PostGIS real via `supertest` — cobrem autenticacao completa (com rotacao/reuso de refresh token) e ocorrencias (foto obrigatoria, RBAC de rota e de posse, transicoes de status). Rodam separado dos unitarios: `npm run test:e2e` (ver secao "Testes" abaixo).
- **Docker:** `Dockerfile` multi-estagio (deps → build → runtime, sem devDependencies na imagem final, usuario nao-root, `HEALTHCHECK`), `docker-entrypoint.sh` (roda `prisma migrate deploy` antes de iniciar) e `docker-compose.prod.yml` (Postgres + API, chaves montadas via volume).
- **CI/CD:** `.github/workflows/backend-ci.yml` (lint, typecheck, testes unitarios e e2e contra Postgres/PostGIS real, build e validacao da imagem Docker).

Ainda **nao** implementado: storage S3 (continua local em disco, via `StorageProvider`).

## Pre-requisitos

- Node.js 20+
- Docker (para rodar o Postgres com PostGIS localmente, e para buildar/rodar a imagem de producao) — ou uma instancia Postgres 16+ com a extensao `postgis` disponivel.

## Como rodar

```bash
cd backend
npm install

# Sobe o Postgres com PostGIS em Docker
docker compose up -d

# Copia o arquivo de ambiente e ajusta se necessario
cp .env.example .env

# Gera um par de chaves RSA de desenvolvimento para assinar os JWTs
npm run keys:generate

# Cria as tabelas a partir do schema
npm run prisma:migrate

# Adiciona a coluna geoespacial (PostGIS) e o trigger de sincronizacao
# (psql nao entende o parametro ?schema= do Prisma, por isso removemos com ${DATABASE_URL%%\?*})
psql "${DATABASE_URL%%\?*}" -f prisma/sql/postgis.sql

# Popula dados iniciais (roles, prefeitura de exemplo, categorias, 1 funcionario)
npm run prisma:seed

# Sobe a API em modo desenvolvimento (hot reload)
npm run dev
```

A API sobe em `http://localhost:3333`, com as rotas sob `http://localhost:3333/api/v1`.

## Testes

```bash
npm test
```

Os testes de `tests/auth.service.test.ts` cobrem as regras de negocio de autenticacao (registro, login, rotacao de refresh token, deteccao de reuso, fluxo de redefinicao de senha) e `tests/occurrences.service.test.ts` cobre as regras de ocorrencias (foto obrigatoria, geracao de protocolo, checagem de posse, transicoes de status validas/invalidas, notificacao ao mudar status) — ambos com o repository mockado, sem exigir um banco de dados real.

### Testes end-to-end (Etapa 6)

```bash
# 1. Suba um Postgres com PostGIS dedicado a testes (pode ser o mesmo docker-compose.yml,
#    so aponte para um banco/porta diferente do de desenvolvimento se rodar os dois juntos)
docker compose up -d

# 2. Aplique o schema no banco de testes
DATABASE_URL_E2E="postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e?schema=public" \
  DATABASE_URL="postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e?schema=public" \
  npx prisma migrate deploy
psql "postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e" -f prisma/sql/postgis.sql

# 3. Rode os testes e2e (config e comando separados de `npm test`)
DATABASE_URL_E2E="postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e?schema=public" npm run test:e2e
```

Diferente dos unitarios, estes sobem a aplicacao real (`createApp()`) e fazem requisicoes HTTP via `supertest` contra o banco de verdade — por isso exigem um Postgres/PostGIS migrado. Ver `tests/e2e/setupE2e.ts` para detalhes.

> Nota: neste ambiente de desenvolvimento assistido, nao houve acesso ao registro npm nem a um banco Postgres real para instalar dependencias e rodar `npm install`/`npm test`/`npm run test:e2e`/`npm run typecheck` de ponta a ponta, nem a um daemon Docker para buildar a imagem. O codigo foi escrito e revisado manualmente com cuidado, mas rode `npm install && npm run typecheck && npm test` no seu ambiente como primeira verificacao, seguido de `npm run test:e2e` (com um Postgres real de pe) antes de considerar o projeto pronto para produção.

## Produção (Etapa 6)

```bash
# Build da imagem
docker build -t goodroads-api .

# Ou via docker-compose (Postgres + API juntos)
cp .env.example .env.production   # preencha com valores reais de producao
mkdir -p keys/dev                 # coloque aqui as chaves JWT (e FCM, se PUSH_DRIVER=fcm) reais
docker compose -f docker-compose.prod.yml up -d --build
```

No `.env.production`, ajuste o host do `DATABASE_URL` de `localhost` para `postgres` (o nome do serviço no `docker-compose.prod.yml`) — dentro da rede do Docker Compose, o container da API nao alcanca o Postgres via `localhost`.

O `docker-entrypoint.sh` roda `prisma migrate deploy` automaticamente antes de iniciar a API. `GET /health` (liveness) e `GET /health/ready` (readiness) ficam disponiveis para o orquestrador; `GET /metrics` expõe métricas Prometheus (mantenha fora do acesso público). Ver `../docs/ARQUITETURA_GOODROADS.md`, seção 12, para o detalhamento completo (segurança, observabilidade, CI/CD).

## Estrutura

Ver `../docs/ARQUITETURA_GOODROADS.md`, secao 2, para a explicacao completa de cada camada (`routes → controller → service → repository → schema`).
