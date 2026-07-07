import { Request, Response } from 'express';
import { AppError } from '../../core/errors/AppError';
import { UsersService } from './users.service';

export class UsersController {
  constructor(private readonly service: UsersService = new UsersService()) {}

  getMe = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const user = await this.service.getMe(req.auth.userId);
    return res.status(200).json(user);
  };

  updateMe = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const user = await this.service.updateMe(req.auth.userId, req.body);
    return res.status(200).json(user);
  };
}
