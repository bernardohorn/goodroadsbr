import { Request, Response } from 'express';
import { OccurrenceStatus } from '@prisma/client';
import { ReportsService } from './reports.service';

export class ReportsController {
  constructor(private readonly service: ReportsService = new ReportsService()) {}

  export = async (req: Request, res: Response) => {
    const query = req.query as {
      format: 'csv' | 'pdf';
      status?: OccurrenceStatus;
      categoryId?: string;
      dateFrom?: string;
      dateTo?: string;
    };

    const filters = {
      status: query.status,
      categoryId: query.categoryId,
      dateFrom: query.dateFrom ? new Date(query.dateFrom) : undefined,
      dateTo: query.dateTo ? new Date(query.dateTo) : undefined
    };

    const date = new Date().toISOString().slice(0, 10);

    if (query.format === 'pdf') {
      const pdf = await this.service.exportPdf(filters);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="ocorrencias-${date}.pdf"`);
      return res.status(200).send(pdf);
    }

    const csv = await this.service.exportCsv(filters);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="ocorrencias-${date}.csv"`);
    return res.status(200).send(csv);
  };
}
