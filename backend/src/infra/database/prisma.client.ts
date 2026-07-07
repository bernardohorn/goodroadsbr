import { PrismaClient } from '@prisma/client';
import { env } from '../../config/env';

/**
 * Instancia unica do Prisma Client, reaproveitada em toda a aplicacao
 * (evita esgotar o pool de conexoes do Postgres abrindo um client por
 * requisicao). Em testes, cada arquivo pode substituir esta instancia por
 * um mock via jest.mock('@/infra/database/prisma.client').
 */
export const prisma = new PrismaClient({
  log: env.isProduction ? ['error', 'warn'] : ['error', 'warn']
});
