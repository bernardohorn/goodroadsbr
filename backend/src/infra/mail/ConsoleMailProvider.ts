import { logger } from '../../core/logger/logger';
import { MailMessage, MailProvider } from './MailProvider';

/**
 * Implementacao de desenvolvimento: apenas loga o e-mail que seria enviado.
 * Evita a necessidade de credenciais de um provedor real de e-mail nesta
 * etapa do projeto, mantendo o fluxo de "esqueci minha senha" testavel de
 * ponta a ponta.
 */
export class ConsoleMailProvider implements MailProvider {
  async send(message: MailMessage): Promise<void> {
    logger.info({ message }, '[mail:console] e-mail simulado');
  }
}
