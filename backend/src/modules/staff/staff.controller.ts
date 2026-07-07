import { Request, Response } from 'express';
import { AppError } from '../../core/errors/AppError';
import { StaffService } from './staff.service';

export class StaffController {
  constructor(private readonly service: StaffService = new StaffService()) {}

  list = async (req: Request, res: Response) => {
    const { search, role } = req.query as { search?: string; role?: 'FUNCIONARIO' | 'ADMIN' };
    const staff = await this.service.list({ search, role });
    return res.status(200).json(staff);
  };

  getById = async (req: Request, res: Response) => {
    const staff = await this.service.getById(req.params.id);
    return res.status(200).json(staff);
  };

  create = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const staff = await this.service.create(req.body, { municipalityId: req.auth.municipalityId });
    return res.status(201).json(staff);
  };

  update = async (req: Request, res: Response) => {
    const staff = await this.service.update(req.params.id, req.body);
    return res.status(200).json(staff);
  };
}
