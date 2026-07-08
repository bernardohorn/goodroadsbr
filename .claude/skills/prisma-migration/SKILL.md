---
name: prisma-migration
description: Conduz mudanças de schema do banco (PostgreSQL via Prisma) de forma segura, prevenindo migrations destrutivas sem confirmação. Use quando o usuário quiser alterar o schema.prisma, adicionar/remover tabelas ou colunas, criar índices, relações ou rodar prisma migrate.
---

## Estado atual do schema

!`cat backend/prisma/schema.prisma 2>/dev/null | head -120 || echo "schema.prisma nao encontrado em backend/prisma/"`

## Fluxo

1. Editar `backend/prisma/schema.prisma` com a mudança desejada.
2. Gerar a migration nomeada:
   `npx prisma migrate dev --name <descricao_curta_em_snake_case>`.
3. Rodar `npx prisma generate` se o client precisar ser regenerado.
4. Revisar o SQL gerado em `prisma/migrations/<timestamp>_<nome>/migration.sql`
   antes de considerar concluído.

## Regras de segurança (BLOQUEANTES)

- **Nunca** gerar/aplicar migration que contenha `DROP TABLE`, `DROP COLUMN`
  ou alteração que perca dados **sem confirmação explícita do usuário**.
  Ao detectar uma dessas, pare e pergunte.
- **Nunca** editar uma migration que já foi aplicada em produção — criar uma
  nova.
- **Nunca** rodar `prisma migrate reset` (apaga o banco) sem confirmação
  explícita — está no deny-list do projeto.
- Renomear coluna/tabela: preferir migration em duas etapas (adicionar novo
  → copiar dados → remover antigo) em vez de rename direto, para não quebrar
  clientes em produção.

## Índices e performance

Sempre que adicionar coluna usada em filtro de listagem de ocorrências
(status, prefeitura, data, localização), adicionar o índice correspondente
na mesma migration. Listagens sem índice degradam com milhares de registros.

## Ao finalizar

1. Confirmar que a migration foi criada e o `migration.sql` foi revisado.
2. `npm run lint && npm test`.
3. Se a mudança altera dados expostos pela API, acionar `api-contract-sync`.
