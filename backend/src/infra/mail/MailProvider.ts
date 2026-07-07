export interface MailMessage {
  to: string;
  subject: string;
  html: string;
}

/**
 * Interface de envio de e-mail (usada pelo fluxo de recuperacao de senha).
 * Segue o mesmo padrao de abstracao de StorageProvider/PushProvider para
 * permitir trocar o provedor (SES, SendGrid, Postmark...) sem alterar o
 * modulo de auth.
 */
export interface MailProvider {
  send(message: MailMessage): Promise<void>;
}
