import { NextFunction, Request, Response } from 'express';
import { RoleName } from '@prisma/client';
import { AppError } from '../errors/AppError';

/**
 * Restringe uma rota a um conjunto de papeis. Deve ser usado sempre depois
 * de `authGuard`. Adicionar um novo papel no futuro (ex.: ADMIN_PREFEITURA)
 * nao exige alterar nenhuma rota existente — basta passar o novo enum onde
 * fizer sentido.
 */
export function requireRole(...allowed: RoleName[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.auth) {
      throw AppError.unauthorized();
    }
    if (!allowed.includes(req.auth.role)) {
      throw AppError.forbidden('Voce nao tem permissao para acessar este recurso.');
    }
    next();
  };
}
