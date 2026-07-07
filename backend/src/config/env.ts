import fs from 'fs';
import path from 'path';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3333),
  API_PREFIX: z.string().default('/api/v1'),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL e obrigatorio'),

  JWT_PRIVATE_KEY_PATH: z.string().default('./keys/dev/private.pem'),
  JWT_PUBLIC_KEY_PATH: z.string().default('./keys/dev/public.pem'),
  JWT_ACCESS_TOKEN_TTL: z.string().default('15m'),
  JWT_REFRESH_TOKEN_TTL_DAYS: z.coerce.number().default(30),

  CORS_ORIGINS: z.string().default(''),

  STORAGE_DRIVER: z.enum(['local', 's3']).default('local'),
  LOCAL_STORAGE_DIR: z.string().default('./uploads'),
  LOCAL_STORAGE_PUBLIC_URL: z.string().default('http://localhost:3333/uploads'),

  // PUSH_DRIVER=noop mantem o comportamento das Etapas 1-4 (apenas loga a
  // intencao de envio). PUSH_DRIVER=fcm exige FCM_SERVICE_ACCOUNT_PATH
  // apontando para o JSON de credenciais de uma service account do
  // Firebase (Console > Configurações do projeto > Contas de serviço >
  // Gerar nova chave privada) — nunca comitado no repositorio.
  PUSH_DRIVER: z.enum(['noop', 'fcm']).default('noop'),
  FCM_SERVICE_ACCOUNT_PATH: z.string().default('./keys/dev/firebase-service-account.json'),

  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(60_000),
  RATE_LIMIT_MAX: z.coerce.number().default(100),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().default(10)
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('Variaveis de ambiente invalidas:', parsed.error.flatten().fieldErrors);
  throw new Error('Configuracao de ambiente invalida. Verifique o arquivo .env (veja .env.example).');
}

const rawEnv = parsed.data;

function readKey(relativePath: string): string {
  const resolved = path.resolve(process.cwd(), relativePath);
  if (!fs.existsSync(resolved)) {
    throw new Error(
      `Chave JWT nao encontrada em ${resolved}. Rode "npm run keys:generate" para criar um par de chaves de desenvolvimento.`
    );
  }
  return fs.readFileSync(resolved, 'utf-8');
}

export const env = {
  ...rawEnv,
  isProduction: rawEnv.NODE_ENV === 'production',
  isTest: rawEnv.NODE_ENV === 'test',
  corsOrigins: rawEnv.CORS_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean),
  jwt: {
    get privateKey() {
      return readKey(rawEnv.JWT_PRIVATE_KEY_PATH);
    },
    get publicKey() {
      return readKey(rawEnv.JWT_PUBLIC_KEY_PATH);
    },
    accessTokenTtl: rawEnv.JWT_ACCESS_TOKEN_TTL,
    refreshTokenTtlDays: rawEnv.JWT_REFRESH_TOKEN_TTL_DAYS
  }
};
