import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { RoleName } from '@prisma/client';
import { env } from '../../config/env';
import { AppError } from '../errors/AppError';

interface AccessTokenPayload {
  sub: string;
  role: RoleName;
  municipalityId: string | null;
}

/**
 * Verifica o access token JWT (RS256) no header Authorization e popula
 * `req.auth`. Nao consulta o banco a cada requisicao (o payload do JWT ja
 * contem o necessario para autorizacao), o que mantem o guard rapido mesmo
 * sob alta carga.
 */
export function authGuard(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw AppError.unauthorized('Token de acesso ausente.');
  }

  const token = header.slice('Bearer '.length);

  try {
    const payload = jwt.verify(token, env.jwt.publicKey, {
      algorithms: ['RS256']
    }) as AccessTokenPayload;

    req.auth = {
      userId: payload.sub,
      role: payload.role,
      municipalityId: payload.municipalityId
    };
    next();
  } catch {
    throw AppError.unauthorized('Token de acesso invalido ou expirado.');
  }
}
