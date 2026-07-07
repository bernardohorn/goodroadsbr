import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { createHash, randomBytes } from 'crypto';
import { RoleName } from '@prisma/client';
import { env } from '../../config/env';
import { ARGON2_OPTIONS, PASSWORD_RESET_TOKEN_TTL_MINUTES } from '../../config/constants';
import { AppError } from '../../core/errors/AppError';
import { logger } from '../../core/logger/logger';
import { mailProvider } from '../../infra/mail/mail.provider';
import { AuthRepository, UserWithRole } from './auth.repository';

interface RequestContext {
  userAgent?: string;
  ipAddress?: string;
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

function sanitizeUser(user: UserWithRole) {
  const { passwordHash: _passwordHash, ...safe } = user;
  return safe;
}

function hashOpaqueToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/**
 * Regras de negocio de autenticacao. Nao conhece Express nem Prisma
 * diretamente (Prisma fica isolado em AuthRepository) — o que torna esta
 * classe testavel com um repository mockado, sem precisar de um banco real
 * (ver tests/auth.service.test.ts).
 */
export class AuthService {
  constructor(private readonly repo: AuthRepository = new AuthRepository()) {}

  async register(
    input: {
      name: string;
      email: string;
      password: string;
      cpf?: string;
      birthDate?: Date;
      phone?: string;
    },
    context: RequestContext = {}
  ) {
    const existing = await this.repo.findUserByEmail(input.email);
    if (existing) {
      throw AppError.conflict('Ja existe uma conta cadastrada com este e-mail.');
    }

    const citizenRole = await this.repo.findRoleByName(RoleName.CIDADAO);
    const passwordHash = await argon2.hash(input.password, {
      type: argon2.argon2id,
      ...ARGON2_OPTIONS
    });

    const user = await this.repo.createCitizen({
      name: input.name,
      email: input.email,
      passwordHash,
      cpf: input.cpf,
      birthDate: input.birthDate,
      phone: input.phone,
      roleId: citizenRole.id
    });

    const tokens = await this.issueTokenPair(user, context);
    return { user: sanitizeUser(user), ...tokens };
  }

  async login(input: { email: string; password: string }, context: RequestContext = {}) {
    const user = await this.repo.findUserByEmail(input.email);

    // Mensagem generica em ambos os casos (usuario inexistente / senha
    // errada) para nao permitir enumeracao de e-mails cadastrados.
    const invalidCredentials = () => AppError.unauthorized('E-mail ou senha invalidos.');

    if (!user) {
      // Ainda assim, gasta um hash "decoy" para manter o tempo de resposta
      // proximo do caso de usuario existente (mitigacao simples de timing attack).
      await argon2.hash(input.password, { type: argon2.argon2id, ...ARGON2_OPTIONS });
      throw invalidCredentials();
    }

    if (!user.active) {
      throw AppError.forbidden('Esta conta esta desativada. Contate a prefeitura.');
    }

    const passwordMatches = await argon2.verify(user.passwordHash, input.password);
    if (!passwordMatches) {
      throw invalidCredentials();
    }

    const tokens = await this.issueTokenPair(user, context);
    return { user: sanitizeUser(user), ...tokens };
  }

  async refresh(refreshTokenPlain: string, context: RequestContext = {}) {
    const tokenHash = hashOpaqueToken(refreshTokenPlain);
    const stored = await this.repo.findRefreshTokenByHash(tokenHash);

    if (!stored) {
      throw AppError.unauthorized('Refresh token invalido.');
    }

    if (stored.revokedAt) {
      // Reuso de um refresh token ja revogado/rotacionado e um forte indicio
      // de que o token vazou. Por seguranca, revogamos TODA a sessao do
      // usuario, forcando um novo login em todos os dispositivos.
      await this.repo.revokeAllUserRefreshTokens(stored.userId);
      logger.warn({ userId: stored.userId }, 'Reuso de refresh token detectado — sessao revogada');
      throw AppError.unauthorized('Sessao invalida. Faca login novamente.');
    }

    if (stored.expiresAt.getTime() < Date.now()) {
      throw AppError.unauthorized('Refresh token expirado. Faca login novamente.');
    }

    const user = await this.repo.findUserById(stored.userId);
    if (!user || !user.active) {
      throw AppError.unauthorized('Usuario nao encontrado ou inativo.');
    }

    const tokens = await this.issueTokenPair(user, context);

    // Rotaciona: o token antigo e marcado como revogado e vinculado ao novo,
    // permitindo detectar reuso caso o antigo seja reapresentado depois.
    await this.repo.revokeRefreshToken(stored.id, hashOpaqueToken(tokens.refreshToken));

    return { user: sanitizeUser(user), ...tokens };
  }

