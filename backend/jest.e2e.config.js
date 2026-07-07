/**
 * Config separada para os testes end-to-end (Etapa 6). Isolada de
 * jest.config.js porque estes testes exigem um Postgres/PostGIS real
 * migrado (ver tests/e2e/setupE2e.ts) — nao devem rodar como parte do
 * `npm test` padrao, que deve continuar funcionando sem nenhuma
 * infraestrutura externa (so repository mockado).
 */
/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '.',
  testMatch: ['<rootDir>/tests/e2e/**/*.e2e.test.ts'],
  // Ordem importa: setupFiles (variaveis de ambiente, sem tocar em src/)
  // roda ANTES do framework de teste ser instalado; setupFilesAfterEnv
  // (que importa `prisma`, logo `src/config/env.ts`) roda depois, ja com
  // process.env no estado certo. Ver tests/e2e/setupEnv.e2e.ts para o
  // detalhe de por que essa divisao existe.
  setupFiles: ['<rootDir>/tests/e2e/setupEnv.e2e.ts'],
  setupFilesAfterEnv: ['<rootDir>/tests/e2e/setupE2e.ts'],
  testTimeout: 30_000,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  }
};
