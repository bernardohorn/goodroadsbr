import { PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export class CategoriesRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findAll(onlyActive: boolean) {
    return this.db.category.findMany({
      where: onlyActive ? { active: true } : undefined,
      orderBy: { name: 'asc' }
    });
  }

  findById(id: string) {
    return this.db.category.findUnique({ where: { id } });
  }

  findByName(name: string) {
    return this.db.category.findUnique({ where: { name } });
  }

  create(data: { name: string; icon?: string; color?: string }) {
    return this.db.category.create({ data });
  }

  update(id: string, data: { name?: string; icon?: string; color?: string; active?: boolean }) {
    return this.db.category.update({ where: { id }, data });
  }
}