  async logout(refreshTokenPlain: string) {
    const tokenHash = hashOpaqueToken(refreshTokenPlain);
    const stored = await this.repo.findRefreshTokenByHash(tokenHash);
    if (stored && !stored.revokedAt) {
      await this.repo.revokeRefreshToken(stored.id);
    }
  }

  async forgotPassword(email: string) {
    const user = await this.repo.findUserByEmail(email);

    // Resposta sempre "de sucesso" no controller, exista ou nao o e-mail —
    // evita que o endpoint seja usado para descobrir quais e-mails estao cadastrados.
    if (!user) {
      logger.info({ email }, 'forgotPassword: e-mail nao cadastrado (resposta silenciosa)');
      return;
    }

    const plainToken = randomBytes(32).toString('hex');
    const tokenHash = hashOpaqueToken(plainToken);
    const expiresAt = new Date(Date.now() + PASSWORD_RESET_TOKEN_TTL_MINUTES * 60_000);

    await this.repo.createPasswordResetToken({ userId: user.id, tokenHash, expiresAt });

    await mailProvider.send({
      to: user.email,
      subject: 'GoodRoads — Redefinicao de senha',
      html: `
        <p>Ola, ${user.name}.</p>
        <p>Use o codigo abaixo para redefinir sua senha (valido por ${PASSWORD_RESET_TOKEN_TTL_MINUTES} minutos):</p>
        <p><strong>${plainToken}</strong></p>
        <p>Se voce nao solicitou isso, ignore este e-mail.</p>
      `
    });
  }

  async resetPassword(tokenPlain: string, newPassword: string) {
    const tokenHash = hashOpaqueToken(tokenPlain);
    const stored = await this.repo.findPasswordResetTokenByHash(tokenHash);

    if (!stored || stored.usedAt || stored.expiresAt.getTime() < Date.now()) {
      throw AppError.unauthorized('Token de redefinicao invalido ou expirado.');
    }

    const passwordHash = await argon2.hash(newPassword, { type: argon2.argon2id, ...ARGON2_OPTIONS });

    await this.repo.updatePassword(stored.userId, passwordHash);
    await this.repo.markPasswordResetTokenUsed(stored.id);
    // Redefinir a senha invalida todas as sessoes ativas, por seguranca.
    await this.repo.revokeAllUserRefreshTokens(stored.userId);
  }

  // -----------------------------------------------------------------------

  private async issueTokenPair(user: UserWithRole, context: RequestContext): Promise<TokenPair> {
    const accessToken = jwt.sign(
      {
        sub: user.id,
        role: user.role.name,
        municipalityId: user.municipalityId
      },
      env.jwt.privateKey,
      { algorithm: 'RS256', expiresIn: env.jwt.accessTokenTtl as jwt.SignOptions['expiresIn'] }
    );

    const refreshTokenPlain = randomBytes(48).toString('hex');
    const expiresAt = new Date(Date.now() + env.jwt.refreshTokenTtlDays * 24 * 60 * 60 * 1000);

    await this.repo.createRefreshToken({
      userId: user.id,
      tokenHash: hashOpaqueToken(refreshTokenPlain),
      expiresAt,
      userAgent: context.userAgent,
      ipAddress: context.ipAddress
    });

    return { accessToken, refreshToken: refreshTokenPlain };
  }
}
