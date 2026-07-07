import { OccurrenceStatus, Prisma, PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export interface ReportFilters {
  status?: OccurrenceStatus;
  categoryId?: string;
  dateFrom?: Date;
  dateTo?: Date;
}

// Limite de seguranca: uma exportacao gigantesca travaria o processo Node
// (tudo e montado em memoria antes de virar CSV). 5000 linhas cobre bem o
// uso esperado de uma prefeitura de porte pequeno/medio; se isso um dia for
// insuficiente, a evolucao natural e paginar a exportacao em um job
// assincrono que grava o arquivo e notifica quando pronto.
const MAX_ROWS = 5000;

function buildWhere(filters: ReportFilters): Prisma.OccurrenceWhereInput {
  return {
    ...(filters.status ? { status: filters.status } : {}),
    ...(filters.categoryId ? { categoryId: filters.categoryId } : {}),
    ...(filters.dateFrom || filters.dateTo
      ? {
          createdAt: {
            ...(filters.dateFrom ? { gte: filters.dateFrom } : {}),
            ...(filters.dateTo ? { lte: filters.dateTo } : {})
          }
        }
      : {})
  };
}

export class ReportsRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findForExport(filters: ReportFilters) {
    return this.db.occurrence.findMany({
      where: buildWhere(filters),
      orderBy: { createdAt: 'desc' },
      take: MAX_ROWS,
      include: {
        category: { select: { name: true } },
        team: { select: { name: true } },
        citizen: { select: { name: true, email: true } },
        assignedTo: { select: { name: true } }
      }
    });
  }
}
