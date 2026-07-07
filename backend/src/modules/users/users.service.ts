import { AppError } from '../../core/errors/AppError';
import { UsersRepository } from './users.repository';

function sanitize<T extends { passwordHash: string }>(user: T) {
  const { passwordHash: _passwordHash, ...safe } = user;
  return safe;
}

export class UsersService {
  constructor(private readonly repo: UsersRepository = new UsersRepository()) {}

  async getMe(userId: string) {
    const user = await this.repo.findById(userId);
    if (!user) {
      throw AppError.notFound('Usuario nao encontrado.');
    }
    return sanitize(user);
  }

  async updateMe(userId: string, data: { name?: string; phone?: string; avatarUrl?: string }) {
    const user = await this.repo.update(userId, data);
    return sanitize(user);
  }
}
