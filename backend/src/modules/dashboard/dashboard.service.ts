import { OccurrenceStatus } from '@prisma/client';
import { DashboardRepository } from './dashboard.repository';

const ALL_STATUSES: OccurrenceStatus[] = ['PENDENTE', 'EM_ANDAMENTO', 'RESOLVIDA', 'CANCELADA'];

export class DashboardService {
  constructor(private readonly repo: DashboardRepository = new DashboardRepository()) {}

  async getStats() {
    const [byStatus, byCategory, monthlySeries, recent, totalCitizens, categories] = await Promise.all([
      this.repo.countByStatus(),
      this.repo.countByCategory(),
      this.repo.monthlySeries(),
      this.repo.recent(5),
      this.repo.totalCitizens(),
      this.repo.categoryNames()
    ]);
    const categoryNameById = new Map(categories.map((c) => [c.id, c.name]));

    const statusCounts = Object.fromEntries(ALL_STATUSES.map((s) => [s, 0])) as Record<OccurrenceStatus, number>;
    for (const row of byStatus) {
      statusCounts[row.status] = row._count._all;
    }
    const total = Object.values(statusCounts).reduce((sum, n) => sum + n, 0);

    return {
      cards: {
        total,
        pendentes: statusCounts.PENDENTE,
        emAndamento: statusCounts.EM_ANDAMENTO,
        resolvidas: statusCounts.RESOLVIDA,
        canceladas: statusCounts.CANCELADA,
        totalCidadaos: totalCitizens
      },
      occurrencesByStatus: statusCounts,
      occurrencesByCategory: byCategory.map((row) => ({
        categoryId: row.categoryId,
        categoryName: row.categoryId ? categoryNameById.get(row.categoryId) ?? 'Sem categoria' : 'Sem categoria',
        total: row._count._all
      })),
      occurrencesByMonth: monthlySeries,
      recent
    };
  }
}
