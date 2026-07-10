import { Request, Response } from 'express';
import { CitizensService } from './citizens.service';

export class CitizensController {
  constructor(private readonly service: CitizensService = new CitizensService()) {}

  list = async (req: Request, res: Response) => {
    const { search, page, pageSize } = req.query as unknown as {
      search?: string;
      page: number;
      pageSize: number;
    };
    const result = await this.service.list({ search }, { page, pageSize });
    return res.status(200).json(result);
  };

  getById = async (req: Request, res: Response) => {
    const citizen = await this.service.getById(req.params.id);
    return res.status(200).json(citizen);
  };

  updateStatus = async (req: Request, res: Response) => {
    const citizen = await this.service.updateStatus(req.params.id, req.body.active as boolean);
    return res.status(200).json(citizen);
  };
}
