import argon2 from 'argon2';
import { RoleName } from '@prisma/client';
import { AppError } from '../../core/errors/AppError';
import { ARGON2_OPTIONS } from '../../config/constants';
import { StaffRepository } from './staff.repository';

export class StaffService {
  constructor(private readonly repo: StaffRepository = new StaffRepository()) {}

  list(filters: { search?: string; role?: RoleName }) {
    return this.repo.findAll(filters);
  }

  async getById(id: string) {
    const staff = await this.repo.findById(id);
    if (!staff) {
      throw AppError.notFound('Funcionario nao encontrado.');
    }
    return staff;
  }

  async create(
    data: { name: string; email: string; phone?: string; password: string; role: RoleName },
    context: { municipalityId: string | null }
  ) {
    const existing = await this.repo.findByEmail(data.email);
    if (existing) {
      throw AppError.conflict('Ja existe um usuario cadastrado com este e-mail.');
    }
    const role = await this.repo.findRoleByName(data.role);
    const passwordHash = await argon2.hash(data.password, { type: argon2.argon2id, ...ARGON2_OPTIONS });
    return this.repo.create({
      name: data.name,
      email: data.email,
      phone: data.phone,
      passwordHash,
      roleId: role.id,
      municipalityId: context.municipalityId
    });
  }

  async update(id: string, data: { name?: string; phone?: string; role?: RoleName; active?: boolean }) {
    const staff = await this.repo.findById(id);
    if (!staff) {
      throw AppError.notFound('Funcionario nao encontrado.');
    }
    let roleId: string | undefined;
    if (data.role) {
      roleId = (await this.repo.findRoleByName(data.role)).id;
    }
    return this.repo.update(id, { name: data.name, phone: data.phone, roleId, active: data.active });
  }
}
