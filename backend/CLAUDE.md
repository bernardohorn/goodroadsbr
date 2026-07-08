# GoodRoads Backend — Claude Code Guide

Node.js + Express + PostgreSQL + Prisma ORM. API consumida pelo app mobile
(cidadãos) e pelo app desktop (prefeitura).

## Estrutura (Clean Architecture)

```
backend/
├── src/
│   ├── domain/            # Entidades e regras de negócio puras (sem deps externas)
│   ├── application/       # Casos de uso / services
│   ├── infrastructure/    # Prisma, repositórios concretos, storage, email
│   ├── interfaces/
│   │   ├── http/          # Controllers, rotas Express, middlewares
│   │   └── dtos/          # Schemas de entrada/saída (zod ou class-validator)
│   ├── config/            # env, jwt, cors, rate limit
│   └── shared/            # erros customizados, utils
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── tests/
│   ├── unit/
│   └── integration/
└── .env.example
```

Regra de dependência: `domain` não importa nada de `infrastructure` ou
`interfaces`. `application` só depende de `domain` e de interfaces
(abstrações), nunca de implementações concretas do Prisma diretamente —
usar repositórios injetados.

## Autenticação e RBAC

- JWT com access token curto (15min) + refresh token (7d), refresh token
  armazenado com hash no banco (rotação em cada uso).
- Middleware `requireAuth` valida token; middleware `requireRole([...])`
  valida papel. Autorização sempre no servidor, nunca confiar em claims não
  assinadas.
- Senhas: bcrypt (custo ≥ 12), nunca armazenar em texto plano nem logar.

## Banco de dados

- Toda mudança de schema passa por `prisma migrate dev --name <descricao>`.
- Nunca editar migrations já aplicadas em produção; criar uma nova.
- Migrations destrutivas exigem confirmação explícita do usuário antes de
  serem geradas.
- Índices obrigatórios em colunas usadas em filtros de listagem
  (ocorrências por status, por prefeitura, por localização).

## Padrões de API

- REST, versionado (`/api/v1/...`).
- Respostas de erro em formato consistente:
  `{ "error": { "code": "...", "message": "..." } }`.
- Paginação padrão em listagens (`page`, `limit`, `total`).
- Validação de entrada com schema (zod recomendado) em toda rota antes de
  chegar ao controller.
- Localização de ocorrências: armazenar `latitude`/`longitude` (numeric) —
  nunca depender de serviço externo para persistência, apenas para
  geocoding reverso opcional via Nominatim.

## Comandos

```bash
npm run dev              # servidor em modo desenvolvimento
npm run build             # build de produção
npm test                  # testes unitários
npm run test:integration  # testes de integração (requer DB de teste)
npx prisma studio          # inspecionar dados
npx prisma migrate dev     # aplicar/gerar migration
npm run lint               # eslint
npm run format              # prettier
```

## Ao terminar uma tarefa

1. Rodar `npm run lint` e `npm test`.
2. Se alterou schema, confirmar que a migration foi gerada e está no PR.
3. Se alterou contrato de rota, atualizar `docs/api-contract.md` na raiz do
   monorepo.
