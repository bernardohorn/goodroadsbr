import { Request, Response } from 'express';
import { MapService } from './map.service';

export class MapController {
  constructor(private readonly service: MapService = new MapService()) {}

  search = async (req: Request, res: Response) => {
    const { north, south, east, west, status, categoryId } = req.query as unknown as {
      north: number;
      south: number;
      east: number;
      west: number;
      status?: string;
      categoryId?: string;
    };
    const pins = await this.service.findInBoundingBox({ north, south, east, west }, { status, categoryId });
    return res.status(200).json({ items: pins });
  };
}
