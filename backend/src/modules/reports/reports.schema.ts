import { z } from 'zod';

export const exportReportSchema = {
  query: z.object({
    format: z.enum(['csv', 'pdf']).default('csv'),
    status: z.enum(['PENDENTE', 'EM_ANDAMENTO', 'RESOLVIDA', 'CANCELADA']).optional(),
    categoryId: z.string().uuid().optional(),
    dateFrom: z.string().datetime().optional(),
    dateTo: z.string().datetime().optional()
  })
};
