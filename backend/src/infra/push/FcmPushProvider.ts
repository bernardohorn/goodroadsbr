import fs from 'fs';
import path from 'path';
import admin from 'firebase-admin';
import { env } from '../../config/env';
import { logger } from '../../core/logger/logger';
import { prisma } from '../database/prisma.client';
import { PushMessage, PushProvider } from './PushProvider';

/**
 * Implementacao real de `PushProvider` usando o Firebase Admin SDK. So e
 * instanciada quando PUSH_DRIVER=fcm (ver push.provider.ts) — o restante do
 * backend continua dependendo apenas da interface `PushProvider`, sem saber
 * que o FCM existe.
 *
 * Consulta os `DeviceToken` do usuario diretamente via Prisma (em vez de
 * depender de `NotificationsRepository`) para manter a camada `infra`
 * autocontida, no mesmo espirito do `LocalDiskStorageProvider` — infra nao
 * importa modulos de dominio.
 */
export class FcmPushProvider implements PushProvider {
  private app: admin.app.App | null = null;

  private getApp(): admin.app.App {
    if (this.app) return this.app;

    const resolved = path.resolve(process.cwd(), env.FCM_SERVICE_ACCOUNT_PATH);
    if (!fs.existsSync(resolved)) {
      throw new Error(
        `Credenciais do Firebase nao encontradas em ${resolved}. Gere uma service account no Console do Firebase ` +
          '(Configuracoes do projeto > Contas de servico > Gerar nova chave privada) e aponte FCM_SERVICE_ACCOUNT_PATH para o arquivo.'
      );
    }

    const serviceAccount = JSON.parse(fs.readFileSync(resolved, 'utf-8'));
    this.app = admin.apps.length
      ? (admin.apps[0] as admin.app.App)
      : admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    return this.app;
  }

  async send(message: PushMessage): Promise<void> {
    const devices = await prisma.deviceToken.findMany({ where: { userId: message.userId }, select: { token: true } });

    if (devices.length === 0) {
      logger.debug({ userId: message.userId }, '[push:fcm] usuario sem device token registrado, nada a enviar');
      return;
    }

    const tokens = devices.map((d) => d.token);

    let response: admin.messaging.BatchResponse;
    try {
      response = await admin.messaging(this.getApp()).sendEachForMulticast({
        tokens,
        notification: { title: message.title, body: message.body },
        data: message.data ?? {},
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } }
      });
    } catch (error) {
      // Uma falha no envio push nunca deve derrubar o fluxo que a
      // originou (ex.: mudanca de status de uma ocorrencia) — o registro
      // in-app ja foi salvo antes desta chamada (ver notifications.service.ts).
      logger.error({ err: error, userId: message.userId }, '[push:fcm] falha ao enviar notificacao');
      return;
    }

    await this.cleanupInvalidTokens(tokens, response);
  }

  /**
   * Remove tokens que o FCM reportou como invalidos/nao registrados —
   * tipicamente apps desinstalados ou tokens expirados. Sem essa limpeza,
   * o backend continuaria tentando (e falhando) enviar para eles para
   * sempre.
   */
  private async cleanupInvalidTokens(tokens: string[], response: admin.messaging.BatchResponse) {
    const invalidCodes = new Set(['messaging/invalid-registration-token', 'messaging/registration-token-not-registered']);
    const invalidTokens = response.responses
      .map((result, index) => (result.success ? null : { token: tokens[index], code: result.error?.code }))
      .filter((entry): entry is { token: string; code: string | undefined } => entry !== null && invalidCodes.has(entry.code ?? ''))
      .map((entry) => entry.token);

    if (invalidTokens.length > 0) {
      await prisma.deviceToken.deleteMany({ where: { token: { in: invalidTokens } } });
      logger.info({ count: invalidTokens.length }, '[push:fcm] tokens invalidos removidos');
    }
  }
}
