/**
 * Primeira metade do setup dos testes e2e (Etapa 6): SO variaveis de
 * ambiente, sem importar nada de `src/` — roda via `setupFiles` do Jest,
 * que executa antes do framework de teste ser instalado.
 *
 * Por que este arquivo existe separado de `setupE2e.ts` (que roda via
 * `setupFilesAfterEnv`): declaracoes `import` de nivel superior sao
 * "hoisted" para o topo do modulo pelo compilador, mesmo que apareçam
 * depois de outro codigo no arquivo-fonte. Se `setupE2e.ts` fizesse
 * `process.env.DATABASE_URL = ...` e, mais abaixo no mesmo arquivo,
 * `import { prisma } from '../../src/infra/database/prisma.client'`, o
 * import seria executado ANTES da atribuicao — e `src/config/env.ts` leria
 * `process.env` no estado antigo (sem a URL do banco de testes), quebrando
 * a configuracao. Dividir em dois arquivos (cada um um modulo completo,
 * executado em sequencia pelo Jest) evita esse problema.
 */
import fs from 'fs';
import path from 'path';
import { generateKeyPairSync } from 'crypto';

const keysDir = path.resolve(__dirname, '..', '..', 'keys', 'test');
fs.mkdirSync(keysDir, { recursive: true });

const privateKeyPath = path.join(keysDir, 'private.pem');
const publicKeyPath = path.join(keysDir, 'public.pem');

if (!fs.existsSync(privateKeyPath) || !fs.existsSync(publicKeyPath)) {
  const { publicKey, privateKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
  });
  fs.writeFileSync(privateKeyPath, privateKey);
  fs.writeFileSync(publicKeyPath, publicKey);
}

process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.DATABASE_URL_E2E ??
  process.env.DATABASE_URL ??
  'postgresql://goodroads:goodroads@localhost:5432/goodroads_e2e?schema=public';
process.env.JWT_PRIVATE_KEY_PATH = path.relative(process.cwd(), privateKeyPath);
process.env.JWT_PUBLIC_KEY_PATH = path.relative(process.cwd(), publicKeyPath);
process.env.JWT_ACCESS_TOKEN_TTL = '15m';
process.env.JWT_REFRESH_TOKEN_TTL_DAYS = '30';
process.env.LOCAL_STORAGE_DIR = './uploads-e2e';
// Rate limit generoso o bastante para nao interferir na suite (o
// comportamento do rate limiter em si e testado a nivel de middleware, nao
// aqui) — evita testes "flaky" por causa de 429 quando varios `it()` do
// mesmo arquivo batem em /auth em sequencia rapida.
process.env.AUTH_RATE_LIMIT_MAX = '1000';
process.env.RATE_LIMIT_MAX = '1000';
