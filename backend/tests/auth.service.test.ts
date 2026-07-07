import argon2 from 'argon2';
import { RoleName } from '@prisma/client';
import { AuthService } from '../src/modules/auth/auth.service';
import { AuthRepository, UserWithRole } from '../src/modules/auth/auth.repository';
import { AppError } from '../src/core/errors/AppError';

type MockedRepo = {
  [K in keyof AuthRepository]: jest.Mock;
};

function createMockRepo(): MockedRepo {
  return {
    findUserByEmail: jest.fn(),
    findUserById: jest.fn(),
    findRoleByName: jest.fn(),
    createCitizen: jest.fn(),
    updatePassword: jest.fn(),
    createRefreshToken: jest.fn(),
    findRefreshTokenByHash: jest.fn(),
    revokeRefreshToken: jest.fn(),
    revokeAllUserRefreshTokens: jest.fn(),
    createPasswordResetToken: jest.fn(),
    findPasswordResetTokenByHash: jest.fn(),
    markPasswordResetTokenUsed: jest.fn()
  } as unknown as MockedRepo;
}

async function buildUser(overrides: Partial<UserWithRole> = {}, plainPassword = 'Senha@123'): Promise<UserWithRole> {
  const passwordHash = await argon2.hash(plainPassword, { type: argon2.argon2id });
  return {
    id: 'user-1',
    municipalityId: null,
    roleId: 'role-cidadao',
    name: 'Maria Cidada',
    email: 'maria@example.com',
    passwordHash,
    cpf: null,
    birthDate: null,
    phone: null,
    avatarUrl: null,
    active: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    role: { id: 'role-cidadao', name: RoleName.CIDADAO },
    ...overrides
  } as UserWithRole;
}

