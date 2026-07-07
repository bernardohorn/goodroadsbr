import { Request, Response } from 'express';
import { DashboardService } from './dashboard.service';

export class DashboardController {
  constructor(private readonly service: DashboardService = new DashboardService()) {}

  getStats = async (_req: Request, res: Response) => {
    const stats = await this.service.getStats();
    return res.status(200).json(stats);
  };
}
