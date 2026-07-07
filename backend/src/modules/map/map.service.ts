import { AppError } from '../../core/errors/AppError';
import { MapRepository } from './map.repository';

export class MapService {
  constructor(private readonly repo: MapRepository = new MapRepository()) {}

  findInBoundingBox(
    bbox: { north: number; south: number; east: number; west: number },
    filters: { status?: string; categoryId?: string }
  ) {
    if (bbox.north <= bbox.south || bbox.east <= bbox.west) {
      throw AppError.validation('Bounding box invalida: north/east devem ser maiores que south/west.');
    }
    return this.repo.findInBoundingBox(bbox, filters);
  }
}
