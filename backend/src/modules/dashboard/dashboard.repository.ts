import { PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export interface MonthlyCount {
  month: string; // 'YYYY-MM'
  total: number;
}

export class DashboardRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  countByStatus() {
    return this.db.occurrence.groupBy({ by: ['status'], _count: { _all: true } });
  }

  countByCategory() {
    return this.db.occurrence.groupBy({ by: ['categoryId'], _count: { _all: true } });
  }

  /**
   * Serie mensal dos ultimos 6 meses (incluindo o atual). `date_trunc` +
   * `generate_series` garante que meses sem nenhuma ocorrencia apareçam
   * com total 0 em vez de sumirem do grafico.
   */
  async monthlySeries(): Promise<MonthlyCount[]> {
    const rows = await this.db.$queryRaw<{ month: string; total: bigint }[]>`
      SELECT to_char(months.month, 'YYYY-MM') AS month, COUNT(o.id)::int AS total
      FROM generate_series(
        date_trunc('month', now()) - interval '5 months',
        date_trunc('month', now()),
        interval '1 month'
      ) AS months(month)
      LEFT JOIN occurrences o
        ON date_trunc('month', o."created_at") = months.month
      GROUP BY months.month
      ORDER BY months.month
    `;
    return rows.map((r) => ({ month: r.month, total: Number(r.total) }));
  }

  recent(limit: number) {
    return this.db.occurrence.findMany({
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        category: true,
        citizen: { select: { id: true, name: true } }
      }
    });
  }

  totalCitizens() {
    return this.db.user.count({ where: { role: { name: 'CIDADAO' } } });
  }

  categoryNames() {
    return this.db.category.findMany({ select: { id: true, name: true } });
  }
}
