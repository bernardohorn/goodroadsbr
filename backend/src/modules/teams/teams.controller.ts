import { Request, Response } from 'express';
import { AppError } from '../../core/errors/AppError';
import { TeamsService } from './teams.service';

export class TeamsController {
  constructor(private readonly service: TeamsService = new TeamsService()) {}

  list = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const teams = await this.service.list(req.auth.municipalityId);
    return res.status(200).json(teams);
  };

  create = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const team = await this.service.create({ ...req.body, municipalityId: req.auth.municipalityId });
    return res.status(201).json(team);
  };
}
