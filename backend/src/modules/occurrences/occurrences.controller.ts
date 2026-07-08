import { Request, Response } from 'express';
import { AppError } from '../../core/errors/AppError';
import { OccurrencesService } from './occurrences.service';

export class OccurrencesController {
  constructor(private readonly service: OccurrencesService = new OccurrencesService()) {}

  create = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const files = (req.files as Express.Multer.File[] | undefined) ?? [];
    const occurrence = await this.service.create(req.auth, req.body, files);
    return res.status(201).json(occurrence);
  };

  list = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const { page, pageSize, sortBy, sortOrder, ...filters } = req.query as unknown as {
      status?: 'PENDENTE' | 'EM_ANDAMENTO' | 'RESOLVIDA' | 'CANCELADA';
      priority?: 'BAIXA' | 'MEDIA' | 'ALTA' | 'URGENTE';
      categoryId?: string;
      search?: string;
      page: number;
      pageSize: number;
      sortBy: 'createdAt' | 'updatedAt' | 'priority' | 'status';
      sortOrder: 'asc' | 'desc';
    };
    const result = await this.service.list(req.auth, filters, { page, pageSize, sortBy, sortOrder });
    return res.status(200).json(result);
  };

  getById = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const occurrence = await this.service.getById(req.auth, req.params.id);
    return res.status(200).json(occurrence);
  };

  updateStatus = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const occurrence = await this.service.updateStatus(req.auth, req.params.id, req.body);
    return res.status(200).json(occurrence);
  };

  updateDetails = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const occurrence = await this.service.updateDetails(req.auth, req.params.id, req.body);
    return res.status(200).json(occurrence);
  };

  getHistory = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const history = await this.service.getHistory(req.auth, req.params.id);
    return res.status(200).json(history);
  };
}
