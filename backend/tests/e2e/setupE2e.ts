/**
 * Segunda metade do setup dos testes e2e (Etapa 6) — roda via
 * `setupFilesAfterEnv`, depois de `setupEnv.e2e.ts` (que configura
 * `process.env`, ver esse arquivo para o porque da divisao) e depois do
 * framework de teste (`beforeAll`/`afterAll`) estar instalado.
 *
 * Diferente de `tests/setupEnv.ts` (usado pelos testes unitarios, que
 * mockam o repository e nunca tocam um banco real), estes testes sobem a
 * aplicacao Express de verdade (`createApp()`) e fazem requisicoes HTTP
 * reais contra ela via `supertest`, que por sua vez conversa com um
 * Postgres/PostGIS real atraves do Prisma — exatamente o caminho que uma
 * requisicao percorre em producao.
 *
 * Por isso, ao contrario dos testes unitarios, os e2e **exigem** uma
 * instancia real de Postgres com o schema migrado. Rode:
 *
 *   docker compose up -d
 *   DATABASE_URL="postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e?schema=public" \
 *     npx prisma migrate deploy
 *   psql "$DATABASE_URL" -f prisma/sql/postgis.sql
 *   npm run test:e2e
 *
 * (ou aponte DATABASE_URL_E2E para um banco de testes ja preparado — ver
 * README). Este arquivo NAO roda migrations sozinho: rodar DDL a cada
 * execucao de teste seria lento e arriscado (o schema real deve ser
 * migrado do mesmo jeito que em producao, via `prisma migrate deploy`).
 *
 * Este sandbox de desenvolvimento nao tem um Postgres real disponivel, entao
 * estes testes nao puderam ser executados aqui — apenas escritos e
 * revisados estaticamente. Ver docs/DECISOES.md.
 */
import { RoleName } from '@prisma/client';
import { prisma } from '../../src/infra/database/prisma.client';

/**
 * Garante que os 3 papeis (roles) existem antes de qualquer teste — o
 * fluxo de registro (`AuthService.register`) depende de `Role.CIDADAO` ja
 * existir no banco (mesma pre-condicao que `prisma/seed.ts` garante em
 * desenvolvimento). `upsert` torna a chamada idempotente entre execucoes.
 */
export async function ensureRolesSeeded(): Promise<void> {
  await Promise.all(
    Object.values(RoleName).map((name) =>
      prisma.role.upsert({ where: { name }, update: {}, create: { name } })
    )
  );
}

/** Email unico por teste, para nao colidir entre execucoes no mesmo banco. */
export function uniqueEmail(prefix: string): string {
  return `${prefix}.${Date.now()}.${Math.random().toString(36).slice(2, 8)}@e2e.goodroads.dev`;
}

beforeAll(async () => {
  await ensureRolesSeeded();
});

afterAll(async () => {
  await prisma.$disconnect();
});
