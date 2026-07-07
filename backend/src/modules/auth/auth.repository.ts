import { Prisma, PrismaClient, RoleName } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

const userWithRole = Prisma.validator<Prisma.UserDefaultArgs>()({
  include: { role: true }
});

export type UserWithRole = Prisma.UserGetPayload<typeof userWithRole>;

/**
 * Unica camada que fala com o Prisma para o dominio de autenticacao. Se o
 * ORM for trocado no futuro, apenas este arquivo (e os demais
 * `*.repository.ts`) precisam mudar.
 */
export class AuthRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findUserByEmail(email: string): Promise<UserWithRole | null> {
    return this.db.user.findUnique({ where: { email }, ...userWithRole });
  }

  findUserById(id: string): Promise<UserWithRole | null> {
    return this.db.user.findUnique({ where: { id }, ...userWithRole });
  }

  findRoleByName(name: RoleName) {
    return this.db.role.findUniqueOrThrow({ where: { name } });
  }

  createCitizen(data: {
    name: string;
    email: string;
    passwordHash: string;
    cpf?: string;
    birthDate?: Date;
    phone?: string;
    roleId: string;
  }): Promise<UserWithRole> {
    return this.db.user.create({
      data: {
        name: data.name,
        email: data.email,
        passwordHash: data.passwordHash,
        cpf: data.cpf,
        birthDate: data.birthDate,
        phone: data.phone,
        roleId: data.roleId
      },
      ...userWithRole
    });
  }

  updatePassword(userId: string, passwordHash: string) {
    return this.db.user.update({ where: { id: userId }, data: { passwordHash } });
  }

  // --- Refresh tokens -------------------------------------------------

  createRefreshToken(data: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
    userAgent?: string;
    ipAddress?: string;
  }) {
    return this.db.refreshToken.create({ data });
  }

  findRefreshTokenByHash(tokenHash: string) {
    return this.db.refreshToken.findUnique({ where: { tokenHash } });
  }

  revokeRefreshToken(id: string, replacedBy?: string) {
    return this.db.refreshToken.update({
      where: { id },
      data: { revokedAt: new Date(), replacedBy }
    });
  }

  revokeAllUserRefreshTokens(userId: string) {
    return this.db.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() }
    });
  }

  // --- Password reset ---------------------------------------------------

  createPasswordResetToken(data: { userId: string; tokenHash: string; expiresAt: Date }) {
    return this.db.passwordResetToken.create({ data });
  }

  findPasswordResetTokenByHash(tokenHash: string) {
    return this.db.passwordResetToken.findUnique({ where: { tokenHash } });
  }

  markPasswordResetTokenUsed(id: string) {
    return this.db.passwordResetToken.update({ where: { id }, data: { usedAt: new Date() } });
  }
}
