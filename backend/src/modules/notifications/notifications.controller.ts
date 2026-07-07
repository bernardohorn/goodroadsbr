import { Request, Response } from 'express';
import { AppError } from '../../core/errors/AppError';
import { NotificationsService } from './notifications.service';

export class NotificationsController {
  constructor(private readonly service: NotificationsService = new NotificationsService()) {}

  list = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const { unreadOnly, page, pageSize } = req.query as unknown as {
      unreadOnly: boolean;
      page: number;
      pageSize: number;
    };
    const result = await this.service.listForUser(req.auth.userId, { unreadOnly, page, pageSize });
    return res.status(200).json(result);
  };

  markRead = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const notification = await this.service.markRead(req.auth.userId, req.params.id);
    return res.status(200).json(notification);
  };

  registerDevice = async (req: Request, res: Response) => {
    if (!req.auth) throw AppError.unauthorized();
    const { token, platform } = req.body as { token: string; platform?: string };
    await this.service.registerDevice(req.auth.userId, { token, platform });
    return res.status(204).send();
  };

  unregisterDevice = async (req: Request, res: Response) => {
    const { token } = req.body as { token: string };
    await this.service.unregisterDevice(token);
    return res.status(204).send();
  };
}
