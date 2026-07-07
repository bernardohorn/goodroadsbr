import { AppError } from '../../core/errors/AppError';
import { pushProvider } from '../../infra/push/push.provider';
import { NotificationsRepository } from './notifications.repository';

/**
 * Cria o registro de notificacao in-app (fonte de verdade, consultavel pelo
 * app) e, em paralelo, delega o envio push para `PushProvider`. Desde a
 * Etapa 5, `PushProvider` pode ser o `FcmPushProvider` real (ver
 * src/infra/push/push.provider.ts) — este service nao precisa saber disso,
 * so conhece a interface.
 */
export class NotificationsService {
  constructor(private readonly repo: NotificationsRepository = new NotificationsRepository()) {}

  async notifyStatusChange(params: { userId: string; occurrenceId: string; protocolNumber: string; newStatusLabel: string }) {
    const title = 'Atualizacao na sua ocorrencia';
    const body = `A ocorrencia ${params.protocolNumber} agora esta: ${params.newStatusLabel}.`;

    await this.repo.create({
      userId: params.userId,
      occurrenceId: params.occurrenceId,
      title,
      body,
      type: 'STATUS_CHANGE'
    });

    await pushProvider.send({ userId: params.userId, title, body, data: { occurrenceId: params.occurrenceId } });
  }

  async listForUser(userId: string, params: { unreadOnly: boolean; page: number; pageSize: number }) {
    const { items, total } = await this.repo.findManyForUser(userId, params);
    return { items, total, page: params.page, pageSize: params.pageSize };
  }

  async markRead(userId: string, notificationId: string) {
    const notification = await this.repo.findById(notificationId);
    if (!notification || notification.userId !== userId) {
      throw AppError.notFound('Notificacao nao encontrada.');
    }
    return this.repo.markRead(notificationId);
  }

  // --- Device tokens (FCM) --------------------------------------------------

  registerDevice(userId: string, data: { token: string; platform?: string }) {
    return this.repo.upsertDeviceToken({ userId, token: data.token, platform: data.platform });
  }

  async unregisterDevice(token: string) {
    await this.repo.removeDeviceToken(token);
  }
}
