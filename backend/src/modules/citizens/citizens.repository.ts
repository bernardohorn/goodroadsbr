import { Prisma, PrismaClient, RoleName } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

const citizenSelect = Prisma.validator<Prisma.UserSelect>()({
  id: true,
  name: true,
  email: true,
  phone: true,
  cpf: true,
  avatarUrl: true,
  active: true,
  createdAt: true
});

export type Citizen = Prisma.UserGetPayload<{ select: typeof citizenSelect }>;

export class CitizensRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  async findAll(
    filters: { search?: string },
    pagination: { page: number; pageSize: number }
  ): Promise<{ items: Citizen[]; total: number }> {
    const where: Prisma.UserWhereInput = {
      role: { name: RoleName.CIDADAO },
      ...(filters.search
        ? {
            OR: [
              { name: { contains: filters.search, mode: 'insensitive' } },
              { email: { contains: filters.search, mode: 'insensitive' } }
            ]
          }
        : {})
    };

    const [items, total] = await this.db.$transaction([
      this.db.user.findMany({
        where,
        select: citizenSelect,
        orderBy: { name: 'asc' },
        skip: (pagination.page - 1) * pagination.pageSize,
        take: pagination.pageSize
      }),
      this.db.user.count({ where })
    ]);

    return { items, total };
  }

  findById(id: string): Promise<Citizen | null> {
    return this.db.user.findFirst({ where: { id, role: { name: RoleName.CIDADAO } }, select: citizenSelect });
  }

  updateStatus(id: string, active: boolean): Promise<Citizen> {
    return this.db.user.update({ where: { id }, data: { active }, select: citizenSelect });
  }
}
