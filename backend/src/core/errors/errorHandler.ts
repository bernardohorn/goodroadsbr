import { NextFunction, Request, Response } from 'express';
import { MulterError } from 'multer';
import { ZodError } from 'zod';
import { AppError } from './AppError';
import { logger } from '../logger/logger';

/**
 * Middleware central de tratamento de erros. Deve ser o ultimo `app.use()`
 * registrado. Garante que nenhuma rota vaze stack traces ou detalhes internos
 * para o cliente em producao.
 */
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error({ err, path: req.path }, 'AppError 5xx');
    }
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details
      }
    });
  }

  if (err instanceof ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Dados invalidos.',
        details: err.flatten()
      }
    });
  }

  if (err instanceof MulterError) {
    const friendlyMessage =
      err.code === 'LIMIT_FILE_SIZE'
        ? 'Uma das fotos excede o tamanho maximo permitido.'
        : err.code === 'LIMIT_FILE_COUNT' || err.code === 'LIMIT_UNEXPECTED_FILE'
          ? 'Numero de fotos enviadas excede o permitido.'
          : 'Falha ao processar o upload de arquivos.';

    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: friendlyMessage }
    });
  }

  logger.error({ err, path: req.path }, 'Erro nao tratado');

  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Erro interno do servidor.'
    }
  });
}
