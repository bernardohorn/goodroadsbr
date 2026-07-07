import { ConsoleMailProvider } from './ConsoleMailProvider';
import { MailProvider } from './MailProvider';

// Trocar pela implementacao real (SES/SendGrid/Postmark) quando o dominio de
// envio de e-mail transacional da prefeitura for definido.
export const mailProvider: MailProvider = new ConsoleMailProvider();
