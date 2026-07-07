import { Prisma, PrismaClient, RoleName } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

const staffSelect = Prisma.validator<Prisma.UserSelect>()({
  id: true,
  name: true,
  email: true,
  phone: true,
  avatarUrl: true,
  active: true,
  createdAt: true,
  role: { select: { name: true } }
});

export type StaffMember = Prisma.UserGetPayload<{ select: typeof staffSelect }>;

export class StaffRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findByEmail(email: string) {
    return this.db.user.findUnique({ where: { email } });
  }

  findRoleByName(name: RoleName) {
    return this.db.role.findUniqueOrThrow({ where: { name } });
  }

  async findAll(filters: { search?: string; role?: RoleName }): Promise<StaffMember[]> {
    return this.db.user.findMany({
      where: {
        role: { name: { in: filters.role ? [filters.role] : [RoleName.FUNCIONARIO, RoleName.ADMIN] } },
        ...(filters.search
          ? {
              OR: [
                { name: { contains: filters.search, mode: 'insensitive' } },
                { email: { contains: filters.search, mode: 'insensitive' } }
              ]
            }
          : {})
      },
      select: staffSelect,
      orderBy: { name: 'asc' }
    });
  }

  findById(id: string): Promise<StaffMember | null> {
    return this.db.user.findUnique({ where: { id }, select: staffSelect });
  }

  create(data: { name: string; email: string; phone?: string; passwordHash: string; roleId: string; municipalityId?: string | null }) {
    return this.db.user.create({ data, select: staffSelect });
  }

  update(id: string, data: { name?: string; phone?: string; roleId?: string; active?: boolean }) {
    return this.db.user.update({ where: { id }, data, select: staffSelect });
  }
}
