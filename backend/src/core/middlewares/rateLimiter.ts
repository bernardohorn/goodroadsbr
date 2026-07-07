import rateLimit from 'express-rate-limit';
import { env } from '../../config/env';

/**
 * Rate limit padrao para toda a API. Usa armazenamento em memoria por
 * padrao (adequado para uma unica instancia). Ao escalar horizontalmente
 * para multiplas instancias, trocar por um `RedisStore`
 * (`rate-limit-redis`) e a unica mudanca necessaria aqui — a assinatura do
 * middleware para o resto da aplicacao nao muda.
 */
export const defaultRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false
});

/**
 * Rate limit mais agressivo para rotas sensiveis (`/auth/*`), reduzindo a
 * superficie de ataques de forca bruta contra login e reset de senha.
 */
export const authRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.AUTH_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Muitas tentativas. Tente novamente em instantes.' } }
});
