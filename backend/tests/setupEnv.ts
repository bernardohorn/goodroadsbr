/**
 * Configura variaveis de ambiente e chaves RSA de teste antes de qualquer
 * modulo da aplicacao ser importado (via jest `setupFiles`). Mantem os
 * testes independentes de `.env`/`npm run keys:generate` terem sido
 * executados manualmente.
 */
import { generateKeyPairSync } from 'crypto';
import fs from 'fs';
import path from 'path';

const keysDir = path.resolve(__dirname, '..', 'keys', 'test');
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
process.env.DATABASE_URL = process.env.DATABASE_URL ?? 'postgresql://test:test@localhost:5432/goodroads_test';
process.env.JWT_PRIVATE_KEY_PATH = path.relative(process.cwd(), privateKeyPath);
process.env.JWT_PUBLIC_KEY_PATH = path.relative(process.cwd(), publicKeyPath);
process.env.JWT_ACCESS_TOKEN_TTL = '15m';
process.env.JWT_REFRESH_TOKEN_TTL_DAYS = '30';
