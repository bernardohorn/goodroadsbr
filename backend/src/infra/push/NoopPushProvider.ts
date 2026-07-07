import { logger } from '../../core/logger/logger';
import { PushMessage, PushProvider } from './PushProvider';

/**
 * Implementacao provisoria usada ate o modulo de notificacoes (Etapa 5)
 * integrar de fato com o Firebase Admin SDK. Mantem o restante do sistema
 * funcional e testavel sem exigir credenciais do FCM nesta etapa.
 */
export class NoopPushProvider implements PushProvider {
  async send(message: PushMessage): Promise<void> {
    logger.info({ message }, '[push:noop] notificacao nao enviada (FCM ainda nao configurado)');
  }
}
