import { PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export class UsersRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findById(id: string) {
    return this.db.user.findUnique({ where: { id }, include: { role: true } });
  }

  update(id: string, data: { name?: string; phone?: string; avatarUrl?: string }) {
    return this.db.user.update({ where: { id }, data, include: { role: true } });
  }
}
