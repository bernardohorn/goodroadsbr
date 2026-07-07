/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '.',
  // Testes unitarios apenas (repository mockado, sem banco real). Os e2e
  // (tests/e2e/**/*.e2e.test.ts) tem config e comando proprios — ver
  // jest.e2e.config.js e `npm run test:e2e` — porque exigem um Postgres
  // real de pe, o que `npm test` nao deve assumir.
  testMatch: ['<rootDir>/tests/**/*.test.ts'],
  testPathIgnorePatterns: ['<rootDir>/node_modules/', '<rootDir>/tests/e2e/'],
  clearMocks: true,
  setupFiles: ['<rootDir>/tests/setupEnv.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/server.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  }
};
