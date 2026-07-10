import { AppError } from '../../core/errors/AppError';
import { Citizen, CitizensRepository } from './citizens.repository';

export class CitizensService {
  constructor(private readonly repo: CitizensRepository = new CitizensRepository()) {}

  list(filters: { search?: string }, pagination: { page: number; pageSize: number }) {
    return this.repo.findAll(filters, pagination);
  }

  async getById(id: string): Promise<Citizen> {
    const citizen = await this.repo.findById(id);
    if (!citizen) {
      throw AppError.notFound('Cidadao nao encontrado.');
    }
    return citizen;
  }

  async updateStatus(id: string, active: boolean): Promise<Citizen> {
    const citizen = await this.repo.findById(id);
    if (!citizen) {
      throw AppError.notFound('Cidadao nao encontrado.');
    }
    return this.repo.updateStatus(id, active);
  }
}
