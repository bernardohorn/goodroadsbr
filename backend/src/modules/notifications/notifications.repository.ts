import { NotificationType, PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export class NotificationsRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  create(data: { userId: string; occurrenceId?: string; title: string; body: string; type?: NotificationType }) {
    return this.db.notification.create({ data });
  }

  async findManyForUser(userId: string, params: { unreadOnly: boolean; page: number; pageSize: number }) {
    const where = { userId, ...(params.unreadOnly ? { read: false } : {}) };
    const [items, total] = await this.db.$transaction([
      this.db.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (params.page - 1) * params.pageSize,
        take: params.pageSize
      }),
      this.db.notification.count({ where })
    ]);
    return { items, total };
  }

  findById(id: string) {
    return this.db.notification.findUnique({ where: { id } });
  }

  markRead(id: string) {
    return this.db.notification.update({ where: { id }, data: { read: true } });
  }

  // --- Device tokens (FCM) --------------------------------------------------

  /**
   * Upsert por token: se o mesmo device registrar de novo (reinstalou o
   * app, por exemplo), atualizamos o dono em vez de duplicar. Isso tambem
   * cobre o caso de um token que pertencia a outro usuario no mesmo device
   * (ex.: logout de uma conta, login em outra) — o token passa a apontar
   * para quem esta logado agora.
   */
  upsertDeviceToken(data: { userId: string; token: string; platform?: string }) {
    return this.db.deviceToken.upsert({
      where: { token: data.token },
      update: { userId: data.userId, platform: data.platform },
      create: data
    });
  }

  removeDeviceToken(token: string) {
    return this.db.deviceToken.deleteMany({ where: { token } });
  }

  findDeviceTokensByUserId(userId: string) {
    return this.db.deviceToken.findMany({ where: { userId }, select: { token: true } });
  }

  removeDeviceTokensByValue(tokens: string[]) {
    if (tokens.length === 0) return Promise.resolve({ count: 0 });
    return this.db.deviceToken.deleteMany({ where: { token: { in: tokens } } });
  }
}
