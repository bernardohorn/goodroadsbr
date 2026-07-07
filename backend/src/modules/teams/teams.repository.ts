import { PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export class TeamsRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findAll(municipalityId: string | null) {
    return this.db.team.findMany({
      where: municipalityId ? { municipalityId } : undefined,
      orderBy: { name: 'asc' }
    });
  }

  create(data: { name: string; municipalityId?: string | null }) {
    return this.db.team.create({ data });
  }
}