describe('AuthService', () => {
  let repo: MockedRepo;
  let service: AuthService;

  beforeEach(() => {
    repo = createMockRepo();
    service = new AuthService(repo as unknown as AuthRepository);
  });

  describe('register', () => {
    it('cria um cidadao com senha em hash e retorna tokens', async () => {
      repo.findUserByEmail.mockResolvedValue(null);
      repo.findRoleByName.mockResolvedValue({ id: 'role-cidadao', name: RoleName.CIDADAO });
      const createdUser = await buildUser();
      repo.createCitizen.mockResolvedValue(createdUser);

      const result = await service.register({
        name: 'Maria Cidada',
        email: 'maria@example.com',
        password: 'Senha@123'
      });

      expect(repo.createCitizen).toHaveBeenCalledTimes(1);
      const createArgs = repo.createCitizen.mock.calls[0][0];
      expect(createArgs.passwordHash).not.toBe('Senha@123');
      expect(await argon2.verify(createArgs.passwordHash, 'Senha@123')).toBe(true);

      expect(result.user).not.toHaveProperty('passwordHash');
      expect(result.accessToken).toEqual(expect.any(String));
      expect(result.refreshToken).toEqual(expect.any(String));
      expect(repo.createRefreshToken).toHaveBeenCalledTimes(1);
    });

    it('rejeita cadastro com e-mail ja existente', async () => {
      repo.findUserByEmail.mockResolvedValue(await buildUser());

      await expect(
        service.register({ name: 'Maria', email: 'maria@example.com', password: 'Senha@123' })
      ).rejects.toMatchObject({ code: 'CONFLICT' } satisfies Partial<AppError>);

      expect(repo.createCitizen).not.toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('autentica com credenciais corretas', async () => {
      const user = await buildUser();
      repo.findUserByEmail.mockResolvedValue(user);

      const result = await service.login({ email: user.email, password: 'Senha@123' });

      expect(result.user.id).toBe(user.id);
      expect(result.accessToken).toEqual(expect.any(String));
    });

    it('rejeita senha incorreta sem revelar se o e-mail existe', async () => {
      const user = await buildUser();
      repo.findUserByEmail.mockResolvedValue(user);

      await expect(service.login({ email: user.email, password: 'errada' })).rejects.toMatchObject({
        code: 'UNAUTHORIZED'
      });
    });

    it('rejeita login de usuario inexistente com a mesma mensagem generica', async () => {
      repo.findUserByEmail.mockResolvedValue(null);

      await expect(
        service.login({ email: 'ninguem@example.com', password: 'qualquer' })
      ).rejects.toMatchObject({ code: 'UNAUTHORIZED' });
    });

    it('rejeita login de usuario inativo', async () => {
      const user = await buildUser({ active: false });
      repo.findUserByEmail.mockResolvedValue(user);

      await expect(service.login({ email: user.email, password: 'Senha@123' })).rejects.toMatchObject({
        code: 'FORBIDDEN'
      });
    });
  });

  describe('refresh', () => {
    it('rotaciona o refresh token valido e emite um novo par', async () => {
      const user = await buildUser();
      repo.findRefreshTokenByHash.mockResolvedValue({
        id: 'rt-1',
        userId: user.id,
        tokenHash: 'hash',
        revokedAt: null,
        expiresAt: new Date(Date.now() + 60_000),
        userAgent: null,
        ipAddress: null,
        replacedBy: null,
        createdAt: new Date()
      });
      repo.findUserById.mockResolvedValue(user);

      const result = await service.refresh('token-valido');

      expect(repo.revokeRefreshToken).toHaveBeenCalledWith('rt-1', expect.any(String));
      expect(result.accessToken).toEqual(expect.any(String));
    });

    it('detecta reuso de refresh token ja revogado e derruba toda a sessao', async () => {
      repo.findRefreshTokenByHash.mockResolvedValue({
        id: 'rt-1',
        userId: 'user-1',
        tokenHash: 'hash',
        revokedAt: new Date(),
        expiresAt: new Date(Date.now() + 60_000),
        userAgent: null,
        ipAddress: null,
        replacedBy: 'rt-2',
        createdAt: new Date()
      });

      await expect(service.refresh('token-reusado')).rejects.toMatchObject({ code: 'UNAUTHORIZED' });
      expect(repo.revokeAllUserRefreshTokens).toHaveBeenCalledWith('user-1');
    });

    it('rejeita refresh token expirado', async () => {
      repo.findRefreshTokenByHash.mockResolvedValue({
        id: 'rt-1',
        userId: 'user-1',
        tokenHash: 'hash',
        revokedAt: null,
        expiresAt: new Date(Date.now() - 1000),
        userAgent: null,
        ipAddress: null,
        replacedBy: null,
        createdAt: new Date()
      });

      await expect(service.refresh('token-expirado')).rejects.toMatchObject({ code: 'UNAUTHORIZED' });
    });
  });

  describe('forgotPassword / resetPassword', () => {
    it('gera um token de reset apenas quando o e-mail existe', async () => {
      repo.findUserByEmail.mockResolvedValueOnce(await buildUser());
      await service.forgotPassword('maria@example.com');
      expect(repo.createPasswordResetToken).toHaveBeenCalledTimes(1);

      repo.findUserByEmail.mockResolvedValueOnce(null);
      await service.forgotPassword('ninguem@example.com');
      expect(repo.createPasswordResetToken).toHaveBeenCalledTimes(1); // nao incrementou
    });

    it('redefine a senha e revoga todas as sessoes com token valido', async () => {
      repo.findPasswordResetTokenByHash.mockResolvedValue({
        id: 'prt-1',
        userId: 'user-1',
        tokenHash: 'hash',
        expiresAt: new Date(Date.now() + 60_000),
        usedAt: null,
        createdAt: new Date()
      });

      await service.resetPassword('token-valido', 'NovaSenha@123');

      expect(repo.updatePassword).toHaveBeenCalledWith('user-1', expect.any(String));
      expect(repo.markPasswordResetTokenUsed).toHaveBeenCalledWith('prt-1');
      expect(repo.revokeAllUserRefreshTokens).toHaveBeenCalledWith('user-1');
    });

    it('rejeita token de reset ja utilizado', async () => {
      repo.findPasswordResetTokenByHash.mockResolvedValue({
        id: 'prt-1',
        userId: 'user-1',
        tokenHash: 'hash',
        expiresAt: new Date(Date.now() + 60_000),
        usedAt: new Date(),
        createdAt: new Date()
      });

      await expect(service.resetPassword('token-usado', 'NovaSenha@123')).rejects.toMatchObject({
        code: 'UNAUTHORIZED'
      });
    });
  });
});
