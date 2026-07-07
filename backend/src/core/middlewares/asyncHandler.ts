import { NextFunction, Request, Response } from 'express';

type AsyncRouteHandler = (req: Request, res: Response, next: NextFunction) => Promise<unknown>;

/**
 * Express 4 nao encaminha rejeicoes de Promise para o error handler
 * automaticamente (isso so mudou no Express 5). Todo controller assincrono
 * deve ser envolvido por este helper para que um `throw new AppError(...)`
 * dentro de um `async` handler chegue ate `errorHandler` em vez de virar um
 * unhandledRejection silencioso.
 */
export function asyncHandler(handler: AsyncRouteHandler) {
  return (req: Request, res: Response, next: NextFunction) => {
    handler(req, res, next).catch(next);
  };
}
