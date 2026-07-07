import { AppError } from '../../core/errors/AppError';
import { CategoriesRepository } from './categories.repository';

export class CategoriesService {
  constructor(private readonly repo: CategoriesRepository = new CategoriesRepository()) {}

  list(onlyActive: boolean) {
    return this.repo.findAll(onlyActive);
  }

  async create(data: { name: string; icon?: string; color?: string }) {
    const existing = await this.repo.findByName(data.name);
    if (existing) {
      throw AppError.conflict('Ja existe uma categoria com este nome.');
    }
    return this.repo.create(data);
  }

  async update(id: string, data: { name?: string; icon?: string; color?: string; active?: boolean }) {
    const category = await this.repo.findById(id);
    if (!category) {
      throw AppError.notFound('Categoria nao encontrada.');
    }
    return this.repo.update(id, data);
  }
}
